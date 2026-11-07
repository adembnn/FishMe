"""Rhode Island : accès de pêche et de mise à l'eau du RIDEM (RIGIS, Fishing and Boating Access 2024). Champs libres non copiés."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from normaliser import _nettoyer, _txt  # noqa: E402

TYPES = {"trailer ramp": ("rampe", "acces"), "smallcraft launch": ("acces_portage", "acces"), "fishing access": ("peche_rive", "peche")}


def acces_ri_dem(f, dom=None):
    p = f["properties"]
    ident = p.get("ID")
    if ident is None:
        return None
    type_, coin = TYPES.get((_txt(p.get("TYPE")) or "").lower(), ("acces", "acces"))
    eau = {"fresh": "douce", "salt": "salee"}.get((_txt(p.get("Wat_Ttp")) or "").lower())
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"ri-dem:{int(ident)}", "nom": _txt(p.get("NAME")), "type": type_, "coin": coin, "milieu": eau})}


NORMALISEURS = {"acces_ri_dem": acces_ri_dem}
