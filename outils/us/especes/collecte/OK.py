"""OK : Oklahoma Department of Wildlife Conservation. Niveau Etat (fiches « Field Guide / fish ») + plans d'eau
(fiches « Where To Fish », bloc « Fish Species of Interest »). Jamais le rapport de pêche ni les noms de pêcheurs.

Usage : python3 -I OK.py   (reseau ; bruts dans /private/tmp/claude-501/brut-us/especes/esp-7/)"""
import html
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _commun import DATE, ecrire, entree  # noqa: E402
from _http import telecharger  # noqa: E402

BASE = "https://wildlifedepartment.com"
BRUT = "/private/tmp/claude-501/brut-us/especes/esp-7"
SOURCES = [
    {"nom": "ODWC, Field Guide (fiches poissons)", "url": BASE + "/wildlife/field-guide",
     "licence": "non précisée", "date": DATE},
    {"nom": "ODWC, Where To Fish (fiches de plans d'eau, Fish Species of Interest)", "url": BASE + "/fishing/wheretofish",
     "licence": "non précisée", "date": DATE},
]


def _texte(page):
    t = re.sub(r"(?s)<(script|style).*?</\1>", "", page)
    t = html.unescape(re.sub(r"<[^>]+>", "\n", t))
    return [l.strip() for l in t.split("\n") if l.strip()]


def liens_lacs(page):
    return sorted(set(re.findall(r'href="(/fishing/wheretofish/(?:northeast|northwest|central|southeast|southwest)/[a-z0-9\-]+)"', page)))


def parser_lac(page):
    """Page de plan d'eau -> (nom, [especes d'interet])."""
    L = _texte(page)
    nom = None
    for i in range(len(L) - 3):
        if L[i:i + 3] == ["Home", "Fishing", "Where To Fish"]:
            nom = L[i + 3]
            break
    esp = []
    if "Fish Species of Interest" in L:
        for l in L[L.index("Fish Species of Interest") + 1:]:
            if l.startswith(("Upload Your Catch", "Recent Journals", "Submit Your Catch")):
                break
            esp.append(l)
    return nom, esp


def liens_poissons(page):
    return re.findall(r'href="/wildlife/field-guide/fish/([a-z0-9\-]+)"[^>]*>.*?(?:<h\d[^>]*>|class="[^"]*title[^"]*"[^>]*>)?', page)


def parser_nom_poisson(page):
    m = re.search(r"<title>([^<|]+?)\s*\|", page)
    return html.unescape(m.group(1)).strip() if m else None


def main():
    os.makedirs(BRUT, exist_ok=True)
    entrees, ecartes = [], set()
    # --- plans d'eau
    liens = set()
    p = 0
    while p < 60:
        c, d = telecharger(f"{BASE}/fishing/wheretofish?page={p}")
        if c != 200:
            break
        nouveaux = set(liens_lacs(d.decode("utf8", "ignore"))) - liens
        if not nouveaux:
            break
        liens |= nouveaux
        p += 1
    n_lacs = 0
    for l in sorted(liens):
        c, d = telecharger(BASE + l)
        if c != 200:
            continue
        nom, esp = parser_lac(d.decode("utf8", "ignore"))
        if not nom or not esp:
            continue
        n_lacs += 1
        for s in esp:
            e = entree(s, {"type": "plan_eau", "id": nom, "nom": nom}, "liste_agence", 1)
            if e:
                entrees.append(e)
            else:
                ecartes.add(s)
    n_lac_entrees = len(entrees)
    # --- niveau Etat : fiches poissons du Field Guide
    slugs = set()
    p = 0
    while p < 120:
        c, d = telecharger(f"{BASE}/wildlife/field-guide?page={p}")
        if c != 200:
            break
        t = d.decode("utf8", "ignore")
        nouveaux = set(re.findall(r'href="/wildlife/field-guide/fish/([a-z0-9\-]+)"', t)) - slugs
        slugs |= nouveaux
        if "pager__item--next" not in t and "Next page" not in t:
            break
        p += 1
    noms_poissons = []
    for s in sorted(slugs):
        c, d = telecharger(f"{BASE}/wildlife/field-guide/fish/{s}")
        if c != 200:
            continue
        n = parser_nom_poisson(d.decode("utf8", "ignore"))
        if n:
            noms_poissons.append(n)
    etat = []
    for n in noms_poissons:
        e = entree(n, {"type": "etat", "id": "OK", "nom": "Oklahoma"}, "liste_agence", 0)
        if e:
            etat.append(e)
        else:
            ecartes.add(n)
    path, taille = ecrire("OK", "agence", SOURCES, etat + entrees)
    print(path, taille, "octets ; fiches poissons:", len(noms_poissons), "; etat:", len(etat), "; plans d'eau:", n_lacs, "; entrees plan d'eau:", n_lac_entrees)
    print("ecartes (latin non resolu):", sorted(ecartes))


if __name__ == "__main__":
    main()
