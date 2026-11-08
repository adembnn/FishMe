#!/usr/bin/env python3
"""AR : pages « poissons » de l'Arkansas Game & Fish Commission (AGFC). Aucune liste unique n'existe sur agfc.com :
chaque fait (espèce, éventuellement plan d'eau) est tiré d'une page de l'agence et n'est écrit que si la phrase d'ancrage
se retrouve dans la page téléchargée (faits et noms seulement, aucun texte recopié).
Usage : python3 -I AR.py [dossier de pages déjà téléchargées]"""
import re, html, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import esp8_commun as C

H = "https://www.agfc.com/fishing/"
PAGES = [  # (fichier local, URL, nom)
    ("ar-bb.html", H + "black-bass/", "AGFC, Black Bass"),
    ("ar-cat.html", H + "more-species/catfish/", "AGFC, Catfish"),
    ("ar-pan.html", H + "more-species/panfish/", "AGFC, Panfish"),
    ("ar-str.html", H + "more-species/striped-bass/", "AGFC, Striped Bass"),
    ("ar-wal.html", H + "more-species/walleye/", "AGFC, Walleye"),
    ("ar-gar.html", H + "more-species/alligator-gar/", "AGFC, Alligator Gar"),
    ("ar-tr.html", H + "trout/", "AGFC, Trout"),
]
ETAT = {"type": "etat", "id": "AR", "nom": "Arkansas"}


def eau(nom):
    return {"type": "plan_eau", "id": nom, "nom": nom}


# (page, espèce, zone, phrase d'ancrage dans la page)
FAITS = [
    (0, "largemouth bass", ETAT, "the largemouth, smallmouth and spotted bass"),
    (0, "smallmouth bass", ETAT, "the largemouth, smallmouth and spotted bass"),
    (0, "spotted bass", ETAT, "the largemouth, smallmouth and spotted bass"),
    (0, "florida largemouth bass", ETAT, "stocks the Florida largemouth bass"),
    (1, "channel catfish", ETAT, "channel catfish"),
    (2, "redear sunfish", ETAT, "redear sunfish"),
    (3, "striped bass", ETAT, "Beaver, Hamilton, Norfork and Ouachita"),
    (4, "walleye", ETAT, "walleye, sauger and saugeye"),
    (4, "sauger", ETAT, "walleye, sauger and saugeye"),
    (4, "saugeye", ETAT, "walleye, sauger and saugeye"),
    (5, "alligator gar", ETAT, "Alligator Gar"),
    (6, "rainbow trout", ETAT, "rainbow trout"),
    (6, "brown trout", ETAT, "brown, cutthroat or tiger trout"),
    (6, "cutthroat trout", ETAT, "brown, cutthroat or tiger trout"),
    (6, "tiger trout", ETAT, "brown, cutthroat or tiger trout"),
    (6, "brook trout", ETAT, "rainbow or brook trout"),
    # plans d'eau nommés par l'agence
    (3, "striped bass", eau("Beaver Lake"), "Beaver, Hamilton, Norfork and Ouachita"),
    (3, "striped bass", eau("Lake Hamilton"), "Beaver, Hamilton, Norfork and Ouachita"),
    (3, "striped bass", eau("Norfork Lake"), "Beaver, Hamilton, Norfork and Ouachita"),
    (3, "striped bass", eau("Lake Ouachita"), "Beaver, Hamilton, Norfork and Ouachita"),
    (4, "walleye", eau("Greers Ferry Lake"), "Greers Ferry and Lake Catherine"),
    (4, "walleye", eau("Lake Catherine"), "Greers Ferry and Lake Catherine"),
    (6, "rainbow trout", eau("White River (Bull Shoals Dam to Norfork Access)"), "White River from Bull Shoals Dam to the Norfork Access"),
    (6, "rainbow trout", eau("North Fork River (Norfork Dam to Norfork Access)"), "North Fork River from Norfork Dam to the Norfork Access"),
    (6, "rainbow trout", eau("White River (Norfork Access to Arkansas Highway 58)"), "Norfork Access downstream to the Arkansas Highway 58 bridge"),
    (6, "brown trout", eau("White River (Norfork Access to Arkansas Highway 58)"), "one brown, cutthroat or tiger trout"),
    (6, "cutthroat trout", eau("White River (Norfork Access to Arkansas Highway 58)"), "one brown, cutthroat or tiger trout"),
    (6, "tiger trout", eau("White River (Norfork Access to Arkansas Highway 58)"), "one brown, cutthroat or tiger trout"),
    (6, "brook trout", eau("White River (Norfork Access to Arkansas Highway 58)"), "rainbow or brook trout"),
]


def texte(page):
    s = re.sub(r"<script.*?</script>|<style.*?</style>", " ", page, flags=re.S)
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", s)))


def construire(pages):
    """pages : liste de contenus HTML dans l'ordre de PAGES. -> (entrees, manquants)"""
    textes = [texte(p) for p in pages]
    entrees, manquants = [], []
    for i, nom, zone, phrase in FAITS:
        if phrase.lower() not in textes[i].lower():
            manquants.append((nom, zone["nom"], phrase))
            continue
        e = C.entree(nom, zone, "liste_agence", i)
        if e and e not in entrees:
            entrees.append(e)
    return entrees, manquants


def main(dossier=None):
    dossier = dossier or C.BRUT
    pages = []
    for f, url, _ in PAGES:
        chemin = os.path.join(dossier, f)
        pages.append(open(chemin, encoding="utf-8", errors="replace").read() if os.path.exists(chemin) else C.telecharger(url))
    entrees, manquants = construire(pages)
    sources = [C.src(n, u) for _, u, n in PAGES]
    chemin, taille = C.ecrire("AR", "agence", sources, entrees)
    print(chemin, taille, len(entrees), "entrées ; phrases d'ancrage absentes :", manquants)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
