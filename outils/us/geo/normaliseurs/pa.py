"""Normaliseur de la Pennsylvanie (PFBC, via PASDA). Aucune dépendance : fonctions locales seulement."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _nettoyer(p):
    return {k: v for k, v in p.items() if v is not None}


def acces_pa_pfbc(f, dom=None):
    """PFBC, « Access » : zones d'accès à la pêche et à la navigation, publiques ou semi-publiques selon l'agence."""
    p = f["properties"]
    # ID_NO vaut 0 pour 162 accès de sentiers nautiques et se répète : l'identifiant du service (OBJECTID) est le seul unique.
    ident = p.get("OBJECTID")
    if ident is None:
        return None

    def oui(k):
        return (_txt(p.get(k)) or "").upper() == "Y"

    peche_seule = (_txt(p.get("LOCATION_U")) or "").lower() == "fishing only"
    if oui("RAMP"):
        type_ = "rampe"
    elif oui("SHORE_FISH") or oui("PIER") or peche_seule:
        type_ = "peche_rive"
    else:
        type_ = "acces_portage" if oui("HP") else "acces"
    nom = _txt(p.get("ACC_NAME")) or _txt(p.get("WATERBODY"))
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"pa-pfbc:{ident}", "nom": nom, "type": type_, "coin": "peche" if type_ == "peche_rive" else "acces",
        "eau": _txt(p.get("WATERBODY")), "comte": _txt(p.get("COUNTY")), "gestionnaire": _txt(p.get("OWNER"))})}


NORMALISEURS = {"acces_pa_pfbc": acces_pa_pfbc}
