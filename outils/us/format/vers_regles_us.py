"""Convertit la sortie du consensus (outils/us/regles/donnees/<USPS>/consensus.json) en fichier du chargeur Swift
(Packages/Core/Sources/Core/Resources/regles-us/<USPS>.json) et met à jour index.json (sha256, nombre de règles).

Usage (depuis la racine du dépôt) :
    python3 -I outils/us/format/vers_regles_us.py WI MN [--date AAAA-MM-JJ] [--sortie DOSSIER] [--consensus DOSSIER]

Seules les règles confirmées sans réserve par les deux lectures (`regles` du consensus) sont converties ; les « incertaines » et les
« a_verifier » ne le sont jamais. Statut de chaque règle : `double_lecture_confirmee`.

Regroupement : une règle du chargeur par (portée, espèce, famille), parce que le moteur compare les règles d'une même famille au même
niveau et appelle « conflit » deux règles différentes (une limite du jour et une limite de possession séparées se contrediraient).
Familles : ouverture (saison, fermeture, relacher daté), taille (taille_min, taille_max, fenetre « relacher_entre »), limites
(limite_jour, limite_possession), engins (engin, interdit), appâts (appat).

Ce qui n'est pas converti (dit dans le journal `<USPS>.journal.txt` à côté du consensus) :
- espèce inconnue du catalogue outils/us/especes/especes-us.json (ex. « Crappie », nom de groupe) ;
- saison toute l'année (aucune contrainte), relâcher sans dates, fenêtre d'un autre mode, type « autre » ;
- deux valeurs différentes dans la même case (même portée, espèce, famille) : les deux sont retirées (conflit).
Les dates portées par une limite ou une taille (« 6 du 23 mai au 28 févr. ») ne sont pas recopiées : la saison de l'espèce les porte.

La citation d'une règle regroupée réunit celles de ses parties (séparées par « / ») ; au-delà de 200 caractères, chaque partie est
coupée et finit par « … ». Les parties complètes (citations de A et de B) restent dans `constituants`, clé ignorée par le chargeur.
"""
import hashlib
import importlib.util
import json
import os
import re
import sys
import unicodedata

RACINE = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
CONSENSUS = os.path.join(RACINE, "outils", "us", "regles", "donnees")
SORTIE = os.path.join(RACINE, "Packages", "Core", "Sources", "Core", "Resources", "regles-us")
ESPECES = os.path.join(RACINE, "outils", "us", "especes", "especes-us.json")
CITATION_MAX = 200

# Nom de l'État et page de l'agence : lus dans les notes des lecteurs (NOTES-A.md, NOTES-B.md) et dans leurs « textes ».
ETATS = {
    "WI": ("Wisconsin", "https://dnr.wisconsin.gov/topic/Fishing/regulations"),
    "MN": ("Minnesota", "https://www.dnr.state.mn.us/regulations/fishing/index.html"),
    "MI": ("Michigan", "https://www.michigan.gov/dnr/managing-resources/laws/orders/fisheries-orders"),
}

FAMILLE = {"saison": "ouverture", "fermeture": "ouverture", "relacher": "ouverture", "taille_min": "taille", "taille_max": "taille",
           "fenetre": "taille", "limite_jour": "limites", "limite_possession": "limites", "engin": "engins", "interdit": "engins",
           "appat": "appats"}


def charger_consensus_us():
    spec = importlib.util.spec_from_file_location("consensus_us", os.path.join(RACINE, "outils", "us", "regles", "consensus_us.py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


c = charger_consensus_us()


def slug(texte):
    texte = unicodedata.normalize("NFKD", texte or "").encode("ascii", "ignore").decode().lower()
    texte = re.sub(r"\(.*?\)", " ", texte)
    return re.sub(r"[^a-z0-9]+", "-", texte).strip("-")


def catalogue_especes(chemin=ESPECES):
    """Nom canonique du consensus -> slug de l'app (« Rainbow trout (steelhead) » -> rainbow-trout)."""
    with open(chemin, encoding="utf-8") as f:
        liste = json.load(f)
    table = {}
    for e in liste:
        table.setdefault(c.espece(e["nom_en"]), e["slug"])
    return table


def mm_jj(date):
    return str(date)[-5:] if date else None


class Conversion:
    def __init__(self, etat, especes):
        self.etat = etat
        self.especes = especes
        self.journal = []
        self.juridictions = {}  # clé de zone -> dict
        self.cases = {}  # (portee, espece, famille) -> {"champs": {...}, "parties": [...]}

    def noter(self, regle, raison):
        self.journal.append(f"{regle.get('id')} : {raison}")

    # -- Portée -------------------------------------------------------------------------------------------------
    def portee(self, regle):
        p = regle.get("portee") or {}
        if p.get("troncon") or p.get("plan_eau"):
            return None  # niveau 3 : aucune règle confirmée aujourd'hui ; jamais devinée
        if not p.get("zone"):
            return f"US-{self.etat}"
        cle = c.portee(regle)["zone"]
        nom = re.sub(r"\s+", " ", p["zone"]).strip()
        if cle not in self.juridictions:
            ident = f"US-{self.etat}/{slug(nom)}"
            self.juridictions[cle] = {"id": ident, "niveau": "zone", "nom": nom}
        elif len(nom) < len(self.juridictions[cle]["nom"]):
            self.juridictions[cle]["nom"] = nom
        return self.juridictions[cle]["id"]

    # -- Valeur d'une règle typée vers les champs du chargeur ------------------------------------------------------
    def champs(self, r):
        t, v = r["type"], r.get("valeur") or {}
        du, au = mm_jj(r.get("du")), mm_jj(r.get("au"))
        if t == "saison":
            if c.dates(r) == (None, None):
                return None, "saison toute l'année ou sans dates : aucune contrainte à charger"
            return {"saison": {"du": du, "au": au}}, None
        if t in ("fermeture", "relacher"):
            if not (du and au):
                return None, f"{t} sans dates : période non lue, non convertie"
            genre = "remise_a_eau_seulement" if t == "relacher" else "peche_interdite"
            return {"fermetures": [{"type": genre, "du": du, "au": au, "motif": v.get("code") or t}]}, None
        if t in ("taille_min", "taille_max"):
            longueur = self.longueur(v)
            if not longueur:
                return None, "taille sans longueur lisible"
            return {"tailles": {"minimale" if t == "taille_min" else "maximale": longueur}}, None
        if t == "fenetre":
            if v.get("mode") != "relacher_entre":
                return None, f"fenêtre de mode {v.get('mode')} : non convertie"
            basse, haute = self.longueur(v, "_min"), self.longueur(v, "_max")
            if not (basse and haute):
                return None, "fenêtre sans bornes lisibles"
            return {"tailles": {"fenetre": {"basse": basse, "haute": haute}}}, None
        if t in ("limite_jour", "limite_possession"):
            n = v.get("nombre")
            if not isinstance(n, (int, float)) or isinstance(n, bool) or n < 0 or n != int(n):
                return None, "limite sans nombre entier"
            return {"limites": {"prise" if t == "limite_jour" else "possession": int(n)}}, None
        if t in ("engin", "interdit"):
            return ({"engins": [v["code"]]}, None) if v.get("code") else (None, "engin sans code")
        if t == "appat":
            return ({"appats": [v["code"]]}, None) if v.get("code") else (None, "appât sans code")
        return None, f"type {t} : pas de champ dans le format du chargeur"

    @staticmethod
    def longueur(v, suffixe=""):
        for cle, unite in (("pouces", "pouces"), ("cm", "cm"), ("mm", "mm")):
            x = v.get(cle + suffixe)
            if isinstance(x, (int, float)) and not isinstance(x, bool) and x > 0:
                return {unite: x}
        return None

    # -- Ajout d'une règle confirmée -----------------------------------------------------------------------------
    def ajouter(self, r):
        if r.get("statut") != "brouillon":
            self.noter(r, "règle incertaine : jamais convertie")
            return
        famille = FAMILLE.get(r["type"])
        champs, raison = self.champs(r)
        if not champs:
            self.noter(r, raison)
            return
        noms = r.get("especes") or []
        if noms:
            slugs = []
            for n in noms:
                s = self.especes.get(c.espece(n))
                if not s:
                    self.noter(r, f"espèce « {n} » absente du catalogue de l'app (groupe ou espèce inconnue)")
                    return
                slugs.append(s)
        else:
            slugs = [None]
        portee = self.portee(r)
        if not portee:
            self.noter(r, "portée plan d'eau ou tronçon : non convertie")
            return
        autre = r.get("lecture_b") or r.get("lecture_a") or {}
        partie = {"consensus": r["id"], "type": r["type"], "lecture": "B" if r.get("confirmee_par_lecture") == "A" else "A",
                  "citation": r.get("citation"), "source": r.get("source"),
                  "confirmee_par": {"id": autre.get("id"), "citation": autre.get("citation")},
                  "valide_au": r.get("valide_au") or r.get("expire_le")}
        for s in slugs:
            case = self.cases.setdefault((portee, s, famille), {"champs": {}, "parties": [], "conflit": False})
            if not fusionner(case["champs"], champs):
                case["conflit"] = True
            case["parties"].append(partie)

    # -- Fichier final --------------------------------------------------------------------------------------------
    def fichier(self, date, version):
        nom, lien = ETATS[self.etat]
        regles = []
        for (portee, esp, famille), case in sorted(self.cases.items(), key=lambda kv: (kv[0][0], kv[0][1] or "", kv[0][2])):
            if case["conflit"]:
                for p in case["parties"]:
                    self.journal.append(f"{p['consensus']} : deux valeurs différentes pour {portee} {esp or 'toutes'} {famille} : retirée")
                continue
            parties = dedoublonner(case["parties"])
            premiere = parties[0]
            src = premiere["source"] or {}
            regle = {"id": f"{self.etat}-{esp or 'toutes'}-{famille}-{portee.split('/', 1)[1] if '/' in portee else 'etat'}",
                     "portee": portee}
            if esp:
                regle["espece"] = esp
            regle.update(case["champs"])
            regle["source"] = {"url": src.get("url"), "date": src.get("date"), "citation": citation([p["citation"] for p in parties])}
            if src.get("edition"):
                regle["source"]["edition"] = src["edition"]
            regle["statut"] = "double_lecture_confirmee"
            fins = sorted(p["valide_au"] for p in parties if p.get("valide_au"))
            if fins:
                regle["valide_jusqua"] = fins[0]
            regle["constituants"] = [{k: p[k] for k in ("consensus", "type", "lecture", "citation", "confirmee_par")} |
                                     {"url": (p["source"] or {}).get("url")} for p in parties]
            regles.append(regle)
        juridictions = sorted(self.juridictions.values(), key=lambda j: j["id"])
        utilisees = {r["portee"] for r in regles}
        juridictions = [j for j in juridictions if j["id"] in utilisees]
        return {"format": 1, "etat": self.etat, "nom_etat": nom, "lien_agence": lien, "version": version, "genere_le": date,
                "couverture": 2, "relecture": "double lecture (lecteurs A et B indépendants, outils/us/regles/consensus_us.py)",
                "juridictions": juridictions, "exigences": [], "regles": regles}


def fusionner(dest, champs):
    """Fusionne des champs dans une case ; faux si une même case reçoit deux valeurs différentes."""
    for cle, val in champs.items():
        if cle in ("engins", "appats", "fermetures"):
            liste = dest.setdefault(cle, [])
            for x in val:
                if x not in liste:
                    liste.append(x)
        elif isinstance(val, dict):
            sous = dest.setdefault(cle, {})
            for k, x in val.items():
                if k in sous and sous[k] != x:
                    return False
                sous[k] = x
        else:
            if cle in dest and dest[cle] != val:
                return False
            dest[cle] = val
    return True


def dedoublonner(parties):
    vues, sortie = set(), []
    for p in parties:
        if p["consensus"] not in vues:
            vues.add(p["consensus"])
            sortie.append(p)
    return sortie


def citation(textes):
    """Citations réunies par « / », 200 caractères au plus ; chaque partie coupée garde son début exact et finit par « … »."""
    morceaux = []
    for t in textes:
        t = re.sub(r"\s+", " ", t or "").strip()
        if t and t not in morceaux:
            morceaux.append(t)
    tout = " / ".join(morceaux)
    if len(tout) <= CITATION_MAX:
        return tout
    part = (CITATION_MAX - 3 * (len(morceaux) - 1)) // len(morceaux)
    coupe = [m if len(m) <= part else m[: part - 1].rstrip() + "…" for m in morceaux]
    return " / ".join(coupe)[:CITATION_MAX]


def sha256(chemin):
    with open(chemin, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def convertir(etat, date, dossier_consensus=CONSENSUS, especes=None):
    with open(os.path.join(dossier_consensus, etat, "consensus.json"), encoding="utf-8") as f:
        cons = json.load(f)
    if cons.get("fixture"):
        raise ValueError(f"{etat} : consensus FIXTURE, jamais converti")
    if cons.get("etat") != etat:
        raise ValueError(f"{etat} : le consensus porte l'État {cons.get('etat')}")
    conv = Conversion(etat, especes if especes is not None else catalogue_especes())
    for r in cons.get("regles") or []:
        conv.ajouter(r)
    for r in cons.get("incertaines") or []:
        conv.noter(r, "règle incertaine : jamais convertie")
    return conv.fichier(date, f"{date}.1"), conv.journal


def ecrire(etat, date, sortie=SORTIE, dossier_consensus=CONSENSUS):
    donnees, journal = convertir(etat, date, dossier_consensus)
    os.makedirs(sortie, exist_ok=True)
    chemin = os.path.join(sortie, f"{etat}.json")
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(donnees, f, ensure_ascii=False, indent=1)
        f.write("\n")
    with open(os.path.join(dossier_consensus, etat, "conversion.journal.txt"), "w", encoding="utf-8") as f:
        f.write(f"{etat} : {len(donnees['regles'])} règles écrites dans regles-us/{etat}.json ; non converties :\n")
        f.write("\n".join(journal) + "\n")
    # Index : entrée de l'État, somme du fichier écrit.
    chemin_index = os.path.join(sortie, "index.json")
    with open(chemin_index, encoding="utf-8") as f:
        index = json.load(f)
    entree = {"niveau": 2, "regles": len(donnees["regles"]), "sha256": sha256(chemin)}
    fins = sorted(r["valide_jusqua"] for r in donnees["regles"] if r.get("valide_jusqua"))
    if fins:
        entree["expire_min"] = fins[0]
    index.setdefault("etats", {})[etat] = entree
    index["etats"] = dict(sorted(index["etats"].items()))
    index["version"] = f"{date}.1"
    index["date"] = date
    with open(chemin_index, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=1)
        f.write("\n")
    return donnees, journal


def main(argv):
    etats = [a for a in argv if re.fullmatch(r"[A-Z]{2}", a)]
    if not etats:
        print(__doc__)
        return 2
    date = argv[argv.index("--date") + 1] if "--date" in argv else "2026-11-07"
    sortie = argv[argv.index("--sortie") + 1] if "--sortie" in argv else SORTIE
    cons = argv[argv.index("--consensus") + 1] if "--consensus" in argv else CONSENSUS
    for e in etats:
        donnees, journal = ecrire(e, date, sortie, cons)
        print(f"{e} : {len(donnees['regles'])} règles chargeables, {len(donnees['juridictions'])} zones ; {len(journal)} non converties")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
