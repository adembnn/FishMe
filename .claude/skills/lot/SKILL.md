---
name: lot
description: "Rappelle le lot de la branche courante (fiche, dossiers permis, test qui bloque la fusion), puis démarre le travail avec la consigne de la fiche. Hors d'une branche de lot, propose scripts/lot.sh avec la liste des lots."
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(git branch*) Bash(git status*) Bash(python3 outils/atelier/lots.py*)
---

# /lot : quel est mon lot, et que construire ?

Branche courante : !`git branch --show-current`

Tu parles à une personne débutante. Phrases courtes, un terme technique expliqué entre parenthèses la première fois.

## 1. Trouver le lot
Lance `python3 outils/atelier/lots.py lot <la branche ci-dessus>`. Il affiche le code du lot (par exemple `L3`), ou rien si la branche n'est pas une branche de lot.

## 2. Si un code sort
1. Lance `python3 outils/atelier/lots.py json` et retrouve la ligne de ce lot. Lance `python3 outils/atelier/lots.py permis <code>` : les dossiers où ce lot a le droit d'écrire (les dossiers communs `docs/`, `reports/`, `CLAUDE.md` et `README.md` y sont aussi).
2. Lis `docs/fiches/<code>.md` en entier et la ligne du lot dans `docs/lots.md`.
3. Rappelle à la personne, en 6 lignes au plus :
   - le lot, son nom et qui le tient (A Adem, B Titouan ou S Sullyvan) ;
   - les étapes E qu'il sert (une étape est ce que voit le pêcheur, voir `docs/parcours-demo.md`) ;
   - les dossiers permis, et que tout le reste est interdit (le projet Xcode est à A, `Packages/Core` à B, sauf `Conseils/` à S) ;
   - le test qui bloque la fusion, la commande exacte ;
   - les lots dont il dépend, et s'ils sont déjà fusionnés (`git log --oneline` le montre).
4. Passe la case « Avant de commencer » de la fiche. Pour chaque case, dis si la preuve est là. Lance la commande de preuve seulement si elle ne change rien (`git log`, `ls`, `python3 outils/atelier/lots.py`). Une preuve que tu n'as pas vue est « non vérifié ». Si une case bloque le lot (le lot précédent n'est pas fusionné, par exemple), dis-le avant d'écrire du code.
5. Rends un plan de 4 lignes et attends le « ok » de la personne :
   1. le livrable, en une phrase ;
   2. la commande qui prouve que c'est fini (le test « fini » de la fiche) ;
   3. ce que tu ne feras pas ;
   4. ce que tu dois savoir d'elle avant de commencer.
6. Après le « ok », suis à la lettre la « Consigne à coller dans Claude Code » de la fiche (le bloc de texte), en parallèle (Adem, 15 oct. 14h42 : « on va tout paralléliser »). C'est un réflexe (Adem, 15 oct. 19h41 : « ça doit être un réflexe », « crame les tokens ») : tout travail qui se découpe part en plusieurs agents lancés dans le même message, jamais un par un, et le coût en jetons n'est jamais une raison d'aller moins vite ; les sous-agents restent en Sonnet effort moyen :
   1. Lis les documents qu'elle cite. Découpe le lot en morceaux indépendants : un fichier ou un sous-dossier chacun, avec son test, sans fichier partagé entre deux morceaux.
   2. Lance un agent `codeur` (Sonnet, effort moyen ; jamais d'Opus en sous-agent, Adem, 15 oct. 18h19) par morceau, tous dans le même message, pour qu'ils travaillent en même temps. Donne à chacun : son morceau, ses fichiers, le contrat qu'il appelle (`docs/architecture.md`), la page Apple à lire s'il y en a une. Confie à `petites-mains` (Haiku) le mécanique : textes, fichiers JSON d'après un modèle, renommages, recherches, lecture de la sortie de `scripts/verif.sh`.
   3. Garde pour toi (Opus, effort moyen au moins, `/effort high` pour C0, L1, R1 et le débogage) le découpage, les contrats, l'assemblage et la correction de ce qui casse.
   4. Quand les codeurs ont rendu : commite et pousse tout de suite ce qui est prêt, sans attendre la fin du lot (une limite de session peut tout arrêter). Puis compile une seule fois (un seul `xcodebuild` ou `swift test` à la fois), lance les tests, corrige, puis relance une vague de codeurs pour ce qui reste. Dans une session cloud (pas de Xcode), un lot d'écrans ne compile pas : commite, pousse la branche du lot et dis-le ; la session du Mac la reprend, compile et corrige. Le Mac A (8 Go de mémoire) ne compile qu'un lot à la fois.
   Travaille seulement dans les dossiers permis. Après chaque vague, une phrase pour dire ce que chaque fichier fait. Si la fiche donne une page Apple à lire (adresse avec `.md` à la fin), elle est lue avant d'écrire du code qui s'en sert : tes connaissances d'iOS 27 sont peut-être incomplètes, n'invente aucune fonction.
7. À la fin, lance la commande de fin de la fiche et colle sa sortie. Tu n'écris jamais « fini », « ça marche » ou « testé » sans cette sortie. Puis propose `/fusion`.
8. Si la personne est bloquée depuis 20 minutes, suis la partie « Si ça coince » de la fiche.

## 3. Si rien ne sort
La branche n'est pas une branche de lot (`main`, par exemple). On ne code pas ici.
1. Dis-le en une phrase.
2. Lance `python3 outils/atelier/lots.py json` et montre les lots en tableau court : code, nom, qui, étapes. Dis lesquels sont dans la version de jeudi et lesquels dans la version suivante (vendredi), d'après les deux tableaux de `docs/lots.md`.
3. Pose la question, avec ton choix par défaut :
   1. Qui es-tu ? a) A, Adem (Mac A : projet, carte, paywall, conditions, envoi) b) B, Titouan (Mac B et cloud : `Core`, données, prise, carte à collectionner) c) S, Sullyvan (données Hub'Eau, conseils, relectures)
   2. Quel lot prends-tu ? Propose le premier lot de sa lettre qui n'est pas encore fusionné.
4. Quand la personne a choisi, propose la commande `scripts/lot.sh <code>`. Elle crée la copie de travail du lot (un second dossier du même dépôt, sur la branche du lot). Lance-la seulement si la personne dit oui. Le script affiche le dossier créé : il faut y ouvrir une nouvelle session Claude Code, puis taper `/lot`.
