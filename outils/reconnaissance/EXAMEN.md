# Examen d'acceptation du modèle (écrit AVANT l'entraînement)

Règle : le modèle n'entre dans l'app (`App/Prise/`) que s'il passe TOUS les seuils ci-dessous,
mesurés par `python3 -I examen.py` sur le jeu de test (jamais vu à l'entraînement ni à la validation).
Les seuils sont proposés par R1, Adem valide. Ils ne changent pas après avoir vu un score.

| # | Mesure | Seuil | Pourquoi |
|---|--------|-------|----------|
| 1 | Top-3 moyen par espèce (la bonne espèce est parmi les 3 proposées) | >= 90 % | l'app propose 3 espèces plus « Autre » |
| 2 | Top-1 moyen par espèce (la bonne espèce est la première) | >= 70 % | confort du pêcheur |
| 3 | Top-3 de chaque espèce prise seule | >= 80 % | une espèce faible sort du modèle (grille) |
| 4 | Photos de test par espèce | >= 10 | sous 10, la mesure ne prouve rien : espèce « non évaluable », elle sort |
| 5 | Photos hors liste (« autre » : pas un poisson, espèce non gardée) refusées | >= 90 % | l'app doit proposer « Autre » |
| 6 | Taille du modèle (.mlmodel/.mlpackage) | <= 30 Mo | budget de l'app |
| 7 | Photos d'entraînement/validation/test toutes >= 299x299 | 0 hors norme | exigence de Create ML (vérifié par `preparer_jeu.py`) |

Moyenne « par espèce » = chaque espèce pèse pareil, pour qu'un brochet ultra-présent ne masque pas un sandre raté.
Marge d'erreur : avec 10 à 30 photos par espèce, compter +/- 10 points par espèce ; seul le total est fiable.

Verdict : `examen.py` sort avec le code 0 (passe) ou 1 (échoue) et écrit la matrice de confusion
(`sortie/confusion.csv`). Modèle visé : 77 espèces. Repli : 6 espèces (brochet, sandre, perche-commune,
truite-fario, carpe-commune, black-bass) si le modèle complet n'est pas prêt ; l'examen est le même, sur les classes gardées.
Les espèces qui échouent au seuil 3 ou 4 sortent du modèle (elles restent dans « Autre » / la grille) ; le reste est
ré-évalué, puis le modèle passe ou non. Une photo « autre » = pas un poisson ou espèce hors des classes gardées.

Format du journal (CSV, une ligne par photo de test) : `fichier,vraie,p1,p2,p3` ;
`vraie` = id d'espèce, ou `autre` ; `p1..p3` = propositions dans l'ordre, `autre` si le moteur refuse.
Même format pour le modèle Create ML (`mac/entrainer.swift`) et pour l'IA d'Apple (`mac/apple_ia.swift`).
