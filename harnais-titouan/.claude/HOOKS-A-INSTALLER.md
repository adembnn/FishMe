# Hooks à installer : SPÉCIFICATION (rien n'est installé)

Ce fichier ne contient aucun script. Il décrit ce que doivent faire les deux hooks du template `mon-harness` (`garde-fou.mjs`, `fin-de-tour.mjs`, Node) une fois copiés dans ce projet, avec les adaptations propres à Bredouille. **Tout est à valider par l'utilisateur** avant copie des scripts ou modification de `.claude/settings.json`. Les hooks du template s'exécutent avec Node : vérifier que `node` est installé sur le PC de Titouan et sur le Mac d'Adem.

## 1. `garde-fou` (PreToolUse, outils Bash et PowerShell) : blocages à ajouter

Le template bloque déjà `git push --force`, `git reset --hard`, `git clean -f`, `git checkout -- .`, `rm -rf` et toute mention de `.env`. Pour Bredouille, il doit **en plus** bloquer (code de sortie 2, message en français expliquant quoi faire à la place) :

| Cible | Détail à bloquer | Pourquoi |
|---|---|---|
| Force-push | `git push` avec `--force`, `-f`, `--force-with-lease`, ou `+branche` ; aussi `git push --delete` sur `main` | Deux devs sur le même dépôt, un écrasement perd le travail de l'autre |
| Suppression de dossiers de données | `rm -r`/`rm -rf`, `Remove-Item -Recurse`, `rmdir /s`, `del /s`, `git rm -r` visant `Data-images/`, `PecheCore/Resources/`, `Tools/data-pipeline/cache/`, `Data/`, `plan/`, `docs/` | Les données mettent des heures à regénérer (Hub'Eau, images) ; `Data-images/` n'est pas dans Git |
| `project.pbxproj` | Toute écriture ou édition (Write/Edit/commande) d'un chemin contenant `project.pbxproj` ou `*.xcodeproj/` | Il n'existe pas dans le dépôt, `project.yml` (XcodeGen) est la seule source (règle 14) |
| Secrets | `git add` ou écriture de `.env*`, `*.p8`, `*.p12`, `*.cer`, `*.pem`, `*.mobileprovision`, `*.keychain*`, `*.key`, `*apikey*`, `*secret*` ; lecture (`cat`, `type`, `Get-Content`) de ces fichiers | Règle 17 |
| Ajout de masse | `git add -A` / `git add .` quand `git status` contient un de ces fichiers | Évite le commit accidentel |

Précisions :
- Le matcher doit couvrir `Bash|PowerShell` (Titouan est sous PowerShell) **et** les outils d'édition (`Write|Edit`) pour `project.pbxproj` et les fichiers de secrets, car un blocage limité aux commandes serait contournable par Write.
- Les motifs doivent normaliser les séparateurs `\` et `/` et ignorer la casse (Windows).
- Éviter les faux positifs : mentionner `.env` dans un message de commit ou dans ce document ne doit pas bloquer ; viser les arguments de commandes git, de lecture et d'écriture de fichier. Un blocage qui gêne à tort doit se corriger dans l'heure, sinon l'équipe le désactive.

## 2. `fin-de-tour` (Stop) : ce qu'il exécute

À partir de `.claude/verify.json` (copié depuis `verify.json.example`) : si le dépôt a des changements, lancer la commande de vérification, **bloquer la fin du tour une seule fois** si elle échoue (affichant l'erreur), puis laisser passer en prévenant l'humain si elle échoue encore.

**Sans aucun commit automatique** : le template committe `auto: checkpoint` si tout passe ; ici c'est supprimé. Les commits sont `Lxx: résumé` écrits à la main, et la formule « Vérifié / Non vérifié » (règle 13) précède chaque commit.

| Machine | Commande lancée | Comportement |
|---|---|---|
| Windows (Titouan) | `python Tools/check/check_all.py` ; puis, si `swift` est disponible dans le PATH, `swift test` dans `PecheCore/` | Si `swift` est absent, afficher « swift test non exécuté (toolchain absente) » sans échouer |
| Mac (Adem) | `python3 Tools/check/check_all.py` ; puis, si le lot touche Swift et si `project.yml` a changé ou si le dernier build date de plus de 30 min, `xcodegen generate` puis `xcodebuild` sur le schéma de l'app (simulateur) | `xcodebuild` est facultatif et à durée plafonnée (3 minutes) pour ne pas bloquer le travail ; la compilation complète reste lancée à la main |

Autres exigences : afficher à la fin une ligne « Vérifié : … / Non vérifié : … » rappelant la règle 13 ; ne rien vérifier si aucun fichier n'a changé ; une durée totale de plus de 60 secondes est un défaut à corriger (le hook sera sinon désactivé).

## 3. Fragment de configuration à ajouter (à valider par l'utilisateur)

À fusionner dans `.claude/settings.json` sans écraser l'existant (non appliqué) :

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash|PowerShell|Write|Edit",
        "hooks": [{ "type": "command", "command": "node \"$CLAUDE_PROJECT_DIR/.claude/hooks/garde-fou.mjs\"" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "node \"$CLAUDE_PROJECT_DIR/.claude/hooks/fin-de-tour.mjs\"" }] }
    ]
  },
  "permissions": {
    "deny": ["Read(**/.env*)", "Read(**/*.p8)", "Read(**/*.p12)", "Read(**/*.mobileprovision)"],
    "ask": ["Bash(git push*)", "PowerShell(git push*)"]
  }
}
```

À valider avant application : (1) la syntaxe exacte des règles `permissions` et du matcher selon la version de Claude Code installée ; (2) que `$CLAUDE_PROJECT_DIR` se résout sous PowerShell chez Titouan ; (3) que `garde-fou.mjs` du template est bien adapté (nouveaux motifs de la section 1, outils `Write|Edit`) ; (4) que `fin-de-tour.mjs` du template est modifié pour retirer le commit automatique et ajouter la logique du tableau de la section 2. Les deux scripts sont du code : ils se copient et s'adaptent à la main, après relecture, pas depuis cette spécification.
