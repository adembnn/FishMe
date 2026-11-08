"""Idaho : sites d'accès pêche et bateau de l'Idaho Department of Fish and Game (IDFG, service FFW).
Ne copie ni notes libres (`public_info_notes`), ni noms d'utilisateurs, ni codes de dossiers : nom, type, comté, propriétaire seulement."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import normaliser as nz  # noqa: E402


def acces_id_idfg(f, dom=None):
    p = f["properties"]
    ident = p.get("ID")
    if ident is None or (nz._txt(p.get("status")) or "").lower() != "active":
        return None
    rampe = (nz._txt(p.get("ramp")) or "").lower() == "yes"
    quai = (nz._txt(p.get("dock")) or "").lower() == "yes"
    genre = (nz._txt(p.get("fishing_boating")) or "").lower()
    type_ = "rampe" if rampe else ("peche_rive" if quai and genre == "fishing" else "acces")
    coin = "peche" if genre == "fishing" and not rampe else "acces"
    return {"type": "Feature", "geometry": f["geometry"], "properties": nz._nettoyer({
        "id": f"id-idfg:{ident}", "nom": nz._txt(p.get("site_name")), "type": type_, "coin": coin,
        "comte": nz._txt(p.get("county")), "gestionnaire": nz._txt(p.get("landowner"))})}


NORMALISEURS = {"acces_id_idfg": acces_id_idfg}
