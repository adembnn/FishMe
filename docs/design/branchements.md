# Branchements à faire dans RootView (A), lot/design-systeme

Vues restylées ou créées d'après docs/design/choix.md. Rien n'a été compilé (cloud). À brancher :

- ClubView : passer .poissonsDuClub([...]) ; PartageCarteView : passer partagerAuClub ; retirer le bouton « Mes amis » en surimpression sur ClubView.
- AutreSpotProView(decouvrir:plusTard:) (App/Carte/Vues) : présenter au .paywall(.autreSpot).
- SansPositionView (App/Carte/Vues) : présenter quand la position est refusée.
- BandeauVigilanceView(alerte:previensMoi:lecture:) : passer previensMoi et lecture pour l'interrupteur « Préviens-moi » de AlerteView.
- ReglagesView(niveau: Binding<NiveauPecheur>, alertes: Binding<Bool>, mesureAudience: Binding<Bool>, abonne: Bool, achats: Achats, liens: LiensLegaux, surEtat: (EtatAchats) -> Void, ouvrirSource: (String) -> Void, ouvrirSecurite: () -> Void, ouvrirPaywall: () -> Void) (App/Abonnement) ; mesureAudience = même Binding que ClubView ; surEtat = suivi.appliquer ; niveau et alertes : stockage à fournir.
- FinSessionView(fin: FinDeSession, infosEspece:, lieu:, surTerminer:, surFermer:) (App/Session) : passer moteur.derniereFin, appeler moteur.acquitterFin() dans surTerminer, puis ouvrir le paywall qui se ferme si fin.paywall == .quiSeFerme. infosEspece = catalogue L1.
- MesSortiesView(sorties: moteur.sortiesTerminees, infosEspece:, lieu:, surChoix:, surRetour:) (App/Session).
- PescedexView(voirAquarium:, pecherEnPhoto:) (App/Collection) : sans ces closures, « Voir mon aquarium » et « Le pêcher en photo » sont cachés.
- AppTests/Prise/PriseVerdictTests.swift : 7 tests du verdict sur fourchette (étape .details ajoutée entre taille et résultat).
- À vérifier à la compilation (Prise) : PriseFeuille (init @ViewBuilder), UnevenRoundedRectangle, Task { @MainActor } dans AVCaptureDevice.requestAccess.

## Pages restantes (16 oct. 6h)
- PescedexView(photographier:, declarer:) : sans ces closures, le groupe « Pour commencer » du Pescedex vide (P45) n'apparaît pas.
- FinSessionView(conseil:) : conseil de la prochaine fois (P47), tiré des conseils de L1 ; sans lui, le bloc est caché.
- Écran de lancement P44 B (A, Info.plist) : UILaunchScreen avec fond marine #0D4A85 et le logo La Lune centré, rien d'autre (maquette docs/design/maquettes/P44-lancement-B sur claude/design-systeme-4qneio).
- P46 B (App/Carte/Vues/EtatsVidesCarte.swift) : afficher BandeauPasDeReseauView() dans le haut de VueCarte quand le réseau manque (NWPathMonitor, comme Amis/SurveillanceReseau.swift), et PasDeSpotView(choisirUnSpot:) quand spotAffiche == nil.
- Après P44 (16 oct. 6h) : iOS n'autorise qu'un écran de lancement statique. Prévoir dans RootView un point d'accroche pour une vue d'ouverture animée qui prend le relais juste après (vue plein écran marine, posée au-dessus du contenu au démarrage puis retirée). L'animation elle-même vient du fil « Animations de chargement et sons », après le choix d'Adem.
- Mouvement (16 oct. 6h30, choix d'Adem : lancement A, carte B, sonar, sons recommandés) sur `claude/animations-sons-213bkk` : `App/Mouvement/` (Sons.swift + 13 sons CAF, OuvertureView, ChargementBouchon, ChargementSonar), révélation « Le dos de la carte » dans `App/Collection/RevelationCarteView.swift` + `EffetsRevelation.swift`, ouverture branchée dans RootView (overlay), sonar dans VueCarte (première lecture seulement), bouchon à la place des ProgressView (fiche du spot, paywall, Où chercher, lecture de la photo). Réglages « Sons » et « Vibrations » : clés `reglages.sons` et `reglages.vibrations` (oui par défaut), interrupteurs à poser dans P35. Rien n'a été compilé (cloud Linux).
