#!/usr/bin/env python3
"""US16 : échoue si une entrée d'espèces par zone n'a pas espèce (nom, latin), zone, preuve, source (URL https), date, licence, confiance.
Usage : python3 -I verifier_zones.py [dossier especes-us] ; code 0 si 0 trou."""
import json, os, re, sys

ICI = os.path.dirname(os.path.abspath(__file__))
DEFAUT = os.path.join(ICI, "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
PRODUCTEURS = {"agence", "gbif", "nas", "biodata", "signalements"}
PREUVES = {"liste_agence", "empoissonnement", "enquete_peche_electrique", "occurrence_gbif", "nas", "biodata", "signalement_public"}
CONFIANCES = {"officielle", "enregistrement_scientifique", "non confirmé, signalement public"}
ZONES = {"etat", "huc8", "plan_eau"}
LICENCES_GBIF = {"CC0-1.0", "CC-BY-4.0"}
INTERDITS = re.compile(r"autoris|allowed|\blegal\b|tu peux la garder|you can keep|\brare\b|\buncommon\b|légendaire", re.I)
DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
NOM_FICHIER = re.compile(r"^([A-Z]{2})-(agence|gbif|nas|biodata|signalements)\.json$")


def verifier_fichier(nom, d, slugs=None):
    t = []
    m = NOM_FICHIER.match(nom)
    if not m:
        return [f"{nom} : nom de fichier hors schéma"]
    if d.get("format") != "fishme-especes-us/1" or d.get("etat") != m.group(1) or d.get("producteur") != m.group(2):
        t.append(f"{nom} : format, état ou producteur incohérent")
    if not DATE.match(str(d.get("date", ""))):
        t.append(f"{nom} : date absente")
    srcs = d.get("sources") or []
    for i, s in enumerate(srcs):
        if not str(s.get("url", "")).startswith("https://") or not s.get("licence") or not DATE.match(str(s.get("date", ""))) or not s.get("nom"):
            t.append(f"{nom} : source {i} sans nom, https, licence ou date")
        if m.group(2) == "gbif" and s.get("licence") not in LICENCES_GBIF:
            t.append(f"{nom} : source GBIF {i} avec licence {s.get('licence')} (CC0-1.0 ou CC-BY-4.0 seulement)")
        if re.search(r"inaturalist\.org", str(s.get("url", "")), re.I) and m.group(2) != "gbif":
            t.append(f"{nom} : iNaturalist direct interdit (source {i})")
    for j, e in enumerate(d.get("entrees") or []):
        ou = f"{nom} entrée {j}"
        if not e.get("nom") or not e.get("latin"):
            t.append(f"{ou} : nom ou latin manquant")
        if e.get("slug") is not None and slugs is not None and e["slug"] not in slugs:
            t.append(f"{ou} : slug inconnu {e['slug']}")
        z = e.get("zone") or {}
        if z.get("type") not in ZONES or not z.get("id"):
            t.append(f"{ou} : zone invalide")
        if z.get("type") == "huc8" and not re.fullmatch(r"\d{8}", str(z.get("id"))):
            t.append(f"{ou} : HUC8 invalide")
        if e.get("preuve") not in PREUVES:
            t.append(f"{ou} : preuve invalide")
        if e.get("confiance") not in CONFIANCES:
            t.append(f"{ou} : confiance invalide")
        if not isinstance(e.get("src"), int) or not (0 <= e["src"] < len(srcs)):
            t.append(f"{ou} : src hors de sources")
        if e.get("preuve") == "signalement_public" and e.get("confiance") != "non confirmé, signalement public":
            t.append(f"{ou} : un signalement public doit porter la confiance « non confirmé »")
        for k in ("nom", "latin"):
            if INTERDITS.search(str(e.get(k, ""))):
                t.append(f"{ou} : mot interdit dans {k}")
        if set(e) & {"rarete", "rareté", "utilisateur", "user", "lat", "lon", "coordonnees"}:
            t.append(f"{ou} : champ interdit (rareté, utilisateur ou coordonnées)")
    return t


def verifier(dossier=DEFAUT):
    slugs = None
    p = os.path.join(ICI, "especes-us.json")
    if os.path.exists(p):
        slugs = {e["slug"] for e in json.load(open(p, encoding="utf-8"))}
    t, n = [], 0
    if os.path.isdir(dossier):
        for nom in sorted(os.listdir(dossier)):
            if nom.endswith(".json"):
                n += 1
                t += verifier_fichier(nom, json.load(open(os.path.join(dossier, nom), encoding="utf-8")), slugs)
    return t, n


if __name__ == "__main__":
    trous, n = verifier(sys.argv[1] if len(sys.argv) > 1 else DEFAUT)
    for x in trous:
        print("TROU", x)
    print(f"{len(trous)} trou(s) ; {n} fichier(s)")
    sys.exit(1 if trous else 0)
