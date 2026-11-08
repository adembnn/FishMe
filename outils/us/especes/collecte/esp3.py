#!/usr/bin/env python3
"""US16 vague 2, groupe esp-3 (MD, DC, VA, WV, NC) : espèces signalées d'après les pages des agences.
Faits et noms seulement. Usage : python3 -I esp3.py [dossier de sortie]  (réseau ; bruts dans /private/tmp/claude-501/brut-us/especes/).
Sources lues le 2026-11-08 ; aucune page n'indique de licence : « non précisée ». MD : le site des pêches (dnr.maryland.gov) répond 403,
on lit la liste de l'enquête sur les cours d'eau (MBSS, eyesonthebay.dnr.maryland.gov)."""
import html, json, os, re, sys, time, urllib.request

ICI = os.path.dirname(os.path.abspath(__file__))
ESPECES = os.path.join(ICI, "..", "especes-us.json")
SORTIE = os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
BRUT = "/private/tmp/claude-501/brut-us/especes/"
UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
DATE = "2026-11-08"

ALIAS = {  # nom de page -> slug de especes-us.json
    "hybrid striped bass": "wiper", "tiger musky": "tiger-muskie", "muskellenge": "muskellunge",
    "alabama bass": None, "mosquitofish": None,
}
# Espèces d'intérêt pour le pêcheur retenues dans chaque page (le reste : vairons, dards, lamproies... écarté)
VA = ["Alabama Bass", "American Shad", "Black Crappie", "Blue Catfish", "Bluegill", "Bowfin", "Brook Trout", "Brown Trout",
      "Chain Pickerel", "Channel Catfish", "Common Carp", "Flathead Catfish", "Flier", "Freshwater Drum", "Green Sunfish",
      "Hickory Shad", "Hybrid Striped Bass", "Largemouth Bass", "Longnose Gar", "Muskellunge", "Northern Pike",
      "Northern Snakehead", "Paddlefish", "Pumpkinseed", "Rainbow Trout", "Redbreast Sunfish", "Redear Sunfish",
      "Roanoke Bass", "Rock Bass", "Sauger", "Saugeye", "Smallmouth Bass", "Spotted Bass", "Striped Bass", "Walleye",
      "Warmouth", "White Bass", "White Catfish", "White Crappie", "White Perch", "Yellow Perch"]
MD = ["American eel", "Black crappie", "Bluegill", "Brown bullhead", "Brown trout", "Chain pickerel", "Channel catfish",
      "Common carp", "Cutthroat trout", "Goldfish", "Green sunfish", "Largemouth bass", "Longear sunfish", "Pumpkinseed",
      "Rainbow trout", "Redbreast sunfish", "Redfin pickerel", "Rock bass", "Smallmouth bass", "Striped bass", "White perch",
      "White sucker", "Yellow bullhead", "Yellow perch"]
DC = ["American Shad", "Hickory Shad", "Channel Catfish", "Chain Pickerel", "Largemouth Bass", "Smallmouth Bass",
      "Striped Bass", "Northern Pike", "Walleye", "Yellow Perch"]
WV_SANS_LATIN = {"Tiger Trout": "Salmo trutta x Salvelinus fontinalis", "Golden Trout": "Oncorhynchus mykiss aguabonita",
                 "Bullhead Catfish": "Ameiurus spp."}
LATIN_PAGE = {"Alabama Bass": "Micropterus henshalli", "Flier": "Centrarchus macropterus", "Roanoke Bass": "Ambloplites cavifrons",
              "Hickory Shad": "Alosa mediocris", "Bullhead Catfish": "Ameiurus spp.", "Tiger Trout": WV_SANS_LATIN["Tiger Trout"],
              "Golden Trout": WV_SANS_LATIN["Golden Trout"]}


def charger_table():
    t = json.load(open(ESPECES, encoding="utf-8"))
    return {e["slug"]: e for e in t}


def trouver(nom, table):
    k = nom.strip().lower()
    if k in ALIAS:
        return table.get(ALIAS[k]) if ALIAS[k] else None
    return table.get(k.replace(" ", "-"))


def entree(nom, table, src, zone, preuve, latin=None, **extra):
    e = trouver(nom, table)
    r = {"slug": e["slug"] if e else None, "nom": nom if not e else e["nom_en"],
         "latin": e["latin"] if e else (latin or LATIN_PAGE.get(nom)), "zone": zone, "preuve": preuve,
         "src": src, "confiance": "officielle"}
    r.update(extra)
    return r


def texte(brut):
    t = re.sub(r"<script.*?</script>|<style.*?</style>", "", brut, flags=re.S)
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", t)))


def noms_presents(t, noms):
    """Garde les noms de la liste qui figurent dans le texte de la page (jamais un nom absent de la page)."""
    return [n for n in noms if re.search(r"\b" + re.escape(n) + r"\b", t, re.I)]


def parse_nc(brut):
    """Fiches du catalogue « poissons » du NCWRC : (nom, latin, classification). Noms pris dans les liens /species/<slug>."""
    t = texte(brut)
    out = []
    for m in re.finditer(r"([A-Z][A-Za-z' \-]{2,40}?) Scientific Name: ([A-Z][a-z]+(?: [a-z]+)?(?: spp\.)?) Classification: ", t):
        out.append((m.group(1), m.group(2)))
    return out


def parse_va_empoissonnement(brut):
    """Lignes du tableau d'empoissonnement truites de la DWR : (année, plan d'eau, [espèces])."""
    lignes = []
    for tr in re.findall(r"<tr[^>]*>(.*?)</tr>", brut, flags=re.S):
        d = re.search(r'date_stocked">([^<]+)<', tr)
        w = re.search(r'waterbody_details">([^<]+)<', tr)
        if not d or not w:
            continue
        an = re.search(r"(\d{4})", d.group(1))
        esp = re.findall(r"<li>([^<]+)</li>", tr)
        nom = re.sub(r"\s*\[[^\]]*\]", "", html.unescape(w.group(1))).strip()
        if an and esp:
            lignes.append((int(an.group(1)), nom, [html.unescape(x).strip() for x in esp]))
    return lignes


def fichier(usps, sources, entrees):
    return {"format": "fishme-especes-us/1", "etat": usps, "producteur": "agence", "date": DATE, "sources": sources, "entrees": entrees}


def src(nom, url, jeu=None):
    s = {"nom": nom, "url": url, "licence": "non précisée", "date": DATE}
    if jeu:
        s["jeu"] = jeu
    return s


def construire(pages):
    """pages : dict nom -> html brut. Retourne {USPS: fichier}."""
    table = charger_table()
    out = {}
    etat = lambda u, n: {"type": "etat", "id": u, "nom": n}
    # MD : enquête MBSS
    t = texte(pages["mbss"])
    sm = [src("Maryland Biological Stream Survey, fish distributions 1995-2025 (Maryland DNR)", "https://eyesonthebay.dnr.maryland.gov/mbss/fishes.cfm")]
    out["MD"] = fichier("MD", sm, [entree(n, table, 0, etat("MD", "Maryland"), "enquete_peche_electrique") for n in noms_presents(t, MD)])
    # DC
    t = texte(pages["dc"])
    sd = [src("DC Fish Field Guide (DOEE, Fisheries and Wildlife Division)", "https://doee.dc.gov/page/dc-fish-field-guide")]
    out["DC"] = fichier("DC", sd, [entree(n, table, 0, etat("DC", "District of Columbia"), "liste_agence") for n in noms_presents(t, DC)])
    # VA
    t = texte(pages["va"])
    sv = [src("Wildlife Species Information: Fishes (Virginia DWR)", "https://dwr.virginia.gov/wildlife/fishes/"),
          src("Trout Stocking Schedule (Virginia DWR)", "https://dwr.virginia.gov/fishing/trout-stocking-schedule/")]
    ev = [entree(n, table, 0, etat("VA", "Virginia"), "liste_agence") for n in noms_presents(t, VA)]
    plans = {}
    for an, nom, esp in parse_va_empoissonnement(pages["vastock"]):
        for s in esp:
            k = (nom, s)
            p = plans.setdefault(k, [0, an])
            p[0] += 1
            p[1] = max(p[1], an)
    for (nom, s), (n, an) in sorted(plans.items()):
        ev.append(entree(s, table, 1, {"type": "plan_eau", "id": nom, "nom": nom}, "empoissonnement", n=n, annee_max=an))
    out["VA"] = fichier("VA", sv, ev)
    # WV : page sportfish (noms en majuscules, sans latin)
    t = texte(pages["wv"])
    sw = [src("Sportfish in West Virginia (WVDNR)", "https://wvdnr.gov/plants-animals/sportfish/")]
    m = re.search(r"Plants & Animals / --> (.*?) Learn More About Fish Identification", t)
    liste = [x.strip().title() for x in re.split(r"\s*Learn More\s*", m.group(1)) if x.strip()] if m else []
    liste = [x for x in liste if x != "Fallfish"]
    out["WV"] = fichier("WV", sw, [entree(n, table, 0, etat("WV", "West Virginia"), "liste_agence") for n in liste])
    # NC : catalogue poissons (pages 0 à 4), seulement les espèces d'intérêt présentes dans le catalogue
    cat = []
    for p in pages["nc"]:
        cat += parse_nc(p)
    vus, enc = set(), []
    ok = {n.lower() for n in VA} | {"bullhead catfish", "lake sturgeon", "roanoke bass", "hickory shad"}
    for nom, latin in cat:
        k = next((o for o in sorted(ok, key=len, reverse=True) if nom.lower().strip().endswith(o)), "")
        nom = k.title() if k else nom
        if k in ok and k not in vus:
            vus.add(k)
            enc.append(entree(nom.strip(), table, 0, etat("NC", "North Carolina"), "liste_agence", latin=latin))
    sn = [src("Fish (catalogue des espèces, NC Wildlife Resources Commission)", "https://www.ncwildlife.gov/catalog-category/fish")]
    out["NC"] = fichier("NC", sn, enc)
    return out


URLS = {"mbss": "https://eyesonthebay.dnr.maryland.gov/mbss/fishes.cfm", "dc": "https://doee.dc.gov/page/dc-fish-field-guide",
        "va": "https://dwr.virginia.gov/wildlife/fishes/", "vastock": "https://dwr.virginia.gov/fishing/trout-stocking-schedule/",
        "wv": "https://wvdnr.gov/plants-animals/sportfish/"}


def lire(url):
    time.sleep(0.5)
    return urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA}), timeout=40).read().decode("utf-8", "ignore")


def main(sortie=SORTIE):
    os.makedirs(BRUT, exist_ok=True)
    pages = {k: lire(u) for k, u in URLS.items()}
    pages["nc"] = [lire("https://www.ncwildlife.gov/catalog-category/fish" + ("" if i == 0 else f"?page={i}")) for i in range(5)]
    os.makedirs(sortie, exist_ok=True)
    for usps, d in construire(pages).items():
        json.dump(d, open(os.path.join(sortie, f"{usps}-agence.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        print(usps, len(d["entrees"]), "entrées")


if __name__ == "__main__":
    main(*(sys.argv[1:2]))
