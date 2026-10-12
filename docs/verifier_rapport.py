"""Bloque un rapport d'agent qui ne respecte pas les règles d'Adem.

Usage : python3 verifier_rapport.py reports/archi-ios.md [autres.md ...]
Sort 0 si tous les rapports passent, 1 sinon.
"""
import re
import sys

MAX_LIGNES = 200
MIN_SOURCES = 3


def verifier(chemin):
    texte = open(chemin, encoding="utf-8").read()
    lignes = texte.splitlines()
    trous = []
    if len(lignes) > MAX_LIGNES:
        trous.append(f"{len(lignes)} lignes, maximum {MAX_LIGNES}")
    if "Décision débloquée" not in texte:
        trous.append("pas de ligne « Décision débloquée »")
    if not re.search(r"^#+ .*Recommandation", texte, re.M):
        trous.append("pas de section « Recommandation »")
    sources = set(re.findall(r"https?://[^\s)>\]]+", texte))
    if len(sources) < MIN_SOURCES:
        trous.append(f"{len(sources)} sources, minimum {MIN_SOURCES}")
    if re.search(r"Poké(?!dex)|Pokémon", texte) and "marque" not in texte:
        trous.append("« Poké » utilisé sans rappel de la marque Nintendo")
    return trous


def main(chemins):
    echecs = 0
    for chemin in chemins:
        trous = verifier(chemin)
        if trous:
            echecs += 1
            print(f"ÉCHEC {chemin}")
            for t in trous:
                print(f"  - {t}")
        else:
            print(f"OK    {chemin}")
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
