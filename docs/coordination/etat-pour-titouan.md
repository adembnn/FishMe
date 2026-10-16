# État pour Titouan

Mis à jour toutes les 5 min par le fil « Synchro avec Titouan » (Claude, cloud). Dernière mise à jour : 16 oct., 11h24 (Paris).
Toi (ou ta session), tu écris dans `docs/coordination/titouan-vers-equipe.md`. Ne touche pas à ce fichier-ci.

## Échéances (heure de Paris)
- **14h** : build sur TestFlight (pas de prod). Dernier archive vers 13h15.
- **15h** : deck **Keynote** envoyé au jury. Pitch 5 min + 2 min de questions, rendez-vous en bas à 15h45.

## Branches à jour
- `lot/design-systeme` (d6d5d4e et après) : tous les écrans refaits selon les maquettes (paywall P34 en français compris). Depuis : « À essayer » plein (appât, hameçon, technique, moment) et pastille « Ton spot · lieu » (63e9263).
- `lot/widget-aquarium` (483071c) : brochet, gardon, silure et perche en volume dans le widget, nouveaux fonds océan.
- `mac/integration` (944fe44) : ce qui compile sur le Mac d'Adem, avec le design d6d5d4e et l'abonnement (Pro forcé en Debug pour la démo).
- `lot/aquarium` : rendus 3D poussés pour brochet, gardon, perche, silure et black-bass (618fdf9).

## Ne pas toucher en ce moment
Le fil design modifie : `App/Carte/Vues`, `App/Session`, `App/Conseils`, `App/Collection`, `App/Club`, `App/Prise`, `App/Abonnement`, et ajoute dans `Core/Conseils`. Ensuite viennent « À essayer » et le parcours du spot ci-dessous.
Évite ces fichiers ; si tu dois y toucher, écris-le d'abord dans `titouan-vers-equipe.md`.
`RootView.swift`, le `.xcodeproj` et `mac/integration` restent à Adem.

## Parcours du spot (décidé par Adem, 16 oct. 11h10)
1. P03 « Où pêches-tu ? » puis question du niveau : inchangés.
2. Swipe des poissons : le dernier écran n'a plus qu'**un bouton « Voir mon spot »**. Il ferme le swipe et ouvre l'onglet Carte. Il ne démarre jamais la session.
3. **Vol vers le spot** : la carte s'ouvre sur toute la zone, puis la caméra vole en ~2 s jusqu'au cercle de 1 km du spot proposé. Bulle : « Ton spot, à 2,3 km. Touche la rivière pour le déplacer ». Puis la fiche P06 « Ton spot » monte (poisson le plus pêché en vedette, « Commencer une session », « Choisir un autre spot », « Y aller »). Le vol n'a lieu qu'au premier passage.
4. Avant la 1re session, toucher la rivière déplace le cercle ; la fiche suit.
5. La session ne démarre que par « Commencer une session » sur la fiche.
6. **Session en plein écran réductible** : un geste vers le bas ou un bouton « Carte » la réduit en bandeau sur la carte (chrono + appareil photo). Toucher le bandeau rouvre le plein écran.
7. Fin de session (P16) puis paywall qui se ferme : inchangés, retour sur la carte.

## Pêche éthique (décision d'Adem)
- On met en avant le poisson **le plus pêché** du spot.
- On ne propose **jamais** un spot à cause d'une espèce rare.

## Blocages
- TestFlight / iCloud : toujours bloqué chez MWM. Le compte d'Adem ne peut pas créer le conteneur iCloud ; il faut un admin MWM. Le premier envoi est parti sans iCloud (sauvegarde et amis coupés).

## Ce qu'on attend de toi
1. **Tes rendus 3D de l'aquarium, maintenant 5 espèces** : **tanche, rotengle, ablette, barbeau, carassin**, dans cet ordre. Consigne complète : `docs/mac-a-faire/titouan-rendus-aquarium.md` sur `lot/aquarium`. Une espèce par commit, poussée dès qu'elle est prête (`git pull --no-rebase` puis push, jamais en force).
2. **Ne fais PAS breme-commune ni chevesne** : un fil cloud les prend juste après la carpe (changement de 11h23, faute de nouvelles de ta part). Les autres (gardon, perche, sandre, truite-fario, silure, black-bass, carpe-commune, brochet) sont faites ou en cours dans le cloud.
3. Écris dans `titouan-vers-equipe.md` : chaque espèce poussée, ce qui bloque, tes questions.

## Règles communes
- Ne touche jamais aux branches des autres sans l'écrire ici d'abord.
- Jamais de `push --force`.
