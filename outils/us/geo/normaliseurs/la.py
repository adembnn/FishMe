"""Louisiane : points d'accès publics listés par le LDWF (Louisiana Department of Wildlife and Fisheries).
Nom d'objet, type, eau seulement : téléphone, e-mail, site web, horaires et notes libres ne sont jamais copiés."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _nettoyer(p):
    return {k: v for k, v in p.items() if v is not None}


def _public(acces):
    """Garde « Public… » (même avec un tarif ou un permis d'espace) ; écarte privé, inconnu, réservé aux campeurs."""
    a = (_txt(acces) or "").lower()
    return a.startswith("publi") and "registered" not in a and "member" not in a


def acces_la_ldwf(f, dom=None):
    p = f["properties"]
    ident = p.get("OBJECTID")
    if ident is None or not _public(p.get("Access")):
        return None
    ramp = (_txt(p.get("Ramp_and_P")) or "").lower()
    type_ = "rampe" if "ramp" in ramp or not ramp else "acces"
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"la-ldwf:{ident}", "nom": _txt(p.get("Boat_Launc")), "type": type_, "coin": "acces",
        "eau": _txt(p.get("Waterbody")), "gestionnaire": "LDWF (liste)"})}


def peche_rive_la_ldwf(f, dom=None):
    p = f["properties"]
    ident = p.get("FID") if p.get("FID") is not None else p.get("OBJECTID")
    nom = _txt(p.get("Site_Name"))
    if ident is None or not nom:
        return None
    pref = "la-bank" if "FID" in p else "la-comm"
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"{pref}:{ident}", "nom": nom, "type": "peche_rive", "coin": "peche"})}


NORMALISEURS = {"acces_la_ldwf": acces_la_ldwf, "peche_rive_la_ldwf": peche_rive_la_ldwf}
