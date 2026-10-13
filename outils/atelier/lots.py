"""Lit docs/lots.md : quel lot possède quelle branche et quels dossiers.

C'est la seule source des règles de l'atelier : les crochets et les scripts l'appellent,
aucun dossier n'est écrit en dur ailleurs.

Usage :
  python3 outils/atelier/lots.py verifier             sort 0 si chaque lot a une branche et des dossiers disjoints
  python3 outils/atelier/lots.py lot <branche>        affiche le code du lot de cette branche (rien si aucun)
  python3 outils/atelier/lots.py proprietaire <chemin> affiche le lot qui possède ce chemin, « commun » ou rien
  python3 outils/atelier/lots.py permis <code>         affiche les dossiers où ce lot peut écrire, un par ligne
  python3 outils/atelier/lots.py json                 affiche tous les lots en JSON
"""
import json
import os
import re
import sys

RACINE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
LOTS_MD = os.path.join(RACINE, "docs", "lots.md")
COMMUNS = ["docs/", "reports/", "CLAUDE.md", "README.md"]


def _cellules(ligne):
    return [c.strip() for c in ligne.strip().strip("|").split("|")]


def charger(chemin=LOTS_MD):
    """Rend la liste des lots : code, nom, branche, dossiers, qui, etapes, test."""
    with open(chemin, encoding="utf-8") as f:
        lignes = f.read().splitlines()
    lots, entete = [], None
    for ligne in lignes:
        if not ligne.startswith("|"):
            entete = None
            continue
        cellules = _cellules(ligne)
        if "Lot" in cellules and "Dossier" in cellules:
            entete = cellules
            continue
        if entete is None or set(ligne) <= set("|-: "):
            continue
        r = dict(zip(entete, cellules))
        code = r["Lot"].split()[0]
        dossiers = re.findall(r"`([^`]+)`", r.get("Dossier", ""))
        for d in list(dossiers):
            m = re.match(r"^App/([^/]+)/$", d)
            if m:
                dossiers += [f"AppTests/{m.group(1)}/", f"AppUITests/{m.group(1)}/"]
        lots.append({
            "code": code,
            "nom": r["Lot"][len(code):].strip(),
            "branche": r.get("Branche", "").strip("`"),
            "dossiers": dossiers,
            "qui": r.get("Qui", ""),
            "etapes": r.get("Étapes", ""),
            "test": r.get("Test qui bloque la fusion", ""),
        })
    return lots


def _couvre(dossier, chemin):
    dossier = dossier.rstrip("/")
    return chemin == dossier or chemin.startswith(dossier + "/")


def relatif(chemin, racine=RACINE):
    """Chemin relatif à la racine du dépôt, ou None s'il est hors du dépôt."""
    absolu = os.path.realpath(os.path.join(racine, chemin))
    racine = os.path.realpath(racine)
    if absolu != racine and not absolu.startswith(racine + os.sep):
        return None
    return os.path.relpath(absolu, racine).replace(os.sep, "/")


def proprietaire(chemin, lots=None):
    """Code du lot qui possède ce chemin relatif, « commun », ou None si personne."""
    for c in COMMUNS:
        if _couvre(c, chemin):
            return "commun"
    for lot in lots if lots is not None else charger():
        if any(_couvre(d, chemin) for d in lot["dossiers"]):
            return lot["code"]
    return None


def lot_de_branche(branche, lots=None):
    for lot in lots if lots is not None else charger():
        if lot["branche"] and lot["branche"] == branche:
            return lot
    return None


def verifier(lots):
    trous = []
    vus = {}
    for lot in lots:
        if not lot["branche"].startswith("lot/"):
            trous.append(f"{lot['code']} : branche absente ou hors de lot/")
        if not lot["dossiers"]:
            trous.append(f"{lot['code']} : aucun dossier")
        for d in lot["dossiers"]:
            for autre, code in vus.items():
                if _couvre(autre, d) or _couvre(d, autre):
                    trous.append(f"{lot['code']} et {code} se partagent `{d}`")
            vus[d] = lot["code"]
    branches = [l["branche"] for l in lots]
    for b in set(branches):
        if branches.count(b) > 1:
            trous.append(f"branche {b} donnée à plusieurs lots")
    return trous


def main(args):
    lots = charger()
    if not args or args[0] == "verifier":
        trous = verifier(lots)
        for t in trous:
            print(f"  - {t}")
        print(f"{len(lots)} lots lus, {len(trous)} trou(s)")
        return 1 if trous else 0
    if args[0] == "lot" and len(args) == 2:
        lot = lot_de_branche(args[1], lots)
        if lot:
            print(lot["code"])
        return 0
    if args[0] == "proprietaire" and len(args) == 2:
        print(proprietaire(relatif(args[1]) or args[1], lots) or "")
        return 0
    if args[0] == "permis" and len(args) == 2:
        lot = next((l for l in lots if l["code"] == args[1]), None)
        if not lot:
            print(f"lot inconnu : {args[1]}", file=sys.stderr)
            return 1
        print("\n".join(lot["dossiers"] + COMMUNS))
        return 0
    if args[0] == "json":
        print(json.dumps(lots, ensure_ascii=False, indent=1))
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
