#!/usr/bin/env bash
set -euo pipefail

TOOL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd -- "$TOOL_DIR/.." && pwd)"
REPO_ROOT="$(cd -- "$KIT_DIR/../../.." && pwd)"
REQUESTED_LOCALES=""
SCENE_LIST="trends,today,readings,trend,plus"
REUSE_JOB=""
ADOPT_JOB=""
while (($#)); do
    case "$1" in
        --scenes)
            SCENE_LIST="$2"
            shift 2
            ;;
        --adopt-job)
            ADOPT_JOB="$2"
            shift 2
            ;;
        --reuse-job)
            REUSE_JOB="$2"
            shift 2
            ;;
        *)
            REQUESTED_LOCALES="$REQUESTED_LOCALES${REQUESTED_LOCALES:+,}$1"
            shift
            ;;
    esac
done
PYTHON="$KIT_DIR/.venv/bin/python"
if [[ ! -x "$PYTHON" ]]; then
    python3 -m venv "$KIT_DIR/.venv"
fi
"$PYTHON" -m pip install -r "$TOOL_DIR/requirements.txt"
"$TOOL_DIR/build.sh"
"$PYTHON" "$TOOL_DIR/fetch_live.py"

mkdir -p "$KIT_DIR/raw"
SELECTED_FILE="$KIT_DIR/raw/.selected-locales"
python3 - "$KIT_DIR/app.json" "$SELECTED_FILE" "$REQUESTED_LOCALES" <<'PY'
import json
import sys
from pathlib import Path

app_path, selected_path, requested_string = sys.argv[1:]
requested = [item for item in requested_string.split(',') if item]
targets = json.loads(Path(app_path).read_text())['targets']
known = {item['store_locale']: item for item in targets}
unknown = sorted(set(requested) - set(known))
if unknown:
    raise SystemExit(f"unknown store locale: {', '.join(unknown)}")
selected = [item['store_locale'] for item in targets if not requested or item['store_locale'] in requested]
Path(selected_path).write_text(''.join(locale + '\n' for locale in selected))
print('Capturing:', ', '.join(['en-US', *selected]))
PY

SCENE_FILE="$KIT_DIR/raw/.selected-scenes"
python3 - "$SCENE_LIST" "$SCENE_FILE" <<'PY'
import sys
from pathlib import Path

known = ['trends', 'today', 'readings', 'trend', 'plus']
requested = [scene for scene in sys.argv[1].split(',') if scene]
unknown = sorted(set(requested) - set(known))
if unknown or not requested:
    raise SystemExit(f"unknown or empty scene list: {', '.join(unknown)}")
Path(sys.argv[2]).write_text(''.join(scene + '\n' for scene in known if scene in requested))
PY

if [[ -n "$REUSE_JOB" ]]; then
    python3 - "$KIT_DIR" "$REUSE_JOB" "$SELECTED_FILE" "$SCENE_FILE" <<'PY'
import json
import shutil
import sys
from pathlib import Path

kit, job, selected_file, scene_file = map(Path, sys.argv[1:])
results = Path.home() / '.gh-sim' / 'results' / job / 'attachments'
manifest_path = results / 'manifest.json'
if not manifest_path.is_file():
    raise SystemExit(f'missing reusable screenshot manifest: {manifest_path}')

selected = ['en-US', *[line for line in selected_file.read_text().splitlines() if line]]
captured = set(scene_file.read_text().splitlines())
scenes = ['trends', 'today', 'readings', 'trend', 'plus']
records = []

def collect(value):
    if isinstance(value, dict):
        if 'exportedFileName' in value and 'suggestedHumanReadableName' in value:
            records.append(value)
        for child in value.values():
            collect(child)
    elif isinstance(value, list):
        for child in value:
            collect(child)

collect(json.loads(manifest_path.read_text()))
for locale in selected:
    for scene in scenes:
        if scene in captured:
            continue
        prefix = f'{locale}__{scene}'
        matches = []
        for item in records:
            stem = Path(item['suggestedHumanReadableName']).stem
            parts = stem.rsplit('_', 2)
            key = parts[0] if len(parts) == 3 and parts[1].isdigit() else stem
            if key == prefix:
                matches.append(item)
        if len(matches) != 1:
            raise SystemExit(f'expected one reusable screenshot for {prefix}, found {len(matches)}')
        source = results / Path(matches[0]['exportedFileName']).name
        if not source.is_file():
            raise SystemExit(f'missing reusable attachment: {source}')
        destination = kit / 'raw' / locale / 'phone' / f'{scene}.png'
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        print(f'reused {locale}/phone/{scene}.png from {job}')
PY
fi

LOCALE_CONFIG="$REPO_ROOT/VO2MaxUITests/StoreScreenshotLocales.json"
LOCALE_BACKUP="$(mktemp)"
cp "$LOCALE_CONFIG" "$LOCALE_BACKUP"
restore_locale_config() {
    cp "$LOCALE_BACKUP" "$LOCALE_CONFIG"
    rm -f "$LOCALE_BACKUP"
}
trap restore_locale_config EXIT HUP INT TERM
python3 - "$KIT_DIR/app.json" "$SELECTED_FILE" "$SCENE_FILE" "$LOCALE_CONFIG" <<'PY'
import json
import sys
from pathlib import Path

app_path, selected_path, scene_path, config_path = map(Path, sys.argv[1:])
app = json.loads(app_path.read_text())
selected = set(selected_path.read_text().splitlines())
scenes = scene_path.read_text().splitlines()
locales = [
    {
        'store_locale': 'en-US',
        'language': 'en',
        'apple_locale': 'en_US',
    }
]
locales.extend(
    {
        'store_locale': item['store_locale'],
        'language': item['lang'],
        'apple_locale': item['apple_locale'],
    }
    for item in app['targets']
    if item['store_locale'] in selected
)
config_path.write_text(json.dumps({
    'locales': locales,
    'scenes': [{'name': scene, 'route': scene} for scene in scenes],
}, indent=2) + '\n')
PY

JOB_ID_FILE="$KIT_DIR/raw/.last-job-id"
rm -f "$JOB_ID_FILE"
if [[ -n "$ADOPT_JOB" ]]; then
    # Post-process a gh-sim job already started (or finished) for these locales and scenes.
    printf '%s\n' "$ADOPT_JOB" > "$JOB_ID_FILE"
    until [[ -f "$HOME/.gh-sim/results/$ADOPT_JOB/attachments/manifest.json" ]]; do sleep 20; done
    TEST_STATUS=0
elif gh-sim test --scheme VO2MaxUITests --device "iPhone 17 Pro Max" \
    --only VO2MaxUITests/StoreScreenshotsUITests/testLocalizedStoreScreenshots \
    --id-file "$JOB_ID_FILE"; then
    TEST_STATUS=0
else
    TEST_STATUS=$?
fi
if [[ -s "$JOB_ID_FILE" ]]; then
    python3 - "$KIT_DIR/raw/.ghsim-jobs" "$JOB_ID_FILE" <<'PY'
import sys
from pathlib import Path

tracker, job_file = map(Path, sys.argv[1:])
job = job_file.read_text().strip()
items = tracker.read_text().splitlines() if tracker.exists() else []
if job not in items:
    tracker.write_text('\n'.join([*items, job]) + '\n')
PY
fi
if (( TEST_STATUS != 0 )); then
    exit "$TEST_STATUS"
fi

python3 - "$KIT_DIR" "$JOB_ID_FILE" "$SELECTED_FILE" "$SCENE_FILE" <<'PY'
import json
import shutil
import sys
from pathlib import Path

kit, job_file, selected_file, scene_file = map(Path, sys.argv[1:])
job = job_file.read_text().strip()
attachments = Path.home() / '.gh-sim' / 'results' / job / 'attachments'
manifest = attachments / 'manifest.json'
selected = [line for line in selected_file.read_text().splitlines() if line]
locales = ['en-US', *selected]
scenes = [line for line in scene_file.read_text().splitlines() if line]
if not manifest.is_file():
    raise SystemExit(f'missing screenshot attachments manifest: {manifest}')
records = []

def collect(value):
    if isinstance(value, dict):
        if 'exportedFileName' in value and 'suggestedHumanReadableName' in value:
            records.append(value)
        for child in value.values():
            collect(child)
    elif isinstance(value, list):
        for child in value:
            collect(child)

collect(json.loads(manifest.read_text()))
expected = len(locales) * len(scenes)
matches = {}
for item in records:
    stem = Path(item['suggestedHumanReadableName']).stem
    parts = stem.rsplit('_', 2)
    key = parts[0] if len(parts) == 3 and parts[1].isdigit() else stem
    if '__' not in key:
        continue
    locale, scene = key.split('__', 1)
    if locale in locales and scene in scenes:
        matches.setdefault((locale, scene), []).append(item)
if len(matches) != expected or any(len(items) != 1 for items in matches.values()):
    raise SystemExit(f'expected one attachment for each of {expected} locale/scene pairs, found {len(matches)} pairs')

for locale in locales:
    for scene in scenes:
        item = matches[(locale, scene)][0]
        source = attachments / Path(item['exportedFileName']).name
        if not source.is_file():
            raise SystemExit(f'missing screenshot attachment: {source}')
        destination = kit / 'raw' / locale / 'phone' / f'{scene}.png'
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        print(f'{locale}/phone/{scene}.png')

for locale in locales:
    for scene in ['trends', 'today', 'readings', 'trend', 'plus']:
        raw = kit / 'raw' / locale / 'phone' / f'{scene}.png'
        if not raw.is_file():
            raise SystemExit(f'missing required capture {locale}/phone/{scene}.png; use --reuse-job for unchanged scenes')
PY

CONFIG="$KIT_DIR/frames.json"
HEADERS="$KIT_DIR/copy/headers.json"
OUT="$KIT_DIR/out"
GATE_FILE="$KIT_DIR/raw/.gate-status"
: > "$GATE_FILE"

while IFS= read -r locale; do
    [[ -n "$locale" ]] || continue
    rm -rf "$OUT/$locale"
    "$PYTHON" "$TOOL_DIR/reskin.py" --config "$CONFIG" --raw-root "$KIT_DIR/raw" \
        --headers "$HEADERS" --locale "$locale" --out "$OUT"
    lang="$(python3 - "$KIT_DIR/app.json" "$locale" <<'PY'
import json
import sys
from pathlib import Path

app = json.loads(Path(sys.argv[1]).read_text())
print(next(item['lang'] for item in app['targets'] if item['store_locale'] == sys.argv[2]))
PY
)"
    if "$PYTHON" "$TOOL_DIR/gate.py" --config "$CONFIG" --raw-root "$KIT_DIR/raw" \
        --headers "$HEADERS" --out-root "$OUT" --locale "$locale" \
        --catalog "$REPO_ROOT/Shared/Localizable.xcstrings" --lang "$lang"; then
        printf '%s\tPASS\n' "$locale" >> "$GATE_FILE"
    else
        printf '%s\tFAIL\n' "$locale" >> "$GATE_FILE"
    fi
    "$PYTHON" "$TOOL_DIR/sheet.py" --config "$CONFIG" --locale "$locale" \
        --out-root "$OUT" --base-label en-US
done < "$SELECTED_FILE"

python3 - "$KIT_DIR" "$SELECTED_FILE" "$GATE_FILE" "$JOB_ID_FILE" "$REUSE_JOB" <<'PY'
import json
import shutil
import sys
from pathlib import Path

kit, selected_file, gate_file, job_file = map(Path, sys.argv[1:5])
reuse_job = sys.argv[5] or None
repo = kit.parents[2]
config = json.loads((kit / 'frames.json').read_text())
selected = [line for line in selected_file.read_text().splitlines() if line]
gates = dict(line.split('\t', 1) for line in gate_file.read_text().splitlines() if line)
frames = config['sets']['phone']['frames']
managed = {frame['store_file'] for frame in frames}
managed.update(config.get('omitted_store_files', []))
report_path = kit / 'report.json'
previous_report = json.loads(report_path.read_text()) if report_path.exists() else {}
previous = previous_report.get('gh_sim_jobs', 0)
tracker = kit / 'raw' / '.ghsim-jobs'
job_ids = tracker.read_text().splitlines() if tracker.exists() else []
reported_ids = set(previous_report.get('gh_sim_job_ids', []))
all_job_ids = sorted(reported_ids | set(job_ids))
job_count = previous + len(set(job_ids) - reported_ids)
failures = [f'{locale}: gate failed' for locale in selected if gates.get(locale) != 'PASS']
if not failures:
    for locale in selected:
        destination = repo / 'fastlane' / 'screenshots' / locale
        destination.mkdir(parents=True, exist_ok=True)
        for path in destination.glob('*.png'):
            if path.name in managed:
                path.unlink()
        for frame in frames:
            source = kit / 'out' / locale / 'phone' / frame['file']
            shutil.copy2(source, destination / frame['store_file'])
report = {
    'locales': selected,
    'frames': len(frames),
    'gate': {locale: gates.get(locale, 'FAIL') for locale in selected},
    'gh_sim_jobs': job_count,
    'gh_sim_job_ids': all_job_ids,
    'app_code_changed': [],
    'defects': failures,
    'left_out': [],
    'excluded_by_design': [
        '05-keep-supporting-detail-close.png: Apple Watch display stays English and is outside the localized phone set'
    ],
    'adapter': 'GH-SIM localized UI test screenshot attachments, 14-second post-readiness wait',
    'captured_scenes': [line for line in (kit / 'raw' / '.selected-scenes').read_text().splitlines() if line],
    'reused_from_job': reuse_job,
}
report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')
print(json.dumps(report, indent=2, ensure_ascii=False))
if failures:
    raise SystemExit(1)
PY
