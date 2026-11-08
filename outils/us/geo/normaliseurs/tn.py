"""Normaliseur Tennessee (US15, groupe deep-south). Source : TWRA, services publics hébergés sur ArcGIS Online (compte TWRA_GIS) :
Boat_Launch_Sites (rampes) et Fishing_Sites (sites de pêche depuis la rive). Le service tnmap.tn.gov de l'État ne répond pas depuis nos machines."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from normaliser import _nettoyer, _txt  # noqa: E402

# Propriétaires privés : le service les liste, mais on ne les copie pas (pas de lieu privé dans l'app).
PRIVES = {"private", "private land", "wma / private land", "marina"}


def _public(p):
    return (_txt(p.get("Owner")) or "").lower() not in PRIVES


def acces_tn_rampes(f, dom=None):
    """Rampes TWRA (couche « Boat Launch Sites »). « Directions » et « Comments » (textes libres) jamais copiés ; id = OBJECTID du service."""
    p = f["properties"]
    oid = p.get("OBJECTID")
    if oid is None or not _public(p):
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"tn-rampe:{oid}", "nom": _txt(p.get("Name")) or _txt(p.get("Waterway")), "type": "rampe", "coin": "acces",
        "eau": _txt(p.get("Waterway")), "comte": _txt(p.get("County")), "gestionnaire": _txt(p.get("Manager")) or _txt(p.get("Owner")),
        "rampes": p.get("Ramps")})}


def peche_tn_rive(f, dom=None):
    """Sites de pêche TWRA (couche « Fishing Sites »), type quai / rive."""
    p = f["properties"]
    oid = p.get("OBJECTID")
    if oid is None or not _public(p):
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"tn-peche:{oid}", "nom": _txt(p.get("Name")) or _txt(p.get("Waterway")), "type": "peche_rive", "coin": "peche",
        "eau": _txt(p.get("Waterway")), "comte": _txt(p.get("County")), "gestionnaire": _txt(p.get("Manager")) or _txt(p.get("Owner"))})}


NORMALISEURS = {"acces_tn_rampes": acces_tn_rampes, "peche_tn_rive": peche_tn_rive}
