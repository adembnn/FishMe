#!/usr/bin/env python3
"""Construit sortie/couches-us-<USPS>.json depuis etats/<USPS>.json (+ etats/_communes.json).

Usage :
  python3 construire_etat.py MN                         # tout l'État (peut être long et lourd pour les tracés)
  python3 construire_etat.py MN --couches acces         # une couche seulement
  python3 construire_etat.py MN --emprise -94.35,46.45,-94.20,46.60 --sortie /tmp/essai   # échantillon
Python 3.9+, bibliothèque standard seulement. Le dossier sortie/ est ignoré par git (données fabriquées).
"""
import argparse
import datetime
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import arcgis  # noqa: E402
import normaliser  # noqa: E402

ICI = os.path.dirname(os.path.abspath(__file__))
FORMAT = "fishme-couches-us/1"
AVERTISSEMENT = ("Données d'agences publiques, indicatives. Une terre publique n'est pas un droit de pêche ; "
                 "un accès listé n'est pas une garantie d'accès ; l'agence de l'État fait foi (lien et date affichés).")


def charger_config(usps, dossier=None):
    dossier = dossier or os.path.join(ICI, "etats")
    with open(os.path.join(dossier, f"{usps}.json"), encoding="utf-8") as f:
        cfg = json.load(f)
    couches = list(cfg.get("couches", []))
    if cfg.get("communes"):
        with open(os.path.join(dossier, "_communes.json"), encoding="utf-8") as f:
            couches = json.load(f)["couches"] + couches
    cfg["couches"] = couches
    return cfg


def _date_service(meta):
    ms = ((meta or {}).get("editingInfo") or {}).get("dataLastEditDate")
    return normaliser._ymd(ms)


def construire_couche(c, cfg, emprise, http=arcgis.http_json, max_objets=None, ordre_min=None, log=print, dormir=None):
    usps = cfg["etat"]
    sortie = {k: c.get(k) for k in ("id", "role", "nom", "geometrie", "source", "editeur", "url_source", "licence",
                                    "date_source", "date_lecture", "confidentialite", "note")}
    sortie["statut"] = c.get("statut", "ok")
    if not c.get("service") or sortie["statut"] == "absent":
        sortie["statut"] = "absent"
        sortie["compte"] = 0
        sortie["date_lecture"] = datetime.date.today().isoformat()
        return sortie
    if c.get("etats_couverts") and usps not in c["etats_couverts"]:
        sortie["statut"] = "absent_du_service"
        sortie["compte"] = 0
        sortie["date_lecture"] = datetime.date.today().isoformat()
        return sortie
    where = (c.get("where") or "1=1").replace("{USPS}", usps)
    if ordre_min is not None and c["normaliseur"] == "trace_3dhp":
        where = f"streamorder >= {int(ordre_min)}"
    dom = {}
    try:
        meta = arcgis.metadonnees(c["service"], c["couche"], http)
        dom = {f["name"]: f["domain"]["codedValues"] for f in meta.get("fields", [])
               if f.get("domain") and f["domain"].get("codedValues")}
        d = _date_service(meta)
        if d:
            sortie["date_source_service"] = d
    except Exception as e:  # la fiche est un bonus : on continue sans domaines
        log(f"  fiche de couche illisible ({e})")
    brut, total = arcgis.telecharger(c["service"], c["couche"], emprise, where, "*", c.get("generalisation"),
                                     max_objets=max_objets, http=http, log=log,
                                     **({"dormir": dormir, "pause": 0} if dormir else {}))
    norm = NORMALISEURS_FN(c["normaliseur"])
    vus, feats = set(), []
    for f in brut:
        if not f.get("geometry"):
            continue
        n = norm(f, dom)
        if not n or n["properties"]["id"] in vus:
            continue
        vus.add(n["properties"]["id"])
        n["geometry"] = normaliser.rogner_aux_parties(n["geometry"], emprise)
        if not n["geometry"]:
            continue
        # simplification côté client : certains serveurs ignorent maxAllowableOffset en GeoJSON
        n["geometry"] = normaliser.simplifier(n["geometry"], c.get("generalisation"))
        if not n["geometry"]:
            continue
        n["geometry"] = normaliser.arrondir(n["geometry"], c.get("decimales", 4))
        feats.append(n)
    sortie["compte"] = len(feats)
    sortie["compte_service_dans_emprise"] = total
    sortie["collection"] = {"type": "FeatureCollection", "features": feats}
    return sortie


def NORMALISEURS_FN(nom):
    return normaliser.NORMALISEURS[nom]


def construire(usps, emprise=None, ids=None, http=arcgis.http_json, max_objets=None, ordre_min=None, log=print,
               dossier_config=None, dormir=None):
    cfg = charger_config(usps, dossier_config)
    emprise = emprise or cfg["emprise"]
    couches = []
    for c in cfg["couches"]:
        if ids and c["id"] not in ids:
            continue
        log(f"[{usps}] couche {c['id']}")
        couches.append(construire_couche(c, cfg, emprise, http, max_objets, ordre_min, log, dormir))
    return {"format": FORMAT, "etat": usps, "nom": cfg["nom"], "genere": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "emprise": list(emprise), "emprise_etat": cfg["emprise"], "liens_etat": cfg.get("liens_etat", {}),
            "avertissement": AVERTISSEMENT, "couches": couches}


def ecrire(doc, dossier):
    os.makedirs(dossier, exist_ok=True)
    chemin = os.path.join(dossier, f"couches-us-{doc['etat']}.json")
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
    return chemin


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("usps")
    ap.add_argument("--emprise", help="minLon,minLat,maxLon,maxLat (défaut : emprise de l'État)")
    ap.add_argument("--couches", help="identifiants séparés par des virgules")
    ap.add_argument("--max-objets", type=int)
    ap.add_argument("--ordre-min", type=int, help="ordre de Strahler minimal des tracés (défaut du fichier : 3)")
    ap.add_argument("--sortie", default=os.path.join(ICI, "sortie"))
    ap.add_argument("--lister", action="store_true", help="liste les couches de l'État sans rien télécharger")
    a = ap.parse_args(argv)
    usps = a.usps.upper()
    if a.lister:
        for c in charger_config(usps)["couches"]:
            print(f"{c['id']:20} {c.get('statut','ok'):10} {c['role']:18} {c.get('licence','')[:60]}")
        return 0
    emprise = [float(x) for x in a.emprise.split(",")] if a.emprise else None
    doc = construire(usps, emprise, a.couches.split(",") if a.couches else None, max_objets=a.max_objets, ordre_min=a.ordre_min)
    chemin = ecrire(doc, a.sortie)
    print(f"✓ {chemin} ({os.path.getsize(chemin) / 1e6:.3f} Mo)")
    for c in doc["couches"]:
        print(f"  {c['id']:22} {c['statut']:18} {c['compte']:>7} objets")
    return 0


if __name__ == "__main__":
    sys.exit(main())
