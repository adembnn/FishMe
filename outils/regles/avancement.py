"""Écrit le tableau d'avancement de la lecture locale (D3) à partir des fichiers présents.

Usage : python -I outils/regles/avancement.py [fichier de sortie, par défaut reports/regles-local/avancement.md]
Pour chaque département : textes du corpus (dont OCR), règles des lectures A et B, et règles confirmées (consensus/<code>.json).
"""
import json
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))


def lire(*chemin):
    p = os.path.join(ICI, *chemin)
    try:
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return None


def main():
    sortie = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ICI, "..", "..", "reports", "regles-local", "avancement.md")
    lignes = []
    print = lignes.append
    codes = set()
    for d in ("corpus", "dep", "dep-b", "consensus"):
        if os.path.isdir(os.path.join(ICI, d)):
            codes |= {os.path.splitext(n)[0] for n in os.listdir(os.path.join(ICI, d))}
    print("# Avancement D3 en local (PC Windows d'Adem)\n")
    print("Chaîne : collecteur (corpus + manifeste) → lectures A et B → valider.py → consensus.py <code> --json.\n")
    print("| Dép. | Textes (OCR) | A | B | Confirmées |")
    print("|---|---|---|---|---|")
    total = 0
    for c in sorted(codes):
        man = lire("corpus", c, "manifeste.json")
        textes = man.get("textes", []) if man else []
        ocr = sum(1 for t in textes if str(t.get("extraction", "")).startswith(("ocr", "mixte")))
        a, b, k = lire("dep", c + ".json"), lire("dep-b", c + ".json"), lire("consensus", c + ".json")
        na = len(a["regles"]) if a else None
        nb = len(b["regles"]) if b else None
        nk = None
        if isinstance(k, dict):
            r = k.get("regles") or k.get("retenues") or k.get("accord")
            nk = len(r) if isinstance(r, list) else None
        if nk:
            total += nk
        cell = lambda v: "" if v is None else str(v)
        conf = f"{nk} ({round(100 * nk / na)} % de A)" if nk is not None and na else cell(nk)
        print(f"| {c} | {len(textes)} ({ocr}) | {cell(na)} | {cell(nb)} | {conf} |")
    print(f"\nTotal des règles confirmées : {total}.")
    with open(sortie, "w", encoding="utf-8") as f:
        f.write("\n".join(lignes) + "\n")
    sys.stdout.buffer.write(f"{sortie} : {len(codes)} départements, {total} règles confirmées\n".encode("utf-8"))


if __name__ == "__main__":
    main()
