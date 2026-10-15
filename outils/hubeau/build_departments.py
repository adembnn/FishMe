#!/usr/bin/env python3
"""Etape 2 : cache Hub'Eau -> JSON de rarete par departement (PecheCore/.../Data/departments/<code>.json).

Usage :
  python build_departments.py                 # tous les departements presents dans le cache
  python build_departments.py --dep 95 75     # seulement ceux-la
  python build_departments.py --compare       # compare les profils de seuils A/B (rapport, n'ecrit rien d'autre)
  python build_departments.py --profil A      # force un profil de seuils de config.json

Source des donnees : OFB / ASPE via Hub'Eau, Licence Ouverte 2.0. Aucun appel reseau ici.
"""
from __future__ import annotations

import argparse
import glob
import gzip
import json
import os
import sys
import time

import rarity
from fetch_hubeau import load_config, resolve

HERE = os.path.dirname(os.path.abspath(__file__))


def load_cached(cache_dir: str, endpoint: str, dep: str) -> list[dict]:
    """Concatene les lignes de tous les fichiers de cache d'un endpoint/departement (hors count_*)."""
    rows = []
    for p in sorted(glob.glob(os.path.join(cache_dir, endpoint, dep, "*.json.gz"))):
        if os.path.basename(p).startswith("count_"):
            continue
        with gzip.open(p, "rt", encoding="utf-8") as f:
            rows.extend(json.load(f)["data"])
    return rows


def announced_lots(cache_dir: str, dep: str):
    """Nombre de lots annonce par l'API (fichier count_*), None si inconnu."""
    for p in glob.glob(os.path.join(cache_dir, "observations", dep, "count_*.json.gz")):
        with gzip.open(p, "rt", encoding="utf-8") as f:
            return json.load(f)["count"]
    return None


def load_meta() -> dict:
    with open(os.path.join(HERE, "species_meta.json"), encoding="utf-8") as f:
        return json.load(f)["especes"]


def available_deps(cache_dir: str) -> list[str]:
    ops = {os.path.basename(d) for d in glob.glob(os.path.join(cache_dir, "operations", "*"))}
    obs = {os.path.basename(d) for d in glob.glob(os.path.join(cache_dir, "observations", "*"))}
    return sorted(d for d in ops & obs if glob.glob(os.path.join(cache_dir, "operations", d, "*.json.gz"))
                  and any(not os.path.basename(p).startswith("count_")
                          for p in glob.glob(os.path.join(cache_dir, "observations", d, "*.json.gz"))))


def build(dep: str, cfg: dict, meta: dict, profil: str, cache_dir: str) -> tuple[dict, dict]:
    bornes = cfg["seuils"]["profils"][profil]
    ops = load_cached(cache_dir, "operations", dep)
    obs = load_cached(cache_dir, "observations", dep)
    agg = rarity.aggregate(ops, obs, cfg["since"], cfg["fusion_codes"])
    especes, unknown = rarity.rank_species(agg, meta, bornes, cfg["plafond_milieu"])
    fiab = rarity.reliability(agg["n_ops"], agg["n_sta"], cfg["fiabilite"])
    doc = {"v": 1, "dep": dep, "depuis": cfg["since"], "ops": agg["n_ops"], "sta": agg["n_sta"], "fiab": fiab,
           "profil": profil, "seuils": bornes, "genere": time.strftime("%Y-%m-%d"),
           "source": cfg["source"], "licence": cfg["licence"], "especes": especes}
    annonces = announced_lots(cache_dir, dep)
    stats = {"dep": dep, "lots": len(obs), "lots_annonces": annonces, "complet": annonces is None or len(obs) >= annonces,
              "ops_brutes": len(ops), "ops": agg["n_ops"], "sta": agg["n_sta"],
             "fiab": fiab, "obs_ignorees": agg["obs_ignorees"], "inconnus": unknown,
             "n_especes": len(especes), "distribution": rarity.distribution(especes)}
    return doc, stats


def write_json(doc: dict, out_dir: str) -> int:
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, f"{doc['dep']}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
    return os.path.getsize(path)


def compare(cfg, meta, deps, cache_dir) -> dict:
    """Distribution des classes pour chaque profil, par departement et agregee."""
    res = {}
    for profil in cfg["seuils"]["profils"]:
        tot = {k: 0 for k in range(1, 6)}
        par_dep = {}
        for dep in deps:
            _, st = build(dep, cfg, meta, profil, cache_dir)
            if not st["complet"]:
                continue
            par_dep[dep] = {"distribution": st["distribution"], "fiab": st["fiab"], "ops": st["ops"]}
            for k, v in st["distribution"].items():
                tot[k] += v
        n = sum(tot.values()) or 1
        res[profil] = {"bornes": cfg["seuils"]["profils"][profil], "total": tot,
                       "parts_pct": {k: round(100 * v / n, 1) for k, v in tot.items()}, "par_dep": par_dep}
    return res


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config")
    ap.add_argument("--dep", nargs="*")
    ap.add_argument("--profil")
    ap.add_argument("--compare", action="store_true")
    a = ap.parse_args(argv)
    cfg = load_config(a.config)
    meta, cache_dir = load_meta(), resolve(cfg, "cache_dir")
    deps = a.dep or available_deps(cache_dir)
    if not deps:
        print("Aucun departement en cache : lancer fetch_hubeau.py", file=sys.stderr)
        return 1
    reports = resolve(cfg, "reports_dir")
    os.makedirs(reports, exist_ok=True)
    if a.compare:
        res = compare(cfg, meta, deps, cache_dir)
        with open(os.path.join(reports, "seuils_comparaison.json"), "w", encoding="utf-8") as f:
            json.dump({"departements": deps, "profils": res}, f, ensure_ascii=False, indent=1)
        for p, r in res.items():
            print(f"profil {p} {r['bornes']}: total {r['total']} parts % {r['parts_pct']}")
        return 0
    profil = a.profil or cfg["seuils"]["profil_actif"]
    out_dir, summary = resolve(cfg, "output_dir"), []
    for dep in deps:
        doc, st = build(dep, cfg, meta, profil, cache_dir)
        if not st["complet"]:
            print(f"[{dep}] IGNORE : cache incomplet ({st['lots']} lots sur {st['lots_annonces']} annonces)", file=sys.stderr)
            continue
        st["octets"] = write_json(doc, out_dir)
        summary.append(st)
        print(f"[{dep}] {st['ops']} ops, {st['sta']} stations, fiabilite {st['fiab']}, {st['n_especes']} especes, "
              f"classes {st['distribution']}, {st['octets']} octets, inconnus {st['inconnus'] or '-'}")
    with open(os.path.join(reports, "build_report.json"), "w", encoding="utf-8") as f:
        json.dump({"profil": profil, "date": time.strftime("%Y-%m-%d %H:%M"), "departements": summary},
                  f, ensure_ascii=False, indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
