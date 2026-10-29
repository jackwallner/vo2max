#!/usr/bin/env python3
"""Checks Shared/Localizable.xcstrings against the Swift source.

Run from the repo root: python3 Tools/Localization/check.py

Fails (exit 1) when
  * a localizable literal in the source has no catalog key,
  * a catalog key is missing a language, or
  * a translation's format specifiers do not match its key.

Literals count as localizable when they are the first argument of a SwiftUI
text API (Text, Button, Label, Section, navigationTitle, alert, ...) or of
String(localized:). Simple integer interpolation types are inferred from local
declarations so catalog keys keep their runtime format specifiers.
"""
import json
import os
import re
import sys

ROOT = os.getcwd()
DIRS = ['VO2Max', 'VO2MaxWidget', 'VO2MaxWatch', 'VO2MaxWatchWidget', 'Shared']
LANGS = ['de', 'fr', 'nl', 'zh-Hant', 'ru', 'ar', 'es', 'ja', 'th', 'cs', 'it', 'hu', 'ro', 'el', 'pl', 'sk', 'sv']
PLURAL_KEYS = {
    '%lld days ago', '%lld days selected', '%lld estimates',
    'Age: %lld years',
    '%lld of %lld usable stretches so far.', '%lld readings', '%lld sessions',
    'About %lld months', 'About %lld months away at your recent pace',
    'At the recent pace of %@ mL/kg/min per month, the lower edge of your target range is roughly %lld months away.',
    'Average: %@. %lld readings.', 'Average: %@. Range: %lld to %lld. %lld readings.',
    'Last %lld days',
    'This comparison needs at least %lld stretches between estimates, with a few in each group. Keep recording workouts and it will fill in as Apple Health logs more estimates.',
    'previous %lld days', 'vs. previous %lld days',
    'Latest estimate %@. You usually get one every %lld days.',
    '%@. You usually get one every %lld days.',
    '%lld estimates from Apple Health', '%lld readings in the last 90 days', '%lld sessions',
    "Apple Health hasn't logged a VO2 max estimate in %lld days. %@",
    'Your last estimate landed %@, in line with your usual cadence of about %lld days.',
    'Your last estimate landed %@. You usually get one about every %lld days. %@',
    'Your last estimate landed %@, well past your usual %lld-day cadence. %@',
    'Sessions per week: %@. Estimate intervals: %lld.',
}
PLURAL_CATEGORIES = {
    'de': {'one', 'other'}, 'fr': {'one', 'other'}, 'nl': {'one', 'other'},
    'ru': {'one', 'few', 'many', 'other'}, 'ar': {'zero', 'one', 'two', 'few', 'many', 'other'},
    'es': {'one', 'other'}, 'cs': {'one', 'few', 'many', 'other'},
    'it': {'one', 'other'}, 'hu': {'one', 'other'}, 'ro': {'one', 'few', 'other'},
    'el': {'one', 'other'}, 'pl': {'one', 'few', 'many', 'other'},
    'sk': {'one', 'few', 'many', 'other'}, 'sv': {'one', 'other'},
}
UI_FUNCS = {'Text', 'Button', 'Label', 'Section', 'Toggle', 'TextField', 'navigationTitle', 'accessibilityLabel',
            'alert', 'DatePicker', 'Stepper', 'Link', 'configurationDisplayName', 'description', 'eyebrow',
            'confirmationDialog', 'Picker', 'LocalizedStringKey', 'accessibilityHint', 'accessibilityValue',
            'SecureField', 'ContentUnavailableView', 'navigationSubtitle', 'help', 'value'}
IGNORED = {'0'}


def parse_literal(src, i):
    """src[i] == '"'. Returns (end_index_after, segments) where segments are ('lit', str) or ('interp', expr)."""
    assert src[i] == '"'
    if src.startswith('"""', i):
        j = src.index('"""', i + 3)
        return j + 3, None
    i += 1
    segs = []; buf = ''
    while True:
        c = src[i]
        if c == '"':
            if buf: segs.append(('lit', buf))
            return i + 1, segs
        if c == '\\':
            n = src[i + 1]
            if n == '(':
                if buf: segs.append(('lit', buf)); buf = ''
                depth = 1; j = i + 2; expr = ''
                while depth:
                    ch = src[j]
                    if ch == '"':
                        k, _ = parse_literal(src, j)
                        expr += src[j:k]; j = k; continue
                    if ch == '(': depth += 1
                    elif ch == ')':
                        depth -= 1
                        if depth == 0: break
                    expr += ch; j += 1
                segs.append(('interp', expr.strip()))
                i = j + 1; continue
            if n == 'u':
                j = src.index('}', i)
                buf += chr(int(src[i + 3:j], 16)); i = j + 1; continue
            buf += {'n': '\n', 't': '\t', '"': '"', '\\': '\\', "'": "'", '0': '\0'}[n]
            i += 2; continue
        buf += c; i += 1

def scan(path):
    src = open(path).read()
    out = []
    stack = []  # (funcname, argtext_since_last_comma, argindex)
    i = 0; n = len(src)
    line = 1
    while i < n:
        c = src[i]
        if c == '\n': line += 1
        if src.startswith('//', i):
            j = src.find('\n', i); i = n if j < 0 else j; continue
        if src.startswith('/*', i):
            j = src.index('*/', i); line += src[i:j].count('\n'); i = j + 2; continue
        if c == '"':
            end, segs = parse_literal(src, i)
            if segs is not None and stack:
                fn, argtxt, idx = stack[-1]
                ctx = None
                if fn == 'String' and argtxt.strip().startswith('localized:'):
                    ctx = 'String'
                elif fn in UI_FUNCS and idx == 0 and not re.match(r'\s*[a-zA-Z_]+\s*:', argtxt):
                    ctx = fn
                elif fn in UI_FUNCS and idx == 0 and re.match(r'\s*titleKey\s*:', argtxt):
                    ctx = fn
                if ctx:
                    out.append((line, ctx, segs))
            line += src[i:end].count('\n')
            if stack:
                f, a, k = stack[-1]; stack[-1] = (f, a + src[i:end], k)
            i = end; continue
        if c == '(':
            m = re.search(r'([A-Za-z_][A-Za-z_0-9]*)\s*$', src[max(0, i - 60):i])
            stack.append((m.group(1) if m else '', '', 0)); i += 1; continue
        if c == ')':
            if stack: stack.pop()
            i += 1; continue
        if c == ',' and stack:
            f, a, k = stack[-1]; stack[-1] = (f, '', k + 1); i += 1; continue
        if stack:
            f, a, k = stack[-1]; stack[-1] = (f, a + c, k)
        i += 1
    return out


def integer_names(source, integer_properties):
    patterns = (
        r'\b(?:let|var)\s+(\w+)\s*:\s*(?:Int|Int\d+|UInt|UInt\d+)\b',
        r'\b(\w+)\s*:\s*(?:Int|Int\d+|UInt|UInt\d+)\b',
        r'\b(?:let|var)\s+(\w+)\s*=\s*-?\d+\b',
    )
    names = {name for pattern in patterns for name in re.findall(pattern, source)}
    integer_functions = set(re.findall(
        r'\bfunc\s+(\w+)\s*\([^)]*\)\s*->\s*(?:Int|Int\d+|UInt|UInt\d+)\??',
        source,
        re.S,
    ))
    declarations = re.findall(r'\b(?:let|var)\s+(\w+)\s*=\s*([^\n]+)', source)
    for _ in range(4):
        before = len(names)
        for name, expression in declarations:
            if re.search(r'\.count\b|\b(?:U?Int\d*)\s*\(', expression):
                names.add(name)
                continue
            if any(re.search(rf'\b{re.escape(function)}\s*\(', expression) for function in integer_functions):
                names.add(name)
                continue
            member = expression.strip().split('.')[-1].split()[0].rstrip('?!')
            if member in names | integer_properties and not any(token in expression for token in ('String(', 'formatted(', '"')):
                names.add(name)
        if len(names) == before:
            break
    return names


def is_integer_expression(expression, names, integer_properties):
    expression = expression.strip()
    if re.fullmatch(r'-?\d+', expression) or re.search(r'\b(?:U?Int\d*)\s*\(', expression):
        return True
    if expression.endswith('.count'):
        return True
    identifier = re.sub(r'[?!]+$', '', expression.split('.')[-1].strip())
    if re.fullmatch(r'[A-Za-z_]\w*', identifier) and identifier in names:
        return True
    if '.' in expression and identifier in integer_properties:
        return True
    if '.formatted(' in expression or 'String(' in expression:
        return False
    return None


def integer_properties(sources):
    type_by_name = {}
    for source in sources:
        for name, swift_type in re.findall(r'\b(?:let|var)\s+(\w+)\s*:\s*(\w+)', source):
            type_by_name.setdefault(name, set()).add(swift_type)
    integers = {'Int', 'Int8', 'Int16', 'Int32', 'Int64', 'UInt', 'UInt8', 'UInt16', 'UInt32', 'UInt64'}
    return {name for name, types in type_by_name.items() if len(types) == 1 and types <= integers}


def loose(key):
    return re.sub(r'%(\d+\$)?(lld|@)', '%*', key)


def specs(value, subs=None):
    found = []
    auto = 0
    for m in re.finditer(r'%(?:(\d+)\$)?(lld|@|%)|%#@(\w+)@|(%arg)', value):
        if m.group(2) == '%':
            continue
        if m.group(3):
            found.append((subs[m.group(3)]['argNum'], 'lld'))
            continue
        if m.group(4):
            substitution = next(iter(subs.values()))
            found.append((substitution['argNum'], substitution['formatSpecifier']))
            continue
        if m.group(1):
            pos = int(m.group(1))
        else:
            auto += 1
            pos = auto
        found.append((pos, m.group(2)))
    return sorted(set(found))


def main():
    catalog_paths = [
        'Shared/Localizable.xcstrings',
        'VO2Max/InfoPlist.xcstrings',
        'VO2MaxWatch/InfoPlist.xcstrings',
    ]
    catalog = json.load(open(os.path.join(ROOT, catalog_paths[0])))['strings']
    swift_sources = []
    for directory in DIRS:
        for dirpath, _, files in os.walk(os.path.join(ROOT, directory)):
            swift_sources.extend(
                open(os.path.join(dirpath, name)).read()
                for name in files if name.endswith('.swift')
            )
    int_properties = integer_properties(swift_sources)
    problems = []
    for d in DIRS:
        for dirpath, _, files in os.walk(os.path.join(ROOT, d)):
            for name in files:
                if not name.endswith('.swift'):
                    continue
                path = os.path.join(dirpath, name)
                source = open(path).read()
                integer_vars = integer_names(source, int_properties)
                for line, _, segs in scan(path):
                    has_interp = any(kind == 'interp' for kind, _ in segs)
                    specs_by_interp = [is_integer_expression(v, integer_vars, int_properties) for kind, v in segs if kind == 'interp']
                    key = ''.join((v.replace('%', '%%') if has_interp else v) if kind == 'lit'
                                  else ('%lld' if is_integer_expression(v, integer_vars, int_properties) is True else '%@')
                                  for kind, v in segs)
                    if key.strip() and key not in IGNORED and key not in catalog:
                        compatible = [candidate for candidate in catalog if loose(candidate) == loose(key)]
                        if not compatible or all(spec is not None for spec in specs_by_interp):
                            problems.append(f'{os.path.relpath(path, ROOT)}:{line}: no catalog key for "{key}"')
    for catalog_path in catalog_paths:
        path = os.path.join(ROOT, catalog_path)
        if not os.path.exists(path):
            problems.append(f'{catalog_path}: catalog is missing')
            continue
        strings = json.load(open(path))['strings']
        for key, entry in strings.items():
            locs = entry.get('localizations', {})
            for lang in LANGS:
                loc = locs.get(lang)
                if loc is None:
                    problems.append(f'{catalog_path} "{key}": missing {lang}')
                    continue
                want = specs(key)
                substitutions = loc.get('substitutions')
                plural_substitutions = [
                    substitution for substitution in (substitutions or {}).values()
                    if substitution.get('variations', {}).get('plural')
                ]
                if key in PLURAL_KEYS and plural_substitutions:
                    substitution = plural_substitutions[0]
                    selected = (substitution['argNum'], substitution['formatSpecifier'])
                    root_expected = [selected]
                    root_bad = specs(loc['stringUnit']['value'], substitutions) != root_expected
                else:
                    root_bad = specs(loc['stringUnit']['value'], substitutions) != want
                bad = [loc['stringUnit']['value']] if root_bad else []
                for substitution in (substitutions or {}).values():
                    values = substitution.get('variations', {}).get('plural', {}).values()
                    selected = (substitution['argNum'], substitution['formatSpecifier'])
                    without_count = [item for item in want if item != selected]
                    bad.extend(
                        unit['stringUnit']['value']
                        for unit in values
                        if specs(unit['stringUnit']['value'], substitutions) not in (want, without_count)
                    )
                if key in PLURAL_KEYS and lang in PLURAL_CATEGORIES:
                    forms = set(
                        loc.get('substitutions', {}).get('n', {}).get('variations', {}).get('plural', {})
                    )
                    missing = PLURAL_CATEGORIES[lang] - forms
                    if missing:
                        problems.append(f'{catalog_path} "{key}" [{lang}]: missing plural categories {sorted(missing)}')
                for value in bad:
                    problems.append(f'{catalog_path} "{key}" [{lang}]: format specifiers differ in "{value}"')
    for p in problems:
        print(p)
    print(f'{len(catalog)} keys, {len(LANGS)} languages, {len(problems)} problems')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
