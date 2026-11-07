"""Arkansas (AGFC) : accès à la pêche (rive, pontons) et accès bateau / kayak. Les commentaires libres ne sont pas copiés."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _nettoyer(p):
    return {k: v for k, v in p.items() if v is not None}


def peche_ar_agfc(f, dom=None):
    p = f["properties"]
    ident = _txt(p.get("globalid")) or _txt(p.get("OBJECTID"))
    if not ident or not f.get("geometry"):
        return None
    ft = _txt(p.get("ftype")) or ""
    type_ = "peche_rive" if ft in ("Fishing Pier", "Fishing Jetty") else "acces"
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"ar-fish:{ident.strip('{}').lower()}", "nom": _txt(p.get("flabel")), "type": type_, "coin": "peche",
        "eau": _txt(p.get("waterbody")), "lien": _txt(p.get("hyp_1"))})}


def bateau_ar_agfc(f, dom=None):
    p = f["properties"]
    ident = _txt(p.get("globalid")) or _txt(p.get("OBJECTID"))
    if not ident or not f.get("geometry"):
        return None
    ft = _txt(p.get("ftype")) or ""
    type_ = "acces_portage" if "Canoe" in ft or "Kayak" in ft else "rampe"
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"ar-boat:{ident.strip('{}').lower()}", "nom": _txt(p.get("flabel")), "type": type_, "coin": "acces",
        "eau": _txt(p.get("waterbody")), "surface": _txt(p.get("fdescrip"))})}


NORMALISEURS = {"ar_peche_agfc": peche_ar_agfc, "ar_bateau_agfc": bateau_ar_agfc}
