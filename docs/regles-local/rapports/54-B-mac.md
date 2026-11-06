Décision débloquée : l'app peut afficher 218 règles brouillon de Meurthe-et-Moselle (54), ligne par ligne et sourcées ; 8 restent à trancher (incertain).

Lecteur B, 54 Meurthe-et-Moselle, lu le 2026-10-16. Fichier : outils/regles/dep-b/54.json (valider.py : OK, 226 règles, 7 textes).

Textes (tous OCR ; les tableaux ont été vérifiés sur l'image des pages)
- AP permanent DDT-ERC 2022-128, 2022-11-03 (copie mairie de Tucquegnieux) : entier.
- Avis annuel 2026 DDT-ERC 2025-071, 2025-11-22 : entier.
- Réserves 2026 DDT-ERC 2025-070, 2025-11-22 : entier. Graciation 2026 DDT-ERC 2025-069, 2025-11-22 : entier.
- Carpe de nuit 2026 DDT-ERC 2025-068, 2025-12-18 : entier. Lac de Pierre-Percée DDT-ERC-2024-108, 2024-11-28 : entier.
- DDT/2015/007 police de navigation de Pierre-Percée : lu en partie, aucune règle (pas de la pêche).

Règles par type : carpe_nuit 56, reserve 51, no_kill 33, ouverture 26, interdit 17, taille_min 17, mode_peche 12, quota_jour 8, autre 3, remise_eau 1, transport_vivant 1, categorie 1.
Par statut : brouillon 218, incertain 8.

Contradictions : aucune entre le permanent et l'avis 2026 (dates et tailles concordent une fois les formules calculées). Écarts de forme seulement :
- Le permanent art. 7-2 donne 4 lignes en 2e catégorie ; l'avis n'en parle pas. Le permanent continue de s'appliquer.
- Le permanent exclut l'arc-en-ciel des ouvertures (art. 2) mais pas des tailles (art. 5) ; l'avis dit « les truites ». Arc-en-ciel 25 cm : incertain.
- Art. 8-1 du permanent renvoie à « l'article 5 » (probablement 7) : règle incertain.

Corrections d'OCR vérifiées sur l'image
- Avis : brochet et sandre 2e catégorie « 1er au 25 janvier » (le texte brut lisait « 285 »).
- Pierre-Percée : carnassiers « limité à 1 » (chiffre absent du texte brut).
- Réserves : « La reculée dite Le Plain à Damelevières » absente du texte brut, présente sur l'image.
- Graciation Esch : « confluence avec l'Heymonrupt » (le texte brut lisait l'Esch).

Choix de découpage
- Un secteur de tableau = une règle (carpe de nuit, réserves, graciation). Étang Thiriet : 7 règles (une par week-end).
- Graciation : une règle no_kill par espèce citée ; « toutes espèces » = liste vide.
- « Étangs de Pré Albert, Chaudeney et Clément » (carpe de nuit) lu comme trois étangs : incertain.
- Dates 2026 calculées : plans d'eau en réserve 27 avril au 26 juin ; Meurthe 1er janvier au 26 avril ; Orne (Serry) 1er janvier au 1er juillet.
- Graciation de l'Orne : le texte dit « 1er juillet 2025 au 31 décembre 2026 » ; je mets du = 2026-01-01 et je cite le texte.

Ce qui manque
- Plan annexé de Pierre-Percée (zones interdites) : image seule, non exploitée.
- Pierre-Percée : fin de validité de l'arrêté 2024-108 non lue, donc expire_le null. Brochet et sandre y suivent les périodes départementales : incertain, dates non recopiées.
- « Truite commune » (graciation Chiers) écrit « truite » tel quel, pas fario.
- Le permanent n'est lu que dans une copie de mairie ; la version de la préfecture n'a pas été comparée.
- Classement 1re/2e catégorie des cours d'eau du 54 : aucun texte lu, donc aucune règle de catégorie par cours d'eau.

Les 3 règles les plus risquées
1. 54-pierre-percee-carnassiers-quota-jour : chiffre « 1 » lu sur l'image seulement.
2. 54-carpe-nuit-etang-pre-albert / -chaudeney / -clement : découpage en 3 étangs non sûr, premiers week-ends sans dates.
3. 54-truite-arc-en-ciel-taille-min-departement : le texte dit « les truites » sans nommer l'arc-en-ciel.
