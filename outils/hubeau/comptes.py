"""Comptes de peches par station, departement et region. Fonctions pures, sans reseau ni fichier.

D2 ne sort QUE des comptes : aucune classe de rarete, aucun seuil, aucun plafond, aucune fiabilite
(les 4 niveaux et leurs seuils sont dans Core, lot L1).

Unite : la peche (une operation OFB = une station a une date). « Peche » = operation avec au moins un
poisson (operation_sans_poisson faux). code_operation est un entier cote operations et un texte cote
observations : tout est compare en texte.
"""
from __future__ import annotations

from datetime import date


def debut_fenetre(aujourdhui: date, annees: int = 10) -> str:
    """1er janvier de l'annee en cours moins `annees` (2016-01-01 pour 2026)."""
    return f"{aujourdhui.year - annees}-01-01"


def _vide() -> dict:
    return {"peches": 0, "especes": {}}


def _ajoute(acc: dict, annee: int, taxons) -> None:
    acc["peches"] += 1
    for t in taxons:
        e = acc["especes"].setdefault(t, {"peches": 0, "derniere": annee})
        e["peches"] += 1
        if annee > e["derniere"]:
            e["derniere"] = annee


def paires_vers_par_op(paires, codes_especes=None) -> dict:
    """{(code_operation, code_taxon)} -> {code_operation: {code_taxon}} en texte (filtre optionnel sur les codes)."""
    par_op: dict[str, set] = {}
    for op, taxon in paires:
        if codes_especes is None or str(taxon) in codes_especes:
            par_op.setdefault(str(op), set()).add(str(taxon))
    return par_op


def agreger(stations: dict, operations, par_op: dict, debut_dix_ans: str) -> dict:
    """stations : {code_station: {"dep": "94", ...}} (dep = departement range par polygone, ou None).
    operations : lignes {code_operation, date_operation, code_station, operation_sans_poisson}.
    par_op : {code_operation en texte: ensemble de code_taxon en texte} (voir paires_vers_par_op).
    Retourne {"stations": {id: {"dix_ans": acc, "historique": acc, "derniere": annee|None}},
              "departements": {dep: {"dix_ans": acc, "historique": acc}},
              "ecartees": {"station_inconnue": n, "sans_date": n, "sans_poisson": n}}
    acc = {"peches": n, "especes": {code: {"peches": n, "derniere": annee}}}."""
    vus = set()
    out_s: dict = {}
    out_d: dict = {}
    ecart = {"station_inconnue": 0, "sans_date": 0, "sans_poisson": 0, "doublons": 0}
    for o in operations:
        op = str(o["code_operation"])
        if op in vus:
            ecart["doublons"] += 1
            continue
        vus.add(op)
        st = stations.get(o.get("code_station"))
        if st is None or not st.get("dep"):
            ecart["station_inconnue"] += 1
            continue
        d = (o.get("date_operation") or "")[:10]
        if len(d) != 10:
            ecart["sans_date"] += 1
            continue
        if o.get("operation_sans_poisson"):
            ecart["sans_poisson"] += 1
            continue
        annee = int(d[:4])
        taxons = par_op.get(op, ())
        rs = out_s.setdefault(o["code_station"], {"dix_ans": _vide(), "historique": _vide(), "derniere": None,
                                                      "derniere_dix_ans": None})
        rd = out_d.setdefault(st["dep"], {"dix_ans": _vide(), "historique": _vide()})
        portees = ["historique"] + (["dix_ans"] if d >= debut_dix_ans else [])
        for p in portees:
            _ajoute(rs[p], annee, taxons)
            _ajoute(rd[p], annee, taxons)
        if rs["derniere"] is None or annee > rs["derniere"]:
            rs["derniere"] = annee
        if d >= debut_dix_ans and (rs["derniere_dix_ans"] is None or annee > rs["derniere_dix_ans"]):
            rs["derniere_dix_ans"] = annee
    return {"stations": out_s, "departements": out_d, "ecartees": ecart}


def fusionner(a: dict, b: dict) -> dict:
    """Somme deux acc (utile pour les regions : les peches de deux departements sont distinctes)."""
    r = {"peches": a["peches"] + b["peches"], "especes": {k: dict(v) for k, v in a["especes"].items()}}
    for k, v in b["especes"].items():
        if k in r["especes"]:
            r["especes"][k]["peches"] += v["peches"]
            r["especes"][k]["derniere"] = max(r["especes"][k]["derniere"], v["derniere"])
        else:
            r["especes"][k] = dict(v)
    return r


def comptes_regions(par_dep: dict, regions: dict, deps_inclus) -> dict:
    """regions : {code_region: {"nom", "departements": [...]}}. Une region n'est `complete` que si tous
    ses departements font partie du lancement (sinon ses comptes seraient partiels)."""
    deps_inclus = set(deps_inclus)
    out = {}
    for code, r in regions.items():
        membres = r["departements"]
        acc = {"dix_ans": _vide(), "historique": _vide()}
        for d in membres:
            if d in par_dep:
                for p in acc:
                    acc[p] = fusionner(acc[p], par_dep[d][p])
        acc["nom"] = r["nom"]
        acc["complete"] = all(d in deps_inclus for d in membres)
        out[code] = acc
    return out
