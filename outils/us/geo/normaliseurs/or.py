"""Normaliseurs d'OR (US15, groupe ouest-int) : Oregon State Marine Board (état) et sources fédérales (BLM, USFS, NPS)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _federal_ouest as fed  # noqa: E402


def or_blm(f, dom=None):
    return fed.blm_rampe(f, "OR")


def or_usfs(f, dom=None):
    return fed.usfs_site(f, "OR")


def or_nps(f, dom=None):
    return fed.nps_poi(f, "OR")


def or_osmb(f, dom=None):
    """Oregon State Marine Board, Boating Access Sites : rampes affichées au public, hors sites fermés.
    Ni téléphone, ni contact, ni horaires, ni tarifs copiés."""
    p = f["properties"]
    ident = fed._txt(p.get("globalid"))
    if not ident or fed._txt(p.get("facility_type")) != "Boat Ramp" or fed._txt(p.get("public_display")) != "Yes":
        return None
    if (fed._txt(p.get("oa_status")) or "").lower() == "closed":
        return None
    lt = fed._txt(p.get("launch_type")) or ""
    if lt == "Trailered Boat Launch":
        type_ = "rampe"
    elif lt in ("Hand Carry Boat Launch", "Floating Kayak Dock"):
        type_ = "acces_portage"
    else:
        type_ = "acces"
    voies = fed._txt(p.get("ramp_lanes"))
    return {"type": "Feature", "geometry": f["geometry"], "properties": fed._propre({
        "id": f"or-osmb:{ident}", "nom": fed._txt(p.get("name")), "type": type_, "coin": "acces",
        "eau": fed._txt(p.get("waterway_name")), "comte": fed._txt(p.get("county")),
        "voies": int(voies) if voies and voies.isdigit() else None})}


NORMALISEURS = {"or_blm": or_blm, "or_usfs": or_usfs, "or_nps": or_nps, "or_osmb": or_osmb}
