#!/usr/bin/env python3
"""Illinois : points d'accès à l'eau cartographiés par OpenStreetMap (DERNIER recours : aucune source d'agence ouverte et joignable trouvée).

Interroge Overpass (une requête, User-Agent honnête) pour leisure=slipway et amenity=boat_ramp dans la zone Illinois, écarte access=private/no,
et écrit <brut>/couches-us-IL.json au format de construire_etat.py (couche `acces`, role acces) pour embarquer.py.
Licence : ODbL 1.0, © contributeurs OpenStreetMap. Texte de source : « point cartographié par OpenStreetMap », jamais « listé par l'agence ».
Les noms viennent du seul tag `name`. Aucun téléphone, site web, note ni autre tag n'est copié.

Usage : python3 osm_il.py --brut /private/tmp/claude-501/brut-us/IL [--entree reponse-overpass.json]
        python3 osm_il.py --corriger-textes ../../../Packages/Core/Sources/Core/Resources/geo-us/IL-points.json
"""
import argparse
import datetime
import json
import os
import subprocess
import sys

OVERPASS = "https://overpass-api.de/api/interpreter"
UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
REQUETE = ('[out:json][timeout:120];area["ISO3166-2"="US-IL"]->.a;'
           '(nwr["leisure"="slipway"](area.a);nwr["amenity"="boat_ramp"](area.a););out center tags;')
SOURCE = "point cartographié par OpenStreetMap (leisure=slipway ou amenity=boat_ramp), via Overpass"
LICENCE = "ODbL 1.0, © contributeurs OpenStreetMap"
URL = "https://www.openstreetmap.org/copyright"
TEXTE_PRIVE = {"private", "no", "customers", "permit", "members"}


def telecharger():
    # curl : le Python d'Xcode échoue la poignée de main TLS avec overpass-api.de (SSLV3_ALERT_HANDSHAKE_FAILURE)
    sortie = subprocess.run(["curl", "-s", "-m", "200", "-A", UA, "--data-urlencode", "data=" + REQUETE, OVERPASS],
                            check=True, capture_output=True)
    return json.loads(sortie.stdout.decode("utf-8"))


def points(rep):
    vus, feats = set(), []
    for e in rep.get("elements", []):
        t = e.get("tags") or {}
        if (t.get("access") or "").lower() in TEXTE_PRIVE:
            continue
        lon, lat = (e["lon"], e["lat"]) if e["type"] == "node" else (e.get("center", {}).get("lon"), e.get("center", {}).get("lat"))
        if lon is None or lat is None:
            continue
        ident = f"osm-il:{e['type'][0]}{e['id']}"
        if ident in vus:
            continue
        vus.add(ident)
        nom = (t.get("name") or "").strip() or None
        p = {"id": ident, "type": "rampe", "coin": "acces"}
        if nom:
            p["nom"] = nom
        feats.append({"type": "Feature", "geometry": {"type": "Point", "coordinates": [round(lon, 5), round(lat, 5)]}, "properties": p})
    return feats


def construire(rep, date):
    feats = points(rep)
    couche = {"id": "acces", "role": "acces", "nom": "Rampes de mise à l'eau cartographiées par OpenStreetMap", "geometrie": "point",
              "source": SOURCE, "editeur": "contributeurs OpenStreetMap", "url_source": URL, "licence": LICENCE,
              "date_source": rep.get("osm3s", {}).get("timestamp_osm_base", "[?]"), "date_lecture": date, "confidentialite": "public",
              "note": "Dernier recours : aucune source d'agence ouverte et joignable trouvée pour l'Illinois ; access=private et access=no écartés.",
              "statut": "ok", "compte": len(feats), "collection": {"type": "FeatureCollection", "features": feats}}
    return {"format": "fishme-couches-us/1", "etat": "IL", "nom": "Illinois", "genere": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "couches": [couche]}


def corriger_textes(chemin):
    """embarquer.py écrit « accès public listé par <agence> » ; pour OSM le texte doit dire « point cartographié par OpenStreetMap »."""
    with open(chemin, encoding="utf-8") as f:
        d = json.load(f)
    for s in d.get("sources", []):
        s["texte"] = SOURCE
    d["mention"] = ("Point cartographié par OpenStreetMap (bénévoles), pas une liste d'agence ; ce n'est ni un droit de pêche "
                    "ni une garantie d'accès. Source et date ci-dessous.")
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--brut")
    ap.add_argument("--entree", help="réponse Overpass déjà téléchargée (sinon une requête est envoyée)")
    ap.add_argument("--date", default=datetime.date.today().isoformat())
    ap.add_argument("--corriger-textes")
    a = ap.parse_args(argv)
    if a.corriger_textes:
        corriger_textes(a.corriger_textes)
        return 0
    if a.entree:
        with open(a.entree, encoding="utf-8") as f:
            rep = json.load(f)
    else:
        rep = telecharger()
    doc = construire(rep, a.date)
    os.makedirs(a.brut, exist_ok=True)
    chemin = os.path.join(a.brut, "couches-us-IL.json")
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
    print(f"{chemin} : {doc['couches'][0]['compte']} points")
    return 0


if __name__ == "__main__":
    sys.exit(main())
