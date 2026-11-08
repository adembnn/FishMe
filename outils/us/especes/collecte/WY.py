"""Wyoming : espèces signalées par l'agence (WGFD).
Niveau État : tableau « Fish of Wyoming » (colonne Game = espèces de pêche sportive).
Plan d'eau : rapport d'empoissonnement WGFD (formulaire public ASP.NET : une recherche par espèce, 2024 à 2026),
agrégé (espèce, eau, nombre de lâchers, année la plus récente).
Usage : python3 -I WY.py"""
import html as H, http.cookiejar, json, os, re, sys, time, urllib.parse, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun_esp9 as C

LISTE = "https://wgfd.wyo.gov/fishing-boating/fish-wyoming"
STOCK = "https://wgfapps.wyo.gov/FishStock/FishStock"
LIC = "non précisée"
GRID = "ctl00$MainContent$FishStockGrid$ctl00$ctl03$ctl01$ctl"
# nom latin « Micropterus nigricans » (page WGFD) = black-bass à grande bouche, nom valide M. salmoides (voir rapport)
CORRECTION_LATIN = {"Micropterus nigricans": "Micropterus salmoides"}


def especes_etat(html):
    x = C.texte_lignes(html)
    i = x.index("Scientific Name")
    rows, k = [], i
    while k < len(x) - 2:
        if x[k + 1] in ("Game", "Nongame") and x[k + 2][:1].isupper() and " " in x[k + 2]:
            rows.append((x[k], x[k + 1], x[k + 2])); k += 3
        else:
            k += 1
    return [r for r in rows if r[1] == "Game"]


def champs_caches(h):
    f = {}
    for m in re.finditer(r'<input[^>]*type="hidden"[^>]*>', h):
        n = re.search(r'name="([^"]+)"', m.group(0)); v = re.search(r'value="([^"]*)"', m.group(0))
        if n:
            f[n.group(1)] = H.unescape(v.group(1)) if v else ""
    return f


def lignes_tableau(h):
    """(date, espèce, nombre, longueur, eau, comté) des lignes de la grille."""
    out = []
    for tr in re.findall(r'<tr class="rg(?:Row|AltRow)"[^>]*>(.*?)</tr>', h, re.S):
        c = [H.unescape(re.sub(r"<[^>]+>", "", x)).replace("\xa0", " ").strip() for x in re.findall(r"<td[^>]*>(.*?)</td>", tr, re.S)]
        if len(c) >= 6:
            out.append(c[:6])
    return out


def recherche(especes):
    """Pour chaque (valeur, texte) : toutes les pages de résultats. Rend [(eau, espèce brute, année)]."""
    cj = http.cookiejar.CookieJar()
    op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    op.addheaders = [("User-Agent", C.UA)]
    base = op.open(STOCK, timeout=60).read().decode("utf-8", "ignore")
    res = []
    for val, txt in especes:
        f = champs_caches(base)
        f["ctl00$MainContent$Species"] = txt
        f["ctl00_MainContent_Species_ClientState"] = json.dumps({"logEntries": [], "value": val, "text": txt, "enabled": True, "checkedIndices": [], "checkedItemsTextOverflows": False})
        f["ctl00$MainContent$Search"] = "Search"
        h = op.open(urllib.request.Request(STOCK, data=urllib.parse.urlencode(f).encode()), timeout=90).read().decode("utf-8", "ignore")
        time.sleep(0.3)
        pages = 1
        m = re.search(r"in\s+(\d+)\s+pages", re.sub(r"<[^>]+>", " ", h))
        if m:
            pages = int(m.group(1))
        toutes = lignes_tableau(h)
        for p in range(2, pages + 1):
            g = champs_caches(h)
            g["__EVENTTARGET"] = GRID + f"{4 + p:02d}"
            g["__EVENTARGUMENT"] = ""
            g["ctl00$MainContent$Species"] = txt
            g["ctl00_MainContent_Species_ClientState"] = f["ctl00_MainContent_Species_ClientState"]
            h = op.open(urllib.request.Request(STOCK, data=urllib.parse.urlencode(g).encode()), timeout=90).read().decode("utf-8", "ignore")
            time.sleep(0.3)
            toutes += lignes_tableau(h)
        for c in toutes:
            an = re.search(r"(\d{4})", c[0])
            if an and c[1].upper() == txt.upper():
                res.append((c[4], c[1], int(an.group(1))))
        print(f"  {txt}: {len(toutes)} lignes ({pages} pages)", file=sys.stderr)
    return res, base


def liste_especes_formulaire(base):
    m = re.search(r'RadComboBox, \{[^}]*"_uniqueId":"ctl00\$MainContent\$Species".*?"itemData":\[(.*?)\]', base, re.S)
    vals = re.findall(r'"value":"([^"]+)"', m.group(1))
    t = C.texte_lignes(base)
    i = t.index("Species"); j = t.index("County")
    # les libellés des espèces suivent « Species select » dans la page
    return vals, t[i:j]


def main():
    sources = [
        {"nom": "Wyoming Game and Fish Department, Fish of Wyoming", "url": LISTE, "licence": LIC, "date": C.DATE},
        {"nom": "Wyoming Game and Fish Department, Fish Stocking Report", "url": STOCK, "licence": LIC, "date": C.DATE},
    ]
    h = C.lire(LISTE, "wy-fw.html")
    entrees = []
    for nom, _, latin in especes_etat(h):
        esp = C.trouver(nom)
        if not esp:
            esp = (None, nom, CORRECTION_LATIN.get(latin, latin))
        entrees.append(C.entree(esp, "etat", "WY", "Wyoming", "liste_agence", 0))
    n_etat = len(entrees)
    base = C.lire(STOCK, "wy-stock.html")
    vals, bloc = liste_especes_formulaire(base)
    libs = [l for l in bloc if l.isupper() and l not in ("SPECIES", "SELECT")]
    couples = [(v, l) for v, l in zip(vals, libs)]
    print(f"{len(couples)} espèces au formulaire", file=sys.stderr)
    lignes, _ = recherche(couples)
    eaux = C.agreger_empoissonnement(lignes, lambda s: C.trouver(s) or especes_hors_table(s), "WY", 1)
    entrees += eaux
    p, taille = C.ecrire("WY", "agence", sources, entrees)
    print(f"WY : {n_etat} espèces (État), {len(eaux)} entrées plan d'eau, {taille} octets")


HORS_TABLE = {
    "bear river cutthroat": "cutthroat",
    "colorado river cutthroat": "cutthroat",
    "snake river cutthroat": "cutthroat",
    "yellowstone cutthroat": "cutthroat",
    "gsf x blg hybrid": "hybrid sunfish",
    "tiger trout (bkt x bnt)": "tiger trout",
    "kokanee salmon": "kokanee",
    "grayling": "arctic grayling",
}


def especes_hors_table(s):
    k = s.lower()
    if k in HORS_TABLE:
        return C.trouver(HORS_TABLE[k])
    return {"gizzard shad": (None, "Gizzard shad", "Dorosoma cepedianum"),
            "temiscamie": (None, "Temiscamie (arctic char x brook trout)", "Salvelinus alpinus x Salvelinus fontinalis"),
            "brook x temiscamie": (None, "Brook trout x temiscamie", "Salvelinus fontinalis x Salvelinus alpinus"),
            "temiscamie brook": (None, "Temiscamie x brook trout", "Salvelinus alpinus x Salvelinus fontinalis"),
            "splake": C.trouver("splake"),
            }.get(k)


if __name__ == "__main__":
    main()
