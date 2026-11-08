"""NAS : USGS Nonindigenous Aquatic Species, poissons signales par Etat et par bassin HUC8 (especes NON indigenes seulement).

Usage : python3 -I NAS.py ND SD NE KS OK   (reseau, API publique https://nas.er.usgs.gov/api/v2/)
Ecrit <USPS>-nas.json : une entree par espece et par Etat, une par espece et par HUC8 (n = enregistrements, annee_max).
Les coordonnees des enregistrements ne sont jamais conservees. Licence : domaine public federal (USGS)."""
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _commun import DATE, ecrire, resoudre  # noqa: E402
from _http import telecharger  # noqa: E402

NOMS = {"ND": "North Dakota", "SD": "South Dakota", "NE": "Nebraska", "KS": "Kansas", "OK": "Oklahoma"}
API = "https://nas.er.usgs.gov/api/v2/occurrence/search?group=Fishes&state={usps}&limit=500&offset={off}"


def agreger(resultats, usps):
    """resultats NAS -> (par_etat, par_huc8) : dict latin -> {nom, n, annee_max, speciesID}."""
    etat, huc = {}, {}
    for r in resultats:
        latin = (r.get("scientificName") or "").strip()
        if not latin or r.get("freshMarineIntro") not in ("Freshwater", None, ""):
            continue
        an = r.get("year") if isinstance(r.get("year"), int) else None
        for cible, cle in ((etat, latin), (huc, (latin, str(r.get("huc8") or "")))):
            if isinstance(cle, tuple) and not (len(cle[1]) == 8 and cle[1].isdigit()):
                continue
            x = cible.setdefault(cle, {"nom": r.get("commonName") or latin, "n": 0, "annee_max": None, "id": r.get("speciesID")})
            x["n"] += 1
            if an and (x["annee_max"] is None or an > x["annee_max"]):
                x["annee_max"] = an
    return etat, huc


def construire(usps, resultats):
    etat, huc = agreger(resultats, usps)
    sources = [{"nom": "USGS NAS, occurrences de poissons non indigènes (API)", "url": "https://nas.er.usgs.gov/api/v2/",
                "licence": "domaine public fédéral", "date": DATE}]
    entrees = []

    def ajout(latin, x, zone):
        slug, _, _ = resoudre(x["nom"])
        e = {"slug": slug, "nom": x["nom"], "latin": latin, "zone": zone, "preuve": "nas", "src": 0,
             "confiance": "enregistrement_scientifique", "n": x["n"]}
        if x["annee_max"]:
            e["annee_max"] = x["annee_max"]
        entrees.append(e)

    for latin, x in sorted(etat.items()):
        ajout(latin, x, {"type": "etat", "id": usps, "nom": NOMS[usps]})
    for (latin, h), x in sorted(huc.items()):
        ajout(latin, x, {"type": "huc8", "id": h, "nom": "HUC8 " + h})
    return sources, entrees


def collecter(usps):
    res, off = [], 0
    while True:
        for essai in range(4):
            c, d = telecharger(API.format(usps=usps, off=off), timeout=120)
            if c == 200:
                break
            time.sleep(5 * (essai + 1))
        if c != 200:
            raise RuntimeError(f"NAS {usps} offset {off} : HTTP {c}")
        j = json.loads(d)
        res += j.get("results", [])
        if str(j.get("endOfRecords")).lower() == "true" or not j.get("results"):
            break
        off += 500
    return res


def main(etats):
    for usps in etats:
        res = collecter(usps)
        sources, entrees = construire(usps, res)
        p, t = ecrire(usps, "nas", sources, entrees)
        print(usps, "enregistrements:", len(res), "entrees:", len(entrees), t, "octets")


if __name__ == "__main__":
    main(sys.argv[1:] or list(NOMS))
