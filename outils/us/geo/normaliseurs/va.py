"""Virginie : accès publics à l'eau du DWR (Department of Wildlife Resources) et pontons de pêche du DWR."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s if s and s != "<Null>" else None


def _id(p):
    g = _txt(p.get("GlobalID"))
    return g.strip("{}").lower() if g else None


def _props(d):
    return {k: v for k, v in d.items() if v is not None}


def acces_va_dwr(f, dom=None):
    p = f["properties"]
    ident = _id(p)
    if not ident or (_txt(p.get("On_List")) or "").upper() == "N":
        return None
    rampe = (_txt(p.get("Type_of_Ramp")) or "").lower()
    if "ramp" in rampe and "hand launch" not in rampe:
        type_ = "rampe"
    elif "hand launch" in rampe or "slide" in rampe or "canoe" in rampe:
        type_ = "acces_portage"
    else:
        type_ = "acces"
    gest = _txt(p.get("Owner"))
    if gest == "No File":
        gest = None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _props({
        "id": f"va-dwr:{ident}", "nom": _txt(p.get("SITENAME")), "type": type_, "coin": "acces",
        "eau": _txt(p.get("WATERBODY")), "comte": _txt(p.get("COUNTY")), "gestionnaire": gest,
        "rampes": p.get("NO_OFRAMPS")})}


def ponton_va_dwr(f, dom=None):
    p = f["properties"]
    ident = _id(p)
    if not ident:
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _props({
        "id": f"va-pier:{ident}", "nom": _txt(p.get("Facility_N")), "type": "peche_rive", "coin": "peche",
        "eau": _txt(p.get("Body_of_Wa"))})}


NORMALISEURS = {"acces_va_dwr": acces_va_dwr, "ponton_va_dwr": ponton_va_dwr}
