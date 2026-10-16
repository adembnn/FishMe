# Notes pour le relecteur d'Apple (champ « Notes » d'App Store Connect)

Brouillon en anglais, 3531 octets comptés par Python (limite 4000). Version soumise unique : parcours E1 à E9 plus Amis (CloudKit, CKShare), widget « Mon aquarium » et Live Activity de session (décision d'Adem du 15 oct. : tout dans une seule soumission). Libellés et comportements relus dans le code de `origin/claude/finir-app-ud5swp` (504ee2e, qui contient `mac/integration` 5780585, `lot/amis`, `lot/widget-aquarium`, `lot/ecran-verrouille`), pas sur un iPhone : rien n'est vérifié à l'écran. Rien n'est inventé : coordonnées du quai de Charenton, lien de la vidéo, couverture des règles, contact et Apple ID de test du côté « recevoir » restent entre crochets. Recompter après toute modification (`len(texte.encode("utf-8")) <= 4000`).

Pas de compte à l'ouverture : cocher « Connexion non requise » dans App Store Connect, aucun compte démo (le compte iCloud de l'appareil sert aux amis).

```
FishMe is a freshwater fishing app for France. The map shows where fish were recorded by the French Office for Biodiversity (OFB) and the rules that apply (each with source and quote). Every confirmed catch becomes a collectible card in the user's "Pescedex" (the collection's name).

NO APP ACCOUNT. No sign-in, no demo credentials. Friends use the iCloud account of the device.

HOW TO TEST WITHOUT A FISH OR A RIVER
1. Launch. Location is asked once: allow, or refuse and pick a department on the map. Then "Ton niveau ?" ("Passer" skips), then a deck of common species: swipe right = already caught, left = never. Right swipes create "declared" cards (no photo). Then "Pêcher maintenant". A sheet asks to count app usage: "Accepter" or "Refuser".
2. Test spot: Quai de Charenton, Paris, [LAT, LON]. Tap the river: species, rarity, conditions, rules with sources.
3. Tap "Commencer une session". The first session is always allowed; its place becomes the free spot.
4. Tap "Ajouter une prise", then "Essayer avec une photo d'exemple". Pick the species among 3 images ("Autre espèce" lists all), set the length, "Confirmer la taille", then "Ranger dans le Pescedex". Weight is an estimate.
5. Tap "Terminer": the card is revealed, then the paywall; "Continuer gratuitement sur mon spot" closes it. A 2nd spot opens it too. Use a sandbox account. Prices and trial come from StoreKit; "Restaurer les achats" is there.
6. Free: map, rules, Pescedex, one spot, alerts.
7. FRIENDS (CloudKit). Tab "Mon club", button "Mes amis" (top right). With iCloud on, "Inviter un ami" opens the iOS share sheet: a read-only share to named recipients only. One device is enough to check it. To receive, a second Apple ID opens the link and taps "Accepter" [SECOND TEST APPLE ID, if any]. Without iCloud: no invite button, the banner says "Connecte-toi à iCloud pour voir tes amis. Ton Pescedex reste là." with a "Réglages" link; the rest works. Friends see cards only, place at department level. On a friend: "Signaler", "Bloquer", "Retirer"; "Supprimer mes cartes partagées" stops sharing. Example cards are never shared.
8. WIDGET. Needs one declared card (step 1) or a catch from a real photo; the example photo does not count. Home Screen: hold, "+", search "FishMe", "Mon aquarium", "Add Widget" (also Lock Screen sizes). Empty: "Ta 1re prise nagera ici". A tap opens the Pescedex.
9. LIVE ACTIVITY. Live Activities must be on (Settings > FishMe). After "Commencer une session", press the side button: the Lock Screen and Dynamic Island show a countdown to the legal end of fishing ("fin légale") and the catch count; "Terminer" removes it. No place is shown.

60-second video: [LINK, from B].

LEGAL NOTICE. Rules are indicative; the prefectoral order prevails. The AI never decides whether a fish may be kept: it proposes the species, the user confirms, a sourced rules table answers. Coverage: national baseline plus [DEPARTMENTS FROM THE BUILD]; elsewhere the app says so.

EXTERNAL SERVICES
- Apple Maps (MapKit); OFB surveys and Hub'Eau (Licence Ouverte 2.0), Hub'Eau gets a station code only.
- Apple Weather (WeatherKit): rounded point or OFB station, never the exact position; Apple Weather mark shown.
- iCloud (CloudKit): cards shared only with invited friends.
- Species proposals run on the device (Core ML).
- MWM Spark Flash SDK: diagnostics, no tracking, started only after consent.

PRIVACY. Exact fishing spots never leave the iPhone. Saved photos carry no GPS. Not made for kids.

Contact: [NAME], [PHONE], [EMAIL].
```

## Preuves du code (hors bloc envoyé à Apple)

Branche `claude/finir-app-ud5swp`, sauf mention.

| Ce que dit la note | Preuve |
|---|---|
| Étape 1 : localisation, « Passer », cartes à glisser, cartes déclarées | `App/RootView.swift:164-168` (démarrage), tunnel `lot/premier-pas` (non relu ici) ; cartes déclarées comptées : `RootView.swift:224` |
| « Commencer une session » | `App/Carte/Vues/VueCarte.swift:251` ; `App/Session/BandeauSession.swift:10` |
| « Ajouter une prise » ; « Terminer » | `App/Session/BandeauSession.swift:85` ; `:91` |
| « Essayer avec une photo d'exemple » | `App/Prise/PriseRacineView.swift:78` |
| « Confirmer la taille » ; « Ranger dans le Pescedex » | `App/Prise/PriseVuesResultat.swift:39` ; `:121` (la version exemple s'appelle « Ranger (carte d'exemple) ») |
| « Continuer gratuitement sur mon spot » | `App/Abonnement/TextesPaywall.swift:111` |
| Étape 7 : onglet « Mon club », bouton « Mes amis » (haut à droite) | `RootView.swift:553` ; `:638-646` |
| « Inviter un ami » (ShareLink, partage lecture seule, destinataires nommés) | `App/Amis/AmisView.swift:133-138` ; `:13-14` (`.readOnly`, `.specifiedRecipientsOnly`) |
| Bouton d'invitation absent sans iCloud | `AmisView.swift:47` (`if gestion.compte == .disponible`) ; `GestionAmis.swift:55-58` |
| Bandeau « Connecte-toi à iCloud pour voir tes amis. Ton Pescedex reste là. » et lien « Réglages » | `AmisView.swift:86` ; `:99-100` |
| « Accepter » / « Refuser » à la réception | `AmisView.swift:122-125` ; réception du lien : `App/Amis/RelaisInvitations.swift:48` |
| « Signaler », « Bloquer », « Retirer » ; « Supprimer mes cartes partagées » | `App/Amis/PescedexAmiView.swift:70`, `:49`, `:53` ; `AmisView.swift:205` |
| Lieu limité au département ; collections visibles des amis invités seulement | `AmisView.swift:51` ; `:14` |
| Carte d'exemple jamais partagée | `App/Amis/ConstructeurCartes.swift:13` |
| Étape 8 : widget « Mon aquarium », tailles écran d'accueil et écran verrouillé | `WidgetAquarium/AquariumWidget.swift:39`, `:41-44` |
| « Ta 1re prise nagera ici » (état vide) | `WidgetAquarium/VuesAquariumWidget.swift:148` |
| Le widget exclut la carte d'exemple, compte les cartes déclarées ; le toucher ouvre le Pescedex | `RootView.swift:223-244` ; `:252-253` |
| Étape 9 : Live Activity, compte à rebours « fin légale », nombre de prises, Dynamic Island | `Widget/Session/SessionLiveActivity.swift:29`, `:35`, `:54`, `:76-106` |
| Démarrage au premier plan, silencieux si Live Activities désactivées | `Widget/Session/PilotageActivite.swift:19` ; `RootView.swift:345` |
| « Terminer » retire l'activité | `PilotageActivite.swift:55-63` ; `RootView.swift:359` |
| Aucune position ni nom de coin sur l'écran verrouillé | `Widget/Session/EtatSession.swift:4-8` (heures et un nombre seulement) |
| Clé `NSSupportsLiveActivities` | `BuildChallenge.xcodeproj/project.pbxproj:550` |

## Ce qui manque dans le code pour que chaque étape marche

- Étape 7 : aucun ami d'exemple dans le build envoyé (`FauxServiceAmis` est sous `#if DEBUG`, `App/Amis/FauxServiceAmis.swift:1`) et on ne peut pas accepter son propre partage : le relecteur ne voit le côté « recevoir » qu'avec un second Apple ID. Les cartes ne partent qu'à l'ouverture de « Mes amis » (`RootView.swift:650`) ou au retour du réseau (`GestionAmis.swift:118`), pas à chaque nouvelle carte (le commentaire de `GestionAmis.swift:93` dit « A le branche sur L4 » : non branché).
- Étape 8 : le widget reste vide avec la seule photo d'exemple (`RootView.swift:227`) ; il faut une carte déclarée (tunnel du premier lancement) ou une vraie photo. Si le relecteur a passé le tunnel avec « Passer », rien ne le lui fait revoir (à vérifier sur le build).
- Étape 9 : sans réglage « Activités en direct » l'app n'affiche rien et ne le dit pas (`PilotageActivite.swift:19`) ; la note le dit au relecteur.
- Toujours à lire dans le build : coordonnées du quai de Charenton, `departementsCouverts()`, lien de la vidéo (B), contact d'Adem, ordre réel du premier lancement. Si le modèle ne passe pas l'examen de R1, l'étape 4 devient « all French species as images, the user picks one ». Si une fonction n'est pas dans le build, elle sort des étapes.
