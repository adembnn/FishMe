#!/usr/bin/env python3
"""US16 vague 2 : Illinois, producteur « agence » (IDNR, site iFish Illinois, robots.txt : Allow /).
Niveau État : page « Illinois Fish Species » (ifishillinois.org/FishSpecies).
Niveau plan d'eau : page de chaque plan d'eau (« Fishing Outlook » = enquêtes de pêche électrique ; « Recent Stocking History »).
On garde espèce + plan d'eau + année seulement ; ni jugement qualitatif du site, ni texte recopié.
Usage : python3 -I IL.py [--hors-ligne]   (bruts dans /private/tmp/claude-501/brut-us/especes/il/, hors git)
"""
import html, json, os, re, sys, time, urllib.request

UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
BASE = "https://ifishillinois.org"
DATE = "2026-11-08"
ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us", "IL-agence.json")
BRUT = "/private/tmp/claude-501/brut-us/especes/il"
TABLE = os.path.join(ICI, "..", "especes-us.json")

# Noms de l'agence absents de la table ou nommés autrement : (latin, slug ou None)
EXTRA = {
    "emerald bowfin": ("Amia ocellicauda", None),
    "black buffalo": ("Ictiobus niger", None),
    "pallid sturgeon": ("Scaphirhynchus albus", None),
    "northern sunfish": ("Lepomis peltastes", None),
    "shortnose gar": ("Lepisosteus platostomus", None),
    "walleye x sauger (saugeye)": ("Sander vitreus x Sander canadensis", "saugeye"),
    "saugeye": ("Sander vitreus x Sander canadensis", "saugeye"),
    "striped bass x white bass (wiper)": ("Morone chrysops x Morone saxatilis", "wiper"),
    "hybrid striped bass": ("Morone chrysops x Morone saxatilis", "wiper"),
    "wiper": ("Morone chrysops x Morone saxatilis", "wiper"),
    "muskie": ("Esox masquinongy", "muskellunge"),
    "tiger muskie": ("Esox masquinongy x Esox lucius", "tiger-muskie"),
}


def charger_table():
    d = json.load(open(TABLE, encoding="utf-8"))
    m = {re.sub(r" \(.*\)$", "", e["nom_en"]).lower(): (e["latin"], e["slug"]) for e in d}
    m.update(EXTRA)
    return m


def texte(h):
    h = re.sub(r"url\('data:[^']*'\)", "url()", h)
    h = re.sub(r"(?s)<(script|style).*?</\1>", "", h)
    h = re.sub(r"<[^>]+>", "\n", h)
    h = html.unescape(h)
    h = re.sub(r"[ \t\xa0]+", " ", h)
    return re.sub(r"\n\s*\n+", "\n", h)


def parse_especes_etat(h):
    h = re.sub(r"url\('data:[^']*'\)", "url()", h)
    seg = h[h.find("background-img-"):]
    return [html.unescape(n).strip() for n in re.findall(r"<p[^>]*>([^<]+)</p>", seg) if n.strip()]


def parse_plan_eau(h):
    """-> (nom, comté, [(espèce, annee_enquete|None)], [(espèce, annee_empoissonnement)])"""
    t = texte(h)
    m = re.search(r"Sign In\n([^\n]+)\n Back to", t)
    nom = m.group(1).strip() if m else None
    c = re.search(r"Info /\n?\s*([A-Za-z .'-]+ County)", t)
    comte = c.group(1).strip() if c else None
    enquete, stock = [], []
    i = t.find("Fishing Outlook")
    j = t.find("Recent Stocking History")
    if i >= 0:
        fin = j if j > i else i + 6000
        lignes = [x.strip() for x in t[i + len("Fishing Outlook"):fin].split("\n") if x.strip()]
        # structure : espèce / note qualitative (ignorée) / phrase
        k = 0
        while k + 2 < len(lignes):
            esp, phrase = lignes[k], lignes[k + 2]
            k += 3
            if re.match(r"No ", phrase) or re.search(r"\bwere not\b|not sampled|none were", phrase, re.I):
                continue
            if re.search(r"were (collected|sampled)|collected at|ranged from|measured|are present|were present|sampled in", phrase):
                a = re.search(r"\b(20\d\d|19\d\d)\b", re.split(r"(?<=[a-z\"”])\. ", phrase)[0])
                enquete.append((esp, int(a.group(1)) if a else None))
    if j >= 0:
        bloc = [x.strip() for x in t[j + len("Recent Stocking History"):].split("\n") if x.strip()]
        k = 0
        while k + 3 < len(bloc):
            if re.fullmatch(r"(19|20)\d\d", bloc[k]):
                stock.append((bloc[k + 1], int(bloc[k])))
                k += 4
            else:
                if bloc[k].startswith("Contact"):
                    break
                k += 1
    return nom, comte, enquete, stock


def get(url, nom, hors_ligne):
    os.makedirs(BRUT, exist_ok=True)
    p = os.path.join(BRUT, nom)
    if os.path.exists(p):
        return open(p, encoding="utf-8", errors="ignore").read()
    if hors_ligne:
        return None
    time.sleep(0.3)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    h = urllib.request.urlopen(req, timeout=40).read().decode("utf-8", "ignore")
    h = re.sub(r"url\('data:[^']*'\)", "url()", h)
    open(p, "w", encoding="utf-8").write(h)
    return h


def prechauffer(urls):
    """Télécharge en parallèle (4 fils) mais avec 0,3 s au moins entre deux départs de requête."""
    import threading
    from concurrent.futures import ThreadPoolExecutor
    verrou, dernier = threading.Lock(), [0.0]

    def un(u):
        p = os.path.join(BRUT, u.rsplit("/", 1)[1] + ".html")
        if os.path.exists(p):
            return
        with verrou:
            time.sleep(max(0, dernier[0] + 0.3 - time.time()))
            dernier[0] = time.time()
        try:
            h = urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": UA}), timeout=60).read().decode("utf-8", "ignore")
        except Exception:
            return
        open(p, "w", encoding="utf-8").write(re.sub(r"url\('data:[^']*'\)", "url()", h))
    os.makedirs(BRUT, exist_ok=True)
    with ThreadPoolExecutor(4) as ex:
        list(ex.map(un, urls))


def construire(hors_ligne=False):
    table = charger_table()
    sources = [{"nom": "IDNR, iFish Illinois : Illinois Fish Species", "url": BASE + "/FishSpecies", "licence": "non précisée", "date": DATE}]
    entrees, non_mappes = [], {}
    h = get(BASE + "/FishSpecies", "species.html", hors_ligne)
    for n in parse_especes_etat(h):
        if n.lower() not in table:
            non_mappes[n] = non_mappes.get(n, 0) + 1
            continue
        latin, slug = table[n.lower()]
        entrees.append({"slug": slug, "nom": n, "latin": latin, "zone": {"type": "etat", "id": "IL", "nom": "Illinois"},
                        "preuve": "liste_agence", "src": 0, "confiance": "officielle"})
    smap = get(BASE + "/sitemap.xml", "sitemap.xml", hors_ligne)
    urls = sorted(set(re.findall(r"<loc>(https://ifishillinois\.org/Waterbodies/Details/[0-9a-f-]+)</loc>", smap or "")))
    if not hors_ligne:
        prechauffer(urls)
    vus, nb_pages = {}, 0
    for u in urls:
        ph = get(u, u.rsplit("/", 1)[1] + ".html", hors_ligne)
        if not ph:
            continue
        nom, comte, enq, stk = parse_plan_eau(ph)
        if not nom:
            continue
        nb_pages += 1
        ident = nom if nom not in vus else f"{nom} ({comte})"
        vus[nom] = vus.get(nom, 0) + 1
        sources.append({"nom": f"IDNR, iFish Illinois : {nom}", "url": u, "licence": "non précisée", "date": DATE})
        si = len(sources) - 1
        par = {}
        for esp, an in enq:
            par[(esp, "enquete_peche_electrique")] = max(an or 0, par.get((esp, "enquete_peche_electrique"), 0))
        for esp, an in stk:
            par[(esp, "empoissonnement")] = max(an, par.get((esp, "empoissonnement"), 0))
        for (esp, preuve), an in sorted(par.items()):
            if esp.lower() not in table:
                non_mappes[esp] = non_mappes.get(esp, 0) + 1
                continue
            latin, slug = table[esp.lower()]
            e = {"slug": slug, "nom": esp, "latin": latin, "zone": {"type": "plan_eau", "id": ident, "nom": ident},
                 "preuve": preuve, "src": si, "confiance": "officielle"}
            if an:
                e["annee_max"] = an
            entrees.append(e)
    return {"format": "fishme-especes-us/1", "etat": "IL", "producteur": "agence", "date": DATE,
            "sources": sources, "entrees": entrees}, non_mappes, nb_pages


if __name__ == "__main__":
    d, nm, n = construire("--hors-ligne" in sys.argv)
    os.makedirs(os.path.dirname(SORTIE), exist_ok=True)
    json.dump(d, open(SORTIE, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print("plans d'eau lus", n, "entrées", len(d["entrees"]), "octets", os.path.getsize(SORTIE))
    print("noms non rapprochés (écartés) :", json.dumps(nm, ensure_ascii=False))
