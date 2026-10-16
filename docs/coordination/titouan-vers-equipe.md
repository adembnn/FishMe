# Titouan vers l'équipe

Ta session écrit ici (les plus récents en haut) : ce qui est fait et poussé, ce qui bloque, tes questions.
Le fil « Synchro avec Titouan » lit ce fichier toutes les 5 min et transmet à Adem ce qui demande une action.

Format : `- HHhMM (Paris) : ...`

## Messages
- 12h22 (Paris) : **Titouan : j'avais raté ce fichier, je l'ai lu en entier maintenant. Je ne touche plus à `RootView.swift` ni aux écrans de la liste « Ne pas toucher ».** Réponses et état :

  **1. Réponse à Adem (compiler et lancer sans Xcode ouvert, peu de RAM).** Outil : `xcodebuild` en ligne de commande (c'est le compilateur d'Xcode 27, mêmes SDK) + l'outil simulateur de Claude Code (`xcrun simctl` pour lancer/arrêter). Ni XcodeBuildMCP (il exige Node/npx, absent chez moi, il ne démarre pas), ni l'agent intégré à Xcode. Xcode (l'interface) n'est PAS ouvert : c'est ce qui économise la RAM. Rien à installer à part Xcode 27 + le runtime iOS 27 + la Metal Toolchain (`xcodebuild -downloadComponent MetalToolchain`, 840 Mo, nécessaire sinon « cannot execute tool metal »). Commandes, depuis la racine d'un dossier de travail du dépôt :
  `xcodebuild build FISHME_ICLOUD=NO -project BuildChallenge.xcodeproj -scheme BuildChallenge -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath /tmp/dd CODE_SIGNING_ALLOWED=NO`
  puis `xcrun simctl boot 'iPhone 18 Pro'`, `xcrun simctl install booted /tmp/dd/Build/Products/Debug-iphonesimulator/BuildChallenge.app`, `xcrun simctl launch booted ai.mwm.build.challenge.team.01`. **`FISHME_ICLOUD=NO` est indispensable sans signature** : sans lui l'app plante au lancement (`CKContainer(identifier:)` dans SauvegardeICloud, pas d'entitlement iCloud). Pas de simulateur DeviceHub ouvert, un seul simulateur démarré. Une compilation incrémentale dure 1 à 3 min.

  **2. Données (pas de spots).** Fait : `scripts/donnees.sh` lancé chez moi (3 ✓), la carte a bien ses relevés OFB et ses stations.

  **3. Les 12 photos de démo (`App/Demo/Photos/`) : licence et source de chacune sont dans `App/Demo/photos-demo.json`** (champs fichier, auteur, licence, urlSource) et s'affichent dans Profil > Sources. Toutes viennent de Wikimedia Commons : CC0 (brochet-1 AsgerJon, perche-commune-1 Nervurax Fishing), domaine public (sandre-1 eLNuko), CC BY (truite-fario-1 Philthy54 3.0, black-bass-1 Arnaudia31 4.0, silure-glane-1 Joe Pell 2.0), CC BY-SA (brochet-2 Azerty197666 4.0, perche-commune-2 Topbeat 3.0, carpe-commune-1 Viaouest 4.0, chevesne-1 2mentech 4.0, gardon-1 Peter van der Sluijs 4.0, tanche-1 Peter van der Sluijs 3.0). Les CC BY-SA dépassent la règle « CC0 ou CC BY » du CLAUDE.md : à vous de décider de les garder (attribution affichée) ou de les écarter ; les 6 premières suffisent pour la démo. silure-glane-1 montre un visage reconnaissable (pas de gros plan) : à écarter si vous préférez.

  **4. Ce qui est nouveau chez moi (branche `titouan/finitions`, à reprendre par le fil design, je ne le fusionne nulle part).** Déjà poussé : df2579c et 20fabcc (session : fond opaque, anneau chrono ; les boutons et la mise en page d'Adem sont conservés). Pas encore poussé, je le commite à l'instant, nouveaux fichiers surtout :
   - Récap de fin de session « La pêche du jour » : `App/Session/FinSessionView.swift` (enveloppe), nouveaux `RecapSortieView.swift`, `RecapSortieCartes.swift` (cartes créées en carrousel, ou carte Eau calme si rien pêché).
   - Première page de la carte épurée : « Commencer une session » en Liquid Glass + colonne de 4 boutons verre (météo, position, filtre, profil), fiche « Ton spot » remplacée par une feuille « poissons » : `App/Carte/Vues/VueCarte.swift`, `ComposantsCarte.swift`, nouveau `CommandesCarte.swift`.
   - Ajout manuel d'une prise (import d'une photo, espèce, taille, département) : `App/Collection/PescedexView.swift` (bouton « + ») et nouveau `AjoutManuelPriseView.swift`.
   - Aquarium : vrai moteur de comportement (entrées et sorties décalées, bancs, virages, rais de lumière) : nouveaux `App/Aquarium/MoteurNage.swift`, `EffetsEau.swift`, `AquariumView.swift`.
   - Corrections de relecture (recherche de commune, courbe de rivière, MapKit, cache des photos de démo, marque Apple Weather officielle, zone MapKit arrondie, actions amis de démo).
   - **Retouches que j'ai déjà faites dans `RootView.swift` (à reprendre à la main, le fil design en reste propriétaire)** : feuille météo `meteoOuverte` + closures `ouvrirMeteo`/`ouvrirProfil` dans `vueCarte` ; `ajouterManuellement:` dans l'appel `PescedexView` + `ajouterPriseManuelle` dans ParcoursApp ; `rarete:` passé à `FinSessionView` ; `.toolbarVisibility(.hidden, for: .tabBar)` pendant la session plein écran ; `coinsPublics: core.coins()` dans `ServicesCarte(...)`.
   - Règle de design pour agents : `docs/regle-design-agents.md` (poussé).

  **5. Relecture App Store de ma branche (à décider par Adem, bloquant pour la soumission, pas pour la démo).** (a) le code d'amis CloudKit est dans le build alors que la check-list le prévoit hors du build soumis (le relecteur n'a pas de 2e compte iCloud) ; (b) hors démo, le club est une liste locale sans autres membres : le texte « Visible par les membres de ton club » promet un partage qui n'existe pas ; (c) le lien « Confidentialité » (`ParcoursApp.confidentialiteProvisoire`, RootView ~l.588) ouvre la politique d'Apple, pas la nôtre ; (d) le contact de signalement (`ContactClub.adresse`) est une adresse Gmail perso ; (e) le mode démo est visible en Release dans le profil : à écrire dans les notes de revue.

  **6. Rendus 3D.** Mes 7 espèces sont poussées (6 de moi ; le carassin du cloud était déjà là, plus récent). Je vois que brème, carassin, carpe, gardon, ablette, perche, silure sont refaits avec PART_DOS=0.1. **Je prends rotengle maintenant** (je ne touche ni tanche, chevesne, barbeau : dites-moi s'ils sont faits ou si je dois en prendre un autre).
  **7. Sur quoi je pars ensuite :** rotengle, puis je regarde à l'écran la page Club/Amis et la page récap, et je corrige. Je n'ouvre plus de nouvelle fonction sans l'écrire ici d'abord.
