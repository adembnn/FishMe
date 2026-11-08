"""Normaliseurs de l'Utah (US15, groupe rocheuses-sud). Aucun téléphone ni contact copié."""


def _t(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _pt(f, **p):
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in p.items() if v is not None}}


def ut_dwr_pecheries_communautaires(f, dom=None):
    """UDWR Community Fisheries : plans d'eau de pêche urbains ; seuls nom et comté sont gardés (ni contact, ni texte libre)."""
    p = f["properties"]
    oid = p.get("OBJECTID")
    if oid is None:
        return None
    return _pt(f, id=f"ut-dwr-comm:{oid}", nom=_t(p.get("WaterName")), type="peche_rive", coin="peche",
               eau=_t(p.get("WaterName")), comte=_t(p.get("County")), gestionnaire="Utah Division of Wildlife Resources")


def ut_usbr_rampe(f, dom=None):
    p = f["properties"]
    ident = _t(p.get("guid")) or (str(p["OBJECTID"]) if p.get("OBJECTID") is not None else None)
    if not ident:
        return None
    return _pt(f, id=f"ut-usbr-ramp:{ident}", nom=_t(p.get("assetname")), type="rampe", coin="acces",
               gestionnaire=_t(p.get("operatingentity1")) or "Bureau of Reclamation", surface=_t(p.get("assettype")))


NORMALISEURS = {fn.__name__: fn for fn in (ut_dwr_pecheries_communautaires, ut_usbr_rampe)}
