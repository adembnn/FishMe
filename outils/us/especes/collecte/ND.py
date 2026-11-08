"""ND : North Dakota Game and Fish. Niveau Etat (liste officielle des especes) + plans d'eau (appli « Where to Fish », champ « Sport Fish »).

Usage : python3 -I ND.py   (reseau ; bruts dans /private/tmp/claude-501/brut-us/especes/esp-7/)
Les fonctions parser_* sont testees sur fixtures (tests/test_collecte_esp7.py)."""
import html
import os
import re
import sys
import time
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _commun import DATE, ecrire, entree  # noqa: E402
from _http import UA, telecharger  # noqa: E402

BRUT = "/private/tmp/claude-501/brut-us/especes/esp-7"
URL_LISTE = "https://gf.nd.gov/wildlife/id/fish/state-list"
URL_APPLI = "https://gfappspublic.nd.gov/wheretofish/Search.aspx"
URL_LAC = "https://gfappspublic.nd.gov/wheretofish/LakeDetail.aspx?Lake="
SOURCES = [
    {"nom": "ND Game and Fish, Current North Dakota Fish Species Listing", "url": URL_LISTE,
     "licence": "non précisée", "date": DATE},
    {"nom": "ND Game and Fish, Where to Fish (fiches de plans d'eau, champ Sport Fish)", "url": URL_APPLI,
     "licence": "non précisée", "date": DATE},
]


def parser_liste_etat(page):
    """Texte de la page -> liste de noms communs (sans le statut natif/non natif)."""
    t = re.sub(r"(?s)<(script|style).*?</\1>", "", page)
    t = html.unescape(re.sub(r"<[^>]+>", "\n", t))
    return [m.group(1).strip() for m in re.finditer(r"^\s*([A-Z][A-Za-z' \-]+?) \((?:Native|Nonnative)\)\s*$", t, flags=re.M)]


def parser_lac(page):
    """Page LakeDetail -> (nom du plan d'eau, [especes])."""
    m = re.search(r'id="ctl00_lblLakeName"[^>]*>([^<]+)<', page)
    f = re.search(r'id="ctl00_lblFishSpecies"[^>]*>([^<]*)<', page)
    nom = html.unescape(m.group(1)).strip() if m else None
    esp = [x.strip() for x in html.unescape(f.group(1)).split(",") if x.strip()] if f else []
    return nom, esp


def codes_lacs(page):
    """Page de resultats de l'appli -> {code: nom}. Les coordonnees presentes dans la page ne sont jamais gardees."""
    pairs = re.findall(r'Name:\s+"([^"]+?)"[^}]*?LakeCode:\s*"(\d+)"', page, flags=re.S)
    return {c: n.split(" - ")[0].strip() for n, c in pairs}


def _post(page, cible):
    h = {m.group(1): m.group(2) for m in re.finditer(r'<input type="hidden" name="([^"]+)" id="[^"]*" value="([^"]*)"', page)}
    h["__EVENTTARGET"], h["__EVENTARGUMENT"] = cible, ""
    time.sleep(0.3)
    req = urllib.request.Request(URL_APPLI, data=urllib.parse.urlencode(h).encode(), headers={"User-Agent": UA})
    return urllib.request.urlopen(req, timeout=90).read().decode("utf8", "ignore")


def main():
    os.makedirs(BRUT, exist_ok=True)
    entrees, ecartes = [], set()
    c, d = telecharger(URL_LISTE)
    assert c == 200, c
    open(os.path.join(BRUT, "nd.html"), "wb").write(d)
    noms = parser_liste_etat(d.decode("utf8", "ignore"))
    for n in noms:
        e = entree(n, {"type": "etat", "id": "ND", "nom": "North Dakota"}, "liste_agence", 0)
        if e:
            entrees.append(e)
        else:
            ecartes.add(n)
    n_etat = len(entrees)
    c, d = telecharger(URL_APPLI)
    page = d.decode("utf8", "ignore")
    res = _post(page, "ctl00$ContentPlaceHolder1$lbAllLakes")
    open(os.path.join(BRUT, "ndall.html"), "w").write(res)
    lacs = codes_lacs(res)
    n_lacs = 0
    for code in sorted(lacs):
        c, d = telecharger(URL_LAC + code)
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
    p, taille = ecrire("ND", "agence", SOURCES, entrees)
    print(p, taille, "octets ; etat:", n_etat, "; plans d'eau avec liste:", n_lacs, "; entrees plan d'eau:", len(entrees) - n_etat)
    print("ecartes (latin non resolu):", sorted(ecartes))


if __name__ == "__main__":
    main()
