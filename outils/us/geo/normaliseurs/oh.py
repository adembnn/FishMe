"""Ohio : normaliseurs de l'ODNR Division of Watercraft (guide des installations et guide de la pagaie).

Seuls des objets publics : ni téléphone, ni adresse, ni contact, ni commentaire libre. Les booléens Access valent -1 (vrai) et 0 (faux).
"""
import zlib


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _n(v):
    return v if isinstance(v, (int, float)) and not isinstance(v, bool) and v > 0 else 0


def oh_acces_bateau(f, dom=None):
    """Guide des installations nautiques (Facility Guide) : sites publics qui offrent une mise à l'eau (rampe ou mise à l'eau à la main)."""
    p = f["properties"]
    ident = p.get("ID")
    if ident is None or p.get("PUB") != -1:
        return None
    portage = p.get("HandLaunchOnly") == -1
    if not (p.get("FtLaunch") == -1 or portage):
        return None  # marina ou installation sans mise à l'eau
    rampes = _n(p.get("ConcRmp")) + _n(p.get("GRAVRMP")) + _n(p.get("OtherRmp"))
    # `ID` se répète d'un site à l'autre (249 valeurs pour 886 lignes) : on y ajoute une empreinte du nom pour avoir une clé unique et stable
    cle = f"{int(ident)}-{zlib.crc32((_txt(p.get('SiteName')) or '').encode('utf-8')) % 100000:05d}"
    out = {"id": f"oh-dow:{cle}", "nom": _txt(p.get("SiteName")), "type": "acces_portage" if portage else "rampe", "coin": "acces",
           "eau": _txt(p.get("WATERBODY")) or _txt(p.get("Waterway")), "comte": _txt(p.get("COUNTY")), "gestionnaire": _txt(p.get("AdminType"))}
    if rampes:
        out["rampes"] = rampes
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in out.items() if v is not None}}


def oh_acces_pagaie(f, dom=None):
    """Guide de la pagaie (Stream Access) : points d'accès aux cours d'eau ; les obstacles (HAZARD = -1 : barrages, chutes) sont écartés.
    Le texte libre FEATURE (itinéraire) n'est pas copié : le nom retombe sur le cours d'eau."""
    p = f["properties"]
    ident = p.get("ID")
    if ident is None or p.get("HAZARD") != 0:
        return None
    out = {"id": f"oh-paddle:{int(ident)}", "type": "rampe" if p.get("LAUNCHRAMP") == -1 else "acces", "coin": "acces",
           "eau": _txt(p.get("WATERWAY")), "comte": _txt(p.get("COUNTY"))}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in out.items() if v is not None}}


NORMALISEURS = {"oh_acces_bateau": oh_acces_bateau, "oh_acces_pagaie": oh_acces_pagaie}
