# Décisions produit tranchées

Source : réponses de Titouan, 13 octobre 2026. Les décisions encore ouvertes restent dans `CLAUDE.md` (section « Décisions ouvertes »).

| # | Décision | Conséquence |
|---|---|---|
| Q14 | Persona de démo : pêcheur régulier qui veut collectionner, mais plutôt débutant en identification des espèces. | Le mode débutant reste dans la première version. La collection est le moteur, l'aide à l'identification sert de filet. Captures et démo sont écrites pour lui. |
| Q15 | L'app s'ouvre sur la caméra, sans écran d'accueil. | Permission caméra au premier tap utile. Repli « choisir une photo » si refus. À faire valider par `revue-ux-2taps` et `gardien-appstore`. |
| Q16 | Public général, classification 4+ visée, pas de catégorie « Made for Kids ». | Pas de publicité, pas de suivi. Achats et localisation traités comme pour un public général. |
| Q17 | Hors ligne strict, y compris au premier lancement. | Données par département embarquées dans l'app. Aucune requête réseau dans le cœur. |
| Q10 | Grille gratuite provisoire : 15 cartes gratuites, puis Pro. À rediscuter avec l équipe ; ne pas considérer comme définitif. | Paywall, descriptif et preflight suivent « 15 cartes ». Le plan `peche/04` (1 département, 30 prises) est écarté pour l instant. |
| Q24 | Le Pro repose sur cinq leviers, retenus par Titouan le 15 octobre 2026 : (1) bestiaire de tous les départements (gratuit : le sien) ; (2) finitions des cartes (cadres, effets, albums par rivière), purement cosmétiques ; (3) bilan de saison partageable et export du carnet de pêche ; (4) sauvegarde et synchronisation iCloud, sans compte ; (5) mode Préparer (espèces du mois, matériel, conseils de débutant). | Seul moteur de revenu : l'abonnement du kit MWM. Le gratuit reste complet : photo, trois espèces, carte, collection, cartes Eau calme hors quota, bestiaire du département, partage d'une image. Les cartes obtenues ne disparaissent jamais. Chaque levier n'est annoncé dans la fiche App Store que s'il est livré. |
| Q24b | **Exclus pour de bon** : vendre de la rareté ou des chances de cartes rares ; échanges, enchères ou marché entre joueurs ; monnaie virtuelle ; paquets au hasard payants. | La rareté vient des relevés de l'OFB et ne s'achète pas. Aucune loot box. Inspiré du modèle de WikiMasters (gratuit puis abonnement) mais sans sa partie marché. |
