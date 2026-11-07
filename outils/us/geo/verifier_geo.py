#!/usr/bin/env python3
"""Vérifie un ou plusieurs fichiers couches-us-<USPS>.json.

Contrôles : format, licence/source/date renseignées par couche, comptage cohérent, emprise valide, aucune coordonnée hors des
États-Unis ni hors de l'emprise de l'État (marge), précision des coordonnées (confidentialité), aucune donnée personnelle
(téléphone, e-mail, champs interdits), identifiants uniques, type de géométrie conforme.
Usage : python3 verifier_geo.py sortie/couches-us-MN.json [--strict] [--min-objets acces=10]
Code de sortie : 0 si aucune erreur (les avertissements ne comptent pas, sauf --strict : licence « [?] » ou couche vide = erreur).
Limite connue : l'emprise d'un État est une boîte ; elle déborde sur le Canada (MI, MN nord-est) : un point canadien dans la boîte passe.
"""
import argparse
import json
import math
import os
import re
import sys

FORMAT = "fishme-couches-us/1"
STATUTS = {"ok", "absent", "absent_du_service", "a_confirmer"}
# Boîtes des États-Unis (lat_min, lat_max, lon_min, lon_max) : 48 États contigus, Alaska (côté est de l'antiméridien), Hawaï, Porto Rico/îles Vierges.
BOITES_US = [(24.3, 49.5, -125.1, -66.8), (51.0, 71.6, -170.0, -129.0), (18.8, 22.4, -160.7, -154.7), (17.6, 18.6, -67.4, -64.5)]
CLES_INTERDITES = {"phone", "telephone", "tel", "contact", "email", "mail", "comments", "comment", "directions", "notes", "note",
                   "spot", "spots", "prise", "prises", "utilisateur", "user", "owner_phone", "ownership_manager_phone_text", "gps"}
RE_TEL = re.compile(r"(\+?1[\s.-]?)?\(?\b\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}\b")
RE_MAIL = re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+")
TYPES_GEO = {"point": {"Point"}, "ligne": {"LineString", "MultiLineString"}, "polygone": {"Polygon", "MultiPolygon"}}
OBLIGATOIRES = ("source", "editeur", "url_source", "licence", "date_source", "date_lecture", "role", "nom", "statut")


def dans_us(lon, lat):
    return any(a <= lat <= b and c <= lon <= d for a, b, c, d in BOITES_US)


def decimales(x):
    s = repr(float(x))
    return len(s.split(".")[1]) if "." in s and "e" not in s else 0


def positions(coords):
    if coords and isinstance(coords[0], (int, float)):
        yield coords
    else:
        for c in coords:
            yield from positions(c)


def verifier_doc(doc, strict=False, minimums=None):
    """Renvoie (erreurs, avertissements)."""
    err, avert = [], []
    minimums = minimums or {}
    if doc.get("format") != FORMAT:
        err.append(f"format inattendu : {doc.get('format')!r}")
    usps = doc.get("etat")
    if not (isinstance(usps, str) and re.fullmatch(r"[A-Z]{2}", usps)):
        err.append(f"code USPS invalide : {usps!r}")
    for k in ("emprise", "emprise_etat"):
        e = doc.get(k)
        if not (isinstance(e, list) and len(e) == 4 and all(isinstance(x, (int, float)) for x in e) and e[0] < e[2] and e[1] < e[3]):
            err.append(f"{k} invalide : {e!r}")
        elif not (dans_us(e[0], e[1]) and dans_us(e[2], e[3])):
            err.append(f"{k} hors des États-Unis : {e!r}")
    if not doc.get("avertissement"):
        err.append("avertissement absent")
    if err and not isinstance(doc.get("couches"), list):
        return err, avert
    be = doc.get("emprise_etat") or [-180, -90, 180, 90]
    marge = 0.3
    ids_couches = set()
    for c in doc.get("couches", []):
        cid = c.get("id") or "?"
        pre = f"couche {cid} : "
        if cid in ids_couches:
            err.append(pre + "identifiant de couche en double")
        ids_couches.add(cid)
        absente = c.get("statut") in ("absent", "absent_du_service")
        for k in (("role", "nom", "statut", "note", "date_lecture") if absente else OBLIGATOIRES):
            if not str(c.get(k) or "").strip():
                err.append(pre + f"« {k} » non renseigné")
        if c.get("statut") not in STATUTS:
            err.append(pre + f"statut inconnu {c.get('statut')!r}")
        lic = str(c.get("licence") or "")
        if lic.startswith("[?]") or "[?]" in lic:
            (err if strict else avert).append(pre + "licence à confirmer [?]")
        if c.get("statut") in ("absent", "absent_du_service"):
            if c.get("compte") != 0 or c.get("collection"):
                err.append(pre + "couche absente mais avec des objets")
            continue
        col = c.get("collection") or {}
        feats = col.get("features") if col.get("type") == "FeatureCollection" else None
        if feats is None:
            err.append(pre + "collection GeoJSON manquante")
            continue
        if c.get("compte") != len(feats):
            err.append(pre + f"compte {c.get('compte')} != {len(feats)} objets")
        if len(feats) < minimums.get(cid, 0):
            err.append(pre + f"{len(feats)} objets, minimum attendu {minimums[cid]}")
        elif not feats:
            (err if strict else avert).append(pre + "aucun objet")
        autorises = TYPES_GEO.get(c.get("geometrie"))
        if autorises is None:
            err.append(pre + f"geometrie inconnue {c.get('geometrie')!r}")
            continue
        vus, mauvais_geo, hors_us, hors_emprise, trop_precis, perso, debord = set(), 0, 0, 0, 0, 0, 0
        dmax = 5 if c.get("geometrie") == "point" else 4
        for f in feats:
            p = f.get("properties") or {}
            i = p.get("id")
            if not i or i in vus:
                err.append(pre + f"identifiant manquant ou en double : {i!r}")
                break
            vus.add(i)
            g = f.get("geometry") or {}
            if g.get("type") not in autorises:
                mauvais_geo += 1
                continue
            for pos in positions(g.get("coordinates")):
                lon, lat = pos[0], pos[1]
                if not (math.isfinite(lon) and math.isfinite(lat)) or not dans_us(lon, lat):
                    hors_us += 1
                elif not (be[0] - marge <= lon <= be[2] + marge and be[1] - marge <= lat <= be[3] + marge):
                    if c.get("geometrie") == "point":
                        hors_emprise += 1
                    else:  # lacs frontaliers (Michigan, Supérieur), fleuves : un tracé peut déborder, c'est normal
                        debord += 1
                if decimales(lon) > dmax or decimales(lat) > dmax:
                    trop_precis += 1
            for k, v in p.items():
                if k.lower() in CLES_INTERDITES or (isinstance(v, str) and (RE_TEL.search(v) or RE_MAIL.search(v))):
                    perso += 1
        if debord:
            avert.append(pre + f"{debord} sommets au-delà de l'emprise de l'État (eaux ou terres frontalières, toujours aux États-Unis)")
        for n, msg in ((mauvais_geo, "géométrie de type inattendu"), (hors_us, "coordonnées hors des États-Unis"),
                       (hors_emprise, f"points hors de l'emprise de l'État (+{marge}°)"),
                       (trop_precis, f"coordonnées trop précises (> {dmax} décimales)"), (perso, "donnée personnelle ou champ interdit")):
            if n:
                err.append(pre + f"{n} {msg}")
    return err, avert


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("fichiers", nargs="+")
    ap.add_argument("--strict", action="store_true")
    ap.add_argument("--min-objets", action="append", default=[], help="couche=N (répétable)")
    a = ap.parse_args(argv)
    minimums = {k: int(v) for k, v in (x.split("=") for x in a.min_objets)}
    code = 0
    for chemin in a.fichiers:
        try:
            with open(chemin, encoding="utf-8") as f:
                doc = json.load(f)
        except (OSError, json.JSONDecodeError) as e:
            print(f"✗ {chemin} : illisible ({e})")
            code = 1
            continue
        err, avert = verifier_doc(doc, a.strict, minimums)
        taille = os.path.getsize(chemin) / 1e6
        if taille > 25:
            avert.append(f"fichier lourd ({taille:.1f} Mo) : à découper")
        for m in avert:
            print(f"⚠ {chemin} : {m}")
        for m in err:
            print(f"✗ {chemin} : {m}")
        if not err:
            print(f"✓ {chemin} ({taille:.3f} Mo, {sum(c.get('compte', 0) for c in doc['couches'])} objets)")
        code = code or (1 if err else 0)
    return code


if __name__ == "__main__":
    sys.exit(main())
