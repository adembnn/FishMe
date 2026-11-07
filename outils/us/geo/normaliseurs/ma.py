"""Massachusetts : Office of Fishing and Boating Access (DFG OFBA, via MassGIS). Aucun commentaire libre ni lien d'itinéraire copié."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from normaliser import _nettoyer, _txt  # noqa: E402


def acces_ma_ofba(f, dom=None):
    p = f["properties"]
    ident = p.get("OFBA_ID")
    if ident is None or (_txt(p.get("PENDING")) or "").lower() == "yes":
        return None
    codes = {c.strip() for c in (_txt(p.get("FACILITY_TYPE")) or "").split(",") if c.strip()}
    rampe = (_txt(p.get("RAMPTYPE")) or "").lower()
    if codes & {"A", "B"} and rampe in ("concrete", "gravel"):
        type_ = "rampe"
    elif codes & {"C", "D"} or (codes & {"A", "B"} and rampe == "cartop"):
        type_ = "acces_portage"
    elif codes and codes <= {"E", "F"}:
        type_ = "peche_rive"
    else:
        type_ = "acces"
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"ma-ofba:{ident}", "nom": _txt(p.get("FACNAME")), "type": type_,
        "coin": "peche" if type_ == "peche_rive" else "acces",
        "comte": _txt(p.get("TOWN")), "gestionnaire": _txt(p.get("MAINTRESP")),
        "rampes": p.get("NORAMPS")})}


NORMALISEURS = {"acces_ma_ofba": acces_ma_ofba}
