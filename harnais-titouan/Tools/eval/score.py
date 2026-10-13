#!/usr/bin/env python3
"""Score un journal d'identification exporte par l'app contre eval_manifest.csv.

  python -I score.py --manifest eval_manifest.csv --journal results.json [--json-out score.json]

Regles :
- Une photo du manifeste absente du journal, en erreur, ou sans proposition compte comme ECHEC (pas de gonflage).
- top-1 = vraie espece en 1re proposition ; top-3 = dans les 3 premieres.
- Latence p50/p95 (interpolation lineaire) sur les reponses sans erreur.
- Matrice de confusion par groupe : lignes = verite, colonnes = 1re proposition ;
  'hors_groupe' = 1re proposition d'une espece d'un autre groupe, 'aucune' = pas de proposition utilisable.
- Verdict GO / NO-GO : voir PROTOCOLE.md (seuils en constantes ci-dessous).
Format du journal : voir journal.schema.json.
"""
import argparse, csv, json, sys
from collections import Counter, defaultdict
from pathlib import Path

GROUPS = ["carnassiers", "cyprinides_argentes", "carpes", "salmonides"]
# Groupes connus au-dela des especes du manifeste (une proposition hors manifeste reste classee dans son groupe).
KNOWN_GROUPS = {
    "carnassiers": ["brochet", "perche", "sandre", "black-bass", "silure", "aspe", "lote"],
    "cyprinides_argentes": ["gardon", "rotengle", "breme-commune", "breme-bordeliere", "chevaine", "vandoise",
                            "vandoise-rostree", "ablette", "ide-melanote", "hotu", "toxostome"],
    "carpes": ["carpe-commune", "carpe-miroir", "carpe-cuir", "carassin-commun", "carassin-argente",
               "carassin-dore", "tanche", "barbeau-fluviatile"],
    "salmonides": ["truite-fario", "truite-arc-en-ciel", "saumon-atlantique", "ombre"],
}
T_TOP3_GO, T_TOP1_GO, T_GROUP_GO, T_LAT_P50_MS, T_TOP3_NOGO = 0.85, 0.60, 0.70, 4000, 0.70


def percentile(values, q):
    if not values:
        return None
    v = sorted(values)
    k = (len(v) - 1) * q
    lo, hi = int(k), min(int(k) + 1, len(v) - 1)
    return v[lo] + (v[hi] - v[lo]) * (k - lo)


def load_manifest(path):
    with open(path, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f, delimiter=";"))


def rate(hit, n):
    return hit / n if n else None


def score(manifest, journal):
    results = {r["image_id"]: r for r in journal.get("results", [])}
    known = {m["image_id"] for m in manifest}
    unknown = sorted(set(results) - known)
    group_of = {s: g for g, ss in KNOWN_GROUPS.items() for s in ss}
    group_of.update({m["espece_verite"]: m["groupe"] for m in manifest})
    per = defaultdict(lambda: {"n": 0, "top1": 0, "top3": 0})
    conf = {g: defaultdict(Counter) for g in GROUPS}
    lat, errors, missing, out_of_list = [], 0, 0, 0
    cond = defaultdict(lambda: {"n": 0, "top3": 0})
    for m in manifest:
        truth, grp = m["espece_verite"], m["groupe"]
        r = results.get(m["image_id"])
        props = []
        if r is None:
            missing += 1
        elif r.get("error"):
            errors += 1
        else:
            props = [p for p in (r.get("proposals") or [])][:3]
            if r.get("latency_ms") is not None:
                lat.append(r["latency_ms"])
            out_of_list += int(r.get("out_of_list") or 0)
        t1 = bool(props) and props[0] == truth
        t3 = truth in props
        for key in ("__all__", grp):
            s = per[key]
            s["n"] += 1; s["top1"] += t1; s["top3"] += t3
        cond[m["condition"]]["n"] += 1
        cond[m["condition"]]["top3"] += t3
        if props:
            pred = props[0]
            col = pred if group_of.get(pred) == grp else "hors_groupe"
        else:
            col = "aucune"
        conf[grp][truth][col] += 1
    allm = per["__all__"]
    groups = {g: {"n": per[g]["n"], "top1": rate(per[g]["top1"], per[g]["n"]),
                  "top3": rate(per[g]["top3"], per[g]["n"])} for g in GROUPS if per[g]["n"]}
    out = {
        "n": allm["n"], "top1": rate(allm["top1"], allm["n"]), "top3": rate(allm["top3"], allm["n"]),
        "latence_ms": {"p50": percentile(lat, 0.5), "p95": percentile(lat, 0.95), "n": len(lat)},
        "erreurs": errors, "non_repondu": missing, "hors_liste": out_of_list, "ids_inconnus": unknown,
        "groupes": groups, "par_condition_top3": {c: rate(v["top3"], v["n"]) for c, v in cond.items()},
        "confusion": {g: {t: dict(c) for t, c in conf[g].items()} for g in GROUPS if g in groups},
    }
    out["verdict"], out["criteres_echoues"] = verdict(out)
    return out


def verdict(o):
    failed = []
    if o["top3"] is None or o["top3"] < T_TOP3_GO:
        failed.append(f"top-3 global < {T_TOP3_GO:.0%}")
    if o["top1"] is None or o["top1"] < T_TOP1_GO:
        failed.append(f"top-1 global < {T_TOP1_GO:.0%}")
    for g, v in o["groupes"].items():
        if v["top3"] < T_GROUP_GO:
            failed.append(f"top-3 du groupe {g} < {T_GROUP_GO:.0%}")
    p50 = o["latence_ms"]["p50"]
    if p50 is None or p50 > T_LAT_P50_MS:
        failed.append(f"latence p50 > {T_LAT_P50_MS} ms")
    if o["top3"] is None or o["top3"] < T_TOP3_NOGO:
        return "NO-GO", failed
    return ("GO" if not failed else "GO_AVEC_CONFIRMATION_OBLIGATOIRE"), failed


def fmt(x):
    return "n/a" if x is None else f"{x:.0%}"


def report(o):
    lines = [f"n={o['n']}  top-1={fmt(o['top1'])}  top-3={fmt(o['top3'])}  erreurs={o['erreurs']}  "
             f"non_repondu={o['non_repondu']}  hors_liste={o['hors_liste']}",
             "latence ms : p50={p50} p95={p95} (n={n})".format(**{k: (round(v) if isinstance(v, float) else v)
                                                                for k, v in o["latence_ms"].items()})]
    for g, v in o["groupes"].items():
        lines.append(f"  groupe {g:<20} n={v['n']:<3} top-1={fmt(v['top1'])} top-3={fmt(v['top3'])}")
        for truth, row in o["confusion"][g].items():
            lines.append(f"      {truth:<18} -> " + ", ".join(f"{k}:{c}" for k, c in sorted(row.items())))
    lines.append(f"VERDICT : {o['verdict']}  {o['criteres_echoues']}")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default=str(Path(__file__).parent / "eval_manifest.csv"))
    ap.add_argument("--journal", required=True)
    ap.add_argument("--json-out")
    a = ap.parse_args()
    o = score(load_manifest(a.manifest), json.loads(Path(a.journal).read_text(encoding="utf-8")))
    print(report(o))
    if a.json_out:
        Path(a.json_out).write_text(json.dumps(o, ensure_ascii=False, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
