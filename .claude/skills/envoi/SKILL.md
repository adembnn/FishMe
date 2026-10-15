---
name: envoi
description: "Envoie le build sur TestFlight, depuis main, sur Mac : vérifie que main est à jour et vert, lance revue-finale (Sonnet, effort moyen), s'arrête sur tout bloquant Apple, puis lance scripts/envoi.sh. Ne soumet jamais à la relecture d'Apple : un humain clique dans App Store Connect."
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(git branch*) Bash(git status*) Bash(git fetch origin*) Bash(git rev-parse*) Bash(git log*) Bash(python3 outils/atelier/lots.py*) Bash(scripts/verif.sh*) Bash(uname*)
---

# /envoi : du main vert vers TestFlight

Système : !`uname -s`
Branche courante : !`git branch --show-current`

Tu parles à une personne débutante. Phrases courtes, un terme technique expliqué entre parenthèses la première fois. TestFlight est l'outil d'Apple pour essayer une version avant publication. Envoyer sur TestFlight garde le build chez nous : la soumission à la relecture d'Apple est une étape à part.

## Ce que tu ne fais jamais
Tu ne soumets rien à la relecture d'Apple. Ni bouton, ni `fastlane deliver` avec soumission, ni appel à l'API d'App Store Connect pour « ajouter pour examen ». C'est un humain qui clique dans App Store Connect. Tu ne contournes aucun garde-fou (`ATELIER_LIBRE`, `--no-verify`).

## 1. Sur un Mac
Si le système ci-dessus n'est pas `Darwin`, arrête-toi : l'archive de l'app ne se fait que sur Mac. Dis qui peut le faire (A, qui a le compte et l'iPhone de test).

## 2. main est à jour
1. La branche courante doit être `main`. Sinon arrête-toi : « l'envoi part de main ».
2. Lance `git fetch origin main`, puis `git status -sb` et `git rev-parse HEAD origin/main`. Il faut : aucun changement non enregistré, et les deux empreintes identiques. Si `main` est en retard sur `origin/main`, propose `git pull --ff-only`. Si `main` a des commits que `origin/main` n'a pas, arrête-toi et explique : la personne décide.

## 3. main est vert
Lance `scripts/verif.sh` (vérification complète). Montre ses lignes ✓ / ✗ / ·.
- Rouge : arrête-toi, `/fusion` ou `/lot` pour réparer.
- Une ligne « · sauté » : sur un Mac, rien ne doit être sauté. Arrête-toi et dis quelle partie n'a pas tourné.

## 4. Revue finale
Fais un appel à l'outil Agent (il s'appelait Task dans les anciennes versions) : `subagent_type` est `revue-finale`, `model` est `sonnet` (effort moyen, écrit dans l'agent ; Adem, 15 oct. 18h19 : jamais d'Opus en sous-agent). Prompt :

```
Relis main (commit <court>) avant l'envoi à Apple, contre docs/app-store.md et docs/parcours-demo.md. Réponds dans le format de ton fichier.
```

Montre sa réponse telle quelle. Puis :
- Un point [APPLE] : arrête-toi. N'envoie rien. Dis quel lot corrige quoi (le tableau des refus de `docs/app-store.md` donne le lot) et propose `/lot`.
- Un point [DÉMO] : arrête-toi et pose la question à la personne, avec ta recommandation et un choix par défaut (corriger d'abord, ou envoyer quand même). C'est elle qui tranche.
- Seulement des points [reste] : continue, et garde-les pour le point final. Le point « À confirmer par un humain » est relu à voix haute à la personne : ce sont des choses que le dépôt ne peut pas prouver.

## 5. Envoyer
1. Écris en une ligne ce qui va partir : le dernier commit (`git log -1 --oneline`) et la branche `main`. Demande « on envoie ? » et attends un « oui » clair.
2. Lance `scripts/envoi.sh`. Montre sa sortie en entier.
3. En cas d'échec (signature, compte, réseau), recopie l'erreur et arrête-toi. Ne relance pas en boucle.

## 6. Après l'envoi
Rappelle ce qui reste, à faire par une personne dans App Store Connect : attendre que le build soit « prêt à tester », le choisir pour la version, remplir les notes pour le relecteur, puis cliquer sur « Ajouter pour examen » (la soumission à la relecture d'Apple). MWM demande ensuite la relecture accélérée.
Termine par un point de 3 lignes :

```
Envoyé : <commit, build envoyé sur TestFlight, ou « non envoyé » avec la raison>
Vérification : <verif.sh, verdict de revue-finale, sortie d'envoi.sh>
Suite : <ce qu'un humain fait dans App Store Connect, et qui>
```

Tu n'écris jamais « envoyé », « fini » ou « ça marche » sans la sortie de `scripts/envoi.sh`.
