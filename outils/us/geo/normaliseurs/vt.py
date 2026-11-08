"""Normaliseur du Vermont (US15, groupe ne-nord) : Fishing Access Areas (Vermont Fish & Wildlife Department, ANR).
Les colonnes d'espèces du service ne sont pas copiées ici (poissons par zone : lot US16)."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def acces_vt_fw(f, dom=None):
    p = f["properties"]
    ident = p.get("id") if p.get("id") is not None else p.get("OID")
    if ident is None:
        return None
    at = (_txt(p.get("AccessType")) or "").lower()
    rampe = (_txt(p.get("RampType")) or "None").lower()
    if "shore" in at:
        type_, coin = "peche_rive", "peche"
    elif rampe not in ("none", "steps", ""):
        type_, coin = "rampe", "acces"
    else:
        type_, coin = "acces", "acces"
    props = {"id": f"vt-fw:{ident}", "nom": _txt(p.get("AccessName")) or _txt(p.get("WaterBody")), "type": type_, "coin": coin,
             "eau": _txt(p.get("WaterBody")), "comte": _txt(p.get("County")), "commune": _txt(p.get("Town")),
             "gestionnaire": _txt(p.get("Manager")), "surface": _txt(p.get("RampType"))}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_vt_fw": acces_vt_fw}
