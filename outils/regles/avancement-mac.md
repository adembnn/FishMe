# Avancement D3 sur le Mac (part d'Adem : vagues 7 et 8, 53→72)

Arrêt : 15 oct, 19h57 (pause demandée par Adem).

Fait :
- Copie de travail créée par `scripts/lot.sh D3` : `../Build-Challenge-Unaite-MWM-Apple-F-d3`, branche `lot/regles-france` (90ccc72). La copie Xcode n'a pas été touchée.
- Réseau : mayenne.gouv.fr et nord.gouv.fr répondent 200 depuis le Mac (legifrance 403).
- Tesseract absent du Mac (pas encore installé).

Par département (53 à 72) : collecté non, lecture A non, lecture B non, consensus non, poussé non.
Aucun sous-agent lancé, rien à pousser.

À la reprise : `brew install tesseract tesseract-lang`, vérifier corpus.py sur Mac, puis vague 7.

## Reprise avortée (15 oct., 20h03)
- Installation de Tesseract lancée puis arrêtée (Adem ferme le Mac) : à relancer, `brew install tesseract tesseract-lang`.
- Repéré pour la reprise : pymupdf manque aussi sur le Mac (`pip3 install pymupdf`) ; corpus.py cherche Tesseract dans des chemins Windows, à adapter (shutil.which) ; ajouter un verrou pour qu'un seul OCR tourne à la fois.
- Départements 53 à 72 : toujours rien de collecté, lu ou poussé.

## Nuit du 15 au 16 oct. (mis à jour 23h55)
- Poussés depuis le Mac : 53 (212 confirmées), 62 (160), 69 (187), 17 (128, toutes « vérifie l'arrêté » : fédération seule).
- Déjà poussés par le cloud (sautés) : 54 55 56 57 60 63 66 67 70 72 79 80 81 82 85 à 90.
- En cours : 2A (PDF obtenu, OCR), 59 (deux lectures), chasse des textes bloqués 47 61 64 65 68 83 (Wayback, Common Crawl, Calaméo par Playwright, préfecture au ralenti), collectes 58 71 73 74 76 84.
- corpus.py : Tesseract trouvé sur Mac, deux OCR au plus en même temps (commit 97bdd0d sur lot/regles-france).

## Fin de nuit (16 oct., 1h15)
- Poussés depuis le Mac (9) : 53 (212 confirmées), 62 (160), 69 (187), 17 (128, fédération seule), 2A (77), 83 (229), 76 (138), 84 (88), 47 (157).
- Tous les départements 2A, 17, 47, 53 à 90 sont maintenant sur regles/local (les autres poussés par le cloud).
- Textes téléchargés sans lecture pour le matin : outils/regles/corpus-complements/ (41, 32, 39, 40).
- Compléments de départements déjà poussés (59, 63, 66, 71, 54, réserves 74 82 88 89) : refusés par le contrôle du mode automatique, en attente de l'accord d'Adem.

- 49 Maine-et-Loire poussé le 16 oct. vers 1h40 (6 textes signés, 4 depuis la préfecture).

## Compléments (16 oct., 2h-4h30, avec l'accord d'Adem)
- Fusions poussées (toutes les règles déjà confirmées gardées) : 59 (166→428), 63 (202→309), 72 (394→446), 40 (318→375), 82 (158→219), 66 (184→318), 88 (233→361), 54 (184→214), 74 (229→384), 71 (341→393).
- Règles retirées car remplacées par un texte plus récent (option « Retirer ») : 41, ouverture anguille jaune au 31/08 (cat. 1 et 2), remplacée par le 31/07 du modificatif du 28/07/2026 (134→132) ; 71, 10 fenêtres de capture brochet de l'AP abrogé du 13/12/2024, chacune redonnée par le modificatif du 09/01/2026.
- Non lus : 32 (arrêtés du Département, sans règle) et 39 (lots de l'État à Vouglans). 89 : recherche sans résultat.
