# L10 Écran verrouillé : ce que le Mac doit faire (lot/ecran-verrouille, f17bc3b, non compilé)
1. Nouvelle cible Widget Extension « FishMeWidget », Include Live Activity coché, Configuration App Intent décoché ; bundle ai.mwm.build.challenge.team.01.widget ; même équipe ; iOS 27.0 ; iPhone seul ; embarquée dans BuildChallenge. Pas de Core dans le widget.
2. Supprimer le dossier d'exemple généré (son @main).
3. Glisser Widget/ du dépôt, cible FishMeWidget seulement. Appartenance : EtatSession.swift = FishMeWidget + BuildChallenge ; PilotageActivite.swift = BuildChallenge seulement ; SessionLiveActivity.swift et FishMeWidgetBundle.swift = FishMeWidget seulement.
4. Cible app : INFOPLIST_KEY_NSSupportsLiveActivities = YES. Ni App Group ni Push.
5. RootView, ParcoursApp : `@ObservationIgnored let ecranVerrouille = PilotageActivite()` ;
   - commencer(_:), cas .demarree : `if let c = moteur.enCours { ecranVerrouille.demarrer(debut: c.sortie.debut, finLegale: c.finLegale) }`
   - demarrer(), après moteur.reprendre() : `if let c = moteur.enCours { await ecranVerrouille.reprendre(debut: c.sortie.debut, finLegale: c.finLegale, prises: moteur.nombrePrises) }`
   - terminerPrise, après moteur.ajouter(...) : `Task { await ecranVerrouille.mettreAJour(prises: moteur.nombrePrises) }`
   - sessionFinie, en tête : `Task { await ecranVerrouille.terminer() }`
6. Compiler le schéma BuildChallenge, puis BuildChallengeTests (AppTests/EcranVerrouille). Essai DEBUG : demarrerFaux(finLegaleDansMinutes: 2), demarrerFauxHorsFenetre().
Risques : ActivityKit/WidgetKit jamais compilés ; activitySystemActionForegroundColor ; redessin à staleDate.
