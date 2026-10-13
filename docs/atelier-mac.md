# Atelier Mac : préparer ton Mac (mercredi soir)

À suivre sur **chaque Mac** (A et B), dans l'ordre. À la fin, `scripts/docteur.sh` affiche « Tout est vert ». Ne passe à l'étape suivante que si tu vois ce que l'étape annonce. Si ce n'est pas le cas, va à « Si ça coince » en bas de page.

## Trois mots avant de commencer

- **Terminal** : la fenêtre où l'on tape des commandes au lieu de cliquer. Ouvre-la avec `Cmd + Espace`, tape `Terminal`, appuie sur Entrée. Pour chaque ligne grise ci-dessous : copie-la, colle-la avec `Cmd + V`, valide avec Entrée.
- **sudo** : devant une commande, il veut dire « fais-le en administrateur ». Le Mac te demande ton mot de passe ; en le tapant, rien ne s'affiche, c'est normal.
- **Commande** : une ligne de texte qui demande une action au Mac. Elle ne casse rien tant que tu la copies telle quelle.

## Les 15 étapes

### 1. Vérifier le Mac
```
sw_vers -productVersion
sysctl -n hw.optional.arm64
```
Tu dois voir `26.6` ou plus (par exemple `26.6.1`), puis `1`. Le `1` veut dire que le Mac a une puce Apple (M1, M2…) : Xcode 27 ne marche que sur ces Macs. Si la version est plus basse : Réglages Système > Général > Mise à jour de logiciels. ([Notes de version d'Xcode 27](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes))

### 2. Installer Xcode 27.0
**Xcode** est le logiciel d'Apple qui fabrique l'app. Télécharge la version **27.0** sur [developer.apple.com/download/all](https://developer.apple.com/download/all/) (compte Apple demandé) ou dans l'App Store, puis glisse `Xcode.app` dans le dossier Applications. Ouvre-le une fois, accepte la licence et laisse-le installer ses composants.
```
ls -d /Applications/Xcode*.app
```
Tu dois voir au moins `/Applications/Xcode.app`.

### 3. Choisir cet Xcode et finir son installation
Un Mac peut avoir plusieurs Xcode ; ces deux commandes disent lequel utiliser et terminent l'installation des outils de base.
```
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcodebuild -version
```
Tu dois voir `Xcode 27.0` puis une ligne `Build version …`. Si ton Xcode a un autre nom (par exemple `Xcode-27.0.app`), remplace-le dans la première ligne. ([Apple, composants d'Xcode](https://developer.apple.com/documentation/xcode/installing-additional-simulator-runtimes))

### 4. Télécharger et lancer une fois le simulateur iOS 27
Le **simulateur** est un iPhone virtuel qui s'ouvre sur l'écran du Mac.
```
xcodebuild -downloadPlatform iOS
xcrun simctl list runtimes
```
Le téléchargement est long. Ensuite tu dois voir une ligne qui commence par `iOS 27.0`. Pour le lancer une fois, prends un nom dans la liste de `xcrun simctl list devices available | grep iPhone` (par exemple `iPhone 18 Pro`) :
```
xcrun simctl bootstatus "iPhone 18 Pro" -b
xcrun simctl shutdown "iPhone 18 Pro"
```
Le premier démarrage est le plus lent. Si la commande répond `Invalid device`, remplace le nom par l'identifiant entre parenthèses de la liste.

### 5. Connecter le compte Apple de l'équipe MWM dans Xcode
Dans Xcode : `Xcode > Settings > Apple Accounts`, bouton `+`, « Apple ID », ton compte. Tu dois voir l'équipe **MWM** sous ton compte. Prends une capture de cet écran : c'est la preuve demandée par la fiche L0. (Sans l'invitation MWM acceptée, l'équipe n'apparaît pas.)

### 6. Installer Homebrew
**Homebrew** est un installateur de logiciels gratuit qui se pilote au Terminal. Colle la commande donnée sur [brew.sh](https://brew.sh/) :
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
À la fin, Homebrew affiche « Next steps » avec deux ou trois commandes : copie-les exactement. Sur un Mac à puce Apple, ce sont :
```
echo >> ~/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
brew --version
```
Tu dois voir `Homebrew` suivi d'un numéro de version. ([Installation de Homebrew](https://docs.brew.sh/Installation))

### 7. Installer gh, Node et fastlane
`gh` parle à GitHub. **Node** fait tourner XcodeBuildMCP (étape 11). **fastlane** prend les captures d'écran de la fiche App Store.
```
brew install gh node fastlane
gh --version
node --version
fastlane --version
```
Tu dois voir une version pour chacun ; `fastlane` doit afficher `2.236.0` ou plus. L'installation de fastlane prend plusieurs minutes. ([fastlane](https://docs.fastlane.tools/getting-started/ios/setup/))

### 8. Connecter gh à GitHub
```
gh auth login
gh auth status
```
Réponds : `GitHub.com`, `HTTPS`, `Yes` (pour authentifier git), `Login with a web browser`. Le Terminal affiche un code à 8 caractères : copie-le, appuie sur Entrée, colle-le dans la page GitHub qui s'ouvre. `gh auth status` doit afficher `Logged in to github.com account …`. ([gh auth login](https://cli.github.com/manual/gh_auth_login))

### 9. Installer Claude Code
```
curl -fsSL https://claude.ai/install.sh | bash
```
L'installation n'affiche rien pendant le téléchargement. Quand elle est finie, **ferme le Terminal et rouvre-en un**, puis :
```
claude --version
```
Tu dois voir un numéro de version suivi de `(Claude Code)`. ([Claude Code, installation](https://code.claude.com/docs/en/setup), [guide du Terminal](https://code.claude.com/docs/en/terminal-guide))

### 10. Récupérer le projet et brancher les crochets de git
**Cloner** veut dire copier le projet de GitHub sur ton Mac. **git** est l'outil qui garde l'historique du projet. Ses **crochets** sont de petits programmes qu'il lance avant d'enregistrer ou d'envoyer ton travail, pour refuser ce qui est cassé.
```
cd ~/Documents
gh repo clone adembnn/build-challenge-unaite-mwm-apple-f
cd build-challenge-unaite-mwm-apple-f
git config core.hooksPath .githooks
git config core.hooksPath
```
La dernière ligne doit afficher `.githooks`. Reste sur la branche proposée par défaut. Les commandes suivantes se lancent toutes depuis ce dossier.

### 11. Télécharger XcodeBuildMCP à l'avance
**XcodeBuildMCP** (gratuit, open source, maintenu par Sentry) laisse Claude Code compiler l'app, la lancer dans le simulateur, lire l'écran et taper dedans. Le fichier `.mcp.json` du projet le démarre tout seul ; on le télécharge maintenant pour que jeudi il démarre vite. Le projet a changé de nom : le paquet s'appelle maintenant `mobilebuildmcp`, et `.mcp.json` fige la version 2.7.1.
```
MOBILEBUILDMCP_SENTRY_DISABLED=true npx -y mobilebuildmcp@2.7.1 --version
```
Tu dois voir `2.7.1`. (`npx` est livré avec Node. `SENTRY_DISABLED` coupe l'envoi de statistiques.) ([XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP), [nouveau nom](https://www.mobilebuildmcp.com/))

### 12. Autoriser les agents à utiliser Xcode
**MCP** est le branchement standard qui permet à un agent comme Claude Code d'utiliser les outils d'une autre application. Dans Xcode : `Xcode > Settings > Intelligence > Model Context Protocol`, coche **Allow external agents to use Xcode tools**. Cela ouvre à XcodeBuildMCP les outils propres à Xcode (aperçus SwiftUI, journal de compilation). ([Apple, agents externes](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode))

Test sans Claude Code, avec le simulateur :
```
MOBILEBUILDMCP_SENTRY_DISABLED=true npx -y mobilebuildmcp@2.7.1 simulator list
```
Tu dois voir la liste des iPhone virtuels, dont ceux d'iOS 27. Jeudi, quand le projet sera ouvert dans Xcode, `… xcode-ide list-tools` doit lister les outils d'Xcode ; Xcode peut alors afficher une fenêtre « Allow ? » : clique Allow [?].

### 13. Se connecter à Claude Code et accepter le serveur du projet
Dans le dossier du projet :
```
claude
```
La première fois, une page web s'ouvre pour te connecter. Claude Code demande ensuite s'il peut faire confiance au dossier (réponds oui), puis s'il peut utiliser le serveur **XcodeBuildMCP** du projet (réponds oui). Tape `/mcp` : la ligne XcodeBuildMCP doit indiquer qu'il est connecté [?]. Sors avec `/exit`, sans rien demander d'autre. ([Claude Code, MCP](https://code.claude.com/docs/en/mcp))

### 14. Brancher l'iPhone de test (facultatif ce soir)
Câble, déverrouille l'iPhone, touche « Se fier à cet ordinateur ». Dans Xcode : `Window > Devices and Simulators` doit lister l'iPhone. Ensuite, sur l'iPhone : Réglages > Confidentialité et sécurité > Mode développeur (cette ligne n'apparaît qu'après le premier branchement à Xcode), puis redémarrage.
```
xcrun devicectl list devices
```
Tu dois voir ton iPhone avec l'état `connected` ou `available`.

### 15. Figer les mises à jour, puis lancer le docteur
Coupe les mises à jour automatiques : Réglages Système > Général > Mise à jour de logiciels > (i) à côté de « Mises à jour automatiques », et désactive tout. Plus aucune mise à jour d'Xcode ou de macOS avant la fin du challenge. Puis, dans le dossier du projet :
```
scripts/docteur.sh
```
Le **docteur** est un script qui contrôle les points ci-dessus et affiche une ligne par point : `✓` c'est bon, `✗` à réparer (la commande de réparation est écrite dessous), `·` facultatif. Il doit se terminer par **Tout est vert**. Si un `✗` reste : lance la commande « réparer » indiquée, puis relance le docteur. Envoie la sortie complète à A si le `✗` revient.

## Ce que ces outils font jeudi

- **XcodeBuildMCP** : Claude Code compile et lance l'app dans le simulateur, lit l'écran, tape et capture. Ses outils s'appellent `build_sim`, `build_run_sim`, `screenshot`, `snapshot_ui`, `tap`, `type_text`, `list_sims`, `list_schemes`. Il se règle dans `.mcp.json`.
- **Captures d'écran de la fiche** : `fastlane preparer_captures` (une fois, par A, qui crée aussi la cible de tests d'interface, un petit programme qui touche l'écran à ta place), puis `fastlane captures` : captures en français sur l'iPhone 6,9" (1320 x 2868) et 6,3", dans `fastlane/screenshots/` (ignoré par git). Les deux tailles sont prises parce que la page d'Apple et le plan ne citent pas la même comme exigée ; `fastlane captures seul_6_9:true` ne garde que le 6,9". `fastlane verifier_captures` contrôle les tailles.
- **Envoi sur TestFlight** (A ou B, après L0). Un **build** est une version de l'app prête à être envoyée ; **TestFlight** est l'app d'Apple qui sert à la tester avant publication ; **App Store Connect** est le site où MWM gère l'app. `scripts/envoi.sh --a-blanc` répète tout sans rien envoyer. `scripts/envoi.sh` envoie pour de vrai, depuis `main` (la branche principale du projet) à jour et verte (toutes les vérifications passent), avec le compte Apple connecté dans Xcode, et pose une question avant. Le numéro de build monte tout seul (minutes écoulées depuis le 1er octobre 2026). Le **schéma** (le réglage Xcode qui dit quoi compiler) est lu dans la ligne `SCHEMA=` de `scripts/verif.sh`. Le build apparaît ensuite dans App Store Connect > TestFlight, après quelques minutes de traitement par Apple [?].

## Si l'envoi par le compte Apple échoue : la clé d'API

Message typique : « No signing certificate » ou « Cloud signing permission error ». La voie de repli est une **clé d'API App Store Connect**, un fichier `.p8` qui remplace la connexion par compte.

1. Un **Admin** de l'équipe MWM la crée : App Store Connect > Users and Access > Integrations > App Store Connect API > Team Keys > `+`, rôle **Admin ou App Manager** [?]. Il télécharge le `.p8` (téléchargeable une seule fois) et note le Key ID et l'Issuer ID. ([Apple, clés d'API](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api))
2. Range le `.p8` hors du projet, par exemple dans `~/.appstoreconnect/`.
3. Dans le projet, crée le fichier des secrets avec des noms vides, puis ouvre-le dans un éditeur :
   ```
   scripts/env.sh
   ```
   Il recopie les noms de `env.exemple` dans `.env`, valeurs vides, et ouvre `.env`. Claude peut le lancer pour toi : il ne lit jamais le fichier.
   Remplis les trois valeurs toi-même (`ASC_KEY_PATH` = chemin complet du `.p8`). Ne les colle jamais dans un chat ni dans Claude Code. `.env` et `*.p8` sont déjà dans `.gitignore`.
4. Relance `scripts/envoi.sh`. Quand les trois valeurs sont remplies, il les utilise ; sinon il garde le compte Xcode.

## Sous Linux (la session cloud de C)

C n'a pas de Mac et n'a rien de cette page à installer. Dans une session cloud, Claude Code charge le serveur de `.mcp.json` sans poser de question et Node le démarre, mais tous ses outils échouent (`spawn xcrun ENOENT`, `MCPBRIDGE_NOT_FOUND`) faute de Xcode. Il ne fait aucun mal, mais il ne sert à rien. Pour l'éteindre, C crée le fichier `.claude/settings.local.json` avec `{"disabledMcpjsonServers": ["XcodeBuildMCP"]}`. `scripts/docteur.sh` y contrôle autre chose : Docker, l'image `swift:6.4`, `gh` et Python ; la réparation est `scripts/cloud-pret.sh`. `scripts/envoi.sh` refuse de démarrer sous Linux, avec un message clair.

## Si ça coince

| Ce que tu vois | Ce qu'il faut faire |
|---|---|
| `command not found: brew` (ou `gh`, `node`, `claude`) | Ferme le Terminal et rouvre-en un. Si ça persiste : relis les commandes « Next steps » de l'étape 6. |
| `xcode-select: error` ou `xcodebuild: error: tool 'xcodebuild' requires Xcode` | Étape 3 : `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`. |
| `docteur.sh` : `✗ aucun simulateur iOS 27` | `xcodebuild -downloadPlatform iOS` (étape 4). |
| `docteur.sh` : `✗ XcodeBuildMCP … pas encore téléchargé` | Étape 11, avec du réseau. |
| fastlane se plaint de l'encodage (UTF-8) | `echo 'export LC_ALL=en_US.UTF-8' >> ~/.zshrc` puis `echo 'export LANG=en_US.UTF-8' >> ~/.zshrc`, ferme et rouvre le Terminal. |
| XcodeBuildMCP reste « Pending approval » dans `claude mcp list` | Lance `claude` dans le dossier du projet et accepte le serveur (étape 13). |
| Xcode ne voit pas l'iPhone | Câble, « Se fier », mode développeur (étape 14), redémarrage de l'iPhone. |
| `envoi.sh` : « Unable to log in » | Xcode > Settings > Apple Accounts : reconnecte le compte, puis relance. |

Les points marqués [?] n'ont pas pu être confirmés sans Mac ; le détail et les sources sont dans `docs/reports/atelier-mac.md`.
