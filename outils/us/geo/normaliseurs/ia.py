"""Iowa DNR : couche « Recreation Amenities » (Recreation/MapServer/8), filtrée sur les types d'accès à l'eau. Aucun champ libre copié."""


def _txt(v):
    s = str(v).strip() if v is not None else ""
    return s or None


TYPES = {"Boat Ramp": "rampe", "Boat Ramp - Gravel": "rampe", "Boat Ramp - Hard Surface": "rampe", "Boat Dock": "quai",
         "Fishing Dock": "peche_rive", "Fishing Access": "peche_rive", "Jetty": "peche_rive",
         "Paddling Access": "acces_portage", "Public Access": "acces"}


def acces_ia_dnr(f, dom=None):
    p = f["properties"]
    ident = p.get("OBJECTID")
    brut = _txt(p.get("Type")) or ""
    t = TYPES.get(brut)
    if ident is None or not t:
        return None
    nom = _txt(p.get("Name"))
    comte = _txt(p.get("County"))
    if not nom or nom.lower() == brut.lower():
        nom = brut + (f", {comte} County" if comte else "")
    pr = {"id": f"ia-dnr:{ident}", "nom": nom, "type": t, "coin": "peche" if t == "peche_rive" else "acces"}
    if comte:
        pr["comte"] = comte
    return {"type": "Feature", "geometry": f["geometry"], "properties": pr}


NORMALISEURS = {"acces_ia_dnr": acces_ia_dnr}
