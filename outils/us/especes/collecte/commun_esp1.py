"""Outils communs du groupe esp-1 (ME NH VT MA RI) : table nom -> latin, écriture du JSON, lecture HTML."""
import html, json, os, re

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.normpath(os.path.join(ICI, "..", "..", "..", ".."))
SORTIE = os.path.join(RACINE, "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
BRUT = "/private/tmp/claude-501/brut-us/especes"
DATE = "2026-11-08"

# nom courant (minuscules) -> latin ; le slug vient de especes-us.json
LATIN = {
    "brook trout": "Salvelinus fontinalis", "rainbow trout": "Oncorhynchus mykiss",
    "brown trout": "Salmo trutta", "lake trout": "Salvelinus namaycush",
    "landlocked atlantic salmon": "Salmo salar", "atlantic salmon": "Salmo salar",
    "rainbow smelt": "Osmerus mordax", "brown bullhead": "Ameiurus nebulosus",
    "smallmouth bass": "Micropterus dolomieu", "largemouth bass": "Micropterus salmoides",
    "yellow perch": "Perca flavescens", "walleye": "Sander vitreus",
    "northern pike": "Esox lucius", "chain pickerel": "Esox niger",
    "pumpkinseed": "Lepomis gibbosus", "rock bass": "Ambloplites rupestris",
    "bluegill": "Lepomis macrochirus", "redbreast sunfish": "Lepomis auritus",
    "black crappie": "Pomoxis nigromaculatus", "white crappie": "Pomoxis annularis",
    "common carp": "Cyprinus carpio", "longnose gar": "Lepisosteus osseus",
    "freshwater drum": "Aplodinotus grunniens", "bowfin": "Amia calva",
    "steelhead": "Oncorhynchus mykiss", "tiger trout": "Salmo trutta x Salvelinus fontinalis",
    "white perch": "Morone americana", "striped bass": "Morone saxatilis",
    "american shad": "Alosa sapidissima", "american eel": "Anguilla rostrata",
    "lake whitefish": "Coregonus clupeaformis", "cisco": "Coregonus artedi",
    "yellow bullhead": "Ameiurus natalis", "black bullhead": "Ameiurus melas",
    "channel catfish": "Ictalurus punctatus", "white catfish": "Ameiurus catus",
    "redfin pickerel": "Esox americanus americanus", "muskellunge": "Esox masquinongy",
    "tiger muskellunge": "Esox masquinongy x Esox lucius", "burbot": "Lota lota",
    "white sucker": "Catostomus commersonii", "sea-run brook trout": "Salvelinus fontinalis",
    "arctic char": "Salvelinus alpinus", "blueback herring": "Alosa aestivalis",
    "alewife": "Alosa pseudoharengus", "striped bass ": "Morone saxatilis",
}


def slugs():
    d = json.load(open(os.path.join(RACINE, "outils", "us", "especes", "especes-us.json"), encoding="utf-8"))
    return {e["latin"]: e["slug"] for e in d}


def nom_propre(n):
    return " ".join(w.capitalize() for w in n.split())


def entree(nom, zone, preuve, src, confiance="officielle", n=None, annee_max=None):
    lat = LATIN[nom.lower()]
    e = {"slug": slugs().get(lat), "nom": nom_propre(nom), "latin": lat, "zone": zone,
         "preuve": preuve, "src": src, "confiance": confiance}
    if n is not None:
        e["n"] = n
    if annee_max is not None:
        e["annee_max"] = annee_max
    return e


def texte(h):
    h = re.sub(r"(?s)<(script|style).*?</\1>", "", h)
    h = re.sub(r"<[^>]+>", "\n", h)
    h = html.unescape(h)
    return re.sub(r"\n\s*\n+", "\n", h)


def tableaux(h):
    out = []
    for tb in re.findall(r"(?s)<table.*?</table>", h):
        rows = []
        for r in re.findall(r"(?s)<tr.*?</tr>", tb):
            rows.append([re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", c))).strip()
                         for c in re.findall(r"(?s)<t[hd].*?</t[hd]>", r)])
        out.append(rows)
    return out


def ecrire(usps, producteur, sources, entrees):
    os.makedirs(SORTIE, exist_ok=True)
    d = {"format": "fishme-especes-us/1", "etat": usps, "producteur": producteur, "date": DATE,
         "sources": sources, "entrees": entrees}
    p = os.path.join(SORTIE, f"{usps}-{producteur}.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, indent=1)
        f.write("\n")
    return p
