# L16 Onboarding sans friction : état et demandes

Code écrit sans Mac ni Xcode : rien n'a été compilé ni exécuté. Chaque point ci-dessous est à vérifier au premier BUILD.
Les tests (`AppTests/Conseils/ConseilsTests.swift`, `AppUITests/Conseils/OnboardingUITests.swift`) sont écrits, non exécutés.

## Fait (à vérifier sur Mac) // ⚠ à vérifier
- « Où pêches-tu ? » (`OuPechesTuView.pleinEcran`) : rond, texte à 40 pt, poissons à 26 pt sous la phrase, boutons à 40 pt du bas,
  deux espaces égaux autour du bloc, défilement sans barre si l'écran est trop court.
- Tunnel (`TunnelPremiersPasView`) : titre « Lesquels as-tu déjà pêchés ? » en en-tête VoiceOver et sous-titre sous le compteur,
  cartes centrées dans l'espace compteur/panneau (pas de marge fixe), panneau fixe sans poignée ni geste, `id` par espèce,
  transition `.scale(0.96)` + opacité sur 0,2 s (opacité seule si « Réduire les animations »).
- « Pas encore de carte » (`finSansCarte`, quand aucune carte n'est déclarée) : carte à débloquer (silhouette de l'espèce la plus commune,
  cadenas, rareté seulement si la fermeture `rarete` la fournit), « 0 sur N dans le 94 », phrase Pescedex, seul bouton « Voir mon spot ».
  Le composant de carte déclarée de L18 n'est pas exposé : la silhouette vient d'`ImageEspece`. À remplacer quand L18 l'expose.
- « Voir mon spot » appelle `voirMonSpot` (ou `choisirUnSpot`) et rien d'autre.
- Logique testable : `FinDuTunnel` dans `LogiqueConseils.swift` (3 tests).

## Pas fait
- Retrait de l'astuce widget : le fichier est `WidgetAquarium/AstuceAjouterWidget.swift` (hors de mon dossier) et l'appel est dans `RootView.swift` l.739.
  Rien dans `App/Conseils/` ne la mentionne.
- Vérifications sur iPhone (mesures de la fiche, vidéo 60 fps, VoiceOver, AX5) : impossibles sans Mac.

## Demandes pour L25 (à brancher par A)
1. `RootView.proposerSuitePremierLancement` : supprimer la branche `else if consentement == .inconnu, !consentementPropose { ... courant = .consentement }`.
   Sinon « Voir mon spot » (via `feuilleFermee()`) rouvre la feuille de consentement. `Modal.consentement` reste pour les réglages (L6).
2. `RootView.swift` l.739 : retirer `.astuceAjouterWidget(...)`, puis supprimer `WidgetAquarium/AstuceAjouterWidget.swift` du projet (cible app).
3. Passer `departement:` (code du département de la zone, « 94 ») à `TunnelPremiersPasView` ; sans lui le compteur dit « dans ta zone ».
4. Passer `rarete:` si disponible (sinon aucune rareté affichée, voulu).
5. Après fusion de L25 : `grep -rn astuceAjouterWidget App/ WidgetAquarium/` vide, et « Voir mon spot » sans feuille.

## Décisions pour Adem
- Titre et sous-titre du tunnel : « Lesquels as-tu déjà pêchés ? » / « Glisse à droite si oui, à gauche sinon » (texte de la fiche).
- « Pas encore de carte » : titre au-dessus de la carte, en plus du compteur et de la phrase Pescedex (peu de texte : à raccourcir si trop).
