# Correction UI Club (27 oct.)

## Cause : test périmé (pas un défaut de l'app)
Run 1 (test seul), message exact :
`ClubUITests.swift:26: XCTAssertGreaterThanOrEqual failed: ("31.999999999999986") is less than ("44.0") - Fil`
Le bouton fautif est « Fil », segment du sélecteur système Fil / Amis / Club de l'écran Communauté (32 pt),
pas un bouton de la page Club. Aucun bouton de App/Club n'est sous 44 pt. Ce n'est pas un faux rouge : mesure stable, 31,99 pt.
Même cas déjà traité dans AmisUITests (segments écartés).

## Correction
AppUITests/Club/ClubUITests.swift : la boucle des 44 pt écarte les boutons dont le libellé est celui d'un segment
(`app.segmentedControls.buttons`), comme le test Amis. Intention gardée : tous les autres boutons de la page restent
contrôlés à 44 pt, et l'absence de barre de défilement aussi. Affaiblissement : seuls les 3 segments du sélecteur
Communauté (hors page Club) sont exemptés. Aucun fichier App/ modifié.
Piste non faite : passer le sélecteur Communauté à 44 pt (App/Communaute, interdit pour moi).

## Sortie réelle (run 2, classe ClubUITests entière)
- Test Case testClubSansBarreDeDefilementEtBoutonsDe44Points passed (44.479 s)
- Test Case testLeLienDeClubOuvreLaFeuilleRejoindre skipped (41.046 s) : lien -FISHME_URL pas branché dans RootView (prévu par le test)
- Test Case testRejoindreAvecUnLienOuvreLaFeuilleDeColle passed (67.197 s)
- Executed 3 tests, with 1 test skipped and 0 failures (0 unexpected)

## Divers
reports/ecrans/*.png modifiés avant ma run (20:46, ma run 21:15) : non touchés. Rien commité.
