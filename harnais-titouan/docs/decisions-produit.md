# Décisions produit tranchées

Source : réponses de Titouan, 13 octobre 2026. Les décisions encore ouvertes restent dans `CLAUDE.md` (section « Décisions ouvertes »).

| # | Décision | Conséquence |
|---|---|---|
| Q14 | Persona de démo : pêcheur régulier qui veut collectionner, mais plutôt débutant en identification des espèces. | Le mode débutant reste dans la première version. La collection est le moteur, l'aide à l'identification sert de filet. Captures et démo sont écrites pour lui. |
| Q15 | L'app s'ouvre sur la caméra, sans écran d'accueil. | Permission caméra au premier tap utile. Repli « choisir une photo » si refus. À faire valider par `revue-ux-2taps` et `gardien-appstore`. |
| Q16 | Public général, classification 4+ visée, pas de catégorie « Made for Kids ». | Pas de publicité, pas de suivi. Achats et localisation traités comme pour un public général. |
| Q17 | Hors ligne strict, y compris au premier lancement. | Données par département embarquées dans l'app. Aucune requête réseau dans le cœur. |
| Q10 | Grille gratuite provisoire : 15 cartes gratuites, puis Pro. À rediscuter avec l équipe ; ne pas considérer comme définitif. | Paywall, descriptif et preflight suivent « 15 cartes ». Le plan `peche/04` (1 département, 30 prises) est écarté pour l instant. |
