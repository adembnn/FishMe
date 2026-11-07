#!/usr/bin/env python3
"""US15 : vérifie la couverture géographique des 51 juridictions (50 États + DC) et écrit le tableau (--rapport).

Pour chaque code USPS : etats/<USPS>.json avec nom, agence, lien_plans ou lien_avis (https), emprise, et un bloc `couverture` :
  {"acces": {"statut": "ok|partiel|absent", "raison": "...", "sources_inaccessibles": [{"url": "...", "raison": "403"}]},
   "plans_eau": {...}, "lignes_eau": {...}, "licences_a_confirmer": ["..."], "manque": ["..."]}
Un statut « ok » exige un fichier embarqué non vide ; « partiel » et « absent » exigent une raison. Chaque fichier embarqué porte
source, licence (« non précisée » si non lue), URL et date. Aucun mot de permission dans les textes de source. Code de sortie 0 si 0 trou.
Usage : python3 -I verifier_couverture.py [--sortie DIR_GEO_US] [--rapport reports/us/couverture-geo.md] [--budget-mo 150]
"""
import argparse
import json
import os
import re
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
DEFAUT = os.path.join(ICI, "..", "..", "..", "Packages", "Core", "Sources", "Core", "Resources", "geo-us")
ETATS = ("AL AK AZ AR CA CO CT DE DC FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD "
         "TN TX UT VT VA WA WV WI WY").split()
COUCHES = {"acces": "points", "plans_eau": "plans-eau", "lignes_eau": "lignes-eau"}
STATUTS = {"ok", "partiel", "absent"}
MOTS = re.compile(r"autoris|allowed|\blegal\b|tu peux la garder|you can keep|accès libre|free access", re.I)


def lire(chemin):
    with open(chemin, encoding="utf-8") as f:
        return json.load(f)


def textes(doc):
    """Textes de méta-données seulement (pas les noms de lieux)."""
    for k in ("mention", "source", "licence", "lien_agence", "url_source"):
        if isinstance(doc.get(k), str):
            yield doc[k]
    for s in doc.get("sources") or []:
        for k in ("texte", "licence", "url"):
            if isinstance(s.get(k), str):
                yield s[k]


def verifier(sortie=DEFAUT, config=os.path.join(ICI, "etats")):
    trous, lignes, total = [], [], 0
    for u in ETATS:
        chemin = os.path.join(config, f"{u}.json")
        if not os.path.exists(chemin):
            trous.append(f"{u} : etats/{u}.json absent")
            continue
        cfg = lire(chemin)
        for k in ("nom", "agence", "emprise"):
            if not cfg.get(k):
                trous.append(f"{u} : `{k}` manquant")
        if not any(str(cfg.get(k, "")).startswith("https://") for k in ("lien_plans", "lien_avis")):
            trous.append(f"{u} : lien_plans ou lien_avis https manquant")
        cv = cfg.get("couverture")
        if not isinstance(cv, dict):
            trous.append(f"{u} : bloc `couverture` manquant")
            continue
        ligne = dict(etat=u, nom=cfg.get("nom"), cv=cv, comptes={}, mo=0.0)
        for cle, suffixe in COUCHES.items():
            bloc = cv.get(cle)
            if not isinstance(bloc, dict) or bloc.get("statut") not in STATUTS:
                trous.append(f"{u} : couverture.{cle}.statut absent ou hors de {sorted(STATUTS)}")
                continue
            f = os.path.join(sortie, f"{u}-{suffixe}.json")
            existe = os.path.exists(f)
            if bloc["statut"] != "ok" and not bloc.get("raison"):
                trous.append(f"{u} : couverture.{cle} « {bloc['statut']} » sans raison")
            if bloc["statut"] == "ok" and not existe:
                trous.append(f"{u} : couverture.{cle} « ok » mais {u}-{suffixe}.json absent")
            if not existe:
                continue
            doc = lire(f)
            ligne["mo"] += os.path.getsize(f) / 1e6
            n = doc.get("compte", 0)
            ligne["comptes"][cle] = n
            if bloc["statut"] == "ok" and not n:
                trous.append(f"{u} : {u}-{suffixe}.json vide alors que « ok »")
            srcs = doc.get("sources") or [doc]
            if not srcs:
                trous.append(f"{u} : {u}-{suffixe}.json sans source")
            for s in srcs:
                lic = s.get("licence")
                url = s.get("url") or s.get("url_source")
                date = s.get("date") or doc.get("date")
                if not lic or not url or not date or not (s.get("source") or s.get("texte")):
                    trous.append(f"{u} : {u}-{suffixe}.json : source, licence, URL ou date manquante")
            for t in textes(doc):
                if MOTS.search(t):
                    trous.append(f"{u} : {u}-{suffixe}.json : mot interdit dans « {t[:60]} »")
        for suffixe in ("avis",):
            f = os.path.join(sortie, f"{u}-{suffixe}.json")
            if os.path.exists(f):
                ligne["mo"] += os.path.getsize(f) / 1e6
        total += ligne["mo"]
        lignes.append(ligne)
    return trous, lignes, total


def rapport(lignes, total, budget):
    out = ["# Couverture géographique des États-Unis (généré par `outils/us/geo/verifier_couverture.py`)", "",
           f"Taille embarquée mesurée : {total:.1f} Mo (budget indicatif {budget} Mo). Statuts : ok = fichier embarqué non vide ; "
           "partiel = une partie seulement, raison donnée ; absent = rien, raison donnée.", "",
           "| État | Accès publics | Plans d'eau nommés | Lignes d'eau | Mo | Licences à confirmer | Ce qui manque |", "|---|---|---|---|---|---|---|"]
    for l in lignes:
        cv = l["cv"]
        def c(k):
            b = cv.get(k, {})
            n = l["comptes"].get(k)
            r = f" ({b.get('raison')})" if b.get("raison") else ""
            return f"{b.get('statut', '?')}{' ' + str(n) if n is not None else ''}{r}"
        out.append(f"| {l['etat']} {l['nom']} | {c('acces')} | {c('plans_eau')} | {c('lignes_eau')} | {l['mo']:.2f} | "
                   f"{len(cv.get('licences_a_confirmer', []))} | {'; '.join(cv.get('manque', [])) or '—'} |")
    return "\n".join(out) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--sortie", default=DEFAUT)
    ap.add_argument("--rapport")
    ap.add_argument("--budget-mo", type=float, default=150)
    a = ap.parse_args(argv)
    trous, lignes, total = verifier(a.sortie)
    if a.rapport:
        with open(a.rapport, "w", encoding="utf-8") as f:
            f.write(rapport(lignes, total, a.budget_mo))
    for t in trous:
        print("TROU", t)
    if total > a.budget_mo:
        print(f"TROU taille embarquée {total:.1f} Mo > {a.budget_mo} Mo : proposer un autre découpage à Titouan")
        trous.append("taille")
    print(f"{len(trous)} trou(s) ; {len(lignes)} juridictions lues ; {total:.1f} Mo")
    return 1 if trous else 0


if __name__ == "__main__":
    sys.exit(main())
