"""Virginie-Occidentale : sites de pêche et d'accès à l'eau du WV DNR (service WVGIS, Hunting & Fishing Tool)."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s if s and s != "<Null>" else None


def acces_wv_dnr(f, dom=None):
    p = f["properties"]
    if p.get("OBJECTID") is None or p.get("Active") not in (1, None):
        return None
    if (_txt(p.get("Ownership")) or "").lower() == "private":
        return None
    acces = (_txt(p.get("AccessType")) or "").lower()
    if "ramp" in acces:
        type_ = "rampe"
    elif acces in ("carry down", "slide down", "boat access only"):
        type_ = "acces_portage"
    elif acces in ("fishing", "no boats"):
        type_ = "peche_rive"
    else:
        type_ = "acces"
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in {
        "id": f"wv-dnr:{p['OBJECTID']}", "nom": _txt(p.get("SiteName")), "type": type_,
        "coin": "peche" if type_ == "peche_rive" else "acces",
        "eau": _txt(p.get("Waterbody")), "comte": _txt(p.get("County")), "gestionnaire": _txt(p.get("Ownership")),
        "voies": p.get("NumLaunch")}.items() if v is not None}}


NORMALISEURS = {"acces_wv_dnr": acces_wv_dnr}
