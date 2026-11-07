#!/usr/bin/env python3
"""Recoupe especes-us.json avec ITIS (nom valide) et USGS NAS (natif/exotique).

Réseau requis. Met à jour en place : verifie.latin, verifie.statut, source[].
Usage : python3 -I recouper_sources.py [especes-us.json]
Une espèce n'est « vérifiée » que si l'autorité la confirme ; sinon [?] (verifie=false).
Hybrides et groupes (spp.) ne sont jamais auto-vérifiés.
"""
import json, sys, time, urllib.parse, urllib.request
from pathlib import Path

ITIS = "https://www.itis.gov/ITISWebService/jsonservice/"
NAS = "https://nas.er.usgs.gov/api/v2/species/search?"
ITIS_PAGE = "https://www.itis.gov/servlet/SingleRpt/SingleRpt?search_topic=TSN&search_value="
NAS_PAGE = "https://nas.er.usgs.gov/queries/FactSheet.aspx?speciesID="


def get(url):
    for _ in range(3):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "FishMe-recoupement/1.0 (liste d'especes)"})
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.loads(r.read().decode("utf-8", "replace"))
        except Exception:
            time.sleep(2)
    return None


def itis(latin):
    d = get(ITIS + "searchByScientificName?srchKey=" + urllib.parse.quote(latin))
    names = [n for n in (d or {}).get("scientificNames", []) if n and n["combinedName"].lower() == latin.lower()]
    if not names:
        return None
    tsn = names[0]["tsn"]
    f = get(ITIS + "getFullRecordFromTSN?tsn=" + tsn) or {}
    rating = ((f.get("usage") or {}).get("taxonUsageRating") or "").lower()
    return {"tsn": tsn, "valide": rating in ("valid", "accepted")}


def nas(latin):
    parts = latin.split()
    if len(parts) < 2:
        return None
    q = {"genus": parts[0], "species": parts[1]}
    d = get(NAS + urllib.parse.urlencode(q))
    res = [r for r in (d or {}).get("results", []) if not r.get("variety")]
    if len(parts) > 2:
        sub = [r for r in res if r.get("subspecies") == parts[2]]
        res = sub or res
    if not res:
        return None
    return {"id": res[0]["speciesID"], "natif": str(res[0]["native_exotic"]).startswith("Native")}


def main(path):
    p = Path(path)
    data = json.loads(p.read_text(encoding="utf-8"))
    for e in data:
        lat = e["latin"]
        e["source"] = []
        e["verifie"] = {"latin": False, "statut": False}
        if e["hybride"]:
            e["a_verifier"] = "[?] hybride d'élevage : ni ITIS ni NAS ne le portent comme espèce ; parents vérifiés séparément"
            continue
        i = itis(lat.replace(" spp.", ""))
        if i and i["valide"]:
            e["verifie"]["latin"] = True
            e["source"].append({"autorite": "ITIS", "tsn": i["tsn"], "url": ITIS_PAGE + i["tsn"]})
        n = None if "spp." in lat else nas(lat)
        if n:
            e["source"].append({"autorite": "USGS NAS", "id": n["id"], "url": NAS_PAGE + str(n["id"]),
                                "natif_aux_etats_unis": n["natif"]})
            attendu_natif = e["statut"] == "native"
            e["verifie"]["statut"] = (n["natif"] == attendu_natif)
        e.pop("a_verifier", None)
        manque = [k for k, v in e["verifie"].items() if not v]
        if manque:
            e["a_verifier"] = "[?] non confirmé par ITIS/USGS NAS : " + ", ".join(manque)
        print(e["slug"], e["verifie"], file=sys.stderr)
    p.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else str(Path(__file__).with_name("especes-us.json")))
