#!/usr/bin/env python3
"""US16 groupe esp-6 : MI-agence.json depuis le « Fish Atlas » ouvert du Michigan DNR (couche ArcGIS publique).
michigan.gov (pages d'espèces) répond « Access Denied » (Akamai) : jamais contourné ; cette couche est un service de données ouvert du même DNR.
Garde : espèces de especes-us.json ; agrège par espèce (niveau État seulement : la couche ne nomme pas les plans d'eau, et ses données s'arrêtent en 2002) : n, annee_max. Aucune coordonnée gardée.
Usage : python3 esp6_mi.py   (réseau)"""
import json, os, sys, urllib.parse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from esp6_fetchlib import get

ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.normpath(os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us"))
COUCHE = "https://services3.arcgis.com/Jdnp1TjADvSDxMAX/arcgis/rest/services/DNRFisheriesDataOPENDATA/FeatureServer/0"
DATE = "2026-11-08"
ANNEE_MIN = 0


def table_latin():
    t = {}
    for e in json.load(open(os.path.join(ICI, "..", "especes-us.json"), encoding="utf-8")):
        p = e["latin"].split()
        if len(p) >= 2 and " x " not in e["latin"] and "spp" not in e["latin"]:
            t.setdefault(p[0] + " " + p[1], e)
    return t


def requete(table, offset):
    noms = ",".join("'" + n + "'" for n in sorted(table))
    stats = json.dumps([{"statisticType": "count", "onStatisticField": "OBJECTID", "outStatisticFieldName": "n"},
                        {"statisticType": "max", "onStatisticField": "Year", "outStatisticFieldName": "y"}])
    q = {"where": "Year >= 1990", "groupByFieldsForStatistics": "Taxon",
         "outStatistics": stats, "orderByFields": "Taxon", "resultOffset": offset, "resultRecordCount": 1000, "f": "json"}
    return COUCHE + "/query?" + urllib.parse.urlencode(q)


def main():
    table = table_latin()
    lignes, off = [], 0
    while True:
        code, t = get(requete(table, off))
        if code != 200:
            raise SystemExit(f"Fish Atlas : HTTP {code}")
        j = json.loads(t)
        if "error" in j:
            raise SystemExit(str(j["error"]))
        lignes += [f["attributes"] for f in j.get("features", [])]
        if not j.get("exceededTransferLimit"):
            break
        off += 1000
    etat, lacs = {}, []
    for a in lignes:
        e = table.get(a["Taxon"])
        if not e:
            continue
        x = etat.setdefault(e["slug"], [0, 0])
        x[0] += a["n"]
        x[1] = max(x[1], a["y"] or 0)
        lacs.append((e, a))
    srcs = [{"nom": f"Michigan DNR, Fish Atlas (enregistrements de poissons récoltés dans l'État de 1990 à 2002 : espèce, nombre, dernière année ; la couche ne nomme pas les plans d'eau, seulement un type d'eau)",
             "url": "https://hub.arcgis.com/datasets/MichiganDNR::fish-atlas", "licence": "non précisée", "date": DATE}]
    entrees = []
    for slug, (n, y) in sorted(etat.items()):
        e = table[[k for k, v in table.items() if v["slug"] == slug][0]]
        entrees.append({"slug": slug, "nom": e["nom_en"], "latin": e["latin"], "zone": {"type": "etat", "id": "MI", "nom": "Michigan"},
                        "preuve": "liste_agence", "src": 0, "confiance": "officielle", "n": n, **({"annee_max": y} if y else {})})
    doc = {"format": "fishme-especes-us/1", "etat": "MI", "producteur": "agence", "date": DATE, "sources": srcs, "entrees": entrees}
    os.makedirs(SORTIE, exist_ok=True)
    p = os.path.join(SORTIE, "MI-agence.json")
    json.dump(doc, open(p, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print("MI niveau État :", len(etat), "; ", os.path.getsize(p) // 1024, "Ko")


if __name__ == "__main__":
    main()
