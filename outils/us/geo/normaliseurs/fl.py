"""FL : inventaire des rampes de mise à l'eau publiques de la FWC (FWC Florida Boat Ramp Inventory, eau douce seulement).

Ne copie ni téléphone, ni adresse postale, ni commentaires libres, ni URL de gestionnaire ; seulement nom, type, plan d'eau, comté, gestionnaire.
Sont écartés : eau salée ou saumâtre, sites fermés ou détruits, accès à usage restreint, hydravions, mises à l'eau pour la chasse.
"""

FERME = {"Closed with No Further Information", "Closed - Under Transition", "Temporarily Closed", "Permanently Closed", "Destroyed"}
HORS_SUJET = {"Seaplane Ramp", "Hand Launch for Hunting"}


def _t(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def acces_fl_fwc(f, dom=None):
    p = f["properties"]
    ident = _t(p.get("RampID")) or _t(p.get("GlobalID"))
    if not ident or _t(p.get("WaterType")) != "Freshwater" or _t(p.get("Status")) in FERME:
        return None
    if _t(p.get("AccessType")) == "Government Owned for Restricted Public Use" or _t(p.get("RampType")) in HORS_SUJET:
        return None
    genre = _t(p.get("RampType")) or ""
    type_ = "acces_portage" if genre.startswith("Hand Launch") else "rampe"
    props = {"id": f"fl-fwc:{ident}", "nom": _t(p.get("RampName")), "type": type_, "coin": "acces", "eau": _t(p.get("WaterBodyName")),
             "comte": (_t(p.get("County")) or "").title() or None, "gestionnaire": _t(p.get("PrimaryAdminEntity")),
             "voies": p.get("TotalLanes")}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_fl_fwc": acces_fl_fwc}
