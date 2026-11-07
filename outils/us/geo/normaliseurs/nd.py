"""ND : Game and Fish Department, couche « Fishing Facilities » (GNF_FishingWaters, couche 4). Faits publics seulement :
pas de téléphone, de contact ni de « directions »."""


def _txt(v):
    v = v.strip() if isinstance(v, str) else v
    return v if v not in ("", None) else None


def acces_nd_gnf(f, dom=None):
    p = f["properties"]
    if (_txt(p.get("Exist")) or "").upper() == "N" or (_txt(p.get("Useable")) or "").upper() == "N":
        return None
    ident = p.get("ID")
    if ident is None:
        return None
    unite = _txt(p.get("UNIT_TYPE")) or ""
    detail = (_txt(p.get("code_Name")) or "").lower()
    if unite == "Boat Ramps":
        type_, coin = "rampe", "acces"
    elif unite.startswith("Docks") and "fishing pier" in detail:
        type_, coin = "peche_rive", "peche"
    elif unite.startswith("Docks"):
        type_, coin = "acces", "acces"
    else:
        return None
    lac = _txt(p.get("Lake_Name"))
    lieu = _txt(p.get("Location_Name"))
    nom = " – ".join(x for x in (lac, lieu) if x)
    comte = _txt(p.get("County_Name"))
    props = {"id": f"nd-gnf:{ident}", "nom": nom or None, "type": type_, "coin": coin, "eau": lac,
             "comte": None if comte == "Not Specified" else comte,
             "gestionnaire": _txt(p.get("Ownership")), "surface": _txt(p.get("Ramp"))}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_nd_gnf": acces_nd_gnf}
