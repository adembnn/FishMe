"""Vérifie qu'un fichier de règles d'un département suit la forme de consigne-departement.md (version 2).

Usage : python3 valider.py <fichier.json>
Affiche OK, ou une ligne par défaut à corriger (et sort 1).
"""
import importlib.util
import json
import os
import re
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("consensus", os.path.join(ICI, "consensus.py"))
consensus = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(consensus)

TYPES = {"ouverture", "taille_min", "fenetre_capture", "quota_jour", "mode_peche", "interdit", "reserve", "no_kill",
         "carpe_nuit", "consommation", "horaire", "categorie", "remise_eau", "transport_vivant", "limite_eau_douce", "autre"}
CLES = {"ouverture": {"formule", "texte"}, "taille_min": {"cm", "texte"}, "fenetre_capture": {"min_cm", "max_cm", "texte"},
        "quota_jour": {"nombre", "texte"}, "mode_peche": {"lignes_max", "hamecons_max", "mouches_max", "maille_mm_min", "texte"},
        "categorie": {"classe", "texte"}}
NOMS = set(consensus.CODES) | {c for _, c in consensus.NOMS}
DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def defauts(donnees):
    if not isinstance(donnees.get("regles"), list) or not isinstance(donnees.get("textes"), list):
        yield "il manque la liste « textes » ou « regles »"
        return
    vus = set()
    for i, r in enumerate(donnees["regles"]):
        q = f"règle {i} ({r.get('id')})"
        if r.get("id") in vus:
            yield f"{q} : id en double"
        vus.add(r.get("id"))
        if r.get("type") not in TYPES:
            yield f"{q} : type inconnu « {r.get('type')} »"
        for e in r.get("especes") or []:
            if e not in NOMS and not str(e).startswith("autre:"):
                yield f"{q} : espèce « {e} » hors liste (code Sandre, nom de la liste, ou autre:<nom>)"
        if str(r.get("categorie")) not in ("1", "2", "toutes"):
            yield f"{q} : catégorie « {r.get('categorie')} »"
        for champ in ("du", "au", "expire_le"):
            v = r.get(champ)
            if v is not None and not DATE.match(str(v)):
                yield f"{q} : {champ} n'est pas une date AAAA-MM-JJ"
        valeur = r.get("valeur")
        if not isinstance(valeur, dict):
            yield f"{q} : valeur doit être un objet"
        else:
            permises = CLES.get(r.get("type"), {"texte"})
            for k, v in valeur.items():
                if k not in permises:
                    yield f"{q} : clé de valeur « {k} » non prévue pour {r.get('type')} (permises : {', '.join(sorted(permises))})"
                elif k not in ("texte", "formule", "classe") and not isinstance(v, (int, float)):
                    yield f"{q} : valeur.{k} doit être un nombre"
        if r.get("statut") not in ("brouillon", "incertain"):
            yield f"{q} : statut « {r.get('statut')} »"
        if r.get("statut") == "brouillon" and not r.get("citation"):
            yield f"{q} : brouillon sans citation"
        if r.get("citation") and len(r["citation"]) > 400:
            yield f"{q} : citation trop longue"
        portee = r.get("portee")
        if not isinstance(portee, dict) or (portee.get("lieu") is not None and not isinstance(portee.get("lieu"), str)):
            yield f"{q} : portee.lieu doit être un texte ou null"
        if not (r.get("source") or {}).get("texte"):
            yield f"{q} : source.texte manquant"
        if not r.get("phrase"):
            yield f"{q} : phrase manquante"


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 1
    try:
        with open(sys.argv[1], encoding="utf-8") as f:
            donnees = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        print(f"illisible : {e}")
        return 1
    liste = list(defauts(donnees))
    for d in liste[:60]:
        print(d)
    if liste:
        print(f"{len(liste)} défauts")
        return 1
    print(f"OK : {len(donnees['regles'])} règles, {len(donnees['textes'])} textes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
