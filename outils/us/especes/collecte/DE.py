#!/usr/bin/env python3
"""US16 DE : page DNREC « Gamefish » (liste d'espèces) + jeu ouvert data.delaware.gov « Freshwater Pond Fish Community Surveys »
(pêche électrique annuelle des étangs publics, domaine public) -> DE-agence.json.
Usage : python3 DE.py <sortie.json> [surveys.json]  (sans fichier : réseau)."""
import json, sys, time, urllib.request

UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
JOUR = "2026-11-08"
URL = "https://data.delaware.gov/resource/aaur-zvyv.json?$limit=5000"
LISTE = [  # page Gamefish du DNREC (hors genres entiers : Lepomis, trout, salmon, hybrides de muskellunge)
    ("largemouth-bass", "Largemouth bass", "Micropterus salmoides"), ("smallmouth-bass", "Smallmouth bass", "Micropterus dolomieu"),
    ("black-crappie", "Black crappie", "Pomoxis nigromaculatus"), ("white-crappie", "White crappie", "Pomoxis annularis"),
    ("rock-bass", "Rock bass", "Ambloplites rupestris"), ("white-bass", "White bass", "Morone chrysops"),
    ("walleye", "Walleye", "Sander vitreus"), ("northern-pike", "Northern pike", "Esox lucius"),
    ("chain-pickerel", "Chain pickerel", "Esox niger"), ("muskellunge", "Muskellunge", "Esox masquinongy"),
    ("wiper", "Hybrid striped bass", "Morone chrysops x Morone saxatilis"),
]
TROUT = [("rainbow-trout", "Rainbow trout", "Oncorhynchus mykiss")]  # page DNREC « Freshwater Trout Fishing » (saison 2026)
CHAMPS = {  # champ du jeu -> espèce
    "largemouth_bass": ("largemouth-bass", "Largemouth bass", "Micropterus salmoides"),
    "bluegill": ("bluegill", "Bluegill", "Lepomis macrochirus"),
    "black_crappie": ("black-crappie", "Black crappie", "Pomoxis nigromaculatus"),
    "yellow_perch": ("yellow-perch", "Yellow perch", "Perca flavescens"),
    "striped_bass_hybrid": ("wiper", "Hybrid striped bass", "Morone chrysops x Morone saxatilis"),
    "redear_sunfish": ("redear-sunfish", "Redear sunfish", "Lepomis microlophus"),
}


def charger():
    time.sleep(0.3)
    return json.load(urllib.request.urlopen(urllib.request.Request(URL, headers={"User-Agent": UA}), timeout=60))


def construire(lignes):
    e = []
    for slug, nom, lat in LISTE:
        e.append({"slug": slug, "nom": nom, "latin": lat, "zone": {"type": "etat", "id": "DE", "nom": "Delaware"},
                  "preuve": "liste_agence", "src": 0, "confiance": "officielle"})
    for slug, nom, lat in TROUT:
        e.append({"slug": slug, "nom": nom, "latin": lat, "zone": {"type": "etat", "id": "DE", "nom": "Delaware"},
                  "preuve": "liste_agence", "src": 2, "confiance": "officielle", "annee_max": 2026})
    agg = {}
    for r in lignes:
        for champ, esp in CHAMPS.items():
            try:
                v = float(r.get(champ, 0))
            except ValueError:
                continue
            if v > 0:
                a = agg.setdefault((r["pond_name"], r.get("county", ""), esp), [0, 0])
                a[0] += 1
                a[1] = max(a[1], int(r["survey_year"]))
    for (etang, comte, (slug, nom, lat)), (n, an) in sorted(agg.items()):
        e.append({"slug": slug, "nom": nom, "latin": lat, "zone": {"type": "plan_eau", "id": etang, "nom": f"{etang} ({comte} County)"},
                  "preuve": "enquete_peche_electrique", "src": 1, "confiance": "officielle", "n": n, "annee_max": an})
    return {"format": "fishme-especes-us/1", "etat": "DE", "producteur": "agence", "date": JOUR,
            "sources": [
                {"nom": "DNREC Division of Fish and Wildlife, Gamefish (liste d'espèces)",
                 "url": "https://dnrec.delaware.gov/fish-wildlife/fishing/gamefish/", "licence": "non précisée", "date": JOUR},
                {"nom": "DNREC Division of Fish and Wildlife, Freshwater Pond Fish Community Surveys, data.delaware.gov (n = nombre d'enquêtes où l'espèce est comptée)",
                 "url": "https://data.delaware.gov/Energy-and-Environment/Freshwater-Pond-Fish-Community-Surveys/aaur-zvyv",
                 "licence": "domaine public (Public Domain, data.delaware.gov)", "date": JOUR, "jeu": "aaur-zvyv"},
                {"nom": "DNREC, Freshwater Trout Fishing (truites arc-en-ciel lâchées en 2026)",
                 "url": "https://dnrec.delaware.gov/fish-wildlife/fishing/freshwater-trout/", "licence": "non précisée", "date": JOUR}],
            "entrees": e}


if __name__ == "__main__":
    lignes = json.load(open(sys.argv[2])) if len(sys.argv) > 2 else charger()
    d = construire(lignes)
    json.dump(d, open(sys.argv[1], "w"), ensure_ascii=False, separators=(",", ":"))
    print("DE", len(d["entrees"]), "entrées")
