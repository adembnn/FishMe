"""Lit docs/lots.md : quel lot possède quelle branche et quels dossiers.

C'est la seule source des règles de l'atelier : les crochets et les scripts l'appellent,
aucun dossier n'est écrit en dur ailleurs.

Usage :
  python3 outils/atelier/lots.py verifier             sort 0 si chaque lot a une branche et des dossiers disjoints
  python3 outils/atelier/lots.py lot <branche>        affiche le code du lot de cette branche (rien si aucun)
  python3 outils/atelier/lots.py proprietaire <chemin> affiche le lot qui possède ce chemin, « commun » ou rien
  python3 outils/atelier/lots.py permis <code>         affiche les dossiers où ce lot peut écrire, un par ligne
  python3 outils/atelier/lots.py json                 affiche tous les lots en JSON
  python3 outils/atelier/lots.py liste                 affiche les lots, un par ligne (code, branche, nom, qui)
  python3 outils/atelier/lots.py branche-de <code>     affiche la branche du lot (sort 1 si le code est inconnu)
  python3 outils/atelier/lots.py changes               affiche les fichiers changés depuis la base commune avec main
  python3 outils/atelier/lots.py parties               lit des chemins sur l'entrée, dit quelles parties de verif.sh les touchent
  python3 outils/atelier/lots.py hors-lot <code|->     lit des chemins sur l'entrée, affiche ceux qui sortent du lot
  python3 outils/atelier/lots.py mise-a-jour <code>  sort 0 si le lot est dans le tableau « Dans la mise à jour » (attend v1.0-soumise)
  python3 outils/atelier/lots.py precommit             contrôle le commit en préparation (crochet de git)
"""
import json
import os
import re
import subprocess
import sys
import unicodedata

RACINE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
LOTS_MD = os.path.join(RACINE, "docs", "lots.md")
COMMUNS = ["docs/", "reports/", "CLAUDE.md", "README.md"]


def _cellules(ligne):
    return [c.strip() for c in ligne.strip().strip("|").split("|")]


def charger(chemin=LOTS_MD):
    """Rend la liste des lots : code, nom, branche, dossiers, qui, etapes, test."""
    with open(chemin, encoding="utf-8") as f:
        lignes = f.read().splitlines()
    lots, entete, section = [], None, ""
    for ligne in lignes:
        if ligne.startswith("## "):
            section = ligne[3:].strip()
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
                dossiers += [t for t in (f"AppTests/{m.group(1)}/", f"AppUITests/{m.group(1)}/") if t not in dossiers]
        lots.append({
            "code": code,
            "nom": r["Lot"][len(code):].strip(),
            "branche": r.get("Branche", "").strip("`"),
            "dossiers": dossiers,
            "qui": r.get("Qui", ""),
            "etapes": r.get("Étapes", ""),
            "test": r.get("Test qui bloque la fusion", ""),
            "mise_a_jour": section.startswith("Dans la mise à jour"),
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


# ---------------------------------------------------------------------------
# Ajouts de l'atelier (H0) : branche, fichiers changés, frontières des lots.
# Les hooks de Claude Code, les crochets de git et les scripts appellent ces fonctions.
# ---------------------------------------------------------------------------

def code_atelier(lots=None):
    """Le code du lot qui possède `outils/atelier/` (H0 avant le 19 oct., H1 depuis) : jamais écrit en dur."""
    for lot in (lots if lots is not None else charger()):
        if "outils/atelier/" in lot["dossiers"]:
            return lot["code"]
    return None
BRANCHES_PRINCIPALES = ("main", "master")
FICHIERS_FABRIQUES = ["stations-especes.json", "rarete-departements.json"]  # jamais commités (scripts/donnees.sh)
DOSSIERS_SANS_MARQUE = ["App/", "store/"]  # « Poké » y est interdit (marque de Nintendo)
DOSSIERS_APP = ["App/", "AppTests/", "AppUITests/", "Widget/"]
DOSSIERS_PAQUETS = ["Packages/"]
# « Poké » avec accent (Pokémon, Pokédex…), ou sans accent quand le mot est complet
MARQUE = re.compile(r"pok[eé](?:mon|dex|ball)|poké")


def _git(args, racine=RACINE):
    """Lance git dans `racine`. Rend (code de sortie, sortie texte). 127 si git est absent."""
    try:
        p = subprocess.run(["git", "-c", "core.quotepath=off"] + args, cwd=racine,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except OSError:
        return 127, ""
    return p.returncode, p.stdout.decode("utf-8", "replace")


def branche_courante(racine=RACINE):
    """Nom de la branche (vide si la tête est détachée ou si ce n'est pas un dépôt git)."""
    code, sortie = _git(["symbolic-ref", "--short", "-q", "HEAD"], racine)
    return sortie.strip() if code == 0 else ""


def base_commune(racine=RACINE):
    """Commit d'où la branche est partie : l'ancêtre commun avec origin/main, sinon main. None si on ne trouve pas."""
    for ref in ("origin/main", "main", "origin/master", "master"):
        code, sortie = _git(["merge-base", "HEAD", ref], racine)
        if code == 0 and sortie.strip():
            return sortie.strip()
    return None


def fichiers_changes(racine=RACINE):
    """Chemins changés depuis la base commune : commités, indexés, modifiés, supprimés et nouveaux (hors .gitignore)."""
    cible = base_commune(racine) or "HEAD"
    noms = set()
    for args in (["diff", "--name-only", "--no-renames", "-z", cible],
                 ["ls-files", "--others", "--exclude-standard", "-z"]):
        code, sortie = _git(args, racine)
        if code == 0:
            noms.update(n for n in sortie.split("\0") if n)
    return sorted(noms)


def est_secret(chemin):
    """Vrai pour un fichier de secrets (.env, .env.local…), où qu'il soit."""
    return os.path.basename(chemin).startswith(".env")


def est_projet_xcode(chemin):
    return chemin.endswith(".pbxproj")


def est_fabrique(chemin):
    return os.path.basename(chemin) in FICHIERS_FABRIQUES


def hors_lot(code, chemins, lots=None):
    """Chemins relatifs qui sortent du lot `code` (None : branche qui n'est pas un lot).
    Rend une liste de (chemin, propriétaire) ; le propriétaire est None si personne ne possède le chemin."""
    lots = lots if lots is not None else charger()
    refuses = []
    for chemin in chemins:
        proprio = proprietaire(chemin, lots)
        if proprio == "commun" or (code is not None and proprio == code):
            continue
        refuses.append((chemin, proprio))
    return refuses


def parties(chemins, lots=None):
    """Parties de scripts/verif.sh que ces chemins touchent : documents, lots, atelier, core, app."""
    lots = lots if lots is not None else charger()
    trouvees = set()
    for c in chemins:
        if c.startswith("docs/"):
            trouvees.add("documents")
        if c in ("docs/lots.md", "outils/atelier/lots.py"):
            trouvees.add("lots")
        if proprietaire(c, lots) == code_atelier(lots):
            trouvees.add("atelier")
        if any(c.startswith(d) for d in DOSSIERS_PAQUETS):
            trouvees.add("core")
        if any(c.startswith(d) for d in DOSSIERS_APP) or ".xcodeproj/" in c or c.endswith(".xcodeproj"):
            trouvees.add("app")
    return sorted(trouvees)


def _liste_dossiers(lot):
    return ", ".join(f"`{d}`" for d in lot["dossiers"])


def message_hors_lot(chemin, proprio, branche, lots=None):
    """Explication (en français simple) d'un chemin refusé : qui le possède, quoi lire, quoi faire."""
    lots = lots if lots is not None else charger()
    lot = lot_de_branche(branche, lots)
    communs = "docs/, reports/, CLAUDE.md et README.md"
    if lot is None:
        return (f"Refusé : `{chemin}` ne peut pas être écrit ici, parce que la branche `{branche or '(aucune)'}` n'est pas un lot.\n"
                f"Sur une branche qui n'est pas un lot, seuls {communs} sont permis.\n"
                "À faire : lance `scripts/lot.sh <code>` (les codes : `python3 outils/atelier/lots.py liste`), "
                "puis `cd` dans le dossier qu'il affiche et relance `claude` là-bas.")
    if proprio is None:
        return (f"Refusé : `{chemin}` n'appartient à aucun lot dans docs/lots.md.\n"
                f"Ton lot {lot['code']} écrit dans : {_liste_dossiers(lot)}, plus {communs}.\n"
                "À faire : si ce fichier doit exister, ajoute son dossier dans la colonne « Dossier » de docs/lots.md "
                "(c'est la seule source des règles), puis recommence.")
    autre = next((l for l in lots if l["code"] == proprio), None)
    nom = f" ({autre['nom']}, tenu par {autre['qui']})" if autre else ""
    return (f"Refusé : `{chemin}` appartient au lot {proprio}{nom}, pas à ton lot {lot['code']} ({lot['nom']}).\n"
            f"Ton lot {lot['code']} écrit dans : {_liste_dossiers(lot)}, plus {communs}.\n"
            f"À faire : ne touche pas à ce fichier. Lis la fiche docs/fiches/{proprio}.md pour savoir ce que ce lot attend, "
            "et note ce dont tu as besoin dans reports/ ou docs/ pour la personne qui le tient.")


def contenu_indexe(chemin, racine=RACINE):
    """Contenu du fichier tel qu'il est dans l'index de git (texte), ou '' s'il est illisible."""
    try:
        p = subprocess.run(["git", "show", ":" + chemin], cwd=racine, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except OSError:
        return ""
    return p.stdout.decode("utf-8", "replace") if p.returncode == 0 else ""


def cherche_marque(texte):
    """Numéros de ligne (à partir de 1) qui citent « Poké… », accents composés ou non, majuscules ou non."""
    lignes = unicodedata.normalize("NFC", texte).casefold().splitlines()
    return [i + 1 for i, ligne in enumerate(lignes) if MARQUE.search(ligne)]


def controler_commit(racine=RACINE):
    """Contrôle du commit en préparation (crochet pre-commit). Rend la liste des problèmes ; vide = permis."""
    problemes = []
    lots = charger(os.path.join(racine, "docs", "lots.md"))
    branche = branche_courante(racine)
    en_fusion = (os.environ.get("ATELIER_COMMIT_DE_FUSION") == "1"
                 or _git(["rev-parse", "-q", "--verify", "MERGE_HEAD"], racine)[0] == 0)
    if branche in BRANCHES_PRINCIPALES:
        problemes.append(f"Commit direct sur `{branche}` refusé : `{branche}` ne reçoit que ce que `scripts/fusionner.sh` y envoie.\n"
                         "À faire : `scripts/lot.sh <code>` pour travailler dans la copie de ton lot."
                         + (" Pour annuler cette fusion : `git merge --abort`." if en_fusion else ""))
    code, sortie = _git(["diff", "--cached", "--name-only", "--no-renames", "-z"], racine)
    fichiers = [f for f in sortie.split("\0") if f] if code == 0 else []
    lot = lot_de_branche(branche, lots)
    if not en_fusion and branche not in BRANCHES_PRINCIPALES:
        # Pendant une fusion, l'index contient le travail des autres lots : la frontière est contrôlée par fusionner.sh.
        for chemin, proprio in hors_lot(lot["code"] if lot else None, fichiers, lots):
            problemes.append(message_hors_lot(chemin, proprio, branche, lots)
                             + f"\nPour retirer ce fichier du commit : `git restore --staged {chemin}`")
    for chemin in fichiers:
        if est_secret(chemin):
            problemes.append(f"Refusé : `{chemin}` est un fichier de secrets (clés). Il ne se commite jamais.\n"
                             f"À faire : `git restore --staged {chemin}` ; le `.env` reste sur ton ordinateur.")
        elif est_fabrique(chemin):
            problemes.append(f"Refusé : `{chemin}` est un fichier de données fabriqué par script. Il ne se commite jamais.\n"
                             f"À faire : `git restore --staged {chemin}` ; `scripts/donnees.sh` le télécharge.")
    for chemin in fichiers:
        if any(chemin.startswith(d) for d in DOSSIERS_SANS_MARQUE):
            lignes = cherche_marque(contenu_indexe(chemin, racine))
            if lignes:
                problemes.append(f"Refusé : `{chemin}` (ligne {lignes[0]}) cite « Poké… », une marque de Nintendo. "
                                 "Elle ne doit apparaître ni dans l'app ni dans la fiche App Store.\n"
                                 "À faire : écris « Pescedex » (le nom de la collection) ou un autre mot.")
    return problemes


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
    if args[0] == "liste":
        for l in lots:
            print(f"{l['code']:<3} {l['branche']:<16} {l['nom']} (tenu par {l['qui']})")
        return 0
    if args[0] == "branche-de" and len(args) == 2:
        lot = next((l for l in lots if l["code"].upper() == args[1].upper()), None)
        if not lot:
            print(f"lot inconnu : {args[1]}. Lots : {', '.join(l['code'] for l in lots)}", file=sys.stderr)
            return 1
        print(lot["branche"])
        return 0
    if args[0] == "mise-a-jour" and len(args) == 2:
        lot = next((l for l in lots if l["code"].upper() == args[1].upper()), None)
        return 0 if lot and lot["mise_a_jour"] else 1
    if args[0] == "changes":
        print("\n".join(fichiers_changes()))
        return 0
    if args[0] == "parties":
        print(" ".join(parties([l.strip() for l in sys.stdin if l.strip()], lots)))
        return 0
    if args[0] == "hors-lot" and len(args) == 2:
        code = None if args[1] == "-" else args[1]
        refuses = hors_lot(code, [l.strip() for l in sys.stdin if l.strip()], lots)
        for chemin, proprio in refuses:
            print(f"{chemin}\t{proprio or 'personne'}")
        return 1 if refuses else 0
    if args[0] == "precommit":
        try:
            problemes = controler_commit()
        except Exception as erreur:  # un crochet en panne ne doit pas empêcher de corriger docs/lots.md
            print(f"· crochet pre-commit inactif : {erreur}", file=sys.stderr)
            return 0
        for p in problemes:
            print(p, file=sys.stderr)
            print(file=sys.stderr)
        if problemes:
            print("Commit refusé par l'atelier (cas d'urgence seulement : `git commit --no-verify`).", file=sys.stderr)
        return 1 if problemes else 0
    if args[0] == "json":
        print(json.dumps(lots, ensure_ascii=False, indent=1))
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
