"""Normaliseur du Maine (US15, groupe ne-nord) : sites d'accès bateau de la Maine GeoLibrary (Bureau of Parks and Lands).
Champs copiés : nom de l'eau, commune, comté, gestionnaire (code), type de rampe, places. Aucun contact ni note libre."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def acces_me_bateau(f, dom=None):
    p = f["properties"]
    ident = p.get("FILE_NO")
    if ident is None:
        return None
    t = (_txt(p.get("TYPE")) or "").upper()
    type_ = {"TR": "rampe", "CI": "acces_portage", "LF": "acces"}.get(t, "acces")
    props = {"id": f"me-bateau:{ident}", "nom": _txt(p.get("WATER_BODY")), "type": type_, "coin": "acces",
             "eau": _txt(p.get("WATER_BODY")), "comte": _txt(p.get("COUNTY")), "commune": _txt(p.get("MCD")),
             "gestionnaire": _txt(p.get("OWNSHIP")), "surface": _txt(p.get("TYPERAMP")),
             "marees": _txt(p.get("TIDE_COMBO")), "places_remorque": p.get("RIGPARK")}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_me_bateau": acces_me_bateau}
