"""US15 : normaliseur du Delaware (DNREC, couche Fishing Access de FirstMap). Faits seulement : nom, type, eau, comté, gestionnaire.
Le champ URL (une photo) et NOTES ne sont pas copiés. Un site marqué PUBLICACCESS = No est écarté."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s if s and s not in ("<Null>", "Null") else None


_TYPES = {
    "Boat Ramp": ("rampe", "acces"),
    "Canoe Launch": ("acces_portage", "acces"),
    "Boat Dock": ("acces", "acces"),
    "Fishing Pier": ("peche_rive", "peche"),
    "Shoreline Fishing": ("peche_rive", "peche"),
    "Surf Fishing Vehicle Access": ("peche_rive", "peche"),
}


def acces_de_fishing(f, dom=None):
    p = f["properties"]
    if (_txt(p.get("PUBLICACCESS")) or "").lower() == "no":
        return None
    oid = p.get("OBJECTID")
    if oid is None:
        return None
    type_, coin = _TYPES.get(_txt(p.get("FACILITY")) or "", ("acces", "acces"))
    nom = _txt(p.get("TIDAL_FISHING_ACCESS_AREAS")) or _txt(p.get("GNIS_NAME"))
    props = {"id": f"de-fish:{oid}", "nom": nom, "type": type_, "coin": coin,
             "eau": _txt(p.get("GNIS_NAME")), "comte": _txt(p.get("COUNTY")),
             "gestionnaire": _txt(p.get("DIVISION"))}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in props.items() if v is not None}}


NORMALISEURS = {"acces_de_fishing": acces_de_fishing}
