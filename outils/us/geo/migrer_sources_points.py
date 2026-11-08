#!/usr/bin/env python3
"""Migre les fichiers geo-us/*-points.json vers le format fishme-geo-us/2 (8 nov.).

Avant : sources[].texte = phrase française composée (« accès public listé par <agence>, <jeu> »), affichée telle quelle
        dans l'interface anglaise.
Après : sources[].genre ("agence" ou "osm") + sources[].jeu (agence et jeu de données, noms propres seulement) ;
        l'app compose la phrase dans sa langue. `mention` (phrase française, jamais lue par l'app) est retirée.
Les fichiers plans-eau et lignes-eau perdent « couche » dans leur source (« (couche Waterbody) » devient « (Waterbody) »).
Idempotent. Usage : python3 outils/us/geo/migrer_sources_points.py [dossier]
"""
import glob, json, os, sys

RACINE = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "geo-us")
PREFIXES = (("accès public listé par ", "agence"), ("point cartographié par ", "osm"))


# Le champ `jeu` ne porte que des noms propres et des termes de catalogue : les bouts de français des anciens textes sont traduits ici.
TRADUCTIONS = (
    ("installations de mise à l'eau, propriétaire public", "boat launch facilities, public owner"),
    ("(même service)", "(same service)"),
    ("Lake Features (atlas 2015) : Boat Ramp et Fishing Dock", "Lake Features (atlas 2015): Boat Ramp and Fishing Dock"),
    ("(couche « Access 202611 » du service PASDA PAFishBoat : accès vérifiés par la PFBC, publics ou semi-publics, plus des accès signalés par des partenaires de sentiers nautiques)",
     '(layer "Access 202611" of the PASDA PAFishBoat service: access sites verified by the PFBC, public or semi-public, plus access sites reported by water-trail partners)'),
    ("sites dont l'activité principale est la navigation ou la pêche", "sites whose main activity is boating or fishing"),
    ("inventaire des comtés côtiers de Mobile et Baldwin", "inventory of the coastal counties of Mobile and Baldwin"),
    ("surfaces d'accès, servitudes de pêche publiques et autres accès ; ramenées au centre de chaque surface",
     "access areas, public fishing easements and other access; reduced to the center of each area"),
    ("accès publics aux eaux à marée et à leurs rives ; seuls les sites marqués pêche, quai ou rampe sont gardés",
     "public access to tidal waters and their shores; only sites marked fishing, pier or ramp are kept"),
    ("diffusée par MassGIS", "published by MassGIS"),
    ("(registre d'actifs, rampes possédées, exploitées ou gérées par Reclamation)",
     "(asset register, ramps owned, operated or managed by Reclamation)"),
    ("(contributeurs), rampes de mise à l'eau", "(contributors), boat ramps"),
    ("slipway ou amenity", "slipway or amenity"),
    ("accès à la rivière sur propriétés CPW", "river access on CPW properties"),
    ("(état de décembre 2002)", "(as of December 2002)"),
    ("et agences fédérales", "and federal agencies"),
    (" et Bureau of Reclamation", " and Bureau of Reclamation"),
    ("(service Public_Lakes, couche 5)", "(Public_Lakes service, layer 5)"),
    ("service ArcGIS ", "ArcGIS service "),
    ("couche « ", 'layer "'), (" »", '"'),
    ("couche ", "layer "),
)


def traduire(jeu):
    for fr, en in TRADUCTIONS:
        jeu = jeu.replace(fr, en)
    return jeu


def ecrire(chemin, d):
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))


for chemin in sorted(glob.glob(os.path.join(RACINE, "*-points.json"))):
    d = json.load(open(chemin, encoding="utf-8"))
    nouvelles = []
    for s in d["sources"]:
        if "texte" in s:
            t = s["texte"]
            pref, genre = next(((p, g) for p, g in PREFIXES if t.startswith(p)), (None, None))
            if pref is None:
                sys.exit(f"{chemin} : texte inconnu : {t!r}")
            s = {"genre": genre, "jeu": t[len(pref):], **{k: v for k, v in s.items() if k != "texte"}}
        s["jeu"] = traduire(s["jeu"])
        nouvelles.append(s)
    d["sources"] = nouvelles
    d.pop("mention", None)
    ecrire(chemin, d)

# Avis : la source d'un fichier sans enregistrement était une phrase française (jamais affichée sans ligne d'avis, mais gardée propre).
for chemin in sorted(glob.glob(os.path.join(RACINE, "*-avis.json"))):
    d = json.load(open(chemin, encoding="utf-8"))
    src = d.get("source")
    if isinstance(src, str):
        neuf = traduire(src.replace(" : aucun enregistrement pour ", ": no record for ").replace(" au 2026", " on 2026")
                        .replace(" ; renvoi à la page de l'agence", "; see the agency page"))
        if neuf != src:
            d["source"] = neuf
            ecrire(chemin, d)

# Tous les fichiers du dossier passent au format 2 (version du schéma, une seule pour les 245 fichiers).
for chemin in sorted(glob.glob(os.path.join(RACINE, "*.json"))):
    d = json.load(open(chemin, encoding="utf-8"))
    if d.get("format") == "fishme-geo-us/1":
        d["format"] = "fishme-geo-us/2"
        ecrire(chemin, d)

for suffixe in ("plans-eau", "lignes-eau"):
    for chemin in sorted(glob.glob(os.path.join(RACINE, f"*-{suffixe}.json"))):
        d = json.load(open(chemin, encoding="utf-8"))
        if isinstance(d.get("source"), str) and "(couche " in d["source"]:
            d["source"] = d["source"].replace("(couche ", "(")
            ecrire(chemin, d)
