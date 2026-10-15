#!/usr/bin/env python3
"""Etape 1 : recupere operations + observations OFB par departement (cache local, reprise).

Usage :
  python fetch_hubeau.py                      # tous les departements pilotes de config.json
  python fetch_hubeau.py --dep 95 75          # seulement ceux-la
  python fetch_hubeau.py --since 2015         # surcharge la date de debut

Strategie : si le departement a <= page_size lignes d'observations depuis `since`, une seule requete ;
sinon une requete par annee civile (decoupee en deux automatiquement si une annee depasse page_size).
Les reponses sont en cache gzip (Tools/data-pipeline/cache/, ignore par Git) : relancer le script
reprend la ou il s'est arrete et ne refait aucun appel deja reussi.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import date

from hubeau_client import OBS_FIELDS, OPS_FIELDS, HubeauClient, QuotaError

HERE = os.path.dirname(os.path.abspath(__file__))


def load_config(path: str | None = None) -> dict:
    path = path or os.path.join(HERE, "config.json")
    with open(path, encoding="utf-8") as f:
        cfg = json.load(f)
    cfg["_dir"] = os.path.dirname(os.path.abspath(path))
    return cfg


def resolve(cfg: dict, key: str) -> str:
    return os.path.normpath(os.path.join(cfg["_dir"], cfg[key]))


def year_ranges(since: int, today: date | None = None):
    today = today or date.today()
    for y in range(since, today.year + 1):
        yield f"{y}-01-01", f"{y}-12-31"


def fetch_department(client: HubeauClient, dep: str, since: int, log=print) -> dict:
    t0 = time.time()
    start, end = f"{since}-01-01", date.today().isoformat()
    stats = {"dep": dep, "requetes_api": 0, "requetes_cache": 0}
    ops, m = client.fetch_range("operations", dep, start, end, OPS_FIELDS)
    stats["requetes_api"] += m["api"]
    stats["requetes_cache"] += m["cache"]
    n_obs_total = client.count("observations", dep, start, end)
    obs_rows = 0
    if n_obs_total <= client.api["page_size"]:
        ranges = [(start, end)]
    else:
        ranges = list(year_ranges(since))
    for a, b in ranges:
        rows, m = client.fetch_range("observations", dep, a, b, OBS_FIELDS)
        obs_rows += len(rows)
        stats["requetes_api"] += m["api"]
        stats["requetes_cache"] += m["cache"]
    stats.update(operations=len(ops), observations_lots=obs_rows, observations_annoncees=n_obs_total,
                 secondes=round(time.time() - t0, 1))
    log(f"[{dep}] {len(ops)} operations, {obs_rows} lots (annonces {n_obs_total}), "
        f"{stats['requetes_api']} appels API, {stats['requetes_cache']} en cache, {stats['secondes']} s")
    return stats


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config")
    ap.add_argument("--dep", nargs="*")
    ap.add_argument("--since", type=int)
    a = ap.parse_args(argv)
    cfg = load_config(a.config)
    since = a.since or cfg["since"]
    deps = a.dep or cfg["departements_pilotes"]
    client = HubeauClient(cfg, resolve(cfg, "cache_dir"))
    done, failed = [], []
    for dep in deps:
        try:
            done.append(fetch_department(client, dep, since))
        except QuotaError as e:
            print(f"[{dep}] ARRET: {e}", file=sys.stderr)
            failed.append({"dep": dep, "erreur": str(e)})
            break
        except Exception as e:  # on continue avec les autres departements
            print(f"[{dep}] ECHEC: {e}", file=sys.stderr)
            failed.append({"dep": dep, "erreur": str(e)})
    rep = {"since": since, "reussis": done, "echecs": failed, "requetes_api_total": client.n_requests,
           "secondes_api": round(client.total_seconds, 1), "date": time.strftime("%Y-%m-%d %H:%M")}
    os.makedirs(resolve(cfg, "reports_dir"), exist_ok=True)
    with open(os.path.join(resolve(cfg, "reports_dir"), "fetch_report.json"), "w", encoding="utf-8") as f:
        json.dump(rep, f, ensure_ascii=False, indent=1)
    print(f"Termine : {len(done)} departements OK, {len(failed)} echecs, {client.n_requests} requetes API.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
