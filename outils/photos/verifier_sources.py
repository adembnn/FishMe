"""Vérifie un tableau de sources de photos (reports/photos/groupe-N.csv).
Usage : python3 outils/photos/verifier_sources.py N
Échoue (code 1) si une espèce du groupe manque, si une colonne manque,
si une licence n'est pas dans la liste, ou si un compte n'est pas un entier."""
import csv, sys, pathlib
N = sys.argv[1]
base = pathlib.Path(__file__).resolve().parents[2] / "reports" / "photos"
especes = [l.strip() for l in (base / f"groupe-{N}.txt").read_text(encoding="utf-8").splitlines() if l.strip()]
cols = ["espece_id", "source", "licence", "nb_photos", "requete_url", "note"]
licences = {"cc0", "cc-by", "cc-by-sa", "cc-by-nc", "cc-by-nc-sa", "domaine-public", "non-libre", "toutes"}
erreurs, vus, total = [], {}, {}
with open(base / f"groupe-{N}.csv", encoding="utf-8", newline="") as f:
    r = csv.DictReader(f)
    if r.fieldnames != cols:
        sys.exit(f"colonnes attendues {cols}, trouvées {r.fieldnames}")
    for n, row in enumerate(r, 2):
        e = row["espece_id"]
        if e not in especes: erreurs.append(f"ligne {n} : espèce inconnue {e}")
        if row["licence"] not in licences: erreurs.append(f"ligne {n} : licence invalide {row['licence']}")
        if not row["nb_photos"].isdigit(): erreurs.append(f"ligne {n} : nb_photos non entier")
        elif row["licence"] != "toutes":
            total[e] = total.get(e, 0) + int(row["nb_photos"])
        if not row["requete_url"].startswith("http"): erreurs.append(f"ligne {n} : requete_url absente")
        vus[e] = vus.get(e, 0) + 1
for e in especes:
    if e not in vus: erreurs.append(f"espèce sans ligne : {e}")
if erreurs:
    print("\n".join(erreurs)); sys.exit(1)
faibles = [e for e in especes if total.get(e, 0) < 100]
print(f"groupe {N} : {len(especes)} espèces couvertes, 0 erreur")
print(f"moins de 100 photos mesurées : {len(faibles)} -> {', '.join(faibles) or 'aucune'}")
