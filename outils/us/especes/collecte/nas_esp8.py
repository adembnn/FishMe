#!/usr/bin/env python3
"""USGS NAS (espèces non indigènes) pour AR, LA, TX, NM, CO : une entrée par espèce et par bassin HUC8 (n = nombre d'enregistrements,
annee_max = dernière année). Source : API https://nas.er.usgs.gov/api/v2/occurrence/search (données USGS, domaine public fédéral).
Écarte les enregistrements au statut échoué, éradiqué ou disparu. Usage : python3 -I nas_esp8.py [USPS ...] (réseau)"""
import json, re, sys, os, urllib.parse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import esp8_commun as C

API = "https://nas.er.usgs.gov/api/v2/occurrence/search"
ECARTES = {"failed", "eradicated", "extirpated", "extirpated/eradicated"}
INDEX = {}


def charger_index():
    with open(os.path.join(C.ICI, "..", "especes-us.json"), encoding="utf-8") as f:
        for e in json.load(f):
            INDEX[e["latin"].lower()] = e["slug"]


def agreger(resultats, etat):
    """resultats : liste d'enregistrements NAS -> entrees (dict par (latin, huc8))."""
    agg = {}
    for r in resultats:
        if str(r.get("status", "")).lower() in ECARTES:
            continue
        huc, latin, an = str(r.get("huc8") or ""), (r.get("scientificName") or "").strip(), r.get("year")
        if not re.fullmatch(r"\d{8}", huc) or not latin:
            continue
        k = (latin, huc)
        a = agg.setdefault(k, {"nom": r.get("commonName") or latin, "huc": r.get("huc8Name") or huc, "n": 0, "an": 0})
        a["n"] += 1
        if isinstance(an, int):
            a["an"] = max(a["an"], an)
    entrees = []
    for (latin, huc), a in sorted(agg.items()):
        e = {"slug": INDEX.get(latin.lower()), "nom": a["nom"], "latin": latin, "zone": {"type": "huc8", "id": huc, "nom": a["huc"]},
             "preuve": "nas", "src": 0, "confiance": "enregistrement_scientifique", "n": a["n"]}
        if a["an"]:
            e["annee_max"] = a["an"]
        entrees.append(e)
    return entrees


def recuperer(etat):
    out, off = [], 0
    while True:
        q = urllib.parse.urlencode({"state": etat, "group": "Fishes", "limit": 200, "offset": off})
        d = None
        for essai in range(4):  # le serveur répond parfois 500 : on réessaie avec une pause croissante
            try:
                d = json.loads(C.telecharger(API + "?" + q, 0.3 + 2 * essai))
                break
            except Exception as ex:
                print(etat, "offset", off, "essai", essai, ex, file=sys.stderr)
        if d is None:
            raise RuntimeError(f"{etat} : le serveur NAS refuse l'offset {off}")
        out += d.get("results", [])
        if str(d.get("endOfRecords")).lower() == "true" or not d.get("results"):
            break
        off += 200
    return out


def main(etats):
    charger_index()
    for etat in etats:
        res = recuperer(etat)
        entrees = agreger(res, etat)
        sources = [C.src("USGS Nonindigenous Aquatic Species database, enregistrements de poissons (API occurrence)", f"{API}?state={etat}&group=Fishes",
                         "domaine public fédéral")]
        chemin, taille = C.ecrire(etat, "nas", sources, entrees)
        print(etat, len(res), "enregistrements ->", len(entrees), "entrées", taille, "octets")


if __name__ == "__main__":
    main(sys.argv[1:] or ["AR", "LA", "TX", "NM", "CO"])
