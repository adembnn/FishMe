"""Prouve que la carte de construction n'a pas de trou.

Usage : python3 verifier.py   (depuis le dossier build/)
Affiche « 0 trou » et sort 0 si tout tient, sinon la liste des trous et sort 1.
"""
import os
import re
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
LIVRABLES = ["README.md", "parcours-demo.md", "lots.md", "architecture.md",
             "donnees.md", "app-store.md", "avant-jeudi.md", "message-mwm.md"]
TITRES_FICHE = ["## But", "## Avant de commencer", "## Dossiers", "## Contrat",
                "## Consigne à coller dans Claude Code", "## Test « fini »",
                "## Pièges", "## Si ça coince"]
QUI = {"A", "B", "S"}  # plus de « C » depuis le 15 oct. 14h26 (Adem)
trous = []


def lire(nom):
    with open(os.path.join(ICI, nom), encoding="utf-8") as f:
        return f.read()


def tableaux(texte):
    """Rend chaque tableau Markdown comme une liste de dicts (en-tête -> cellule)."""
    blocs, courant = [], []
    for ligne in texte.splitlines() + [""]:
        if ligne.startswith("|"):
            courant.append(ligne)
        elif courant:
            blocs.append(courant)
            courant = []
    rendus = []
    for bloc in blocs:
        if len(bloc) < 3:
            continue
        cellules = lambda l: [c.strip() for c in l.strip().strip("|").split("|")]
        entete = cellules(bloc[0])
        rendus.append([dict(zip(entete, cellules(l))) for l in bloc[2:]])
    return rendus


def chemins(cellule):
    return [c.rstrip("/") for c in re.findall(r"`([^`]+)`", cellule)]


# 1. Les livrables existent.
for nom in LIVRABLES:
    if not os.path.exists(os.path.join(ICI, nom)):
        trous.append(f"livrable absent : {nom}")

# 2. Les lots : complets, disjoints, et couvrent les étapes E1 à E9.
lots = [r for t in tableaux(lire("lots.md")) for r in t if "Lot" in r and "Dossier" in r]
if not lots:
    trous.append("lots.md : aucun tableau de lots trouvé")
proprietaire = {}
etapes_couvertes = set()
for lot in lots:
    code = lot["Lot"].split()[0]
    for col in ["Dossier", "Étapes", "Qui", "Test qui bloque la fusion", "Durée (estimation)"]:
        if not lot.get(col):
            trous.append(f"{code} : colonne « {col} » vide")
    if lot.get("Qui") not in QUI:
        trous.append(f"{code} : « Qui » doit valoir A, B ou S, pas « {lot.get('Qui')} »")
    etapes = lot.get("Étapes", "")
    etapes_couvertes |= set(re.findall(r"E\d", etapes))
    if "toutes" in etapes:
        etapes_couvertes |= {f"E{i}" for i in range(1, 10)}
    for chemin in chemins(lot.get("Dossier", "")):
        for autre, autre_code in proprietaire.items():
            if chemin == autre or chemin.startswith(autre + "/") or autre.startswith(chemin + "/"):
                trous.append(f"{code} et {autre_code} se partagent `{chemin}`")
        proprietaire[chemin] = code
    fiche = os.path.join(ICI, "fiches", f"{code}.md")
    if not os.path.exists(fiche):
        trous.append(f"{code} : fiche absente (fiches/{code}.md)")
    else:
        texte = open(fiche, encoding="utf-8").read()
        positions = [texte.find(t) for t in TITRES_FICHE]
        manquants = [t for t, p in zip(TITRES_FICHE, positions) if p < 0]
        if manquants:
            trous.append(f"fiches/{code}.md : titres absents {manquants}")
        elif positions != sorted(positions):
            trous.append(f"fiches/{code}.md : titres dans le désordre")

etapes_parcours = set(re.findall(r"^\| (E\d) \|", lire("parcours-demo.md"), re.M))
if len(etapes_parcours) != 9:
    trous.append(f"parcours-demo.md : {len(etapes_parcours)} étapes trouvées au lieu de 9")
for e in sorted(etapes_parcours - etapes_couvertes):
    trous.append(f"{e} n'est servie par aucun lot")

# 3. Chaque fichier de données a sa source et sa licence.
for t in tableaux(lire("donnees.md")):
    for r in t:
        if "Fichier" in r:
            if not r.get("Source") or not r.get("Licence et obligation"):
                trous.append(f"donnees.md : {r['Fichier']} sans source ou sans licence")

# 4. Chaque point de la check-list App Store a un responsable et un moment.
for t in tableaux(lire("app-store.md")):
    for r in t:
        if "Point" in r and (not r.get("Qui") or not r.get("Quand")):
            trous.append(f"app-store.md : point {r.get('#')} sans « Qui » ou sans « Quand »")

# 5. Pas plus de 3 questions ouvertes, chacune avec un choix par défaut.
readme = lire("README.md")
questions = re.findall(r"^\*\*\d\.\*\*", readme, re.M)
if len(questions) > 3:
    trous.append(f"README.md : {len(questions)} questions ouvertes, 3 au plus")
if readme.count("Par défaut") < len(questions):
    trous.append("README.md : une question sans choix par défaut")

# 6. Aucune marque de Nintendo hors des lignes qui la signalent ; aucun renvoi vers un fichier absent.
for nom in LIVRABLES:
    if not os.path.exists(os.path.join(ICI, nom)):
        continue
    for n, ligne in enumerate(lire(nom).splitlines(), 1):
        if re.search(r"Poké", ligne) and "marque" not in ligne:
            trous.append(f"{nom}:{n} : « Poké » sans rappel de la marque")
        for ref in re.findall(r"`((?:reports|fiches)/[\w.-]+\.md)`", ligne):
            if not os.path.exists(os.path.join(ICI, ref)):
                trous.append(f"{nom}:{n} : renvoi vers {ref}, absent")

if trous:
    print(f"{len(trous)} trou(s) :")
    for t in trous:
        print(f"  - {t}")
    sys.exit(1)
print(f"0 trou : {len(lots)} lots, étapes {', '.join(sorted(etapes_couvertes & etapes_parcours))} couvertes, "
      f"{len(LIVRABLES)} livrables, fiches complètes.")
