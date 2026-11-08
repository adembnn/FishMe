"""Texas : points d'accès listés par le TPWD (Texas Parks and Wildlife Department).
Rampes publiques (Inland Fisheries) et accès fluviaux loués par le TPWD (RACA, baux en cours seulement).
Description, directions, téléphone et liens de carte ne sont jamais copiés."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _nettoyer(p):
    return {k: v for k, v in p.items() if v is not None}


def acces_tx_rampes(f, dom=None):
    p = f["properties"]
    ident = _txt(p.get("TPWAID")) or (str(p["PWAID"]) if p.get("PWAID") is not None else None)
    if not ident:
        return None
    eau = _txt(p.get("AccessTypeDescription"))
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"tx-ramp:{ident}", "nom": eau, "type": "rampe", "coin": "acces", "eau": eau,
        "gestionnaire": "TPWD (liste)"})}


def acces_tx_raca(f, dom=None):
    p = f["properties"]
    if (_txt(p.get("Lease_Status")) or "").lower() != "current":
        return None
    nom = _txt(p.get("RACA_site_name"))
    if p.get("OBJECTID") is None or not nom:
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"tx-raca:{p['OBJECTID']}", "nom": nom, "type": "acces", "coin": "acces", "eau": _txt(p.get("River"))})}


NORMALISEURS = {"acces_tx_rampes": acces_tx_rampes, "acces_tx_raca": acces_tx_raca}
