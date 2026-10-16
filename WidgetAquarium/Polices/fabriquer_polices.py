#!/usr/bin/env python3
"""Fabrique les deux polices « masques clignotants » du widget Aquarium.

Technique de Bryce Bostwick (MIT, github.com/brycebostwick/WidgetAnimation) :
`Text(date, style: .timer)` change de chiffre chaque seconde. Avec une police où
les chiffres pairs sont un carré plein et les impairs vides, le dernier caractère
du chrono clignote (1 s plein, 1 s vide). Deux masques décalés d'1/8 s (pair
plein / impair plein) se recoupent 1/8 s toutes les 2 s : une image à la fois.

Usage : python3 fabriquer_polices.py [dossier_de_sortie]   (défaut : ce dossier)
Dépendance : fonttools (pip install fonttools).
"""
import sys
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

# Métriques : em = avance = hauteur de ligne = 1000.
EM = 1000
MONTEE = 800       # ascender (hhea, OS/2 typo, OS/2 win)
DESCENTE = -200    # descender ; MONTEE - DESCENTE = 1000 = hauteur de ligne
INTERLIGNE = 0     # lineGap nul : aucun espace vertical entre lignes

NOMS_CHIFFRES = ["zero", "one", "two", "three", "four",
                 "five", "six", "seven", "eight", "nine"]


def carre():
    """Carré plein : toute la boîte d'avance, de la descente à la montée."""
    stylo = TTGlyphPen(None)
    stylo.moveTo((0, DESCENTE))
    stylo.lineTo((0, MONTEE))
    stylo.lineTo((EM, MONTEE))
    stylo.lineTo((EM, DESCENTE))
    stylo.closePath()
    return stylo.glyph()


def vide():
    return TTGlyphPen(None).glyph()


def caracteres_vides():
    """Tout ce qu'un chrono (ou son environnement) peut afficher hors chiffres :
    ASCII imprimable, espaces insécables/fines, signes moins, séparateurs."""
    codes = set(range(0x20, 0x7F)) - set(range(0x30, 0x3A))
    codes |= {0xA0, 0x2007, 0x2008, 0x2009, 0x200A, 0x202F, 0x2212, 0x2013,
              0x2014, 0x2010, 0x2011, 0x00B7, 0x2236}
    return codes


def fabriquer(chemin, famille, pleins_pairs):
    ordre = [".notdef", "space"] + NOMS_CHIFFRES + ["colon", "vide"]
    cmap = {0x20: "space", 0x3A: "colon"}
    for i, nom in enumerate(NOMS_CHIFFRES):
        cmap[0x30 + i] = nom
    for code in caracteres_vides():
        cmap.setdefault(code, "vide")

    glyphes = {}
    for nom in ordre:
        glyphes[nom] = vide()
    for i, nom in enumerate(NOMS_CHIFFRES):
        if (i % 2 == 0) == pleins_pairs:
            glyphes[nom] = carre()

    fb = FontBuilder(EM, isTTF=True)
    fb.setupGlyphOrder(ordre)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphes)
    metriques = {}
    for nom in ordre:
        metriques[nom] = (EM, 0)  # avance fixe (chiffres tabulaires), lsb 0
    fb.setupHorizontalMetrics(metriques)
    fb.setupHorizontalHeader(ascent=MONTEE, descent=DESCENTE, lineGap=INTERLIGNE)
    ps = famille.replace(" ", "") + "-Regular"
    fb.setupNameTable({
        "familyName": famille,
        "styleName": "Regular",
        "uniqueFontIdentifier": ps,
        "fullName": famille + " Regular",
        "psName": ps,
        "version": "Version 1.000",
        "licenseDescription": "Police de masque fabriquee par script, technique "
                              "de Bryce Bostwick (MIT).",
    })
    fb.setupOS2(
        sTypoAscender=MONTEE, sTypoDescender=DESCENTE, sTypoLineGap=INTERLIGNE,
        usWinAscent=MONTEE, usWinDescent=-DESCENTE,
        fsSelection=(1 << 6) | (1 << 7),  # REGULAR + USE_TYPO_METRICS
        version=4, xAvgCharWidth=EM, usWeightClass=400, usWidthClass=5,
        sxHeight=MONTEE, sCapHeight=MONTEE,
    )
    fb.setupPost(isFixedPitch=1)
    fb.save(str(chemin))
    return ps


def main():
    sortie = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent
    sortie.mkdir(parents=True, exist_ok=True)
    for fichier, famille, pairs in [
        ("FishMeMasquePair.ttf", "FishMe Masque Pair", True),
        ("FishMeMasqueImpair.ttf", "FishMe Masque Impair", False),
    ]:
        ps = fabriquer(sortie / fichier, famille, pairs)
        print(f"{fichier} -> {ps}")


if __name__ == "__main__":
    main()
