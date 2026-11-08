"""Caroline du Nord : Boating Access Areas de la NCWRC (Wildlife Resources Commission), vue publique."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s if s and s != "<Null>" else None


def _casse(v):
    s = _txt(v)
    return s.title() if s else None


def acces_nc_wrc(f, dom=None):
    p = f["properties"]
    ident = _txt(p.get("GlobalID"))
    if not ident or (_txt(p.get("Site_Status")) or "").upper() != "OPEN":
        return None
    voies = p.get("Launch_Lane_No") or 0
    if voies > 0:
        type_ = "rampe"
    elif _txt(p.get("Portable_Boat_Access_Type")):
        type_ = "acces_portage"
    else:
        type_ = "acces"
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in {
        "id": f"nc-wrc:{ident.strip('{}').lower()}", "nom": _casse(p.get("BAA_Name")), "type": type_, "coin": "acces",
        "eau": _casse(p.get("Water_Access")), "comte": _casse(p.get("County")), "gestionnaire": _txt(p.get("Owner")),
        "voies": voies or None, "places_remorque": p.get("Parking_Trailer")}.items() if v is not None}}


NORMALISEURS = {"acces_nc_wrc": acces_nc_wrc}
