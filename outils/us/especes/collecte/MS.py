"""MS : guide « Fish I.D. Guide » du MDWFP, 39 espèces communes (niveau État). Usage : python3 -I MS.py [page.html]"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun

URL = "https://www.mdwfp.com/fishing-boating/fish-id-guide"


def noms(html):
    t = commun.texte(html)
    t = t[t.find("Fish Species White Crappie"):t.find("Downloadable Resources")].replace("Fish Species", "", 1)
    return commun.noms_connus(t)


def construire(html):
    sl = commun.slugs_par_latin()
    vus, entrees = set(), []
    liste = []
    for n in noms(html):  # le guide regroupe chain et redfin pickerel en une fiche : deux entrées
        liste += ["Chain pickerel", "Redfin pickerel"] if n.lower() == "chain/redfin pickerel" else [n]
    for n in liste:
        lat = commun.latin_de(n)
        if lat in vus:
            continue
        vus.add(lat)
        entrees.append(commun.entree(n, lat, {"type": "etat", "id": "MS", "nom": "Mississippi"}, "liste_agence", 0, slugs=sl))
    return entrees


def main(page=None):
    html = open(page, encoding="utf-8").read() if page else commun.telecharger(URL)
    sources = [{"nom": "MDWFP, Fish I.D. Guide (39 espèces communes)", "url": URL, "licence": "non précisée", "date": commun.DATE}]
    entrees = construire(html)
    print("MS", len(entrees), commun.ecrire("MS", "agence", sources, entrees))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
