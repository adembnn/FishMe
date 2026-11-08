"""GA : points d'accès à l'eau du Georgia DNR, Wildlife Resources Division (service « WRD_Water_Access_Points »).

Ne copie ni téléphone, ni « Directions », ni liens, ni indicateurs d'espèces ; seulement nom, type, plan d'eau, comté, gestionnaire.
Les points côtiers (eau salée), les sites fermés et `Draw = No` sont écartés.
"""


def _t(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def acces_ga_wrd(f, dom=None):
    p = f["properties"]
    ident = p.get("ID")
    if ident is None or _t(p.get("Name")) is None:
        return None
    if _t(p.get("Status")) == "Closed" or _t(p.get("WaterType")) == "Coastal" or _t(p.get("Draw")) == "No":
        return None
    if _t(p.get("Ramp")) == "Y" or (p.get("NumLanes") or 0) > 0:
        type_ = "rampe"
    elif _t(p.get("BankOnly")) == "Y":
        type_ = "peche_rive"
    elif _t(p.get("CanoeAcc")) == "Y":
        type_ = "acces_portage"
    else:
        type_ = "acces"
    props = {"id": f"ga-wrd:{ident}", "nom": _t(p.get("Name")), "type": type_,
             "coin": "peche" if type_ == "peche_rive" else "acces", "eau": _t(p.get("Waterbody")),
             "comte": _t(p.get("County")), "gestionnaire": _t(p.get("Operator")) or _t(p.get("Owner")), "voies": p.get("NumLanes")}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_ga_wrd": acces_ga_wrd}
