#!/usr/bin/env python3
"""US16 : <USPS>-nas.json depuis l'USGS NAS (occurrences de poissons introduits ou transplantés, par État).
Usage : python3 esp6_nas.py MI WI MN IA MO   (réseau ; écrit dans Packages/Core/Sources/Core/Resources/especes-us/)
Garde : les espèces de especes-us.json seulement, statuts autres que failed/eradicated/extirpated ; agrège (espèce, HUC8) : n, annee_max."""
import json, os, sys, time, collections, datetime
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from esp6_fetchlib import get

ICI = os.path.dirname(os.path.abspath(__file__))
ESP = os.path.join(ICI, "..", "especes-us.json")
SORTIE = os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
EXCLUS = {"failed", "eradicated", "extirpated"}
API = "https://nas.er.usgs.gov/api/v2/occurrence/search"


def table_latin():
    t = {}
    for e in json.load(open(ESP, encoding="utf-8")):
        p = e["latin"].split()
        if len(p) >= 2 and " x " not in e["latin"] and "spp" not in e["latin"]:
            t.setdefault(p[0] + " " + p[1], e)
    return t


def occurrences(usps):
    out, off = [], 0
    while True:
        for essai in range(5):
            code, txt = get(f"{API}?state={usps}&group=Fishes&limit=500&offset={off}")
            if code == 200:
                break
            time.sleep(5 * (essai + 1))
        if code != 200:
            raise SystemExit(f"NAS {usps} : HTTP {code}")
        j = json.loads(txt)
        out += j["results"]
        if str(j.get("endOfRecords")).lower() == "true" or not j["results"]:
            return out
        off += 500


def construire(usps, occ, table, date):
    par_etat, par_huc = collections.OrderedDict(), collections.OrderedDict()
    ignores = collections.Counter()
    for o in occ:
        if str(o.get("status", "")).lower() in EXCLUS:
            continue
        nom = f"{o.get('genus', '')} {o.get('species', '')}".strip() or o.get("scientificName", "")
        e = table.get(nom)
        if not e:
            ignores[nom] += 1
            continue
        y = o.get("year") if isinstance(o.get("year"), int) else None
        for cle, d in ((e["slug"], par_etat), ((e["slug"], o.get("huc8") or ""), par_huc)):
            if d is par_huc and not o.get("huc8"):
                continue
            x = d.setdefault(cle, {"e": e, "n": 0, "y": None, "nom": o.get("huc8Name") or ""})
            x["n"] += 1
            if y and (x["y"] is None or y > x["y"]):
                x["y"] = y
    entrees = []
    for slug, x in sorted(par_etat.items()):
        entrees.append(dict(slug=slug, nom=x["e"]["nom_en"], latin=x["e"]["latin"], zone={"type": "etat", "id": usps, "nom": usps},
                            preuve="nas", src=0, confiance="enregistrement_scientifique", n=x["n"], **({"annee_max": x["y"]} if x["y"] else {})))
    for (slug, huc), x in sorted(par_huc.items()):
        entrees.append(dict(slug=slug, nom=x["e"]["nom_en"], latin=x["e"]["latin"], zone={"type": "huc8", "id": huc, "nom": x["nom"] or huc},
                            preuve="nas", src=0, confiance="enregistrement_scientifique", n=x["n"], **({"annee_max": x["y"]} if x["y"] else {})))
    doc = {"format": "fishme-especes-us/1", "etat": usps, "producteur": "nas", "date": date,
           "sources": [{"nom": "USGS Nonindigenous Aquatic Species (NAS), occurrences de poissons : espèces introduites ou transplantées signalées dans l'État (pas la liste des espèces natives)",
                        "url": f"https://nas.er.usgs.gov/queries/SpeciesList.aspx?Group=Fishes&state={usps}", "licence": "domaine public fédéral", "date": date}],
           "entrees": entrees}
    return doc, ignores


if __name__ == "__main__":
    date = datetime.date.today().isoformat() if len(sys.argv) < 2 or not sys.argv[1].startswith("--date=") else sys.argv[1][7:]
    table = table_latin()
    for usps in [a for a in sys.argv[1:] if not a.startswith("--")]:
        occ = occurrences(usps)
        doc, ign = construire(usps, occ, table, "2026-11-08")
        os.makedirs(SORTIE, exist_ok=True)
        p = os.path.join(SORTIE, f"{usps}-nas.json")
        json.dump(doc, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=0, separators=(",", ":"))
        print(usps, len(occ), "occurrences ;", len(doc["entrees"]), "entrées ;", os.path.getsize(p) // 1024, "Ko ; hors table :", sum(ign.values()))
