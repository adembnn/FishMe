"""Briques communes des collectes d'especes par zone (US16, groupe esp-7).

Fournit : correspondance nom anglais -> (slug, latin), ecriture d'un fichier <USPS>-<producteur>.json.
Aucune rarete, aucun mot de permission, aucune coordonnee."""
import json
import os
import re

ICI = os.path.dirname(os.path.abspath(__file__))
ESPECES = os.path.join(ICI, "..", "especes-us.json")
SORTIE = os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
DATE = "2026-11-08"

# Noms vus chez les agences -> nom de la table (especes-us.json, champ nom_en simplifie)
ALIAS = {
    "bluegill sunfish": "bluegill", "redear sunfish": "redear sunfish", "striped hybrid bass": "wiper",
    "hybrid striped bass": "wiper", "wiper": "wiper", "white bass x striped bass": "wiper",
    "kentucky bass": "spotted bass", "kentucky spotted bass": "spotted bass",
    "king salmon": "chinook salmon", "kokanee": "sockeye salmon", "kokanee salmon": "sockeye salmon",
    "lake herring": "cisco", "tiger muskellunge": "tiger muskie", "tiger muskie": "tiger muskie",
    "pure muskellunge": "muskellunge", "muskie": "muskellunge", "sauger": "sauger",
    "shellcracker": "redear sunfish", "rainbow trout": "rainbow trout", "steelhead": "rainbow trout",
    "burbot (ling)": "burbot", "black bullhead catfish": "black bullhead", "brown bullhead catfish": "brown bullhead", "yellow bullhead catfish": "yellow bullhead", "buffalo": None, "carp": "common carp", "eurasian perch": None,
}

# Hors table : latin verifie dans les tables officielles lues (guide SD GFP) ou connu sans doute
LATIN_EXTRA = {
    "zander": "Sander lucioperca",
    "tiger trout": "Salmo trutta x Salvelinus fontinalis",
    "shortnose gar": "Lepisosteus platostomus",
    "pallid sturgeon": "Scaphirhynchus albus",
    "goldeye": "Hiodon alosoides",
    "mooneye": "Hiodon tergisus",
    "gizzard shad": "Dorosoma cepedianum",
    "rainbow smelt": "Osmerus mordax",
    "river carpsucker": "Carpiodes carpio",
    "quillback": "Carpiodes cyprinus",
    "highfin carpsucker": "Carpiodes velifer",
    "blue sucker": "Cycleptus elongatus",
    "black buffalo": "Ictiobus niger",
    "golden redhorse": "Moxostoma erythrurum",
    "shorthead redhorse": "Moxostoma macrolepidotum",
    "silver redhorse": "Moxostoma anisurum",
    "greater redhorse": "Moxostoma valenciennesi",
    "river redhorse": "Moxostoma carinatum",
    "longnose sucker": "Catostomus catostomus",
    "stonecat": "Noturus flavus",
    "orangespotted sunfish": "Lepomis humilis",
    "yellow bass": "Morone mississippiensis",
    "spotted sucker": "Minytrema melanops",
    "shorthead gar": None,
    "blue catfish": "Ictalurus furcatus",
    "plains minnow": None,
}


def _simple(nom):
    return re.sub(r"\s*\(.*?\)", "", nom).strip().lower()


def charger_table():
    """nom (minuscule) -> (slug, latin) pour les 80 especes de la table."""
    t = {}
    for e in json.load(open(ESPECES, encoding="utf-8")):
        t[_simple(e["nom_en"])] = (e["slug"], e["latin"])
        t[e["slug"].replace("-", " ")] = (e["slug"], e["latin"])
    return t


_TABLE = charger_table()


def resoudre(nom):
    """Renvoie (slug|None, latin|None, nom propre). latin None : espece non resolue (a ecarter et a signaler)."""
    n = re.sub(r"\s+", " ", nom.strip().lower())
    n = ALIAS.get(n, n) if n in ALIAS else n
    if n is None:
        return None, None, nom.strip()
    if n in _TABLE:
        slug, latin = _TABLE[n]
        if " x " in latin or latin.endswith("spp."):
            pass
        return slug, latin, nom.strip()
    if n in LATIN_EXTRA and LATIN_EXTRA[n]:
        return None, LATIN_EXTRA[n], nom.strip()
    return None, None, nom.strip()


def ecrire(etat, producteur, sources, entrees, dossier=None):
    d = {"format": "fishme-especes-us/1", "etat": etat, "producteur": producteur, "date": DATE,
         "sources": sources, "entrees": entrees}
    dossier = dossier or SORTIE
    os.makedirs(dossier, exist_ok=True)
    p = os.path.join(dossier, f"{etat}-{producteur}.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return p, os.path.getsize(p)


def entree(nom, zone, preuve, src, confiance="officielle", n=None, annee_max=None):
    slug, latin, propre = resoudre(nom)
    if not latin:
        return None
    e = {"slug": slug, "nom": propre, "latin": latin, "zone": zone, "preuve": preuve, "src": src, "confiance": confiance}
    if n is not None:
        e["n"] = n
    if annee_max is not None:
        e["annee_max"] = annee_max
    return e
