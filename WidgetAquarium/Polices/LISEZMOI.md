# Polices « masques clignotants » (widget Aquarium)

Technique de Bryce Bostwick (MIT) : https://github.com/brycebostwick/WidgetAnimation

- `modele-clignotant.otf` : la police de son exemple (licence dans `LICENCE-modele-clignotant.txt`). Elle n'est pas déclarée dans l'app.
- `FishMeClignoteChiffre0.otf` à `FishMeClignoteChiffre9.otf` (PostScript `FishMeClignoteChiffreK-Regular`) : faites à partir
  du modèle. Les deux chiffres des secondes d'un chrono forment une ligature : carré plein (`ligaturefull`) quand le chiffre
  des unités vaut K, vide (`ligatureempty`) sinon. Tout le reste est vide. CFF, em 500, montée 500, descente 0.

Dans un `Text(date, style: .timer)`, la police K donne un masque plein 1 s toutes les 10 s. Deux masques décalés d'1/8 s
se recoupent 1/8 s : c'est la fenêtre d'une copie (`HorlogeAnimation.masques`, `AnimationWidget.swift`).

## Régénérer

    pip install fonttools
    python3 WidgetAquarium/Polices/fabriquer_polices.py

## Branchement (lot A : cibles et Info.plist)

Les cibles FishMeWidget et BuildChallenge doivent :
- avoir les 10 `FishMeClignoteChiffreK.otf` dans Copy Bundle Resources ;
- les déclarer dans leur Info.plist, clé `UIAppFonts` ;
- les appeler par leur nom PostScript : `Font.custom("FishMeClignoteChiffre3-Regular", size:)`.
