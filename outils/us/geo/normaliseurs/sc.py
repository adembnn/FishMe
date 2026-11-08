"""SC : points d'accès publics du SCDNR (service « South Carolina Public Water Access PUBLIC VIEW »).

Ne copie ni adresse, ni « directions », ni commentaires libres, ni liste d'espèces ; seulement nom, type, plan d'eau, comté, propriétaire.
"""


def _t(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def acces_sc_dnr(f, dom=None):
    p = f["properties"]
    ident = _t(p.get("WaterAccessID")) or _t(p.get("GlobalID"))
    if not ident or _t(p.get("WaterType")) == "Saltwater" or _t(p.get("Status")) not in (None, "Active") \
            or _t(p.get("PublicAccess")) == "Closed":
        return None
    genre = _t(p.get("WaterAccessType")) or ""
    type_ = {"Boat Ramp": "rampe", "Paddle Launch": "acces_portage", "Bank": "peche_rive", "Pier": "peche_rive"}.get(genre, "acces")
    props = {"id": f"sc-dnr:{ident}", "nom": _t(p.get("WaterAccessName")), "type": type_,
             "coin": "peche" if type_ == "peche_rive" else "acces", "eau": _t(p.get("Waterbody")),
             "comte": _t(p.get("County")), "gestionnaire": _t(p.get("Owner")), "voies": p.get("LaunchLanes")}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_sc_dnr": acces_sc_dnr}
