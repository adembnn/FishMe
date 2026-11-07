#!/usr/bin/env python3
"""Fabrique exemples/evenements-fixture.csv : FIXTURE synthétique, aucune donnée réelle, déterministe.

Cas couverts : espèce partout, espèce rare, HUC8 assez fourni, HUC8 trop petit (repli HUC6), HUC8 isolé (repli État),
État trop petit (donnée insuffisante), deux milieux et deux engins, un événement dupliqué, un événement sans poisson.
Les noms d'espèces sont des noms scientifiques réels mais les fréquences sont inventées : ne rien en conclure.
"""
import csv
import os
import sys

ESPECES = [  # (nom, part en %, premier jour de l'espèce)
    ("Lepomis macrochirus", 95), ("Micropterus salmoides", 70), ("Esox lucius", 55), ("Perca flavescens", 48),
    ("Sander vitreus", 35), ("Ictalurus punctatus", 28), ("Salvelinus fontinalis", 22), ("Micropterus dolomieu", 18),
    ("Lepisosteus osseus", 12), ("Amia calva", 9), ("Acipenser fulvescens", 4), ("Cottus bairdii", 3), ("Umbra limi", 2),
    ("Notropis anogenus", 1),
]
SOURCE = "FIXTURE synthetique"


def presence(j, rang, pct):
    return (j * 37 + rang * 11) % 100 < pct


def evenements():
    lignes = []
    plan = [  # (huc8, etat, milieu, engin, nombre, decalage)
        ("07070001", "WI", "cours_d_eau", "electrofishing", 40, 0),
        ("07070002", "WI", "cours_d_eau", "electrofishing", 30, 7),
        ("07070003", "WI", "cours_d_eau", "electrofishing", 5, 13),
        ("07090001", "WI", "cours_d_eau", "electrofishing", 3, 17),
        ("07070001", "WI", "lac", "gill net", 6, 3),
        ("04030101", "MI", "cours_d_eau", "electrofishing", 4, 21),
    ]
    for huc8, etat, milieu, engin, n, dec in plan:
        for j in range(n):
            esp = [e for r, (e, pct) in enumerate(ESPECES) if presence(j + dec, r, pct)]
            if milieu == "lac":
                esp = [e for e in esp if e not in ("Cottus bairdii", "Salvelinus fontinalis")]
            annee = 2008 + (j * 5 + dec) % 16
            lignes.append(["%s-%s-%s-%03d" % (etat, huc8, milieu[:3], j), huc8, etat, milieu, engin, annee, SOURCE, ";".join(esp)])
    lignes.append(["WI-07070001-cou-000", "07070001", "WI", "cours_d_eau", "electrofishing", 2008, SOURCE, "Lota lota"])  # doublon : réunit les espèces
    lignes.append(["WI-07070002-cou-vide", "07070002", "WI", "cours_d_eau", "electrofishing", 2020, SOURCE, ""])  # événement sans poisson
    return lignes


if __name__ == "__main__":
    chemin = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "exemples", "evenements-fixture.csv")
    with open(chemin, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["evenement_id", "huc8", "etat", "milieu", "engin", "annee", "source", "especes"])
        w.writerows(evenements())
