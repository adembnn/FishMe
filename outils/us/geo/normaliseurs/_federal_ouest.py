"""Aides communes aux normaliseurs az.py, nv.py, or.py (sources fédérales BLM, USFS, NPS ; fichier ignoré par le chargeur)."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _propre(p):
    return {k: v for k, v in p.items() if v is not None}


def blm_rampe(f, usps):
    """BLM, sites de loisirs (couche Boat Ramp). Ni téléphone ni description libre."""
    p = f["properties"]
    ident = _txt(p.get("GlobalID")) or _txt(p.get("OBJECTID"))
    if not ident or (p.get("FET_SUBTYPE") or "") != "Boat Ramp" or (_txt(p.get("WEB_DISPLAY")) or "").upper() == "NO":
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _propre({
        "id": f"blm-rec:{ident}", "nom": _txt(p.get("FET_NAME")), "type": "rampe", "coin": "acces",
        "gestionnaire": _txt(p.get("UNIT_NAME")) or "BLM", "lien": _txt(p.get("WEB_LINK"))})}


def usfs_site(f, usps):
    """USFS, sites de loisirs dont l'activité principale est la navigation ou la pêche."""
    p = f["properties"]
    ident = _txt(p.get("recareaid"))
    act = _txt(p.get("markeractivity")) or ""
    if not ident or not (act.startswith("Boating") or "Fishing" in act):
        return None
    peche = "Fishing" in act
    return {"type": "Feature", "geometry": f["geometry"], "properties": _propre({
        "id": f"usfs-rec:{ident}", "nom": _txt(p.get("recareaname")), "type": "peche_rive" if peche else "acces",
        "coin": "peche" if peche else "acces", "gestionnaire": _txt(p.get("forestname")) or "USDA Forest Service",
        "lien": _txt(p.get("recareaurl"))})}


TYPES_NPS = {"Boat Ramp": "rampe", "Boat Launch": "rampe", "Canoe / Kayak Access": "acces_portage",
             "Canoe Access": "acces_portage", "Canoe/Kayak Access": "acces_portage", "Water Access": "acces",
             "Fishing": "peche_rive"}


def nps_poi(f, usps):
    """NPS, points d'intérêt publics (accès à l'eau). Seulement DATAACCESS « Unrestricted »."""
    p = f["properties"]
    ident = _txt(p.get("GEOMETRYID")) or _txt(p.get("OBJECTID"))
    t = TYPES_NPS.get(_txt(p.get("POITYPE")) or "")
    if not ident or not t or (_txt(p.get("DATAACCESS")) or "") != "Unrestricted":
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _propre({
        "id": f"nps-poi:{ident}", "nom": _txt(p.get("POINAME")) or _txt(p.get("MAPLABEL")), "type": t,
        "coin": "peche" if t == "peche_rive" else "acces", "gestionnaire": _txt(p.get("UNITNAME")) or "National Park Service"})}
