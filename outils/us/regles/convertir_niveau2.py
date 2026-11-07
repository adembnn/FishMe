"""Convertit le consensus de TX, FL, NC, NY et MI vers regles-us/<USPS>.json (lot D7).

Usage (depuis la racine du dépôt) : python3 -I outils/us/regles/convertir_niveau2.py TX FL NC NY
(MI n'est pas converti : 0 règle confirmée sans réserve ; un fichier vide ferait échouer le test de WI et MN) [--date AAAA-MM-JJ]

Réutilise le convertisseur du lot us-format (outils/us/format/vers_regles_us.py), lu sans le modifier, et lui ajoute :
- le nom et le lien de l'agence de TX, FL, NC, NY ;
- le marquage « tiers » : une règle dont la source (ou l'une des sources de ses constituants) n'est pas une page de l'agence
  ou de l'État reçoit source.tiers = true et une édition qui le dit (NC : eRegulations, éditeur tiers).
Seules les règles confirmées sans réserve par les deux lectures sont converties ; les autres restent dans consensus.json
(incertaines, a_verifier) avec les deux lectures.
"""
import importlib.util
import json
import os
import re
import sys
from urllib.parse import urlparse

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.abspath(os.path.join(ICI, "..", "..", ".."))

# Domaines officiels (agence ou État) : tout le reste est « tiers ».
OFFICIELS = ("tpwd.texas.gov", "myfwc.com", "flrules.org", "ncwildlife.gov", "ncleg.gov", "dec.ny.gov", "nysenate.gov", "michigan.gov",
             "widnr.widen.net", "dnr.wisconsin.gov", "dnr.state.mn.us", "revisor.mn.gov")

H = "https" + ":" + "//"
ETATS_PLUS = dict(
    TX=("Texas", H + "tpwd.texas.gov/regulations/outdoor-annual/fishing/freshwater-fishing"),
    FL=("Florida", H + "myfwc.com/fishing/freshwater/regulations/"),
    NC=("North Carolina", H + "www.ncwildlife.gov/fishing/regulations"),
    NY=("New York", H + "dec.ny.gov/things-to-do/freshwater-fishing/regulations"),
)


def charger(nom, chemin):
    spec = importlib.util.spec_from_file_location(nom, chemin)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


vers = charger("vers_regles_us", os.path.join(RACINE, "outils", "us", "format", "vers_regles_us.py"))
vers.ETATS.update(ETATS_PLUS)


def hote(url):
    return re.sub(r"^www\.", "", (urlparse(url or "").hostname or "").lower())


def est_tiers(url):
    h = hote(url)
    return not any(h == d or h.endswith("." + d) for d in OFFICIELS)


def marquer_tiers(donnees):
    n = 0
    for r in donnees["regles"]:
        urls = [r["source"].get("url")] + [c.get("url") for c in r.get("constituants", [])]
        tiers = sorted(set(hote(u) for u in urls if est_tiers(u)))
        if not tiers:
            continue
        r["source"]["tiers"] = True
        ed = r["source"].get("edition")
        r["source"]["edition"] = "Source tierce, hors agence (" + ", ".join(tiers) + ")" + (" : " + ed if ed else "")
        n += 1
    return n


# Noms de groupe du texte de l'agence -> espèces du catalogue de l'app que ce nom désigne (décision du lot D7, dite dans le journal).
# Les citations des règles restent celles de l'agence ; une règle sur un groupe n'est jamais étendue à une espèce que le groupe n'inclut pas.
# Règles confirmées mais retirées du chargement : la règle vise une catégorie (« inland game fish ») que le catalogue ne sait pas porter ;
# la charger sans espèce l'étendrait à toutes les espèces, y compris celles qu'elle ne vise pas.
EXCLURE = dict(NC=["NC-gen-engin-ligne"])
COMMUN = dict(tigermuskellunge=["tiger-muskie"], lakesturgeon=["lake-sturgeon"])
ALIAS = dict(
    NC=dict(trout=["brook-trout", "brown-trout", "rainbow-trout"]),
    NY=dict(landlockedatlanticsalmon=["atlantic-salmon"]),
    FL=dict(
        blackbass=["largemouth-bass", "florida-bass", "spotted-bass", "suwannee-bass"],
        crappie=["black-crappie", "white-crappie"],
    ),
    TX=dict(hybridstripedbass=["wiper"]),
)


def cle(nom):
    return re.sub(r"[^a-z]", "", (nom or "").lower())


def synthetique(slug):
    return "zz" + slug.replace("-", "")


def elargir(regle, etat, catalogue, journal):
    """Remplace chaque nom d'espèce par un nom synthétique qui désigne un seul slug du catalogue (jamais deux espèces confondues)."""
    noms = regle.get("especes") or []
    sortie = []
    for n in noms:
        slugs = ALIAS.get(etat, dict()).get(cle(n)) or COMMUN.get(cle(n))
        if slugs:
            journal.append("(info) " + str(regle.get("id")) + " : « " + n + " » lu comme " + ", ".join(slugs))
        else:
            slugs = [sl for sl, nom in catalogue.items() if re.sub(r"\(.*?\)", "", nom).strip().lower() == n.strip().lower()]
        if slugs:
            sortie.extend(synthetique(sl) for sl in slugs)
        else:
            sortie.append(n)
    copie = dict(regle)
    copie["especes"] = sortie
    return copie


def table_synthetique(catalogue):
    return dict((vers.c.espece(synthetique(sl)), sl) for sl in catalogue)


def date_partielle(regle):
    du, au = regle.get("du"), regle.get("au")
    if not du and not au:
        return False
    return (str(du)[-5:], str(au)[-5:]) != ("01-01", "12-31")


def convertir(etat, date, dossier_consensus=vers.CONSENSUS, especes=None):
    with open(os.path.join(dossier_consensus, etat, "consensus.json"), encoding="utf-8") as f:
        cons = json.load(f)
    if cons.get("fixture") or cons.get("etat") != etat:
        raise ValueError(etat + " : consensus fixture ou d'un autre État")
    with open(vers.ESPECES, encoding="utf-8") as f:
        catalogue = dict((e["slug"], e["nom_en"]) for e in json.load(f))
    conv = vers.Conversion(etat, especes if especes is not None else table_synthetique(catalogue))
    journal = []
    for r in cons.get("regles") or []:
        if r.get("id") in EXCLURE.get(etat, []):
            conv.noter(r, "règle de catégorie (game fish) sans espèce : non chargée, pas étendue à toutes les espèces")
            continue
        if r.get("type") not in ("saison", "fermeture", "relacher") and date_partielle(r):
            conv.noter(r, "règle datée (" + str(r.get("du")) + " au " + str(r.get("au")) + ") : le format ne porte pas la période, non convertie")
            continue
        conv.ajouter(elargir(r, etat, catalogue, journal))
    for r in cons.get("incertaines") or []:
        conv.noter(r, "règle incertaine : jamais convertie")
    donnees = conv.fichier(date, date + ".1")
    journal = conv.journal + journal
    n = marquer_tiers(donnees)
    if n:
        journal.append("(info) " + str(n) + " règles marquées source tierce (tiers) ; lien de l'agence : " + donnees["lien_agence"])
    return donnees, journal


vers.convertir = convertir  # ecrire() appelle cette fonction, puis calcule la somme sha256 du fichier écrit


def main(argv):
    return vers.main(argv)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
