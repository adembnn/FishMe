#!/usr/bin/env python3
"""Fabrique les 10 polices « masques clignotants » du widget Aquarium : FishMeClignoteChiffre0 … 9.

Technique de Bryce Bostwick (MIT, github.com/brycebostwick/WidgetAnimation, licence dans
LICENCE-modele-clignotant.txt). On part de SA police de masque (`modele-clignotant.otf`, celle de son
exemple qui marche dans un vrai widget) : une ligature remplace les deux derniers chiffres d'un chrono
(les secondes, « 00 » à « 59 ») par un carré plein ou par un glyphe vide.

Ici, `FishMeClignoteChiffreK` est plein seulement quand le chiffre des unités des secondes vaut K :
un masque plein 1 s toutes les 10 s. Deux masques décalés de 1/8 s se recoupent 1/8 s toutes les
10 s : 80 images à 8 images/s, en boucle de 10 s (voir HorlogeAnimation.swift).

Usage : python3 -I fabriquer_polices.py [dossier_de_sortie]   (défaut : ce dossier)
Dépendance : fonttools.
"""
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

ICI = Path(__file__).resolve().parent
CHIFFRES = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]


def fabriquer(k, sortie):
    police = TTFont(str(ICI / "modele-clignotant.otf"))
    for lookup in police["GSUB"].table.LookupList.Lookup:
        for sous_table in lookup.SubTable:
            for ligatures in sous_table.ligatures.values():
                for lig in ligatures:
                    unite = CHIFFRES.index(lig.Component[-1])
                    lig.LigGlyph = "ligaturefull" if unite == k else "ligatureempty"
    famille = f"FishMeClignoteChiffre{k}"
    ps = f"{famille}-Regular"
    for enregistrement in police["name"].names:
        if enregistrement.nameID in (1, 16):
            enregistrement.string = famille
        elif enregistrement.nameID == 3:
            enregistrement.string = f"1.000;FISH;{ps}"
        elif enregistrement.nameID == 4:
            enregistrement.string = f"{famille} Regular"
        elif enregistrement.nameID == 6:
            enregistrement.string = ps
    cff = police["CFF "].cff
    cff.fontNames = [ps]
    cff.topDictIndex[0].FullName = f"{famille} Regular"
    cff.topDictIndex[0].FamilyName = famille
    chemin = sortie / f"{famille}.otf"
    police.save(str(chemin))
    return chemin.name, ps


def main():
    sortie = Path(sys.argv[1]) if len(sys.argv) > 1 else ICI
    sortie.mkdir(parents=True, exist_ok=True)
    for k in range(10):
        print(*fabriquer(k, sortie), sep=" -> ")


if __name__ == "__main__":
    main()
