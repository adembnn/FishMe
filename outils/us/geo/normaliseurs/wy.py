"""Wyoming : installations et accès de rivière listés par le Wyoming Game and Fish Department (WGFD, guide de pêche).
Ne copie ni notes libres (`Notes_Explanation`, `Egress_Location_Notes`), ni coordonnées UTM, ni contacts."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import normaliser as nz  # noqa: E402

TYPES = {"boat ramp": ("rampe", "acces"), "boat dock": ("peche_rive", "acces"), "fishing pier": ("peche_rive", "peche")}


def acces_wy_installations(f, dom=None):
    """Rampes, quais et pontons du guide de pêche ; parkings, toilettes, campings et terrain privé sont écartés."""
    p = f["properties"]
    ident = p.get("OBJECTID")
    t = TYPES.get((nz._txt(p.get("FacilityType")) or "").lower())
    if ident is None or not t or (nz._txt(p.get("AreaType_Ownership")) or "").lower() == "private":
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": nz._nettoyer({
        "id": f"wy-fg:{ident}", "nom": nz._txt(p.get("FacilityName")), "type": t[0], "coin": t[1],
        "eau": nz._txt(p.get("WaterName")), "gestionnaire": nz._txt(p.get("AreaType_Ownership"))})}


def acces_wy_riviere(f, dom=None):
    """Points de mise à l'eau et de sortie pour la descente en rivière (couche WGFD « River Access Points »)."""
    p = f["properties"]
    ident = p.get("OBJECTID")
    if ident is None:
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": nz._nettoyer({
        "id": f"wy-riv:{ident}", "nom": nz._txt(p.get("LaunchLocation")), "type": "acces", "coin": "acces",
        "eau": nz._txt(p.get("StreamName"))})}


NORMALISEURS = {"acces_wy_installations": acces_wy_installations, "acces_wy_riviere": acces_wy_riviere}
