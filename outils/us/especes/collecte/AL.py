"""AL : Outdoor Alabama (ADCNR, Wildlife and Freshwater Fisheries).
Niveau État : pages d'espèces « game fish » et « commercial or non-game fish ». Niveau plan d'eau : fiches des 20 State Public Fishing Lakes
(rubrique « Fish Species » = espèces empoissonnées). Usage : python3 -I AL.py [dossier_brut]  (sinon téléchargement, pause 0,3 s)."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun

BASE = "https://www.outdooralabama.com"
GAME = ["black-bass/largemouth-bass", "black-bass/redeye-bass", "black-bass/shoal-bass", "black-bass/smallmouth-bass", "black-bass/spotted-bass",
        "bream/banded-sunfish", "bream/bluegill", "bream/bluespotted-sunfish", "bream/dollar-sunfish", "bream/flier", "bream/green-sunfish",
        "bream/longear-sunfish", "bream/mud-sunfish", "bream/orangespotted-sunfish", "bream/redbreast-sunfish", "bream/redear-sunfish",
        "bream/redspotted-sunfish", "bream/rock-bass", "bream/shadow-bass", "bream/warmouth", "crappie/black-crappie", "crappie/white-crappie",
        "temperate-bass/hybrid-striped-bass", "temperate-bass/striped-bass", "temperate-bass/white-bass", "temperate-bass/yellow-bass",
        "perch/sauger", "perch/walleye", "perch/yellow-perch", "pickerel/chain-pickerel", "pickerel/redfin-pickerel", "game-fish/rainbow-trout"]
NONGAME = ["catfish/blue-catfish", "catfish/channel-catfish", "catfish/flathead-catfish", "catfish/white-catfish",
           "bullhead-catfish/black-bullhead", "bullhead-catfish/brown-bullhead", "bullhead-catfish/snail-bullhead",
           "bullhead-catfish/spotted-bullhead", "bullhead-catfish/yellow-bullhead", "gar/alligator-gar", "gar/longnose-gar", "gar/spotted-gar",
           "drum/freshwater-drum", "buffalo/bigmouth-buffalo", "buffalo/black-buffalo", "buffalo/smallmouth-buffalo", "carp/common-carp",
           "carp/grass-carp", "non-game-fish/bowfin", "non-game-fish/paddlefish"]
LACS = ["barbour", "bibb", "chambers", "clay", "coffee", "crenshaw", "dale", "dallas", "dekalb", "escambia", "fayette", "geneva", "lamar", "lee",
        "madison", "marion", "monroe", "pike", "walker", "washington"]
commun.LATIN.update({"crappie": "Pomoxis spp.", "hybrid striped bass": "Morone chrysops x Morone saxatilis"})
SRC_ETAT = [("Outdoor Alabama, Game Fish", BASE + "/freshwater-fishing/game-fish"),
            ("Outdoor Alabama, Commercial or Non-Game Fish", BASE + "/freshwater-fishing/commercial-or-non-game-fish")]


def titre(html):
    m = re.search(r"<title>(.*?)</title>", html, re.S)
    return commun.texte(m.group(1)).split("|")[0].strip() if m else ""


def especes_lac(html):
    t = commun.texte(html)
    m = re.search(r"Fish Species (.*?) (?:Facilities|Note:)", t)
    if not m:
        return []
    liste = re.sub(r"\(winter only\)|\bhybrid striped bass\b", lambda x: "hybrid striped bass" if x.group(0).startswith("hybrid") else "", m.group(1), flags=re.I)
    liste = re.sub(r"[,.]|\band\b", " ", liste)
    return commun.noms_connus(liste)


def lire(brut, chemin):
    f = os.path.join(brut, chemin.replace("/", "_") + ".html") if brut else None
    if f and os.path.exists(f):
        return open(f, encoding="utf-8", errors="replace").read()
    return commun.telecharger(f"{BASE}/{chemin}")


def construire(brut=None):
    sl = commun.slugs_par_latin()
    sources = [{"nom": n, "url": u, "licence": "non précisée", "date": commun.DATE} for n, u in SRC_ETAT]
    entrees, vus = [], set()
    for src, liste in ((0, GAME), (1, NONGAME)):
        for ch in liste:
            nom = titre(lire(brut, ch)) or ch.split("/")[1].replace("-", " ").title()
            lat = commun.latin_de(nom)
            if lat is None:
                raise SystemExit(f"nom scientifique inconnu : {nom}")
            if lat in vus:
                continue
            vus.add(lat)
            entrees.append(commun.entree(nom, lat, {"type": "etat", "id": "AL", "nom": "Alabama"}, "liste_agence", src, slugs=sl))
    n_etat = len(entrees)
    for c in LACS:
        ch = f"public-fishing-lakes/{c}-county-pfl"
        nom_lac = f"{c.title().replace('Dekalb', 'DeKalb')} County State Public Fishing Lake"
        sources.append({"nom": f"Outdoor Alabama, {nom_lac}", "url": f"{BASE}/{ch}", "licence": "non précisée", "date": commun.DATE})
        deja = set()
        for n in especes_lac(lire(brut, ch)):
            lat = commun.latin_de(n)
            if lat in deja:
                continue
            deja.add(lat)
            entrees.append(commun.entree(n.capitalize(), lat, {"type": "plan_eau", "id": nom_lac, "nom": nom_lac}, "empoissonnement", len(sources) - 1, slugs=sl))
    return sources, entrees, n_etat


def main(brut=None):
    sources, entrees, n_etat = construire(brut)
    print("AL état", n_etat, "plan d'eau", len(entrees) - n_etat, commun.ecrire("AL", "agence", sources, entrees))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
