"""Convertit une lecture d'arrêtés en forme v1 (clés libres dans `valeur`) vers la forme v2 de consigne-departement.md.

Usage : python3 v1_vers_v2.py <entrée.json> <sortie.json>
Écrit la sortie, affiche le nombre de règles lues, converties et écartées, et les motifs d'écart (sur stderr aussi le détail).

Règle d'or : aucune fausse donnée. Ce qui change :
- les ids, espèces (sauf noms libres, voir ci-dessous), catégories, portées, dates, statuts, sources et citations restent tels quels ;
- `valeur` ne garde en clés v2 que des nombres reconnus (cm, nombre, lignes_max...) ; tout le reste de la valeur v1
  (clés libres, notes, raisons, listes) passe en clair dans `valeur.texte`, sous la forme « clé : valeur » ;
- `ouverture` : `formule` reprend le texte v1 `regle` (ou, à défaut, les périodes écrites en toutes lettres) ;
- `taille_min` avec une fenêtre (fenetre_cm, ou cm et max_cm) devient `fenetre_capture` ;
- un nom d'espèce libre est ramené à un nom de la liste seulement s'il est sans ambiguïté, sinon `autre:<nom écrit>` ;
- une règle dont le chiffre décisif n'est pas un nombre propre (taille ou quota sans nombre, plusieurs espèces à tailles
  différentes dans une règle, catégorie ni 1 ni 2, type inconnu, ouverture sans date ni formule, citation de plus de 400 caractères) est écartée et comptée :
  dans l'app elle deviendra « vérifie l'arrêté ».
Les textes gardent leurs quatre clés (titre, url, signe_le, lu). Les clés v1 `verifie_par`, `raison_incertain`,
`lecture_limites` et `note` d'une règle passent aussi dans `valeur.texte`. `note` et `a_saisir` du fichier ne sont pas repris.
"""
import collections
import importlib.util
import json
import os
import re
import sys

_spec = importlib.util.spec_from_file_location("consensus", os.path.join(os.path.dirname(os.path.abspath(__file__)), "consensus.py"))
consensus = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(consensus)

TYPES = {"ouverture", "taille_min", "fenetre_capture", "quota_jour", "mode_peche", "interdit", "reserve", "no_kill",
         "carpe_nuit", "consommation", "horaire", "categorie", "remise_eau", "transport_vivant", "limite_eau_douce", "autre"}
NOMS_VALIDES = set(consensus.CODES) | {c for _, c in consensus.NOMS}
# Clés v1 de `valeur` qui deviennent une clé v2 numérique, par type (v1 -> v2).
CLES_CHIFFREES = {
    "taille_min": {"cm": "cm"},
    "quota_jour": {"total": "nombre"},
    "mode_peche": {"lignes_max": "lignes_max", "hamecons_max": "hamecons_max", "mouches_max": "mouches_max",
                   "mouches_artificielles_max": "mouches_max", "maille_mm_min": "maille_mm_min"},
}
# Clés dont la valeur texte se lit seule, sans l'étiquette.
CLES_NUES = {"regle", "texte"}
CLES_RACINE = ("verifie_par", "raison_incertain", "lecture_limites", "note")


def nombre(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def clair(v):
    """Une valeur v1 quelconque en texte lisible, sans rien ajouter."""
    if isinstance(v, bool):
        return "oui" if v else "non"
    if v is None:
        return "non précisé"
    if isinstance(v, (int, float)):
        return str(v).rstrip("0").rstrip(".") if isinstance(v, float) else str(v)
    if isinstance(v, str):
        return v
    if isinstance(v, list):
        return ", ".join(clair(x) for x in v)
    if isinstance(v, dict):
        return "; ".join(f"{k.replace('_', ' ')} : {clair(x)}" for k, x in v.items())
    return str(v)


def morceau(cle, v, type_):
    if isinstance(v, bool):
        return cle.replace("_", " ") if v else f"{cle.replace('_', ' ')} : non"
    if isinstance(v, str) and (cle in CLES_NUES or cle == type_):
        return v
    return f"{cle.replace('_', ' ')} : {clair(v)}"


def espece(nom):
    """Nom v1 vers nom v2 ; `autre:<nom>` quand le rapprochement serait une supposition."""
    nom = str(nom).strip()
    if nom in consensus.CODES or nom in NOMS_VALIDES or nom.startswith("autre:"):
        return nom
    sans_parentheses = re.sub(r"\(.*?\)", " ", nom)
    plein = consensus.norm(nom)
    mots = consensus.norm(sans_parentheses)
    if "," in nom or " et " in nom.split("(")[0] or "fritures" in plein:
        return "autre:" + nom
    if re.search(r"\bautres?\b", plein):
        mots = consensus.norm(sans_parentheses)
        return "grenouilles-autres" if "grenouille" in mots else "autre:" + nom
    if mots == "alose":
        return "autre:" + nom
    base = plein if "hors" not in plein else mots
    canon = consensus.espece(base) if base else ""
    if canon not in NOMS_VALIDES:
        return "autre:" + nom
    return canon


def periodes_en_clair(periodes):
    if not isinstance(periodes, list):
        return None
    morceaux = []
    for p in periodes:
        if isinstance(p, dict) and p.get("du") and p.get("au"):
            morceaux.append(f"du {p['du']} au {p['au']}")
        else:
            return None
    return " ; ".join(morceaux) or None


def convertir_valeur(r, motifs):
    """Rend (type, valeur v2) ou None si la règle doit être écartée (motif ajouté)."""
    type_ = r.get("type")
    v = dict(r.get("valeur") or {})
    if type_ not in TYPES:
        motifs["type inconnu"] += 1
        return None
    sortie = {}
    reste = dict(v)

    if type_ == "taille_min":
        fen = reste.get("fenetre_cm")
        if isinstance(fen, list) and len(fen) == 2 and all(nombre(x) for x in fen):
            type_ = "fenetre_capture"
            sortie = {"min_cm": fen[0], "max_cm": fen[1]}
            del reste["fenetre_cm"]
        elif nombre(reste.get("cm")) and nombre(reste.get("max_cm")):
            type_ = "fenetre_capture"
            sortie = {"min_cm": reste.pop("cm"), "max_cm": reste.pop("max_cm")}
        elif nombre(reste.get("cm")):
            sortie = {"cm": reste.pop("cm")}
        else:
            motifs["taille minimale sans nombre unique (cm absent, ou une taille par espèce)"] += 1
            return None
    elif type_ in CLES_CHIFFREES:
        for ancien, nouveau in CLES_CHIFFREES[type_].items():
            if nombre(reste.get(ancien)) and nouveau not in sortie:
                sortie[nouveau] = reste.pop(ancien)
        if type_ == "quota_jour" and "nombre" not in sortie:
            motifs["quota sans nombre par jour (kg, par espèce ou texte)"] += 1
            return None
    elif type_ == "categorie":
        c = reste.get("categorie")
        classe = str(c) if c is not None else str(r.get("categorie"))
        if classe not in ("1", "2"):
            motifs["catégorie ni 1 ni 2"] += 1
            return None
        sortie = {"classe": classe}
        reste.pop("categorie", None)
    elif type_ == "ouverture":
        formule = reste.pop("regle", None)
        periodes = reste.pop("periodes", None)
        en_clair = periodes_en_clair(periodes)
        if not isinstance(formule, str) or not formule.strip():
            formule = en_clair
        elif periodes and len(periodes) > 1 and en_clair:
            reste = {"periodes": en_clair, **reste}
        if not formule and not (r.get("du") and r.get("au")):
            motifs["ouverture sans formule ni dates"] += 1
            return None
        if formule:
            sortie = {"formule": formule}
        elif r.get("du") and r.get("au"):
            sortie = {"formule": f"du {r['du']} au {r['au']}"}

    for k in CLES_RACINE:
        if r.get(k) not in (None, "", [], {}):
            reste[k] = r[k]
    morceaux = [morceau(k, x, type_) for k, x in reste.items() if x not in (None, "", [], {})]
    morceaux = [m for m in morceaux if m]
    if morceaux:
        sortie["texte"] = " ; ".join(morceaux)
    if not sortie:
        motifs["valeur vide"] += 1
        return None
    return type_, sortie


def convertir_regle(r, motifs):
    if len(r.get("citation") or "") > 400:
        motifs["citation de plus de 400 caractères (on ne la coupe pas)"] += 1
        return None
    res = convertir_valeur(r, motifs)
    if res is None:
        return None
    type_, valeur = res
    portee = dict(r.get("portee") or {})
    portee.setdefault("plan_eau", None)
    portee.setdefault("cours_eau", None)
    sortie = {
        "id": r["id"], "type": type_, "especes": [espece(e) for e in r.get("especes") or []],
        "categorie": str(r.get("categorie", "toutes")), "portee": portee,
        "du": r.get("du"), "au": r.get("au"), "valeur": valeur,
        "phrase": r.get("phrase"), "source": r.get("source"), "citation": r.get("citation"),
        "statut": r.get("statut"), "expire_le": r.get("expire_le"), "remplace": r.get("remplace"),
    }
    return sortie


def convertir(donnees):
    motifs = collections.Counter()
    regles = []
    for r in donnees.get("regles", []):
        sortie = convertir_regle(r, motifs)
        if sortie is not None:
            regles.append(sortie)
    textes = [{"titre": t.get("titre"), "url": t.get("url"), "signe_le": t.get("signe_le"), "lu": t.get("lu")}
              for t in donnees.get("textes", [])]
    resultat = {"version": 2, "departement": donnees.get("departement"), "genere_le": donnees.get("genere_le"),
                "textes": textes, "regles": regles}
    return resultat, len(donnees.get("regles", [])), motifs


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 1
    with open(sys.argv[1], encoding="utf-8") as f:
        donnees = json.load(f)
    resultat, avant, motifs = convertir(donnees)
    with open(sys.argv[2], "w", encoding="utf-8") as f:
        json.dump(resultat, f, ensure_ascii=False, indent=1)
        f.write("\n")
    ecartees = avant - len(resultat["regles"])
    print(f"{avant} règles lues, {len(resultat['regles'])} converties, {ecartees} écartées")
    for motif, n in motifs.most_common():
        print(f"  écartée ({n}) : {motif}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
