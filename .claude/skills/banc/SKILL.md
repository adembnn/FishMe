---
name: banc
description: "Banc d'essai : de faux utilisateurs ultra critiques (docs/banc/personas.md) font leurs missions dans l'app, trois passages par profil, on garde ce que 2 passages sur 3 relèvent, l'avocat de la défense conteste, et le rapport va dans reports/banc/. Argument : le code d'un lot, ou tout."
argument-hint: "[code du lot | tout]"
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(uname*) Bash(date*) Bash(ls*) Bash(git branch*) Bash(git status*) Bash(git diff*) Bash(python3 outils/atelier/lots.py*) Bash(mkdir -p reports/banc*) Bash(mkdir -p .atelier*) Bash(xcodebuild*) Bash(xcrun simctl*)
---

# /banc : faire passer l'app devant ses pires utilisateurs

Branche courante : !`git branch --show-current`

Tu parles à une personne débutante. Phrases courtes, un terme technique expliqué entre parenthèses la première fois. Le banc ne prouve rien à lui seul : une note de faux utilisateur ne valide jamais une étape (règle d'Adem). La preuve reste l'iPhone de test et de vrais pêcheurs.

## 0. Quoi tester
- Argument `tout`, ou rien sur `main` : tous les profils de `docs/banc/personas.md`, toutes leurs missions.
- Sinon le lot (argument, ou celui de la branche : `python3 outils/atelier/lots.py lot <branche>`), ses étapes (`python3 outils/atelier/lots.py json`), et seulement les missions de `docs/banc/personas.md` qui passent par ces étapes. Le profil « designer exigeant » joue toujours.
Dis en une ligne quels profils et quelles missions tu lances.

## 1. Préparer
Lance `uname -s`.
- **Mac (`Darwin`)** : l'app vivante. Fabrique-la une seule fois : `xcodebuild -project BuildChallenge.xcodeproj -scheme BuildChallenge -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath .atelier/build-du-banc build`. Rouge : arrête-toi, montre les 10 dernières lignes utiles. Puis crée un simulateur par passage parallèle (6 au plus à la fois, la mémoire du Mac ne tient pas plus) : `xcrun simctl create banc-<k> "<un iPhone de xcrun simctl list devicetypes>" <le runtime iOS 27 de xcrun simctl list runtimes>`, `xcrun simctl boot <udid>`, `xcrun simctl install <udid> .atelier/build-du-banc/Build/Products/Debug-iphonesimulator/BuildChallenge.app`. Chaque passage reçoit son propre simulateur : deux agents sur le même écran se marchent dessus.
- **Ailleurs** : pas d'app vivante. Les passages jouent sur les captures de `reports/ecrans/` et le code de `App/`. Dis-le : ce banc-là ne voit ni tailles réelles, ni vitesse.
`mkdir -p reports/banc/captures`.

## 2. Jouer : 3 passages par profil
Dans un seul message (un lot de 6 au plus sur Mac, tous ailleurs), un appel à l'outil Agent par passage : `subagent_type` `banc-utilisateur`, `model` `sonnet`. Prompt :

```
Profil : <nom exact de la fiche>. Passage <1|2|3>. Missions : <codes>. <Sur Mac : ton simulateur est <udid> ; passe simulatorId=<udid> à chaque outil mcp__XcodeBuildMCP__…, lance l'app avec xcrun simctl launch <udid> ai.mwm.build.challenge.team.01, capture avec xcrun simctl io <udid> screenshot.> Réponds dans le format de ton fichier.
```

## 3. Garder ce qui revient
Pour chaque profil, regroupe les critiques qui parlent du même défaut sur le même écran. Garde celles relevées par au moins 2 passages sur 3, ou par au moins 2 profils différents. Jette les autres, compte-les. Fais aussi le tableau des missions : réussite, touchers et secondes de chaque passage, et la médiane.

## 4. L'avocat
Un appel à l'outil Agent : `subagent_type` `banc-avocat`, `model` `sonnet`, avec la liste gardée (profil, gravité, preuve, fondement, nombre de passages). Montre sa réponse telle quelle.

## 5. Le rapport
Écris `reports/banc/<lot ou tout>-<AAAAMMJJ-HHMM>.md` (la date vient de `date +%Y%m%d-%H%M`) : profils et missions lancés, machine (app vivante ou non), tableau des missions, puis la réponse de l'avocat, puis le nombre de critiques jetées faute de consensus. Pas de tiret cadratin.

## 6. Ranger
Sur Mac : `xcrun simctl shutdown` puis `xcrun simctl delete` pour chaque simulateur `banc-<k>` que tu as créé, et seulement ceux-là.

## 7. Le point de 3 lignes
```
Banc : <profils × passages, app vivante ou non>, missions réussies <x sur y>
Bloquant : <N points, ou aucun> · Questions pour Adem : <K>
Suite : <corriger les bloquants dans le lot, ou rien>
```
Tu n'écris jamais qu'un écran est « parfait » ou « validé » : le banc dit ce qui coince, pas ce qui marche.
