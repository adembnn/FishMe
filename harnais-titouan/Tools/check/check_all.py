#!/usr/bin/env python3
"""Vérifications du dépôt Bredouille (Python standard, Windows/macOS/Linux).

Usage : python Tools/check/check_all.py [--skip-swift]
Code de sortie : 0 = tout est bon ; 1 = au moins une vérification a échoué.
`swift test` est lancé dans PecheCore seulement si `swift` est dans le PATH
(sinon : message « non exécuté », ce qui n'est pas un échec).
"""
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent  # racine du dépôt (bredouille-app)
CORE = ROOT / "PecheCore"
# Frameworks interdits dans PecheCore (doit compiler sous Linux et Windows).
APPLE_ONLY = {
    "SwiftUI", "UIKit", "AppKit", "Combine", "Observation", "CoreLocation",
    "FoundationModels", "os", "OSLog", "CoreML", "Vision", "CoreMotion",
    "StoreKit", "AVFoundation", "Photos", "PhotosUI", "MapKit", "CoreGraphics",
    "SwiftData", "AppIntents", "Darwin", "CryptoKit", "CoreImage", "ImageIO",
}
IMPORT_RE = re.compile(r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*import\s+(?:\w+\s+)?([A-Za-z_][\w]*)")


def read_text(path):
    return path.read_text(encoding="utf-8", errors="replace")


def walk(excluded_dirs, extensions=None):
    """Parcourt le dépôt en ignorant les dossiers exclus (par nom)."""
    for p in sorted(ROOT.rglob("*")):
        rel = p.relative_to(ROOT).parts
        if not p.is_file() or any(part in excluded_dirs for part in rel[:-1]):
            continue
        if extensions is None or p.suffix.lower() in extensions:
            yield p


def check_wording(config):
    rules = [(r["id"], re.compile(r["pattern"], re.IGNORECASE), r["message"]) for r in config["rules"]]
    marker = config.get("allow_marker", "wording-ok")
    exts = {e.lower() for e in config["scan_extensions"]}
    skip_files = set(config.get("exclude_files", []))
    errors, scanned = [], 0
    for p in walk(set(config["exclude_dirs"]), exts):
        if p.name in skip_files:
            continue
        scanned += 1
        for n, line in enumerate(read_text(p).splitlines(), 1):
            if marker in line:
                continue
            for rid, rx, msg in rules:
                if rx.search(line):
                    errors.append(f"{p.relative_to(ROOT)}:{n} [{rid}] {msg}")
    return errors, scanned


def check_json():
    errors, count = [], 0
    for p in walk({".git", ".build", "DerivedData", "node_modules", "cache", "xcuserdata"},
                  {".json", ".geojson", ".storekit"}):
        count += 1
        try:
            json.loads(read_text(p).lstrip("﻿"))
        except ValueError as e:
            errors.append(f"{p.relative_to(ROOT)} : JSON invalide ({e})")
    return errors, count


def check_core_imports():
    errors, count = [], 0
    if not CORE.is_dir():
        return ["PecheCore introuvable"], 0
    for p in sorted(CORE.rglob("*.swift")):
        if ".build" in p.parts:
            continue
        count += 1
        for n, line in enumerate(read_text(p).splitlines(), 1):
            m = IMPORT_RE.match(line)
            if m and m.group(1) in APPLE_ONLY:
                errors.append(f"{p.relative_to(ROOT)}:{n} import {m.group(1)} interdit dans PecheCore")
    return errors, count


def run_swift_tests():
    """Retourne (statut, message) avec statut dans ok / ko / skip."""
    swift = shutil.which("swift")
    if not swift:
        return "skip", "swift introuvable dans le PATH : swift test NON EXÉCUTÉ"
    if not (CORE / "Package.swift").is_file():
        return "ko", "PecheCore/Package.swift introuvable"
    proc = subprocess.run([swift, "test"], cwd=CORE, text=True, errors="replace",
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if proc.returncode == 0:
        return "ok", "swift test réussi"
    return "ko", "swift test en échec :\n" + "\n".join(proc.stdout.splitlines()[-25:])


def main():
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):  # console Windows : forcer l'UTF-8
            stream.reconfigure(encoding="utf-8", errors="replace")
    failed = False

    def report(title, errors, detail):
        nonlocal failed
        if errors:
            failed = True
            print(f"[ECHEC] {title} ({len(errors)})")
            for e in errors:
                print("   - " + e)
        else:
            print(f"[OK]    {title} : {detail}")

    try:
        config = json.loads(read_text(HERE / "wording_forbidden.json"))
    except (OSError, ValueError) as e:
        print(f"[ECHEC] wording_forbidden.json illisible : {e}")
        return 1
    errs, n = check_wording(config)
    report("Formulations interdites", errs, f"{n} fichiers examinés")
    errs, n = check_json()
    report("Validité JSON", errs, f"{n} fichiers JSON valides")
    errs, n = check_core_imports()
    report("PecheCore sans framework Apple", errs, f"{n} fichiers Swift examinés")

    if "--skip-swift" in sys.argv:
        print("[SKIP]  swift test : ignoré (--skip-swift)")
    else:
        status, msg = run_swift_tests()
        tag = {"ok": "[OK]   ", "ko": "[ECHEC]", "skip": "[SKIP] "}[status]
        print(f"{tag} {msg}")
        failed = failed or status == "ko"

    print("\nRésultat :", "ECHEC (code 1)" if failed else "OK (code 0)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
