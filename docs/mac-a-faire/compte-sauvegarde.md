# Compte et sauvegarde iCloud : ce que le Mac doit faire (branche claude/compte-sauvegarde-mv4tgb, non compilé)

Le compte FishMe, c'est l'identifiant Apple du pêcheur : pas de mot de passe, pas de serveur à nous, pas de Sign in with Apple
(sans serveur, il ne ramènerait rien de plus qu'iCloud). L'app marche pareil sans iCloud et hors ligne.

Ce qui revient sur un nouvel iPhone : cartes du Pescedex avec leurs photos (sans GPS), cartes bredouille, sorties terminées,
compteur de sessions, niveau du pêcheur, premier lancement déjà vu, clubs. FishMe Pro revient par StoreKit (« Restaurer les achats »).
Les amis reviennent seuls (zones CloudKit du même compte). Ne revient pas : le spot gratuit exact (trousseau de cet iPhone seulement,
règle « aucun coin exact ne quitte l'iPhone ») et l'accord de mesure d'audience (à redemander sur chaque iPhone).

## Fichiers
- `Packages/Core/Sources/Core/Sauvegarde/FusionSauvegarde.swift` + tests (6 verts sous Linux, `swift test --filter FusionSauvegarde`).
- `App/Compte/SauvegardeICloud.swift` (CloudKit, base privée, zone « Sauvegarde »), `App/Compte/ProfilLocal.swift`, `App/Compte/CompteView.swift`.
- Retouches : `App/Collection/DepotCartes.swift` (identifiants, urlPhoto, importer), `App/Abonnement/ReglagesView.swift`
  (ligne « Mon compte », paramètre `ouvrirCompte` facultatif), `App/RootView.swift` (modèle du compte, sauvegarde 5 s après chaque écriture
  et au lancement, relecture après un rapatriement, destination « Mon compte » dans les Réglages).

## À faire sur le Mac
1. Ajouter le dossier `App/Compte/` à la cible BuildChallenge s'il n'est pas pris par le dossier synchronisé.
2. Compiler BuildChallenge (iOS 27). Points à surveiller : `recordZoneChanges(inZoneWith:since:desiredKeys:resultsLimit:)`,
   `modifyRecordZones`, isolation (types du compte marqués `nonisolated`, `ProfilLocal` sur le fil principal), `.buttonStyle(.secondaire)`.
3. Capacité iCloud + CloudKit sur l'identifiant `ai.mwm.build.challenge.team.01`, conteneur `iCloud.ai.mwm.build.challenge.team.01`
   (déjà dans `Config/BuildChallenge.entitlements`, déjà dans la liste d'Adem avec App Group et WeatherKit).
4. Essai : iPhone connecté à iCloud, prendre 2 cartes, Réglages > Mon compte : « 2 cartes ». Supprimer l'app, la réinstaller,
   ouvrir Mon compte : les 2 cartes et leurs photos reviennent.
5. Avant TestFlight : console CloudKit, déployer le schéma (types Carte, Bredouille, Profil) de Development vers Production.
6. Partager FishMe : ajouter la clé Info `FishMeLienAppStore` = `https://apps.apple.com/app/id<numéro>` quand App Store Connect donne
   le numéro. Sans la clé, le bouton reste caché.

## Limites connues
- Synchro en ajout seul : une carte corrigée après coup n'est pas renvoyée, et une future suppression de carte devra laisser
  une marque de suppression dans iCloud, sinon la carte reviendra.
- Le profil (sorties) part en fichier joint `fichier` du type Profil, pas en champ : pas de limite de 1 Mo.
