#!/usr/bin/env python3
"""Teste les URL de etats.json (réseau) et écrit urls_statut.
Usage : python3 -I liens.py [--ecrire]
Statuts : ok (2xx), bloque_robots (401/403/429 : l'hôte répond mais refuse un robot),
injoignable (réseau), 404 (URL devinée fausse : l'URL est alors mise à null).
"""
import json, sys, urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

F = Path(__file__).with_name("etats.json")
CLES = ("url_agence", "url_regles_eau_douce", "url_permis")

def statut(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 (FishMe-verif)"})
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return "ok" if r.status < 400 else str(r.status)
    except urllib.error.HTTPError as e:
        if 300 <= e.code < 400:
            return "ok"
        return "bloque_robots" if e.code in (401, 403, 429) else str(e.code)
    except Exception:
        return "injoignable"

def main():
    d = json.loads(F.read_text())
    urls = sorted({e[k] for e in d["etats"] for k in CLES if e[k]})
    with ThreadPoolExecutor(16) as ex:
        res = dict(zip(urls, ex.map(statut, urls)))
    for e in d["etats"]:
        e["urls_statut"] = {}
        for k in CLES:
            u = e[k]
            if not u:
                continue
            s = res[u]
            if s in ("404", "410") and k != "url_agence":
                e["notes"] = (e["notes"] + " " if e["notes"] else "") + f"{k} : URL devinée {u} en {s}, retirée [?]."
                e[k] = None
            else:
                e["urls_statut"][k] = s
    if "--ecrire" in sys.argv:
        F.write_text(json.dumps(d, ensure_ascii=False, indent=1) + "\n")
    from collections import Counter
    print(Counter(res.values()))

if __name__ == "__main__":
    main()
