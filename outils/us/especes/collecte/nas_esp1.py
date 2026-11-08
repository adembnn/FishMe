#!/usr/bin/env python3
"""USGS NAS (espèces non indigènes) pour ME NH VT MA RI : poissons d'eau douce de la table especes-us.json,
par bassin HUC8 + niveau État. Statuts écartés : failed, eradicated, extirpated.
Usage : python3 -I nas_esp1.py [ETAT ...] [--brut DOSSIER]   (sans --brut : lit le réseau, pause 0,3 s, cache dans BRUT)"""
import json, os, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun_esp1 as c

UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
NOMS = {"ME": "Maine", "NH": "New Hampshire", "VT": "Vermont", "MA": "Massachusetts", "RI": "Rhode Island"}
ECARTES = {"failed", "eradicated", "extirpated"}


def telecharger(usps, brut):
    p = os.path.join(brut, f"nas-{usps}.json")
    if os.path.exists(p):
        return json.load(open(p, encoding="utf-8"))
    res, off = [], 0
    while True:
        u = f"https://nas.er.usgs.gov/api/v2/occurrence/search?state={usps}&group=Fishes&limit=200&offset={off}"
        for essai in range(4):
            time.sleep(0.3 + 2 * essai)
            try:
                r = json.load(urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": UA}), timeout=90))
                break
            except Exception:
                if essai == 3:
                    raise
        res += r["results"]
        if str(r.get("endOfRecords")).lower() == "true" or not r["results"]:
            break
        off += 200
    json.dump(res, open(p, "w", encoding="utf-8"))
    return res


def construire(usps, occ):
    sl = c.slugs()
    src = [{"nom": "USGS Nonindigenous Aquatic Species database, occurrences de poissons dans " + NOMS[usps],
            "url": f"https://nas.er.usgs.gov/api/v2/occurrence/search?state={usps}&group=Fishes",
            "licence": "domaine public fédéral", "date": c.DATE}]
    agg = {}
    for o in occ:
        lat = o.get("scientificName")
        if lat not in sl or o.get("freshMarineIntro") not in ("Freshwater", "Freshwater/Marine"):
            continue
        if str(o.get("status", "")).lower() in ECARTES:
            continue
        for zt, zid, znom in [("etat", usps, NOMS[usps])] + (
                [("huc8", o["huc8"], o.get("huc8Name") or o["huc8"])] if o.get("huc8") and o["huc8"] != "00000000" else []):
            a = agg.setdefault((lat, zt, zid), {"nom": o.get("commonName") or lat, "znom": znom, "n": 0, "an": None})
            a["n"] += 1
            if o.get("year"):
                a["an"] = max(a["an"] or 0, int(o["year"]))
    ent = []
    for (lat, zt, zid), a in sorted(agg.items()):
        ent.append({"slug": sl[lat], "nom": a["nom"], "latin": lat, "zone": {"type": zt, "id": zid, "nom": a["znom"]},
                    "preuve": "nas", "src": 0, "confiance": "enregistrement_scientifique", "n": a["n"],
                    **({"annee_max": a["an"]} if a["an"] else {})})
    return src, ent


if __name__ == "__main__":
    a = sys.argv[1:]
    brut = c.BRUT
    if "--brut" in a:
        i = a.index("--brut"); brut = a[i + 1]; a = a[:i] + a[i + 2:]
    for u in (a or list(NOMS)):
        s, e = construire(u, telecharger(u, brut))
        print(c.ecrire(u, "nas", s, e), len(e), "entrées")
