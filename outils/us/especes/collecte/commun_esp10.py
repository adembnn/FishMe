"""US16 vague 2, groupe esp-10 : outils communs (lecture polie, écriture des fichiers fishme-especes-us/1)."""
import html, json, os, re, time, urllib.error, urllib.request

UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
BRUT = "/private/tmp/claude-501/brut-us/especes/"
ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, "..", "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
DATE = "2026-11-08"


def lire(url, cle):
    """Télécharge avec pause de 0,3 s ; (code, html). Brut gardé hors git."""
    os.makedirs(BRUT, exist_ok=True)
    if cle.startswith("nas-") and os.path.exists(BRUT + cle + ".html") and os.path.getsize(BRUT + cle + ".html") > 0:
        return 200, open(BRUT + cle + ".html").read()  # brut déjà lu (relance)
    try:
        r = urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA}), timeout=30)
        b, c = r.read().decode("utf-8", "ignore"), r.status
    except urllib.error.HTTPError as e:
        b, c = "", e.code
    except Exception:
        b, c = "", 0
    open(BRUT + cle + ".html", "w").write(b)
    time.sleep(0.3)
    return c, b


def texte(h):
    t = re.sub(r"<(script|style)[\s\S]*?</\1>", "", h)
    t = html.unescape(re.sub(r"<[^>]+>", "\n", t))
    return re.sub(r"\n\s*\n+", "\n", t)


def slugs_latin():
    d = json.load(open(os.path.join(ICI, "..", "especes-us.json")))
    return {e["latin"].lower(): e["slug"] for e in d}


def slug_de(latin, nom=""):
    s = slugs_latin()
    l = latin.lower()
    if l in s:
        return s[l]
    return None


def ecrire(usps, producteur, sources, entrees):
    os.makedirs(SORTIE, exist_ok=True)
    d = {"format": "fishme-especes-us/1", "etat": usps, "producteur": producteur, "date": DATE,
         "sources": sources, "entrees": entrees}
    p = os.path.join(SORTIE, f"{usps}-{producteur}.json")
    with open(p, "w") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return p


def entree(nom, latin, zone, preuve, src, confiance="officielle", **kw):
    e = {"slug": slug_de(latin), "nom": nom, "latin": latin, "zone": zone, "preuve": preuve, "src": src, "confiance": confiance}
    e.update({k: v for k, v in kw.items() if v is not None})
    return e


def zone_etat(usps, nom):
    return {"type": "etat", "id": usps, "nom": nom}


# --- WDFW : pages d'espèce avec « Lakes where this species may be found » ---
def lacs_wdfw(h):
    i = h.find("Lakes where this species may be found")
    if i < 0:
        return []
    h = h[i:]
    j = h.find("accordion-item")
    h = h[:j] if j > 0 else h
    return sorted(set(html.unescape(x).strip() for x in re.findall(r'href="/fishing/locations/lowland-lakes/[^"]+"[^>]*>([^<]+)<', h)))


# --- NAS ---
def nas_fishes(usps):
    """Occurrences NAS de poissons (non indigènes) d'un État : agrégées par espèce et HUC8."""
    agg = {}
    off = 0
    while True:
        u = f"https://nas.er.usgs.gov/api/v2/occurrence/search?state={usps}&group=Fishes&limit=500&offset={off}"
        c, b = lire(u, f"nas-{usps}-{off}")
        if c != 200:
            return None
        d = json.loads(b)
        for r in d.get("results", []):
            if r.get("group") != "Fishes" and "Fish" not in str(r.get("group")):
                continue
            k = (r["scientificName"], r.get("commonName", ""), str(r.get("huc8") or ""))
            a = agg.setdefault(k, [0, 0])
            a[0] += 1
            a[1] = max(a[1], r.get("year") or 0)
        if d.get("endOfRecords") in (True, "true") or not d.get("results"):
            break
        off += 500
    return agg


def fichier_nas(usps, agg, nom_etat):
    sources = [{"nom": "USGS Nonindigenous Aquatic Species (NAS) database, occurrences de poissons non indigènes",
                "url": f"https://nas.er.usgs.gov/api/v2/occurrence/search?state={usps}&group=Fishes",
                "licence": "domaine public fédéral", "date": DATE}]
    huc, tot = [], {}
    for (lat, com, h), (n, an) in sorted(agg.items()):
        t = tot.setdefault((lat, com), [0, 0])
        t[0] += n
        t[1] = max(t[1], an)
        if re.fullmatch(r"\d{8}", h):
            huc.append(entree(com or lat, lat, {"type": "huc8", "id": h}, "nas", 0, "enregistrement_scientifique", n=n, annee_max=an or None))
    etat = [entree(com or lat, lat, zone_etat(usps, nom_etat), "nas", 0, "enregistrement_scientifique", n=n, annee_max=an or None)
            for (lat, com), (n, an) in sorted(tot.items())]
    # plafond 400 Ko : on retire d'abord les lignes HUC8 des espèces hors table (slug null), puis les moins documentées
    huc.sort(key=lambda e: (e["slug"] is None, -e.get("n", 0)))
    while huc and len(json.dumps(etat + huc, ensure_ascii=False, separators=(",", ":"))) > 380000:
        huc.pop()
    return ecrire(usps, "nas", sources, etat + huc), len(etat), len(huc)
