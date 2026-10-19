"""Avis App Store via le flux RSS JSON public (gratuit, sans clé), pages 1 à 10.
Usage : python3 avis_appstore.py <id> <pays> [<pays>...]
Écrit reports/marche/donnees/avis-<id>-<pays>.csv (UTF-8).
Le flux est parfois vide pour certains pays : le script le dit clairement."""
import csv
import pathlib
import sys
import time

import requests

ID = sys.argv[1]
PAYS_LISTE = sys.argv[2:]
SORTIE = pathlib.Path(__file__).resolve().parents[2] / "reports" / "marche" / "donnees"
SORTIE.mkdir(parents=True, exist_ok=True)
COLS = ["id_app", "pays", "date", "note", "titre", "texte", "version", "auteur"]

for pays in PAYS_LISTE:
    avis = []
    for page in range(1, 11):
        url = (f"https://itunes.apple.com/{pays}/rss/customerreviews"
               f"/page={page}/id={ID}/sortBy=mostRecent/json")
        try:
            r = requests.get(url, timeout=15)
            data = r.json()
        except Exception as e:
            print(f"{pays} page {page} : flux en erreur ({e}), arrêt")
            break
        entrees = data.get("feed", {}).get("entry", [])
        if page == 1 and entrees and "im:name" in entrees[0]:
            entrees = entrees[1:]
        if not entrees:
            break
        def lab(x):
            return x.get("label", "") if isinstance(x, dict) else (x or "")
        for e in entrees:
            if not isinstance(e, dict):
                continue
            avis.append({
                "id_app": ID, "pays": pays,
                "date": lab(e.get("updated")),
                "note": lab(e.get("im:rating")),
                "titre": lab(e.get("title")),
                "texte": lab(e.get("content")),
                "version": lab(e.get("im:version")),
                "auteur": lab(e.get("author", {}).get("name") if isinstance(e.get("author"), dict) else ""),
            })
        time.sleep(0.5)
    if not avis:
        print(f"{pays} : 0 avis (flux vide pour ce pays)")
        continue
    dest = SORTIE / f"avis-{ID}-{pays}.csv"
    with open(dest, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLS)
        w.writeheader()
        w.writerows(avis)
    print(f"{pays} : {len(avis)} avis -> {dest}")
