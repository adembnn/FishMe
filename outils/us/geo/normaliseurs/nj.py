"""Normaliseurs du New Jersey (NJDEP). Aucune dépendance : fonctions locales seulement."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _nettoyer(p):
    return {k: v for k, v in p.items() if v is not None}


def acces_nj_lacs(f, dom=None):
    """NJDEP Fish and Wildlife, « Great Fishing Close to Home » : plans d'eau choisis par l'agence (téléphone et adresse non copiés)."""
    p = f["properties"]
    ident = p.get("ID") if p.get("ID") is not None else p.get("OBJECTID")
    nom = _txt(p.get("WATERBODY"))
    if ident is None or not nom:
        return None
    rampe = (_txt(p.get("BOAT_RAMP")) or "").upper() == "Y"
    portage = (_txt(p.get("CAR_TOP_LAUNCH")) or "").upper() == "Y"
    type_ = "rampe" if rampe else ("acces_portage" if portage else "acces")
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"nj-lac:{ident}", "nom": nom, "type": type_, "coin": "acces", "eau": nom,
        "gestionnaire": _txt(p.get("OWNER"))})}


def acces_nj_marees(f, dom=None):
    """NJDEP, « NJ Public Access Locations » (eaux à marée) : seulement pêche, quai ou rampe ; les commentaires libres ne sont pas copiés."""
    p = f["properties"]
    ident = _txt(p.get("PA_ID")) or p.get("OBJECTID")
    if ident is None or (_txt(p.get("REVIEW_TYPE")) or "") != "Public":
        return None
    rampe = (_txt(p.get("BOATLNCH")) or "") == "Yes"
    peche = (_txt(p.get("FISHING")) or "") == "Yes" or (_txt(p.get("PIER")) or "") == "Yes"
    if not rampe and not peche:
        return None
    rue, mun = _txt(p.get("STREET")), _txt(p.get("MUN_LABEL"))
    nom = ", ".join(x for x in (rue, mun) if x) or "Accès sans nom"
    type_ = "rampe" if rampe else "peche_rive"
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"nj-maree:{ident}", "nom": nom, "type": type_, "coin": "peche" if type_ == "peche_rive" else "acces",
        "eau": _txt(p.get("SHORELINE")), "comte": _txt(p.get("COUNTY_LAB"))})}


NORMALISEURS = {"acces_nj_lacs": acces_nj_lacs, "acces_nj_marees": acces_nj_marees}
