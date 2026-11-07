"""Hawaï (US15) : rampes de mise à l'eau de la couche BoatingFacilities (DLNR, Division of Aquatic Resources ; Hawaii Statewide GIS Program).

On ne garde que `facility = Launch Ramp` et on retire les installations privées. Données de 2002, surtout côtières.
"""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _acces_hi_rampes(f, dom=None):
    p = f["properties"]
    ident = p.get("id")
    geom = f.get("geometry")
    if ident is None or not geom or geom.get("type") != "Point":
        return None
    if (_txt(p.get("facility")) or "").lower() != "launch ramp":
        return None
    juri = _txt(p.get("jurisdiction")) or ""
    if "private" in juri.lower():
        return None
    props = {"id": f"hi-dar:{ident}", "nom": _txt(p.get("name")), "type": "rampe", "coin": "acces",
             "gestionnaire": juri.replace("Faciltiy", "Facility") or None, "ile": _txt(p.get("island"))}
    return {"type": "Feature", "geometry": geom, "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"hi_acces_rampes": _acces_hi_rampes}
