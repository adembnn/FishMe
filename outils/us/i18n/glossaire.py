#!/usr/bin/env python3
"""Compte les occurrences de chaque terme de glossaire.tsv dans l'inventaire et écrit reports/us/i18n/glossaire.md.

Les lignes « verdict » et « unité » et « permis de pêche » sont toujours gardées ; le reste est classé par nombre de textes contenant le terme
(interface Swift + phrases de règles + conseils) et coupé à 150 termes. Lancer d'abord extraire_textes.py.
Usage : python3 -I outils/us/i18n/glossaire.py [--racine .]
"""
import argparse
import csv
import os
import re

TOTAL = 150


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--racine", default=".")
    ap = ap.parse_args()
    dossier = os.path.join(ap.racine, "reports/us/i18n")
    corpus = {"ui": [], "regles": [], "conseils": []}
    lignes = []
    for nom in ("inventaire.csv", "inventaire-regles.csv"):
        with open(os.path.join(dossier, nom), encoding="utf-8") as f:
            lignes += list(csv.DictReader(f))
    if True:
        for r in lignes:
            t = re.sub(r"\\\(.*?\)", " ", r["texte"])
            if r["origine"] == "swift" and not r["type"].startswith("interne"):
                corpus["ui"].append(t)
            elif r["type"] in ("json:phrase", "json:texte"):
                corpus["conseils" if "conseils.json" in r["fichier"] else "regles"].append(t)
    termes = []
    with open(os.path.join(ap.racine, "outils/us/i18n/glossaire.tsv"), encoding="utf-8") as f:
        for r in csv.DictReader(f, delimiter="\t"):
            rx = re.compile(r["motif_fr"], re.I)
            r["n"] = {k: sum(1 for t in v if rx.search(t)) for k, v in corpus.items()}
            r["total"] = sum(r["n"].values())
            termes.append(r)
    def force(t):
        return t["categorie"] in ("verdict", "unité") or t["motif_fr"] == "permis de pêche"
    forces = [t for t in termes if force(t)]
    autres = sorted([t for t in termes if not force(t)], key=lambda t: -t["total"])
    gardes = forces + autres[: TOTAL - len(forces)]
    ecartes = autres[TOTAL - len(forces):]
    ordre = ["verdict", "règle", "unité", "eau", "espèce", "matériel", "app"]
    noms = {"verdict": "Verdicts et vocabulaire de la loi", "règle": "Règles de pêche", "unité": "Unités et mesures",
            "eau": "Eaux et lieux", "espèce": "Espèces", "matériel": "Matériel et techniques", "app": "Interface"}
    L = ["# Glossaire FR vers EN US (150 termes)", "",
         "Généré par `outils/us/i18n/glossaire.py` depuis `outils/us/i18n/glossaire.tsv` et `inventaire.csv`. "
         "Colonnes de comptage : nombre de textes contenant le terme (interface Swift / phrases de règles JSON / conseils JSON). "
         "Le mot n'est pas traduit mot à mot quand la colonne « À ne pas utiliser » l'interdit : on reformule.", "",
         "Corpus comptés : %d textes d'interface, %d phrases de règles, %d conseils. %d termes candidats, %d retenus (%d forcés : verdicts, unités, permis de pêche ; puis par fréquence)."
         % (len(corpus["ui"]), len(corpus["regles"]), len(corpus["conseils"]), len(termes), len(gardes), len(forces)), ""]
    for cat in ordre:
        lignes = sorted([t for t in gardes if t["categorie"] == cat], key=lambda t: -t["total"])
        if not lignes:
            continue
        L += ["## %s" % noms[cat], "", "| FR (motif) | EN US | À ne pas utiliser | Interface / règles / conseils | Note |", "|---|---|---|---|---|"]
        for t in lignes:
            n = t["n"]
            L.append("| `%s` | %s | %s | %d / %d / %d | %s |" % (t["motif_fr"].replace("|", "\\|"), t["en_us"], t["a_ne_pas_utiliser"], n["ui"], n["regles"], n["conseils"], t["note"]))
        L.append("")
    L += ["## Mots à ne jamais afficher côté US", "",
          "legal, illegal, lawful, allowed, authorized (authorised), permitted, permissible, within the law, legal size, legal limit, keeper, "
          "OK to keep, safe to keep, you can keep it, you may keep, approved, compliant, guaranteed, best spot, good spot, hot spot, "
          "the fish will bite, fishing score ou index, pourcentage de confiance de l'IA. Orthographe US : license, color, center, gray.", "",
          "Écartés faute de place (%d) : %s." % (len(ecartes), ", ".join(t["motif_fr"] for t in ecartes)), ""]
    with open(os.path.join(dossier, "glossaire.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(L))
    print("%d termes retenus, %d écartés" % (len(gardes), len(ecartes)))


if __name__ == "__main__":
    main()
