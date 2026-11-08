#!/usr/bin/env python3
"""US16 NY : brochure DEC « Freshwater Sportfish of NYS » (20 espèces) + jeu ouvert data.ny.gov « Fish Stocking Lists (Actual) »
(espèce, plan d'eau, comté, année max, depuis 2016) -> NY-agence.json.
Usage : python3 NY.py <sortie.json> [agrégat.json]  (sans agrégat : réseau, pause 0,3 s)."""
import json, sys, time, urllib.parse, urllib.request

UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
JOUR = "2026-11-08"
SOCRATA = "https://data.ny.gov/resource/e52k-ymww.json"
DEPUIS = 2022
LISTE = [  # brochure DEC, ordre de la brochure
    ("atlantic-salmon", "Atlantic salmon", "Salmo salar"), ("brook-trout", "Brook trout", "Salvelinus fontinalis"),
    ("brown-trout", "Brown trout", "Salmo trutta"), ("chinook-salmon", "Chinook salmon", "Oncorhynchus tshawytscha"),
    ("lake-trout", "Lake trout", "Salvelinus namaycush"), ("rainbow-trout", "Rainbow trout", "Oncorhynchus mykiss"),
    ("muskellunge", "Muskellunge", "Esox masquinongy"), ("northern-pike", "Northern pike", "Esox lucius"),
    ("chain-pickerel", "Chain pickerel", "Esox niger"), ("bluegill", "Bluegill", "Lepomis macrochirus"),
    ("pumpkinseed", "Pumpkinseed", "Lepomis gibbosus"), ("rock-bass", "Rock bass", "Ambloplites rupestris"),
    ("black-crappie", "Black crappie", "Pomoxis nigromaculatus"),
    # la brochure imprime « Micropterus nigricans » ; nom retenu : M. salmoides (ITIS, table d'espèces)
    ("largemouth-bass", "Largemouth bass", "Micropterus salmoides"), ("smallmouth-bass", "Smallmouth bass", "Micropterus dolomieu"),
    ("walleye", "Walleye", "Sander vitreus"), ("yellow-perch", "Yellow perch", "Perca flavescens"),
    ("brown-bullhead", "Brown bullhead", "Ameiurus nebulosus"), ("common-carp", "Common carp", "Cyprinus carpio"),
    ("white-perch", "White perch", "Morone americana"),
]
# libellés du jeu d'empoissonnement -> (slug, nom, latin) ; « Panfish » (générique) écarté
MAP = {
    "Walleye": ("walleye", "Walleye", "Sander vitreus"), "Brook Trout": ("brook-trout", "Brook trout", "Salvelinus fontinalis"),
    "Splake": (None, "Splake", "Salvelinus fontinalis x Salvelinus namaycush"),
    "Gilt Darter": (None, "Gilt darter", "Percina evides"), "Lake Sturgeon": ("lake-sturgeon", "Lake sturgeon", "Acipenser fulvescens"),
    "Brown Trout": ("brown-trout", "Brown trout", "Salmo trutta"), "Lake Trout": ("lake-trout", "Lake trout", "Salvelinus namaycush"),
    "Paddlefish": ("paddlefish", "Paddlefish", "Polyodon spathula"), "Landlocked Salmon": ("atlantic-salmon", "Atlantic salmon (landlocked)", "Salmo salar"),
    "Sauger": ("sauger", "Sauger", "Sander canadensis"), "Chinook": ("chinook-salmon", "Chinook salmon", "Oncorhynchus tshawytscha"),
    "Muskellunge": ("muskellunge", "Muskellunge", "Esox masquinongy"), "Tiger Muskellunge": ("tiger-muskie", "Tiger muskellunge", "Esox masquinongy x Esox lucius"),
    "Steelhead": ("rainbow-trout", "Steelhead", "Oncorhynchus mykiss"), "Rainbow Trout": ("rainbow-trout", "Rainbow trout", "Oncorhynchus mykiss"),
    "Lake Herring (Cisco)": ("cisco", "Cisco (lake herring)", "Coregonus artedi"), "Round Whitefish": (None, "Round whitefish", "Prosopium cylindraceum"),
    "Northern Sunfish": (None, "Northern sunfish", "Lepomis peltastes"), "Coho": ("coho-salmon", "Coho salmon", "Oncorhynchus kisutch"),
}


def requete(params):
    url = SOCRATA + "?" + urllib.parse.urlencode(params)
    return json.load(urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA}), timeout=90))


def agreger():
    time.sleep(0.3)
    return requete({"$select": "waterbody,county,species,max(year),count(*)", "$where": f"year>={DEPUIS}",
                    "$group": "waterbody,county,species", "$limit": 50000})


def construire(agg):
    e = []
    for slug, nom, lat in LISTE:
        e.append({"slug": slug, "nom": nom, "latin": lat, "zone": {"type": "etat", "id": "NY", "nom": "New York"},
                  "preuve": "liste_agence", "src": 0, "confiance": "officielle"})
    ecartes = set()
    for r in sorted(agg, key=lambda r: (r["waterbody"], r["county"], r["species"])):
        m = MAP.get(r["species"])
        if not m:
            ecartes.add(r["species"])
            continue
        e.append({"slug": m[0], "nom": m[1], "latin": m[2],
                  "zone": {"type": "plan_eau", "id": f'{r["waterbody"]} ({r["county"]} County)', "nom": r["waterbody"]},
                  "preuve": "empoissonnement", "src": 1, "confiance": "officielle",
                  "annee_max": int(r["max_year"])})
    return {"format": "fishme-especes-us/1", "etat": "NY", "producteur": "agence", "date": JOUR,
            "sources": [
                {"nom": "NYS DEC, Freshwater Sportfish of New York State (brochure)",
                 "url": "https://dec.ny.gov/sites/default/files/2026-08/freshwatersportfishbrochure.pdf",
                 "licence": "non précisée", "date": JOUR},
                {"nom": f"NYS DEC, Fish Stocking Lists (Actual) beginning 2011, data.ny.gov (lignes depuis {DEPUIS} agrégées par plan d'eau et espèce )",
                 "url": "https://data.ny.gov/d/e52k-ymww", "licence": "non précisée", "date": JOUR,
                 "jeu": "e52k-ymww"}],
            "entrees": e}, sorted(ecartes)


if __name__ == "__main__":
    agg = json.load(open(sys.argv[2])) if len(sys.argv) > 2 else agreger()
    d, ecartes = construire(agg)
    json.dump(d, open(sys.argv[1], "w"), ensure_ascii=False, separators=(",", ":"))
    print("NY", len(d["entrees"]), "entrées ; libellés écartés :", ecartes)
