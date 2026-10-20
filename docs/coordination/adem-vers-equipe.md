# Adem vers l'équipe : point du 20 octobre au soir

## Bloquant : iCloud, Push et le conteneur CloudKit n'existent pas côté Apple
Xcode (cible `BuildChallenge`, onglet Signing & Capabilities, équipe MWM `ZUQ3ZP29N4`) affiche :
`Communication with Apple failed. Your account does not have sufficient permissions to modify containers.`
Le profil de signature n'a donc ni iCloud, ni Push Notifications, ni le conteneur `iCloud.ai.mwm.build.challenge.team.01`.
Dans CloudKit Console, ce conteneur n'est pas dans la liste de l'équipe.

**Il faut quelqu'un de MWM avec un rôle assez haut** (propriétaire ou administrateur) :
- soit activer iCloud (CloudKit), Push Notifications et App Groups sur l'identifiant `ai.mwm.build.challenge.team.01` et créer le conteneur ;
- soit passer Adem administrateur de l'équipe.

Tant que ce n'est pas fait : le fil, le chat, les clubs, les repères et la sauvegarde ne marchent pas sur un vrai iPhone. Le simulateur (iCloud coupé) n'est pas bloqué.
Le schéma CloudKit à importer ensuite est prêt dans `outils/cloudkit/` (13 types ; **non validé par Apple**, la validation demande un jeton de gestion).
À faire plus tard (Adem).

## Ce qui est fait (branche locale `lot/compile-20oct`, non poussée)
- `integration/fusion-20oct` compile en Debug sur iPhone 17 : `** BUILD SUCCEEDED **`. 14 fichiers de `App/` et 4 de `AppTests/` corrigés (isolation Swift 6 surtout), plus le projet Xcode.
- `swift test` sur `Packages/Core` : 522 tests, 1 échec connu (le test de vitesse « fichier de 400 Ko », 17 s sous charge, 0,9 s seul).
- Tests d'app : 613 tests, au moins 12 en échec, **pas encore corrigés**. Parmi eux, un vrai défaut de texte : la phrase « secteurs autorisés » (`MoteurRegles.swift`) contredisait la décision 10 ; reformulée en « prévus », non retestée.
- Release `donnees` republiée le 20 oct. : `stations-especes.json` recalé (96,2 %, 313 `recalee:false`) et `stations-temperature.json` (850 stations, 24 en service, outre-mer retiré).

## Règles d'Île-de-France (75, 77, 92, 93, 94)
Relecture par script et lecture, pas par une personne : `verifie_par` reste vide. Personne ne signe pour l'instant, donc l'app ne dit jamais « relue par une personne ».
À corriger dans les fichiers de règles (faits en local, non poussés) : 6 règles d'enduro périmées retirées du 77, brochet du 93 à deux lectures 50/60, date de l'avis du 75 au 15/01.

## Décisions qui attendent Adem
CGU v4 et questions pour le juriste, phrase « aucun coin exact ne quitte l'iPhone », référent de la boîte de signalement, 3 repères gratuits, les 7 décisions de l'étude de marché.
