"""US15 : normaliseurs du Maryland (Maryland DNR, service AIMS/MarineFacilities : couches 1 « Public Fishing Access Site » et
2 « Water Access Site »). Faits seulement : nom, type, eau, comté, gestionnaire. Téléphone, adresse, commentaires libres, liens :
jamais copiés. Les deux couches partagent l'identifiant `md-site:<SiteID>` quand il existe, pour qu'un site présent dans les deux
ne compte qu'une fois (la couche 1, plus riche, passe d'abord)."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s if s and s.lower() not in ("n/a", "none", "null") else None


def _oui(v):
    return (_txt(v) or "").lower().startswith("yes")


def _site(site_id, repli):
    return f"md-site:{site_id}" if site_id not in (None, "", 0) else repli


def acces_md_peche(f, dom=None):
    p = f["properties"]
    oid = p.get("OBJECTID")
    if oid is None:
        return None
    if _oui(p.get("Ramp")):
        type_, coin = "rampe", "acces"
    elif _oui(p.get("ShoreFishi")) or _oui(p.get("Piers")):
        type_, coin = "peche_rive", "peche"
    elif _oui(p.get("KykCanoeLn")):
        type_, coin = "acces_portage", "acces"
    else:
        type_, coin = "acces", "acces"
    props = {"id": _site(p.get("SiteID"), f"md-peche:{oid}"), "nom": _txt(p.get("Name")), "type": type_, "coin": coin,
             "eau": _txt(p.get("Waterbody")), "comte": _txt(p.get("County")), "gestionnaire": _txt(p.get("OpAgency"))}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


def acces_md_eau(f, dom=None):
    p = f["properties"]
    oid = p.get("OBJECTID_1", p.get("OBJECTID"))
    surface = (_txt(p.get("strRampSurfaceMaterial")) or "").upper()
    if "DUPE" in surface or oid is None:  # doublon signalé par le service lui-même
        return None
    rampes = p.get("intNumberOfRamps") or 0
    if isinstance(rampes, (int, float)) and rampes > 0:
        type_ = "rampe"
    elif _oui(p.get("SoftLaunch")):
        type_ = "acces_portage"
    else:
        type_ = "acces"
    props = {"id": _site(p.get("SiteID"), f"md-eau:{oid}"), "nom": _txt(p.get("strBoatingFacName")), "type": type_, "coin": "acces",
             "eau": _txt(p.get("strWaterBody")), "comte": _txt(p.get("strAdminName")),
             "gestionnaire": _txt(p.get("strFacilityOwnerName")),
             "rampes": rampes if isinstance(rampes, (int, float)) and rampes > 0 else None}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_md_peche": acces_md_peche, "acces_md_eau": acces_md_eau}
