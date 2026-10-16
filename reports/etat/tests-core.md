# Tests de Packages/Core sous Linux (16 oct. 2026)

Copie de Packages/Core (branche mac/integration) dans /tmp/claude-0/core-tests/Core, image swift:6.4, aucun fichier du dépôt modifié.

- `swift build` : réussi, 12 s (compilation à froid).
- `swift test` : code de sortie 0. Swift Testing : 188 tests dans 22 suites, 0 échec, 1 problème connu (known issue), durée 2,5 s. XCTest : 0 test (aucun).
- Problème connu : cas-09 (variante anguille-jaune sans stade), CasVerdictsReelsTests.swift:100. Rendu « verifieLArrete », cas d'or attend « relacheLa » ; les règles de D1 ne visent que l'argentée et la civelle. Déjà noté dans reports/l1-divergences.md et marqué `withKnownIssue`.
- Cas d'or (Sources/Core/Resources/cas-verdicts.json) : testés, 13 cas lus, 13 exécutés, 12 passent sans réserve, 1 passe avec le problème connu ci-dessus.
- Avertissements : (1) Package.swift : 4 fichiers de Tests/CoreTests/Moteur/Fixtures (hubeau-marne-H/Q/QmM.json, stations-essai.json) non déclarés comme ressources ni exclus. (2) 1 avertissement de compilation « no 'async' operations occur within 'await' expression » (un `await #expect(throws:)` inutile, MiseAJourTests.swift:160). Aucun avertissement de concurrence Swift 6 relevé.
- Temps de chargement mesurés par les tests : fichier de règles de 359 Ko, 0,096 s ; test « Les vrais fichiers se chargent » (tous les vrais fichiers de règles et données), 2,49 s au total (inclut les contrôles, pas un chargement pur). Pas d'autre outil de mesure.
