#!/usr/bin/env python3
"""Dernier recours : rampes de mise à l'eau d'un État depuis OpenStreetMap (Overpass), quand la source de l'agence est injoignable.

Écrit <brut>/couches-us-<USPS>.json au format de construire_etat.py (une couche `acces`), que embarquer.py lit ensuite.
Seuls leisure=slipway et amenity=boat_ramp sont pris ; access=private, no et customers sont exclus ; seul le nom est copié.
Licence : ODbL 1.0, © contributeurs OpenStreetMap. Le texte de source dit « point cartographié par OpenStreetMap », jamais « listé par l'agence ».

  python3 osm_acces.py MT --brut /chemin/brut                  # télécharge (1 requête) puis écrit couches-us-MT.json
  python3 osm_acces.py MT --brut /chemin/brut --corriger-points /chemin/geo-us/MT-points.json
    (embarquer.py écrit « accès public listé par <agence> » : cette étape remplace ce texte par celui d'OpenStreetMap)
"""
import argparse
import datetime
import json
import math
import os
import sys
import urllib.parse
import urllib.request

ICI = os.path.dirname(os.path.abspath(__file__))
OVERPASS = "https://overpass-api.de/api/interpreter"
USER_AGENT = "FishMe-data/1.0 (fishme.app@gmail.com)"
EXCLUS = {"private", "no", "customers"}
TEXTE_SOURCE = "point cartographié par OpenStreetMap (contributeurs), rampes de mise à l'eau"
LICENCE = "ODbL 1.0, © contributeurs OpenStreetMap"
URL_SOURCE = "https://www.openstreetmap.org/copyright"


def requete(usps):
    return ('[out:json][timeout:120];area["ISO3166-2"="US-%s"]->.a;'
            '(nwr["leisure"="slipway"](area.a);nwr["amenity"="boat_ramp"](area.a););out center tags;' % usps)


def telecharger(usps):
    donnees = urllib.parse.urlencode({"data": requete(usps)}).encode()
    req = urllib.request.Request(OVERPASS, data=donnees, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.loads(r.read().decode("utf-8"))


def _distance_m(a, b):
    dx = (a[0] - b[0]) * 111320.0 * math.cos(math.radians((a[1] + b[1]) / 2))
    dy = (a[1] - b[1]) * 110540.0
    return math.hypot(dx, dy)


def points(brut, usps):
    """Features Point (lon, lat arrondis à 5 décimales) ; un objet à moins de 20 m d'un autre déjà pris est écarté (nœud et chemin du même quai)."""
    pref = usps.lower()
    feats, gardes = [], []
    for e in brut.get("elements", []):
        tags = e.get("tags") or {}
        if (tags.get("access") or "").lower() in EXCLUS:
            continue
        if e.get("type") == "node":
            lon, lat = e.get("lon"), e.get("lat")
        else:
            c = e.get("center") or {}
            lon, lat = c.get("lon"), c.get("lat")
        if lon is None or lat is None:
            continue
        if any(_distance_m((lon, lat), g) < 20 for g in gardes):
            continue
        gardes.append((lon, lat))
        nom = (tags.get("name") or "").strip() or None
        props = {"id": f"{pref}-osm:{e['type'][0]}{e['id']}", "type": "rampe", "coin": "acces"}
        if nom:
            props["nom"] = nom
        feats.append({"type": "Feature", "geometry": {"type": "Point", "coordinates": [round(lon, 5), round(lat, 5)]},
                      "properties": props})
    return feats


def construire_doc(usps, brut, cfg, date_lecture):
    feats = points(brut, usps)
    base = ((brut.get("osm3s") or {}).get("timestamp_osm_base") or "")[:10] or "[?]"
    couche = {"id": "acces_osm", "role": "acces", "nom": "Rampes de mise à l'eau (OpenStreetMap)", "geometrie": "point",
              "source": TEXTE_SOURCE, "editeur": "contributeurs OpenStreetMap", "url_source": URL_SOURCE, "licence": LICENCE,
              "date_source": base, "date_lecture": date_lecture, "confidentialite": "public",
              "note": "Dernier recours : la source de l'agence était injoignable. Aucune liste d'agence ; qualité inégale.",
              "statut": "ok", "compte": len(feats), "collection": {"type": "FeatureCollection", "features": feats}}
    return {"format": "fishme-couches-us/1", "etat": usps, "nom": cfg["nom"], "emprise": cfg["emprise"], "emprise_etat": cfg["emprise"],
            "liens_etat": cfg.get("liens_etat", {}), "couches": [couche]}


def corriger_points(chemin):
    with open(chemin, encoding="utf-8") as f:
        d = json.load(f)
    for s in d.get("sources", []):
        s["texte"] = TEXTE_SOURCE
    d["mention"] = "Points cartographiés par OpenStreetMap, source et date ci-dessous ; ce n'est ni un droit de pêche ni une garantie d'accès."
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("usps")
    ap.add_argument("--brut", required=True)
    ap.add_argument("--corriger-points")
    ap.add_argument("--date", default=datetime.date.today().isoformat())
    a = ap.parse_args(argv)
    usps = a.usps.upper()
    if a.corriger_points:
        corriger_points(a.corriger_points)
        return 0
    with open(os.path.join(ICI, "etats", f"{usps}.json"), encoding="utf-8") as f:
        cfg = json.load(f)
    os.makedirs(a.brut, exist_ok=True)
    cache = os.path.join(a.brut, f"osm-{usps}.json")
    if os.path.exists(cache):
        with open(cache, encoding="utf-8") as f:
            brut = json.load(f)
    else:
        brut = telecharger(usps)
        with open(cache, "w", encoding="utf-8") as f:
            json.dump(brut, f, separators=(",", ":"))
    doc = construire_doc(usps, brut, cfg, a.date)
    with open(os.path.join(a.brut, f"couches-us-{usps}.json"), "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
    print(f"{usps} : {doc['couches'][0]['compte']} rampes OpenStreetMap")
    return 0


if __name__ == "__main__":
    sys.exit(main())
