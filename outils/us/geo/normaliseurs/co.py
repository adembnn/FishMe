"""Normaliseurs du Colorado (US15, groupe rocheuses-sud). Seuls des objets d'agence publics ; aucun contact, téléphone, note libre."""


def _t(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _pt(f, ident, nom, type_, coin, **extra):
    p = dict({"id": ident, "nom": nom, "type": type_, "coin": coin}, **extra)
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in p.items() if v is not None}}


def co_cpw_installation(f, dom=None):
    """CPW Facilities : seulement Boat Ramp (3010), Fishing (1100) et Fishing ADA (1101)."""
    p = f["properties"]
    code, oid = p.get("FAC_TYPE"), p.get("OBJECTID")
    if oid is None or code not in (3010, 1100, 1101):
        return None
    nom = _t(p.get("FAC_NAME")) or _t(p.get("PROPNAME"))
    if code == 3010:
        return _pt(f, f"co-cpw-fac:{oid}", nom, "rampe", "acces", gestionnaire="Colorado Parks and Wildlife")
    return _pt(f, f"co-cpw-fac:{oid}", nom, "peche_rive", "peche", gestionnaire="Colorado Parks and Wildlife")


def co_cpw_acces_riviere(f, dom=None):
    p = f["properties"]
    oid = p.get("OBJECTID")
    if oid is None:
        return None
    return _pt(f, f"co-cpw-river:{oid}", _t(p.get("Property")), "acces", "acces", gestionnaire="Colorado Parks and Wildlife")


def _blm(f, prefixe, type_, coin):
    p = f["properties"]
    ident = _t(p.get("FAMS_ID")) or (str(p["OBJECTID"]) if p.get("OBJECTID") is not None else None)
    if not ident:
        return None
    return _pt(f, f"{prefixe}:{ident}", _t(p.get("FET_NAME")), type_, coin, gestionnaire="Bureau of Land Management")


def co_blm_rampe(f, dom=None):
    return _blm(f, "co-blm-ramp", "rampe", "acces")


def co_blm_peche(f, dom=None):
    return _blm(f, "co-blm-fish", "peche_rive", "peche")


def co_usbr_rampe(f, dom=None):
    p = f["properties"]
    ident = _t(p.get("guid")) or (str(p["OBJECTID"]) if p.get("OBJECTID") is not None else None)
    if not ident:
        return None
    return _pt(f, f"co-usbr-ramp:{ident}", _t(p.get("assetname")), "rampe", "acces",
               gestionnaire=_t(p.get("operatingentity1")) or "Bureau of Reclamation", surface=_t(p.get("assettype")))


NORMALISEURS = {fn.__name__: fn for fn in (
    co_cpw_installation, co_cpw_acces_riviere, co_blm_rampe, co_blm_peche, co_usbr_rampe)}
