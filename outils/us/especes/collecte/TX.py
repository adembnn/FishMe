#!/usr/bin/env python3
"""TX : rapports d'empoissonnement de Texas Parks and Wildlife (TPWD), par plan d'eau (grands lacs et baies).
Niveau État : les espèces de la liste « Reports by Species » (espèces empoissonnées). Niveau plan d'eau : espèce + plan d'eau,
n = nombre de lignes d'empoissonnement du rapport pour cette espèce, annee_max = dernière année. Ne garde que les poissons de pêche
(les poissons fourrage et les hybrides sans nom scientifique net sont écartés).
Usage : python3 -I TX.py [dossier des pages déjà téléchargées]"""
import re, html, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import esp8_commun as C

BASE = "https://tpwd.texas.gov/fishboat/fish/management/stocking/"
ACTION = "https://tpwd.texas.gov/fishboat/fish/action/stock_bywater.php?WB_code="

# « Bass, Largemouth » -> « Largemouth bass » ; quelques cas à la main
SPECIAL = {"bass, florida largemouth": "florida largemouth bass", "bass, sharelunker largemouth": "largemouth bass",
           "bluegill, coppernose": "bluegill", "sunfish, bluegill": "bluegill", "carp, grass": "grass carp",
           "cichlid, rio grande": "rio grande cichlid", "sucker, blue": "blue sucker"}
FOURRAGE = {"shad, gizzard", "shad, threadfin", "shiner, golden", "minnow, fathead", "fish", "bass, lone star",
            "sunfish, green x redear"}


def nom_courant(brut):
    k = html.unescape(brut).strip().lower()
    if k in FOURRAGE:
        return None
    if k in SPECIAL:
        return SPECIAL[k]
    if "," in k:
        a, b = [x.strip() for x in k.split(",", 1)]
        return f"{b} {a}"
    return k


def parser_eau(page):
    """-> {nom courant: (n lignes, année max)} pour une page stock_bywater."""
    out = {}
    for tr in re.findall(r"<tr[^>]*>(.*?)</tr>", page, flags=re.S):
        cells = [re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", c))).strip() for c in re.findall(r"<td[^>]*>(.*?)</td>", tr, flags=re.S)]
        cells = [c for c in cells if c]
        if len(cells) < 2 or not re.fullmatch(r"(19|20)\d\d", cells[1]):
            continue
        nom = nom_courant(cells[0])
        if not nom:
            continue
        n, an = out.get(nom, (0, 0))
        out[nom] = (n + 1, max(an, int(cells[1])))
    return out


def liste_eaux(page):
    return [(c, html.unescape(n).strip()) for c, n in re.findall(r'stock_bywater\.php\?WB_code=(\w+)"[^>]*>([^<]*)', page)]


def parser_especes_etat(page):
    m = re.search(r'<select name="species".*?</select>', page, flags=re.S)
    noms = [html.unescape(x) for x in re.findall(r"<option[^>]*>([^<]+)</option>", m.group(0))] if m else []
    return [n for n in (nom_courant(x) for x in noms) if n]


def construire(page_etat, page_eaux, pages_eaux):
    """pages_eaux : {code: html}. -> (entrees, inconnus)"""
    entrees, inconnus = [], set()
    for nom in parser_especes_etat(page_etat):
        e = C.entree(nom, {"type": "etat", "id": "TX", "nom": "Texas"}, "empoissonnement", 0)
        if e is None:
            inconnus.add(nom)
        elif e not in entrees:
            entrees.append(e)
    for code, nom_eau in liste_eaux(page_eaux):
        if code not in pages_eaux:
            continue
        for nom, (n, an) in sorted(parser_eau(pages_eaux[code]).items()):
            e = C.entree(nom, {"type": "plan_eau", "id": nom_eau, "nom": nom_eau}, "empoissonnement", 1, n=n, annee_max=an)
            if e is None:
                inconnus.add(nom)
            else:
                entrees.append(e)
    return entrees, sorted(inconnus)


def main(dossier=None):
    dossier = dossier or C.BRUT
    lire = lambda f: open(os.path.join(dossier, f), encoding="utf-8", errors="replace").read()
    page_etat, page_eaux = lire("tx-st1.html"), lire("tx-st2.html")
    pages = {}
    for code, _ in liste_eaux(page_eaux):
        f = os.path.join(dossier, "tx", code + ".html")
        if os.path.exists(f):
            pages[code] = open(f, encoding="utf-8", errors="replace").read()
    entrees, inconnus = construire(page_etat, page_eaux, pages)
    sources = [C.src("TPWD, rapports d'empoissonnement par espèce (liste des espèces empoissonnées)", BASE + "fishstock_state.phtml"),
               C.src("TPWD, rapports d'empoissonnement par plan d'eau (grands lacs et baies)", BASE + "fishstock_water.phtml")]
    chemin, taille = C.ecrire("TX", "agence", sources, entrees)
    print(chemin, taille, len(entrees), "entrées ; sans correspondance :", inconnus)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
