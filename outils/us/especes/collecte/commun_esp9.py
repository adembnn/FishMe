"""Outils communs de collecte (US16 vague 2, groupe esp-9 : WY MT ID UT NV).
Réseau poli : User-Agent FishMe-data, pause >= 0,25 s ; bruts hors git dans BRUT. Aucune clé d'API."""
import json, os, re, time, urllib.error, urllib.request

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.normpath(os.path.join(ICI, "..", "..", "..", ".."))
SORTIE = os.path.join(RACINE, "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
BRUT = "/private/tmp/claude-501/brut-us/especes/esp-9/"
UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
DATE = "2026-11-08"

# Nom d'usage (en minuscules, simplifié) -> (slug ou None, nom affiché, latin valide)
ESPECES = {
    "arctic grayling": ("arctic-grayling", "Arctic grayling", "Thymallus arcticus"),
    "grayling": ("arctic-grayling", "Arctic grayling", "Thymallus arcticus"),
    "black bullhead": ("black-bullhead", "Black bullhead", "Ameiurus melas"),
    "yellow bullhead": ("yellow-bullhead", "Yellow bullhead", "Ameiurus natalis"),
    "burbot": ("burbot", "Burbot", "Lota lota"),
    "channel catfish": ("channel-catfish", "Channel catfish", "Ictalurus punctatus"),
    "flathead catfish": ("flathead-catfish", "Flathead catfish", "Pylodictis olivaris"),
    "cutthroat trout": ("cutthroat-trout", "Cutthroat trout", "Oncorhynchus clarkii"),
    "cutthroat": ("cutthroat-trout", "Cutthroat trout", "Oncorhynchus clarkii"),
    "mountain whitefish": ("mountain-whitefish", "Mountain whitefish", "Prosopium williamsoni"),
    "sauger": ("sauger", "Sauger", "Sander canadensis"),
    "shovelnose sturgeon": ("shovelnose-sturgeon", "Shovelnose sturgeon", "Scaphirhynchus platorynchus"),
    "stonecat": (None, "Stonecat", "Noturus flavus"),
    "black crappie": ("black-crappie", "Black crappie", "Pomoxis nigromaculatus"),
    "white crappie": ("white-crappie", "White crappie", "Pomoxis annularis"),
    "bluegill": ("bluegill", "Bluegill", "Lepomis macrochirus"),
    "brook trout": ("brook-trout", "Brook trout", "Salvelinus fontinalis"),
    "brown trout": ("brown-trout", "Brown trout", "Salmo trutta"),
    "freshwater drum": ("freshwater-drum", "Freshwater drum", "Aplodinotus grunniens"),
    "golden trout": (None, "Golden trout", "Oncorhynchus aguabonita"),
    "green sunfish": ("green-sunfish", "Green sunfish", "Lepomis cyanellus"),
    "kokanee": ("sockeye-salmon", "Kokanee (landlocked sockeye salmon)", "Oncorhynchus nerka"),
    "lake trout": ("lake-trout", "Lake trout", "Salvelinus namaycush"),
    "largemouth bass": ("largemouth-bass", "Largemouth bass", "Micropterus salmoides"),
    "smallmouth bass": ("smallmouth-bass", "Smallmouth bass", "Micropterus dolomieu"),
    "striped bass": ("striped-bass", "Striped bass", "Morone saxatilis"),
    "white bass": ("white-bass", "White bass", "Morone chrysops"),
    "wiper": ("wiper", "Wiper (hybrid striped bass)", "Morone chrysops x Morone saxatilis"),
    "northern pike": ("northern-pike", "Northern pike", "Esox lucius"),
    "ohrid trout": (None, "Ohrid trout", "Salmo letnica"),
    "pumpkinseed": ("pumpkinseed", "Pumpkinseed", "Lepomis gibbosus"),
    "rainbow trout": ("rainbow-trout", "Rainbow trout", "Oncorhynchus mykiss"),
    "rainbow": ("rainbow-trout", "Rainbow trout", "Oncorhynchus mykiss"),
    "rock bass": ("rock-bass", "Rock bass", "Ambloplites rupestris"),
    "walleye": ("walleye", "Walleye", "Sander vitreus"),
    "yellow perch": ("yellow-perch", "Yellow perch", "Perca flavescens"),
    "redear sunfish": ("redear-sunfish", "Redear sunfish", "Lepomis microlophus"),
    "tiger muskie": ("tiger-muskie", "Tiger muskie", "Esox masquinongy x Esox lucius"),
    "muskie tiger": ("tiger-muskie", "Tiger muskie", "Esox masquinongy x Esox lucius"),
    "tiger trout": (None, "Tiger trout (brook x brown)", "Salmo trutta x Salvelinus fontinalis"),
    "splake": (None, "Splake (lake x brook trout)", "Salvelinus namaycush x Salvelinus fontinalis"),
    "grass carp": ("grass-carp", "Grass carp", "Ctenopharyngodon idella"),
    "common carp": ("common-carp", "Common carp", "Cyprinus carpio"),
    "cisco": ("cisco", "Cisco", "Coregonus artedi"),
    "bonneville cisco": (None, "Bonneville cisco", "Prosopium gemmifer"),
    "bonneville whitefish": (None, "Bonneville whitefish", "Prosopium spilonotus"),
    "sacramento perch": (None, "Sacramento perch", "Archoplites interruptus"),
    "white sucker": ("white-sucker", "White sucker", "Catostomus commersonii"),
    "utah sucker": (None, "Utah sucker", "Catostomus ardens"),
    "utah chub": (None, "Utah chub", "Gila atraria"),
    "carp": ("common-carp", "Common carp", "Cyprinus carpio"),
    "splake trout": (None, "Splake (lake x brook trout)", "Salvelinus namaycush x Salvelinus fontinalis"),
    "tiger muskellunge": ("tiger-muskie", "Tiger muskie", "Esox masquinongy x Esox lucius"),
    "hybrid sunfish": (None, "Hybrid sunfish", "Lepomis spp. (hybride)"),
    "bullhead": (None, "Bullhead (Ameiurus spp.)", "Ameiurus spp."),
}


def trouver(nom):
    """Nom lu dans une page de l'agence -> (slug, nom, latin) ou None."""
    n = re.sub(r"\s+", " ", re.sub(r"\(.*?\)", "", nom)).strip().lower()
    n = {"crappie white": "white crappie", "crappie black": "black crappie", "grayling arctic": "arctic grayling",
         "grass carp sterile": "grass carp"}.get(n, n)
    if n.startswith("kokanee"):
        n = "kokanee"
    if n.endswith("cutthroat") or n.endswith("cutthroat trout") or n.startswith("cutthroat"):
        n = "cutthroat trout"
    return ESPECES.get(n)


def lire(url, nom_cache=None, data=None, pause=0.3):
    """GET (ou POST si data) poli ; met en cache dans BRUT si nom_cache."""
    os.makedirs(BRUT, exist_ok=True)
    if nom_cache and os.path.exists(BRUT + nom_cache):
        return open(BRUT + nom_cache, encoding="utf-8", errors="ignore").read()
    for essai in range(4):
        try:
            r = urllib.request.urlopen(urllib.request.Request(url, data=data, headers={"User-Agent": UA}), timeout=60)
            t = r.read().decode("utf-8", "ignore")
            break
        except urllib.error.HTTPError as e:
            if e.code < 500 or essai == 3:
                raise
            time.sleep(3 * (essai + 1))
    if nom_cache:
        open(BRUT + nom_cache, "w", encoding="utf-8").write(t)
    time.sleep(pause)
    return t


def texte_lignes(h):
    import html as H
    b = re.sub(r"<(script|style)[^>]*>.*?</\1>", "", h, flags=re.S | re.I)
    b = re.sub(r"<[^>]+>", "\n", b)
    return [H.unescape(l).replace("\xa0", " ").strip() for l in b.split("\n") if H.unescape(l).replace("\xa0", " ").strip()]


def titre(nom):
    """Nom de plan d'eau MAJUSCULES -> casse lisible (sans coordonnées, nom public seulement)."""
    mots = re.sub(r"\s+", " ", nom.strip()).title()
    return mots.replace("'S", "'s")


def entree(esp, zone_type, zone_id, zone_nom, preuve, src, n=None, annee_max=None, confiance="officielle"):
    slug, nom, latin = esp
    e = {"slug": slug, "nom": nom, "latin": latin,
         "zone": {"type": zone_type, "id": zone_id, "nom": zone_nom},
         "preuve": preuve, "src": src, "confiance": confiance}
    if n is not None:
        e["n"] = n
    if annee_max is not None:
        e["annee_max"] = annee_max
    return e


def ecrire(usps, producteur, sources, entrees):
    os.makedirs(SORTIE, exist_ok=True)
    d = {"format": "fishme-especes-us/1", "etat": usps, "producteur": producteur, "date": DATE,
         "sources": sources, "entrees": entrees}
    p = os.path.join(SORTIE, f"{usps}-{producteur}.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return p, os.path.getsize(p)


def agreger_empoissonnement(lignes, esp_de, usps, src, zone_prefixe=""):
    """lignes : (nom_eau, espece_brute, annee). Une entrée par (eau, espèce) : n = nombre de lâchers, annee_max."""
    agg = {}
    for eau, esp_brute, annee in lignes:
        esp = esp_de(esp_brute)
        if not esp:
            continue
        k = (eau, esp[2])
        a = agg.setdefault(k, [esp, 0, 0])
        a[1] += 1
        a[2] = max(a[2], annee)
    out = []
    for (eau, _), (esp, n, an) in sorted(agg.items()):
        nom = titre(eau)
        out.append(entree(esp, "plan_eau", nom, nom, "empoissonnement", src, n=n, annee_max=an))
    return out
