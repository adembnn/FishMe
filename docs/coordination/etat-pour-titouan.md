# État pour Titouan

Mis à jour toutes les 5 min par le fil « Synchro avec Titouan » (Claude, cloud). Dernière mise à jour : 16 oct., 12h24 (Paris).
Toi (ou ta session), tu écris dans `docs/coordination/titouan-vers-equipe.md`. Ne touche pas à ce fichier-ci.



## ✅ MERCI POUR TES RÉPONSES (12h22)
Bien reçu, tout est transmis à Adem et au fil design. Suite :
- **Rotengle : OK, il est à toi.** On prévient le fil cloud qui devait le refaire. À 12h24, déjà refaits avec `PART_DOS=0.1` : brème, carpe, gardon, ablette, perche (+ carassin, silure). Pas encore refaits : tanche, chevesne (fil de renfort), barbeau (autre fil cloud), sandre, truite (cloud). N'en prends pas d'autre sans l'écrire ici.
- Ta réponse Xcode, tes photos (licences) et ta relecture App Store (points a à e) sont chez Adem, qui décide.
- Tes retouches de `RootView.swift` et ton commit dc5ea49 (carte épurée, récap de fin de session, ajout manuel, aquarium vivant) sont signalés au fil design, qui les reprend à la main.

## ❓ Question d'Adem sur Xcode : répondue (merci).

## 🔧 PAS DE SPOTS DANS TON SIMULATEUR ? (correctif)
Les 3 fichiers de données (`stations-especes.json`, `rarete-departements.json`, `stations-hydro.json`) ne sont jamais dans git : ils sont dans la release GitHub privée « donnees ». Sans eux, la carte n'a aucun spot.
1. Dans ton dépôt, sur `mac/integration` : `git pull`.
2. Si besoin : `brew install gh` puis `gh auth login` (ton compte doit avoir accès au dépôt).
3. Depuis la racine du dépôt : `scripts/donnees.sh`. Il doit afficher 3 lignes ✓ : `App/Donnees/stations-especes.json`, `App/Donnees/rarete-departements.json`, `App/Donnees/stations-hydro.json`.
4. Dans Xcode : Product > Clean Build Folder (⇧⌘K), puis relance.
5. Facultatif : `xcrun simctl location booted set 48.835,2.240` (position simulée).

Si un ✗ s'affiche, copie le message dans `titouan-vers-equipe.md`.


## ⚠️ DÉCISION D'ADEM SUR `titouan/finitions` (11h56)
Tes commits (cartes, météo façon Apple, aquarium dans l'app, Communauté, Pescedex de démo) touchent les mêmes écrans que le fil design. **Adem a tranché : le fil design reprend le meilleur des deux, écran par écran, dans `lot/design-systeme`.** Ce que ça change pour toi :
1. **Ne touche plus à `App/RootView.swift`** ni aux écrans de la liste « Ne pas toucher en ce moment » ci-dessous.
2. **Pousse seulement ce qui est nouveau** sur `titouan/finitions`, et **décris-le** dans `titouan-vers-equipe.md` (quel écran, quel fichier, ce qui change) pour que le fil design le reprenne.
3. **Tes 12 photos de démo** (`App/Demo/Photos/`) : il faut une **licence libre et la source citée** pour chacune (dans `App/Demo/photos-demo.json` ou dans ton message). Sinon elles ne seront pas utilisées.

**Déjà repris de ta branche par le fil design (12h00-12h02)** : météo façon Apple (exemple seulement en DEBUG), profil et recherche sur la carte, chargement du spot, photo de soi en fin de session, ouverture ralentie, cartes Eau calme, verso photo plein cadre, lieu et date au recto, geste de la carte, aquarium et widget (`lot/design-systeme` ec95613, 0c4ed8b, 69b991c).
**Repris aussi (12h03-12h05)** : Communauté, profil, pages Club et Amis (f6e0d33) ; ton e1fa051 : spots d'eau, verso photo entière, aquarium plus lent, vignette touchable (12a398f). Mode démo : réglage « Démo cachée » éteint par défaut, tout marqué « Démo » (3765a34).
**Vus, pas encore repris** : df2579c et 20fabcc (session : fond opaque, chrono en anneau façon minuteur Apple). Décris tes prochains commits dans `titouan-vers-equipe.md`. Attention : les « coins publics » sont prévus pour la mise à jour (lot L7), pas pour la version de cet après-midi.

## Échéances (heure de Paris)
- **14h** : build sur TestFlight (pas de prod). Dernier archive vers 13h15.
- **15h** : deck **Keynote** envoyé au jury. Pitch 5 min + 2 min de questions, rendez-vous en bas à 15h45.

## Branches à jour
- `lot/design-systeme` (d6d5d4e et après) : tous les écrans refaits selon les maquettes (paywall P34 en français compris). Depuis : « À essayer » plein (appât, hameçon, technique, moment) et pastille « Ton spot · lieu » (63e9263).
- `lot/widget-aquarium` (483071c) : brochet, gardon, silure et perche en volume dans le widget, nouveaux fonds océan.
- `mac/integration` (3dab93b) : compile sur le Mac d'Adem ; le parcours du spot y est (« Voir mon spot » avec vol vers le cercle, session réductible en bandeau) et l'ouverture « Le bond » ralentie.
- `lot/aquarium` : rendus 3D poussés pour brochet, gardon, perche, silure, black-bass, sandre, truite-fario, carassin, et la brème refaite sans deuxième œil (54bedd6).

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
1. **Merci Titouan !** Tes 6 espèces (tanche, chevesne, rotengle, brème, ablette, barbeau) poussées à 11h42 sont propres. Elles sont déjà dans le widget (`lot/widget-aquarium` 0f47e40).
   **Mais** la relecture a trouvé un deuxième œil sur le haut de la tête (tanche, chevesne, rotengle, brème, ablette, barbeau, et aussi gardon, perche, sandre, truite). Correction : `PART_DOS=0.1` dans la commande (voir `docs/mac-a-faire/titouan-rendus-aquarium.md`, section « À refaire »). Le cloud refait déjà les 6 tiennes. Si tu es libre, tu peux en reprendre une : regarde d'abord `git log origin/lot/aquarium` (un commit « PART_DOS=0.1 » ou « deuxième œil » après 11h50 veut dire déjà refaite) et écris ici laquelle tu prends.
2. Le cloud fait le reste : carassin (commencé à 11h44), carpe, et le silure refait avec la queue droite. **Plus rien ne t'attend sur la liste des rendus.**
3. **Question pour toi : sur quoi tu pars maintenant ?** Écris-le dans `titouan-vers-equipe.md` (et ce qui bloque, tes questions) avant de commencer, pour qu'on ne fasse pas le même travail deux fois.

## Règles communes
- Ne touche jamais aux branches des autres sans l'écrire ici d'abord.
- Jamais de `push --force`.
