#!/usr/bin/env python3
"""US16 vague 2 : poissons non indigènes signalés par État d'après l'USGS NAS (API v2 publique), producteur « nas ».
Une entrée = espèce x bassin HUC8 (n = nombre d'enregistrements, annee_max = année la plus récente). Statuts gardés : established, collected.
Aucune coordonnée ni lieu-dit n'est recopié. Usage : python3 -I NAS.py TN KY OH IN IL   (bruts dans /private/tmp/claude-501/brut-us/especes/nas/)"""
import json, os, sys, time, urllib.request

UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
DATE = "2026-11-08"
ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
TABLE = os.path.join(ICI, "..", "especes-us.json")
BRUT = "/private/tmp/claude-501/brut-us/especes/nas"
NOMS = {"TN": "Tennessee", "KY": "Kentucky", "OH": "Ohio", "IN": "Indiana", "IL": "Illinois"}
STATUTS = {"established", "collected"}


def telecharger(usps):
    os.makedirs(BRUT, exist_ok=True)
    p = os.path.join(BRUT, f"{usps}.json")
    if os.path.exists(p):
        return json.load(open(p, encoding="utf-8"))
    res, off = [], 0
    while True:
        time.sleep(0.3)
        u = f"https://nas.er.usgs.gov/api/v2/occurrence/search?state={usps}&group=Fishes&limit=500&offset={off}"
        d = json.loads(urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": UA}), timeout=120).read())
        res += [{k: r.get(k) for k in ("scientificName", "commonName", "huc8", "huc8Name", "year", "status")} for r in d["results"]]
        if str(d.get("endOfRecords")).lower() == "true" or not d["results"]:
            break
        off += 500
    json.dump(res, open(p, "w", encoding="utf-8"))
    return res


def agreger(usps, lignes):
    table = {e["latin"]: e["slug"] for e in json.load(open(TABLE, encoding="utf-8"))}
    agg = {}
    for r in lignes:
        if r["status"] not in STATUTS or not r["huc8"] or not str(r["huc8"]).isdigit() or len(str(r["huc8"])) != 8:
            continue
        k = (r["scientificName"], r["commonName"], str(r["huc8"]), r["huc8Name"])
        a = agg.setdefault(k, [0, 0])
        a[0] += 1
        a[1] = max(a[1], r["year"] or 0)
    entrees = []
    for (lat, nom, huc, hn), (n, an) in sorted(agg.items()):
        if not lat:
            continue
        e = {"slug": table.get(lat), "nom": nom or lat, "latin": lat, "zone": {"type": "huc8", "id": huc, "nom": hn or huc},
             "preuve": "nas", "src": 0, "confiance": "enregistrement_scientifique", "n": n}
        if an:
            e["annee_max"] = an
        entrees.append(e)
    return {"format": "fishme-especes-us/1", "etat": usps, "producteur": "nas", "date": DATE,
            "sources": [{"nom": f"USGS Nonindigenous Aquatic Species (NAS), poissons, {NOMS[usps]}", "url": "https://nas.er.usgs.gov/api/v2/",
                         "licence": "non précisée", "date": DATE}],
            "entrees": entrees}


if __name__ == "__main__":
    for s in sys.argv[1:]:
        d = agreger(s, telecharger(s))
        p = os.path.join(SORTIE, f"{s}-nas.json")
        json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
        print(s, len(d["entrees"]), "entrées", os.path.getsize(p), "octets")
