#!/usr/bin/env python3
"""Banc de test sans node : lance les mêmes cas (test/cas.js) avec jsc, le moteur JavaScript de macOS.
Usage : python3 banc.py   (code de sortie 0 si tout passe)"""
import os, shutil, subprocess, sys

ICI = os.path.dirname(os.path.abspath(__file__))
JSC = "/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Helpers/jsc"

def main():
    node = shutil.which("node")
    if node:
        return subprocess.call([node, "--test"], cwd=ICI)
    if not os.path.exists(JSC):
        print("Ni node ni jsc : impossible de lancer les tests.")
        return 2
    return subprocess.call([JSC, "-m", os.path.join("test", "jsc_runner.js")], cwd=ICI)

if __name__ == "__main__":
    sys.exit(main())
