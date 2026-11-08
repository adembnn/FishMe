"""Connecticut : rampes de mise à l'eau du DEEP (couche DEEP Boat Launches, CC0 d'après la fiche de l'élément ArcGIS)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from normaliser import _nettoyer, _txt  # noqa: E402


def acces_ct_deep(f, dom=None):
    p = f["properties"]
    ident = p.get("ACCESS_ID")
    if ident is None:
        return None
    lt = (_txt(p.get("LAUNCHTYPE")) or "").lower()
    type_ = "rampe" if "trailer" in lt else ("acces_portage" if "car" in lt else "acces")
    lien = _txt(p.get("LINK"))
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"ct-deep:{int(ident)}", "nom": _txt(p.get("LAUNCHNAME")), "type": type_, "coin": "acces",
        "lien": lien if lien and lien.startswith(("http://", "https://")) else None})}


NORMALISEURS = {"acces_ct_deep": acces_ct_deep}
