"""Avis et fiche Google Play via google-play-scraper (gratuit, sans clé).
Usage : python3 avis_play.py <package> <lang> <pays> [max=500]
Écrit reports/marche/donnees/avis-play-<package>-<pays>.csv
et reports/marche/donnees/fiche-play-<package>-<pays>.json."""
import csv
import json
import pathlib
import sys

from google_play_scraper import Sort, app, reviews

PKG, LANG, PAYS = sys.argv[1], sys.argv[2], sys.argv[3]
MAX = int(sys.argv[4]) if len(sys.argv) > 4 else 500
SORTIE = pathlib.Path(__file__).resolve().parents[2] / "reports" / "marche" / "donnees"
SORTIE.mkdir(parents=True, exist_ok=True)

f = app(PKG, lang=LANG, country=PAYS)
fiche = {"nom": f.get("title"), "editeur": f.get("developer"),
         "note_moyenne": f.get("score"), "nombre_avis": f.get("reviews"),
         "nombre_notes": f.get("ratings"), "installs": f.get("installs"),
         "date_maj": f.get("updated") and str(f.get("updated")),
         "gratuit": f.get("free"), "achats_integres": f.get("offersIAP"),
         "genre": f.get("genre"), "url": f.get("url"),
         "description_300": (f.get("description") or "")[:300]}
dest_fiche = SORTIE / f"fiche-play-{PKG}-{PAYS}.json"
dest_fiche.write_text(json.dumps(fiche, ensure_ascii=False, indent=2), encoding="utf-8")

res, _ = reviews(PKG, lang=LANG, country=PAYS, sort=Sort.NEWEST, count=MAX)
COLS = ["package", "pays", "date", "note", "texte", "version", "auteur", "pouce"]
dest = SORTIE / f"avis-play-{PKG}-{PAYS}.csv"
with open(dest, "w", encoding="utf-8", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=COLS)
    w.writeheader()
    for a in res:
        w.writerow({"package": PKG, "pays": PAYS,
                    "date": a["at"].isoformat(), "note": a["score"],
                    "texte": a["content"], "version": a.get("appVersion") or "",
                    "auteur": a.get("userName", ""), "pouce": a.get("thumbsUpCount", 0)})
print(f"{fiche['nom']} — note {fiche['note_moyenne']}, {fiche['nombre_avis']} avis, {fiche['installs']} installs")
print(f"{len(res)} avis -> {dest}")
print(f"fiche -> {dest_fiche}")
