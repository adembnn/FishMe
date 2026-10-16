# Polices « masques clignotants » (widget Aquarium)

Technique de Bryce Bostwick (MIT) : https://github.com/brycebostwick/WidgetAnimation

- `FishMeMasquePair.ttf` (PostScript `FishMeMasquePair-Regular`) : 0, 2, 4, 6, 8 = carré plein, 1, 3, 5, 7, 9 = vides.
- `FishMeMasqueImpair.ttf` (PostScript `FishMeMasqueImpair-Regular`) : l'inverse.
- Tous les autres caractères (`:`, espace, `-`, `.`, etc.) sont vides. Toutes les avances valent 1000 (em 1000, chiffres tabulaires).
- Métriques : montée 800, descente -200, lineGap 0 (hhea, OS/2 typo et win) : la hauteur de ligne vaut 1000 et le carré (0..1000 en x, -200..800 en y) la couvre entièrement, sans espace entre lignes.

Dans un `Text(date, style: .timer)`, le dernier chiffre clignote (1 s plein, 1 s vide). Deux masques décalés d'1/8 s se recoupent 1/8 s toutes les 2 s.

## Régénérer

    pip install fonttools
    python3 WidgetAquarium/Polices/fabriquer_polices.py

## Branchement (lot A : cible et Info.plist)

L'extension widget FishMeWidget doit :
- avoir les deux `.ttf` dans sa cible (Copy Bundle Resources) ;
- les déclarer dans son Info.plist, clé `UIAppFonts` : `FishMeMasquePair.ttf`, `FishMeMasqueImpair.ttf` ;
- les appeler par leur nom PostScript : `Font.custom("FishMeMasquePair-Regular", size:)`.
