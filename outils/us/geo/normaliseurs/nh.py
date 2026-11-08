"""Normaliseur du New Hampshire (US15, groupe ne-nord) : NH Access Sites to Public Waters (NH Fish and Game).
Le champ libre ADDITIONAL (consignes locales) n'est pas copié ; seulement type, plan d'eau, commune, comté, gestionnaire."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def acces_nh_fg(f, dom=None):
    p = f["properties"]
    ident = _txt(p.get("PUBACC_ID"))
    if not ident:
        return None
    fg = (_txt(p.get("FGTYPE")) or "").upper()
    if fg == "RAMP":
        type_, coin = "rampe", "acces"
    elif fg == "SHOREBANK":
        type_, coin = "peche_rive", "peche"
    elif fg == "CARTOP":
        type_, coin = "acces_portage", "acces"
    else:
        type_, coin = "acces", "acces"
    props = {"id": f"nh-fg:{ident}", "nom": _txt(p.get("FACILITY")), "type": type_, "coin": coin,
             "eau": _txt(p.get("WATER_BODY")), "comte": _txt(p.get("COUNTY")), "commune": _txt(p.get("TOWN")),
             "gestionnaire": _txt(p.get("OWNERSHIP")), "eau_type": _txt(p.get("WB_TYPE")), "surface": _txt(p.get("RAMP"))}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_nh_fg": acces_nh_fg}
