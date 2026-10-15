"""Fonctions pures de rarete (sans reseau ni fichier) : testees par tests/test_rarity.py.

Unite statistique : l'operation de peche (une station, une date). Pour (departement, espece) :
freq_ops = operations ou l'espece est presente / operations du departement (depuis `since`).
"""
from __future__ import annotations

from collections import defaultdict


def classify(freq: float, bornes: list[float]) -> int:
    """bornes = [commune, peu_commune, rare, tres_rare] (bornes basses, freq >= borne).
    Retourne 1 (commune) .. 5 (remarquable, sous la derniere borne)."""
    for i, b in enumerate(bornes):
        if freq >= b:
            return i + 1
    return len(bornes) + 1


def apply_ceiling(classe: int, milieu: str, plafond: dict) -> tuple[int, bool]:
    """Espece de plan d'eau : classe plafonnee (ex. 2 = au plus 'peu commune'). Retourne (classe, plafonne?)."""
    cap = plafond.get(milieu)
    if cap is not None and classe > cap:
        return cap, True
    return classe, False


def reliability(n_ops: int, n_sta: int, fiab: dict) -> str:
    """'faible' si moins de min_stations stations ou moins de min_operations operations."""
    if n_sta < fiab["min_stations"] or n_ops < fiab["min_operations"]:
        return "faible"
    return "ok"


def canonical(code: str, fusion: dict) -> str:
    """Fusionne des codes d'une meme espece (ex. CMI, CCU -> CCO)."""
    for target, members in fusion.items():
        if code in members:
            return target
    return code


def aggregate(ops: list[dict], obs: list[dict], since: int, fusion: dict) -> dict:
    """Comptes bruts par espece. ops/obs = lignes Hub'Eau. Les observations d'operations inconnues
    ou anterieures a `since` sont ignorees (comptees dans 'obs_ignorees')."""
    since_s = str(since)
    ops_ok = {}
    for o in ops:
        if (o.get("date_operation") or "")[:4] >= since_s:
            ops_ok[str(o["code_operation"])] = o.get("code_station")  # int cote operations, str cote observations
    stations = {s for s in ops_ok.values() if s}
    per_ops, per_sta = defaultdict(set), defaultdict(set)
    ignored = 0
    for r in obs:
        op, sp = str(r.get("code_operation")), r.get("code_alternatif_taxon")
        if op not in ops_ok or not sp:
            ignored += 1
            continue
        sp = canonical(sp, fusion)
        per_ops[sp].add(op)
        per_sta[sp].add(ops_ok[op] or r.get("code_station"))
    return {"n_ops": len(ops_ok), "n_sta": len(stations), "obs_ignorees": ignored,
            "especes": {sp: (len(per_ops[sp]), len(per_sta[sp])) for sp in per_ops}}


def rank_species(agg: dict, meta: dict, bornes: list[float], plafond: dict, min_ops_species: int = 3):
    """Classe chaque espece connue. Retourne (liste triee, codes_inconnus).
    Elements : dict code, nom, o (ops), s (stations), p (freq), k (classe 1-5 ou absente si statut),
    st (statut), pl (plafonne), r (1 si fonde sur < 3 operations). Tri : freq decroissante, puis code."""
    n = agg["n_ops"] or 1
    out, unknown = [], {}
    for sp, (k_ops, k_sta) in agg["especes"].items():
        m = meta.get(sp)
        if m is None:
            unknown[sp] = k_ops
            continue
        nom, milieu, statut = m
        e = {"c": sp, "n": nom, "o": k_ops, "s": k_sta, "p": round(k_ops / n, 4)}
        if statut:
            e["st"] = statut  # exotique / protege / non_poisson : pas de classe de rarete
        else:
            k, capped = apply_ceiling(classify(k_ops / n, bornes), milieu, plafond)
            e["k"] = k
            if capped:
                e["pl"] = 1
        if k_ops < min_ops_species:
            e["r"] = 1
        out.append(e)
    out.sort(key=lambda e: (-e["p"], e["c"]))
    return out, unknown


def distribution(especes: list[dict], n_classes: int = 5) -> dict:
    """Repartition des classes parmi les especes classees (hors statut)."""
    d = {k: 0 for k in range(1, n_classes + 1)}
    for e in especes:
        if "k" in e:
            d[e["k"]] += 1
    return d
