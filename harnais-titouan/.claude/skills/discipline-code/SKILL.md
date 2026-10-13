---
name: discipline-code
description: Conventions Git, commits Lxx et vérification pour Bredouille. Se déclenche dès qu'un commit, une branche, un message de commit ou la clôture d'un lot doit être produit.
---

# Discipline de code (Bredouille)

## Commits et branches
- Un commit = un changement cohérent, dans le périmètre d'un seul lot. Message : `Lxx: résumé court` (ex. `L4: moteur de rareté, seuils en config`). Hors lot : `fix:`, `docs:`, `chore:`. Les commits automatiques du hook portent `auto:`.
- Trunk-based : `main` doit rester vert ; branches courtes `lot/L17-holo`, PR petites [I, plan `peche/04` §1.8].
- **Fix forward** : un build cassé se corrige dans les 15 minutes par celui qui l'a cassé.
- Jamais de `git push --force`, `reset --hard`, `clean -f` sans demande explicite de l'humain.
- Jamais de secret, clé, `.env`, certificat, profil de provisionnement dans un commit.
- Titouan ne génère ni ne modifie `project.pbxproj` / `*.xcodeproj` (ignoré par Git ; seul `project.yml` compte, propriété d'Adem).

## Avant de déclarer un lot terminé
1. `python Tools/check/check_all.py` passe (voir `.claude/verify.json`).
2. Le diff reste dans le périmètre de fichiers du lot.
3. Compte rendu au format : « Vérifié : … (commande, résultat). Non vérifié, à compiler sur Mac : … ».

## Bon / mauvais
- Bon : `L8: questionnaire d'identification assisté + tests purs`, 3 fichiers dans `PecheCore/`.
- Mauvais : `update stuff` touchant `PecheCore`, `project.yml` et un workflow CI.
- Mauvais : « Compile » écrit par Titouan sans Mac. Bon : « Écrit, non compilé ; CI/Adem à confirmer ».
