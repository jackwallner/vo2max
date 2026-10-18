#!/usr/bin/env python3
"""Export expected analysis values from the iOS implementation without an iOS runtime."""
from pathlib import Path
import os
import subprocess
import tempfile


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix="vo2max-parity-") as temporary:
        directory = Path(temporary)
        main_file = directory / "main.swift"
        main_file.write_text((root / "scripts/export-android-parity.swift").read_text())
        files = [root / "Shared/Utilities" / f"{name}.swift" for name in ["CardioFitnessAnalysis", "CardioMetricAnalysis", "CardioFreshness"]]
        binary = directory / "parity"
        subprocess.run(["swiftc", *map(str, files), str(main_file), "-o", str(binary)], check=True)
        target = root / "android/app/src/test/resources/swift-parity.json"
        subprocess.run([str(binary), str(target)], check=True, env={**os.environ, "TZ": "UTC"})


if __name__ == "__main__":
    main()
