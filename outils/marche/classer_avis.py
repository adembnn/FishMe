"""Classe les avis d'un CSV (App Store ou Play, colonnes date/note/texte/titre)
dans des thèmes par mots-clés (fr, en, de, nl, es, it).
Usage : python3 classer_avis.py <csv>
Écrit <csv>-themes.csv avec la colonne « themes » et affiche un tableau
thèmes × nombre, séparé par note basse (1-2) et haute (4-5).
Attention : tri grossier pour orienter la lecture des rapports,
pas une mesure fiable — les mots-clés ratent le sarcasme et les contextes."""
import csv
import pathlib
import re
import sys
import unicodedata

THEMES = {
    "bug": ["bug", "crash", "freeze", "plante", "bloqu", "ne marche", "doesn t work",
            "not working", "error", "erreur", "fehler", "stürzt", "absturz", "werkt niet",
            "no funciona", "non funziona", "lent", "slow", "lag"],
    "prix_abonnement": ["abonnement", "subscription", "prix", "price", "cher", "expensive",
                        "payant", "pay", "gratuit", "free", "rembours", "refund", "abo",
                        "teuer", "kosten", "gratis", "precio", "prezzo", "euro", "$", "€"],
    "demande_fonction": ["serait bien", "il manque", "j aimerais", "would be nice",
                         "wish", "feature", "fonction", "ajouter", "add", "suggestion",
                         "manque", "missing", "wünsche", "funzione", "función", "mis"],
    "regles_legales": ["règle", "regulation", "loi", "law", "légal", "legal", "arrêté",
                       "permit", "licence", "permis", "verboten", "regel", "vorschrift",
                       "wetten", "ley", "norma", "regolamento", "taille", "size limit"],
    "spots_lieux": ["spot", "lieu", "endroit", "carte", "map", "lac", "rivière", "river",
                    "lake", "location", "see", "fluss", "plek", "lugar", "posto",
                    "coin", "place", "water", "étang", "pond"],
    "social_communaute": ["ami", "friend", "communaut", "community", "partage", "share",
                          "social", "groupe", "group", "club", "ensemble", "together",
                          "freunde", "amici", "amigos", "vrienden"],
    "donnees_fausses": ["faux", "wrong", "incorrect", "inexact", "pas à jour", "outdated",
                        "obsolete", "fausse", "erreur de", "veraltet", "falsch", "fout",
                        "incorrecto", "sbagliat", "bad data", "donnée"],
    "reconnaissance_espece": ["reconnaiss", "identif", "espèce", "species", "poisson",
                              "fish id", "identific", "erkenn", "art erken", "specie",
                              "especie", "scan", "photo du poisson", "identifier"],
    "meteo_conditions": ["météo", "weather", "meteo", "wetter", "température", "vent",
                         "wind", "pluie", "rain", "regen", "lluvia", "pioggia", "weer",
                         "niveau d eau", "water level", "crue", "flood", "pression"],
    "compliment": ["super", "génial", "great", "awesome", "parfait", "perfect",
                   "excellent", "love", "adore", "top", "bravo", "merci", "best",
                   "toll", "super app", "genial", "geweldig", "excelente", "ottima"],
}

def norm(t):
    t = unicodedata.normalize("NFKD", t.lower())
    return " ".join(re.findall(r"[a-zà-ÿ0-9'€$]+", t))

SRC = pathlib.Path(sys.argv[1])
with open(SRC, encoding="utf-8", newline="") as f:
    r = csv.DictReader(f)
    cols, lignes = r.fieldnames, list(r)

stats = {t: {"bas": 0, "haut": 0, "autre": 0} for t in THEMES}
sans_theme = 0
for l in lignes:
    blob = norm((l.get("titre") or "") + " " + (l.get("texte") or ""))
    trouves = [t for t, mots in THEMES.items() if any(m in blob for m in mots)]
    l["themes"] = ";".join(trouves)
    try:
        note = int(float(l.get("note") or 0))
    except ValueError:
        note = 0
    cat = "bas" if 1 <= note <= 2 else "haut" if note >= 4 else "autre"
    if not trouves:
        sans_theme += 1
    for t in trouves:
        stats[t][cat] += 1

dest = SRC.with_name(SRC.name + "-themes.csv")
with open(dest, "w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=cols + ["themes"])
    w.writeheader()
    w.writerows(lignes)

print(f"{len(lignes)} avis, {sans_theme} sans thème trouvé -> {dest}")
print(f"{'thème':24s} {'1-2★':>5s} {'4-5★':>5s} {'3★/?':>5s}")
for t, s in sorted(stats.items(), key=lambda x: -sum(x[1].values())):
    print(f"{t:24s} {s['bas']:5d} {s['haut']:5d} {s['autre']:5d}")
