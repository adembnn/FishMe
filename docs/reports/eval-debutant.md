# Évaluation débutant : lots L0 Squelette, L3 Prise et D1 Données saisies
Décision débloquée : ce que les fiches de lot doivent contenir et ce qu'il faut faire avant jeudi
Lu le 12/10/2026. [?] = non vérifié. « Estimation » = ma supposition, pas une mesure. Je joue un étudiant de M1 qui n'a jamais fait d'app iPhone : je ne valide rien, je dis où je coince.

## Version simple
Les documents décrivent la maison finie. La porte d'entrée manque : où cliquer dans Xcode, quelle commande taper, qui appeler quand ça coince. Ma matinée se perd à trois endroits : l'attente de l'équipe MWM, le squelette L0 que tout le monde attend, et les données D1 sans lesquelles L1 et L3 ne prouvent rien.
Estimations : L0 passe son test vers 11 h 45 (le plan dit 10 h) ; L3 ne se prouve qu'après 13 h 30 ; D1 demande 10 à 14 h (`donnees.md` §9 dit 10 à 12 h, son tableau additionne 13 à 14 h), `lots.md` en compte 3 à 4.
Claude Code écrit des fichiers, mais je ne le vois créer ni le projet ni les cibles Xcode tout seul. Le serveur MCP d'Xcode 27 sait changer réglages, droits et clés Info, à condition de l'activer (notes de version, §2) : personne ne l'a testé [?].

## 1. Ma matinée, minute par minute (durées = estimations)
### L0 Squelette (Mac A)
| Heure | Ce que je tape ou clique | Ce que je ne comprends pas, où j'attends, où je perds du temps |
|---|---|---|
| 9 h 00 | Terminal, `claude`. Je tape : « Je suis débutant. Lis CLAUDE.md, lots.md (L0) et archi-ios.md §3 et §6. Dis-moi une étape à la fois ce que je clique dans Xcode. » | Quel dépôt ? Aucune URL, aucun `git clone`. Aucune liste de clics : je dépends de ce que Claude Code devine pour Xcode 27. |
| 9 h 10 | Xcode, premier lancement, Settings > Apple Accounts > + | ATTENTE MWM. L'équipe n'apparaît qu'après acceptation de l'invitation (mail sur quelle adresse : celle de l'école ou la perso ?). Le rôle ne suffit pas : Apple note que App Manager et Developer exigent l'accès « Certificates, Identifiers & Profiles » donné dans Users and Access (§2, tableau illisible pour moi [?]). PERTE 20 à 30 min. |
| 9 h 35 | File > New > Project > iOS > App | Nom, identifiant d'organisation, « Storage : None ou SwiftData », « Include Tests » : aucun critère. Le bundle ID est « com.mwm.nomprovisoire », figé après le 1er build (app-store.md ligne 0) : qui le valide ? |
| 9 h 50 | Signing & Capabilities, équipe MWM ; File > New > Target > Widget Extension | Il faut cocher « Include Live Activity » : la page Apple de création dit de le décocher. Chaque cible a sa signature. « Bundle ID not unique » grise le bouton Set Up. |
| 10 h 05 | + Capability (WeatherKit, achats) ; onglet Info : clés caméra, position, Live Activity, chiffrement | `app-store.md` demande App Groups, `archi-ios.md` dit « ni App Groups » : je choisis au hasard. À l'écran, NSCameraUsageDescription s'appelle sans doute « Privacy - Camera Usage Description » [?]. WeatherKit : erreur d'authentification jusqu'à ~30 min après sa création (source secondaire). |
| 10 h 20 | File > New > Package « Core ». Je tape : « Crée les types et les protocoles de archi-ios.md §4, avec un faux de chacun. » | « Protocole », « contrat », « faux service » ne sont pas définis. Aucune signature n'est écrite : Claude Code les invente et tous les lots s'y collent. Option 1 (12 paquets) ou 2 (un `Core`) ? `lots.md` dit « à trancher » : je tranche sans critère. |
| 10 h 45 | Cmd+B (compiler) | Erreurs `public` : « initializer is inaccessible due to internal protection level » (message de mémoire [?] ; l'init automatique d'un type public reste interne, §2). « No such module 'Core' » dans le widget : Core doit être ajouté aussi à la cible Widget. PERTE 20 à 30 min. |
| 11 h 10 | Brancher l'iPhone, Device Hub, Faire confiance, Mode développeur, redémarrage | Les documents ne citent jamais Device Hub (§2). Le réglage n'apparaît qu'après le début de l'appairage. Wi-Fi de l'école : l'appairage sans fil peut échouer [?]. PERTE 15 à 30 min. |
| 11 h 25 | Run sur le simulateur, puis sur l'iPhone | Premier démarrage du simulateur iOS 27 : plusieurs minutes signalées (archi §5), même s'Apple annonce un démarrage plus rapide (§2). « Untrusted Developer » possible sur l'iPhone [?]. |
| 11 h 40 | Je tape : « Crée le .gitignore Xcode, fais le commit et pousse sur main. » | Pas de dépôt distant ni de règle de branche écrits. Test de L0 passé vers 11 h 45. Le premier envoi TestFlight de 12 h n'a aucun pas-à-pas (Archive, Distribute) et je ne sais pas si mon rôle peut envoyer. |
### L3 Prise (Mac B)
| Heure | Ce que je tape ou clique | Ce que je ne comprends pas, où j'attends, où je perds du temps |
|---|---|---|
| 9 h 00 | Je lis `lots.md` et `archi-ios.md` §2.1 | ATTENTE : pas de projet avant ~11 h 45. `lots.md` dit que B démarre L1 « sur les faux services » à 9 h, mais les faux naissent dans L0 à ~10 h 45. |
| 11 h 50 | `git pull`, ouvrir le projet, choisir l'équipe | Mon compte doit être dans l'équipe MWM, sinon « No account for team ». Je tape : « Crée la branche lot/prise. » |
| 12 h 00 | Je tape : « Lis lots.md (L3), archi §2.1 et Core. Construis le parcours photo, 3 propositions, curseur, verdict. » | Dossier : `App/Prise/` (lots.md) ou `Packages/Prise` plus `Packages/Identification` (archi). Contrat : je dois lire le code de Core écrit par un autre. Les 14 espèces et leurs noms sont dans `donnees.md` §3, pas dans un fichier. |
| 12 h 30 | Run dans le simulateur | Pas de caméra (PhotosPicker), photothèque vide : où sont les 20 photos de poissons ? (archi §6 point 5, sans responsable). L'IA y est sans doute indisponible : je ne vois que la grille [?]. |
| 12 h 50 | Run sur l'iPhone, câble | Crash au lancement si la clé caméra manque. Je n'ai pas le droit de toucher le `.xcodeproj` : ATTENTE Mac A. « L'iPhone de test » est au singulier : un téléphone pour deux Mac ? |
| 13 h 10 | L'IA répond mal, double une espèce, ou `modelNotReady` | Aucun écran ne montre le téléchargement du modèle [?]. Langue iPhone différente de la langue Siri : IA indisponible (§2). Photo couchée : `orientation:` oublié. PERTE 30 min. |
| 13 h 40 | Tester le verdict | Les règles sont un faux tant que L1 et D1 manquent. Les « 5 cas préparés » n'existent nulle part. Mode avion : le câble est obligatoire si Xcode se connecte en Wi-Fi (estimation). |
| 14 h 00 | Je tape : « Fusionne lot/prise dans main. » | CONFLIT git : A a modifié Core pendant que je codais, j'ai des lignes `<<<<<<<` que je ne sais pas lire. PERTE 20 à 30 min. Pas de CI : « le test bloque la fusion » veut dire « je promets ». `xcodebuild test` est marquée [?] (scheme, simulateur). Aucun seuil de précision de l'IA : « 3 propositions » passe même si elles sont fausses. Gel atteint, L1 et L4 (même Mac B) non commencés. |
### D1 Données saisies (C, sans Mac)
| Heure | Ce que je tape ou clique | Ce que je ne comprends pas, où j'attends, où je perds du temps |
|---|---|---|
| 9 h 00 | Session Claude Code cloud (« à confirmer », lots.md). Je tape : « Je suis débutant, sans Mac. Lis lots.md (D1) et donnees.md. Crée data/regles.json avec le schéma du §4, trois règles pour commencer, et dis-moi où est chaque source. » | Dossier `data/` (lots.md), `Resources/` (archi, lots L1) : qui copie vers l'app, et comment sans Mac ? Aucune commande git pour moi. |
| 9 h 20 | Overpass Turbo : coller la requête de `donnees.md` §1, exporter | Requête jamais exécutée par l'auteur [?] : France entière, délai 180 s, plan B absent. Quel fichier prendre dans france-geojson ? |
| 9 h 50 | `coins-maison.json`, 30 à 60 points | Quels coins ? Aucun critère (accès public ?). Coordonnées « prises dans Plans » : application Mac, je n'en ai pas. |
| 10 h 20 | `regles.json` national, depuis Légifrance (R436-6 à R436-21). Je tape : « Remplis le fichier pour R436-18 et colle le texte de la loi à côté. » | Légifrance : ma lecture automatique de R436-18 a échoué [?], donc je dépends du site à la main. Je ne sais pas encoder « 2e samedi de mars » dans `du` et `au`, ni la `valeur` de chaque `type`, ni nommer `id` et `remplace`. Un seul exemple (brochet 94). PERTE 30 min, et L1 lira mon format. |
| 11 h 20 | 75, 92, 93, 94, 77 | La page de la fédération donne bien 60, 50, 40 et 23 cm (vérifié, §2), mais sans date, et cite des arrêtés de 2010 et 2017 alors que `donnees.md` cite celui de 2025 pour le 75. Lequel prime ? Si je mets `incertain`, l'app ne dira jamais « tu peux la garder ». Les PDF du 77, 92 et 94 sont à lire à la main : 1 h chacun est optimiste. |
| 13 h 00 | Relecture croisée « contre l'arrêté » | Par qui ? Je suis seul sur D1. Le test « chaque règle a sa source » n'a pas de commande (ni script, ni `jq`). |
| 13 h 30 | `stations-especes.json` | Absent de D1 dans `lots.md`, attribué à « étudiant 1 » dans `donnees.md` (script Python de 2 à 3 h, puis 1 h d'exécution). « Jamais commité » mais l'app en a besoin : qui l'ajoute au build ? |
D1 est loin d'être fini à 14 h, et S1 (4 à 6 h, même personne) attend derrière.

## 2. Ce que j'ai vérifié chez Apple (lu le 12/10/2026)
- Équipe et signature : connexion dans Xcode > Settings > Apple Accounts, puis Set Up Signing (équipe, bundle ID unique, sinon bouton grisé), bouton Register pour l'iPhone. Les simulateurs tournent dans Device Hub : https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices
- Device Hub (Xcode > Open Developer Tool > Device Hub, ou Manage Devices…) : appairage sans fil seulement avec iOS 27 et même Wi-Fi ; par câble, Trust puis Pair ; si l'appareil n'apparaît pas après Trust, le redémarrer : https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub
- Mode développeur : il n'apparaît dans Réglages que si l'appairage est commencé ; Réglages > Confidentialité et sécurité, interrupteur, redémarrage, puis Enable et code : https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device
- Rôles : App Manager et Developer exigent l'accès « Certificates, Identifiers & Profiles » accordé dans Users and Access (note lue, cases du tableau perdues [?]) : https://developer.apple.com/help/account/access/roles/
- IA : trois raisons d'indisponibilité confirmées (`appleIntelligenceNotEnabled`, `deviceNotEligible`, `modelNotReady`) : https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason . Aucune page ne dit où voir l'avancement du téléchargement [?].
- Image dans la requête : CGImage, CIImage, CVPixelBuffer ou URL (UIImage n'est pas listé, contrairement à `archi-ios.md` §2.1) ; `orientation:` existe ; exemple `@Generable enum` avec `.greedy` : https://developer.apple.com/documentation/foundationmodels/analyzing-images-with-multimodal-prompting
- Appareils : iPhone 15 Pro et plus, français inclus, langue de l'iPhone égale à celle de Siri, 8 Go (14 Go pour certains) ; l'IA est « automatically available » après la mise à jour 27.0 : à constater sur l'iPhone plutôt qu'à supposer, `archi-ios.md` §5 parle d'activer et de télécharger [?] : https://support.apple.com/en-us/121115
- Paquet local : File > New > Package, puis General > Frameworks, Libraries, and Embedded Content ; la page ne dit rien de `public` ni de la cible Widget : https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages . Swift : « A public type defaults to having internal members » : https://raw.githubusercontent.com/swiftlang/swift-book/main/TSPL.docc/LanguageGuide/AccessControl.md
- Extension : la page officielle demande de décocher « Include Live Activity » (cas widget simple), l'inverse d'E4 : https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension
- Xcode 27 : macOS Tahoe 26.6 exigé ; runtimes du simulateur avec cache précalculé (démarrage plus rapide) ; serveur MCP pour agents (simulateur, captures, clés Info), `sudo xcrun mcp-server enable` en préversion : https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes
- Données : la page de la fédération confirme 60, 50, 40, 23 cm et 3 par jour dont 2 brochets, sans date : http://www.federation-peche-paris.fr/808-reglementation.htm . Légifrance R436-18 : page non ouverte par mes outils [?].

## 3. Ce qui manque pour que je sois autonome
- Vocabulaire non défini : cible (target), protocole, contrat, faux service, module/paquet/lot (trois mots pour un dossier), branche, merge, pull request, build, Archive, capability et entitlement, profil de provisionnement, Device Hub, `@Generable`, rôles App Manager et Developer, `async`.
- Commandes jamais données : `git clone`, créer la branche `lot/...`, fusionner, `gh pr create` ; `xcodebuild -version`, `xcrun simctl list runtimes`, `xcrun devicectl list devices` (iPhone visible ?) ; `xcodebuild test` complet avec un vrai nom de scheme ; valider un JSON ; vérifier que seul mon dossier a changé (`git diff --name-only`).
- Réglages non décrits : chaque clic de L0 (liste en §5) ; Minimum Deployments iOS 27.0 pour l'app, le widget et le `Package.swift` ; ajout de Core à la cible Widget ; où saisir les clés Info ; case « Shared » du scheme ; où mettre les photos de test dans le simulateur ; connexion de Claude Code au compte de chacun.
- Décisions sans critère : Option 1 ou 2 ; options du modèle de projet Xcode ; bundle ID ; rôle MWM ; encodage des dates dans `regles.json` ; `incertain` ou `verifie` quand deux sources divergent ; seuil de précision de l'IA ; qui relit D1 ; où vivent les tests (une cible de test doit exister, donc Mac A) ; quoi couper si un test échoue à 14 h.
- Contradictions : App Groups (app-store.md oui, archi non) ; dossier des données (`data/`, `Resources/`, `Packages/Donnees/Resources/`) ; L3 dans `App/Prise/` ou deux paquets ; B démarre à 9 h alors que les faux naissent vers 10 h 45 ; « 12 espèces sur 31 » alors qu'il y en a 14 ; un seul iPhone pour deux Mac ; D1 à 3 à 4 h dans `lots.md` contre 10 à 14 h dans `donnees.md` ; le script Hub'Eau n'a aucun lot.

## 4. La fiche de lot d'une page
Elle contient, dans cet ordre : 1. But en une phrase et étape servie. 2. Cases « avant de commencer », chacune avec sa preuve en une commande. 3. Dossiers permis et interdits. 4. Contrat en mots (entrées, sorties, cas d'échec), sans code avant jeudi. 5. Consigne à coller dans Claude Code. 6. Test « fini » : commande, sortie attendue, test à la main numéroté. 7. Pièges connus (3 au plus) avec parade. 8. À qui demander, après combien de minutes, et quoi couper si c'est raté à 14 h. Exemple rempli :
```
FICHE L3 PRISE   Mac B   branche lot/prise   étape E5   durée prévue 2 à 3 h (estimation)
BUT : d'une photo de poisson au verdict « garde » ou « relâche », sans jamais bloquer l'écran.
AVANT DE COMMENCER (preuve entre parenthèses) :
 [ ] L0 fusionné (git log montre « L0 squelette » ; l'app vide se lance sur l'iPhone)
 [ ] clés caméra et photothèque et cible de test posées par Mac A (l'app ne plante pas à l'ouverture de la caméra)
 [ ] iPhone avec IA prêt (l'app jetable de mercredi a affiché « disponible » : capture collée ici)
 [ ] data/cas-verdicts.json et le dossier photos existent (5 cas, réponse attendue écrite par un humain)
DROIT DE TOUCHER : App/Prise/ seulement. INTERDIT : *.xcodeproj, Packages/Core, App/Donnees, data/.
CONTRAT (copié de Core, en mots) :
 identifier(photo, département) donne 3 espèces de la liste fermée de 14, ou « grille manuelle » avec la raison
 (pas d'IA, IA non activée, modèle pas prêt, erreur). Jamais de message d'erreur, jamais de pourcentage.
 verdict(espèce, taille cm, date, département) donne garde, relâche ou « vérifie l'arrêté », la phrase et la source.
 L'IA ne touche jamais au verdict. Les 14 espèces viennent de data/especes.json, pas de ta tête.
CONSIGNE À COLLER DANS CLAUDE CODE :
 « Je suis débutant. Lis CLAUDE.md, lots.md (ligne L3), archi-ios.md §2.1 et cette fiche. Travaille seulement dans
 App/Prise/. Construis : choix ou prise de photo, 3 propositions de l'IA d'Apple (sinon grille des 14 espèces),
 curseur de taille, verdict. Ne calcule jamais le verdict toi-même : appelle le service de règles de Core. Ne touche à aucun
 .xcodeproj. Après chaque fichier créé, une phrase pour m'expliquer. À la fin, lance la commande de test et colle la sortie. »
TEST « FINI » (colle les sorties dans la pull request) :
 1. xcodebuild test -scheme <scheme noté par Mac A> -destination 'platform=iOS Simulator,name=<iPhone>' : « TEST SUCCEEDED » [?]
 2. iPhone avec IA, câble, mode avion : photo, 3 propositions, taille, verdict (vidéo d'écran de 30 s)
 3. Même chose sur iPhone sans IA ou réglage simulé : grille, même verdict
 4. data/cas-verdicts.json : 5 cas sur 5 justes. 5. git diff --name-only main : uniquement App/Prise/
PIÈGES : photo couchée (orientation:) ; pas de caméra au simulateur (PhotosPicker) ; modelNotReady (réessayer au retour).
À QUI DEMANDER : projet, clés, contrat : Mac A ; données : C ; MWM : (nom, canal) [?]. Bloqué 20 min : 3 lignes
 (ce que j'ai tapé, l'erreur, ce que j'ai essayé) puis je continue sur la grille manuelle.
SI RATÉ À 14 H : on livre grille + verdict, l'IA devient bonus (décision d'Adem [?]).
```

## 5. À faire avant jeudi, sans écrire de code de l'app
1. MWM : invitations envoyées mardi, acceptées mercredi midi ; accès « Certificates, Identifiers & Profiles » coché ; contrat Paid Apps ; bundle ID écrit et figé ; WeatherKit activé sur l'identifiant (30 min de délai). Preuve : capture de Settings > Apple Accounts montrant l'équipe MWM sur chaque Mac.
2. Projet jetable (accord d'Adem requis, archi §6 point 7) : sur chaque Mac, un projet vide hors dépôt, supprimé ensuite (ce n'est pas du code de l'app), signé, lancé sur l'iPhone, qui affiche `SystemLanguageModel.default.availability`. Il lève en grande partie les blocages 1, 5 et 6 en 15 min par Mac (estimation).
3. Mac, installé mardi soir (estimation : 10 à 20 Go à télécharger avec le runtime iOS 27) ; commandes de mémoire, à valider [?] : `sw_vers -productVersion` donne 26.6 ou plus ; `uname -m` donne arm64 ; `xcodebuild -version` donne Xcode 27.0 ; `xcrun simctl list runtimes` montre iOS 27.0 ; simulateur lancé une fois ; `claude` et `gh auth status` connectés.
4. iPhone : modèle noté, iOS 27, 20 Go libres, langue égale à celle de Siri, mode développeur, câble, UDID envoyé à MWM si la signature automatique est coupée. Combien de téléphones pour 2 Mac ? Décider.
5. Dépôt : privé, créé, trois accès, `.gitignore` Xcode, `CLAUDE.md` du dépôt (Xcode 27.0, iOS 27.0, structure choisie), commande de fusion écrite. Un script `verifier-lot` qui refuse un lot touchant un fichier hors de son dossier, comme `verifier_rapport.py`.
6. Fiches des 11 lots rédigées avec contrats en mots ; liste figée des 14 espèces (nom, cas Swift, code Sandre) ; 5 cas de verdict avec réponse attendue ; 20 photos nommées par espèce ; clics de L0 listés écran par écran.
7. D1 commence mardi (pas besoin de Mac) : requête Overpass exécutée, format de `regles.json` figé avec 3 règles complètes, validateur d'une ligne, lecteur désigné pour la relecture, script Hub'Eau lancé sur le 94 (recommandation de `donnees.md`).

## 6. Les 7 blocages les plus probables (probabilités = estimations, classés par probabilité puis par perte)
| # | Blocage | Qui | Proba | Parade |
|---|---|---|---|---|
| 1 | Équipe MWM : invitation non acceptée, mauvais compte Apple, accès « Certificates » oublié, bundle ID refusé | A, B | 80 % | §5 point 1 et projet jetable mercredi ; un Admin enregistre les iPhone si la signature automatique est coupée |
| 2 | D1 en retard ou format ambigu : L1 et L3 ne prouvent rien | C, B | 75 % | D1 dès mardi, format figé, 5 cas de verdict écrits à la main ; en dernier recours, socle national et 94 seuls |
| 3 | Cascade L0 : Core pas prêt à 10 h, B et A attendent | A, B | 70 % | clics de L0 listés d'avance, contrats en mots, B lit et prépare ses photos pendant L0 |
| 4 | Erreurs de paquet Swift : `public` oublié (init compris), plateforme trop ancienne, Core absent du widget | A, B | 65 % | ligne fixe dans chaque consigne : « tout ce que l'app utilise est `public`, init compris, Package.swift en iOS 27 » |
| 5 | iPhone absent de Device Hub, mode développeur invisible, simulateur lent, un seul téléphone | A, B | 55 % | câble, `xcrun devicectl list devices`, test mercredi, ordre de passage du téléphone |
| 6 | IA indisponible sur l'iPhone de test (`modelNotReady`, langue Siri, place disque) | B | 50 % | contrôle mercredi, 20 Go libres, deuxième iPhone sans IA, réglage de scheme (source secondaire [?]) |
| 7 | Conflit git ou `project.pbxproj` : je touche un fichier hors dossier | A, B | 40 % | script `verifier-lot`, A seul sur le projet, XcodeGen décidé d'avance comme secours |

## Recommandation
1. Préparer deux jours avant jeudi : mardi D1, invitations MWM et téléchargements ; mercredi projet jetable sur les deux Mac et fiches de lot au format du §4. Option la plus forte écartée : tout laisser à Claude Code jeudi. Elle convient au code ; les clics Xcode, les comptes et l'iPhone resteraient sans guide.
2. Structure : l'Option 2 (un seul `Core`) me convient mieux, parce que `public` ne concerne qu'un paquet et que L3 reste dans `App/Prise/` sans toucher au projet. Décision technique de l'évaluateur iOS.
3. Corriger `lots.md` : B démarre L1 quand Core est poussé (vers 11 h 45), D1 compte 10 à 14 h, le script Hub'Eau reçoit un lot et un responsable, le calendrier de 14 h tient compte de près de 2 h de squelette en plus.
Décor : ces trois points demandent un geste de toi ou de MWM avant jeudi 9 h. Sans réponse, j'applique a partout.
Questions pour Adem (réponds « 1. a / 2. a / 3. a »).
1. Projet jetable mercredi sur les deux Mac, 15 min chacun, avec MWM qui invite mardi : a) oui (recommandé, défaut) / b) non.
2. D1 démarre mardi et un pêcheur ou toi relit les règles jeudi 9 h : a) oui (défaut) / b) jeudi seulement.
3. Un seul iPhone ou deux pour les deux Mac : a) un iPhone avec IA par Mac (défaut) / b) un seul, passé de main en main.
