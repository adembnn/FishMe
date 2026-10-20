"""Liste des especes a demander : tous les codes Sandre de especes.json (D1), jamais inventes.

Formats lus : especes.json de D1 (liste d'entrees avec `code_sandre`, ou dict avec "especes"),
especes-national.json (meme forme) et, en repli, species_source.csv de Titouan (colonne code_sandre).
Les codes de ces fichiers ne sont PAS presumes justes : `hubeau.py --verifier-especes` les compare au
nom latin renvoye par Hub'Eau pour chaque code_taxon.
"""
from __future__ import annotations

import csv
import json
import os


def charger(chemin: str) -> list[dict]:
    """Retourne [{"id", "nom", "latin", "code"}] pour les entrees qui ont un code Sandre (sans doublon de code)."""
    if chemin.endswith(".csv"):
        with open(chemin, encoding="utf-8", newline="") as f:
            lignes = [{"id": r["id"], "nom": r["nom_fr"], "latin": r["nom_latin"], "code_sandre": r["code_sandre"]}
                      for r in csv.DictReader(f, delimiter=";")]
    else:
        with open(chemin, encoding="utf-8") as f:
            d = json.load(f)
        lignes = d.get("especes", []) if isinstance(d, dict) else d
    out, codes = [], set()
    for e in lignes:
        code = e.get("code_sandre")
        if code in (None, "", "null"):
            continue
        code = str(code)
        if code in codes:
            continue
        codes.add(code)
        out.append({"id": e.get("id"), "nom": e.get("nom"), "latin": e.get("latin"), "code": code})
    return out


def trouver(explicite: str | None, defaut: str, repli_csv: str):
    """(chemin, avertissement). especes.json vide (D1 pas encore fusionne) -> repli sur le CSV de Titouan."""
    if explicite:
        return explicite, None
    if os.path.exists(defaut):
        try:
            if charger(defaut):
                return defaut, None
        except (ValueError, OSError):
            pass
    return repli_csv, (f"{defaut} absent ou vide (D1 pas fusionne) : repli sur {repli_csv} "
                       "(codes Sandre de Titouan, a verifier avec --verifier-especes)")


def _nom_cle(latin: str) -> str:
    return " ".join((latin or "").lower().replace("-", " ").split()[:2])


def comparer_latin(attendu: str, hubeau: str) -> bool:
    """Meme genre + espece (sous-espece ignoree). Hub'Eau garde d'anciens noms : un ecart est signale, pas corrige."""
    return _nom_cle(attendu) == _nom_cle(hubeau)
