# État pour Titouan

Mis à jour toutes les 5 min par le fil « Synchro avec Titouan » (Claude, cloud). Dernière mise à jour : 16 oct., 11h09 (Paris).
Toi (ou ta session), tu écris dans `docs/coordination/titouan-vers-equipe.md`. Ne touche pas à ce fichier-ci.

## Échéances (heure de Paris)
- **14h** : build sur TestFlight (pas de prod). Dernier archive vers 13h15.
- **15h** : deck **Keynote** envoyé au jury. Pitch 5 min + 2 min de questions, rendez-vous en bas à 15h45.

## Où en est l'app
- `mac/integration` (7651d5f) compile sur le Mac d'Adem : maquettes branchées dans RootView (session plein écran, prise, fin de session, paywall, réglages, conditions, Pescedex, club), carte découpée. Installée dans DeviceHub à 11h.
- En cours : le fil design corrige « Choisir sur la carte » (demande encore la position) et la question du niveau qui tarde (`lot/design-systeme`).
- Paywall P34 en français comme la maquette (`lot/design-systeme` 39b4d6d), à intégrer au prochain build.
- Widget aquarium : `lot/widget-aquarium` (brochet en volume, nouveaux fonds océan), à fusionner après le design.

## Blocages
- Accès TestFlight / iCloud chez MWM : le compte d'Adem ne peut pas créer le conteneur iCloud. Le premier envoi est parti sans iCloud (sauvegarde et amis coupés). Il faut un admin MWM pour le remettre.

## Ce qu'on attend de toi
1. **Rendus 3D de l'aquarium, ta moitié** : tanche, chevesne, rotengle, breme-commune, ablette, barbeau, carassin. Consigne complète : `docs/mac-a-faire/titouan-rendus-aquarium.md` sur `lot/aquarium`. Une espèce par commit, poussée dès qu'elle est prête (`git pull --no-rebase` puis push, jamais en force).
2. Le cloud fait gardon (poussé), perche, sandre, truite-fario ; un autre fil fait silure, black-bass, carpe-commune. Le brochet est fait.
3. Écris dans `titouan-vers-equipe.md` : chaque espèce poussée, ce qui bloque, tes questions.

## Règles communes
- Ne touche jamais aux branches des autres sans le dire ici. `RootView.swift`, le `.xcodeproj` et `mac/integration` sont à Adem.
- Jamais de `push --force`.
