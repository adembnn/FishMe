# Atelier Mac : outils du simulateur, des captures et de l'envoi TestFlight
Décision débloquée : quels outils gratuits donnent à Claude Code des yeux et des mains sur le simulateur, prennent les captures de la fiche App Store et envoient le build sur TestFlight, et ce que chaque Mac doit avoir mercredi soir pour que tout cela marche jeudi.
Lu le 13/10/2026. [?] = non vérifié. Rien n'a été lancé sur un Mac (rédigé sous Linux) : chaque commande Mac vient d'une source citée en bas de page. Les scripts et le Fastfile ont été essayés sous Linux avec de faux outils.

## En bref

| Besoin | Choix | Livré dans |
|---|---|---|
| Claude pilote le simulateur | XcodeBuildMCP, paquet `mobilebuildmcp@2.7.1`, un seul serveur | `.mcp.json` |
| Contrôle de la machine | `scripts/docteur.sh` (Mac et Linux) | `scripts/docteur.sh` |
| Envoi TestFlight | `xcodebuild archive` puis `-exportArchive` avec `destination=upload`, compte d'Xcode | `scripts/envoi.sh` |
| Captures de la fiche | fastlane `snapshot` via les voies `captures` et `verifier_captures` | `fastlane/` |
| Mise en route des 2 Mac | 15 étapes | `docs/atelier-mac.md` |

## 1. XcodeBuildMCP

- **Le nom a changé.** `xcodebuildmcp.com` redirige vers `mobilebuildmcp.com`. Le dépôt historique est `getsentry/XcodeBuildMCP`, le paquet npm actuel est `mobilebuildmcp` (version 2.7.1 lue dans le paquet). Gratuit, open source, maintenu par Sentry. J'ai figé `mobilebuildmcp@2.7.1` : une mise à jour du paquet ne peut pas casser l'atelier en pleine semaine. La clé du serveur dans `.mcp.json` reste `XcodeBuildMCP`, donc les noms d'outils côté Claude restent `mcp__XcodeBuildMCP__<outil>`.
- **Installation pour Claude Code, au niveau du projet** : fichier `.mcp.json` à la racine (type `stdio`, `command`, `args`, `env`), commité. Équivalent en ligne de commande : `claude mcp add --scope project XcodeBuildMCP -- npx -y mobilebuildmcp@2.7.1 mcp`. Claude Code demande l'accord de chaque personne la première fois ([doc MCP](https://code.claude.com/docs/en/mcp)).
- **Réglages choisis** (`env`) : `MOBILEBUILDMCP_ENABLED_WORKFLOWS=simulator,ui-automation,device,xcode-ide` (les autres groupes d'outils restent éteints, pour garder un contexte léger), `MOBILEBUILDMCP_SENTRY_DISABLED=true` (pas de statistiques), `MOBILEBUILDMCP_PROJECT_PATH=Projet.xcodeproj` (le nom prévu par le plan, L0).
- **Noms exacts des outils** (relevés en démarrant le serveur, 46 outils) :

| Action | Outil MCP |
|---|---|
| lister les schémas / les simulateurs | `list_schemes`, `list_sims` |
| compiler pour le simulateur | `build_sim` |
| compiler, installer et lancer | `build_run_sim` |
| lancer les tests | `test_sim` |
| capture d'écran | `screenshot` |
| décrire l'écran (arbre des éléments, avec références) | `snapshot_ui` |
| toucher, écrire, glisser | `tap`, `type_text`, `swipe`, `long_press`, `gesture`, `button` |
| vidéo du simulateur | `record_sim_video` |
| iPhone branché | `build_run_device`, `list_devices`, `install_app_device`, `launch_app_device` |
| réglages de session | `session_set_defaults`, `session_show_defaults` |
| outils propres à Xcode (via `xcrun mcpbridge`) | `xcode_ide_list_tools`, `xcode_ide_call_tool` |

- **Défauts de session** : le schéma et le simulateur doivent être donnés une fois par `session_set_defaults`, ou écrits dans `.mobilebuildmcp/config.yaml` (commande `npx mobilebuildmcp setup`). Ce dossier est hors des dossiers permis de H0 et de L0 : à décider (voir Recommandation) `[?]`.
- **Sous Linux** : le serveur démarre (Node suffit) et annonce ses outils, mais chaque appel échoue (`spawn xcrun ENOENT`, `MCPBRIDGE_NOT_FOUND`). Dans une session cloud, Claude Code charge les serveurs du projet sans poser de question ([doc MCP](https://code.claude.com/docs/en/mcp)) : C aura donc ces outils inutiles dans son contexte.
- **Vérification sans Claude** (aucun appel payant) : `npx -y mobilebuildmcp@2.7.1 simulator list`, puis `… xcode-ide list-tools` avec le projet ouvert dans Xcode `[?]`.

## 2. Ce que fait Xcode 27 pour les agents

Source : [notes de version d'Xcode 27](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes).

- **Réglage** : `Xcode > Settings > Intelligence > Model Context Protocol`, case « Allow external agents to use Xcode tools » ([Apple, agents externes](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode)). C'est ce que relaie `xcrun mcpbridge`.
- **Nouveautés** : les agents d'Xcode lancent un simulateur, installent et lancent l'app, simulent des touchers et capturent l'écran ; le serveur MCP d'Xcode gagne le débogage, le changement de schéma et de destination, la lecture et l'édition des réglages de build, des entitlements et de l'Info.plist ; aperçus SwiftUI en variantes (clair/sombre, tailles de texte) ; plugins avec skills ; protocole ACP ; couche de sécurité sur l'accès aux fichiers (réglable).
- **Aperçu à surveiller** : depuis la bêta 5, `sudo xcrun mcp-server enable` active un serveur MCP qui n'exige plus de projet ouvert dans Xcode. Je ne l'ai pas utilisé : « aperçu précoce » selon Apple, état en 27.0 final inconnu `[?]`.
- **Device Hub** remplace la fenêtre Simulator pour piloter simulateurs et iPhone. MobileBuildMCP le gère depuis sa version 2.7.0.
- **Prérequis** : macOS Tahoe **26.6 ou plus**, et Mac à **puce Apple seulement** (même source).
- **Premier simulateur iPhone** : `[?]`. La vidéo WWDC26 258 lance l'app sur « iPhone 17 Pro » ([vidéo](https://developer.apple.com/videos/play/wwdc2026/258/)) ; la page des captures d'Apple cite déjà l'iPhone 18 Pro et l'iPhone 18 Pro Max. Rien n'est écrit en dur : le docteur lit la liste réelle et la voie fastlane prend le plus récent « Pro Max » et le plus récent « Pro » d'iOS 27.

## 3. Envoi TestFlight : `xcodebuild archive` puis `-exportArchive`

- **Chaîne retenue** : `xcodebuild archive -project … -scheme … -configuration Release -destination generic/platform=iOS -archivePath … -allowProvisioningUpdates CURRENT_PROJECT_VERSION=<n>`, puis `xcodebuild -exportArchive -archivePath … -exportOptionsPlist … -exportPath … -allowProvisioningUpdates`.
- **ExportOptions.plist** : `method=app-store-connect`, `destination=upload` (« export » ou « upload », défaut export, selon `xcodebuild -help`), `signingStyle=automatic`, `uploadSymbols=true`. Avec `upload`, l'archive part directement vers App Store Connect, sans `altool` ni Transporter.
- **Compte d'Xcode, sans clé** : `-allowProvisioningUpdates` laisse xcodebuild parler à Apple avec le compte connecté dans Xcode (la page de manuel le dit pour le compte ; pas de preuve écrite pour un envoi complet sous Xcode 27) `[?]`. Un fil du forum Apple rappelle que la clé d'API ne permet pas toutes les opérations qu'Xcode fait avec un compte connecté ([forum](https://developer.apple.com/forums/thread/763225)) : le compte est donc la première voie, la clé le repli.
- **Repli par clé d'API** : `-authenticationKeyPath`, `-authenticationKeyID`, `-authenticationKeyIssuerID`. Une clé d'équipe (« Team Key », créée par un Admin) est nécessaire pour les profils ; une clé individuelle ne couvre pas les endpoints de provisioning ([Apple](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)). À demander à MWM : un Admin crée la clé (rôle Admin ou App Manager `[?]`) et la remet en main propre ; les trois valeurs vont dans `.env`, rempli par la personne elle-même, jamais dans un chat.
- **Numéro de build** : calculé en minutes depuis le 1er octobre 2026, passé en `CURRENT_PROJECT_VERSION`, relu dans l'archive avant l'envoi. `BUILD=<n>` pour en imposer un. La clé `manageAppVersionAndBuildNumber` n'est pas posée : son défaut sous Xcode 27 n'est pas confirmé `[?]`.
- **Versions d'Xcode acceptées** par App Store Connect : build avec Xcode 26 ou plus pour une app iOS ([Apple](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)) : Xcode 27.0 convient.
- **Garde-fous du script** : refus hors Mac, hors Xcode 27, hors branche `main`, arbre non propre, retard ou avance sur `origin/main`, `scripts/verif.sh` rouge ; question o/N avant l'envoi (ou `--oui`) ; `--a-blanc` archive et exporte en local sans rien envoyer.

## 4. Captures de la fiche : fastlane `snapshot`

- **Principe** : `snapshot` lance les tests d'interface (UI tests) de l'app sur des simulateurs et ramasse les images demandées par `snapshot("01Accueil")`. Il faut une cible de tests d'interface, `SnapshotHelper.swift` (la voie `preparer_captures` le copie depuis fastlane) et un schéma partagé. C'est A, seul à toucher au projet Xcode, qui les crée jeudi.
- **Voie `captures`** : choisit les simulateurs d'après `xcrun simctl list devices available -j`, passe `ios_version`, `languages=["fr-FR"]`, `only_testing`, puis contrôle les tailles des PNG (en-tête lu en Ruby pur). Le nom du schéma et de la cible : `SCHEMA_TESTS_UI` et `CIBLE_TESTS_UI`, en tête du Fastfile ou en variables d'environnement.
- **fastlane 2.236.0 minimum** : avant lui, `snapshot` échouait sur iOS 26.4.1 parce que la version était tronquée (26.4) dans la destination de `xcodebuild` ; le correctif ([PR 30054](https://github.com/fastlane/fastlane/pull/30054)) vise le simulateur par son identifiant et sort dans la [version 2.236.0](https://github.com/fastlane/fastlane/releases/tag/2.236.0). `fastlane_version "2.236.0"` en tête du Fastfile, et le docteur le contrôle.
- **Écart à signaler au plan** : `docs/app-store.md` ligne 4 demande des captures 6,9" (1320 x 2868) « prises sur le build TestFlight ». La page [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) lue le 13 oct. liste comme exigé au moins un jeu « iPhone with Dynamic Island (medium display) » (1179 x 2556 ou 1206 x 2622, soit 6,3"), alors que le 6,9" (1260 x 2736, 1290 x 2796, 1320 x 2868) est le grand écran, et ajoute que les plus grandes tailles se réduisent automatiquement. La lecture de la page est ambiguë `[?]`. Par prudence, la voie fournit les deux ; `seul_6_9:true` ne garde que le 6,9".
- **Build des captures** : `configuration("Release")` dans le Snapfile, donc même code que le build envoyé (les faux services sont sous `#if DEBUG`). Si la compilation des tests d'interface en Release casse, A passe à Debug, mais les captures montreraient alors des faux services : à éviter pour la fiche `[?]`.
- **Fichiers produits** : `fastlane/screenshots/` et `fastlane/report.xml`, déjà dans le `.gitignore` de la branche `atelier/garde`.
- **Testé sous Linux** avec fastlane 2.241.0 : lecture du Fastfile, voies listées, choix des simulateurs sur JSON factice, contrôle de tailles sur faux PNG, passage des paramètres à `capture_screenshots` avec des simulateurs simulés. Jamais lancé avec Xcode `[?]`.

## 5. swift-snapshot-testing pour photographier les cartes

- **Rôle** : tests automatiques qui comparent l'image d'une vue SwiftUI à une image de référence : un bon filet pour la carte à collectionner (les 4 raretés, nom long, texte agrandi, mode sombre). Gratuit ([dépôt Point-Free](https://github.com/pointfreeco/swift-snapshot-testing)).
- **Avec Swift Testing** : pris en charge depuis la 1.17.0 : `@Test func carte() { assertSnapshot(of: CarteView(...), as: .image(layout: .device(config: .iPhone13Pro))) }`. Réglage par suite : `@Suite(.snapshots(record: .failed))`. Version 1.19.x à jour (pièces jointes Swift Testing, correctif de la marge de sécurité de `UIHostingController`).
- **Contraintes** : les images de référence dépendent du simulateur et de la version d'iOS : toujours le même appareil `[?]` ; elles sont commitées (petites) ; la transparence « Liquid Glass » des fonds peut varier d'un rendu à l'autre `[?]`.
- **Qui l'ajoute** : c'est une dépendance de paquet et une cible de tests, donc un changement de `.xcodeproj` : A seul. `Core` reste en Foundation seulement et ne le reçoit pas. Non installé par cet atelier.

## 6. Réglages à ajouter dans `.claude/settings.json` (non écrits par moi)

```json
{
  "enabledMcpjsonServers": ["XcodeBuildMCP"],
  "permissions": {
    "allow": [
      "mcp__XcodeBuildMCP__list_sims", "mcp__XcodeBuildMCP__list_schemes",
      "mcp__XcodeBuildMCP__session_set_defaults", "mcp__XcodeBuildMCP__session_show_defaults",
      "mcp__XcodeBuildMCP__build_sim", "mcp__XcodeBuildMCP__build_run_sim", "mcp__XcodeBuildMCP__test_sim",
      "mcp__XcodeBuildMCP__screenshot", "mcp__XcodeBuildMCP__snapshot_ui",
      "mcp__XcodeBuildMCP__tap", "mcp__XcodeBuildMCP__type_text", "mcp__XcodeBuildMCP__swipe",
      "Bash(fastlane captures*)", "Bash(fastlane verifier_captures*)", "Bash(fastlane preparer_captures*)"
    ],
    "ask": ["Bash(scripts/envoi.sh*)"]
  }
}
```

- `enabledMcpjsonServers` évite la question d'approbation, mais Claude Code l'ignore dans un dossier non approuvé : la première session demande donc quand même « faire confiance au dossier » ([doc](https://code.claude.com/docs/en/mcp)).
- `Bash(scripts/*)` est déjà permis dans la branche `atelier/garde` : cela couvre `scripts/envoi.sh --oui`, qui envoie un build à Apple sans question. La règle `ask` passe avant `allow` et garde l'humain dans la boucle.
- Pour la session cloud de C : `{"disabledMcpjsonServers": ["XcodeBuildMCP"]}` dans `.claude/settings.local.json` (ou par `scripts/cloud-pret.sh`).
- Les outils `*_device` (installer sur l'iPhone) restent volontairement hors de la liste permise : une question à chaque fois.

## 7. Autres outils gratuits (rien d'installé hors liste)

- **swift-snapshot-testing** (section 5), le plus utile pour les cartes.
- **xcbeautify** (`brew install xcbeautify`) : rend lisible le journal de `xcodebuild`, pour que Claude lise moins de bruit.
- **`xcrun simctl location booted set 48.85,2.35`** (déjà dans Xcode) : place l'iPhone virtuel dans un département (75, 92, 93, 94, 77) pour tester la rareté locale ; le groupe d'outils `simulator-management` de XcodeBuildMCP fait pareil, plus l'effacement et le mode sombre, et se rajoute dans `MOBILEBUILDMCP_ENABLED_WORKFLOWS`.
- **`npx mobilebuildmcp init`** : installe une « skill » pour l'agent. Elle écrit hors des dossiers de l'atelier, donc non lancée.

## Recommandation

1. Garder ce paquet d'outils : XcodeBuildMCP figé en 2.7.1, `xcodebuild` + `destination=upload` avec le compte d'Xcode, fastlane `snapshot`. Aucun n'a besoin de clé payante ni de compte supplémentaire.
2. Jeudi matin, juste après L0 : A lance `scripts/envoi.sh --a-blanc` pour prouver archive + export, puis un envoi réel d'un squelette, **avant** de promettre l'envoi du soir. Si la signature échoue, demander à MWM une clé d'équipe (section 3) tout de suite.
3. Fusionner les réglages de la section 6 dans `.claude/settings.json` (lot H0).
4. Demander à B ou C, qui tiennent la fiche, de lire la page des tailles de captures avant jeudi 15 h 30 : la ligne 4 de `docs/app-store.md` parle du 6,9" seul.
5. Décider qui écrit `.mobilebuildmcp/config.yaml` (schéma et simulateur par défaut) : option conseillée, A le crée avec `npx mobilebuildmcp setup` après L0 et le commite ; sinon le crochet de démarrage de H0 rappelle à Claude d'appeler `session_set_defaults`.
6. Option écartée : le MCP d'Xcode seul, sans XcodeBuildMCP. Plus direct, mais il exige Xcode ouvert sur le projet et son aperçu sans fenêtre est instable `[?]`.

## À vérifier sur un Mac

1. `scripts/docteur.sh` tout vert sur chaque Mac, et la forme réelle de `xcrun devicectl list devices` (le script cherche `connected` ou `available`).
2. `scripts/envoi.sh --a-blanc` puis un envoi réel : `destination=upload` avec le compte d'Xcode 27, et le défaut de `manageAppVersionAndBuildNumber`.
3. Le nom du premier simulateur iPhone d'Xcode 27 et le résultat de `fastlane captures` (tailles réelles 1320 x 2868 et 1206 x 2622).
4. L'approbation du serveur au premier `claude` du dossier, `/mcp`, et la sortie de `xcode-ide list-tools` (fenêtre « Allow » dans Xcode ?).
5. Le rendu du verre et des flous dans les images de référence de swift-snapshot-testing.

## Sources

- [Notes de version d'Xcode 27](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes) : macOS 26.6, puce Apple, MCP, agents.
- [Apple, simulateurs supplémentaires](https://developer.apple.com/documentation/xcode/installing-additional-simulator-runtimes) : `xcodebuild -downloadPlatform iOS`, `-runFirstLaunch`, `xcode-select -s`.
- [Apple, agents externes dans Xcode](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode)
- [Apple, spécifications des captures](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Apple, envoyer un build](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [Apple, clés d'API](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)
- [Page de manuel de xcodebuild](https://keith.github.io/xcode-man-pages/xcodebuild.1.html) et [ExportOptions classées](https://gist.github.com/jessedc/12a74aff88d06e669cf1c9999408c62c)
- [XcodeBuildMCP (Sentry)](https://github.com/getsentry/XcodeBuildMCP), [documentation](https://www.xcodebuildmcp.com/docs), [nouveau nom](https://www.mobilebuildmcp.com/)
- [Claude Code, MCP](https://code.claude.com/docs/en/mcp) et [installation](https://code.claude.com/docs/en/setup)
- [fastlane snapshot](https://docs.fastlane.tools/actions/snapshot/), [guide des captures](https://docs.fastlane.tools/getting-started/ios/screenshots/), [fastlane 2.236.0](https://github.com/fastlane/fastlane/releases/tag/2.236.0)
- [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) et [le billet sur Swift Testing](https://www.pointfree.co/blog/posts/146-swift-testing-support-for-snapshottesting)
- [Homebrew](https://brew.sh/), [gh auth login](https://cli.github.com/manual/gh_auth_login)
