#!/usr/bin/env python3
"""US15, groupe ouest-int (AZ, NV, OR) : ce que les scripts partagés ne savent pas faire, sans les modifier.

1. `osm` : télécharge les rampes cartographiées par OpenStreetMap (Overpass, dernier recours) et les range dans
   <brut>/osm-<USPS>.json. Peu de requêtes, pause, User-Agent honnête, jamais de contournement.
2. `injecter` : ajoute au couches-us-<USPS>.json de construire_etat.py une couche « acces_osm » (licence ODbL, texte de source
   « point cartographié par OpenStreetMap », jamais « listé par l'agence »).
3. `embarquer` : lance embarquer.main avec deux corrections de construire_points : (a) le texte de source nomme l'éditeur de
   la couche (BLM, USFS, NPS, OSMB…) et non « l'agence » de l'État ; (b) les points hors du contour de l'État (pris par la
   boîte englobante des services fédéraux) sont retirés.

Usage :
  python3 ouest_int.py osm AZ --brut /chemin/brut/AZ
  python3 ouest_int.py injecter AZ --brut /chemin/brut/AZ
  python3 ouest_int.py embarquer AZ --brut /chemin/brut/AZ --sortie ../../../Packages/Core/Sources/Core/Resources/geo-us
"""
import argparse
import datetime
import json
import os
import sys
import time
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import embarquer  # noqa: E402

OVERPASS = "https://overpass-api.de/api/interpreter"
UA = "FishMe-data/1.0 (contact: fishme.app@gmail.com)"
REQUETE = ('[out:json][timeout:120];area["ISO3166-2"="US-{usps}"]->.a;'
           '(nwr["leisure"="slipway"](area.a);nwr["amenity"="boat_ramp"](area.a););out center tags;')
COUCHE_OSM = dict(
    id="acces_osm", role="acces", nom="Rampes de mise à l'eau cartographiées par OpenStreetMap", geometrie="point",
    statut="ok", source="point cartographié par OpenStreetMap (leisure=slipway, amenity=boat_ramp ; access=private et access=no exclus)",
    editeur="OpenStreetMap", url_source="https://www.openstreetmap.org/copyright",
    licence="ODbL 1.0, © contributeurs OpenStreetMap", confidentialite="public",
    note="Source de dernier recours : aucune couche ouverte d'agence ne couvre cet État pour les rampes.")


def telecharger_osm(usps, pauses=(0, 20, 60)):
    corps = urllib.parse.urlencode({"data": REQUETE.format(usps=usps)}).encode()
    derniere = None
    for p in pauses:
        time.sleep(p)
        try:
            req = urllib.request.Request(OVERPASS, data=corps, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=180) as r:
                return json.load(r)
        except Exception as e:  # noqa: BLE001 : on réessaie avec une pause, jamais de contournement
            derniere = e
            print("  Overpass :", e)
    raise RuntimeError(f"Overpass indisponible : {derniere}")


def objets_osm(brut_osm, usps):
    """Features GeoJSON légères : id osm, nom, type. Aucun autre tag copié (ni contact, ni note)."""
    feats, vus = [], set()
    for el in brut_osm.get("elements", []):
        tags = el.get("tags") or {}
        if (tags.get("access") or "").lower() in ("private", "no"):
            continue
        lat = el.get("lat") if el["type"] == "node" else (el.get("center") or {}).get("lat")
        lon = el.get("lon") if el["type"] == "node" else (el.get("center") or {}).get("lon")
        if lat is None or lon is None:
            continue
        ident = f"osm:{el['type'][0]}{el['id']}"
        if ident in vus:
            continue
        vus.add(ident)
        nom = (tags.get("name") or "").strip() or None
        type_ = "rampe" if tags.get("boat") != "no" else "acces"
        props = {"id": ident, "type": type_, "coin": "acces"}
        if nom:
            props["nom"] = nom
        feats.append({"type": "Feature", "geometry": {"type": "Point", "coordinates": [round(lon, 5), round(lat, 5)]},
                      "properties": props})
    return feats


def injecter(usps, brut, date):
    with open(os.path.join(brut, f"osm-{usps}.json"), encoding="utf-8") as f:
        feats = objets_osm(json.load(f), usps)
    chemin = os.path.join(brut, f"couches-us-{usps}.json")
    with open(chemin, encoding="utf-8") as f:
        doc = json.load(f)
    doc["couches"] = [c for c in doc["couches"] if c["id"] != "acces_osm"]
    c = dict(COUCHE_OSM, date_source="continue (données OSM)", date_lecture=date, compte=len(feats),
             collection={"type": "FeatureCollection", "features": feats})
    doc["couches"].append(c)
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
    return len(feats)


def construire_points_corrige(brut):
    original = embarquer.construire_points

    def corrige(usps, doc, date_lecture):
        chemin = os.path.join(brut, f"contour-{usps}.json")
        contour = None
        if os.path.exists(chemin):
            with open(chemin, encoding="utf-8") as f:
                contour = json.load(f)
        sources, lignes, vus = [], [], set()
        for c in doc["couches"]:
            if c.get("role") != "acces" or c.get("statut") != "ok":
                continue
            if c["id"] == "acces_osm":
                txt = f"point cartographié par OpenStreetMap, {c['source']}"
            else:
                txt = f"accès public listé par {c.get('editeur') or embarquer.AGENCES.get(usps, usps)}, {c['source']}"
            sources.append(dict(texte=txt, licence=c["licence"], url=c["url_source"], date=date_lecture))
            k = len(sources) - 1
            for f in c["collection"]["features"]:
                p = f["properties"]
                if f["geometry"]["type"] != "Point" or p["id"] in vus:
                    continue
                lon, lat = f["geometry"]["coordinates"][:2]
                if not embarquer.dans_etat(lon, lat, contour):
                    continue
                vus.add(p["id"])
                nom = (p.get("nom") or "").strip() or (p.get("eau") or "").strip() or "Accès sans nom"
                lignes.append([p["id"], nom, round(lat, 5), round(lon, 5),
                               embarquer.TYPES_ACCES.get(p.get("type"), "autre"), k])
        lignes.sort(key=lambda r: r[0])
        res = original(usps, dict(doc, couches=[]), date_lecture)
        res.update(compte=len(lignes), sources=sources, points=lignes)
        return res

    embarquer.construire_points = corrige


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("action", choices=["osm", "injecter", "embarquer"])
    ap.add_argument("usps")
    ap.add_argument("--brut", required=True)
    ap.add_argument("--sortie")
    ap.add_argument("--date", default=datetime.date.today().isoformat())
    a = ap.parse_args(argv)
    usps = a.usps.upper()
    if a.action == "osm":
        os.makedirs(a.brut, exist_ok=True)
        d = telecharger_osm(usps)
        with open(os.path.join(a.brut, f"osm-{usps}.json"), "w", encoding="utf-8") as f:
            json.dump(d, f, separators=(",", ":"))
        print(f"{usps} : {len(d.get('elements', []))} éléments OSM")
        return 0
    if a.action == "injecter":
        print(f"{usps} : {injecter(usps, a.brut, a.date)} points OSM injectés")
        return 0
    construire_points_corrige(a.brut)
    return embarquer.main([usps, "--brut", a.brut, "--sortie", a.sortie, "--date", a.date])


if __name__ == "__main__":
    sys.exit(main())
