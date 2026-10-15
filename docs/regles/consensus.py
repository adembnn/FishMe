"""Compare deux lectures indépendantes des règles d'un département et garde celles où elles s'accordent.

Usage : python3 consensus.py <code>            (lit dep/<code>.json et dep-b/<code>.json)
        python3 consensus.py <code> --json     (écrit consensus/<code>.json)
        python3 consensus.py --tous            (une ligne par département qui a ses deux lectures)

On compare le fond, pas la rédaction : deux lecteurs peuvent citer deux textes différents (arrêté et avis),
regrouper ou séparer les espèces, écrire un code Sandre ou un nom. Chaque règle est découpée en faits
(type, espèce, dates, nombres écrits comme nombres, lieu). Une règle de A est confirmée si chacun de ses faits existe dans
une règle de B : même type, même espèce, mêmes dates de début et de fin, mêmes nombres (tailles, quotas ; pas
ceux des phrases ; pour une réserve, un parcours ou une catégorie, seul le lieu compte), même cours d'eau ou plan d'eau (ce qui précède la première parenthèse ou virgule)
et lieux proches (au moins 60 % des mots du plus court, deux mots dès que possible) ou absents des deux côtés, et même catégorie
quand aucun lieu n'est nommé. Les citations ne sont pas comparées : chacune doit être exacte dans son texte.
Une règle « incertain » d'un côté reste incertaine. Une règle non confirmée devient « vérifie l'arrêté ».
Sort 0 si les fichiers sont lisibles, 1 sinon.
"""
import json
import os
import re
import sys
import unicodedata

ICI = os.path.dirname(os.path.abspath(__file__))

CODES = {"2151": "brochet", "2195": "sandre", "2193": "perche", "2053": "black-bass", "2238": "silure",
         "2221": "truite-fario", "2216": "truite-arc-en-ciel", "2110": "carpe", "2133": "gardon", "2086": "breme",
         "31041": "chevesne", "2137": "tanche", "2096": "barbeau", "2247": "ombre"}

# Mots-clés vers espèce, du plus précis au plus général : le premier qui colle gagne.
NOMS = [
    (("civelle",), "anguille-civelle"), (("anguille", "argent"), "anguille-argentee"),
    (("anguille", "jaune"), "anguille-jaune"), (("anguille",), "anguille"),
    (("ecrevisse", "rouge"), "ecrevisse-pattes-rouges"), (("ecrevisse", "torrent"), "ecrevisse-torrents"),
    (("ecrevisse", "blanche"), "ecrevisse-pattes-blanches"), (("ecrevisse", "grele"), "ecrevisse-pattes-greles"),
    (("ecrevisse", "californie"), "ecrevisse-californie"), (("ecrevisse", "louisiane"), "ecrevisse-louisiane"),
    (("ecrevisse", "americaine"), "ecrevisse-americaine"), (("ecrevisse",), "ecrevisse"),
    (("grenouille", "verte"), "grenouille-verte"), (("grenouille", "rousse"), "grenouille-rousse"),
    (("grenouille",), "grenouilles-autres"),
    (("arc", "ciel"), "truite-arc-en-ciel"), (("truite", "mer"), "truite-de-mer"), (("truite", "lac"), "truite-de-lac"),
    (("fario",), "truite-fario"), (("omble", "fontaine"), "omble-fontaine"), (("saumon", "fontaine"), "omble-fontaine"),
    (("omble", "chevalier"), "omble-chevalier"), (("cristivomer",), "cristivomer"), (("salmonide",), "salmonides"),
    (("saumon",), "saumon-atlantique"), (("truite",), "truite"), (("ombre",), "ombre"), (("huchon",), "huchon"),
    (("coregone",), "coregone"), (("feinte",), "alose-feinte"), (("alose",), "grande-alose"),
    (("lamproie", "marine"), "lamproie-marine"), (("lamproie", "fluviatile"), "lamproie-fluviatile"),
    (("lamproie",), "lamproie"), (("mulet",), "mulet"), (("friture",), "fritures"),
    (("soleil",), "perche-soleil"), (("poisson", "chat"), "poisson-chat"), (("ablette",), "ablette"),
    (("rotengle",), "rotengle"), (("vandoise",), "vandoise"), (("hotu",), "hotu"), (("lote",), "lote"),
    (("carassin",), "carassin"), (("aspe",), "aspe"),
    (("black",), "black-bass"), (("sandre",), "sandre"), (("brochet",), "brochet"), (("perche",), "perche"),
    (("silure",), "silure"), (("carpe",), "carpe"), (("gardon",), "gardon"), (("breme",), "breme"),
    (("tanche",), "tanche"), (("chevesne",), "chevesne"), (("barbeau",), "barbeau"), (("goujon",), "goujon"),
]

MOTS_VIDES = {"de", "du", "des", "la", "le", "les", "l", "d", "a", "au", "aux", "et", "en", "sur", "commune",
              "pont", "plan", "eau", "lac", "riviere", "ruisseau", "amont", "aval", "depuis", "jusqu", "entre",
              "partie", "situee", "rive", "droite", "gauche", "pecheurs", "loisir", "lieu", "dit"}
TYPES_LIEU = {"reserve", "carpe_nuit", "no_kill", "categorie"}


def norm(texte):
    texte = unicodedata.normalize("NFKD", texte or "").encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", " ", texte).strip()


def espece(nom):
    nom = str(nom).strip()
    if nom in CODES:
        return CODES[nom]
    mots = norm(re.sub(r"\(.*?\)", " ", nom)) or norm(nom)
    for cles, canon in NOMS:
        if all(c in mots for c in cles):
            return canon
    return mots


def especes(regle):
    return {espece(e) for e in regle.get("especes") or []} or {"*"}


def nombres(valeur):
    """Les nombres écrits comme nombres (tailles, quotas, cannes), pas ceux des phrases ni des dates."""
    if isinstance(valeur, dict) and valeur.get("fenetre_cm"):
        valeur = valeur["fenetre_cm"]
    trouves = set()

    def parcourir(v, cle=""):
        if isinstance(v, bool) or cle in ("note", "formule", "regle", "periode_regle", "periodes", "raison_incertain"):
            return
        if isinstance(v, (int, float)):
            trouves.add(float(v))
        elif isinstance(v, dict):
            for k, w in v.items():
                parcourir(w, k)
        elif isinstance(v, list):
            for w in v:
                parcourir(w, cle)
    parcourir(valeur)
    return trouves


def dates(regle):
    du, au = regle.get("du"), regle.get("au")
    if (du or "").endswith("-01-01") and (au or "").endswith("-12-31"):
        return (None, None)
    return (du, au)


def texte_lieu(regle):
    portee = regle.get("portee") or {}
    texte = portee.get("lieu") if isinstance(portee, dict) else None
    if isinstance(texte, dict):
        texte = " ".join(str(v) for v in texte.values())
    return texte or ""


def lieu(regle):
    return {m for m in norm(texte_lieu(regle)).split() if len(m) > 2 and m not in MOTS_VIDES}


def nom_eau(regle):
    """Le cours d'eau ou le plan d'eau : ce qui précède la première parenthèse, virgule ou deux-points."""
    tete = re.split(r"[(,:;]", texte_lieu(regle), maxsplit=1)[0]
    return norm(re.sub(r"^(lac|plan d'eau|etang|étang|canal|riviere|rivière)\s+(de |du |des |d')?", "", tete.strip(), flags=re.I))


def confirme(a, b):
    """Vrai si chaque fait de la règle a se retrouve dans la règle b."""
    if a.get("type") != b.get("type"):
        return False
    ea, eb = especes(a), especes(b)
    sans_espece = a.get("type") in TYPES_LIEU and "*" in (ea | eb)
    if not sans_espece and not ea <= eb:
        return False
    if dates(a) != dates(b):
        return False
    if a.get("type") not in TYPES_LIEU:
        na, nb = nombres(a.get("valeur")), nombres(b.get("valeur"))
        if na != nb and not (len(eb) > 1 and na <= nb):
            return False
    la, lb = lieu(a), lieu(b)
    if la and lb:
        na_, nb_ = nom_eau(a), nom_eau(b)
        if not (na_ and nb_ and (na_ == nb_ or na_ in nb_ or nb_ in na_)):
            return False
        communs = len(la & lb)
        return communs / min(len(la), len(lb)) >= 0.6 and communs >= min(2, len(la), len(lb))
    if la or lb:
        return False
    return str(a.get("categorie")) == str(b.get("categorie"))


def charger(chemin):
    with open(chemin, encoding="utf-8") as f:
        return json.load(f).get("regles", [])


def comparer(code):
    la = charger(os.path.join(ICI, "dep", f"{code}.json"))
    lb = charger(os.path.join(ICI, "dep-b", f"{code}.json"))
    gardees, seules_a, prises = [], [], set()
    for a in la:
        b = next((b for i, b in enumerate(lb) if i not in prises and confirme(a, b)), None)
        if b is None:
            b = next((b for b in lb if confirme(a, b)), None)
        else:
            prises.add(lb.index(b))
        if b is None:
            seules_a.append(a)
            continue
        statut = "brouillon" if a.get("statut") == b.get("statut") == "brouillon" else "incertain"
        gardees.append(dict(a, statut=statut, lecture_b={"id": b.get("id"), "source": b.get("source"), "citation": b.get("citation")}))
    seules_b = [b for b in lb if not any(confirme(b, a) for a in la)]
    return la, lb, gardees, seules_a, seules_b


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    codes = [sys.argv[1]]
    if sys.argv[1] == "--tous":
        codes = sorted(f[:-5] for f in os.listdir(os.path.join(ICI, "dep"))
                       if f.endswith(".json") and os.path.exists(os.path.join(ICI, "dep-b", f)))
    erreur = 0
    for code in codes:
        try:
            la, lb, gardees, seules_a, seules_b = comparer(code)
        except (OSError, json.JSONDecodeError) as e:
            print(f"{code} : lecture impossible ({e})")
            erreur = 1
            continue
        sures = sum(1 for r in gardees if r["statut"] == "brouillon")
        part = round(100 * len(gardees) / len(la)) if la else 0
        print(f"{code} : lecture A {len(la)} règles, lecture B {len(lb)} ; A confirmées par B {len(gardees)} ({part} %, "
              f"dont {sures} sans réserve) ; seulement A {len(seules_a)} ; seulement B {len(seules_b)}")
        if len(codes) == 1:
            for titre, liste in (("Seulement dans A", seules_a), ("Seulement dans B", seules_b)):
                for r in liste[:15]:
                    print(f"  {titre} : {r.get('id')} ({r.get('type')}) {r.get('phrase', '')[:90]}")
        if "--json" in sys.argv:
            os.makedirs(os.path.join(ICI, "consensus"), exist_ok=True)
            with open(os.path.join(ICI, "consensus", f"{code}.json"), "w", encoding="utf-8") as f:
                json.dump({"departement": code, "regles": gardees,
                           "desaccords": {"seulement_a": seules_a, "seulement_b": seules_b}}, f, ensure_ascii=False, indent=1)
    return erreur


if __name__ == "__main__":
    sys.exit(main())
