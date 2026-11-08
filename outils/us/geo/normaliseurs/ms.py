"""Normaliseur Mississippi (US15, groupe deep-south). Source : MDWFP, couche « Boat Ramps » du service Public_Lakes."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from normaliser import _nettoyer, _txt  # noqa: E402


def acces_ms_rampes(f, dom=None):
    """Rampes publiques MDWFP. Champs « DIRECTIONS » (texte libre) et identifiants de rapport non copiés ; id = OBJECTID du service."""
    p = f["properties"]
    oid = p.get("OBJECTID")
    if oid is None:
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"ms-rampe:{oid}", "nom": _txt(p.get("FACILITY_NAME")) or _txt(p.get("WATERBODY")), "type": "rampe", "coin": "acces",
        "eau": _txt(p.get("WATERBODY")), "comte": _txt(p.get("COUNTY")), "gestionnaire": _txt(p.get("OWNER"))})}


NORMALISEURS = {"acces_ms_rampes": acces_ms_rampes}
