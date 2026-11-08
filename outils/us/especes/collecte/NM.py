#!/usr/bin/env python3
"""NM : pages « Warm Water Species » et « Cold Water Species » du New Mexico Department of Game and Fish (NMDOW).
Chaque fait (espèce, éventuellement plan d'eau nommé) n'est écrit que si sa phrase d'ancrage se retrouve dans la page
téléchargée (faits et noms seulement). Usage : python3 -I NM.py [dossier de pages déjà téléchargées]"""
import re, html, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import esp8_commun as C

PAGES = [
    ("nm-warm.html", "https://wildlife.dgf.nm.gov/fishing/game-fish/warm-water/", "NMDOW, Warm Water Species"),
    ("nm-cold.html", "https://wildlife.dgf.nm.gov/fishing/game-fish/cold-water/", "NMDOW, Cold Water Species"),
]
ETAT = {"type": "etat", "id": "NM", "nom": "New Mexico"}


def eau(nom):
    return {"type": "plan_eau", "id": nom, "nom": nom}


def faits():
    f = []
    # niveau État
    for nom, ph in [("largemouth bass", "Largemouth Bass Greenish"), ("smallmouth bass", "Smallmouth Bass Uniform"),
                    ("spotted bass", "Spotted Bass Scales"), ("white bass", "White/Striped Bass"), ("striped bass", "White/Striped Bass"),
                    ("channel catfish", "the channel , flathead , and blue"), ("flathead catfish", "the channel , flathead , and blue"),
                    ("blue catfish", "the channel , flathead , and blue"), ("white crappie", "White Crappie Best fishing waters"),
                    ("yellow perch", "Yellow Perch Eagle Nest"), ("bluegill", "Bluegill: Elephant Butte"),
                    ("green sunfish", "Green Sunfish: Populations occur"), ("northern pike", "Northern Pike Large mouth"),
                    ("tiger muskie", "Tiger Muskie are a cross"), ("walleye", "Walleye Milky eye")]:
        f.append((0, nom, ETAT, ph))
    for nom, ph in [("brook trout", "Brook Trout Light wavy"), ("brown trout", "Brown Trout Abdomen"), ("lake trout", "Lake Trout Light to dark"),
                    ("rainbow trout", "Rainbow Trout Numerous"), ("rio grande cutthroat trout", "Rio Grande Cutthroat Trout Native"),
                    ("kokanee salmon", "Kokanee Salmon Female")]:
        f.append((1, nom, ETAT, ph))
    # plans d'eau nommés par l'agence
    for lac, ph in [("Elephant Butte Lake", "Elephant Butte, Ute, and Conchas are our best largemouth"), ("Ute Lake", "Elephant Butte, Ute, and Conchas are our best largemouth"),
                    ("Conchas Lake", "Elephant Butte, Ute, and Conchas are our best largemouth"), ("Clayton Lake", "Clayton, Bill Evans and Lake Roberts"),
                    ("Bill Evans Lake", "Clayton, Bill Evans and Lake Roberts"), ("Lake Roberts", "Clayton, Bill Evans and Lake Roberts")]:
        f.append((0, "largemouth bass", eau(lac), ph))
    for lac in ["Ute Lake", "Conchas Lake", "Navajo Lake", "Elephant Butte Lake", "Abiquiu Lake"]:
        f.append((0, "smallmouth bass", eau(lac), "Ute, Conchas, Navajo, Elephant Butte, and Abiquiu are our best smallmouth"))
    f.append((0, "smallmouth bass", eau("Gila River"), "portions of the Gila River"))
    for lac in ["Elephant Butte Lake", "Caballo Lake"]:
        f.append((0, "striped bass", eau(lac), "Best Waters Striped Bass: Elephant Butte and Caballo"))
    for lac in ["Elephant Butte Lake", "Caballo Lake", "Cochiti Lake", "Brantley Lake", "Sumner Lake", "Ute Lake"]:
        f.append((0, "white bass", eau(lac), "White Bass: Elephant Butte, Caballo, and the Rio Grande between the two reservoirs; Cochiti, Brantley, Sumner, and Ute"))
    f.append((0, "white bass", eau("Conchas Lake"), "white bass populations are highest at Conchas Lake and Ute Lake"))
    for lac in ["Elephant Butte Lake", "Caballo Lake"]:
        f.append((0, "blue catfish", eau(lac), "Blue catfish are only found in Elephant Butte and Caballo Reservoirs"))
    for lac in ["Elephant Butte Lake", "Conchas Lake", "Caballo Lake", "Ute Lake"]:
        f.append((0, "channel catfish", eau(lac), "Elephant Butte, Conchas, Caballo and Ute all have very good populations"))
    for lac in ["Conchas Lake", "Navajo Lake"]:
        f.append((0, "white crappie", eau(lac), "White Crappie Best fishing waters: Conchas and Navajo Lakes"))
    for lac in ["Ute Lake", "Cochiti Lake", "Caballo Lake", "Elephant Butte Lake"]:
        f.append((0, "white crappie", eau(lac), "Ute Lake, Cochiti Lake, Caballo Lake, and Elephant Butte Lake"))
    for lac in ["Eagle Nest Lake", "Lower Charette Lake", "Springer Lake", "Stubblefield Lake"]:
        f.append((0, "yellow perch", eau(lac), "Yellow Perch Eagle Nest, Lower Charette Lake, Springer Lake, Stubblefield Lake"))
    for lac in ["Elephant Butte Lake", "Sumner Lake", "Santa Rosa Lake", "Ute Lake", "Conchas Lake"]:
        f.append((0, "bluegill", eau(lac), "Bluegill: Elephant Butte Lake, Sumner Lake, Santa Rosa Lake, Ute Lake, Conchas Lake"))
    for riv in ["Canadian River", "Rio Grande", "Pecos River", "Gila River", "Black River"]:
        f.append((0, "green sunfish", eau(riv), "portions of the Canadian River and Rio Grande, as well as the Pecos, Gila, and Black Rivers"))
    for lac in ["Quemado Lake", "Bluewater Lake"]:
        f.append((0, "tiger muskie", eau(lac), "Quemado Lake supports a healthy population of tiger muskie" if lac == "Quemado Lake" else "Bluewater Lake currently supports a high-density population of tiger muskie"))
    for lac in ["Ute Lake", "Conchas Lake"]:
        f.append((0, "walleye", eau(lac), "mostly from Ute and Conchas reservoirs"))
    for riv in ["Cabresto Creek", "Tecolote Creek"]:
        f.append((1, "brook trout", eau(riv), "Cabresto Creek above Questa and Tecolote Creek near Las Vegas"))
    for riv in ["Rio Grande Gorge", "Rio Guadalupe", "Cimarron River"]:
        f.append((1, "brown trout", eau(riv), "The Rio Grande Gorge supports a thriving population of brown trout" if riv == "Rio Grande Gorge" else "Other streams include the Rio Guadalupe in the Jemez and the Cimarron River below Eagle Nest Dam"))
    f.append((1, "lake trout", eau("Heron Lake"), "lake trout were introduced at Heron Lake"))
    for riv in ["Tingley Beach", "Red River", "San Juan River", "Cimarron River"]:
        f.append((1, "rainbow trout", eau(riv), "Tingley Beach are stocked weekly" if riv == "Tingley Beach" else "Red River, San Juan River and Cimarron River should provide good opportunities for rainbow trout"))
    for lac in ["Heron Lake", "Eagle Nest Lake", "Navajo Lake"]:
        f.append((1, "kokanee salmon", eau(lac), {"Heron Lake": "Low reservoir levels are anticipated at Heron Lake", "Eagle Nest Lake": "Eagle Nest Lake also is stocked every year with kokanee", "Navajo Lake": "Navajo Lake may provide a more favorable alternative for trolling"}[lac]))
    return f


def texte(page):
    s = re.sub(r"<script.*?</script>|<style.*?</style>", " ", page, flags=re.S)
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", s)).replace("’", "'"))


def construire(pages):
    textes = [texte(p).lower() for p in pages]
    entrees, manquants = [], []
    for i, nom, zone, phrase in faits():
        if phrase.lower() not in textes[i]:
            manquants.append((nom, zone["nom"], phrase))
            continue
        e = C.entree(nom, zone, "liste_agence", i)
        if e and e not in entrees:
            entrees.append(e)
    # Gila trout (espèce native) : fiche de l'agence
    if "gila trout" in textes[1]:
        entrees.append({"slug": None, "nom": "Gila trout", "latin": "Oncorhynchus gilae", "zone": ETAT, "preuve": "liste_agence", "src": 1, "confiance": "officielle"})
    return entrees, manquants


def main(dossier=None):
    dossier = dossier or C.BRUT
    pages = []
    for f, url, _ in PAGES:
        chemin = os.path.join(dossier, f)
        pages.append(open(chemin, encoding="utf-8", errors="replace").read() if os.path.exists(chemin) else C.telecharger(url))
    entrees, manquants = construire(pages)
    sources = [C.src(n, u) for _, u, n in PAGES]
    chemin, taille = C.ecrire("NM", "agence", sources, entrees)
    print(chemin, taille, len(entrees), "entrées ; phrases d'ancrage absentes :", manquants)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
