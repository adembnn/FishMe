#!/usr/bin/env python3
"""Vérificateur des données embarquées (lot D1, docs/fiches/D1.md, « Test fini »).

  python3 outils/verifier_donnees.py              vérifie la structure ; liste les MANQUES de contenu ; sort 1 s'il y a une ERREUR
  python3 outils/verifier_donnees.py --porte-fusion   sort aussi 1 s'il reste un MANQUE (relecture de S, cas d'or, espèces, images...)
  python3 outils/verifier_donnees.py --index      réécrit regles/index.json (sha256, expire_min, nombres) d'après les fichiers présents

Pas encore écrit : --charger <code> (chargement des fichiers confirmés de D3 : aucun n'est arrivé).
"""
import datetime
import hashlib
import json
import os
import subprocess
import sys

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
        if code in IDF:
            n = sum(1 for r in d["regles"] if r["statut"] == "brouillon")
            if n:
                manque(f"{code} : {n} règles encore « brouillon », à relire par S (reports/relecture/{code}.csv)")
    return vus


def ouvert(fichiers, espece, cat, jour):
    """Lit les données : False si une règle chargée ferme l'espèce ce jour-là (période bornée seulement)."""
    j = jour.isoformat()
    for d in fichiers.values():
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
    if len(esp) < 101:
        manque(f"especes.json : {len(esp)} entrées sur 101 (la liste de reconnaissance de 101 entrées et 66 classes est absente)")
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


def verifier_git():
    try:
        sortie = subprocess.run(["git", "ls-files"], cwd=RACINE, capture_output=True, text=True, check=True).stdout
    except Exception:  # noqa: BLE001
        return
    for l in sortie.splitlines():
        if "stations-especes" in l or "rarete-departements" in l:
            err(f"fichier fabriqué commité : {l}")


def main():
    if "--charger" in sys.argv:
        print("--charger n'est pas encore écrit : aucun fichier confirmé de D3 n'est arrivé (reports/d1-manques.md).")
        return 2
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
