"""Normaliseurs de Californie (CA) : mises à l'eau du guide de pêche du CDFW (installations publiques), rampes du Bureau of Reclamation.

Seuls des objets d'agence publics et des scalaires : ni téléphone, ni e-mail, ni adresse, ni note libre, ni personne interrogée.
Les installations privées (Type_of_Ownership_Gov_or_Non = Private) sont exclues par le filtre `where` de la couche et ici.
"""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _nettoyer(p):
    return {k: v for k, v in p.items() if v is not None}


def _entier(v):
    try:
        n = int(str(v).strip())
    except (TypeError, ValueError):
        return None
    return n if n > 0 else None


def acces_ca_cdfw(f, dom=None):
    """CDFW Fishing Guide, installations de mise à l'eau (FGuideBoating), propriétaires publics seulement."""
    p = f["properties"]
    if (_txt(p.get("Type_of_Ownership_Gov_or_Non")) or "").lower() != "government":
        return None
    ident = p.get("OBJECTID")
    nom = _txt(p.get("Facility_Name"))
    if ident is None or not nom:
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"ca-cdfw:{ident}", "nom": nom, "type": "rampe", "coin": "acces",
        "eau": _txt(p.get("Water_Body")), "comte": _txt(p.get("County")),
        "gestionnaire": _txt(p.get("Owner")), "voies": _entier(p.get("NO_OF_RAMP_LANE_USE_ONE_TIME")),
        "surface": _txt(p.get("Facility_Type"))})}


def acces_ca_usbr(f, dom=None):
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


NORMALISEURS = {fn.__name__: fn for fn in (acces_ca_cdfw, acces_ca_usbr)}
