"""SD : Game, Fish and Parks, couche « Boating Access » (SD_Public/BoatRamps, couche 0). Ni photo, ni commentaire libre, ni
description de lieu (texte libre) n'est copié ; seuls des faits publics."""


def _txt(v):
    v = v.strip() if isinstance(v, str) else v
    return v if v not in ("", "None", None) else None


def acces_sd_gfp(f, dom=None):
    p = f["properties"]
    if _txt(p.get("Display")) == "0":
        return None
    ident = _txt(p.get("GlobalID")) or p.get("OBJECTID")
    if ident is None:
        return None
    ident = str(ident).strip("{}").lower()
    props = {"id": f"sd-gfp:{ident}", "nom": _txt(p.get("Name")), "type": "rampe", "coin": "acces",
             "comte": _txt(p.get("County")), "gestionnaire": _txt(p.get("Ownership")),
             "voies": p.get("NumLanes"), "surface": _txt(p.get("SurfaceType")), "statut": _txt(p.get("Status"))}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_sd_gfp": acces_sd_gfp}
