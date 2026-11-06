#!/usr/bin/env bash
set -euo pipefail

TOOL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd -- "$TOOL_DIR/.." && pwd)"
REPO_ROOT="$(cd -- "$KIT_DIR/../../.." && pwd)"
PYTHON="$KIT_DIR/.venv/bin/python"
LOCALE_FILE="$REPO_ROOT/VO2MaxUITests/StoreScreenshotLocales.json"
if [[ ! -x "$PYTHON" ]]; then
    python3 -m venv "$KIT_DIR/.venv"
fi
"$PYTHON" -m pip install -r "$TOOL_DIR/requirements.txt"
"$TOOL_DIR/build.sh"
"$PYTHON" "$TOOL_DIR/fetch_live.py"
LOCALE_BACKUP="$(mktemp)"
cp "$LOCALE_FILE" "$LOCALE_BACKUP"
restore_locales() {
    cp "$LOCALE_BACKUP" "$LOCALE_FILE"
    rm -f "$LOCALE_BACKUP"
}
trap restore_locales EXIT

mkdir -p "$KIT_DIR/raw"
python3 - "$KIT_DIR/app.json" "$LOCALE_FILE" "$KIT_DIR/raw/.selected-locales" "$@" <<'PY'
import json
import sys
from pathlib import Path

app_path, locale_path, selected_path, *requested = sys.argv[1:]
app = json.loads(Path(app_path).read_text())
targets = app["targets"]
known = {item["store_locale"]: item for item in targets}
unknown = sorted(set(requested) - set(known))
if unknown:
    raise SystemExit(f"unknown store locale: {', '.join(unknown)}")
selected = [item for item in targets if not requested or item["store_locale"] in requested]
locales = [{"store_locale": "en-US", "language": "en", "apple_locale": "en_US"}]
locales.extend({
    "store_locale": item["store_locale"],
    "language": item["lang"],
    "apple_locale": item["apple_locale"],
} for item in selected)
Path(locale_path).write_text(json.dumps({"locales": locales}, indent=2) + "\n")
Path(selected_path).write_text("".join(item["store_locale"] + "\n" for item in selected))
PY

JOB_ID_FILE="$KIT_DIR/raw/.last-job-id"
if gh-sim test --scheme VO2MaxUITests --device "iPhone 17 Pro Max" \
    --only VO2MaxUITests/ReleaseJourneysUITests/testLocalizedStoreScreenshots \
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
    tracker.write_text("\n".join([*items, job]) + "\n")
PY
fi
if (( TEST_STATUS != 0 )); then
    exit "$TEST_STATUS"
fi

python3 - "$KIT_DIR" "$JOB_ID_FILE" "$KIT_DIR/raw/.selected-locales" <<'PY'
import json
import shutil
import sys
from pathlib import Path

kit, job_file, selected_file = map(Path, sys.argv[1:])
job = job_file.read_text().strip()
results = Path.home() / ".gh-sim" / "results" / job
attachments = results / "attachments"
manifest = json.loads((attachments / "manifest.json").read_text())
selected = [line for line in selected_file.read_text().splitlines() if line]
scenes = ["trends", "today", "readings", "trend", "plus"]

records = []
def collect(value):
    if isinstance(value, dict):
        if "exportedFileName" in value and "suggestedHumanReadableName" in value:
            records.append(value)
        for child in value.values():
            collect(child)
    elif isinstance(value, list):
        for child in value:
            collect(child)

collect(manifest)
for locale in ["en-US", *selected]:
    for scene in scenes:
        prefix = f"{locale}__{scene}"
        matches = []
        for item in records:
            stem = Path(item["suggestedHumanReadableName"]).stem
            parts = stem.rsplit("_", 2)
            key = parts[0] if len(parts) == 3 and parts[1].isdigit() else stem
            if key == prefix:
                matches.append(item)
        if len(matches) != 1:
            raise SystemExit(f"expected one screenshot attachment for {prefix}, found {len(matches)}")
        filename = Path(matches[0]["exportedFileName"]).name
        source = attachments / filename
        if not source.is_file():
            raise SystemExit(f"missing attachment {filename}")
        destination = kit / "raw" / locale / "phone" / f"{scene}.png"
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        print(f"{locale}/phone/{scene}.png")
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
print(next(item["lang"] for item in app["targets"] if item["store_locale"] == sys.argv[2]))
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
done < "$KIT_DIR/raw/.selected-locales"

python3 - "$KIT_DIR" "$KIT_DIR/raw/.selected-locales" "$GATE_FILE" "$JOB_ID_FILE" <<'PY'
import json
import shutil
import sys
from pathlib import Path

kit, selected_file, gate_file, job_file = map(Path, sys.argv[1:])
repo = kit.parents[2]
config = json.loads((kit / "frames.json").read_text())
targets = json.loads((kit / "app.json").read_text())["targets"]
selected = [line for line in selected_file.read_text().splitlines() if line]
languages = {item["store_locale"]: item["lang"] for item in targets}
gates = dict(line.split("\t", 1) for line in gate_file.read_text().splitlines() if line)
frames = config["sets"]["phone"]["frames"]
managed = {frame["store_file"] for frame in frames}
managed.update(config.get("omitted_store_files", []))
report_path = kit / "report.json"
previous = json.loads(report_path.read_text()).get("gh_sim_jobs", 0) if report_path.exists() else 0
tracker = kit / "raw" / ".ghsim-jobs"
job_ids = tracker.read_text().splitlines() if tracker.exists() else []
job_count = max(len(job_ids), previous + 1)
failures = [f"{locale}: gate failed" for locale in selected if gates.get(locale) != "PASS"]
if not failures:
    for locale in selected:
        destination = repo / "fastlane" / "screenshots" / locale
        destination.mkdir(parents=True, exist_ok=True)
        for path in destination.glob("*.png"):
            if path.name in managed:
                path.unlink()
        for frame in frames:
            source = kit / "out" / locale / "phone" / frame["file"]
            shutil.copy2(source, destination / frame["store_file"])
report = {
    "locales": selected,
    "frames": len(frames),
    "gate": {locale: gates.get(locale, "FAIL") for locale in selected},
    "gh_sim_jobs": job_count,
    "app_code_changed": [],
    "defects": failures,
    "left_out": [
        "05-keep-supporting-detail-close.png: Watch display stays English and is not part of the localized phone set"
    ],
    "adapter": "xcuitest",
}
report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
print(json.dumps(report, indent=2, ensure_ascii=False))
if failures:
    raise SystemExit(1)
PY
