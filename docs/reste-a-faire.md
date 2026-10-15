# Reste à faire, pour Adem (15 oct. 2026, soir)

> **Message de Titouan pour Adem**, écrit par sa session Claude sur le PC d'Adem (Titouan n'a plus de batterie). Tout ce qui est écrit ici a été vérifié par une commande, sauf mention « non vérifié ». Tout est poussé sur GitHub.

## 1. Ce qui tourne encore sur ton PC (session Claude ouverte)
- **D3, vagues 3 à 6** (départements 13 à 52) : tâche de fond. Reprendre avec la même session. Les départements finis sont en cache.
- **Push toutes les 5 minutes** et **veille toutes les 17 minutes** : tâches de la session. Si la session se ferme, elles s'arrêtent ; relancer `python3 -I outils/regles/pousser.py` (dans `repo-d3`) à la main pour les règles.
- Docker Desktop est lancé (il a planté 3 fois sur des fichiers-prise bloqués ; ne pas le tuer de force).

## 2. À faire par toi sur Mac (dans l'ordre de `docs/compiler-sur-mac.md`)
1. Lier `Packages/Core` à la cible app **et** à la cible de tests (Add Local Package). Sans ça, `import Core` échoue partout. Certain.
2. Choisir Swift 5 ou Swift 6. Le projet est en `SWIFT_VERSION 5.0` avec `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` ; les lots sont écrits pour ce mode (types de données en `nonisolated`).
3. Clés et capacités : clé Info « position pendant l'usage », WeatherKit (identifiant chez MWM), iCloud/CloudKit seulement pour L8 (après l'envoi), notifications (« préviens-moi »), `TestConfig.storekit` dans les ressources des tests.
4. Retirer l'appel direct à `Spark.configure` au lancement : L6 le met derrière le consentement.
5. Brancher chaque écran dans `App/RootView.swift` : la liste de ce que chaque lot attend est dans la réponse finale de son agent (`PriseRacineView`, `PescedexView`, `BandeauSession`, `TunnelPremiersPasView`, `CarteAEssayerView`, `VueCarte`, `PaywallVue`, `FeuilleConsentement`, vues de L12).
6. Compiler un lot à la fois (`xcodebuild … generic/platform=iOS Simulator`) : L5, L3, L4, L13, L2, L12, L6, L9 ; L8 après l'envoi. Un lot non compilé n'est pas fusionné.
7. Dernier : `scripts/fusionner.sh <lot>` pour chaque lot vert ; créer `main` à L0.

## 3. Décisions qui t'attendent
- **Mensuel retenu** : `ChoixOffres.mensuelRetenu` vaut `nil` (`App/Abonnement/Produits.swift`) ; tant que c'est vide, le paywall ne montre que l'annuel 34,99 €.
- **Légendaire** : L4 l'a fait bordeaux + étoile (pas d'or, à cause de « aucun cadre jaune »), alors que `niveau-2` met de l'or.
- **Anguille jaune sans stade** (cas 09) : le moteur rend « vérifie l'arrêté », le cas attendait « relâche-la ». Je recommande de corriger le cas.
- « Hors France » rend « vérifie l'arrêté » avec un message non écrit dans les docs. Lien de préfecture (`urlPrefectures`) à confirmer. Textes du paywall à valider. « Pro en cinq leviers » est introuvable dans le dépôt (L6 a repris les 6 lignes de la fiche).
- Le paywall « 2e spot » a un bouton « Retour à la carte » (sinon l'écran piège l'utilisateur).
- **L8 Amis (CloudKit)** ne doit pas être dans le build soumis jeudi (règle 2.3.1(a), code dormant) : fusion après l'envoi.

## 4. Lots à toi pas encore faits
D0 (style et 4 maquettes : palette en planches A/B/C, 2 à 3 références à donner), L10, L11, L14 (aquarium, en pause), S1 (fiche : la fiche de Titouan décrivait l'ancien produit « Bredouille », à réécrire), L9 existe sur `lot/club` (écrit avant), L7 attend L2.

## 5. D3 (règles de toute la France)
- Fait : 28 départements sur `regles/local` (01 à 16, 19, 22, 23, 27, 75, 77, 78, 91 à 95). Le 93 est refait avec Tesseract : 64 règles confirmées sur 76.
- **Toi : vagues 7 et 8** (53 à 72), **Sullyvan : 9 et 10** (73 à 90). Mode d'emploi : `docs/repartition-d3.md`. Tesseract est installé sur ce PC (français dans `C:\Users\Adem\tessdata`).
- Manques : arrêtés de réserves de l'Eure (Risle, Avre, Iton, Epte, Andelle, 2023-087), arrêté 2022 du 93 (carpe de nuit), liste de reconnaissance à 101 entrées (dossier cloud inaccessible).
- D1 doit charger `docs/regles-local/consensus/` depuis `regles/local` : `git archive origin/regles/local docs/regles-local | tar -x`.

## 6. Modèle de reconnaissance
- Photos : `repo/reports/photos/jeu/` (6 espèces du repli, 175 Mo, **pas dans git**) : à copier sur un Mac. 1 483 images sur 1 675 sont en CC BY-NC (entraînement seul ; jamais publiées). Sandre 925 images (8 fois plus : sous-échantillonner), black-bass : 2 photos en Europe.
- Il manque une classe « autre » pour l'examen. Les seuils de l'examen sont à valider (`outils/reconnaissance/EXAMEN.md`).
- Entraînement : `outils/reconnaissance/mac/lancer.sh` (jamais exécuté, pas de Mac ici). Test d'une heure de l'IA d'Apple sur iPhone 15 Pro : `outils/reconnaissance/mac/apple_ia.swift` (la forme exacte du prompt avec image est un TODO à la compilation).

## 7. Risques connus (non vérifiés sous Xcode)
Alertes WeatherKit en France non garanties ; Vision `RecognizeTextRequest` (toise) ; MapKit `MapReader`, `MapCircle` ; StoreKit `SubscriptionStoreView` ; CloudKit `CKShare` et `UICloudSharingController` iOS 27. Les vérifications de types sous Linux (stubs maison) donnent 0 erreur sur L2, L3, L5, L6, L12, L13.

## 8. Attention
D'autres sessions « Claude » poussent sur les mêmes branches de lot (D1, L1, L3, L12, L13). Décider quelle session garde quels lots, sinon doublons et conflits. Le README du kit MWM dans git ne contient pas de mot de passe (vérifié : clé « your-api-key »).
