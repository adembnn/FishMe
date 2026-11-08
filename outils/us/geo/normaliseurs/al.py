"""Normaliseur Alabama (US15, groupe deep-south). Source : ADCNR, « Alabama Public Access Sites » (comtés côtiers Mobile et Baldwin)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from normaliser import _nettoyer, _txt  # noqa: E402


def acces_al_cotier(f, dom=None):
    """Sites de l'inventaire côtier ADCNR. Seul le statut « Public Access Site » passe (les « Exclude Site » sont écartés par l'agence).
    Adresse, ville et champs libres non copiés ; id = FID du service."""
    p = f["properties"]
    if (_txt(p.get("Status")) or "") != "Public Access Site":
        return None
    fid = p.get("FID")
    if fid is None:
        return None
    return {"type": "Feature", "geometry": f["geometry"], "properties": _nettoyer({
        "id": f"al-acces:{fid}", "nom": _txt(p.get("Site_Name")), "type": "acces", "coin": "acces",
        "eau": _txt(p.get("Watershed")), "comte": _txt(p.get("County"))})}


NORMALISEURS = {"acces_al_cotier": acces_al_cotier}
