# Écrans relus avant le Mac (15 oct., fil « Écrans prêts pour le Mac »)

Relecture statique contre le cœur fusionné (`claude/core-linux-veq964`) et typecheck Docker (Swift 6.4, MainActor par défaut) des fichiers sans framework Apple. Tirer chaque branche juste avant de la fusionner.

| Lot | Commit poussé | Corrigé |
|---|---|---|
| L3 Prise | 2a3e294 | `Axe` nonisolated (ToiseCalibrage), `import Foundation` (PriseVuesResultat) |
| L4 Collection | 1663796 | `ServicesCollection` nonisolated |
| L13 Premier lancement | 3c73066 | `flatMap({ URL(string: $0) })` (ConseilsEspeceView) |
| L9 Mon club | cd1b8e2 | `CarteAPartager`, `LiensOfficiels`, `ContactClub`, `ImageSansGPS` nonisolated |
| L2 Carte | (après f54bcdd) | `ImageEspece` → `ImageEspeceCarte` (doublon avec L13), `GestionPosition` sans `self` avant `super.init()`, `flatMap` (LigneRegleView) |
| L6 Paywall | c633305 (inchangé) | rien |
| L12 Conditions | d0ac6ad | `LiensOfficiels` → `LiensVigilance` (doublon avec L9), `Horloge` de test → `HorlogeTestConditions` |
| L5 Session | 2587e71 | `MoteurSession` → `SuiviSession` (même nom que la struct de Core, ambigu dans les tests) ; fin de la 1re session : `acces(sessionsTerminees: ancien + 1, …)`, sinon le paywall se rouvrait à la fin de la 2e |

## Ce que seul le compilateur du Mac dira
- L3 : API Vision `RecognizeTextRequest().perform(on:)`, `boundingBox.cgRect`.
- L4 : `@Model nonisolated final class` lu depuis l'acteur `DepotCartes` ; `ShaderLibrary.ondeNage`.
- L2 : `MKLocalSearch.start()` (réponse non Sendable ?), `MKMapItem(location:address:)`, `@Bindable` dans `body`.
- L6 : `SKTestSession` (`setSimulatedError` peut-être synchrone : simple avertissement) ; `TestConfig.storekit` doit être dans les ressources de la cible de tests (A).
- L12 : tuple de `weather(for:including:)`, `WeatherAlert.summary/.source`, Swift Charts.
- L13 : `DragGesture` qui écrit un `@State`.

## Manques connus (pas des erreurs de compilation)
- Images d'espèces : 96 sur 99 sur la branche `lot/images-poissons` (à fusionner par A dans `App/Assets.xcassets`), liste et crédits dans `docs/images-especes.md`.
- L5 : la 1re session démarrée loin du spot choisi passe `spotGratuit ?? spotChoisi` à `acces` et peut être bloquée ; à trancher (passer `nil` tant qu'aucun spot gratuit n'est fixé). `JetonsSession` garde des couleurs provisoires (remplacement dans `App/Style/LISEZMOI.md`).
- L9 : l'adresse de contact est vide, un test échoue exprès tant qu'elle manque.
- L6 : le mensuel retenu n'est pas choisi (`ChoixOffres.mensuelRetenu = nil`).
- L3 : le test UI attend l'argument de lancement `-prise-test` (RootView).
- L2 : clé Info `NSLocationWhenInUseUsageDescription` (A).

## Points d'entrée pour RootView
- L5 : `SuiviSession(session:soleil:coffre: TrousseauSpotGratuit())`, `reprendre()` à l'ouverture et au retour au premier plan, `surFin` puis `acquitterFin()`, `abonne` suivi par L6, `BoutonCommencerSession` qui appelle `commencer(ContexteDepart(...))` (`ResultatDepart` : `.demarree`, `.pointAToucher`, `.paywallQuiBloque`, `.dejaEnCours`), `BandeauSession(moteur:ajouterPrise:)`.
- L3 : `PriseRacineView(services:contexte:terminer:)`, `PriseServices(especes:regles:identification:)`, `IdentificationAbsente()` tant que R1 n'a rien livré.
- L4 : `DepotCartes.creerConteneur()`, `DepotCartes(conteneur:dossierPhotos:services:)`, `PescedexModele(depot:services:)`, `PescedexView(modele:emplacements:)` ; écritures `enregistrer(prise:photo:conditions:dureeSecondes:)`, `enregistrerDeclaree(espece:date:)`, `enregistrerBredouille(sortie:lieuFlou:)`.
- L13 : `.questionNiveau(declenchee:)` sur la carte, `TunnelPremiersPasView(especes:maintenant:declarer:pecherMaintenant:choisirUnSpot:passer:)`, `CarteAEssayerView(especesProches:pechables:etatEau:contexte:fermer:)`, `ContexteConseils(...)`, `PremierConseilView(espece:contexte:)` (fiche L2), `CommentLaPecherView(espece:contexte:)` (dos L4).
- L9 : `ClubView(liens:sources:cartes:mesureUsage:) { marqueMeteo }` ; `SourceClub` à bâtir depuis `credits()` (`url` en String).
- L2 : `VueCarte(services:spotFixe:sessionsTerminees:bandeauHaut:bandeauSession:emplacementMaintenant:emplacementConseil:onCommencerSession:onSpotChange:)`, `ServicesCarte(geo:regles:especes:session:stations:)`.
- L6 : `AchatsStoreKit(surAchat:surTransactions:)` + `demarrerEcoute()`, `SuiviAbonnement(achats:)`, `CoucheMesure(passerelle:coffre:)` + `demarrerSiAccorde()`, `PaywallVue(declencheur:produits:achats:mesure:liens:surEtat:surAchatTermine:fermer:)`.
- L12 : `ConditionsDuSpot(meteo:eau:noyau:)`, `StockageMarque(source:)`, `RangeeMaintenantView`, `JaugeRiviereView`, `BandeauVigilanceView(alerte:)`, `LigneConditionsSession` (L5), `BlocConditionsPriseView` (L4), `PreviensMoiView`.
