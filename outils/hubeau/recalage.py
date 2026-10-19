"""D5 : recale chaque station OFB sur le trace de son cours d'eau (decision 8 du 19 oct.). Python 3 seul, aucun reseau ici.

Regle (docs/fiches/D5.md) : la station est projetee sur le point le plus proche du trace du cours d'eau qui porte le meme
`code_eau` (a defaut de ce code dans le trace, le meme nom normalise, sauf pour un plan d'eau). A 300 m au plus : coordonnee projetee
a 5 decimales, `recalee: true`, `eau` = nom du trace. Sinon : coordonnee arrondie a 0,01 degre, `recalee: false`, nom garde.

Le trace est un GeoJSON de LineString / MultiLineString (WGS84) : Sandre BD Carthage / BD Topage (Licence Ouverte), champs
`CdEntiteHydrographique` et `NomEntiteHydrographique` ; les noms `code`, `code_eau`, `nom`, `name` sont acceptes aussi.
Le telechargement du trace est dans `trace_sandre.py`.
"""
from __future__ import annotations

import json
import math
import os
import re
import unicodedata
from array import array

SEUIL_M = 300.0
SEUIL_SANS_COURS_D_EAU_M = 50.0  # station sans code ni nom : seulement un trace tout proche, de n'importe quel nom
M_PAR_DEGRE = 111194.9  # un degre de latitude (sphere de 6 371 km) ; la longitude est multipliee par cos(latitude)
CLES_CODE = ("CdEntiteHydrographique", "code_eau", "code", "CdCoursEau")
CLES_NOM = ("NomEntiteHydrographique", "nom", "name", "NomCoursEau")
MOT_PLAN_D_EAU = re.compile(r"\b(lac|etang|plan d eau|reservoir|retenue|bassin|gravière|graviere|carriere)\b")
ARTICLES = {"le", "la", "les", "l", "du", "de", "des", "d", "un", "une", "au", "aux"}


def normaliser(nom: str | None) -> str:
    """Nom sans accents, en minuscules, sans article ni ponctuation : « L'Avre » et « Avre » deviennent « avre »."""
    if not nom:
        return ""
    t = unicodedata.normalize("NFD", nom)
    t = "".join(c for c in t if unicodedata.category(c) != "Mn").lower()
    mots = [m for m in re.split(r"[^a-z0-9]+", t) if m]
    while mots and mots[0] in ARTICLES:
        mots = mots[1:]
    return " ".join(mots)


def est_plan_d_eau(nom: str | None) -> bool:
    t = unicodedata.normalize("NFD", (nom or "").lower())
    t = "".join(c for c in t if unicodedata.category(c) != "Mn")
    t = re.sub(r"[^a-z0-9]+", " ", t)
    return bool(MOT_PLAN_D_EAU.search(t))


def a_deux_decimales_ou_moins(v: float) -> bool:
    return abs(round(v, 2) - v) < 1e-9


class Trace:
    """Les entites du trace : code -> [(nom, [ligne, ...])], ligne = tableau plat lon, lat, lon, lat..."""

    def __init__(self):
        self.par_code: dict[str, list[tuple[str, list]]] = {}
        self.par_nom: dict[str, list[tuple[str, str, list]]] = {}
        self.n_entites = 0

    def ajouter(self, code: str | None, nom: str | None, lignes: list) -> None:
        # chaque ligne en tableau plat lon, lat, lon, lat... (16 octets par point : la France entiere tient en memoire)
        lignes = [array("d", [c for p in l for c in (p[0], p[1])]) for l in lignes if len(l) >= 2]
        if not lignes:
            return
        self.n_entites += 1
        if code:
            self.par_code.setdefault(str(code), []).append((nom or "", lignes))
        cle = normaliser(nom)
        if cle:
            self.par_nom.setdefault(cle, []).append((str(code or ""), nom or "", lignes))

    def ajouter_geojson(self, doc: dict) -> "Trace":
        for f in doc.get("features", []):
            g = f.get("geometry") or {}
            p = f.get("properties") or {}
            if g.get("type") == "LineString":
                lignes = [g["coordinates"]]
            elif g.get("type") == "MultiLineString":
                lignes = g["coordinates"]
            else:
                continue
            code = next((p[c] for c in CLES_CODE if p.get(c)), None)
            nom = next((p[c] for c in CLES_NOM if p.get(c)), None)
            self.ajouter(code, nom, lignes)
        return self

    @classmethod
    def depuis_fichiers(cls, *chemins: str) -> "Trace":
        t = cls()
        for c in chemins:
            with open(c, encoding="utf-8") as f:
                t.ajouter_geojson(json.load(f))
        return t

    def a_le_code(self, code: str | None) -> bool:
        return bool(code) and str(code) in self.par_code

    def candidats(self, code: str | None, nom: str | None):
        """Les entites a essayer pour une station : meme code ; a defaut de ce code dans le trace, meme nom normalise
        (jamais pour un plan d'eau). Retourne (liste de (nom_trace, lignes), regle)."""
        if self.a_le_code(code):
            return [(n, l) for n, l in self.par_code[str(code)]], "code"
        cle = normaliser(nom)
        if cle and not est_plan_d_eau(nom) and cle in self.par_nom:
            return [(n, l) for _, n, l in self.par_nom[cle]], "nom"
        return [], None


def plus_proche_sur_lignes(lat: float, lon: float, lignes: list, limite_m: float = SEUIL_M):
    """Point des `lignes` le plus proche de (lat, lon), en projetant sur les SEGMENTS (pas sur les sommets).
    Retourne (distance_m, lat, lon) ou None si tout est a plus de `limite_m`. Projection locale en metres (plan tangent)."""
    kx = M_PAR_DEGRE * math.cos(math.radians(lat))
    ky = M_PAR_DEGRE
    marge_lat = limite_m / ky
    marge_lon = limite_m / kx
    meilleur = None
    for ligne in lignes:
        for i in range(0, len(ligne) - 2, 2):
            ax, ay, bx, by = ligne[i], ligne[i + 1], ligne[i + 2], ligne[i + 3]
            if (max(ay, by) < lat - marge_lat or min(ay, by) > lat + marge_lat
                    or max(ax, bx) < lon - marge_lon or min(ax, bx) > lon + marge_lon):
                continue
            dx, dy = (bx - ax) * kx, (by - ay) * ky
            n = dx * dx + dy * dy
            px, py = (lon - ax) * kx, (lat - ay) * ky
            t = 0.0 if n == 0 else max(0.0, min(1.0, (px * dx + py * dy) / n))
            d = math.hypot(px - t * dx, py - t * dy)
            if meilleur is None or d < meilleur[0]:
                meilleur = (d, ay + t * (by - ay), ax + t * (bx - ax))
    if meilleur is None or meilleur[0] > limite_m:
        return None
    return meilleur


def eviter_deux_decimales(v: float) -> float:
    """Une coordonnee projetee qui tombe pile sur 0,01 degre ressemblerait a un arrondi : on la decale d'un cent-millieme
    de degre (environ 1 m), invisible mais distinguable (verifier_donnees.py refuse les `true` a 2 decimales)."""
    v = round(v, 5)
    return round(v + 1e-5, 5) if a_deux_decimales_ou_moins(v) else v


def cellule(lat: float, lon: float, pas: float = 0.05) -> tuple[int, int]:
    """Meme formule que trace_sandre.cellule (les deux fichiers restent lancables seuls)."""
    return math.floor(lon / pas), math.floor(lat / pas)


class Voisinage:
    """Trace par cellule de 0,05 degre, pour les stations sans cours d'eau (ni code ni nom) : trace_sandre.telecharger_cellules."""

    def __init__(self):
        self.cellules: dict[tuple[int, int], Trace] = {}

    @classmethod
    def depuis_cellules(cls, chemins: dict) -> "Voisinage":
        v = cls()
        for k, c in chemins.items():
            with open(c, encoding="utf-8") as f:
                v.cellules[k] = Trace().ajouter_geojson(json.load(f))
        return v

    def candidats(self, lat: float, lon: float):
        t = self.cellules.get(cellule(lat, lon))
        if t is None:
            return []
        return [(n, l) for ents in t.par_code.values() for n, l in ents] +                [(n, l) for ents in t.par_nom.values() for c, n, l in ents if not c]


def recaler_station(lat: float, lon: float, eau: str | None, code_eau: str | None, trace: Trace, seuil_m: float = SEUIL_M,
                    voisinage: "Voisinage | None" = None) -> dict:
    """Retourne {lat, lon, eau, recalee, ecart_m, regle} ; `ecart_m` et `regle` ne vont pas dans le fichier."""
    candidats, regle = trace.candidats(code_eau, eau)
    if not candidats and not code_eau and not eau and voisinage is not None:
        candidats, regle, seuil_m = voisinage.candidats(lat, lon), "voisin", min(seuil_m, SEUIL_SANS_COURS_D_EAU_M)
    meilleur = None
    for nom, lignes in candidats:
        r = plus_proche_sur_lignes(lat, lon, lignes, seuil_m)
        if r and (meilleur is None or r[0] < meilleur[0][0]):
            meilleur = (r, nom)
    if meilleur is not None:
        (d, plat, plon), nom = meilleur
        return {"lat": eviter_deux_decimales(plat), "lon": eviter_deux_decimales(plon), "eau": nom or eau, "recalee": True,
                "ecart_m": round(d, 1), "regle": regle}
    return {"lat": round(lat, 2), "lon": round(lon, 2), "eau": eau, "recalee": False, "ecart_m": None, "regle": regle}


def recaler_stations(stations: list[dict], trace: Trace, seuil_m: float = SEUIL_M, voisinage: "Voisinage | None" = None) -> dict:
    """Modifie en place les dicts du fichier (`lat`, `lon`, `eau`, + `recalee`). Retourne les comptes pour le rapport."""
    n_vrai = 0
    raisons = {"sans_cours_d_eau": 0, "code_et_nom_absents_du_trace": 0, "trop_loin": 0, "plan_d_eau": 0}
    ecarts = []
    for s in stations:
        r = recaler_station(s["lat"], s["lon"], s.get("eau"), s.get("code_eau"), trace, seuil_m, voisinage)
        s["lat"], s["lon"], s["eau"], s["recalee"] = r["lat"], r["lon"], r["eau"], r["recalee"]
        if r["recalee"]:
            n_vrai += 1
            ecarts.append(r["ecart_m"])
        elif not s.get("eau") and not s.get("code_eau"):
            raisons["sans_cours_d_eau"] += 1  # aucun trace a moins de 50 m (ou voisinage non fourni)
        elif r["regle"] is None:
            raisons["plan_d_eau" if est_plan_d_eau(s.get("eau")) else "code_et_nom_absents_du_trace"] += 1
        else:
            raisons["trop_loin"] += 1
    ecarts.sort()
    return {"stations": len(stations), "recalees": n_vrai, "non_recalees": len(stations) - n_vrai, "raisons_false": raisons,
            "ecart_median_m": ecarts[len(ecarts) // 2] if ecarts else None, "ecart_max_m": ecarts[-1] if ecarts else None,
            "seuil_m": seuil_m}


def charger_trace_dossier(dossier: str) -> Trace:
    """Tout le trace du dossier (paquets par code ; les cellules `cell-*.geojson` du voisinage sont lues a part)."""
    import glob
    chemins = sorted(glob.glob(os.path.join(dossier, "paquet-*.geojson")))
    if not chemins:
        raise FileNotFoundError(f"aucun trace (paquet-*.geojson) dans {dossier} : lancer trace_sandre.py")
    return Trace.depuis_fichiers(*chemins)


def preparer_trace(stations: list[dict], dossier: str, log=print, voisinage: bool = True):
    """Telecharge (avec cache) puis charge le trace utile a ces stations. Retourne (Trace, Voisinage ou None).
    Les stations sans cours d'eau (ni code ni nom) ne se rattachent qu'a un trace a 50 m au plus."""
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import trace_sandre
    codes = {s["code_eau"] for s in stations if s.get("code_eau")}
    log(f"trace : {len(codes)} cours d'eau a telecharger ou lire dans le cache ({dossier})")
    trace_sandre.telecharger(codes, dossier, log=log)
    trace = charger_trace_dossier(dossier) if codes else Trace()
    vois = None
    if voisinage:
        cells = {trace_sandre.cellule(s["lat"], s["lon"]) for s in stations if not s.get("code_eau") and not s.get("eau")}
        if cells:
            log(f"trace : {len(cells)} cellules de voisinage pour les stations sans cours d'eau")
            vois = Voisinage.depuis_cellules(trace_sandre.telecharger_cellules(cells, dossier, log=log))
    return trace, vois


def main(argv=None) -> int:
    """Recale un stations-especes.json deja fabrique (sans refaire les 2 h d'appels Hub'Eau) :
    python3 recalage.py ENTREE.json SORTIE.json [--departement 94 80] [--trace f.geojson ... | --dossier DIR]"""
    import argparse
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    ap = argparse.ArgumentParser(description=main.__doc__)
    ap.add_argument("entree")
    ap.add_argument("sortie")
    ap.add_argument("--departement", nargs="+", metavar="CODE", help="ne traiter (et ne garder) que ces departements")
    ap.add_argument("--trace", nargs="+", help="fichiers GeoJSON du trace ; sinon telecharge (Sandre) dans --dossier")
    ap.add_argument("--dossier", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "cache", "trace"))
    ap.add_argument("--seuil", type=float, default=SEUIL_M)
    ap.add_argument("--sans-voisinage", action="store_true", help="ne pas rattacher les stations sans cours d'eau")
    a = ap.parse_args(argv)
    with open(a.entree, encoding="utf-8") as f:
        doc = json.load(f)
    if any("recalee" in s for s in doc["stations"]):
        print("Ce fichier porte deja `recalee` : le recalage arrondit les non recalees, il ne se refait pas sur son resultat. "
              "Repartir du fichier brut.", file=sys.stderr)
        return 2
    if a.departement:
        doc["stations"] = [s for s in doc["stations"] if s["dep"] in a.departement]
    log = lambda m: print(m, file=sys.stderr, flush=True)  # noqa: E731
    vois = None
    if a.trace:
        trace = Trace.depuis_fichiers(*a.trace)
    else:
        trace, vois = preparer_trace(doc["stations"], a.dossier, log, not a.sans_voisinage)
    rapport = recaler_stations(doc["stations"], trace, a.seuil, vois)
    doc["recalage"] = {"regle": f"projection sur le trace du cours d'eau de meme code, {a.seuil:.0f} m au plus (50 m pour une station sans cours d'eau) ; sinon arrondi a 0,01 degre",
                       "trace": "Sandre, BD Carthage (couche CoursEau_FXX), Licence Ouverte"}
    with open(a.sortie, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
    print(json.dumps(rapport, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
