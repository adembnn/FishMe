"""Compare deux lectures indépendantes des règles d'un département et garde celles où elles s'accordent.

Usage : python3 consensus.py <code>            (lit dep/<code>.json et dep-b/<code>.json)
        python3 consensus.py <code> --json     (écrit consensus/<code>.json)
        python3 consensus.py --tous            (une ligne par département qui a ses deux lectures)

On compare le fond, pas la rédaction : deux lecteurs peuvent citer deux textes différents (arrêté et avis),
regrouper ou séparer les espèces, écrire un code Sandre ou un nom. Chaque règle est découpée en faits
(type, espèce, dates, nombres écrits comme nombres, lieu). Une règle de A est confirmée si chacun de ses faits existe dans
une règle de B : même type, même espèce, mêmes dates de début et de fin, mêmes nombres (tailles, quotas ; pas
ceux des phrases ; pour une réserve, un parcours ou une catégorie, seul le lieu compte), et lieux qui se recouvrent.
Le lieu est comparé comme un identifiant : les mots du cours d'eau et du plan d'eau (où qu'ils soient écrits, A met
souvent le plan d'eau en tête et B le cours d'eau), minuscules sans accents, sans mots vides, sans limites ni association.
La règle confirmée doit être au moins aussi fine que celle qui la confirme : « Seine (Vernon) » est dans « Seine »,
pas l'inverse. Une règle large dont l'autre lecture donne chaque morceau (« lots 53 à 57 » contre « lot 53 », « lot 54 »…)
est confirmée si les morceaux couvrent tous ses numéros. Sans lieu des deux côtés, même catégorie ; une règle fine
(avec lieu) est confirmée par la règle du département entier si la valeur est chiffrée ou datée et la même.
Les citations ne sont pas comparées : chacune doit être exacte dans son texte.
Une règle « incertain » d'un côté reste incertaine. Une règle non confirmée devient « vérifie l'arrêté » : elle va
dans `desaccords`. Les paires « même valeur, catégorie différente » (2 contre toutes) vont dans `paires_categorie`
du JSON, pour D1 (fusion prudente : la plus stricte se montre).
Sort 0 si les fichiers sont lisibles, 1 sinon.
"""
import json
import os
import re
import sys
import unicodedata

# Le dossier des lectures : REGLES_DIR s'il est donné, sinon celui de ce script.
ICI = os.environ.get("REGLES_DIR") or os.path.dirname(os.path.abspath(__file__))

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
              "pont", "plan", "plans", "eau", "eaux", "lac", "etang", "etangs", "riviere", "ruisseau", "amont", "aval",
              "depuis", "jusqu", "entre", "partie", "situee", "rive", "rives", "droite", "gauche", "pecheurs", "loisir",
              "lieu", "dit", "ensemble", "totalite", "lineaire", "aappma", "association", "surface", "limites",
              "parcours", "specialise", "section", "parcelle", "parcelles", "cadastre", "cadastres", "cadastrees",
              "lot", "lots", "sci", "closes", "sections", "deux", "trois", "quatre", "cinq", "tous", "tout", "toute", "toutes", "cours", "son", "dans", "base"}
TYPES_LIEU = {"reserve", "carpe_nuit", "no_kill", "categorie"}
# Un lieu est « précis » (et non un cours d'eau entier) s'il nomme un plan d'eau ou un étang.
PRECIS = re.compile(r"\b(plans? d eau|etangs?|lac|ballastiere|base de loisirs|eaux closes)\b")
# Une incise qui ne nomme pas le lieu (association, parcelles, limites…) : elle n'entre pas dans l'identifiant.
INCISE_VIDE = re.compile(r"^(aappma|association|sci|s c i|societe|parcelles?|sections?|limites|lots?|n|ensemble|totalite)\b")
SUITE_NUMEROS = re.compile(r"(?:\blots?\b|n°|\bnos?\b)\s*(?:n°\s*)?\d+(?:\s*[A-Z]\b)?"
                           r"(?:\s*(?:,|\bet\b|à)\s*(?:n°\s*)?\d+(?:\s*[A-Z]\b)?)*")


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


# ---- Le lieu : un identifiant, pas une phrase -------------------------------------------------------------------

def _couper(texte, sep):
    """Coupe au premier `sep` hors parenthèses et hors guillemets : (avant, après) ; après est vide s'il n'y en a pas."""
    profondeur = 0
    for i, c in enumerate(texte):
        if c in "(«":
            profondeur += 1
        elif c in ")»":
            profondeur = max(0, profondeur - 1)
        elif c == sep and profondeur == 0:
            return texte[:i], texte[i + 1:]
    return texte, ""


def _sans_parentheses(texte):
    while True:
        court = re.sub(r"\([^()]*\)", " ", texte)
        if court == texte:
            return texte
        texte = court


def _parentheses(texte):
    """Le contenu des parenthèses de premier niveau (les communes)."""
    sortie, profondeur, debut = [], 0, 0
    for i, c in enumerate(texte):
        if c == "(":
            if profondeur == 0:
                debut = i + 1
            profondeur += 1
        elif c == ")" and profondeur:
            profondeur -= 1
            if profondeur == 0:
                sortie.append(texte[debut:i])
    return " ".join(sortie)


def _mots(texte):
    return {m for m in norm(texte).split() if len(m) > 2 and not m.isdigit() and m not in MOTS_VIDES}


def identifiant_lieu(regle):
    """Les mots qui nomment le lieu : la tête (cours d'eau ou plan d'eau, communes) et la première incise après les
    deux-points. Ni les limites (« amont : pont de… »), ni l'association, ni les surfaces. Que le plan d'eau soit écrit
    en tête (A : « Plan d'eau du château de Broglie (…), sur la Charentonne ») ou après le cours d'eau (B :
    « Charentonne (…) : plan d'eau du château de Broglie »), on obtient les mêmes mots."""
    tete, queue = _couper(texte_lieu(regle), ":")
    incise = _couper(queue, ",")[0]
    return _mots((tete if INCISE_VIDE.match(norm(incise)) else tete + " " + incise) + " " + _noms_structures(regle))


def _noms_structures(regle):
    """Les champs `plan_eau` et `cours_eau` de `portee`, quand la lecture les donne (consigne v2)."""
    portee = regle.get("portee") if isinstance(regle.get("portee"), dict) else {}
    return " ".join(str(portee.get(k)) for k in ("plan_eau", "cours_eau") if portee.get(k))


def noms_lieu(regle):
    """Les mots du lieu hors parenthèses : le cours d'eau et le plan d'eau, sans les communes."""
    tete, queue = _couper(texte_lieu(regle), ":")
    incise = _couper(queue, ",")[0]
    return _mots(_sans_parentheses(tete if INCISE_VIDE.match(norm(incise)) else tete + " " + incise) + " " + _noms_structures(regle))


def communes_lieu(regle):
    """Les mots entre parenthèses dans la tête du lieu (les communes)."""
    return _mots(_parentheses(_couper(texte_lieu(regle), ":")[0]))


def numeros_lieu(regle):
    """Les numéros qui distinguent un lot ou un étang : « lots 53 à 57 », « n° 1, 2 et n° 4 », « E1, E2 »."""
    texte = re.split(r"\bparcelles?\b|\bsections?\b", _sans_parentheses(texte_lieu(regle)), maxsplit=1, flags=re.I)[0]
    trouves = {"e" + n for n in re.findall(r"\bE(\d+)\b", texte)}
    for m in SUITE_NUMEROS.finditer(texte):
        corps = re.sub(r"^(?:\blots?\b|n°|\bnos?\b)\s*", "", m.group(0))
        precedent = None
        for suite in re.finditer(r"(,|\bet\b|à)?\s*(?:n°\s*)?(\d+)", corps):
            n = int(suite.group(2))
            if suite.group(1) == "à" and precedent is not None and 0 < n - precedent < 200:
                trouves.update(str(k) for k in range(precedent, n + 1))
            trouves.add(str(n))
            precedent = n
    return trouves


def lieu_dans(a, b):
    """Le lieu de a est-il le même que celui de b, ou compris dedans ? a doit être au moins aussi fin que b :
    « Seine » n'est pas dans « Seine (Vernon) », a dirait plus que b ; « Seine (Vernon) » est dans « Seine »."""
    ia, ib = identifiant_lieu(a), identifiant_lieu(b)
    if not ia or not ib:
        return False
    na, nb = numeros_lieu(a), numeros_lieu(b)
    if nb and not (na and na <= nb):
        return False
    communs = ia & ib
    if len(communs) < min(2, len(ia), len(ib)):
        return False
    # Deux lectures peuvent nommer l'une le plan d'eau, l'autre le cours d'eau, mais un des deux noms au moins doit
    # se retrouver : « Lieure (Rosay) » et « Andelle (Rosay) » ne sont pas le même lieu parce qu'ils ont la commune.
    noms_a, noms_b = noms_lieu(a), noms_lieu(b)
    if noms_a and noms_b and not noms_a & noms_b:
        return False
    if na and na == nb:
        return True
    ca, cb = communes_lieu(a), communes_lieu(b)
    if ca and cb:
        # Presque toutes les communes de a sont nommées par b (un lecteur peut en oublier une sur une liste de quatre).
        return len(ca & ib) / len(ca) >= 0.75 and len(communs) / min(len(ia), len(ib)) >= 0.6
    if ca:
        return len(communs) / len(ib) >= 0.6
    if cb:
        return bool(PRECIS.search(norm(texte_lieu(a)))) and len(communs) / len(ia) >= 0.6
    return len(communs) / min(len(ia), len(ib)) >= 0.6


def proximite(a, b):
    """Pour choisir la meilleure règle de l'autre lecture : part commune des mots des deux lieux."""
    ia, ib = identifiant_lieu(a), identifiant_lieu(b)
    return len(ia & ib) / len(ia | ib) if ia | ib else 1.0


def confirme(a, b, categorie=True):
    """Vrai si chaque fait de la règle a se retrouve dans la règle b ; a peut être plus fine que b.
    `categorie=False` ignore la catégorie : sert à trouver les paires « même valeur, catégorie différente »."""
    if a.get("type") != b.get("type"):
        return False
    ea, eb = especes(a), especes(b)
    sans_espece = a.get("type") in TYPES_LIEU and "*" in (ea | eb)
    if not sans_espece and not ea <= eb:
        return False
    if dates(a) != dates(b):
        return False
    na, nb = nombres(a.get("valeur")), nombres(b.get("valeur"))
    if a.get("type") not in TYPES_LIEU:
        if na != nb and not (len(eb) > 1 and na <= nb):
            return False
    elif a.get("type") == "categorie":
        ca, cb = (a.get("valeur") or {}).get("classe"), (b.get("valeur") or {}).get("classe")
        if ca is not None and cb is not None and str(ca) != str(cb):
            return False
    la, lb = identifiant_lieu(a), identifiant_lieu(b)
    if la and lb:
        return lieu_dans(a, b)
    if lb:
        return False
    if la:
        # Règle fine contre règle du département entier : seulement si la valeur est chiffrée ou datée, et si la
        # catégorie de la règle large couvre celle de la fine.
        if a.get("type") in TYPES_LIEU or not (na or dates(a) != (None, None)):
            return False
        return not categorie or str(b.get("categorie")) in (str(a.get("categorie")), "toutes")
    return not categorie or str(a.get("categorie")) == str(b.get("categorie"))


def couverte_par_morceaux(a, autres):
    """Règle large (« lots 53 à 57 ») dont l'autre lecture donne chaque morceau à part (« lot 53 », « lot 54 »…) :
    confirmée si les morceaux, ensemble, couvrent tous ses numéros. Rend les morceaux, ou [] sinon."""
    na = numeros_lieu(a)
    if not na:
        return []
    morceaux = [b for b in autres if numeros_lieu(b) and confirme(b, a)]
    couverts = set().union(*(numeros_lieu(b) for b in morceaux)) if morceaux else set()
    return morceaux if na <= couverts else []


def paires_categorie(seules_a, seules_b):
    """Les règles que les deux lectures donnent à l'identique, sauf la catégorie (« 2 » contre « toutes »)."""
    paires = []
    for a in seules_a:
        for b in seules_b:
            if str(a.get("categorie")) != str(b.get("categorie")) and (
                    confirme(a, b, categorie=False) or confirme(b, a, categorie=False)):
                paires.append({"type": a.get("type"), "especes": a.get("especes"), "lieu": texte_lieu(a) or texte_lieu(b) or None,
                               "valeur": a.get("valeur"), "a": {"id": a.get("id"), "categorie": a.get("categorie")},
                               "b": {"id": b.get("id"), "categorie": b.get("categorie")}})
    return paires


def charger(chemin):
    with open(chemin, encoding="utf-8") as f:
        return json.load(f).get("regles", [])


def comparer(code):
    la = charger(os.path.join(ICI, "dep", f"{code}.json"))
    lb = charger(os.path.join(ICI, "dep-b", f"{code}.json"))
    gardees, seules_a = [], []
    for a in la:
        candidats = [b for b in lb if confirme(a, b)]
        morceaux = [] if candidats else couverte_par_morceaux(a, lb)
        if not candidats and not morceaux:
            seules_a.append(a)
            continue
        b = max(candidats or morceaux, key=lambda b: proximite(a, b))
        statut = "brouillon" if a.get("statut") == b.get("statut") == "brouillon" else "incertain"
        if morceaux and any(m.get("statut") != "brouillon" for m in morceaux):
            statut = "incertain"
        regle = dict(a, statut=statut, lecture_b={"id": b.get("id"), "source": b.get("source"), "citation": b.get("citation")})
        if morceaux:
            regle["lecture_b_morceaux"] = [m.get("id") for m in morceaux]
        gardees.append(regle)
    seules_b = [b for b in lb if not any(confirme(b, a) for a in la) and not couverte_par_morceaux(b, la)]
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
        paires = paires_categorie(seules_a, seules_b)
        print(f"{code} : lecture A {len(la)} règles, lecture B {len(lb)} ; A confirmées par B {len(gardees)} ({part} %, "
              f"dont {sures} sans réserve) ; seulement A {len(seules_a)} ; seulement B {len(seules_b)} ; "
              f"même valeur, catégorie différente {len(paires)}")
        if len(codes) == 1:
            for titre, liste in (("Seulement dans A", seules_a), ("Seulement dans B", seules_b)):
                for r in liste[:15]:
                    print(f"  {titre} : {r.get('id')} ({r.get('type')}) {r.get('phrase', '')[:90]}")
            for p in paires:
                print(f"  Même valeur, catégorie {p['a']['categorie']} (A) contre {p['b']['categorie']} (B) : {p['a']['id']} / {p['b']['id']}")
        if "--json" in sys.argv:
            os.makedirs(os.path.join(ICI, "consensus"), exist_ok=True)
            with open(os.path.join(ICI, "consensus", f"{code}.json"), "w", encoding="utf-8") as f:
                json.dump({"departement": code, "regles": gardees,
                           "desaccords": {"seulement_a": seules_a, "seulement_b": seules_b},
                           "paires_categorie": paires}, f, ensure_ascii=False, indent=1)
    return erreur


if __name__ == "__main__":
    sys.exit(main())
