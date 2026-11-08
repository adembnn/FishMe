"""Outils communs du groupe esp-8 (AR, LA, TX, NM, CO) : noms d'espèces vers slug + nom latin, écriture des fichiers.
Seulement des faits : noms d'espèces, plans d'eau publics, années. Aucune rareté, aucun mot de permission."""
import json, os, re, time, urllib.request

UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
DATE = "2026-11-08"
ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
BRUT = "/private/tmp/claude-501/brut-us/especes/esp8/"

# nom courant (minuscules) -> (slug ou None, nom latin, nom affiché). Les slugs viennent de especes-us.json.
ESP = {
    "largemouth bass": ("largemouth-bass", "Micropterus salmoides", "Largemouth bass"),
    "florida largemouth bass": ("florida-bass", "Micropterus floridanus", "Florida largemouth bass"),
    "florida bass": ("florida-bass", "Micropterus floridanus", "Florida bass"),
    "smallmouth bass": ("smallmouth-bass", "Micropterus dolomieu", "Smallmouth bass"),
    "spotted bass": ("spotted-bass", "Micropterus punctulatus", "Spotted bass"),
    "guadalupe bass": ("guadalupe-bass", "Micropterus treculii", "Guadalupe bass"),
    "alabama bass": (None, "Micropterus henshalli", "Alabama bass"),
    "striped bass": ("striped-bass", "Morone saxatilis", "Striped bass"),
    "white bass": ("white-bass", "Morone chrysops", "White bass"),
    "hybrid striped bass": ("wiper", "Morone chrysops x Morone saxatilis", "Hybrid striped bass"),
    "wiper": ("wiper", "Morone chrysops x Morone saxatilis", "Wiper (hybrid striped bass)"),
    "palmetto bass": ("wiper", "Morone saxatilis x Morone chrysops", "Palmetto bass (hybrid striped bass)"),
    "sunshine bass": ("wiper", "Morone chrysops x Morone saxatilis", "Sunshine bass (hybrid striped bass)"),
    "bluegill": ("bluegill", "Lepomis macrochirus", "Bluegill"),
    "pumpkinseed": ("pumpkinseed", "Lepomis gibbosus", "Pumpkinseed"),
    "redear sunfish": ("redear-sunfish", "Lepomis microlophus", "Redear sunfish"),
    "green sunfish": ("green-sunfish", "Lepomis cyanellus", "Green sunfish"),
    "longear sunfish": ("longear-sunfish", "Lepomis megalotis", "Longear sunfish"),
    "warmouth": ("warmouth", "Lepomis gulosus", "Warmouth"),
    "redbreast sunfish": ("redbreast-sunfish", "Lepomis auritus", "Redbreast sunfish"),
    "rock bass": ("rock-bass", "Ambloplites rupestris", "Rock bass"),
    "white crappie": ("white-crappie", "Pomoxis annularis", "White crappie"),
    "black crappie": ("black-crappie", "Pomoxis nigromaculatus", "Black crappie"),
    "yellow bass": ("yellow-bass", "Morone mississippiensis", "Yellow bass"),
    "white perch": ("white-perch", "Morone americana", "White perch"),
    "walleye": ("walleye", "Sander vitreus", "Walleye"),
    "sauger": ("sauger", "Sander canadensis", "Sauger"),
    "saugeye": ("saugeye", "Sander vitreus x Sander canadensis", "Saugeye"),
    "yellow perch": ("yellow-perch", "Perca flavescens", "Yellow perch"),
    "channel catfish": ("channel-catfish", "Ictalurus punctatus", "Channel catfish"),
    "blue catfish": ("blue-catfish", "Ictalurus furcatus", "Blue catfish"),
    "flathead catfish": ("flathead-catfish", "Pylodictis olivaris", "Flathead catfish"),
    "white catfish": ("white-catfish", "Ameiurus catus", "White catfish"),
    "black bullhead": ("black-bullhead", "Ameiurus melas", "Black bullhead"),
    "yellow bullhead": ("yellow-bullhead", "Ameiurus natalis", "Yellow bullhead"),
    "brown bullhead": ("brown-bullhead", "Ameiurus nebulosus", "Brown bullhead"),
    "northern pike": ("northern-pike", "Esox lucius", "Northern pike"),
    "muskellunge": ("muskellunge", "Esox masquinongy", "Muskellunge"),
    "tiger muskie": ("tiger-muskie", "Esox masquinongy x Esox lucius", "Tiger muskie"),
    "chain pickerel": ("chain-pickerel", "Esox niger", "Chain pickerel"),
    "rainbow trout": ("rainbow-trout", "Oncorhynchus mykiss", "Rainbow trout"),
    "brown trout": ("brown-trout", "Salmo trutta", "Brown trout"),
    "brook trout": ("brook-trout", "Salvelinus fontinalis", "Brook trout"),
    "cutthroat trout": ("cutthroat-trout", "Oncorhynchus clarkii", "Cutthroat trout"),
    "colorado river cutthroat trout": ("cutthroat-trout", "Oncorhynchus clarkii pleuriticus", "Colorado River cutthroat trout"),
    "greenback cutthroat trout": ("cutthroat-trout", "Oncorhynchus clarkii stomias", "Greenback cutthroat trout"),
    "rio grande cutthroat trout": ("cutthroat-trout", "Oncorhynchus clarkii virginalis", "Rio Grande cutthroat trout"),
    "snake river cutthroat trout": ("cutthroat-trout", "Oncorhynchus clarkii behnkei", "Snake River cutthroat trout"),
    "lake trout": ("lake-trout", "Salvelinus namaycush", "Lake trout"),
    "arctic char": ("arctic-char", "Salvelinus alpinus", "Arctic char"),
    "chinook salmon": ("chinook-salmon", "Oncorhynchus tshawytscha", "Chinook salmon"),
    "coho salmon": ("coho-salmon", "Oncorhynchus kisutch", "Coho salmon"),
    "kokanee salmon": ("sockeye-salmon", "Oncorhynchus nerka", "Kokanee salmon"),
    "arctic grayling": ("arctic-grayling", "Thymallus arcticus", "Arctic grayling"),
    "mountain whitefish": ("mountain-whitefish", "Prosopium williamsoni", "Mountain whitefish"),
    "common carp": ("common-carp", "Cyprinus carpio", "Common carp"),
    "grass carp": ("grass-carp", "Ctenopharyngodon idella", "Grass carp"),
    "bighead carp": ("bighead-carp", "Hypophthalmichthys nobilis", "Bighead carp"),
    "silver carp": ("silver-carp", "Hypophthalmichthys molitrix", "Silver carp"),
    "goldfish": ("goldfish", "Carassius auratus", "Goldfish"),
    "bigmouth buffalo": ("bigmouth-buffalo", "Ictiobus cyprinellus", "Bigmouth buffalo"),
    "smallmouth buffalo": ("smallmouth-buffalo", "Ictiobus bubalus", "Smallmouth buffalo"),
    "white sucker": ("white-sucker", "Catostomus commersonii", "White sucker"),
    "freshwater drum": ("freshwater-drum", "Aplodinotus grunniens", "Freshwater drum"),
    "longnose gar": ("longnose-gar", "Lepisosteus osseus", "Longnose gar"),
    "spotted gar": ("spotted-gar", "Lepisosteus oculatus", "Spotted gar"),
    "alligator gar": ("alligator-gar", "Atractosteus spatula", "Alligator gar"),
    "bowfin": ("bowfin", "Amia calva", "Bowfin"),
    "northern snakehead": ("northern-snakehead", "Channa argus", "Northern snakehead"),
    "paddlefish": ("paddlefish", "Polyodon spathula", "Paddlefish"),
    "shovelnose sturgeon": ("shovelnose-sturgeon", "Scaphirhynchus platorynchus", "Shovelnose sturgeon"),
    "american eel": ("american-eel", "Anguilla rostrata", "American eel"),
    "blue tilapia": ("blue-tilapia", "Oreochromis aureus", "Blue tilapia"),
    "burbot": ("burbot", "Lota lota", "Burbot"),
    "cutbow": (None, "Oncorhynchus mykiss x Oncorhynchus clarkii", "Cutbow"),
    "golden trout": (None, "Oncorhynchus aguabonita", "Golden trout"),
    "splake": (None, "Salvelinus namaycush x Salvelinus fontinalis", "Splake"),
    "tiger trout": (None, "Salmo trutta x Salvelinus fontinalis", "Tiger trout"),
    "tench": (None, "Tinca tinca", "Tench"),
    "longnose sucker": (None, "Catostomus catostomus", "Longnose sucker"),
    "sacramento perch": (None, "Archoplites interruptus", "Sacramento perch"),
    "rio grande cichlid": (None, "Herichthys cyanoguttatus", "Rio Grande cichlid"),
    "peacock bass": ("peacock-bass", "Cichla ocellaris", "Peacock bass"),
    "tiger muskellunge": ("tiger-muskie", "Esox masquinongy x Esox lucius", "Tiger muskie"),
    "triploid grass carp": ("grass-carp", "Ctenopharyngodon idella", "Grass carp"),
    "warmouth sunfish": ("warmouth", "Lepomis gulosus", "Warmouth"),
    "orangespotted sunfish": (None, "Lepomis humilis", "Orangespotted sunfish"),
    "nile perch": (None, "Lates niloticus", "Nile perch"),
    "kemp's largemouth bass": ("largemouth-bass", "Micropterus salmoides", "Largemouth bass"),
    "mixed largemouth bass": ("largemouth-bass", "Micropterus salmoides", "Largemouth bass"),
    "blue sucker": (None, "Cycleptus elongatus", "Blue sucker"),
}
# Espèces de la liste de l'agence qui ne sont pas des poissons de pêche sportive (fiche « non pêchable » ou espèce protégée) : exclues.


def resoudre(nom):
    """(slug, latin, nom) pour un nom courant, ou None."""
    k = re.sub(r"\s+", " ", nom.strip().lower())
    k = re.sub(r"\s*\(.*?\)", "", k)
    return ESP.get(k)


def entree(nom, zone, preuve, src, confiance="officielle", n=None, annee_max=None):
    r = resoudre(nom)
    if r is None:
        return None
    e = {"slug": r[0], "nom": r[2], "latin": r[1], "zone": zone, "preuve": preuve, "src": src, "confiance": confiance}
    if n is not None:
        e["n"] = n
    if annee_max is not None:
        e["annee_max"] = annee_max
    return e


def telecharger(url, pause=0.3):
    time.sleep(pause)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    return urllib.request.urlopen(req, timeout=40).read().decode("utf-8", "replace")


def ecrire(etat, producteur, sources, entrees, dossier=None):
    d = {"format": "fishme-especes-us/1", "etat": etat, "producteur": producteur, "date": DATE,
         "sources": sources, "entrees": entrees}
    dossier = dossier or SORTIE
    os.makedirs(dossier, exist_ok=True)
    chemin = os.path.join(dossier, f"{etat}-{producteur}.json")
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return chemin, os.path.getsize(chemin)


def src(nom, url, licence="non précisée", date=DATE):
    return {"nom": nom, "url": url, "licence": licence, "date": date}
