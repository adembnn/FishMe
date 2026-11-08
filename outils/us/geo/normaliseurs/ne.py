"""NE : Game and Parks Commission, « Boat Ramps View Layer for Public Web Map » (FeatureServer, couche 3). On ne garde que les
rampes dont AccessType est « Public » et qui ne sont pas d'anciennes rampes ; notes, liens Google et responsables non copiés."""


def _txt(v):
    v = v.strip() if isinstance(v, str) else v
    return v if v not in ("", "None", None) else None


def acces_ne_ngpc(f, dom=None):
    p = f["properties"]
    if _txt(p.get("AccessType")) != "Public" or _txt(p.get("Ramp_Status")) == "Defunct/Old Ramp":
        return None
    ident = p.get("rUID")
    if ident is None:
        return None
    zone = _txt(p.get("rAreaName"))
    eau = _txt(p.get("WaterbodyName"))
    if zone and eau and zone != eau:
        nom = f"{eau} – {zone}"
    else:
        nom = zone or eau
    props = {"id": f"ne-ngpc:{ident}", "nom": nom, "type": "rampe", "coin": "acces",
             "eau": eau, "comte": _txt(p.get("County")), "gestionnaire": _txt(p.get("RampOwner")),
             "voies": p.get("rNumLanes"), "places_remorque": p.get("rParkingWithTrailers"),
             "surface": _txt(p.get("RampType")), "statut": _txt(p.get("Ramp_Status"))}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_ne_ngpc": acces_ne_ngpc}
