"""Normalisation : un objet GeoJSON d'agence -> un objet GeoJSON léger FishMe.

Propriétés communes : id (préfixé par la source), nom, type. Les autres sont des scalaires (texte ou nombre).
Règles de confidentialité (voir LISEZMOI.md) :
- on ne garde que des objets d'agence publics (rampes, tracés, terres publiques, avis) ; aucun numéro de téléphone,
  aucun nom de personne, aucune note libre (champs « comments », « directions », « contact », « phone » jamais copiés) ;
- aucune entrée « spot » du pêcheur ne passe par ces scripts (elles restent sur l'iPhone).
- coordonnées arrondies : points d'accès publics 5 décimales (~1 m, comme les stations OFB publiques) ; lignes et
  polygones 4 décimales (~11 m), réglable par couche (`decimales`).
"""
import os
import datetime
import json
import re


def arrondir(geom, d):
    """Arrondit récursivement les coordonnées d'une géométrie GeoJSON à d décimales ; retire les doublons consécutifs."""
    def rec(c):
        if c and isinstance(c[0], (int, float)):  # une position
            return [round(c[0], d), round(c[1], d)]
        if c and isinstance(c[0][0], (int, float)):  # une ligne ou un anneau : positions, sans doublons consécutifs
            ded = []
            for q in c:
                r = [round(q[0], d), round(q[1], d)]
                if not ded or r != ded[-1]:
                    ded.append(r)
            return ded
        return [rec(x) for x in c]
    if not geom or "coordinates" not in geom:
        return geom
    return {"type": geom["type"], "coordinates": rec(geom["coordinates"])}


def _rdp(pts, tol):
    """Douglas-Peucker itératif (pas de récursion : certaines terres publiques ont des dizaines de milliers de sommets)."""
    n = len(pts)
    if n < 3:
        return pts
    garde = [False] * n
    garde[0] = garde[-1] = True
    pile = [(0, n - 1)]
    t2 = tol * tol
    while pile:
        i, j = pile.pop()
        ax, ay = pts[i]
        bx, by = pts[j]
        dx, dy = bx - ax, by - ay
        L2 = dx * dx + dy * dy
        pire, k = -1.0, None
        for m in range(i + 1, j):
            px, py = pts[m]
            if L2 == 0:
                d2 = (px - ax) ** 2 + (py - ay) ** 2
            else:
                t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / L2))
                d2 = (px - ax - t * dx) ** 2 + (py - ay - t * dy) ** 2
            if d2 > pire:
                pire, k = d2, m
        if k is not None and pire > t2:
            garde[k] = True
            pile.append((i, k))
            pile.append((k, j))
    return [p for p, g in zip(pts, garde) if g]


def simplifier(geom, tol):
    """Simplifie lignes et polygones (tolérance en degrés). Anneaux réduits à moins de 4 points : supprimés ; polygone sans anneau : None."""
    if not geom or not tol or geom["type"] in ("Point", "MultiPoint"):
        return geom
    def anneau(r):
        s = _rdp(r, tol)
        return s if len(s) >= 4 else None
    def poly(rings, multi=False):
        ext = anneau(rings[0])
        if ext is None:
            return None
        xs, ys = [p[0] for p in ext], [p[1] for p in ext]
        if multi and max(xs) - min(xs) < 2 * tol and max(ys) - min(ys) < 2 * tol:
            return None  # miette de parcelle (< ~200 m) : sans intérêt sur une carte de pêche
        return [ext] + [h for h in (anneau(r) for r in rings[1:]) if h]
    t = geom["type"]
    if t == "LineString":
        return {"type": t, "coordinates": _rdp(geom["coordinates"], tol)}
    if t == "MultiLineString":
        return {"type": t, "coordinates": [_rdp(l, tol) for l in geom["coordinates"]]}
    if t == "Polygon":
        p = poly(geom["coordinates"])
        return {"type": t, "coordinates": p} if p else None
    if t == "MultiPolygon":
        ps = [p for p in (poly(x, True) for x in geom["coordinates"]) if p]
        return {"type": t, "coordinates": ps} if ps else None
    return geom


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _ymd(ms):
    if ms in (None, "", 0):
        return None
    try:
        return datetime.datetime.fromtimestamp(int(ms) / 1000, datetime.timezone.utc).strftime("%Y-%m-%d")
    except (ValueError, OSError, OverflowError):
        return None


def _nettoyer(p):
    return {k: v for k, v in p.items() if v is not None}


def _dom(domaines, champ, v):
    """Décode une valeur à domaine codé (liste {name, code}) ; sinon renvoie la valeur."""
    if v is None:
        return None
    for cv in (domaines or {}).get(champ, []):
        if cv.get("code") == v:
            return cv.get("name")
    return v


# ---- points d'accès -------------------------------------------------------------------------------------------

def acces_mn_swas(f, dom=None):
    p = f["properties"]
    methode = _txt(_dom(dom, "boat_launch_method", p.get("boat_launch_method")))
    type_ = {"Trailer Launch": "rampe", "Carry-In": "acces_portage"}.get(methode, "acces")
    ident = _txt(p.get("unique_swas_id"))
    if not ident:
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"mn-swas:{ident}", "nom": _txt(p.get("water_access_site_name")), "type": type_, "coin": "acces",
        "eau": _txt(p.get("lake_name")), "comte": _txt(_dom(dom, "swas_county", p.get("swas_county"))),
        "gestionnaire": _txt(p.get("administrator")), "rampes": p.get("boat_ramp_count"),
        "places_remorque": p.get("capacity_trailers_non_ada"), "surface": _txt(_dom(dom, "launch_surface_type", p.get("launch_surface_type")))})}


def acces_wi_bateau(f, dom=None):
    p = f["properties"]
    if (_txt(p.get("ABANDON_FLAG")) or "").lower() == "yes":
        return None
    seq = p.get("BOATLANDING_SEQ_NO")
    if seq is None:
        return None
    lt = (_txt(p.get("LANDING_TYPE_CODE")) or "").upper()
    type_ = "rampe" if "RAMP" in lt else ("acces_portage" if "CARRY" in lt or "HAND" in lt else "acces")
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"wi-boat:{seq}", "nom": _txt(p.get("LMS_BOAT_LANDING_NAME")), "type": type_, "coin": "acces",
        "eau": _txt(p.get("WATERBODY_NAME_TEXT")), "comte": _txt(p.get("COUNTY_NAME_TEXT")),
        "gestionnaire": _txt(p.get("OWNERSHIP_NAME_TEXT")), "surface": _txt(p.get("RAMP_TYPE_CODE"))})}


def peche_rive_wi(f, dom=None):
    p = f["properties"]
    seq = p.get("SHOREFISH_SEQ_NO")
    if seq is None:
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"wi-shore:{seq}", "nom": _txt(p.get("FACILITY_NAME_TEXT")), "type": "peche_rive", "coin": "peche",
        "eau": _txt(p.get("WATERBODY_NAME_TEXT")), "comte": _txt(p.get("COUNTY_NAME_TEXT")),
        "lien": _txt(p.get("MORE_INFO_URL"))})}


def acces_mi_prd(f, dom=None):
    p = f["properties"]
    ident = _txt(p.get("legacyid")) or _txt(p.get("globalid"))
    if not ident or (_txt(p.get("referenceonly")) or "").lower() == "yes":
        return None
    carry = (_txt(p.get("carrydown")) or "").lower() == "yes"
    lanes = p.get("nlanes") or 0
    type_ = "rampe" if (isinstance(lanes, (int, float)) and lanes > 0) else ("acces_portage" if carry else "acces")
    if _txt(p.get("bas_type")) and "fishing" in _txt(p.get("bas_type")).lower():
        type_ = "peche_rive"
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"mi-bas:{ident}", "nom": _txt(p.get("name")) or _txt(p.get("labelname")), "type": type_,
        "coin": "peche" if type_ == "peche_rive" else "acces",
        "eau": _txt(p.get("waterbody")), "gestionnaire": _txt(p.get("ownedby")),
        "voies": p.get("nlanes"), "places_remorque": p.get("ntrailerableparking"),
        "statut": _txt(p.get("launch_status"))})}


# ---- eau ------------------------------------------------------------------------------------------------------

def trace_3dhp(f, dom=None):
    p = f["properties"]
    if not p.get("id3dhp"):
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"3dhp:{p['id3dhp']}", "nom": _txt(p.get("gnisidlabel")), "type": _txt(p.get("featuretypelabel")) or "flowline",
        "ordre": p.get("streamorder"), "long_km": p.get("lengthkm"), "bassin": _txt(p.get("mainstemid"))})}


def plan_eau_3dhp(f, dom=None):
    p = f["properties"]
    if not p.get("id3dhp"):
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"3dhp:{p['id3dhp']}", "nom": _txt(p.get("gnisidlabel")), "type": _txt(p.get("featuretypelabel")) or "waterbody",
        "surface_km2": p.get("areasqkm")})}


# ---- terres publiques, avis, empoissonnement ------------------------------------------------------------------

ACCES_PAD = {"OA": "ouvert", "RA": "restreint", "XA": "ferme", "UK": "inconnu"}


def terre_publique_pad(f, dom=None):
    """Une terre publique : dit que la TERRE est publique, jamais que la pêche y est permise ni que l'eau est atteignable."""
    p = f["properties"]
    ident = _txt(p.get("GlobalID")) or _txt(p.get("Source_PAID")) or _txt(p.get("OBJECTID"))
    if not ident:
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": "padus:" + ident.strip("{}").lower(), "nom": _txt(p.get("Unit_Nm")) or _txt(p.get("Loc_Nm")),
        "type": _txt(p.get("Des_Tp")), "gestionnaire": _txt(p.get("Mang_Name")), "etat": _txt(p.get("State_Nm")),
        "acces": ACCES_PAD.get(_txt(p.get("Pub_Access")), "inconnu"), "gap": _txt(p.get("GAP_Sts")),
        "date_acces": _txt(p.get("Access_Dt"))})}


def avis_epa(f, dom=None):
    p = f["properties"]
    ident = _txt(p.get("PERMANENT_")) or _txt(p.get("OBJECTID"))
    if not ident:
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"epa-nlfwa:{ident}", "nom": _txt(p.get("FEATUREDET")), "type": "avis_consommation",
        "avis": _txt(p.get("SOURCE_FEA")), "etat": _txt(p.get("GEOGSTATE")), "cycle": p.get("CYCLE_YEAR"),
        "debut": _ymd(p.get("START_DATE")), "fin": _ymd(p.get("END_DATE"))})}


def empoissonnement_wi(f, dom=None):
    """Résume les enregistrements annuels : dernière année et espèces de cette année (le détail reste chez la DNR)."""
    p = f["properties"]
    wbic = p.get("WBIC")
    if wbic is None:
        return None
    try:
        recs = json.loads(p.get("STOCKING_RECORDS_JSON") or "[]")
    except json.JSONDecodeError:
        recs = []
    annees = [r["year"] for r in recs if isinstance(r.get("year"), int)]
    derniere = max(annees) if annees else None
    especes = sorted({str(r.get("species")).title() for r in recs if r.get("year") == derniere and r.get("species")})
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"wi-stock:{wbic}", "nom": _txt(p.get("WATERBODY_NAME")), "type": "empoissonnement",
        "wbic": wbic, "derniere_annee": derniere, "especes": ", ".join(especes) or None, "lots": len(recs)})}


NORMALISEURS = {fn.__name__: fn for fn in (
    acces_mn_swas, acces_wi_bateau, peche_rive_wi, acces_mi_prd, trace_3dhp, plan_eau_3dhp,
    terre_publique_pad, avis_epa, empoissonnement_wi)}


def _charger_normaliseurs_etats():
    """Un fichier par État dans normaliseurs/<usps>.py, avec un dict NORMALISEURS {nom: fonction} (US15 : pas de conflit entre États)."""
    import importlib.util
    dossier = os.path.join(os.path.dirname(os.path.abspath(__file__)), "normaliseurs")
    if not os.path.isdir(dossier):
        return
    for nom in sorted(os.listdir(dossier)):
        if not nom.endswith(".py") or nom.startswith("_"):
            continue
        spec = importlib.util.spec_from_file_location("normaliseurs_" + nom[:-3], os.path.join(dossier, nom))
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        for cle, fn in getattr(mod, "NORMALISEURS", {}).items():
            if cle in NORMALISEURS:
                raise ValueError(f"normaliseur en double : {cle} ({nom})")
            NORMALISEURS[cle] = fn


def rogner_aux_parties(geom, emprise):
    """Pour les MultiPolygon/MultiLineString : ne garde que les parties dont la boîte touche l'emprise demandée
    (une terre publique d'État peut compter des milliers de parcelles dispersées dont l'échantillon n'a que faire)."""
    if not geom or not emprise or geom["type"] not in ("MultiPolygon", "MultiLineString"):
        return geom
    x0, y0, x1, y1 = emprise
    def touche(pts):
        xs, ys = [p[0] for p in pts], [p[1] for p in pts]
        return max(xs) >= x0 and min(xs) <= x1 and max(ys) >= y0 and min(ys) <= y1
    if geom["type"] == "MultiPolygon":
        parts = [p for p in geom["coordinates"] if touche(p[0])]
    else:
        parts = [l for l in geom["coordinates"] if touche(l)]
    return {"type": geom["type"], "coordinates": parts} if parts else None


_charger_normaliseurs_etats()
