"""Normaliseurs de Washington (WA) : sites d'accès à l'eau du WDFW, mises à l'eau des parcs d'État, rampes du Bureau of Reclamation.

Seuls des objets d'agence publics et des scalaires : ni téléphone, ni contact, ni note libre (champ `Notes` du WDFW non copié).
"""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _nettoyer(p):
    return {k: v for k, v in p.items() if v is not None}


def _pos(v):
    return v if isinstance(v, (int, float)) and v > 0 else None


def acces_wa_wdfw(f, dom=None):
    """WDFW Water Access Sites, couche LabelPoints (un point par site)."""
    p = f["properties"]
    ident = p.get("ManagedPlaceOID")
    if ident is None:
        return None
    rampes, mains, quais = _pos(p.get("BoatRamps")), _pos(p.get("HandLaunches")), _pos(p.get("FishingPlatforms"))
    if rampes:
        type_, coin = "rampe", "acces"
    elif mains:
        type_, coin = "acces_portage", "acces"
    elif quais:
        type_, coin = "peche_rive", "peche"
    else:
        type_, coin = "acces", "acces"
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"wa-wdfw:{ident}", "nom": _txt(p.get("WaterAccessSiteName")), "type": type_, "coin": coin,
        "comte": _txt(p.get("County")), "gestionnaire": _txt(p.get("ManagingEntity")),
        "rampes": rampes, "mises_main": mains, "pontons_peche": quais, "fermeture": _txt(p.get("ClosureType"))})}


def acces_wa_parcs(f, dom=None):
    """Washington State Parks, mises à l'eau (« Identifier » = nom du site ; pas d'autre champ utile)."""
    p = f["properties"]
    if p.get("HideFeature") == 1 or (_txt(p.get("LaunchType")) or "").lower() == "unofficial":
        return None
    ident = p.get("OBJECTID")
    nom = _txt(p.get("Identifier"))
    if ident is None or not nom:
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"wa-parc:{ident}", "nom": nom, "type": "acces", "coin": "acces",
        "gestionnaire": "Washington State Parks", "surface": _txt(p.get("LaunchType"))})}


def acces_wa_usbr(f, dom=None):
    """Bureau of Reclamation, Boat Ramps (jeu national, filtré par emprise)."""
    p = f["properties"]
    ident = _txt(p.get("guid")) or p.get("OBJECTID")
    if ident is None:
        return None
    genre = (_txt(p.get("assettype")) or "").lower()
    type_ = "acces_portage" if "hand" in genre else "rampe"
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"usbr:{ident}", "nom": _txt(p.get("assetname")), "type": type_, "coin": "acces",
        "eau": _txt(p.get("usbrproject")), "gestionnaire": _txt(p.get("operatingentity1")), "surface": _txt(p.get("assettype"))})}


NORMALISEURS = {fn.__name__: fn for fn in (acces_wa_wdfw, acces_wa_parcs, acces_wa_usbr)}
