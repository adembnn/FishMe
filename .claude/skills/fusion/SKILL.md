---
name: fusion
description: "Fusionne le lot courant dans main : lance scripts/verif.sh, fait relire le diff par relecteur-apple, relecteur-code (et relecteur-regles si le lot touche Core, les données ou un verdict), corrige les points bloquants, relance verif, puis lance scripts/fusionner.sh."
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(git branch*) Bash(git status*) Bash(git fetch origin*) Bash(git diff*) Bash(git log*) Bash(git add*) Bash(git commit*) Bash(python3 outils/atelier/lots.py*) Bash(scripts/verif.sh*) Bash(scripts/fusionner.sh*)
---

# /fusion : relire, corriger, fusionner

Branche courante : !`git branch --show-current`

Tu parles à une personne débutante. Phrases courtes, un terme technique expliqué entre parenthèses la première fois. Tu ne contournes jamais un garde-fou : ni `ATELIER_LIBRE`, ni `--no-verify`, ni un `git push` direct vers `main`.

## 0. Est-ce une branche de lot ?
Lance `python3 outils/atelier/lots.py lot <la branche ci-dessus>`. S'il n'affiche rien, arrête-toi : on ne fusionne que depuis une branche `lot/<nom>`. Dis-le et propose `/lot`.
Sinon retiens le code du lot et ses dossiers (`python3 outils/atelier/lots.py permis <code>`).

## 1. Tout enregistrer
Lance `git status --short`. S'il reste des changements non enregistrés, propose le commit (message en français, une ligne, sans ligne « Co-Authored-By »), un commit par lot terminé, et attends le « ok ».

## 2. Vérifier
Lance `scripts/verif.sh` (sans option : la vérification complète). Montre ses lignes ✓ / ✗ / · telles quelles.
- Rouge (une ligne ✗, ou sortie différente de 0) : ne lance aucun relecteur. Va au point 5 pour corriger, puis reviens ici.
- Une ligne « · sauté » : une partie n'a pas tourné (par exemple les tests de l'app, faute de Mac). Dis-le en mots simples. Si la partie sautée est celle que ce lot change, arrête-toi : « non vérifié » veut dire « non fusionné », et dis qui peut la lancer (une personne avec un Mac).

## 3. Choisir les relecteurs
Lance `git fetch origin main`. Sans réseau, continue avec la copie locale de `origin/main` et dis-le. Puis `git diff --name-only origin/main...HEAD`.
- Toujours : `relecteur-apple` et `relecteur-code`.
- En plus `relecteur-regles`, seulement si le lot touche `Packages/Core/`, des données (`Resources/`, `outils/hubeau/`, `outils/verifier_donnees.py`, un fichier `.json`) ou un verdict (cherche `verdict`, `garder`, `rarete`, `rareté` ou `OFB` dans `git diff origin/main...HEAD`). En plus `verificateur-wording`, si le lot change un texte affiché (un fichier de `App/` ou de `store/`, ou des données affichées de `Resources/` ou `Conseils/`).
- En plus `revue-ux-2taps`, si le lot change un fichier de `App/`.
- `coupeur` et `testeur-identification` ne se lancent jamais ici : à la main seulement.
- Dis lesquels tu lances et pourquoi.

## 4. Lancer les relecteurs en parallèle
Dans un seul message, fais un appel par relecteur à l'outil Agent (il s'appelait Task dans les anciennes versions) : `subagent_type` est le nom du relecteur, `model` est `sonnet` (c'est aussi le modèle écrit dans le fichier de l'agent). Prompt de chacun :

```
Relis le lot <code> (branche <branche>). Le diff est : git diff origin/main...HEAD. Fichiers changés : <liste>. Réponds dans le format de ton fichier.
```

Attends les réponses. Montre à la personne, pour chaque relecteur, son verdict et ses points tels qu'ils sont rendus, sans les reformuler.

## 4 bis. Le banc d'essai
Si le lot change un fichier de `App/` (un écran), lance la procédure de `/banc` pour ce lot : lis `.claude/skills/banc/SKILL.md` et suis-la. Ses points BLOQUANT se traitent au point 5 comme ceux des relecteurs. Ses questions pour Adem lui sont posées telles quelles et ne bloquent pas la fusion. Ce que le banc peut bloquer reste à confirmer par Adem (question du 15 oct.) : par défaut, seulement le mesurable.

## 5. Corriger les points bloquants
- Tous les verdicts ✓ : passe au point 6.
- Sinon, liste les points [BLOQUANT] de tous les relecteurs, du plus grave au moins grave. Corrige-les un par un, seulement dans les dossiers permis du lot. Explique chaque correction en une phrase.
- Tu ne corriges pas seul : un fichier hors du lot (le projet Xcode, une clé d'autorisation, `App/RootView.swift` sont à A ; `Packages/Core` est à B, sauf `Conseils/` à S), ou un choix de design, de produit, de périmètre, de fournisseur ou d'argent. Dis qui doit le faire ou pose la question à la personne, avec ta recommandation et un choix par défaut.
- Les points [à voir] ne bloquent pas : ne les corrige pas sans demande. Compte-les pour le point final.
- Après les corrections : relance `scripts/verif.sh`, puis relance seulement les relecteurs qui avaient des points bloquants. Deux tours au plus. Au troisième, arrête-toi, montre ce qui reste et demande quoi faire.
- Enregistre les corrections dans un commit (en français, sans ligne « Co-Authored-By »).

## 6. Fusionner
Lance `scripts/fusionner.sh` depuis la branche du lot. Si le script répond qu'il attend le nom de la branche, relance `scripts/fusionner.sh <la branche>`. Montre sa sortie. S'il refuse (un fichier hors du lot, un test rouge), lis son message, corrige la cause, relance : n'essaie jamais d'entrer dans `main` par un autre chemin.

## 7. Le point de 3 lignes
Termine par exactement ces trois lignes, puis, dessous, la sortie de vérification collée telle quelle (les lignes ✓ / ✗ / ·) :

```
Fusionné : <lot, nombre de commits, relecteurs passés et leur verdict, nombre de points [à voir] restants>
Vérification : <la commande lancée et son résultat, ou « non vérifié » avec la raison>
Suite : <le prochain lot ou la prochaine action, et qui la fait>
```

Tu n'écris jamais « fini », « ça marche » ou « testé » sans la sortie de la commande de vérification.
