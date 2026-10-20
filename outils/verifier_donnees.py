#!/usr/bin/env python3
"""Vérificateur des données embarquées (lot D1, docs/fiches/D1.md, « Test fini »).

  python3 outils/verifier_donnees.py              vérifie la structure ; liste les MANQUES de contenu ; sort 1 s'il y a une ERREUR
  python3 outils/verifier_donnees.py --porte-fusion   sort aussi 1 s'il reste un MANQUE (relecture de S, cas d'or, espèces, images...)
  python3 outils/verifier_donnees.py --stations CHEMIN [--trace DOSSIER]
      (D5) contrôle aussi stations-especes.json (défaut : App/Donnees/ ou outils/hubeau/sortie/) : 100 % `recalee`, 90 % au moins à true,
      aucune coordonnée à 2 décimales parmi les true, 20 stations true tirées au sort (graine fixe) à 50 m au plus du tracé (dossier
      outils/hubeau/cache/trace/ de trace_sandre.py ; sans tracé l'échantillon est un MANQUE).
  python3 outils/verifier_donnees.py --index      réécrit regles/index.json (sha256, expire_min, nombres) d'après les fichiers présents
  python3 outils/verifier_donnees.py --charger <code> [--depuis DIR]
      fusion prudente (docs/fiches/D1.md) : lit DIR/consensus/<code>.json (sortie de `consensus.py <code> --json`) et les lectures
      DIR/dep/<code>.json et DIR/dep-b/<code>.json, écrit regles/<code>.json puis relance --index.
      Règles confirmées par les deux lectures -> regles[] ; vues par une seule lecture -> a_verifier[] (sans valeur ni citation) ;
      deux tailles confirmées différentes -> une règle valeur.candidats_cm, statut incertain.
  python3 outils/verifier_donnees.py --une-lecture <code> --lecture dep|dep-b [--depuis DIR]
      département qui n'a qu'une lecture : tout part en a_verifier[], regles[] vide, niveau partiel.
  DIR par défaut : /mnt/project-files/build/regles/cloud (ou la variable REGLES_DIR).
  Refus : valeur en forme v1, fichier existant relu par une personne (statut verifie ou verifie_par), 75 et 94 (relus, gagnent toujours),
  id en double, fichier de plus de 400 Ko.
"""
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys
import unicodedata

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(RACINE, "Packages", "Core", "Sources", "Core", "Resources")
REGLES = os.path.join(RES, "regles")
IDF = ("75", "92", "93", "94", "77")
V1 = {"periodes", "total", "domaine", "secteurs"}
TYPES = {"ouverture", "taille_min", "quota_jour", "horaire", "interdit", "categorie", "mode_peche", "carpe_nuit",
         "transport_vivant", "remise_eau", "consommation", "reserve", "no_kill", "fenetre_capture", "limite_eau_douce", "autre"}
STATUTS = {"brouillon", "incertain", "verifie"}
erreurs, manques = [], []


def err(m): erreurs.append(m)
def manque(m): manques.append(m)


def lire(chemin):
    try:
        with open(chemin, encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:  # noqa: BLE001
        err(f"{os.path.relpath(chemin, RACINE)} : JSON illisible ({e})")
        return None


def sha(chemin):
    with open(chemin, "rb") as f:
        return hashlib.sha256(f.read().replace(b"\r\n", b"\n")).hexdigest()


def fichiers_regles():
    sortie = {}
    if os.path.isdir(REGLES):
        for n in sorted(os.listdir(REGLES)):
            if n.endswith(".json") and n != "index.json":
                d = lire(os.path.join(REGLES, n))
                if d is not None:
                    sortie[n[:-5]] = d
    return sortie


def verifier_regles(fichiers):
    ids_nat = {r["id"] for r in fichiers.get("national", {}).get("regles", [])}
    vus = {}
    for code, d in fichiers.items():
        textes = {t["id"]: t for t in d.get("textes", [])}
        eaux = {e["cle"] for e in d.get("eaux", [])}
        ids = {r["id"] for r in d.get("regles", [])}
        for t in textes.values():
            for k in ("titre", "url", "lu_le"):
                if not t.get(k):
                    err(f"{code} : texte {t.get('id')} sans {k}")
        for r in d.get("regles", []):
            q = f"{code}/{r.get('id')}"
            if r["id"] in vus:
                err(f"{q} : id en double (déjà dans {vus[r['id']]})")
            vus[r["id"]] = code
            if r.get("type") not in TYPES:
                err(f"{q} : type inconnu {r.get('type')}")
            if r.get("statut") not in STATUTS:
                err(f"{q} : statut {r.get('statut')}")
            if r.get("statut") == "verifie" and not r.get("verifie_par"):
                err(f"{q} : verifie sans verifie_par")
            if r.get("verifie_par") and r.get("statut") != "verifie":
                err(f"{q} : verifie_par sur une règle non verifie")
            if "expire_le" not in r:
                err(f"{q} : expire_le absent (date ou null)")
            c = r.get("citation")
            if not c or len(c) > 300:
                err(f"{q} : citation vide ou de plus de 300 caractères")
            if not r.get("textes") or any(t not in textes for t in r["textes"]):
                err(f"{q} : texte cité absent de textes")
            if r.get("remplace") and r["remplace"] not in ids and r["remplace"] not in ids_nat:
                err(f"{q} : remplace {r['remplace']} n'existe pas")
            eau = (r.get("portee") or {}).get("eau")
            if eau and eau not in eaux:
                err(f"{q} : portee.eau {eau} absente de eaux")
            v = r.get("valeur")
            if not isinstance(v, dict):
                err(f"{q} : valeur doit être un objet")
                continue
            if V1 & set(v):
                err(f"{q} : valeur en forme v1 ({sorted(V1 & set(v))})")
            if "candidats_cm" in v:
                if len(set(r.get("textes", []))) < 2:
                    err(f"{q} : candidats_cm sans deux textes")
                if r.get("statut") != "incertain":
                    err(f"{q} : candidats_cm doit être incertain")
            if r.get("statut") == "brouillon" and r.get("type") == "taille_min" and v.get("cm") is None and "candidats_cm" not in v \
                    and not any(k in v for k in ("texte",)):
                err(f"{q} : taille_min sans valeur")
        for a in d.get("a_verifier", []):
            if "valeur" in a or "citation" in a:
                err(f"{code} : a_verifier avec valeur ou citation ({a.get('type')})")
            if any(t not in textes for t in a.get("textes", [])):
                err(f"{code} : a_verifier ({a.get('type')}) cite un texte absent de textes")
            if a.get("eau") and a["eau"] not in eaux:
                err(f"{code} : a_verifier ({a.get('type')}) eau {a['eau']} absente de eaux")
        if code in IDF:
            n = sum(1 for r in d["regles"] if r["statut"] == "brouillon")
            if n:
                manque(f"{code} : {n} règles encore « brouillon », à relire par S (reports/relecture/{code}.csv)")
    return vus


def ouvert(fichiers, espece, cat, jour):
    """Lit les données : False si une règle chargée ferme l'espèce ce jour-là (période bornée seulement)."""
    j = jour.isoformat()
    # Test de bon sens sur le socle national seulement : une règle locale (ex. 04, arc-en-ciel fermée
    # pendant la fermeture de la 1re catégorie) peut fermer une espèce dans son département sans contredire le national.
    for d in [fichiers["national"]] if "national" in fichiers else fichiers.values():
        for r in d["regles"]:
            if r["type"] == "interdit" and r["du"] and r["au"] and espece in r["especes"] and r["categorie"] in (cat, "toutes") \
                    and r["du"] <= j <= r["au"]:
                return False
            if r["type"] == "ouverture" and cat == "1" and r["categorie"] == "1" and not r["especes"] and r["du"] and r["au"]:
                if not (r["du"] <= j <= r["au"]):
                    return False
    return True


def verifier_dates(fichiers):
    if "national" not in fichiers:
        return
    for jour in (datetime.date(2026, 10, 15), datetime.date(2026, 10, 16)):
        attendu = [("1", "2193", False, "1re catégorie fermée"), ("1", "2221", False, "fario fermée (1re)"),
                   ("2", "2221", False, "fario fermée partout (2e)"), ("2", "2151", True, "brochet ouvert en 2e"),
                   ("2", "2195", True, "sandre ouvert en 2e"), ("2", "2216", True, "arc-en-ciel ouverte en 2e")]
        for cat, esp, att, nom in attendu:
            if ouvert(fichiers, esp, cat, jour) != att:
                err(f"{jour} : {nom} : les données disent le contraire")


def verifier_index(fichiers):
    chemin = os.path.join(REGLES, "index.json")
    idx = lire(chemin)
    if idx is None:
        return
    for code, d in fichiers.items():
        p = os.path.join(REGLES, code + ".json")
        e = idx["national"] if code == "national" else idx.get("departements", {}).get(code)
        if not e:
            if code != "national" or idx.get("national") is None:
                err(f"index : {code} absent")
            continue
        if e.get("sha256") != sha(p):
            err(f"index : sha256 de {code} faux")
        ex = [r["expire_le"] for r in d["regles"] if r.get("expire_le")]
        if e.get("expire_min") != (min(ex) if ex else None):
            err(f"index : expire_min de {code} faux")
        if os.path.getsize(p) > 400 * 1024:
            err(f"{code}.json dépasse 400 Ko")
        if code != "national":
            if e.get("confirmees") != len(d["regles"]) or e.get("a_verifier") != len(d["a_verifier"]):
                err(f"index : nombres de {code} faux")
    for code in idx.get("departements", {}):
        if code not in fichiers:
            err(f"index : {code} sans fichier")


def reecrire_index():
    fichiers = fichiers_regles()
    idx = {"version": "2026-10-15.1", "date": datetime.date.today().isoformat(), "departements": {}, "national": None}
    for code, d in fichiers.items():
        ex = [r["expire_le"] for r in d["regles"] if r.get("expire_le")]
        p = os.path.join(REGLES, code + ".json")
        if code == "national":
            idx["national"] = {"sha256": sha(p), "expire_min": min(ex) if ex else None}
        else:
            idx["departements"][code] = {"niveau": d["niveau"], "confirmees": len(d["regles"]), "a_verifier": len(d["a_verifier"]),
                                         "sha256": sha(p), "expire_min": min(ex) if ex else None}
    with open(os.path.join(REGLES, "index.json"), "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(idx, ensure_ascii=False, indent=1) + "\n")
    print("index.json réécrit")


def verifier_especes():
    esp = lire(os.path.join(RES, "especes.json"))
    if esp is None:
        return {}
    ids = [e.get("id") for e in esp]
    if len(ids) != len(set(ids)):
        err("especes.json : ids en double")
    for e in esp:
        for k in ("statut", "suivi_ofb", "image"):
            if k not in e:
                err(f"especes.json : {e.get('id')} sans {k}")
        for c in e.get("confusions", []):
            if c.get("avec") not in ids:
                err(f"especes.json : {e['id']} confusion avec {c.get('avec')} inconnue")
    # 101 entrées de la liste de reconnaissance, moins les 2 classes du modèle (« autre poisson », « pas un poisson ») qui ne sont pas des espèces.
    if len(esp) < 99:
        manque(f"especes.json : {len(esp)} espèces sur 99 (liste de reconnaissance : 101 entrées dont 2 classes du modèle)")
    if esp and not any(e["confusions"] for e in esp):
        manque("especes.json : aucune confusion renseignée")
    return {e["id"] for e in esp}


def verifier_autres(ids_especes):
    lp = lire(os.path.join(RES, "longueur-poids.json"))
    if isinstance(lp, list):
        for l in lp:
            if l.get("espece") not in ids_especes:
                err(f"longueur-poids.json : espèce {l.get('espece')} absente de especes.json")
            for k in ("a", "b", "lt_min_cm", "lt_max_cm", "source"):
                if k not in l:
                    err(f"longueur-poids.json : {l.get('espece')} sans {k}")
        if len(lp) < 30:
            manque(f"longueur-poids.json : {len(lp)} lignes sur 30")
    cas = lire(os.path.join(RES, "cas-verdicts.json"))
    if isinstance(cas, list):
        faux = [c for c in cas if not c.get("reponse") or not c.get("ecrite_par")]
        if faux:
            err(f"cas-verdicts.json : {len(faux)} cas sans réponse écrite par une personne")
        if len(cas) < 13:
            manque(f"cas-verdicts.json : {len(cas)} cas sur 13 (réponses à écrire par S)")
    cr = lire(os.path.join(RES, "credits.json"))
    if isinstance(cr, list):
        for c in cr:
            if not c.get("lien"):
                err(f"credits.json : crédit sans lien ({c.get('nom')})")
        if not cr:
            manque("credits.json : vide")
    li = lire(os.path.join(RES, "liens-federations.json"))
    if isinstance(li, list):
        for l in li:
            if not l.get("lien") or not l.get("releve_le"):
                err(f"liens-federations.json : lien ou date de relevé manquant ({l.get('departement')})")
        if not li:
            manque("liens-federations.json : vide")
    for n in ("coins-maison.json", "coins-osm.geojson", "departements.geojson", "lacs.geojson", "stations-hydro.json"):
        lire(os.path.join(RES, n))
    lire(os.path.join(RES, "regles", "index.json"))


def chemin_stations():
    """--stations CHEMIN, sinon le fichier téléchargé par scripts/donnees.sh, sinon la sortie de outils/hubeau."""
    c = option("--stations")
    if c:
        return c
    for rel in (("App", "Donnees", "stations-especes.json"), ("outils", "hubeau", "sortie", "stations-especes.json")):
        c = os.path.join(RACINE, *rel)
        if os.path.exists(c):
            return c
    return None


SEUIL_RECALEES = 0.9       # D5 : au moins 90 % des stations à recalee: true
ECHANTILLON = 20           # D5 : stations true tirées au sort, graine fixe
GRAINE = 2026
ECART_ECHANTILLON_M = 50   # D5 : à 50 m au plus du tracé


def verifier_stations(chemin, dossier_trace=None):
    """D5 (docs/fiches/D5.md, « Contrat ») sur stations-especes.json : 100 % portent `recalee` ; au moins 90 % à true ; aucune
    coordonnée à 2 décimales parmi les true ; 20 stations true tirées au sort (graine fixe) à 50 m au plus du tracé de leur cours
    d'eau, avec le nom du tracé. Le tracé : dossier de outils/hubeau/trace_sandre.py (paquet-*.geojson, cell-*.geojson)."""
    import glob
    import random
    sys.path.insert(0, os.path.join(RACINE, "outils", "hubeau"))
    import recalage
    doc = lire(chemin)
    if doc is None:
        return
    stations = doc.get("stations") if isinstance(doc, dict) else None
    nom = os.path.relpath(chemin, RACINE)
    if not stations:
        err(f"{nom} : aucune station")
        return
    sans = [s["id"] for s in stations if not isinstance(s.get("recalee"), bool)]
    if sans:
        err(f"{nom} : {len(sans)} station(s) sur {len(stations)} sans champ recalee (booléen), par exemple {sans[:3]}")
        return
    vraies = [s for s in stations if s["recalee"]]
    part = len(vraies) / len(stations)
    if part < SEUIL_RECALEES:
        err(f"{nom} : {len(vraies)} stations recalées sur {len(stations)} ({part:.1%}), il en faut {SEUIL_RECALEES:.0%} au moins. "
            "Regarder doc[\"recalage\"] / le rapport de hubeau.py : cours d'eau absent du tracé, tracé trop grossier, stations sans cours d'eau.")
    for s in vraies:
        if recalage.a_deux_decimales_ou_moins(s["lat"]) or recalage.a_deux_decimales_ou_moins(s["lon"]):
            err(f"{nom} : station {s['id']} recalee: true mais coordonnée à 2 décimales ou moins ({s['lat']}, {s['lon']})")
    tirage = random.Random(GRAINE).sample(sorted(vraies, key=lambda s: s["id"]), min(ECHANTILLON, len(vraies)))
    dossier_trace = dossier_trace or os.path.join(RACINE, "outils", "hubeau", "cache", "trace")
    fichiers = glob.glob(os.path.join(dossier_trace, "*.geojson")) if os.path.isdir(dossier_trace) else []
    if not fichiers:
        manque(f"{nom} : échantillon de {len(tirage)} stations true non vérifié (pas de tracé dans {os.path.relpath(dossier_trace, RACINE)} ; "
               "--trace DOSSIER, ou outils/hubeau/trace_sandre.py)")
        return
    # on ne garde du tracé que ce que l'échantillon demande (un fichier à la fois : la France entière ne tient pas toujours en mémoire)
    codes = {s["code_eau"] for s in tirage if s.get("code_eau")}
    cellules = {recalage.cellule(s["lat"], s["lon"]) for s in tirage if not s.get("code_eau")}
    t = recalage.Trace()
    for f in sorted(fichiers):
        base = os.path.basename(f)
        if base.startswith("cell-"):
            ix, iy = base[5:-8].split("_")
            if (int(ix), int(iy)) not in cellules:
                continue
        with open(f, encoding="utf-8") as h:
            d = json.load(h)
        d["features"] = [x for x in d.get("features", [])
                         if base.startswith("cell-") or (x.get("properties") or {}).get("CdEntiteHydrographique") in codes]
        t.ajouter_geojson(d)
    ok = 0
    for s in tirage:
        if s.get("code_eau") and t.a_le_code(s["code_eau"]):
            candidats = t.par_code[s["code_eau"]]
        else:  # station rattachée par voisinage (sans cours d'eau) ou par le nom : tout le tracé chargé
            candidats = [(n, l) for ents in t.par_code.values() for n, l in ents]
        meilleur = None
        for n, lignes in candidats:
            r = recalage.plus_proche_sur_lignes(s["lat"], s["lon"], lignes, ECART_ECHANTILLON_M)
            if r and (meilleur is None or r[0] < meilleur[0]):
                meilleur = (r[0], n)
        if meilleur is None:
            err(f"{nom} : station {s['id']} true à plus de {ECART_ECHANTILLON_M} m du tracé de son cours d'eau ({s.get('eau')}, {s.get('code_eau')})")
        elif (meilleur[1] or "") != (s.get("eau") or ""):  # tracé sans nom et station sans eau : même absence
            err(f"{nom} : station {s['id']} : cours d'eau « {s.get('eau')} », mais le tracé s'appelle « {meilleur[1]} »")
        else:
            ok += 1
    print(f"{nom} : {len(vraies)}/{len(stations)} recalées ({part:.1%}) ; échantillon {ok}/{len(tirage)} à {ECART_ECHANTILLON_M} m au plus du tracé")


def chemin_stations_temperature():
    """--stations-temperature CHEMIN, sinon le fichier téléchargé par scripts/donnees.sh, sinon la sortie de outils/hubeau."""
    c = option("--stations-temperature")
    if c:
        return c
    for rel in (("App", "Donnees", "stations-temperature.json"), ("outils", "hubeau", "sortie", "stations-temperature.json")):
        c = os.path.join(RACINE, *rel)
        if os.path.exists(c):
            return c
    return None


CHAMPS_TEMPERATURE = ("code", "nom", "eau", "code_eau", "lat", "lon", "dep", "en_service")


def problemes_stations_temperature(stations):
    """Forme de stations-temperature.json (outils/hubeau/stations_temperature.py, lu par N3) : un tableau de stations avec
    code, nom, eau, code_eau, lat, lon, dep, en_service (`eau` et `code_eau` peuvent valoir null) ; au moins une station en
    service. Rend la liste des problèmes (texte), vide si tout va bien. Aucun accès au réseau."""
    if not isinstance(stations, list):
        return ["stations-temperature.json : un tableau de stations est attendu"]
    if not stations:
        return ["stations-temperature.json : aucune station"]
    pb = []
    codes = set()
    for i, s in enumerate(stations):
        if not isinstance(s, dict):
            pb.append(f"station n°{i} : un objet est attendu")
            continue
        manquants = [c for c in CHAMPS_TEMPERATURE if c not in s]
        if manquants:
            pb.append(f"station n°{i} ({s.get('code')}) : champ(s) absent(s) {manquants}")
            continue
        if not isinstance(s["code"], str) or not s["code"]:
            pb.append(f"station n°{i} : code vide ou pas du texte")
        elif s["code"] in codes:
            pb.append(f"station {s['code']} : code en double")
        codes.add(s["code"])
        if not isinstance(s["nom"], str) or not s["nom"]:
            pb.append(f"station {s['code']} : nom vide")
        for c in ("eau", "code_eau", "dep"):
            if s[c] is not None and not isinstance(s[c], str):
                pb.append(f"station {s['code']} : {c} doit être du texte ou null")
        lat, lon = s["lat"], s["lon"]
        nombres = all(isinstance(v, (int, float)) and not isinstance(v, bool) for v in (lat, lon))
        if not nombres:
            pb.append(f"station {s['code']} : lat et lon doivent être des nombres")
        elif not (41 <= lat <= 52 and -6 <= lon <= 10):  # France métropolitaine
            pb.append(f"station {s['code']} : position hors de la France métropolitaine ({lat}, {lon})")
        if not isinstance(s["en_service"], bool):
            pb.append(f"station {s['code']} : en_service doit être un booléen")
    if not any(isinstance(s, dict) and s.get("en_service") is True for s in stations):
        pb.append("stations-temperature.json : aucune station en service")
    return pb


def verifier_stations_temperature(chemin):
    """Fichier facultatif (N3) : une forme fausse est une ERREUR, l'absence du fichier n'en est pas une."""
    nom = os.path.relpath(chemin, RACINE)
    doc = lire(chemin)
    if doc is None:
        return
    for p in problemes_stations_temperature(doc):
        err(f"{nom} : {p}")
    if isinstance(doc, list):
        print(f"{nom} : {len(doc)} stations, {sum(1 for s in doc if isinstance(s, dict) and s.get('en_service') is True)} en service")


def verifier_git():
    try:
        sortie = subprocess.run(["git", "ls-files"], cwd=RACINE, capture_output=True, text=True, check=True).stdout
    except Exception:  # noqa: BLE001
        return
    for l in sortie.splitlines():
        if "stations-especes" in l or "rarete-departements" in l or os.path.basename(l) == "stations-temperature.json":
            err(f"fichier fabriqué commité : {l}")


# ---------------------------------------------------------------------------------------------------------------------
# Chargeur : fusion prudente des lectures de D3 (docs/fiches/D1.md, « Contrat »)
# ---------------------------------------------------------------------------------------------------------------------
DEPUIS = os.environ.get("REGLES_DIR") or "/mnt/project-files/build/regles/cloud"
V1_CHARGEUR = V1 | {"regle", "note", "hors"}
PROTEGES = ("75", "94")  # relus par une personne : le chargeur n'y touche jamais
NIVEAUX = {"national", "departement", "cours_eau", "troncon", "plan_eau"}
TAILLE_MAX = 400 * 1024
SEUIL_SANS_RESERVE = 0.6


class Refus(Exception):
    """Le chargement s'arrête, rien n'est écrit."""


def norm(texte):
    texte = unicodedata.normalize("NFKD", texte or "").encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", " ", texte).strip()


def nom_eau_brut(lieu):
    """Ce qui précède la première parenthèse, virgule, point-virgule ou deux-points (comme nom_eau de outils/regles/consensus.py)."""
    return re.split(r"[(,:;]", lieu or "", maxsplit=1)[0].strip()


def cle_eau(lieu):
    return norm(re.sub(r"^(lac|plan d'eau|etang|étang|canal|riviere|rivière)\s+(de |du |des |d')?", "", nom_eau_brut(lieu), flags=re.I))


def refuser_v1(code, regles, lecture):
    for r in regles:
        v = r.get("valeur")
        if v is not None and not isinstance(v, dict):
            raise Refus(f"{code} ({lecture}) : la règle {r.get('id')} a une valeur qui n'est pas un objet : forme v1, à relire en v2 avant chargement.")
        trouves = V1_CHARGEUR & set(v or {})
        if trouves:
            raise Refus(f"{code} ({lecture}) : la règle {r.get('id')} a une valeur en forme v1 (clés {sorted(trouves)}) : "
                        "à relire en v2 (consigne de D3) avant chargement.")


class Textes:
    """Range chaque source une fois (titre, url, lu_le, version) et rend son id."""

    def __init__(self, entetes):
        self.liste, self.index, self.signatures = [], {}, {}
        for t in entetes:
            if t.get("url") and t.get("signe_le"):
                self.signatures.setdefault(t["url"], set()).add(t["signe_le"])

    def id(self, source):
        if not source or not source.get("texte") or not source.get("url") or not source.get("lu_le"):
            return None
        cle = (source["texte"], source["url"])
        if cle not in self.index:
            sig = self.signatures.get(source["url"], set())
            self.index[cle] = f"t{len(self.liste) + 1}"
            self.liste.append({"id": self.index[cle], "titre": source["texte"], "url": source["url"],
                               "signe_le": next(iter(sig)) if len(sig) == 1 else None,
                               "lu_le": source["lu_le"], "version": source.get("version")})
        return self.index[cle]

    def garder_utilises(self, utilises):
        self.liste = [t for t in self.liste if t["id"] in utilises]


def couper(citation, n=300):
    c = " ".join((citation or "").split())
    return c if len(c) <= n else c[:n - 6].rstrip() + " [...]"


def eau_de(r, eaux):
    portee = r.get("portee") or {}
    niveau = portee.get("niveau")
    if niveau not in NIVEAUX:
        raise Refus(f"règle {r.get('id')} : portee.niveau inconnu ({niveau}).")
    cle = cle_eau(portee.get("lieu")) if niveau in ("cours_eau", "troncon", "plan_eau") else ""
    if not cle:
        return None
    eaux.setdefault(cle, {"cle": cle, "nom": nom_eau_brut(portee.get("lieu")), "code": None})
    return cle


def cm_de(r):
    v = r.get("valeur") or {}
    c = v.get("cm")
    return c if isinstance(c, (int, float)) and not isinstance(c, bool) else None


def construire_regle(r, textes, eaux, ids_nat):
    """Une règle confirmée au schéma de 94.json, ou None si elle n'a pas de source complète ou de citation."""
    source = r.get("source")
    tid = textes.id(source)
    if tid is None and isinstance(r.get("lecture_b"), dict):
        tid = textes.id(r["lecture_b"].get("source"))
    citation = couper(r.get("citation"))
    if tid is None or not citation:
        return None
    portee = r.get("portee") or {}
    remplace = r.get("remplace")
    return {"id": r["id"],
            "portee": {"niveau": portee.get("niveau"), "code": portee.get("code"), "eau": eau_de(r, eaux),
                       "lieu": portee.get("lieu") or None, "geometrie": None},
            "especes": list(r.get("especes") or []), "categorie": r.get("categorie"), "type": r.get("type"),
            "valeur": dict(r.get("valeur") or {}), "du": r.get("du"), "au": r.get("au"),
            "remplace": remplace if remplace in ids_nat else None,
            "phrase": r.get("phrase"), "textes": [tid], "citation": citation,
            "expire_le": r.get("expire_le"), "statut": r.get("statut") if r.get("statut") in ("brouillon", "incertain") else "incertain",
            "verifie_par": None}


def fusionner_tailles(regles, avertissements):
    """Deux tailles confirmées différentes pour (espèces, catégorie, eau, dates) : une règle, valeur.candidats_cm, deux textes, incertain."""
    groupes = {}
    for r in regles:
        if r["type"] == "taille_min" and cm_de(r) is not None and "candidats_cm" not in r["valeur"]:
            cle = (tuple(sorted(r["especes"])), r["categorie"], r["portee"]["eau"], r["du"], r["au"])
            groupes.setdefault(cle, []).append(r)
    sortie, fusionnes = [], set()
    for rs in groupes.values():
        if len({cm_de(r) for r in rs}) < 2:
            continue
        # Un seul texte ne se contredit pas : deux tailles venues du même texte sont deux tronçons d'une même rivière.
        if len({t for r in rs for t in r["textes"]}) < 2:
            continue
        rs = sorted(rs, key=lambda r: (cm_de(r), r["id"]))
        base = rs[0]
        cands = sorted({cm_de(r) for r in rs})
        tids = []
        for r in rs:
            for t in r["textes"]:
                if t not in tids:
                    tids.append(t)
        cits = [r["citation"] for r in rs]
        citation = " | ".join(cits) if sum(map(len, cits)) + 3 * (len(cits) - 1) <= 300 else " | ".join(couper(c, 300 // len(cits) - 3) for c in cits)
        fusion = dict(base, valeur={"cm": None, "candidats_cm": cands}, textes=tids, citation=citation, statut="incertain",
                      phrase="Deux tailles lues dans les textes : " + " et ".join(f"{c:g} cm" for c in cands) + " ; la plus stricte s'applique.")
        if len(tids) < 2:
            avertissements.append(f"{base['id']} : deux tailles {cands} mais un seul texte cité")
        sortie.append(fusion)
        fusionnes.update(r["id"] for r in rs)
        avertissements.append(f"{base['id']} : tailles {cands} cm confirmées avec deux valeurs, fusion en candidats_cm ({', '.join(r['id'] for r in rs)})")
    return [r for r in regles if r["id"] not in fusionnes] + sortie


def entree_a_verifier(r, textes, eaux):
    tid = textes.id(r.get("source"))
    return {"type": r.get("type"), "especes": list(r.get("especes") or []), "categorie": r.get("categorie"),
            "eau": eau_de(r, eaux), "textes": [tid] if tid else []}


def dedoublonner(liste):
    vus, sortie = set(), []
    for a in liste:
        cle = json.dumps(a, sort_keys=True, ensure_ascii=False)
        if cle not in vus:
            vus.add(cle)
            sortie.append(a)
    return sortie


def verifier_prudence(regles, a_verifier, non_confirmees):
    """Aucune règle confirmée n'est plus souple qu'une lecture non confirmée sans qu'une entrée a_verifier la double."""
    for u in non_confirmees:
        cm_u = cm_de(u)
        if cm_u is None:
            continue
        for c in regles:
            cms = c["valeur"].get("candidats_cm") or ([c["valeur"]["cm"]] if c["valeur"].get("cm") is not None else [])
            if c["type"] == u.get("type") and set(c["especes"]) & set(u.get("especes") or []) and cms and min(cms) < cm_u:
                if not any(a["type"] == u.get("type") and set(a["especes"]) & set(u.get("especes") or []) for a in a_verifier):
                    raise Refus(f"prudence : {c['id']} ({min(cms):g} cm) est plus souple que la lecture non confirmée {u.get('id')} ({cm_u:g} cm) sans entrée a_verifier.")


def niveau_de(lectures, regles):
    """complet = deux lectures v2, tous les textes lus en entier, 60 % au moins de règles confirmées sans réserve ; sinon partiel."""
    if len(lectures) < 2 or not regles:
        return "partiel"
    for lec in lectures:
        if lec.get("version") != 2 or any(t.get("lu") != "entier" for t in lec.get("textes", [])):
            return "partiel"
    sures = sum(1 for r in regles if r["statut"] == "brouillon")
    return "complet" if sures / len(regles) >= SEUIL_SANS_RESERVE else "partiel"


def refuser_ecrasement(code, chemin):
    if code in PROTEGES:
        raise Refus(f"{code} est relu par une personne : le chargeur n'y touche jamais.")
    if os.path.exists(chemin):
        with open(chemin, encoding="utf-8") as f:
            actuel = json.load(f)
        for r in actuel.get("regles", []):
            if r.get("statut") == "verifie" or r.get("verifie_par"):
                raise Refus(f"{code} : le fichier existant a une règle relue par une personne ({r.get('id')}) ; il gagne, rien n'est écrasé.")


def ids_deja_pris(code):
    pris = {}
    for c, d in fichiers_regles().items():
        if c != code:
            for r in d.get("regles", []):
                pris[r["id"]] = c
    return pris


def assembler(code, cons, lectures, ids_pris, ids_nat, version):
    """Fusion prudente pure (sans fichier) : rend (fichier, avertissements). `cons` est la sortie de consensus.py --json."""
    avert = []
    for lec in lectures:
        refuser_v1(code, lec.get("regles", []), "lecture")
    refuser_v1(code, cons.get("regles", []), "consensus")
    textes = Textes([t for lec in lectures for t in lec.get("textes", [])])
    eaux = {}
    regles, non_confirmees = [], []
    for r in cons.get("regles", []):
        if not r.get("id") or r["id"] in ids_pris or r["id"] in ids_nat:
            raise Refus(f"{code} : id {r.get('id')} en double avec {ids_pris.get(r.get('id'), 'national.json')}.")
        c = construire_regle(r, textes, eaux, ids_nat)
        if c is None:
            non_confirmees.append(r)
            avert.append(f"{r['id']} : confirmée mais sans source complète ou sans citation, passée en a_verifier")
        else:
            regles.append(c)
    ids = [r["id"] for r in regles]
    if len(ids) != len(set(ids)):
        raise Refus(f"{code} : ids en double dans le consensus.")
    desaccords = cons.get("desaccords") or {}
    non_confirmees += list(desaccords.get("seulement_a", [])) + list(desaccords.get("seulement_b", []))
    regles = fusionner_tailles(regles, avert)
    a_verifier = dedoublonner([entree_a_verifier(r, textes, eaux) for r in non_confirmees])
    verifier_prudence(regles, a_verifier, non_confirmees)
    utilises = {t for r in regles for t in r["textes"]} | {t for a in a_verifier for t in a["textes"]}
    textes.garder_utilises(utilises)
    employees = {r["portee"]["eau"] for r in regles} | {a["eau"] for a in a_verifier}
    fichier = {"version": version, "departement": code, "niveau": niveau_de(lectures, regles), "textes": textes.liste,
               "eaux": sorted((e for e in eaux.values() if e["cle"] in employees), key=lambda e: e["cle"]), "regles": regles, "a_verifier": a_verifier}
    return fichier, avert


def assembler_une_lecture(code, lecture, ids_nat, version):
    """Département à une seule lecture : tout en a_verifier[], aucune règle, niveau partiel."""
    refuser_v1(code, lecture.get("regles", []), "lecture")
    textes, eaux = Textes(lecture.get("textes", [])), {}
    a_verifier = dedoublonner([entree_a_verifier(r, textes, eaux) for r in lecture.get("regles", [])])
    textes.garder_utilises({t for a in a_verifier for t in a["textes"]})
    return {"version": version, "departement": code, "niveau": "partiel", "textes": textes.liste,
            "eaux": sorted((e for e in eaux.values() if e["cle"] in {a["eau"] for a in a_verifier}), key=lambda e: e["cle"]), "regles": [], "a_verifier": a_verifier}, []


def lire_json(chemin, aide):
    if not os.path.exists(chemin):
        raise Refus(f"{chemin} introuvable. {aide}")
    with open(chemin, encoding="utf-8") as f:
        return json.load(f)


def ecrire_departement(code, fichier):
    texte = json.dumps(fichier, ensure_ascii=False, indent=1) + "\n"
    if len(texte.encode("utf-8")) > TAILLE_MAX:
        # Trop gros avec l'indentation (73, 428 Ko le 15 oct.) : on l'écrit sans espaces.
        texte = json.dumps(fichier, ensure_ascii=False, separators=(",", ":")) + "\n"
    if len(texte.encode("utf-8")) > TAILLE_MAX:
        raise Refus(f"{code}.json ferait {len(texte.encode('utf-8')) // 1024} Ko (limite 400 Ko).")
    os.makedirs(REGLES, exist_ok=True)
    with open(os.path.join(REGLES, code + ".json"), "w", encoding="utf-8", newline="\n") as f:
        f.write(texte)


def version_courante():
    idx = os.path.join(REGLES, "index.json")
    if os.path.exists(idx):
        with open(idx, encoding="utf-8") as f:
            return json.load(f).get("version", "2026-10-15.1")
    return "2026-10-15.1"


def option(nom, defaut=None):
    if nom in sys.argv:
        i = sys.argv.index(nom)
        if i + 1 < len(sys.argv) and not sys.argv[i + 1].startswith("--"):
            return sys.argv[i + 1]
        raise Refus(f"{nom} attend une valeur.")
    return defaut


def charger(code, depuis, une_lecture=None):
    chemin = os.path.join(REGLES, code + ".json")
    refuser_ecrasement(code, chemin)
    nat = os.path.join(REGLES, "national.json")
    ids_nat = {r["id"] for r in json.load(open(nat, encoding="utf-8")).get("regles", [])} if os.path.exists(nat) else set()
    if une_lecture:
        if une_lecture not in ("dep", "dep-b"):
            raise Refus("--lecture vaut dep ou dep-b.")
        lecture = lire_json(os.path.join(depuis, une_lecture, code + ".json"), "Aucune lecture pour ce département.")
        fichier, avert = assembler_une_lecture(code, lecture, ids_nat, version_courante())
    else:
        aide = f"Lance d'abord : REGLES_DIR={depuis} python3 <consensus.py de lot/regles-france> {code} --json"
        cons = lire_json(os.path.join(depuis, "consensus", code + ".json"), aide)
        chemins = [os.path.join(depuis, d, code + ".json") for d in ("dep", "dep-b")]
        if not any(os.path.exists(c) for c in chemins):
            # Mode consensus seul (branche regles/local) : pas de lectures dep/ ni dep-b/. La liste textes
            # vient des source des règles ; sans en-têtes de lecture, le niveau est partiel.
            lectures = []
        else:
            lectures = [lire_json(c, "Il faut les deux lectures (sinon --une-lecture).") for c in chemins]
        fichier, avert = assembler(code, cons, lectures, ids_deja_pris(code), ids_nat, version_courante())
    ecrire_departement(code, fichier)
    for a in avert:
        print("  note :", a)
    cands = sum(1 for r in fichier["regles"] if "candidats_cm" in r["valeur"])
    print(f"{code} : niveau {fichier['niveau']}, {len(fichier['regles'])} règles confirmées, {len(fichier['a_verifier'])} a_verifier, "
          f"{cands} avec candidats_cm, {len(fichier['textes'])} textes, {len(fichier['eaux'])} eaux, "
          f"{os.path.getsize(chemin) // 1024} Ko")
    reecrire_index()


def main():
    if "--charger" in sys.argv or "--une-lecture" in sys.argv:
        try:
            depuis = option("--depuis", DEPUIS)
            if "--charger" in sys.argv:
                charger(option("--charger"), depuis)
            else:
                lecture = option("--lecture")
                if lecture is None:
                    raise Refus("--une-lecture demande --lecture dep ou --lecture dep-b.")
                charger(option("--une-lecture"), depuis, lecture)
        except Refus as e:
            print("REFUS ", e)
            return 1
        return 0
    if "--index" in sys.argv:
        reecrire_index()
        return 0
    fichiers = fichiers_regles()
    if "national" not in fichiers:
        err("regles/national.json absent")
    verifier_regles(fichiers)
    verifier_dates(fichiers)
    verifier_index(fichiers)
    verifier_autres(verifier_especes())
    verifier_git()
    chemin = chemin_stations()
    if chemin:
        verifier_stations(chemin, option("--trace"))
    else:
        print("stations-especes.json absent (scripts/donnees.sh ou outils/hubeau/hubeau.py) : règles D5 non vérifiées")
    chemin_t = chemin_stations_temperature()
    if chemin_t:
        verifier_stations_temperature(chemin_t)
    else:
        print("stations-temperature.json absent (facultatif ; scripts/donnees.sh ou outils/hubeau/stations_temperature.py) : forme non vérifiée")
    for m in erreurs:
        print("ERREUR ", m)
    for m in manques:
        print("MANQUE ", m)
    nb = {c: len(d["regles"]) for c, d in fichiers.items()}
    print(f"règles par fichier : {nb} ; {len(erreurs)} erreur(s), {len(manques)} manque(s)")
    if erreurs:
        return 1
    if manques and "--porte-fusion" in sys.argv:
        print("porte de fusion : FERMÉE (manques ci-dessus)")
        return 1
    print("structure OK" + ("" if not manques else " ; porte de fusion fermée tant que les MANQUES restent"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
