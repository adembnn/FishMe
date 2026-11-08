"""Normaliseurs de New York (NYS DEC). Aucune dépendance : fonctions locales seulement."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _nettoyer(p):
    return {k: v for k, v in p.items() if v is not None}


def _centre(geom):
    """Centre (moyenne des sommets du premier anneau) d'un Polygon/MultiPolygon, en Point GeoJSON ; None si vide."""
    if not geom:
        return None
    if geom["type"] == "Point":
        return geom
    if geom["type"] == "Polygon":
        anneau = geom["coordinates"][0]
    elif geom["type"] == "MultiPolygon":
        anneau = max((p[0] for p in geom["coordinates"]), key=len)
    else:
        return None
    pts = anneau[:-1] if len(anneau) > 1 and anneau[0] == anneau[-1] else anneau
    if not pts:
        return None
    return {"type": "Point", "coordinates": [sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)]}


def acces_ny_lancement(f, dom=None):
    """DEC Boat Launch Sites : lancements à la main ou à la remorque. Les sites d'un gestionnaire privé sont écartés."""
    p = f["properties"]
    oid = p.get("OBJECTID")
    if oid is None or (_txt(p.get("AGENCY")) or "").lower() == "private":
        return None
    t = (_txt(p.get("ACCESS_TYP")) or "").lower()
    type_ = "rampe" if any(k in t for k in ("hard surface", "trailer", "concrete")) else "acces_portage"
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"ny-launch:{oid}", "nom": _txt(p.get("WATERBODY")), "type": type_, "coin": "acces",
        "eau": _txt(p.get("WATERBODY")), "comte": _txt(p.get("COUNTY")), "gestionnaire": _txt(p.get("AGENCY"))})}


def peche_ny_trout(f, dom=None):
    """DEC Trout Stream Fishing Access : surfaces d'accès à la pêche sur des cours d'eau à truites, ramenées à un point."""
    p = f["properties"]
    oid = p.get("OBJECTID")
    pt = _centre(f.get("geometry"))
    if oid is None or not pt:
        return None
    return {"type": "Feature", "geometry": pt, "properties": _nettoyer({
        "id": f"ny-trout:{oid}", "nom": _txt(p.get("WATER")), "type": "peche_rive", "coin": "peche",
        "eau": _txt(p.get("WATER")), "gestionnaire": _txt(p.get("AGENCY"))})}


NORMALISEURS = {"acces_ny_lancement": acces_ny_lancement, "peche_ny_trout": peche_ny_trout}
