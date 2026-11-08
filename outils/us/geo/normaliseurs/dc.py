"""US15 : normaliseur du District de Columbia. Source : points d'intérêt du National Park Service, région de la capitale
(NCR_Points_of_Interest_Public), types Boat Ramp, Water Access, Fishing et Boat Dock seulement. Les marinas et clubs de
bateaux sont écartés (privés ou commerciaux). Faits seulement : nom, type, gestionnaire (nom du site NPS)."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


_TYPES = {
    "Boat Ramp": ("rampe", "acces"),
    "Boat Dock": ("acces", "acces"),
    "Water Access": ("acces", "acces"),
    "Fishing": ("peche_rive", "peche"),
}


def acces_dc_nps(f, dom=None):
    p = f["properties"]
    oid = p.get("OBJECTID")
    if oid is None or _txt(p.get("POITYPE")) not in _TYPES:
        return None
    type_, coin = _TYPES[_txt(p.get("POITYPE"))]
    props = {"id": f"dc-nps:{oid}", "nom": _txt(p.get("POINAME")) or _txt(p.get("MAPLABEL")), "type": type_, "coin": coin,
             "gestionnaire": _txt(p.get("UNITNAME"))}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_dc_nps": acces_dc_nps}
