"""Kansas (KDWP) : trois couches de points publics. Aucune note libre, aucun contact n'est copié."""


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _nettoyer(p):
    return {k: v for k, v in p.items() if v is not None}


def _centre(geom):
    """Barycentre d'aire du plus grand anneau extérieur (repli : centre de la boîte). Point GeoJSON."""
    if geom["type"] == "Point":
        return geom
    anneaux = [geom["coordinates"][0]] if geom["type"] == "Polygon" else [p[0] for p in geom["coordinates"]]
    meilleur, aire_max = None, -1.0
    for a in anneaux:
        s = cx = cy = 0.0
        for k in range(len(a) - 1):
            x0, y0, x1, y1 = a[k][0], a[k][1], a[k + 1][0], a[k + 1][1]
            c = x0 * y1 - x1 * y0
            s += c
            cx += (x0 + x1) * c
            cy += (y0 + y1) * c
        if abs(s) > aire_max:
            aire_max = abs(s)
            if abs(s) > 1e-14:
                meilleur = [cx / (3 * s), cy / (3 * s)]
            else:
                xs, ys = [p[0] for p in a], [p[1] for p in a]
                meilleur = [(min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2]
    return {"type": "Point", "coordinates": meilleur} if meilleur else None


def acces_ks_riviere(f, dom=None):
    """KDWP, Statewide River Access : un accès public à une rivière."""
    p = f["properties"]
    fid = p.get("FID")
    if fid is None or not f.get("geometry"):
        return None
    eau = _txt(p.get("RiverName"))
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"ks-river:{fid}", "nom": f"{eau} (accès rivière)" if eau else None, "type": "acces", "coin": "acces", "eau": eau})}


def acces_ks_plans_eau(f, dom=None):
    """KDWP, réservoirs, lacs d'État et lacs de programme CFAP sans redevance : un point par plan d'eau listé."""
    p = f["properties"]
    fid = p.get("FID")
    if fid is None or not f.get("geometry"):
        return None
    nom = _txt(p.get("LABEL")) or _txt(p.get("ImpndmtNam"))
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"ks-lac:{fid}", "nom": nom, "type": "acces", "coin": "acces", "eau": nom,
        "classe": _txt(p.get("CLASS")), "region": _txt(p.get("REGION"))})}


def acces_ks_pecheurs_a_pied(f, dom=None):
    """KDWP, Walk-in Fishing Access (parcelles ouvertes aux pêcheurs à pied) : le point est le centre de la parcelle."""
    p = f["properties"]
    fid = p.get("FID")
    if fid is None or not f.get("geometry"):
        return None
    c = _centre(f["geometry"])
    if not c:
        return None
    comte = (_txt(p.get("COUNTY")) or "").title()
    return {"type": "Feature", "geometry": c, "properties": _nettoyer({
        "id": f"ks-wifa:{fid}", "nom": f"Walk-in fishing access, {comte} County" if comte else "Walk-in fishing access",
        "type": "acces", "coin": "peche", "comte": comte or None, "surface_ha": None})}


NORMALISEURS = {"ks_acces_riviere": acces_ks_riviere, "ks_acces_plans_eau": acces_ks_plans_eau,
                "ks_acces_pecheurs_a_pied": acces_ks_pecheurs_a_pied}
