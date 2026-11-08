#!/usr/bin/env python3
"""US16 : USGS NAS (espèces de poissons non indigènes signalées) -> <USPS>-nas.json (zones HUC8).
Usage : python3 nas.py <USPS> [dossier_sortie] ; réseau, pause 0,3 s, User-Agent FishMe-data/1.0."""
import json, os, sys, time, urllib.request, datetime

UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
ICI = os.path.dirname(os.path.abspath(__file__))
ESPECES = os.path.join(ICI, "..", "especes-us.json")
SORTIE = os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
URL = "https://nas.er.usgs.gov/api/v2/occurrence/search?state={s}&group=Fishes&limit=1000&offset={o}"
URL_FICHE = "https://nas.er.usgs.gov/queries/SpeciesList.aspx?Group=Fishes&state={s}"
RETENUS = {"established", "collected", "stocked", "unknown", "failed"}


def lire(url):
    for essai in range(3):
        try:
            return json.load(urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA}), timeout=60))
        except Exception:
            time.sleep(2)
    raise RuntimeError(url)


def collecter(usps, lire=lire, aujourdhui=None):
    slugs = {}
    for e in json.load(open(ESPECES)):
        slugs[e["latin"].lower()] = e["slug"]
    agg, off = {}, 0
    while True:
        d = lire(URL.format(s=usps, o=off))
        for r in d["results"]:
            if r.get("freshMarineIntro") not in ("Freshwater", "Both", None, ""):
                continue
            lat = r.get("scientificName")
            if not lat or r.get("status") not in RETENUS or r.get("status") == "failed":
                continue
            h = str(r.get("huc8") or "")
            zone = ("huc8", h) if len(h) == 8 and not h.endswith("000000") else ("etat", usps)
            k = (lat, r.get("commonName") or lat, zone)
            a = agg.setdefault(k, [0, 0])
            a[0] += 1
            a[1] = max(a[1], int(r.get("year") or 0))
        if str(d.get("endOfRecords")).lower() == "true" or not d["results"]:
            break
        off += d["limit"]
        time.sleep(0.3)
    jour = aujourdhui or datetime.date.today().isoformat()
    entrees = []
    for (lat, nom, (zt, zid)), (n, an) in sorted(agg.items(), key=lambda x: (x[0][2], x[0][0])):
        e = {"slug": slugs.get(lat.lower()), "nom": nom, "latin": lat, "zone": {"type": zt, "id": zid}, "preuve": "nas",
             "src": 0, "confiance": "enregistrement_scientifique", "n": n}
        if an:
            e["annee_max"] = an
        if zt == "etat":
            e["zone"]["nom"] = usps
        entrees.append(e)
    return {"format": "fishme-especes-us/1", "etat": usps, "producteur": "nas", "date": jour,
            "sources": [{"nom": "USGS Nonindigenous Aquatic Species database (poissons, signalements par bassin HUC8)",
                         "url": URL_FICHE.format(s=usps), "licence": "domaine public fédéral", "date": jour,
                         "jeu": "https://nas.er.usgs.gov/api/v2/"}],
            "entrees": entrees}


if __name__ == "__main__":
    usps = sys.argv[1]
    sortie = sys.argv[2] if len(sys.argv) > 2 else SORTIE
    d = collecter(usps)
    json.dump(d, open(os.path.join(sortie, f"{usps}-nas.json"), "w"), ensure_ascii=False, indent=0)
    print(usps, len(d["entrees"]), "entrées")
