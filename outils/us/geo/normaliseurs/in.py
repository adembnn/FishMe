"""Indiana : normaliseur des sites d'accès à la pêche de l'IDNR Division of Fish and Wildlife (Fish_Access_RO).

Seuls des champs publics sont copiés ; contacts, baux, commentaires et rapports de pêche ne le sont pas.
"""
import zlib


def _txt(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _oui(v):
    return (_txt(v) or "").lower() == "yes"


def in_acces_peche(f, dom=None):
    p = f["properties"]
    ident = p.get("accessid")
    if ident is None or (_txt(p.get("public_view")) or "").lower() == "no":
        return None
    genre = (_txt(p.get("type_of_la")) or "").lower()
    if _oui(p.get("boat_ramp")) or genre == "boat ramp":
        type_ = "rampe"
    elif genre in ("carry down", "canoe ramp"):
        type_ = "acces_portage"
    elif genre == "shoreline" or _oui(p.get("shoreline")) or _oui(p.get("fishing_pier")):
        type_ = "peche_rive"
    else:
        type_ = "acces"
    # `accessid` se répète pour deux sites différents (900 : River Bend Park et Rogers Park) : empreinte du nom en plus
    cle = f"{int(ident)}-{zlib.crc32((_txt(p.get('site_name')) or '').encode('utf-8')) % 100000:05d}"
    out = {"id": f"in-fas:{cle}", "nom": _txt(p.get("site_name")), "type": type_, "coin": "peche" if type_ == "peche_rive" else "acces",
           "eau": _txt(p.get("waterbody")), "comte": _txt(p.get("county")), "milieu": _txt(p.get("water_type"))}
    return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in out.items() if v is not None}}


NORMALISEURS = {"in_acces_peche": in_acces_peche}
