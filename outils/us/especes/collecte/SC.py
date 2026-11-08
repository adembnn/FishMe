"""SC : liste « Fish Species - Freshwater » du SCDNR (niveau État). Usage : python3 -I SC.py [page.html]"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun

URL = "https://www.dnr.sc.gov/freshwater.html"
TITRES = ["Temperate Bass", "Diaromous Fishes", "Black Bass", "Sunfish", "Pickerel", "Coldwater Trout", "Catfish", "Perch", "Other Species"]


def noms(html):
    t = commun.texte(html)
    t = t[t.find("Guide to Freshwater Fishes"):]
    t = t[:t.find("Research and Education")]
    t = t.replace("Guide to Freshwater Fishes (Adobe PDF - 3MB) -->", "")
    for h in sorted(TITRES, key=len, reverse=True):
        t = t.replace(h, "|")
    res = []
    for bloc in t.split("|"):
        res += commun.noms_connus(bloc)
    return res


def construire(html):
    sl = commun.slugs_par_latin()
    vus, entrees = set(), []
    for n in noms(html):
        lat = commun.latin_de(n)
        if lat in vus:
            continue
        vus.add(lat)
        entrees.append(commun.entree(n.replace("(Shellcracker)", "").strip(), lat, {"type": "etat", "id": "SC", "nom": "South Carolina"}, "liste_agence", 0, slugs=sl))
    return entrees


def main(page=None):
    html = open(page, encoding="utf-8").read() if page else commun.telecharger(URL)
    sources = [{"nom": "SCDNR, Fish Species - Freshwater", "url": URL, "licence": "non précisée", "date": commun.DATE}]
    entrees = construire(html)
    print("SC", len(entrees), commun.ecrire("SC", "agence", sources, entrees))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
