"""Normaliseurs du Nouveau-Mexique (US15, groupe rocheuses-sud). Les champs de restriction, notes et espèces de la NMDGF ne sont pas copiés."""


def _t(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _pt(f, **p):
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in p.items() if v is not None}}


def nm_acces_peche(f, dom=None):
    """NMDGF Fishing Access (couche 5 du service Fishing Waters Map)."""
    p = f["properties"]
    oid = p.get("OBJECTID")
    if oid is None:
        return None
    genre = (_t(p.get("Access_Type")) or "").lower()
    if "boat ramp" in genre:
        type_ = "rampe"
    elif "launching" in genre:
        type_ = "acces_portage"
    elif "shoreline" in genre or "wadeable" in genre:
        type_ = "peche_rive"
    else:
        type_ = "acces"
    nom = _t(p.get("Access_Name")) or _t(p.get("Waterbody_Name"))
    return _pt(f, id=f"nm-fish:{oid}", nom=nom, type=type_, coin="peche" if type_ == "peche_rive" else "acces",
               eau=_t(p.get("Waterbody_Name")), gestionnaire="New Mexico Department of Wildlife")


def nm_rampe(f, dom=None):
    """NMDGF Boat Ramps (couche 4)."""
    p = f["properties"]
    oid = p.get("OBJECTID")
    if oid is None:
        return None
    return _pt(f, id=f"nm-ramp:{oid}", nom=_t(p.get("Water_name")), type="rampe", coin="acces",
               eau=_t(p.get("Water_name")), gestionnaire=_t(p.get("Ownership")), surface=_t(p.get("Ramp_type")))


def nm_usbr_rampe(f, dom=None):
    p = f["properties"]
    ident = _t(p.get("guid")) or (str(p["OBJECTID"]) if p.get("OBJECTID") is not None else None)
    if not ident:
        return None
    return _pt(f, id=f"nm-usbr-ramp:{ident}", nom=_t(p.get("assetname")), type="rampe", coin="acces",
               gestionnaire=_t(p.get("operatingentity1")) or "Bureau of Reclamation", surface=_t(p.get("assettype")))


NORMALISEURS = {fn.__name__: fn for fn in (nm_acces_peche, nm_rampe, nm_usbr_rampe)}
