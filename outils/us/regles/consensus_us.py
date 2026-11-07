"""Compare deux lectures indépendantes des règles d'un État américain et ne garde que celles où elles s'accordent.

Usage : python3 -I consensus_us.py <ETAT> [--json]      (lit lecture-a/<ETAT>.json et lecture-b/<ETAT>.json)
        python3 -I consensus_us.py --fichiers A.json B.json [--json]

Même principe que outils/regles/consensus.py (France) : on compare le fond, pas la rédaction. Une règle de A est
confirmée si une règle de B a même type, même espèce, mêmes dates (années ignorées : 12-01 au 03-15 est la même plage
qu'elle soit écrite 2025-12-01 au 2026-03-15), mêmes nombres après conversion en pouces et en livres (38 cm = 15 pouces),
même code (engin, appât…), et même portée. La portée est un identifiant normalisé : minuscules sans accents, « St. » = Saint,
sans « Lake », « River », « Creek »…, mais un lac et une rivière ne se confondent pas.
La règle confirmée doit être au moins aussi fine que celle qui la confirme (plan d'eau dans État) ; une règle fine n'est
confirmée par une règle d'État que si la valeur est chiffrée ou datée.
Une règle « incertain » d'un côté reste incertaine. Tout le reste devient « a_verifier » (jamais « permis »).
Sort 0 si les fichiers sont lisibles et valides, 1 sinon.
"""
import importlib.util
import json
import os
import re
import sys
import unicodedata

ICI = os.environ.get("REGLES_US_DIR") or os.path.dirname(os.path.abspath(__file__))
NIVEAUX = ["etat", "zone", "plan_eau", "troncon"]

ESPECES = [  # mots-clés (tous présents) vers nom canonique, du plus précis au plus général
    (("largemouth",), "largemouth bass"), (("large", "mouth"), "largemouth bass"), (("bigmouth",), "largemouth bass"),
    (("smallmouth",), "smallmouth bass"), (("small", "mouth"), "smallmouth bass"), (("spotted", "bass"), "spotted bass"),
    (("black", "bass"), "black bass"), (("striped", "bass"), "striped bass"), (("hybrid", "striped"), "hybrid striped bass"),
    (("white", "bass"), "white bass"), (("walleye",), "walleye"), (("sauger",), "sauger"),
    (("northern", "pike"), "northern pike"), (("pike",), "northern pike"), (("muskellunge",), "muskellunge"),
    (("muskie",), "muskellunge"), (("pickerel",), "chain pickerel"),
    (("rainbow", "trout"), "rainbow trout"), (("steelhead",), "steelhead"), (("brown", "trout"), "brown trout"),
    (("brook", "trout"), "brook trout"), (("lake", "trout"), "lake trout"), (("cutthroat",), "cutthroat trout"),
    (("trout",), "trout"), (("chinook",), "chinook salmon"), (("coho",), "coho salmon"), (("salmon",), "salmon"),
    (("channel", "catfish"), "channel catfish"), (("blue", "catfish"), "blue catfish"),
    (("flathead",), "flathead catfish"), (("catfish",), "catfish"), (("bluegill",), "bluegill"),
    (("black", "crappie"), "black crappie"), (("white", "crappie"), "white crappie"), (("crappie",), "crappie"),
    (("yellow", "perch"), "yellow perch"), (("sunfish",), "sunfish"), (("panfish",), "panfish"),
    (("carp",), "common carp"), (("bowfin",), "bowfin"), (("sturgeon",), "sturgeon"), (("paddlefish",), "paddlefish"),
]
NOMS_EAU_VIDES = {"of", "the", "de", "la", "le", "and", "at", "near", "lake", "lakes", "lac", "river", "riviere", "creek",
                  "cr", "pond", "reservoir", "res", "flowage", "impoundment", "stream", "brook", "run", "bayou", "county", "co"}
STATIQUE = {"lake", "lakes", "lac", "pond", "reservoir", "res", "flowage", "impoundment"}
COURANT = {"river", "riviere", "creek", "cr", "stream", "brook", "run", "bayou"}
ABREVIATIONS = {"st": "saint", "ste": "sainte", "mt": "mount", "mtn": "mountain", "ft": "fort", "lk": "lake",
                "rv": "river", "rsvr": "reservoir", "cr": "creek", "n": "north", "s": "south", "e": "east", "w": "west"}
NOMBRES_UNITES = {  # clé de valeur -> (clé canonique, facteur)
    "pouces": ("taille", 1.0), "cm": ("taille", 1 / 2.54), "mm": ("taille", 1 / 25.4),
    "pouces_min": ("taille_min", 1.0), "cm_min": ("taille_min", 1 / 2.54),
    "pouces_max": ("taille_max", 1.0), "cm_max": ("taille_max", 1 / 2.54),
    "livres": ("poids", 1.0), "kg": ("poids", 2.20462),
    "nombre": ("nombre", 1.0), "lignes_max": ("lignes_max", 1.0), "hamecons_max": ("hamecons_max", 1.0)}
TEXTUELS = ("mode", "code")  # comparés quand les deux lectures les donnent


def norm(texte):
    texte = unicodedata.normalize("NFKD", texte or "").encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", " ", texte).strip()


def espece(nom):
    mots = norm(re.sub(r"\(.*?\)", " ", str(nom))) or norm(nom)
    jetons = {m[:-1] if m.endswith("s") and len(m) > 3 else m for m in mots.split()}
    for cles, canon in ESPECES:
        if all(c in jetons for c in cles):
            return canon
    return mots


def especes(regle):
    return {espece(e) for e in regle.get("especes") or []} or {"*"}


# ---- Nombres et dates -------------------------------------------------------------------------------------------

def nombres(valeur):
    """{clé canonique: nombre}, taille en pouces, poids en livres, arrondis à 0,1."""
    sortie = {}
    for cle, (canon, facteur) in NOMBRES_UNITES.items():
        v = (valeur or {}).get(cle)
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            sortie[canon] = round(v * facteur, 1)
    return sortie


def memes_nombres(na, nb):
    return na.keys() == nb.keys() and all(abs(na[k] - nb[k]) <= 0.15 for k in na)


def md(date):
    """'2025-12-01' ou '12-01' -> '12-01' ; None si absent."""
    if not date:
        return None
    return str(date)[-5:]


def dates(regle):
    du, au = md(regle.get("du")), md(regle.get("au"))
    if (du, au) == ("01-01", "12-31"):
        return (None, None)
    return (du, au)


def a_cheval(regle):
    du, au = dates(regle)
    return bool(du and au and du > au)


# ---- La portée : un identifiant, pas une phrase ----------------------------------------------------------------

def mots_eau(texte):
    jetons = [ABREVIATIONS.get(m, m) for m in norm(texte).split()]
    return frozenset(m for m in jetons if m not in NOMS_EAU_VIDES and len(m) > 0)


def genre_eau(texte):
    """'statique', 'courant' ou None selon les mots écrits (Lake X, X River)."""
    jetons = set(norm(texte).split())
    if jetons & STATIQUE and not jetons & COURANT:
        return "statique"
    if jetons & COURANT and not jetons & STATIQUE:
        return "courant"
    return None


def portee(regle):
    p = regle.get("portee") or {}
    zone, eau, tron = (mots_eau(p.get(k) or "") for k in ("zone", "plan_eau", "troncon"))
    niveau = 3 if tron else 2 if eau else 1 if zone else 0
    return {"etat": p.get("etat"), "niveau": niveau, "zone": zone, "eau": eau, "tronc": tron,
            "genre": genre_eau(p.get("plan_eau") or ""), "comte": mots_eau(p.get("comte") or "")}


def portee_dans(a, b):
    """La portée de a est-elle celle de b ou comprise dedans ? Chaque champ nommé par b doit être le même chez a."""
    pa, pb = portee(a), portee(b)
    if pa["etat"] and pb["etat"] and pa["etat"] != pb["etat"]:
        return False
    if pa["niveau"] < pb["niveau"]:
        return False
    for champ in ("zone", "eau"):
        if pb[champ] and pa[champ] != pb[champ]:
            return False
    if pb["eau"] and pa["genre"] and pb["genre"] and pa["genre"] != pb["genre"]:
        return False
    if pa["comte"] and pb["comte"] and pa["comte"] != pb["comte"]:
        return False
    if pb["tronc"]:
        if not pa["tronc"]:
            return False
        inter = pa["tronc"] & pb["tronc"]
        return len(inter) / len(pa["tronc"] | pb["tronc"]) >= 0.6
    return True


# ---- Comparaison ------------------------------------------------------------------------------------------------

def confirme(a, b):
    """Vrai si chaque fait de a se retrouve dans b ; a peut être plus fine que b."""
    if a.get("type") != b.get("type"):
        return False
    ea, eb = especes(a), especes(b)
    if not ea <= eb:
        return False
    if dates(a) != dates(b):
        return False
    va, vb = a.get("valeur") or {}, b.get("valeur") or {}
    if not memes_nombres(nombres(va), nombres(vb)):
        return False
    for cle in TEXTUELS:
        if va.get(cle) is not None and vb.get(cle) is not None and norm(str(va[cle])) != norm(str(vb[cle])):
            return False
    if not portee_dans(a, b):
        return False
    if portee(a)["niveau"] > portee(b)["niveau"]:
        # Règle fine contre règle plus large : seulement si la valeur est chiffrée ou datée, jamais sur du texte seul.
        return bool(nombres(va) or dates(a) != (None, None))
    return True


def proximite(a, b):
    pa, pb = portee(a), portee(b)
    ma = pa["zone"] | pa["eau"] | pa["tronc"]
    mb = pb["zone"] | pb["eau"] | pb["tronc"]
    return len(ma & mb) / len(ma | mb) if ma | mb else 1.0


def a_verifier(regle, raison):
    return dict(regle, verdict="a_verifier", raison_a_verifier=raison)


def comparer(la, lb):
    """(confirmées, seules_a, seules_b) ; les deux dernières portent verdict « a_verifier »."""
    gardees, seules_a = [], []
    for a in la:
        candidats = [b for b in lb if confirme(a, b)]
        if not candidats:
            seules_a.append(a_verifier(a, "la lecture B ne donne pas cette règle"))
            continue
        b = max(candidats, key=lambda b: proximite(a, b))
        statut = "brouillon" if a.get("statut") == b.get("statut") == "brouillon" else "incertain"
        regle = dict(a, statut=statut, lecture_b={"id": b.get("id"), "source": b.get("source"), "citation": b.get("citation")})
        gardees.append(regle)
    seules_b = [a_verifier(b, "la lecture A ne donne pas cette règle") for b in lb if not any(confirme(b, a) for a in la)]
    return gardees, seules_a, seules_b


def chargeur_verifier():
    spec = importlib.util.spec_from_file_location("verifier_us", os.path.join(os.path.dirname(os.path.abspath(__file__)), "verifier_us.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def lire(chemin):
    with open(chemin, encoding="utf-8") as f:
        return json.load(f)


def main(argv):
    if len(argv) < 1:
        print(__doc__)
        return 1
    if argv[0] == "--fichiers":
        if len(argv) < 3:
            print(__doc__)
            return 1
        chemin_a, chemin_b, etat = argv[1], argv[2], None
    else:
        etat = argv[0]
        chemin_a, chemin_b = (os.path.join(ICI, d, f"{etat}.json") for d in ("lecture-a", "lecture-b"))
    try:
        da, db = lire(chemin_a), lire(chemin_b)
    except (OSError, json.JSONDecodeError) as e:
        print(f"lecture impossible ({e})")
        return 1
    verif = chargeur_verifier()
    defauts = [f"A : {d}" for d in verif.defauts(da)] + [f"B : {d}" for d in verif.defauts(db)]
    if da.get("lecteur") == db.get("lecteur"):
        defauts.append("les deux fichiers portent le même lecteur : deux lectures indépendantes sont exigées")
    if da.get("etat") != db.get("etat"):
        defauts.append("les deux lectures ne sont pas du même État")
    if defauts:
        for d in defauts[:40]:
            print(d)
        print(f"{len(defauts)} défauts : aucune règle chargée")
        return 1
    gardees, seules_a, seules_b = comparer(da["regles"], db["regles"])
    etat = etat or da.get("etat")
    sures = sum(1 for r in gardees if r["statut"] == "brouillon")
    print(f"{etat} : A {len(da['regles'])} règles, B {len(db['regles'])} ; confirmées par les deux {len(gardees)} "
          f"(dont {sures} sans réserve, les autres incertaines) ; à vérifier : seulement A {len(seules_a)}, seulement B {len(seules_b)}")
    if "--json" in argv:
        dossier = os.path.join(ICI, "consensus")
        os.makedirs(dossier, exist_ok=True)
        with open(os.path.join(dossier, f"{etat}.json"), "w", encoding="utf-8") as f:
            json.dump({"etat": etat, "fixture": bool(da.get("fixture") or db.get("fixture")),
                       "regles": [r for r in gardees if r["statut"] == "brouillon"],
                       "incertaines": [r for r in gardees if r["statut"] != "brouillon"],
                       "a_verifier": {"seulement_a": seules_a, "seulement_b": seules_b}},
                      f, ensure_ascii=False, indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
