#!/usr/bin/env python3
"""US16 PA : pages « Catch PA Fish » de la PFBC (liste des poissons de pêche sportive) -> PA-agence.json.
Liste lue à la main sur les pages de l'agence (aucun jeu ouvert par plan d'eau accessible : service ArcGIS PASDA arrêté, 500).
Usage : python3 PA.py <sortie.json>"""
import json, sys

JOUR = "2026-11-08"
LISTE = [  # (slug, nom, latin, src) ; src 0 = index Catch PA Fish, 1 = page Trout, 2 = page Bass, 3 = Popular sportfishes (crappies)
    ("smallmouth-bass", "Smallmouth bass", "Micropterus dolomieu", 2), ("largemouth-bass", "Largemouth bass", "Micropterus salmoides", 2),
    ("spotted-bass", "Spotted bass", "Micropterus punctulatus", 2), ("bluegill", "Bluegill", "Lepomis macrochirus", 0),
    ("common-carp", "Carp", "Cyprinus carpio", 0), ("chain-pickerel", "Chain pickerel", "Esox niger", 0),
    ("channel-catfish", "Channel catfish", "Ictalurus punctatus", 0), ("black-crappie", "Black crappie", "Pomoxis nigromaculatus", 3),
    ("white-crappie", "White crappie", "Pomoxis annularis", 3), ("flathead-catfish", "Flathead catfish", "Pylodictis olivaris", 0),
    ("muskellunge", "Muskellunge", "Esox masquinongy", 0), ("northern-pike", "Northern pike", "Esox lucius", 0),
    ("pumpkinseed", "Pumpkinseed", "Lepomis gibbosus", 0), ("redbreast-sunfish", "Redbreast sunfish", "Lepomis auritus", 0),
    ("rock-bass", "Rock bass", "Ambloplites rupestris", 0), ("sauger", "Sauger", "Sander canadensis", 0),
    ("american-shad", "American shad", "Alosa sapidissima", 0), ("northern-snakehead", "Northern snakehead", "Channa argus", 0),
    ("rainbow-trout", "Steelhead", "Oncorhynchus mykiss", 0), ("striped-bass", "Striped bass", "Morone saxatilis", 0),
    ("brook-trout", "Brook trout", "Salvelinus fontinalis", 1), ("brown-trout", "Brown trout", "Salmo trutta", 1),
    ("rainbow-trout", "Rainbow trout", "Oncorhynchus mykiss", 1), ("walleye", "Walleye", "Sander vitreus", 0),
    ("white-bass", "White bass", "Morone chrysops", 0), ("white-perch", "White perch", "Morone americana", 0),
    ("yellow-perch", "Yellow perch", "Perca flavescens", 0),
]
# la page Trout cite le touladi à Lake Erie, Raystown Lake et East Branch Clarion River Dam (pas d'année)
LAKE_TROUT = ["Lake Erie", "Raystown Lake", "East Branch Clarion River Dam"]
BASE = "https://www.pa.gov/agencies/fishandboat/fishing/all-about-fish/catch-pa-fish"


def construire():
    e = []
    for slug, nom, lat, src in LISTE:
        e.append({"slug": slug, "nom": nom, "latin": lat, "zone": {"type": "etat", "id": "PA", "nom": "Pennsylvania"},
                  "preuve": "liste_agence", "src": src, "confiance": "officielle"})
    for eau in LAKE_TROUT:
        e.append({"slug": "lake-trout", "nom": "Lake trout", "latin": "Salvelinus namaycush",
                  "zone": {"type": "plan_eau", "id": eau, "nom": eau}, "preuve": "liste_agence", "src": 1, "confiance": "officielle"})
    return {"format": "fishme-especes-us/1", "etat": "PA", "producteur": "agence", "date": JOUR,
            "sources": [
                {"nom": "PFBC, Catch PA Fish (pages de poissons de pêche sportive)", "url": BASE, "licence": "non précisée", "date": JOUR},
                {"nom": "PFBC, Catch PA Fish : Trout", "url": BASE + "/trout", "licence": "non précisée", "date": JOUR},
                {"nom": "PFBC, Catch PA Fish : Bass (smallmouth, largemouth, spotted)", "url": BASE + "/bass", "licence": "non précisée", "date": JOUR},
                {"nom": "PFBC, Popular Sportfishes of Pennsylvania (crappies noir et blanc)",
                 "url": "https://www.pa.gov/content/dam/copapwp-pagov/en/fishandboat/documents/fishing/all-about-fish/popularsportfishes.pdf",
                 "licence": "non précisée", "date": JOUR}],
            "entrees": e}


if __name__ == "__main__":
    d = construire()
    json.dump(d, open(sys.argv[1], "w"), ensure_ascii=False, separators=(",", ":"))
    print("PA", len(d["entrees"]), "entrées")
