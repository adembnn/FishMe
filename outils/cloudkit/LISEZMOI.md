# Schéma CloudKit en fichier

Image : au lieu de créer 13 onglets à la main dans le tableau de bord, on dépose un fichier qui les crée tous d'un coup.
Conteneur `iCloud.ai.mwm.build.challenge.team.01`, équipe `ZUQ3ZP29N4`, environnement Development.

**Réserve : Apple n'a pas validé ce fichier.** Il est écrit depuis le code et contrôlé par `verifier_schema.py`, jamais passé dans `cktool`. La commande 3 le dira.

Les 4 commandes, dans l'ordre (depuis la racine du dépôt) :

1. Créer un jeton de gestion : CloudKit Console (icloud.developer.apple.com) > Settings > Tokens & Keys > « Management Tokens » > créer. Copier le jeton dans le presse-papiers, sans le coller dans un chat ni un fichier.
2. `xcrun cktool save-token --type management` (le terminal demande le jeton ; il va dans le trousseau).
3. `xcrun cktool validate-schema --team-id ZUQ3ZP29N4 --container-id iCloud.ai.mwm.build.challenge.team.01 --environment development --file outils/cloudkit/schema-development.ckdb`
4. `xcrun cktool import-schema --team-id ZUQ3ZP29N4 --container-id iCloud.ai.mwm.build.challenge.team.01 --environment development --file outils/cloudkit/schema-development.ckdb`

Si la 3 refuse une ligne, envoyer le message d'erreur : on corrige le fichier. Contrôle sans réseau : `python3 -I outils/cloudkit/verifier_schema.py` (attendu : « 0 trou »).

Ce que le fichier contient : 7 types publics (Publication, Like, Commentaire, ProfilPublic, Club, Membre, Signalement) avec les index lus dans les requêtes du code, et 6 types privés (Blocage, MessageClub, MessageAmi, Carte, Bredouille, Profil). Signalement : droit Create seul, aucune lecture publique ; l'équipe lit dans la console.

Pas dans le fichier :
- `Repere` et `PhotoRepere` : champs chiffrés (`encryptedValues`), l'app les crée seule au premier enregistrement en Development.
- Les messages d'amis et de club sont inclus par prudence (le déploiement vers Production a besoin de l'index sur `recordName`) ; les zones partagées elles-mêmes sont créées par l'app.
- Abonnements : créés par l'app.

Ensuite : tester l'app en Development, puis « Deploy Schema Changes » vers Production (un type déployé ne se supprime plus).
Index `createdBy` de ProfilPublic (code `creatorUserRecordID`) : à confirmer à la validation.
