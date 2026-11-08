"""Outils communs des collecteurs d'espèces par État (lot us-esp, groupe esp-4).
Noms scientifiques : nom valide (ITIS / AFS) rattaché au nom usuel ; la page de l'agence est la source du nom usuel et de la zone."""
import json, os, re, time, urllib.request

ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
DATE = "2026-11-08"

LATIN = {
 "largemouth bass": "Micropterus salmoides", "smallmouth bass": "Micropterus dolomieu", "spotted bass": "Micropterus punctulatus",
 "alabama bass": "Micropterus henshalli", "shoal bass": "Micropterus cataractae", "redeye bass": "Micropterus coosae",
 "redeye (bartram's) bass": "Micropterus coosae", "suwannee bass": "Micropterus notius",
 "spotted (alabama) bass": "Micropterus punctulatus",
 "bluegill": "Lepomis macrochirus", "redear sunfish": "Lepomis microlophus", "redear sunfish (shellcracker)": "Lepomis microlophus",
 "redear": "Lepomis microlophus", "redbreast sunfish": "Lepomis auritus", "redbreast": "Lepomis auritus", "green sunfish": "Lepomis cyanellus",
 "longear sunfish": "Lepomis megalotis", "warmouth": "Lepomis gulosus", "pumpkinseed": "Lepomis gibbosus",
 "dollar sunfish": "Lepomis marginatus", "orangespotted sunfish": "Lepomis humilis", "redspotted sunfish": "Lepomis miniatus",
 "spotted sunfish": "Lepomis punctatus", "flier": "Centrarchus macropterus", "banded sunfish": "Enneacanthus obesus",
 "bluespotted sunfish": "Enneacanthus gloriosus", "mud sunfish": "Acantharchus pomotis",
 "rock bass": "Ambloplites rupestris", "shadow bass": "Ambloplites ariommus",
 "black crappie": "Pomoxis nigromaculatus", "white crappie": "Pomoxis annularis",
 "striped bass": "Morone saxatilis", "white bass": "Morone chrysops", "yellow bass": "Morone mississippiensis",
 "white perch": "Morone americana", "hybrid striped bass": "Morone chrysops x Morone saxatilis", "hybrid bass": "Morone chrysops x Morone saxatilis",
 "sunshine bass": "Morone chrysops x Morone saxatilis",
 "walleye": "Sander vitreus", "sauger": "Sander canadensis", "yellow perch": "Perca flavescens",
 "channel catfish": "Ictalurus punctatus", "blue catfish": "Ictalurus furcatus", "flathead catfish": "Pylodictis olivaris",
 "white catfish": "Ameiurus catus", "black bullhead": "Ameiurus melas", "yellow bullhead": "Ameiurus natalis",
 "brown bullhead": "Ameiurus nebulosus", "snail bullhead": "Ameiurus brunneus", "spotted bullhead": "Ameiurus serracanthus",
 "chain pickerel": "Esox niger", "redfin pickerel": "Esox americanus americanus", "chain/redfin pickerel": "Esox niger",
 "rainbow trout": "Oncorhynchus mykiss", "brown trout": "Salmo trutta", "brook trout": "Salvelinus fontinalis",
 "common carp": "Cyprinus carpio", "grass carp": "Ctenopharyngodon idella", "bighead carp": "Hypophthalmichthys nobilis",
 "silver carp": "Hypophthalmichthys molitrix", "bigmouth buffalo": "Ictiobus cyprinellus", "smallmouth buffalo": "Ictiobus bubalus",
 "black buffalo": "Ictiobus niger", "freshwater drum": "Aplodinotus grunniens",
 "longnose gar": "Lepisosteus osseus", "spotted gar": "Lepisosteus oculatus", "alligator gar": "Atractosteus spatula",
 "shortnose gar": "Lepisosteus platostomus", "florida gar": "Lepisosteus platyrhincus",
 "bowfin": "Amia calva", "paddlefish": "Polyodon spathula", "shovelnose sturgeon": "Scaphirhynchus platorynchus",
 "american eel": "Anguilla rostrata", "american shad": "Alosa sapidissima", "gizzard shad": "Dorosoma cepedianum",
 "threadfin shad": "Dorosoma petenense", "blueback herring": "Alosa aestivalis", "hickory shad": "Alosa mediocris",
 "blue tilapia": "Oreochromis aureus", "butterfly peacock": "Cichla ocellaris", "jaguar guapote": "Parachromis managuensis",
 "mayan cichlid": "Mayaheros urophthalmus", "oscar": "Astronotus ocellatus",
}


def slugs_par_latin():
    p = os.path.join(ICI, "..", "especes-us.json")
    return {e["latin"]: e["slug"] for e in json.load(open(p, encoding="utf-8"))}


def latin_de(nom):
    return LATIN.get(re.sub(r"\s+", " ", nom.strip().lower()))


def entree(nom, latin, zone, preuve, src, confiance="officielle", n=None, annee_max=None, slugs=None):
    slugs = slugs if slugs is not None else slugs_par_latin()
    e = {"slug": slugs.get(latin), "nom": nom, "latin": latin, "zone": zone, "preuve": preuve, "src": src, "confiance": confiance}
    if n is not None:
        e["n"] = n
    if annee_max is not None:
        e["annee_max"] = annee_max
    return e


def ecrire(etat, producteur, sources, entrees, dossier=None):
    dossier = dossier or SORTIE
    os.makedirs(dossier, exist_ok=True)
    d = {"format": "fishme-especes-us/1", "etat": etat, "producteur": producteur, "date": DATE, "sources": sources, "entrees": entrees}
    chemin = os.path.join(dossier, f"{etat}-{producteur}.json")
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, indent=1)
        f.write("\n")
    return chemin


def telecharger(url, pause=0.3):
    time.sleep(max(pause, 0.25))
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    return urllib.request.urlopen(req, timeout=30).read().decode("utf-8", "replace")


def texte(html):
    t = re.sub(r"<script.*?</script>|<style.*?</style>|<[^>]+>", " ", html, flags=re.S)
    t = t.replace("&nbsp;", " ").replace("&amp;", "&").replace("&#039;", "'").replace("&rsquo;", "'").replace("’", "'")
    return re.sub(r"\s+", " ", t)


def noms_connus(bloc):
    """Découpe un texte « Nom1 Nom2 ... » en noms de la table LATIN (le plus long d'abord) ; mots inconnus sautés."""
    res, b = [], bloc.strip()
    while b:
        m = max((k for k in LATIN if b.lower().startswith(k)), key=len, default=None)
        if not m:
            b = " ".join(b.split()[1:])
            continue
        res.append(b[:len(m)])
        b = b[len(m):].strip()
    return res
