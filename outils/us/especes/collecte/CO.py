#!/usr/bin/env python3
"""CO : liste « Know Your Fish » de Colorado Parks and Wildlife (niveau État). Les espèces que la fiche marque
« not fishable » (protégées) sont laissées de côté. Usage : python3 -I CO.py  (réseau) ; la fonction parser_liste se teste sur fixture."""
import re, html, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import esp8_commun as C

URL = "https://cpw.state.co.us/fish-species-information-list"
ALIAS = {"pumpkinseed sunfish": "pumpkinseed", "black bullhead catfish": "black bullhead",
         "brown bullhead catfish": "brown bullhead", "grayling arctic": "arctic grayling", "grayling (arctic)": "arctic grayling"}


def parser_liste(page):
    """-> [(nom, pechable)] pour chaque carte d'espèce de la page."""
    out = []
    for bloc in re.split(r'<h4 class="coh-heading', page)[1:]:
        m = re.match(r'[^>]*>\s*([^<]+?)\s*</h4>', bloc)
        if not m or "cpw.state.co.us/species/" not in bloc[:6000]:
            continue
        nom = html.unescape(m.group(1))
        # la carte porte « toggle-1 » (pêchable) ou « toggle-0 » (le texte « not fishable » s'affiche)
        out.append((nom, "toggle-1 " in bloc[:400]))
    return out


def construire(pages):
    vus, entrees, exclus, inconnus = set(), [], [], []
    for p in pages:
        for nom, ok in parser_liste(p):
            if nom in vus:
                continue
            vus.add(nom)
            if not ok:
                exclus.append(nom)
                continue
            cle = ALIAS.get(nom.lower(), nom)
            e = C.entree(cle, {"type": "etat", "id": "CO", "nom": "Colorado"}, "liste_agence", 0)
            if e is None:
                inconnus.append(nom)
            else:
                entrees.append(e)
    return entrees, exclus, inconnus


def main():
    pages = [C.telecharger(URL + ("" if i == 0 else f"?page={i}")) for i in range(6)]
    entrees, exclus, inconnus = construire(pages)
    sources = [C.src("Colorado Parks and Wildlife, Know Your Fish (liste des espèces)", URL)]
    chemin, taille = C.ecrire("CO", "agence", sources, entrees)
    print(chemin, taille, len(entrees), "entrées ; non pêchables écartées :", exclus, "; sans correspondance :", inconnus)


if __name__ == "__main__":
    main()
