# À compiler en premier (Sullyvan et Adem) : l'ordre de priorité

Écrit le 20 octobre 2026 par Titouan (avec ses agents). **Une seule branche à compiler : `integration/fusion-20oct`** (dernier commit 9a55eae6 au moment de l'écriture). Elle contient tous les lots du 19 et 20 octobre, déjà fusionnés sans conflit de code.

## Ce qui est vérifié, ce qui ne l'est pas
- **Vérifié :** les 522 tests du paquet `Packages/Core` passent dans Docker (Swift 6.0, Linux). Un seul test échoue par moment : `ReglesTests.swift:321` « Un fichier de 400 Ko se charge vite » (seuil de 1 s, dépassé quand la machine est chargée ; il était déjà sur `main`).
- **Non vérifié :** tout `App/`, `AppTests/`, `AppUITests/`, `WidgetAquarium/`. **Rien de cela n'a jamais été compilé.** Attendez-vous à une série d'erreurs : signatures, isolation Swift 6 (`SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`), API Apple. Quatre relectures « compilateur humain » ont corrigé les erreurs certaines trouvées (`C:\w\revues` chez Titouan, résumées dans les rapports de lots), mais aucune ne remplace un compilateur.

## Ordre conseillé
1. **Compiler l'app (Debug, simulateur, `FISHME_ICLOUD=NO`)** et corriger les erreurs. Collez fichier:ligne + message au fil de coordination : un agent corrige. Commencez par le cœur (Carte, Pescedex, Session, Prise), qui est le plus ancien. Le réseau social (L21 profil, L23 fil, L24 chat, L22 clubs) est le plus neuf : s'il bloque, ne le laissez pas retarder le reste.
2. **Lancer `swift test` dans `Packages/Core`**, puis les tests d'app. Les tests d'app et d'interface n'ont jamais tourné : une partie échouera par des attendus faux ou des écrans qui ont changé.
3. **Réglages à la main dans Xcode** (liste complète dans `docs/reports/branchements-l25.md`) : capacités iCloud + Push + Background Modes « Remote notifications », `PrivacyInfo.xcprivacy` (à remplir avec `store/app-privacy.md`), retirer la ligne d'exception de `AstuceAjouterWidget.swift` du `project.pbxproj`, exclure les `LISEZMOI.md` du bundle (`Reperes/`, `Aquarium/Skins/`), cocher la Target Membership (app ET widget) des fichiers partagés `WidgetAquarium/DecorsDessines*.swift`, `FondWidget.swift`, `BudgetDecor.swift`.
4. **CloudKit (tableau de bord)** : créer les types (base publique : `Signalement`, `ProfilPublic`, `Publication`, `Commentaire`, `Like`, `Club`, `Membre`, `CartePartageeClub` ; base privée zone `Reperes` : `Repere`, `PhotoRepere`), les index (`creeLe` interrogeable ET triable, `surnomNorm`, `createdBy`, `recordName` de `ProfilPublic`, `MessageAmi`, `MessageClub`), **restreindre la lecture de `Signalement` à l'équipe**, puis déployer en production. Sans cela, le fil, le chat et les clubs ne marchent pas.
5. **Données** : publier `stations-temperature.json` dans la release privée `donnees` (commande dans `branchements-l25.md`, 24 stations en service seulement), vérifier les stations recalées de D5 sur une carte (critères 2, 3, 4 de la fiche D5), relire les règles des départements 75, 77, 92, 93, 94 (encore en brouillon).
6. **Essais sur iPhone réel** : fluidité des décors d'aquarium (Instruments : 60 images/s côté interface, moins de 10 % de CPU au repos ; procédure dans `App/Aquarium/Skins/LISEZMOI-N1.md`), widget (le décor suit l'aquarium), appui long sur la carte (repères), notifications du chat, deux comptes iCloud pour le fil et le chat.

## Décisions qui reviennent à Adem
- Les coordonnées exactes des repères sont sauvegardées dans l'iCloud privé chiffré : la phrase de `CLAUDE.md` « aucun coin de pêche exact ne quitte l'iPhone » est à réécrire.
- Version 4 des CGU (ré-acceptation par tous les utilisateurs) ; 15 questions pour le juriste dans `docs/legal/questions-juriste.md` ; un référent par semaine pour la boîte de signalement (sinon ne pas promettre 24 h).
- 3 repères gratuits en attendant le modèle économique ; fenêtre « en service » de la température de l'eau (30 jours, 24 stations).

## Où lire le détail
`docs/reports/passation-titouan-19-oct.md` (sections « 0 ter », « 0 bis »), `docs/reports/branchements-l25.md`, `docs/reports/alignement-fusion.md`, `docs/legal/`, et les LISEZMOI de chaque lot (`App/*/LISEZMOI*.md`).
