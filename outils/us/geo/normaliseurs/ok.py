"""Oklahoma (OWRB, atlas « Lakes of Oklahoma ») : rampes et quais de pêche. Pas de contact, pas de note libre."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _nettoyer(p):
    return {k: v for k, v in p.items() if v is not None}


TYPES = {"Boat Ramp": ("rampe", "acces"), "Fishing Dock / Pier / Jetty": ("peche_rive", "peche")}


def acces_ok_owrb(f, dom=None):
    p = f["properties"]
    ident = p.get("objectid")
    cible = TYPES.get(_txt(p.get("type")) or "")
    if ident is None or not cible or not f.get("geometry"):
        return None
    lac = _txt(p.get("lake"))
    nom = _txt(p.get("name"))
    if not nom and lac:
        nom = f"{lac} Lake, " + ("boat ramp" if cible[0] == "rampe" else "fishing dock")
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"ok-owrb:{ident}", "nom": nom, "type": cible[0], "coin": cible[1], "eau": lac})}


NORMALISEURS = {"ok_acces_owrb": acces_ok_owrb}
