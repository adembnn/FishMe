#!/usr/bin/env python3
"""US16 : poissons signalés par État puis par bassin HUC8, d'après les occurrences GBIF (Python stdlib seulement).

Ce que fait le script
- État : occurrences GBIF avec country=US et gadmGid de l'État (limites GADM, plus fiables que le texte libre stateProvince).
- HUC8 : appartenance par polygone WKT (service ArcGIS « WBD » couche 4 de hydro.nationalmap.gov, simplifié) passé dans `geometry`.
  Un HUC8 écrit dans CHAQUE État de son champ `states` (HUC8 à cheval sur deux États : deux fichiers).
- Filtres GBIF : occurrenceStatus=PRESENT, hasGeospatialIssue=false, licences CC0_1_0 et CC_BY_4_0 SEULEMENT (CC BY NC et
  « non précisée » exclues par le filtre), basisOfRecord observation / spécimen conservé / échantillon (fossiles et animaux
  en captivité exclus), familles de la liste blanche ci-dessous. JAMAIS iNaturalist directement : seulement les enregistrements
  qui passent par GBIF avec ces licences.
- Agrégation par facette `speciesKey` (aucune pagination d'occurrences). `annee_max` exacte : recherche descendante par tranches
  d'années puis dichotomie (la facette ne donne pas de maximum).
- Aucune coordonnée n'est écrite dans les sorties.

Liste blanche (poissons d'eau douce ou diadromes utiles à un pêcheur ; tout le reste est écarté et compté dans le rapport)
- Familles prises entières : Centrarchidae (sauf Enneacanthus), Ictaluridae (sauf Noturus et genres de grotte), Salmonidae,
  Esocidae, Moronidae, Lepisosteidae, Amiidae, Acipenseridae, Polyodontidae, Catostomidae, Hiodontidae, Anguillidae, Cichlidae,
  Osmeridae, Thymallidae, Coregonidae, Percopsidae, Channidae, Clariidae.
- Familles à genres choisis : Percidae (Sander, Perca seulement : darters écartés), Sciaenidae (Aplodinotus seulement),
  Lotidae/Gadidae (Lota seulement), Clupeidae (Dorosoma, Alosa : shads, alewife, herring d'eau douce ou migrateurs ; menhaden et
  harengs marins écartés), Cyprinidae / Leuciscidae / Xenocyprididae / Tincidae (carpes, carassins, amours, tanche, gardons de
  pêche : Cyprinus, Carassius, Ctenopharyngodon, Hypophthalmichthys, Mylopharyngodon, Aristichthys, Notemigonus, Tinca,
  Scardinius, Rutilus, Leuciscus, Ptychocheilus ; petits cyprins/méné écartés).
- Tout poisson marin (hors migrateurs ci-dessus) est écarté par construction : ses familles ne sont pas dans la liste.

Seuils : au moins 2 enregistrements par entrée (État et HUC8), relevable avec --seuil.
Cache des réponses brutes hors dépôt : /private/tmp/claude-501/brut-us/gbif/. Pause >= 0,25 s entre requêtes réseau.

Usage : python3 gbif_zones.py [--etats WI,MN] [--sans-huc8] [--workers 4] [--plafond 60000] [--seuil 2] [--sortie DOSSIER]
"""
import argparse, hashlib, json, os, re, sys, threading, time
import urllib.error, urllib.parse, urllib.request

ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE_DEFAUT = os.path.join(ICI, "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "especes-us")
CACHE_DEFAUT = "/private/tmp/claude-501/brut-us/gbif"
DATE_JOUR = "2026-11-07"
UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
GBIF = "https://api.gbif.org/v1"
WBD = "https://hydro.nationalmap.gov/arcgis/rest/services/wbd/MapServer/4/query"
PAUSE = 0.25
LICENCES = ["CC0_1_0", "CC_BY_4_0"]
BASES = ["HUMAN_OBSERVATION", "OBSERVATION", "PRESERVED_SPECIMEN", "MACHINE_OBSERVATION", "MATERIAL_SAMPLE", "OCCURRENCE", "MATERIAL_CITATION"]
FACET_LIMIT = 1000
INTERDITS = re.compile(r"autoris|allowed|\blegal\b|tu peux la garder|you can keep|rare|uncommon|légendaire", re.I)

ETATS = {"AL": "Alabama", "AK": "Alaska", "AZ": "Arizona", "AR": "Arkansas", "CA": "California", "CO": "Colorado",
         "CT": "Connecticut", "DE": "Delaware", "DC": "District of Columbia", "FL": "Florida", "GA": "Georgia", "HI": "Hawaii",
         "ID": "Idaho", "IL": "Illinois", "IN": "Indiana", "IA": "Iowa", "KS": "Kansas", "KY": "Kentucky", "LA": "Louisiana",
         "ME": "Maine", "MD": "Maryland", "MA": "Massachusetts", "MI": "Michigan", "MN": "Minnesota", "MS": "Mississippi",
         "MO": "Missouri", "MT": "Montana", "NE": "Nebraska", "NV": "Nevada", "NH": "New Hampshire", "NJ": "New Jersey",
         "NM": "New Mexico", "NY": "New York", "NC": "North Carolina", "ND": "North Dakota", "OH": "Ohio", "OK": "Oklahoma",
         "OR": "Oregon", "PA": "Pennsylvania", "RI": "Rhode Island", "SC": "South Carolina", "SD": "South Dakota",
         "TN": "Tennessee", "TX": "Texas", "UT": "Utah", "VT": "Vermont", "VA": "Virginia", "WA": "Washington",
         "WV": "West Virginia", "WI": "Wisconsin", "WY": "Wyoming"}

# famille -> espèce représentative (le backbone GBIF actuel ne rend pas toujours la famille par son nom ; la clé vient d'une espèce)
FAMILLES_REPRESENTANTS = {
    "Centrarchidae": "Micropterus salmoides", "Percidae": "Sander vitreus", "Ictaluridae": "Ictalurus punctatus",
    "Salmonidae": "Oncorhynchus mykiss", "Esocidae": "Esox lucius", "Moronidae": "Morone saxatilis",
    "Sciaenidae": "Aplodinotus grunniens", "Lepisosteidae": "Lepisosteus osseus", "Amiidae": "Amia calva",
    "Acipenseridae": "Acipenser fulvescens", "Polyodontidae": "Polyodon spathula", "Catostomidae": "Catostomus commersonii",
    "Cyprinidae": "Cyprinus carpio", "Leuciscidae": "Notemigonus crysoleucas", "Xenocyprididae": "Ctenopharyngodon idella",
    "Tincidae": "Tinca tinca", "Clupeidae": "Dorosoma cepedianum", "Hiodontidae": "Hiodon alosoides",
    "Anguillidae": "Anguilla rostrata", "Cichlidae": "Oreochromis niloticus", "Osmeridae": "Osmerus mordax",
    "Thymallidae": "Thymallus arcticus", "Coregonidae": "Coregonus clupeaformis", "Percopsidae": "Percopsis omiscomaycus",
    "Lotidae": "Lota lota", "Gadidae": "Gadus morhua", "Channidae": "Channa argus", "Clariidae": "Clarias batrachus",
}
# famille -> None (entière) ou ensemble de genres exclus ("-") ; familles à genres choisis ("+")
FAMILLES_ENTIERES = {"Centrarchidae": {"Enneacanthus"}, "Ictaluridae": {"Noturus", "Satan", "Prietella", "Trogloglanis"},
                     "Salmonidae": set(), "Esocidae": set(), "Moronidae": set(), "Lepisosteidae": set(), "Amiidae": set(),
                     "Acipenseridae": set(), "Polyodontidae": set(), "Catostomidae": set(), "Hiodontidae": set(),
                     "Anguillidae": set(), "Cichlidae": set(), "Osmeridae": set(), "Thymallidae": set(), "Coregonidae": set(),
                     "Percopsidae": set(), "Channidae": set(), "Clariidae": set()}
GENRES_CARPES = {"Cyprinus", "Carassius", "Ctenopharyngodon", "Hypophthalmichthys", "Mylopharyngodon", "Aristichthys",
                 "Notemigonus", "Tinca", "Scardinius", "Rutilus", "Leuciscus", "Ptychocheilus"}
FAMILLES_PAR_GENRE = {"Percidae": {"Sander", "Perca", "Stizostedion"}, "Sciaenidae": {"Aplodinotus"}, "Lotidae": {"Lota"},
                      "Gadidae": {"Lota"}, "Clupeidae": {"Dorosoma", "Alosa"}, "Cyprinidae": GENRES_CARPES,
                      "Leuciscidae": GENRES_CARPES, "Xenocyprididae": GENRES_CARPES, "Tincidae": GENRES_CARPES}
# familles interrogées chez GBIF : Gadidae n'est qu'un représentant marin, on ne l'interroge pas (Lota est en Lotidae)
FAMILLES_INTERROGEES = [f for f in FAMILLES_REPRESENTANTS if f != "Gadidae"]


def famille_retenue(famille, genre):
    """Vrai si (famille, genre) est dans la liste blanche."""
    if famille in FAMILLES_ENTIERES:
        return genre not in FAMILLES_ENTIERES[famille]
    if famille in FAMILLES_PAR_GENRE:
        return genre in FAMILLES_PAR_GENRE[famille]
    return False


# ---------------------------------------------------------------- réseau et cache

class Client:
    """Requêtes GET avec cache disque, pause globale, reprise sur 429/5xx, plafond de requêtes réseau."""

    def __init__(self, cache=CACHE_DEFAUT, plafond=60000, pause=PAUSE):
        self.cache, self.plafond, self.pause = cache, plafond, pause
        self.n_reseau = 0
        self.n_cache = 0
        self._verrou = threading.Lock()
        self._dernier = 0.0
        os.makedirs(cache, exist_ok=True)

    def _chemin(self, url):
        return os.path.join(self.cache, hashlib.sha1(url.encode()).hexdigest() + ".json")

    def json(self, url):
        p = self._chemin(url)
        if os.path.exists(p):
            with self._verrou:
                self.n_cache += 1
            with open(p, encoding="utf-8") as f:
                return json.load(f)
        d = self._reseau(url)
        tmp = p + f".{threading.get_ident()}.tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(d, f)
        os.replace(tmp, p)
        return d

    def _reseau(self, url):
        delai = 2.0
        for essai in range(7):
            with self._verrou:
                if self.n_reseau >= self.plafond:
                    raise RuntimeError(f"plafond de {self.plafond} requêtes réseau atteint")
                attente = self._dernier + self.pause - time.monotonic()
                if attente > 0:
                    time.sleep(attente)
                self._dernier = time.monotonic()
                self.n_reseau += 1
            try:
                req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
                with urllib.request.urlopen(req, timeout=90) as r:
                    return json.loads(r.read().decode("utf-8"))
            except urllib.error.HTTPError as e:
                if e.code == 429 or e.code >= 500:
                    time.sleep(delai)
                    delai = min(delai * 2, 60)
                    continue
                raise
            except (urllib.error.URLError, TimeoutError, ConnectionError):
                time.sleep(delai)
                delai = min(delai * 2, 60)
        raise RuntimeError(f"échec réseau répété : {url[:160]}")


# ---------------------------------------------------------------- GBIF : requêtes et analyse

def parametres_base(cles_familles, gadm=None, wkt=None):
    p = [("country", "US"), ("occurrenceStatus", "PRESENT"), ("hasGeospatialIssue", "false")]
    p += [("license", x) for x in LICENCES]
    p += [("basisOfRecord", x) for x in BASES]
    p += [("familyKey", str(k)) for k in cles_familles]
    if gadm:
        p.append(("gadmGid", gadm))
    if wkt:
        p.append(("geometry", wkt))
    return p


def url_facette(base, annees=None):
    """URL de comptage par speciesKey ; annees = (debut, fin) pour une tranche d'années."""
    p = list(base) + [("limit", "0"), ("facet", "speciesKey"), ("facetLimit", str(FACET_LIMIT))]
    if annees:
        p.append(("year", f"{annees[0]},{annees[1]}"))
    return f"{GBIF}/occurrence/search?" + urllib.parse.urlencode(p, quote_via=urllib.parse.quote)


def analyser_facettes(rep):
    """Réponse GBIF -> {speciesKey: nombre}. Lève ValueError si la facette est absente ; {} si la zone est vide."""
    if not isinstance(rep, dict) or "facets" not in rep:
        raise ValueError("réponse sans facettes")
    out = {}
    for f in rep["facets"]:
        if f.get("field") == "SPECIES_KEY":
            for c in f.get("counts", []):
                out[int(c["name"])] = int(c["count"])
    return out


class Comptage:
    """Compteur par zone : total par espèce, puis année maximale exacte par dichotomie sur les années."""

    BANDES = [(2025, 2026), (2023, 2024), (2020, 2022), (2015, 2019), (2005, 2014), (1990, 2004), (1900, 1989)]
    BANDES_BUDGET = [(2022, 2026), (2012, 2021), (1900, 2011)]  # tranches plus larges quand le nombre de requêtes est limité

    def __init__(self, client, base, budget=None):
        """budget = nombre maximal de requêtes par tranche d'années pour la zone (None : exact pour toutes les espèces).
        Quand il est épuisé, les espèces non résolues n'ont PAS d'annee_max (jamais estimée)."""
        self.client, self.base, self.budget = client, base, budget
        self.saturee = False

    class _Epuise(Exception):
        pass

    def _compte(self, annees=None):
        if annees and self.budget is not None:
            if self.budget <= 0:
                raise Comptage._Epuise()
            self.budget -= 1
        c = analyser_facettes(self.client.json(url_facette(self.base, annees)))
        if len(c) >= FACET_LIMIT:
            self.saturee = True
        return c

    def totaux(self):
        return self._compte()

    def annees_max(self, especes):
        """{speciesKey: année du plus récent enregistrement} pour les espèces demandées (aucune estimation : ce qui n'a pas
        d'année reste absent du résultat)."""
        restant, res = set(especes), {}
        try:
            for debut, fin in (self.BANDES if self.budget is None else self.BANDES_BUDGET):
                if not restant:
                    break
                trouvees = restant & set(self._compte((debut, fin)))
                if trouvees:
                    self._raffiner(debut, fin, trouvees, res)
                    restant -= trouvees
        except Comptage._Epuise:
            pass
        return res

    def _raffiner(self, debut, fin, especes, res):
        if not especes:
            return
        if debut == fin:
            for e in especes:
                res[e] = debut
            return
        milieu = (debut + fin) // 2
        haut = especes & set(self._compte((milieu + 1, fin)))
        self._raffiner(milieu + 1, fin, haut, res)
        self._raffiner(debut, milieu, especes - haut, res)


# ---------------------------------------------------------------- polygones WBD

def aire_signee(anneau):
    s = 0.0
    for (x1, y1), (x2, y2) in zip(anneau, anneau[1:] + anneau[:1]):
        s += x1 * y2 - x2 * y1
    return s / 2


def _dist_seg(p, a, b):
    (px, py), (ax, ay), (bx, by) = p, a, b
    dx, dy = bx - ax, by - ay
    if dx == dy == 0:
        return ((px - ax) ** 2 + (py - ay) ** 2) ** 0.5
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return ((px - ax - t * dx) ** 2 + (py - ay - t * dy) ** 2) ** 0.5


def douglas_peucker(pts, tol):
    if len(pts) < 3:
        return pts
    garde = [False] * len(pts)
    garde[0] = garde[-1] = True
    pile = [(0, len(pts) - 1)]
    while pile:
        i, j = pile.pop()
        dmax, k = 0.0, None
        for m in range(i + 1, j):
            d = _dist_seg(pts[m], pts[i], pts[j])
            if d > dmax:
                dmax, k = d, m
        if k is not None and dmax > tol:
            garde[k] = True
            pile += [(i, k), (k, j)]
    return [p for p, g in zip(pts, garde) if g]


def simplifier_anneau(anneau, max_sommets):
    """Anneau ouvert (sans point final répété) -> anneau simplifié d'au plus max_sommets sommets."""
    tol = 0.0005
    pts = anneau
    while len(pts) > max_sommets:
        pts = douglas_peucker(anneau + [anneau[0]], tol)[:-1]
        tol *= 1.5
    return pts


def point_dans_anneau(pt, anneau):
    x, y = pt
    dedans = False
    for (x1, y1), (x2, y2) in zip(anneau, anneau[1:] + anneau[:1]):
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            dedans = not dedans
    return dedans


def rings_vers_wkt(rings, max_sommets=140, aire_min=0.0004):
    """Anneaux ArcGIS (extérieurs horaires, trous antihoraires) -> MULTIPOLYGON WKT (extérieur antihoraire, trous horaires).
    Les îlots de moins de aire_min degrés carrés (~4 km²) sont ignorés quand il reste un autre anneau."""
    anneaux = []
    for r in rings:
        pts = [(float(x), float(y)) for x, y in r]
        if len(pts) > 1 and pts[0] == pts[-1]:
            pts = pts[:-1]
        if len(pts) >= 3:
            anneaux.append(pts)
    ext = [a for a in anneaux if aire_signee(a) < 0]
    trous = [a for a in anneaux if aire_signee(a) >= 0]
    if not ext:  # sécurité : tout est dans l'autre sens
        ext, trous = anneaux, []
    ext.sort(key=lambda a: -abs(aire_signee(a)))
    gardes = [a for a in ext if abs(aire_signee(a)) >= aire_min] or ext[:1]
    budget = max(8, max_sommets // len(gardes))
    polys = []
    for a in gardes:
        a = simplifier_anneau(a, budget)
        if aire_signee(a) < 0:
            a = a[::-1]  # antihoraire
        mes_trous = []
        for t in trous:
            if point_dans_anneau(t[0], a) and abs(aire_signee(t)) >= aire_min:
                t = simplifier_anneau(t, max(6, budget // 4))
                if aire_signee(t) > 0:
                    t = t[::-1]  # horaire
                mes_trous.append(t)
        polys.append([a] + mes_trous)

    def fmt(r):
        return "(" + ",".join(f"{x:.4f} {y:.4f}" for x, y in r + [r[0]]) + ")"

    return "MULTIPOLYGON(" + ",".join("(" + ",".join(fmt(r) for r in p) + ")" for p in polys) + ")"


def etats_du_huc8(champ_states):
    """'WI,MI,CN' -> ['MI', 'WI'] : seulement les 50 États et DC."""
    return sorted({s.strip().upper() for s in str(champ_states or "").split(",") if s.strip().upper() in ETATS})


# ---------------------------------------------------------------- espèces

def charger_table_us():
    with open(os.path.join(ICI, "especes-us.json"), encoding="utf-8") as f:
        return {e["latin"].strip().lower(): e for e in json.load(f)}


def resoudre_famille_cles(client, familles=None):
    """{famille: familyKey} via une espèce représentative. Le backbone GBIF actuel range certaines familles sous un autre nom
    (Leuciscidae, Xenocyprididae, Tincidae sous Cyprinidae ; Thymallidae, Coregonidae sous Salmonidae) : on garde la famille que
    GBIF rapporte pour l'espèce (clé non nulle), et une famille rapportée hors liste blanche est signalée (None)."""
    out = {}
    for fam in familles or FAMILLES_INTERROGEES:
        rep = client.json(f"{GBIF}/species/match?" + urllib.parse.urlencode({"name": FAMILLES_REPRESENTANTS[fam]}))
        reelle = rep.get("family")
        if rep.get("familyKey") and (reelle in FAMILLES_ENTIERES or reelle in FAMILLES_PAR_GENRE):
            out[reelle] = rep["familyKey"]
        else:
            out.setdefault(fam, None)
    return {f: k for f, k in out.items() if k or not any(v == f for v in out)}


def info_espece(client, cle):
    d = client.json(f"{GBIF}/species/{cle}")
    return {"latin": d.get("canonicalName") or d.get("species") or "", "famille": d.get("family") or "", "genre": d.get("genus") or "",
            "rang": d.get("rank"), "statut": d.get("taxonomicStatus")}


def nom_anglais(client, cle):
    rep = client.json(f"{GBIF}/species/{cle}/vernacularNames?limit=200")
    noms = [v["vernacularName"] for v in rep.get("results", []) if v.get("language") == "eng" and v.get("vernacularName")]
    if not noms:
        return None
    from collections import Counter
    freq = Counter(n.strip() for n in noms if "(" not in n and n.strip())
    if not freq:
        return None
    nom = sorted(freq, key=lambda n: (-freq[n], -len(n), n))[0]  # le plus répété, puis le plus précis
    return nom[:1].upper() + nom[1:]


def entree_espece(client, cle, table_us, cache_infos):
    """Informations d'une espèce retenue, ou None si elle est écartée (liste blanche, rang, mot interdit)."""
    if cle not in cache_infos:
        i = info_espece(client, cle)
        i["retenue"] = bool(i["latin"]) and i["rang"] == "SPECIES" and famille_retenue(i["famille"], i["genre"])
        if i["retenue"]:
            ref = table_us.get(i["latin"].lower())
            i["slug"] = ref["slug"] if ref else None
            i["nom"] = ref["nom_en"] if ref else (nom_anglais(client, cle) or i["latin"])
            if INTERDITS.search(i["nom"]):
                i["nom"] = i["latin"]
            if INTERDITS.search(i["latin"]):
                i["retenue"] = False
        cache_infos[cle] = i
    return cache_infos[cle] if cache_infos[cle]["retenue"] else None


# ---------------------------------------------------------------- orchestration

def garder(totaux, seuil):
    return {k: n for k, n in totaux.items() if n >= seuil}


def zone_entrees(client, base, seuil, table_us, cache_infos, stats, zone, budget=None):
    """Entrées (sans le champ src) d'une zone : espèces retenues, au moins `seuil` enregistrements, annee_max exacte."""
    comptage = Comptage(client, base, budget)
    totaux = comptage.totaux()
    stats["facettes_totales"] += len(totaux)
    infos = {}
    for k, n in garder(totaux, seuil).items():
        i = entree_espece(client, k, table_us, cache_infos)
        if i:
            infos[k] = i
    stats["ecartees_liste_blanche"] += sum(1 for k in totaux if k not in infos and totaux[k] >= seuil)
    annees = comptage.annees_max(set(infos))
    if comptage.saturee:
        stats["saturees"].append(zone["id"])
    out = []
    for k, i in infos.items():
        e = {"slug": i["slug"], "nom": i["nom"], "latin": i["latin"], "zone": zone, "preuve": "occurrence_gbif", "n": totaux[k]}
        if k in annees:
            e["annee_max"] = annees[k]
        else:
            stats["sans_annee"] += 1  # budget épuisé : champ absent, jamais estimé
        out.append(e)
    out.sort(key=lambda e: (e["latin"]))
    return out


def sources_gbif(cles_familles, gadm_exemple):
    qs = urllib.parse.urlencode(
        [(a, b) for a, b in parametres_base(cles_familles) if a != "license"]
        + [("license", x) for x in LICENCES] + [("facet", "speciesKey")], quote_via=urllib.parse.quote)
    jeu = ("Occurrences GBIF agrégées par espèce : country=US, occurrenceStatus=PRESENT, hasGeospatialIssue=false, licences CC0_1_0 "
           "et CC_BY_4_0 seulement (mélange ; CC-BY-4.0 indiquée par prudence pour l'attribution), basisOfRecord observation, "
           "spécimen conservé ou échantillon (ni fossile ni animal en captivité), familles de pêche d'eau douce ou diadromes "
           "(liste blanche de gbif_zones.py), au moins 2 enregistrements par entrée")
    base_url = f"{GBIF}/occurrence/search?{qs}"
    return [
        {"nom": "GBIF.org (2026-11-07), GBIF Occurrence Data, niveau État (limites GADM)", "url": base_url + "&gadmGid=" + gadm_exemple,
         "licence": "CC-BY-4.0", "date": DATE_JOUR, "jeu": jeu},
        {"nom": "GBIF.org (2026-11-07), GBIF Occurrence Data, niveau bassin HUC8 (polygones USGS WBD)",
         "url": base_url + "&geometry=POLYGONE_WKT_DU_HUC8", "licence": "CC-BY-4.0", "date": DATE_JOUR, "jeu": jeu},
    ]


def fichier_etat(usps, entrees_etat, entrees_huc, srcs):
    ent = []
    for e in entrees_etat:
        ent.append(dict(e, src=0, confiance="enregistrement_scientifique"))
    for e in entrees_huc:
        ent.append(dict(e, src=1, confiance="enregistrement_scientifique"))
    return {"format": "fishme-especes-us/1", "etat": usps, "producteur": "gbif", "date": DATE_JOUR, "sources": srcs, "entrees": ent}


def ecrire(dossier, usps, d):
    os.makedirs(dossier, exist_ok=True)
    chemin = os.path.join(dossier, f"{usps}-gbif.json")
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")
    return os.path.getsize(chemin)


def gids_etats(client):
    """{USPS: gadmGid} par un enregistrement GBIF de chaque État (champ gadm.level1)."""
    out = {}
    for usps, nom in ETATS.items():
        rep = client.json(f"{GBIF}/occurrence/search?" + urllib.parse.urlencode(
            {"country": "US", "stateProvince": nom, "limit": 5, "hasCoordinate": "true"}))
        for r in rep.get("results", []):
            l1 = (r.get("gadm") or {}).get("level1") or {}
            if l1.get("name") == nom and l1.get("gid"):
                out[usps] = l1["gid"]
                break
    return out


def liste_huc8(client):
    """[(huc8, nom, [États])] depuis la couche WBD 4 (sans géométrie)."""
    res, debut = [], 0
    while True:
        q = urllib.parse.urlencode({"where": "1=1", "outFields": "huc8,name,states", "returnGeometry": "false",
                                    "orderByFields": "huc8", "resultOffset": debut, "resultRecordCount": 1000, "f": "json"})
        d = client.json(f"{WBD}?{q}")
        feats = d.get("features", [])
        res += [(f["attributes"]["huc8"], f["attributes"]["name"], etats_du_huc8(f["attributes"]["states"])) for f in feats]
        if len(feats) < 1000:
            break
        debut += 1000
    return res


def geometrie_huc8(client, huc8):
    q = urllib.parse.urlencode({"where": f"huc8='{huc8}'", "outFields": "huc8", "returnGeometry": "true", "outSR": 4326,
                                "maxAllowableOffset": 0.003, "geometryPrecision": 4, "f": "json"})
    d = client.json(f"{WBD}?{q}")
    feats = d.get("features", [])
    if not feats:
        return None
    return rings_vers_wkt(feats[0]["geometry"]["rings"])


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--etats", default="", help="liste USPS séparée par des virgules (défaut : 50 + DC)")
    ap.add_argument("--sans-huc8", action="store_true")
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--plafond", type=int, default=60000)
    ap.add_argument("--seuil", type=int, default=2)
    ap.add_argument("--budget-annees", type=int, default=9,
                    help="requêtes par tranche d'années et par HUC8 (0 = illimité, exact) ; l'État est toujours exact")
    ap.add_argument("--sortie", default=SORTIE_DEFAUT)
    ap.add_argument("--cache", default=CACHE_DEFAUT)
    a = ap.parse_args(argv)
    from concurrent.futures import ThreadPoolExecutor

    choix = [e.strip().upper() for e in a.etats.split(",") if e.strip()] or list(ETATS)
    client = Client(a.cache, a.plafond)
    table_us = charger_table_us()
    fam = resoudre_famille_cles(client)
    manquantes = [f for f, k in fam.items() if not k]
    if manquantes:
        print("familles non résolues (ignorées) :", manquantes, file=sys.stderr)
    cles = sorted({k for k in fam.values() if k})
    gids = gids_etats(client)
    infos, stats = {}, {"facettes_totales": 0, "ecartees_liste_blanche": 0, "sans_annee": 0, "saturees": []}
    verrou = threading.Lock()

    def tache(fn, *args):
        return fn(*args)

    # niveau État
    par_etat = {u: [] for u in choix}
    hucs = {u: [] for u in choix}
    etats_sans_gid = [u for u in choix if u not in gids]
    for u in choix:
        if u in gids:
            zone = {"type": "etat", "id": u, "nom": ETATS[u]}
            par_etat[u] = zone_entrees(client, parametres_base(cles, gadm=gids[u]), a.seuil, table_us, infos, stats, zone)
            print(f"{u} état : {len(par_etat[u])} entrées ({client.n_reseau} requêtes)", flush=True)

    # niveau HUC8
    echecs = []
    if not a.sans_huc8:
        liste = [h for h in liste_huc8(client) if set(h[2]) & set(choix)]
        print(f"{len(liste)} HUC8 à traiter", flush=True)

        def traiter(h):
            code, nom, ets = h
            try:
                wkt = geometrie_huc8(client, code)
                if not wkt:
                    return code, None
                zone = {"type": "huc8", "id": code, "nom": nom}
                return code, zone_entrees(client, parametres_base(cles, wkt=wkt), a.seuil, table_us, infos, stats, zone, a.budget_annees or None)
            except Exception as e:  # noqa: BLE001 : un bassin en échec est compté, jamais comblé
                return code, str(e)

        with ThreadPoolExecutor(a.workers) as ex:
            for i, (h, (code, res)) in enumerate(zip(liste, ex.map(traiter, liste))):
                if isinstance(res, list):
                    for u in h[2]:
                        if u in hucs:
                            hucs[u] += res
                else:
                    echecs.append((code, res))
                if i % 50 == 0:
                    print(f"HUC8 {i}/{len(liste)} ({client.n_reseau} requêtes réseau, {client.n_cache} en cache)", flush=True)

    # écriture
    tableau = {}
    for u in choix:
        if u not in gids:
            continue
        srcs = sources_gbif(cles, gids[u])
        taille = ecrire(a.sortie, u, fichier_etat(u, par_etat[u], hucs[u], srcs))
        tableau[u] = (len(par_etat[u]) + len(hucs[u]), taille)
    json.dump({"tableau": tableau, "requetes_reseau": client.n_reseau, "cache": client.n_cache, "echecs_huc8": echecs,
               "etats_sans_gid": etats_sans_gid, "familles_non_resolues": manquantes, "stats": stats},
              open(os.path.join(a.cache, "..", "gbif-rapport.json"), "w"), ensure_ascii=False, indent=1)
    for u, (n, t) in tableau.items():
        print(f"{u}\t{n}\t{t / 1e6:.3f} Mo")
    print(f"requêtes réseau : {client.n_reseau}, cache : {client.n_cache}, HUC8 en échec : {len(echecs)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
