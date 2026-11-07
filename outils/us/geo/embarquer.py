#!/usr/bin/env python3
"""US11 : fabrique les fichiers SIMPLIFIÉS embarqués dans l'app (Core/Resources/geo-us/).

Un fichier par État et par couche, JSON compact (tableaux de valeurs, pas d'objets : moins d'octets) :
  <USPS>-points.json      points d'accès publics listés par l'agence de l'État (rampes, quais, accès à pied)
  <USPS>-plans-eau.json   plans d'eau nommés : centre + rayon (cercle de même surface), pas de contour
  <USPS>-lignes-eau.json  lignes d'eau nommées d'ordre élevé, très simplifiées (200 m environ)
  <USPS>-avis.json        avis de consommation de poisson, seulement quand le service EPA couvre l'État

Entrées : sortie de construire_etat.py (couches-us-<USPS>.json, couches acces et peche_rive) et deux
téléchargements 3DHP (plans d'eau, tracés) faits ici avec arcgis.py. Le contour de l'État (TIGERweb, Census)
sert seulement à retirer les objets des États voisins pris par la boîte englobante.

Usage :
  python3 embarquer.py WI --brut /chemin/brut --sortie /chemin/geo-us      # tout, avec réseau
  python3 embarquer.py WI --brut ... --sans-reseau                         # seulement ce qui est déjà dans --brut
Jamais { accès libre } ni { pêche autorisée } : chaque ligne dit { accès public listé par <agence> }.
"""
import argparse
import datetime
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import arcgis  # noqa: E402
import normaliser  # noqa: E402

ICI = os.path.dirname(os.path.abspath(__file__))
FORMAT = "fishme-geo-us/1"
HYDRO = "https://hydro.nationalmap.gov/arcgis/rest/services/3DHP_all/MapServer"
TIGER = "https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/State_County/MapServer/0"
TYPES_ACCES = {"rampe": "rampe", "acces_portage": "accesPublic", "acces": "accesPublic", "peche_rive": "quai"}
AGENCES = {"MN": "Minnesota DNR", "WI": "Wisconsin DNR", "MI": "Michigan DNR"}
NOMS = {"MN": "Minnesota", "WI": "Wisconsin", "MI": "Michigan"}
# Pages d'agence. Statut lu le 2026-11-07 avec curl : WI 200 (avis et lacs) ; MN avis 200, lakefind 403 ; MI 403 partout
# (blocage probable des robots, non confirmé dans un navigateur). Ces adresses viennent de etats/<USPS>.json et du rapport zones-acces.
LIENS = {
    "WI": dict(plans="https://dnr.wisconsin.gov/topic/lakes", avis="https://dnr.wisconsin.gov/topic/fishing/consumption"),
    "MN": dict(plans="https://www.dnr.state.mn.us/lakefind/index.html", avis="https://www.health.state.mn.us/communities/environment/fish/index.html"),
    "MI": dict(plans="https://www.michigan.gov/dnr/places/lakes", avis="https://www.michigan.gov/eatsafefish"),
}
SEUIL_PLAN_EAU_KM2 = 0.05
ORDRE_LIGNE_MIN = 4
TOLERANCE_LIGNE = 0.002  # degrés, 200 m environ
DECIMALES_LIGNE = 3


def anneaux_exterieurs(geom):
    """Liste des anneaux extérieurs d'un Polygon/MultiPolygon (coordonnées [lon, lat])."""
    if not geom:
        return []
    if geom["type"] == "Polygon":
        return [geom["coordinates"][0]]
    if geom["type"] == "MultiPolygon":
        return [p[0] for p in geom["coordinates"]]
    return []


def dans_anneau(lon, lat, anneau):
    """Lancer de rayon : le point est-il dans l'anneau ?"""
    dedans = False
    n = len(anneau)
    j = n - 1
    for i in range(n):
        xi, yi = anneau[i][0], anneau[i][1]
        xj, yj = anneau[j][0], anneau[j][1]
        if (yi > lat) != (yj > lat) and lon < (xj - xi) * (lat - yi) / (yj - yi) + xi:
            dedans = not dedans
        j = i
    return dedans


def dans_etat(lon, lat, contour):
    """contour : liste d'anneaux extérieurs ; None = pas de filtre."""
    if contour is None:
        return True
    return any(dans_anneau(lon, lat, a) for a in contour)


def centre_polygone(geom):
    """Centre (lat, lon) du plus grand anneau extérieur : barycentre de surface, repli sur le centre de la boîte."""
    meilleur, aire_max = None, -1.0
    for a in anneaux_exterieurs(geom):
        s = 0.0
        cx = cy = 0.0
        for k in range(len(a) - 1):
            x0, y0, x1, y1 = a[k][0], a[k][1], a[k + 1][0], a[k + 1][1]
            c = x0 * y1 - x1 * y0
            s += c
            cx += (x0 + x1) * c
            cy += (y0 + y1) * c
        if abs(s) > aire_max:
            aire_max = abs(s)
            if abs(s) > 1e-12:
                meilleur = (cy / (3 * s), cx / (3 * s))
            else:
                xs, ys = [p[0] for p in a], [p[1] for p in a]
                meilleur = ((min(ys) + max(ys)) / 2, (min(xs) + max(xs)) / 2)
    return meilleur


def rayon_metres(aire_km2):
    """Rayon du cercle de même surface, en mètres."""
    return math.sqrt(max(aire_km2, 0.0) / math.pi) * 1000.0


def construire_points(usps, doc, date_lecture):
    """doc = couches-us-<USPS>.json de construire_etat.py. Une ligne : [id, nom, lat, lon, type, indice de source]."""
    agence = AGENCES.get(usps, usps)
    sources, lignes = [], []
    vus = set()
    for c in doc["couches"]:
        if c.get("role") != "acces" or c.get("statut") != "ok":
            continue
        txt = f"accès public listé par {agence}, {c['source']}"
        sources.append(dict(texte=txt, licence=c["licence"], url=c["url_source"], date=date_lecture))
        k = len(sources) - 1
        for f in c["collection"]["features"]:
            p = f["properties"]
            if f["geometry"]["type"] != "Point" or p["id"] in vus:
                continue
            vus.add(p["id"])
            lon, lat = f["geometry"]["coordinates"][:2]
            nom = (p.get("nom") or "").strip() or (p.get("eau") or "").strip() or "Accès sans nom"
            lignes.append([p["id"], nom, round(lat, 5), round(lon, 5), TYPES_ACCES.get(p.get("type"), "autre"), k])
    lignes.sort(key=lambda r: r[0])
    return dict(format=FORMAT, etat=usps, couche="points", date=date_lecture, compte=len(lignes),
                mention="Accès public listé par l'agence, source et date ci-dessous ; ce n'est ni un droit de pêche ni une garantie d'accès.",
                sources=sources, points=lignes)


def construire_plans_eau(usps, features, contour, config, date_lecture):
    """features : GeoJSON 3DHP waterbody. Une ligne : [id, nom, lat, lon, rayon en m]. Nommés seulement."""
    lignes, vus = [], set()
    for f in features:
        p = f.get("properties") or dict()
        nom = (p.get("gnisidlabel") or "").strip()
        ident = p.get("id3dhp")
        aire = p.get("areasqkm")
        if not nom or not ident or not aire or ident in vus:
            continue
        c = centre_polygone(f.get("geometry"))
        if not c or not dans_etat(c[1], c[0], contour):
            continue
        vus.add(ident)
        lignes.append([f"3dhp:{ident}", nom, round(c[0], 4), round(c[1], 4), round(rayon_metres(aire))])
    lignes.sort(key=lambda r: (r[1], r[0]))
    return dict(format=FORMAT, etat=usps, couche="plans-eau", date=date_lecture, compte=len(lignes),
                source=config["source"], editeur=config["editeur"], url_source=config["url_source"],
                licence=config["licence"], lien_agence=config.get("lien_agence"),
                mention="Centre et rayon d'un cercle de même surface que le plan d'eau (USGS 3DHP) : indicatif, pas un contour.",
                plans_eau=lignes)


def construire_lignes(usps, features, contour, config, date_lecture):
    """Une ligne : [id, nom, ordre, [[lon, lat], ...]]. Nommées, ordre au moins ORDRE_LIGNE_MIN, très simplifiées."""
    lignes, vus = [], set()
    for f in features:
        p = f.get("properties") or dict()
        nom = (p.get("gnisidlabel") or "").strip()
        ident = p.get("id3dhp")
        ordre = p.get("streamorder") or 0
        if not nom or not ident or ordre < ORDRE_LIGNE_MIN or ident in vus or not f.get("geometry"):
            continue
        g = normaliser.simplifier(f["geometry"], TOLERANCE_LIGNE)
        if not g:
            continue
        g = normaliser.arrondir(g, DECIMALES_LIGNE)
        morceaux = [g["coordinates"]] if g["type"] == "LineString" else g["coordinates"]
        for i, m in enumerate(morceaux):
            if len(m) < 2 or not any(dans_etat(q[0], q[1], contour) for q in m):
                continue
            cle = f"3dhp:{ident}" + (f"/{i}" if len(morceaux) > 1 else "")
            lignes.append([cle, nom, int(ordre), m])
        vus.add(ident)
    lignes.sort(key=lambda r: (r[1], r[0]))
    return dict(format=FORMAT, etat=usps, couche="lignes-eau", date=date_lecture, compte=len(lignes),
                source=config["source"], editeur=config["editeur"], url_source=config["url_source"],
                licence=config["licence"],
                mention="Tracés USGS 3DHP très simplifiés (200 m environ), cours d'eau nommés d'ordre 4 et plus : repère visuel seulement.",
                lignes=lignes)


def construire_avis(usps, doc, date_lecture):
    """Avis EPA : ceux de la couche avis_consommation du doc, s'il y en a. Une ligne : [planEauId ou None, texte, date, lien]."""
    for c in doc["couches"]:
        if c.get("role") == "avis_consommation" and c.get("statut") == "ok" and c.get("collection"):
            lignes = []
            for f in c["collection"]["features"]:
                p = f["properties"]
                texte = (p.get("texte") or p.get("nom") or "").strip()
                if texte:
                    lignes.append([None, texte, p.get("date") or c.get("date_source_service") or date_lecture,
                                   p.get("lien") or c["url_source"]])
            if lignes:
                return dict(format=FORMAT, etat=usps, couche="avis", date=date_lecture, compte=len(lignes),
                            source=c["source"], licence=c["licence"], url_source=c["url_source"], avis=lignes)
    return avis_renvoi(usps, date_lecture)


def avis_renvoi(usps, date_lecture):
    """Quand le service EPA n'a aucun avis pour l'État : un seul avis valant pour l'État, qui renvoie à la page de l'agence."""
    lien = LIENS.get(usps, dict()).get("avis")
    if not lien:
        return None
    agence = AGENCES.get(usps, usps)
    texte = (f"Fish consumption advisories for {NOMS.get(usps, usps)} are published by the {agence} (or the state health department). "
             "The EPA national listing has no record for this state: check the agency page before eating any fish.")
    source = ("EPA National Listing of Fish and Wildlife Advisories (service ArcGIS EPA_Fish_Consumption_Advisory_area2) : "
              f"aucun enregistrement pour {usps} au {date_lecture} ; renvoi à la page de l'agence")
    return dict(format=FORMAT, etat=usps, couche="avis", date=date_lecture, compte=1, source=source,
                licence="[?] non précisée : simple renvoi vers la page de l'agence", url_source=lien,
                avis=[[None, texte, date_lecture, lien]])


def ecrire(doc, chemin):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
    return os.path.getsize(chemin)


def construire_etats(brut, sortie):
    """etats.json : boîte et contour très simplifié (0,01 degré) de chaque État embarqué, pour retrouver l'État d'une position."""
    etats = []
    for nom in sorted(os.listdir(sortie)):
        if not nom.endswith("-points.json") or len(nom) != len("XX-points.json"):
            continue
        usps = nom[:2]
        chemin = os.path.join(brut, f"contour-{usps}.json")
        if not os.path.exists(chemin):
            continue
        with open(chemin, encoding="utf-8") as f:
            anneaux = json.load(f)
        simples = []
        for a in anneaux:
            s = normaliser._rdp([(p[0], p[1]) for p in a], 0.01)
            if len(s) >= 4:
                simples.append([[round(x, 3), round(y, 3)] for x, y in s])
        xs = [p[0] for a in simples for p in a]
        ys = [p[1] for a in simples for p in a]
        if xs:
            etats.append(dict(etat=usps, nom=NOMS.get(usps, usps), bbox=[min(xs), min(ys), max(xs), max(ys)], contour=simples))
    return dict(format=FORMAT, couche="etats", source="US Census Bureau, TIGERweb State_County (contour simplifié à 0,01 degré)",
                licence="[?] non précisée sur le service (produit fédéral, domaine public présumé)", etats=etats)


def contour_tiger(usps, http=arcgis.http_json):
    j = http(TIGER + "/query", dict(where=f"STUSAB = '{usps}'", outFields="STUSAB", outSR=4326,
                                    maxAllowableOffset=0.005, f="geojson"))
    feats = j.get("features") or []
    return [a for f in feats for a in anneaux_exterieurs(f["geometry"])] or None


def telecharger_3dhp(couche, emprise, where, http=arcgis.http_json, log=print, generalisation=None, paquet=None):
    """generalisation (degrés) et paquet plus petit : les plans d'eau des Grands Lacs font échouer le serveur (HTTP 500) sinon."""
    feats, _ = arcgis.telecharger(HYDRO, couche, emprise, where, "*", generalisation, paquet=paquet, http=http, log=log)
    return feats


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("usps")
    ap.add_argument("--brut", required=True, help="dossier des téléchargements bruts (hors dépôt)")
    ap.add_argument("--sortie", required=True, help="dossier geo-us/ de l'app")
    ap.add_argument("--sans-reseau", action="store_true")
    ap.add_argument("--date", default=datetime.date.today().isoformat())
    a = ap.parse_args(argv)
    usps = a.usps.upper()
    with open(os.path.join(ICI, "etats", f"{usps}.json"), encoding="utf-8") as f:
        cfg = json.load(f)
    emprise = cfg["emprise"]
    dtl = a.date
    brut = a.brut

    def en_cache(nom, fabrique):
        chemin = os.path.join(brut, nom)
        if os.path.exists(chemin):
            with open(chemin, encoding="utf-8") as f:
                return json.load(f)
        if a.sans_reseau or fabrique is None:
            return None
        d = fabrique()
        os.makedirs(brut, exist_ok=True)
        with open(chemin, "w", encoding="utf-8") as f:
            json.dump(d, f, separators=(",", ":"))
        return d

    contour = en_cache(f"contour-{usps}.json", lambda: contour_tiger(usps))
    doc = en_cache(f"couches-us-{usps}.json", None)
    if doc is None:
        print("couches-us introuvable : lancer d'abord construire_etat.py", usps, "--couches acces,peche_rive")
        return 1
    tailles = dict()
    tailles["points"] = ecrire(construire_points(usps, doc, dtl), os.path.join(a.sortie, f"{usps}-points.json"))
    commun = dict(editeur="USGS", licence="[?] non précisée : domaine public fédéral présumé (produit USGS), non lu sur le service")
    plans = en_cache(f"plans-eau-{usps}.json", lambda: telecharger_3dhp(
        60, emprise, f"areasqkm >= {SEUIL_PLAN_EAU_KM2} AND gnisidlabel IS NOT NULL", generalisation=0.002, paquet=50))
    if plans is not None:
        cfg_p = dict(commun, source="USGS National Map, 3DHP (couche Waterbody)", url_source=HYDRO + "/60",
                     lien_agence=LIENS.get(usps, dict()).get("plans"))
        tailles["plans-eau"] = ecrire(construire_plans_eau(usps, plans, contour, cfg_p, dtl),
                                      os.path.join(a.sortie, f"{usps}-plans-eau.json"))
    lignes = en_cache(f"lignes-eau-{usps}.json", lambda: telecharger_3dhp(
        50, emprise, f"streamorder >= {ORDRE_LIGNE_MIN} AND gnisidlabel IS NOT NULL"))
    if lignes is not None:
        cfg_l = dict(commun, source="USGS National Map, 3DHP (couche Flowline)", url_source=HYDRO + "/50")
        tailles["lignes-eau"] = ecrire(construire_lignes(usps, lignes, contour, cfg_l, dtl),
                                       os.path.join(a.sortie, f"{usps}-lignes-eau.json"))
    avis = construire_avis(usps, doc, dtl)
    if avis:
        tailles["avis"] = ecrire(avis, os.path.join(a.sortie, f"{usps}-avis.json"))
    tailles["etats"] = ecrire(construire_etats(brut, a.sortie), os.path.join(a.sortie, "etats.json"))
    for k, v in tailles.items():
        print(("etats.json" if k == "etats" else f"{usps}-{k}.json") + f" : {v / 1e6:.3f} Mo")
    return 0


if __name__ == "__main__":
    sys.exit(main())
