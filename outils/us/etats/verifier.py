#!/usr/bin/env python3
"""Vérifie outils/us/etats/etats.json (hors réseau ; liens.py teste les URL).
Usage : python3 -I verifier.py [chemin]   (code de sortie 1 si une erreur)
"""
import json, sys
from collections import Counter
from pathlib import Path

USPS = ("AL AK AZ AR CA CO CT DE DC FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT "
        "NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY").split()
CLES = ("usps nom agence url_agence url_regles_eau_douce url_permis urls_statut prix_resident "
        "prix_non_resident timbres appli_officielle format_regles licence_reutilisation "
        "eaux_tribales_reciprocite niveau_vise verifie date_lecture notes").split()
FORMATS = {"pdf", "site_interactif", "donnees_ouvertes", "inconnu"}
QUALITES = {"officiel", "editeur", "tiers"}
MOTS_VERDICT = ("tu peux la garder", "autorisé")

def _prix(label, p, err):
    if p is None:
        return
    for k in ("montant", "monnaie", "annee", "source", "qualite"):
        if k not in p:
            err.append(f"{label}: clé {k} absente"); return
    if not isinstance(p["montant"], (int, float)) or isinstance(p["montant"], bool) or p["montant"] <= 0:
        err.append(f"{label}: montant invalide")
    if not isinstance(p["annee"], int) or not 2024 <= p["annee"] <= 2027:
        err.append(f"{label}: année invalide")
    if not isinstance(p["source"], str) or not p["source"].startswith("https://"):
        if not (isinstance(p["source"], str) and p["source"].startswith("http://dec.ny.gov/")):
            err.append(f"{label}: prix sans source https")
    if p["qualite"] not in QUALITES:
        err.append(f"{label}: qualité inconnue")

def verifier(d):
    err = []
    etats = d.get("etats", [])
    codes = [e.get("usps") for e in etats]
    for c, n in Counter(codes).items():
        if n > 1: err.append(f"{c}: doublon")
    for c in USPS:
        if c not in codes: err.append(f"{c}: État manquant")
    for c in codes:
        if c not in USPS: err.append(f"{c}: code inconnu")
    for e in etats:
        c = e.get("usps", "?")
        for k in CLES:
            if k not in e: err.append(f"{c}: clé {k} absente")
        if err and any(x.startswith(f"{c}: clé") for x in err): continue
        for k in ("url_agence", "url_regles_eau_douce", "url_permis"):
            u = e[k]
            if u is not None and not (u.startswith("https://") or u.startswith("http://dec.ny.gov/")):
                err.append(f"{c}: {k} pas en https")
        if not e["url_agence"]: err.append(f"{c}: url_agence vide")
        _prix(f"{c}.prix_resident", e["prix_resident"], err)
        _prix(f"{c}.prix_non_resident", e["prix_non_resident"], err)
        for t in e["timbres"]:
            if not t.get("source") or t.get("montant") is None:
                err.append(f"{c}: timbre sans montant ou source")
            elif not t["source"].startswith("http"):
                err.append(f"{c}: timbre source non URL")
        if e["format_regles"].get("type") not in FORMATS: err.append(f"{c}: format_regles.type inconnu")
        if e["niveau_vise"] not in (1, 2, 3): err.append(f"{c}: niveau_vise hors 1-3")
        if not isinstance(e["verifie"], bool): err.append(f"{c}: verifie non booléen")
        if e["verifie"]:
            for k in ("prix_resident", "prix_non_resident"):
                if not e[k] or e[k]["qualite"] != "officiel":
                    err.append(f"{c}: verifie=true sans {k} officiel")
            if e["urls_statut"].get("url_agence") not in ("ok", "bloque_robots"):
                err.append(f"{c}: verifie=true mais agence non joignable")
        for k in ("notes", "licence_reutilisation"):
            v = e[k] or ""
            if any(m in v.lower() for m in MOTS_VERDICT): err.append(f"{c}: mot de verdict permissif dans {k}")
    return err

def bilan(d):
    comp = part = vide = 0
    for e in d["etats"]:
        prix = bool(e["prix_resident"]) and bool(e["prix_non_resident"])
        urls = bool(e["url_regles_eau_douce"]) and bool(e["url_permis"])
        if prix and urls: comp += 1
        elif prix or urls or e["prix_resident"] or e["prix_non_resident"]: part += 1
        else: vide += 1
    return {"etats": len(d["etats"]), "complets": comp, "partiels": part, "vides": vide,
            "verifie": sum(e["verifie"] for e in d["etats"])}

def main(argv):
    f = Path(argv[1]) if len(argv) > 1 else Path(__file__).with_name("etats.json")
    d = json.loads(f.read_text())
    err = verifier(d)
    for x in err: print("ERREUR", x)
    print(bilan(d))
    return 1 if err else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
