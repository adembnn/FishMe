#!/usr/bin/env python3
"""US15 : ajoute à docs/donnees.md une ligne par fichier de geo-us/ qui n'en a pas encore (source, licence, date lues dans le fichier).
Usage : python3 -I generer_donnees_md.py [--verifier]   (--verifier : échoue si une ligne manque, sans rien écrire)"""
import json, os, sys
ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.normpath(os.path.join(ICI, "..", "..", ".."))
GEO = os.path.join(RACINE, "Packages", "Core", "Sources", "Core", "Resources", "geo-us")
MD = os.path.join(RACINE, "docs", "donnees.md")


def ligne(nom):
    p = os.path.join(GEO, nom)
    d = json.load(open(p, encoding="utf-8"))
    ko = os.path.getsize(p) / 1e3
    taille = f"{ko / 1e3:.2f} Mo" if ko >= 1000 else f"{ko:.0f} Ko"
    if d.get("sources"):
        src = " ; ".join(s["texte"] for s in d["sources"])
        lic = " ; ".join(dict.fromkeys(s["licence"] for s in d["sources"]))
    else:
        src = f"{d.get('source')} ({d.get('url_source')})"
        lic = d.get("licence")
    return (f"| `geo-us/{nom}` | E2 (carte US) | {src} | {lic} ; lu le {d.get('date')} | fabriqué par `outils/us/geo/embarquer.py`, "
            f"commité : {d.get('compte', '')} objets, {taille} | US15, {d.get('date')} |")


def main():
    md = open(MD, encoding="utf-8").read()
    manquants = [n for n in sorted(os.listdir(GEO)) if n.endswith(".json") and f"`geo-us/{n}`" not in md]
    if "--verifier" in sys.argv:
        for n in manquants:
            print("TROU docs/donnees.md : pas de ligne pour", n)
        print(f"{len(manquants)} trou(s)")
        return 1 if manquants else 0
    if not manquants:
        return 0
    lignes = md.split("\n")
    dernier = max(i for i, l in enumerate(lignes) if l.startswith("| `geo-us/"))
    lignes[dernier + 1:dernier + 1] = [ligne(n) for n in manquants]
    open(MD, "w", encoding="utf-8").write("\n".join(lignes))
    print(len(manquants), "ligne(s) ajoutée(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
