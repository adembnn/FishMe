"""Alaska (US15) : points d'accès publics du BLM Alaska (service ArcGIS du BLM, couches Boat Launch, Boat Ramp, Boat Takeout, Fishing).

Seuls le nom et la position passent ; la description libre du service (espèces, notes) n'est pas copiée.
Les rampes d'ADF&G ne sont PAS lues : les conditions d'ADF&G interdisent la redistribution sans accord écrit (voir etats/AK.json).
"""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _acces_ak_blm(f, dom=None):
    p = f["properties"]
    oid = p.get("OBJECTID")
    sous = (_txt(p.get("FET_SUBTYPE")) or "").lower()
    geom = f.get("geometry")
    if oid is None or not geom or geom.get("type") != "Point":
        return None
    nom = _txt(p.get("FET_NAME"))
    if sous in ("boat launch", "boat ramp"):
        type_, coin = "rampe", "acces"
    elif sous == "boat takeout":
        type_, coin = "acces", "acces"
    else:  # couche « Fishing » : repère de pêche listé par le BLM
        type_, coin = "peche_rive", "peche"
        if nom and nom.endswith("(Fishing)"):
            nom = nom[: -len("(Fishing)")].strip()
    props = {"id": f"ak-blm:{type_}:{oid}", "nom": nom, "type": type_, "coin": coin, "gestionnaire": "BLM Alaska"}
    return {"type": "Feature", "geometry": geom, "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"ak_acces_blm": _acces_ak_blm}
