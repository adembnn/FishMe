#!/usr/bin/env python3
"""US16 groupe esp-6 : <USPS>-agence.json pour WI, MO, IA depuis les pages publiques des agences.
MI (michigan.gov, Akamai « Access Denied ») et MN (dnr.state.mn.us, Cloudflare « Just a moment ») : 403, jamais contournés, aucun fichier.
Usage : python3 esp6_agence.py WI MO IA   (réseau ; cache hors git dans /private/tmp/claude-501/brut-us/especes/)
Une espèce n'est écrite que si son nom figure dans le texte de la page citée (contrôle fait à chaque exécution).
Le mot « rare » etc. n'est jamais écrit (verifier_zones.py)."""
import json, os, re, sys, html, time, urllib.parse, urllib.request, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from esp6_fetchlib import get, UA, BRUT

ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.normpath(os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us"))
DATE = "2026-11-08"
ESP = {e["slug"]: e for e in json.load(open(os.path.join(ICI, "..", "especes-us.json"), encoding="utf-8"))}
# espèces absentes de especes-us.json : slug null, latin donné ici
HORS = {
    "emerald-bowfin": ("Emerald bowfin", "Amia ocellicauda"),
    "black-buffalo": ("Black buffalo", "Ictiobus niger"),
    "black-carp": ("Black carp", "Mylopharyngodon piceus"),
    "wb-x-bluegill": ("Green sunfish x bluegill", "Lepomis cyanellus x Lepomis macrochirus"),
    "pumpkinseed-x-bluegill": ("Pumpkinseed x bluegill", "Lepomis gibbosus x Lepomis macrochirus"),
    "splake": ("Splake", "Salvelinus namaycush x Salvelinus fontinalis"),
}


def texte(url):
    code, t = get(url)
    if code != 200:
        raise SystemExit(f"{url} : HTTP {code}")
    t = re.sub(r"(?s)<(script|style)[^>]*>.*?</\1>", " ", t)
    return html.unescape(re.sub(r"<[^>]+>", " ", t))


def entree(cle, zone, preuve, src, n=None, annee=None):
    if cle in ESP:
        e = ESP[cle]
        nom, latin, slug = e["nom_en"], e["latin"], cle
    else:
        nom, latin = HORS[cle]
        slug = None
    d = {"slug": slug, "nom": nom, "latin": latin, "zone": zone, "preuve": preuve, "src": src, "confiance": "officielle"}
    if n is not None:
        d["n"] = n
    if annee:
        d["annee_max"] = annee
    return d


def ecrire(usps, sources, entrees):
    doc = {"format": "fishme-especes-us/1", "etat": usps, "producteur": "agence", "date": DATE, "sources": sources, "entrees": entrees}
    os.makedirs(SORTIE, exist_ok=True)
    p = os.path.join(SORTIE, f"{usps}-agence.json")
    json.dump(doc, open(p, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    etat = sum(1 for e in entrees if e["zone"]["type"] == "etat")
    print(usps, "niveau État :", etat, "; plan d'eau/bassin :", len(entrees) - etat, "; ", os.path.getsize(p) // 1024, "Ko")


def src(nom, url):
    return {"nom": nom, "url": url, "licence": "non précisée", "date": DATE}


def liste_etat(usps, nom_etat, pages):
    """pages : [(url, nom, [(regex dans la page, clé espèce)])] -> (sources, entrées niveau État)"""
    sources, entrees, vus = [], [], set()
    for url, nom, motifs in pages:
        t = texte(url)
        i = len(sources)
        sources.append(src(nom, url))
        trouve = False
        for motif, cle in motifs:
            if re.search(motif, t, re.I):
                if cle not in vus:
                    vus.add(cle)
                    entrees.append(entree(cle, {"type": "etat", "id": usps, "nom": nom_etat}, "liste_agence", i))
                trouve = True
            else:
                print("  absent de la page, écarté :", cle, "<-", url)
        if not trouve:
            raise SystemExit("page sans aucune espèce attendue : " + url)
    return sources, entrees


# ---------------------------------------------------------------- Wisconsin
WI = "https://dnr.wisconsin.gov/topic/fishing/species/"
WI_PAGES = [
    ("https://dnr.wisconsin.gov/topic/fishing/species", "Wisconsin DNR, Wisconsin's Fishes (poissons de pêche sportive)", [
        (r"Largemouth bass", "largemouth-bass"), (r"Smallmouth bass", "smallmouth-bass"), (r"Black crappie", "black-crappie"),
        (r"Bluegill", "bluegill"), (r"Pumpkinseed", "pumpkinseed"), (r"Lake sturgeon", "lake-sturgeon"), (r"Musky", "muskellunge"),
        (r"Northern pike", "northern-pike"), (r"Walleye", "walleye"), (r"Yellow perch", "yellow-perch")]),
    (WI + "catfish.html", "Wisconsin DNR, Channel and Flathead catfish", [(r"Channel", "channel-catfish"), (r"Flathead", "flathead-catfish")]),
    (WI + "bullhead.html", "Wisconsin DNR, Bullheads (Brown, Yellow and Black)", [(r"Brown", "brown-bullhead"), (r"Yellow", "yellow-bullhead"), (r"Black", "black-bullhead")]),
    (WI + "troutsalmon.html", "Wisconsin DNR, Trout and salmon", [
        (r"Brook trout", "brook-trout"), (r"Brown trout", "brown-trout"), (r"Chinook salmon", "chinook-salmon"),
        (r"Coho salmon", "coho-salmon"), (r"Lake trout", "lake-trout"), (r"Rainbow trout", "rainbow-trout")]),
    (WI + "snakehead.html", "Wisconsin DNR, Burbot, bowfin and snakehead identification (natives : bowfin, burbot)", [(r"Bowfin \(native\)", "bowfin"), (r"Burbot \(native\)", "burbot")]),
]
WI_STOCK = {  # nom de la base d'empoissonnement -> clé (les poissons fourrage ne sont pas gardés)
    "BLACK CRAPPIE": "black-crappie", "BLUEGILL": "bluegill", "BROOK TROUT": "brook-trout", "BROWN TROUT": "brown-trout",
    "CHANNEL CATFISH": "channel-catfish", "CHINOOK SALMON": "chinook-salmon", "COHO SALMON": "coho-salmon",
    "GREEN SUNFISH X BLUEGILL": "wb-x-bluegill", "LAKE STURGEON": "lake-sturgeon", "LAKE TROUT": "lake-trout",
    "LARGEMOUTH BASS": "largemouth-bass", "MUSKELLUNGE": "muskellunge", "NORTHERN PIKE": "northern-pike",
    "NORTHERN PIKE X MUSKELLUNGE": "tiger-muskie", "PUMPKINSEED": "pumpkinseed", "PUMPKINSEED X BLUEGILL": "pumpkinseed-x-bluegill",
    "RAINBOW TROUT": "rainbow-trout", "SMALLMOUTH BASS": "smallmouth-bass", "SPLAKE (I22 X I23)": "splake", "WALLEYE": "walleye",
    "YELLOW PERCH": "yellow-perch"}
WI_BASE = "https://apps.dnr.wi.gov/fisheriesmanagement/Public/Summary/"
ANNEES = range(2024, 2026)


def wi_empoissonnement(annee):
    f = os.path.join(BRUT, f"wi-stock-{annee}.json")
    if os.path.exists(f):
        return json.load(open(f))
    rows, debut = [], 0
    while True:
        time.sleep(0.3)
        d = urllib.parse.urlencode({"draw": 1, "start": debut, "length": 1000, "STOCKING_YEAR": str(annee), "SPECIES_NAME": "", "COUNTY_CODE": "", "STOCKED_WB_NAME": "", "STOCKED_WB_WBIC": "", "LOCAL_WB_NAME": ""}).encode()
        r = urllib.request.urlopen(urllib.request.Request(WI_BASE + "LoadResults", data=d, headers={"User-Agent": UA, "X-Requested-With": "XMLHttpRequest"}), timeout=120)
        j = json.loads(r.read().decode())
        rows += j["data"]
        debut += 1000
        if debut >= j["recordsFiltered"]:
            break
    json.dump(rows, open(f, "w"))
    return rows


def titre(s):
    s = " ".join(w.capitalize() if not re.match(r"^(I|II|III)$", w) else w for w in (s or "").lower().split())
    return re.sub(r"\b(Of|De|Du|La|Le|Des)\b", lambda m: m.group(1).lower(), s) if False else s


def faire_wi():
    sources, entrees = liste_etat("WI", "Wisconsin", WI_PAGES)
    i = len(sources)
    sources.append(src(f"Wisconsin DNR, Fish Stocking Summary (base publique, années {ANNEES[0]} à {ANNEES[-1]} : espèce, plan d'eau, année)", "https://apps.dnr.wi.gov/fisheriesmanagement/Public/Summary/Index"))
    agg = collections.OrderedDict()
    for a in ANNEES:
        for r in wi_empoissonnement(a):
            cle = WI_STOCK.get(r["SPECIES_NAME"])
            if not cle or not r.get("STOCKED_WBIC") or str(r["STOCKED_WBIC"]) == "99999" or not (r.get("STOCKED_WB_NAME") or "").strip():
                continue
            k = (str(r["STOCKED_WBIC"]), cle)
            x = agg.setdefault(k, {"nom": r["STOCKED_WB_NAME"], "comte": r.get("STOCKED_COUNTY_NAME"), "n": 0, "y": 0})
            x["n"] += 1
            x["y"] = max(x["y"], int(r["STOCKING_YEAR"]))
    for (wbic, cle), x in sorted(agg.items(), key=lambda kv: (kv[1]["nom"] or "", kv[0])):
        nom = titre(x["nom"]) + (f" ({x['comte']} Co.)" if x["comte"] else "")
        entrees.append(entree(cle, {"type": "plan_eau", "id": f"wbic:{wbic}", "nom": nom}, "empoissonnement", i, x["n"], x["y"]))
    ecrire("WI", sources, entrees)


# ---------------------------------------------------------------- Missouri
MO = "https://mdc.mo.gov/fishing/species/"


def p(slug, nom, motifs):
    return (MO + slug, "Missouri Department of Conservation, Fishing Species A-Z : " + nom, motifs)


MO_PAGES = [
    p("black-bass", "Black Bass", [(r"Largemouth Bass", "largemouth-bass"), (r"Smallmouth Bass", "smallmouth-bass"), (r"Spotted Bass", "spotted-bass")]),
    p("crappie", "Crappie", [(r"Black Crappie", "black-crappie"), (r"White Crappie", "white-crappie")]),
    p("catfish", "Catfish", [(r"Blue Catfish", "blue-catfish"), (r"Channel Catfish", "channel-catfish"), (r"Flathead Catfish", "flathead-catfish")]),
    p("bullhead", "Bullhead", [(r"Yellow Bullhead", "yellow-bullhead"), (r"Brown Bullhead", "brown-bullhead"), (r"Black Bullhead", "black-bullhead")]),
    p("sunfish", "Sunfish", [(r"Redear Sunfish", "redear-sunfish"), (r"Longear Sunfish", "longear-sunfish"), (r"Green Sunfish", "green-sunfish"), (r"Bluegill", "bluegill")]),
    p("goggle-eye-rock-bass-warmouth", "Goggle-eye (Rock Bass) and Warmouth", [(r"Rock Bass", "rock-bass"), (r"Warmouth", "warmouth")]),
    p("temperate-bass", "Temperate Bass", [(r"White Bass", "white-bass"), (r"Striped Bass", "striped-bass"), (r"Hybrid Striped Bass", "wiper")]),
    p("trout", "Trout", [(r"Brown Trout", "brown-trout"), (r"Rainbow Trout", "rainbow-trout")]),
    p("walleye-sauger", "Walleye and Sauger", [(r"Walleye", "walleye"), (r"Sauger", "sauger")]),
    p("northern-pike", "Northern Pike", [(r"Northern Pike", "northern-pike")]),
    p("muskellunge", "Muskellunge", [(r"Muskellunge", "muskellunge")]),
    p("pickerel", "Pickerel", [(r"Chain Pickerel", "chain-pickerel"), (r"Grass Pickerel", "grass-pickerel")]),
    p("paddlefish", "Paddlefish", [(r"Paddlefish", "paddlefish")]),
    p("shovelnose-sturgeon", "Shovelnose Sturgeon", [(r"Shovelnose Sturgeon", "shovelnose-sturgeon")]),
    p("freshwater-drum", "Freshwater Drum", [(r"Freshwater Drum", "freshwater-drum")]),
    p("gar", "Gar", [(r"Longnose gar", "longnose-gar"), (r"Alligator gar", "alligator-gar")]),
    p("bowfin", "Bowfin", [(r"Emerald Bowfin", "emerald-bowfin")]),
    p("buffalo", "Buffalo", [(r"Smallmouth Buffalo", "smallmouth-buffalo"), (r"Bigmouth Buffalo", "bigmouth-buffalo"), (r"Black Buffalo", "black-buffalo")]),
    p("carp", "Carp", [(r"Common Carp", "common-carp"), (r"Bighead Carp", "bighead-carp"), (r"Black Carp", "black-carp")]),
    p("suckers", "Suckers", [(r"White Sucker", "white-sucker")]),
]
MO_PARCS = ["Maramec Spring Park", "Bennett Spring State Park", "Montauk State Park", "Roaring River State Park"]


def faire_mo():
    sources, entrees = liste_etat("MO", "Missouri", MO_PAGES)
    t = texte(MO + "trout")
    i = [k for k, s in enumerate(sources) if s["url"].endswith("/trout")][0]
    m = re.search(r"open only in the following trout parks:([^.]*)\.", t)
    if not m:
        raise SystemExit("MO : phrase des parcs à truites absente")
    for parc in MO_PARCS:
        if parc in m.group(1):
            for cle in ("rainbow-trout", "brown-trout"):
                entrees.append(entree(cle, {"type": "plan_eau", "id": parc, "nom": parc}, "liste_agence", i))
        else:
            print("  parc absent de la page :", parc)
    ecrire("MO", sources, entrees)


# ---------------------------------------------------------------- Iowa
IA = "https://www.iowadnr.gov/things-do/fishing/"
IA_PAGES = [
    (IA + "iowa-fish-species", "Iowa DNR, Iowa Fish Species", [
        (r"Bluegill", "bluegill"), (r"Bullheads", "black-bullhead"), (r"Bullheads", "yellow-bullhead"), (r"Bullheads", "brown-bullhead"),
        (r"Channel Catfish", "channel-catfish"), (r"Two species of crappie", "black-crappie"), (r"Two species of crappie", "white-crappie"),
        (r"Hybrid Striped Bass", "wiper"), (r"Largemouth Bass", "largemouth-bass"), (r"Muskie", "muskellunge"), (r"Smallmouth Bass", "smallmouth-bass"),
        (r"native brook trout and the naturalized rainbow and brown trout", "brook-trout"), (r"native brook trout and the naturalized rainbow and brown trout", "rainbow-trout"),
        (r"native brook trout and the naturalized rainbow and brown trout", "brown-trout"), (r"Walleye", "walleye"), (r"Yellow Bass", "yellow-bass"),
        (r"Yellow Perch", "yellow-perch"), (r"northern pike", "northern-pike"), (r"white bass and yellow bass are native", "white-bass"),
        (r"walleye, sauger and yellow perch", "sauger"), (r"grass pickerel", "grass-pickerel"), (r"paddlefish", "paddlefish"), (r"bowfin", "bowfin"),
        (r"freshwater drum", "freshwater-drum")]),
]
IA_TRUITES = [("South Pine Creek", "brook-trout"), ("French Creek", "brown-trout"), ("West Branch French Creek", "brown-trout"),
              ("Casey Springs", "brook-trout"), ("Falcon Springs", "brook-trout"), ("Pine Spring Creek", "brook-trout")]


def faire_ia():
    sources, entrees = liste_etat("IA", "Iowa", IA_PAGES)
    u = IA + "where-fish/trout-fishing"
    t = texte(u)
    i = len(sources)
    sources.append(src("Iowa DNR, Trout Fishing (cours d'eau à truite : espèce indiquée par l'agence)", u))
    for nom, cle in IA_TRUITES:
        mot = "Brook Trout only" if cle == "brook-trout" else "Brown Trout only"
        if re.search(re.escape(nom) + r"\s*\(" + mot + r"\)", t):
            entrees.append(entree(cle, {"type": "plan_eau", "id": nom, "nom": nom}, "liste_agence", i))
        else:
            print("  cours d'eau absent de la page :", nom)
    ecrire("IA", sources, entrees)


if __name__ == "__main__":
    for usps in sys.argv[1:]:
        {"WI": faire_wi, "MO": faire_mo, "IA": faire_ia}[usps]()
