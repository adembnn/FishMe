# App de pêche (Build Challenge Apple, oct. 2026)

Faits et décisions propres à ce dépôt. À mettre à jour dans la minute qui suit chaque décision.
Le plan complet est dans `docs/` : commencer par `docs/README.md`, puis sa fiche de lot dans `docs/fiches/`.
Les documents que le plan cite sans chemin (`lots.md`, `fiches/L3.md`, `reports/...`) sont dans `docs/`. `python3 docs/verifier.py` doit afficher « 0 trou ».

## Le produit
- App iPhone de pêche en eau douce : la carte montre où pêcher et quels poissons y vivent (relevés OFB), chaque prise photographiée devient une carte à collectionner dont la rareté dépend du département.
- Nom de l'app : pas encore choisi. « Pescedex » est le nom de la collection dans l'app, jamais celui de l'app.
- Ne jamais écrire « Poké », « Pokémon » ou « Pokédex » dans l'app, ses textes ou sa fiche App Store (marques de Nintendo).
- Règles : socle national partout, plus 75, 92, 93, 94, 77 saisis à la main, chaque règle avec sa source. Hors de ces départements, jamais « tu peux la garder ».
- L'IA ne décide jamais si un poisson peut être gardé : elle propose l'espèce, l'utilisateur confirme, la table sourcée donne le verdict.
- Aucun coin de pêche exact ne quitte l'iPhone. Les photos enregistrées n'ont pas de GPS.
- Aucune fausse donnée : chaque chiffre OFB affiche son nombre de pêches et l'année du dernier relevé.
- Collections visibles par les amis invités seulement, jamais en public (Adem, 12 oct. 14h43).
- Essai gratuit « 1 mois » puis abonnement, paywall après la première carte. Prix pas fixé.

## La construction
- Critère commun : `docs/parcours-demo.md` (étapes E1 à E9). Lots et calendrier : `docs/lots.md`.
- Aucune ligne de code de l'app avant le jeudi 15 oct. 2026. Build jeudi et vendredi matin.
- Xcode 27.0, iOS 27.0 minimum, iPhone seulement. 2 Mac (A et B) ; C travaille sans Mac, dans le cloud.
- Structure : un seul paquet `Packages/Core` (Foundation seulement, testable sous Linux) + la cible app en dossiers synchronisés, un dossier par lot dans `App/`.
- Un dossier de l'app n'importe que `Core` et lui-même. A seul touche au `.xcodeproj`, aux capacités, aux clés Info et à `App/RootView.swift`. C seul touche à `Packages/Core`.
- Un lot = un dossier = une personne = une branche `lot/<nom>`. On rejoint `main` seulement par `scripts/fusionner.sh`, qui lance `scripts/verif.sh`.
- Les faux services sont sous `#if DEBUG` : rien de factice dans le build envoyé à Apple.
- Les fichiers de données fabriqués par script (stations, raretés) ne sont jamais commités : `scripts/donnees.sh` les télécharge.
- Compte App Store Connect, iPhone de test, fichier StoreKit et SDK Spark Flash fournis par MWM.
- Jeudi, `main` part de la branche `claude/project-thread-78e20q` (le plan seul, sans code) ; A la crée à L0 et la met par défaut sur GitHub.
