"""Fiche App Store via l'API iTunes lookup (gratuite, sans clé).
Usage : python3 fiche_appstore.py <id> <pays>   (ex. 6739852593 fr)
Écrit reports/marche/donnees/fiche-<id>-<pays>.json et affiche un résumé."""
import json
import pathlib
import sys

import requests

ID, PAYS = sys.argv[1], sys.argv[2]
SORTIE = pathlib.Path(__file__).resolve().parents[2] / "reports" / "marche" / "donnees"
SORTIE.mkdir(parents=True, exist_ok=True)

r = requests.get("https://itunes.apple.com/lookup",
                 params={"id": ID, "country": PAYS}, timeout=15)
r.raise_for_status()
res = r.json().get("results", [])
if not res:
    sys.exit(f"aucune app pour id={ID} pays={PAYS}")
a = res[0]

fiche = {
    "nom": a.get("trackName"),
    "editeur": a.get("sellerName"),
    "note_moyenne": a.get("averageUserRating"),
    "nombre_notes": a.get("userRatingCount"),
    "prix": a.get("formattedPrice"),
    "achats_integres": a.get("inAppPurchases") or a.get("features", []),
    "date_version_courante": a.get("currentVersionReleaseDate"),
    "date_premiere_sortie": a.get("releaseDate"),
    "genres": a.get("genres"),
    "taille_octets": int(a.get("fileSizeBytes", 0)),
    "langues": a.get("languageCodesISO2A"),
    "description_300": (a.get("description") or "")[:300],
    "version": a.get("version"),
    "url": a.get("trackViewUrl"),
    "contenu_advisory": a.get("contentAdvisoryRating"),
}
dest = SORTIE / f"fiche-{ID}-{PAYS}.json"
dest.write_text(json.dumps(fiche, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"{fiche['nom']} ({fiche['editeur']}) — note {fiche['note_moyenne']} sur {fiche['nombre_notes']} notes")
print(f"prix {fiche['prix']}, version {fiche['version']}, {len(fiche['langues'] or [])} langues")
print(f"-> {dest}")
