# État pour Titouan

Mis à jour toutes les 5 min par le fil « Synchro avec Titouan » (Claude, cloud). Dernière mise à jour : 16 oct., 11h57 (Paris).
Toi (ou ta session), tu écris dans `docs/coordination/titouan-vers-equipe.md`. Ne touche pas à ce fichier-ci.


## ❓ QUESTION URGENTE D'ADEM (11h48)
**Adem a vu que tu fais tourner l'app directement dans Xcode depuis ton Claude, en prenant moins de RAM. On veut faire pareil sur son Mac (8 Go). Comment tu fais, exactement ?**
**Réponds dans `titouan-vers-equipe.md` avec :**
1. **L'outil** : un MCP Xcode (lequel ?), XcodeBuildMCP, l'agent intégré à Xcode 27, une commande `xcrun simctl`, autre ?
2. **L'installation** : ce que tu as installé et réglé (commande `claude mcp add ...`, fichier de config, réglage dans Xcode).
3. **Les commandes** que ton Claude lance pour compiler et lancer l'app (et sur quel simulateur ou appareil).
4. Ce qui fait que ça prend moins de RAM (DeviceHub fermé ? Xcode fermé ? `xcodebuild` seul ?).


## 🔧 PAS DE SPOTS DANS TON SIMULATEUR ? (correctif)
Les 3 fichiers de données (`stations-especes.json`, `rarete-departements.json`, `stations-hydro.json`) ne sont jamais dans git : ils sont dans la release GitHub privée « donnees ». Sans eux, la carte n'a aucun spot.
1. Dans ton dépôt, sur `mac/integration` : `git pull`.
2. Si besoin : `brew install gh` puis `gh auth login` (ton compte doit avoir accès au dépôt).
3. Depuis la racine du dépôt : `scripts/donnees.sh`. Il doit afficher 3 lignes ✓ : `App/Donnees/stations-especes.json`, `App/Donnees/rarete-departements.json`, `App/Donnees/stations-hydro.json`.
4. Dans Xcode : Product > Clean Build Folder (⇧⌘K), puis relance.
5. Facultatif : `xcrun simctl location booted set 48.835,2.240` (position simulée).

Si un ✗ s'affiche, copie le message dans `titouan-vers-equipe.md`.


## ⚠️ TA BRANCHE `titouan/finitions` CROISE LE FIL DESIGN
On a vu tes commits (86466576 : cartes, météo façon Apple, aquarium dans l'app, Communauté, Pescedex de démo). Bien joué, mais ils touchent les mêmes fichiers que le fil design en ce moment : `App/Collection/*` (Pescedex, recto, verso, plein écran), `App/Club/*`, `App/Carte/Vues/VueCarte.swift`, `App/Session/*`, `App/Abonnement/TextesPaywall.swift`, et `App/RootView.swift` (à Adem).
**Avant d'aller plus loin, écris dans `titouan-vers-equipe.md`** : ce que tu veux voir fusionné, et sur quoi tu repars. On s'accorde avec Adem et le fil design pour ne pas écraser leur travail (`lot/design-systeme`).
Deux points à vérifier de ton côté : les photos de `App/Demo/Photos/` sont-elles libres de droit (elles seraient publiées dans l'app) ? Et le mode démo est-il bien sous `#if DEBUG` (rien de factice dans le build envoyé à Apple) ?

## Échéances (heure de Paris)
- **14h** : build sur TestFlight (pas de prod). Dernier archive vers 13h15.
- **15h** : deck **Keynote** envoyé au jury. Pitch 5 min + 2 min de questions, rendez-vous en bas à 15h45.

## Branches à jour
- `lot/design-systeme` (d6d5d4e et après) : tous les écrans refaits selon les maquettes (paywall P34 en français compris). Depuis : « À essayer » plein (appât, hameçon, technique, moment) et pastille « Ton spot · lieu » (63e9263).
- `lot/widget-aquarium` (483071c) : brochet, gardon, silure et perche en volume dans le widget, nouveaux fonds océan.
- `mac/integration` (3dab93b) : compile sur le Mac d'Adem ; le parcours du spot y est (« Voir mon spot » avec vol vers le cercle, session réductible en bandeau) et l'ouverture « Le bond » ralentie.
- `lot/aquarium` : rendus 3D poussés pour brochet, gardon, perche, silure, black-bass, sandre et truite-fario (06ea21a).

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
