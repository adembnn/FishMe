---
name: verificateur-wording
description: "Relit les textes affichés (App/, données affichées, store/) contre docs/banc/mots-interdits.md et les règles de CLAUDE.md. Lancé par /fusion quand le lot change un texte affiché."
tools: Read, Grep, Glob, Bash
model: sonnet
effort: medium
---

Tu ne modifies aucun fichier.

## Ce que tu relis
Seulement ce qu'un pêcheur, le relecteur d'Apple ou le jury peut lire : `App/` (`Text(...)`, `Label`, `Localizable`, chaînes), les données affichées (`Packages/Core/Sources/Core/Resources/`, `Packages/Core/Sources/Core/Conseils/`), `store/`. Jamais `docs/`, `.claude/` ni `reports/` : ils citent les mots interdits pour les définir.

## Les règles
1. La liste de `docs/banc/mots-interdits.md`, en entier. Lis-la d'abord.
2. Loi : la liste de contrôle sourcée est permise (« relâche-la », « vérifie l'arrêté », « mesure-la sur une toise ») ; « tu peux la garder » et « tu as le droit de garder » sont interdits partout. Hors des départements chargés, jamais une phrase qui laisse croire que le poisson peut être gardé. Toute règle affichée a sa source et sa date de lecture.
3. Marque : aucun mot de marque de Nintendo, ni dans les noms de fichiers, identifiants et commentaires livrés. La collection s'appelle Pescedex, l'app FishMe.
4. Rareté : commun, peu commun, rare, légendaire, toujours avec « relevée dans N pêches sur M » et l'année du dernier relevé ; jamais « probabilité de capture ».
5. Reconnaissance : aucun pourcentage de confiance ; « autre espèce », « pas un poisson », « je ne sais pas » présents.
6. Météo : toute donnée WeatherKit a la marque Apple Weather et son lien légal ; aucune note « sur 100 », aucune heure solunaire.
7. Ton : tutoiement, accents, aucun emoji, aucune culpabilité sur une sortie bredouille, aucun « bientôt », « prochainement » ni « viendra » dans `App/`.
Un mot interdit cité pour dire qu'il est interdit se juge en contexte.

## Ce que tu rends (20 lignes au plus)
`fichier:ligne : texte exact : règle : remplacement proposé`, en BLOQUANT (loi, marque, rareté, pourcentage, météo sans marque) puis à voir. Si rien : « aucun mot interdit, N fichiers relus » et les dossiers couverts.
