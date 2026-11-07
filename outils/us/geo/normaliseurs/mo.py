"""Missouri Department of Conservation : couches Area_Feature_Layers (rampes 17, quais de pêche 19, jetées 20). Nom = nom de la zone MDC."""


def _txt(v):
    s = str(v).strip() if v is not None else ""
    return s or None


def _faire(prefixe, type_, coin):
    def norm(f, dom=None):
        p = f["properties"]
        ident = p.get("OBJECTID")
        if ident is None:
            return None
        pr = {"id": f"{prefixe}:{ident}", "nom": _txt(p.get("Area_Name")), "type": type_, "coin": coin}
        return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in pr.items() if v is not None}}
    return norm


NORMALISEURS = {"acces_mo_rampe": _faire("mo-ramp", "rampe", "acces"),
                "acces_mo_quai": _faire("mo-dock", "peche_rive", "peche"),
                "acces_mo_jetee": _faire("mo-jetty", "peche_rive", "peche")}
