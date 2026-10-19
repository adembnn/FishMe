"""Recherche Reddit sans clé : search.json puis repli sur search.rss (Atom),
car le JSON public renvoie souvent 403.
Usage : python3 reddit.py "<requête>" [subreddit]
Écrit reports/marche/donnees/reddit-<slug>.csv. User-Agent explicite ;
sur 429, pause de 5 s puis un seul nouvel essai. En mode RSS, les colonnes
score et nb_commentaires restent vides (le flux ne les donne pas)."""
import csv
import pathlib
import re
import sys
import time
import xml.etree.ElementTree as ET

import requests

Q = sys.argv[1]
SUB = sys.argv[2] if len(sys.argv) > 2 else None
SORTIE = pathlib.Path(__file__).resolve().parents[2] / "reports" / "marche" / "donnees"
SORTIE.mkdir(parents=True, exist_ok=True)
UA = {"User-Agent": "fishme-etude-marche/0.1"}
NS = {"a": "http://www.w3.org/2005/Atom"}

def extraire_json(r):
    return [{"date": time.strftime("%Y-%m-%d", time.gmtime(d.get("created_utc", 0))),
             "subreddit": d.get("subreddit"), "titre": d.get("title"),
             "score": d.get("score"), "nb_commentaires": d.get("num_comments"),
             "url": "https://www.reddit.com" + d.get("permalink", "")}
            for d in (c["data"] for c in r.json().get("data", {}).get("children", []))]

def extraire_rss(r):
    out = []
    for e in ET.fromstring(r.text).findall("a:entry", NS):
        lien = next((x.get("href") for x in e.findall("a:link", NS)
                     if "/comments/" in (x.get("href") or "")), "")
        m = re.search(r"/r/([^/]+)/", lien)
        out.append({"date": (e.findtext("a:updated", default="", namespaces=NS))[:10],
                    "subreddit": m.group(1) if m else "",
                    "titre": e.findtext("a:title", default="", namespaces=NS),
                    "score": "", "nb_commentaires": "", "url": lien})
    return out

lignes = []
for suffixe in ("json", "rss"):
    if SUB:
        url = f"https://www.reddit.com/r/{SUB}/search.{suffixe}"
        params = {"q": Q, "limit": 100, "restrict_sr": 1}
    else:
        url = f"https://www.reddit.com/search.{suffixe}"
        params = {"q": Q, "limit": 100}
    for essai in range(4):
        r = requests.get(url, params=params, headers=UA, timeout=15)
        if r.status_code == 429 and essai < 3:
            pause = 5 * (essai + 1)
            print(f"429 : pause {pause} s puis nouvel essai")
            time.sleep(pause)
            continue
        break
    if r.status_code == 200:
        try:
            lignes = extraire_json(r) if suffixe == "json" else extraire_rss(r)
        except Exception:
            lignes = []
        if lignes:
            print(f"source : {url}")
            break
    print(f"{suffixe} : HTTP {r.status_code}")
if not lignes:
    sys.exit("reddit : aucun résultat récupéré")

slug = re.sub(r"[^a-z0-9]+", "-", (Q + ("-" + SUB if SUB else "")).lower()).strip("-")
dest = SORTIE / f"reddit-{slug}.csv"
with open(dest, "w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["date", "subreddit", "titre", "score", "nb_commentaires", "url"])
    w.writeheader()
    w.writerows(lignes)
print(f"{len(lignes)} posts -> {dest}")
