# Avant jeudi 9 h (aucune ligne de code de l'app)

Version du 12 oct., 17h ; les personnes suivent la décision d'Adem du 15 oct. 14h26 (plus de C : A, B et S, `lots.md`). Chaque ligne a sa preuve. Les lignes marquées (Q3) dépendent de la question 3 de `README.md`.

## Adem
- [ ] Envoyer `message-mwm.md` à MWM. Preuve : réponse écrite de MWM sur les 6 points.
- [ ] Demander aux organisateurs si « publiée vendredi 15 h » veut dire « envoyée à Apple » ou « en ligne ». Preuve : leur réponse.
- [ ] Choisir le nom de l'app (le fil de cadrage), puis le prix. Preuve : nom et prix écrits dans le `CLAUDE.md` du dépôt.
- [ ] Désigner qui est A, B et S (fait le 15 oct. 14h26 : `lots.md`, « Qui »).

## MWM (via Adem)
- [ ] Ligne 0 de `app-store.md` faite. Preuve : capture de Xcode > Settings > Apple Accounts montrant l'équipe MWM, sur chaque Mac.

## A et B (les deux Mac)
- [ ] macOS Tahoe 26.6 ou plus, Xcode 27.0, simulateur iOS 27 lancé une fois, puis plus aucune mise à jour. Preuve : `sw_vers -productVersion`, `xcodebuild -version`, `xcrun simctl list runtimes` (commandes à confirmer sur le Mac).
- [ ] Claude Code et `gh` connectés. Preuve : `gh auth status`.
- [ ] Invitation MWM acceptée, équipe visible dans Xcode.
- [ ] Projet Xcode vide de 15 min, signé, lancé sur l'iPhone, effacé ensuite (Q3, option c seulement).
- [ ] D1 : A saisit les règles du 92 et du 93, B celles du 77, au format de `donnees.md`, chaque règle avec sa source. Preuve : relecture par S contre l'arrêté.

## Les iPhones
- [ ] Lister les iPhones de l'équipe et leur modèle. L'IA d'Apple demande un iPhone 15 Pro ou plus récent ([Apple](https://support.apple.com/en-us/121115)). Il en faut un par Mac, et si possible un iPhone sans IA pour tester le repli.
- [ ] iOS 27, Apple Intelligence active, modèle téléchargé, langue de l'iPhone identique à celle de Siri, 20 Go libres.
- [ ] Mode développeur (il n'apparaît qu'après un premier branchement à Xcode).

## Sans Mac (c'était C ; depuis le 15 oct. 14h26, B, S ou A)
- [ ] B, D1 : socle national, 75 et 94 saisis, chaque règle avec sa source ; le PDF du 94 lu à la main. Preuve : relecture par S contre l'arrêté.
- [ ] S, D1 : relire les saisies de A (92, 93) et de B (77). Preuve : une ligne « relu par » dans chaque fichier.
- [ ] B : `cas-verdicts.json` : les 5 cas de `donnees.md`, réponses confirmées contre les textes.
- [ ] S, D2, option a de Q3 : export tableur Hub'Eau des 5 départements (stations, pêches, espèces), sans script. Options b et c : script lancé sur le 94, de bout en bout. Preuve : les niveaux du 94 égaux à la liste « Attendu dans le 94 » de `donnees.md`.
- [ ] A, textes S1 : fiche, page de confidentialité, page d'assistance, notes pour le relecteur en anglais.
- [ ] B : session Claude Code dans le cloud qui lance l'image Docker `swift:6.4`. Preuve : `docker run --rm swift:6.4 swift --version` affiche 6.4.

## Toute l'équipe
- [ ] 20 photos de vraies prises, espèce confirmée par le pêcheur, dans un dossier partagé ; plus une photo d'exemple dont on a les droits, pour le relecteur.
- [ ] Lire sa fiche de lot dans `fiches/` et noter ce qui n'est pas clair.
- [ ] Dépôt `build-challenge-unaite-mwm-apple-f` cloné ; lire son `CLAUDE.md`.
