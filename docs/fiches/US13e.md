# US13e Anglais : petits dossiers (Abonnement, Mouvement, Mesure, Envies, Records, Style, Ma fédération, Où chercher, Carte de pêche, Veille)
B (Titouan) · branche `lot/anglais-e` (créée par `scripts/lot.sh US13e`) · étapes : hors parcours · travail d'une session seule : 2 à 3 h · lancé le 7 nov. au soir (« finir l'app », Titouan)

## But
Rendre l'anglais complet pour ces dossiers : chaque texte affiché passe par une table de chaînes propre au lot (`AnglaisE.xcstrings`, sourceLanguage fr, clé = le français, valeur en = l'anglais), en suivant exactement le modèle de `App/ReglesUS/TextesReglesUS.swift` (langue prise dans le .lproj de la région, pas du téléphone ; `Text(…, tableName:)` pour les littéraux SwiftUI). Un seul `Localizable.xcstrings` par cible est permis : ne crée pas d'autre fichier de ce nom. Vocabulaire de pêche : `outils/us/i18n/glossaire.tsv`. Ne change ni le français ni le comportement.
Décisions du 7 nov. (`CLAUDE.md`) : voir la colonne « Dépend de » de `docs/lots.md`.

## Avant de commencer
- [ ] `CLAUDE.md` (« Décisions du 7 nov. ») et `docs/lots.md` (ligne US13e) lus.
- [ ] Le code existant du dossier du lot lu avant d'écrire (rien n'est réécrit sans raison).
- [ ] `reports/us/synthese.md` et le rapport de `reports/us/` qui concerne ce lot lus.

## Dossiers
- Permis : `App/Abonnement/`, `App/Mouvement/`, `App/Mesure/`, `App/Envies/`, `App/Records/`, `App/Style/`, `App/MaFederation/`, `App/OuChercher/`, `App/CartePeche/`, `App/Veille/`.
- Interdit : tout le reste du dépôt, y compris les dossiers des autres lots (W1, US10 à US14, D6, D7, L25) ; `App/RootView.swift` est à L25 : une ligne à y ajouter se demande à la session principale.

## Contrat
- Aucun texte affiché ne contient « autorisé », « allowed », « legal », « tu peux la garder » ni « you can keep it » ; verdicts US : « interdit », « à vérifier », « donnée absente », avec lien de l'agence, source et date.
- La France ne change pas de comportement.
- Aucune donnée lourde ni photo dans git hors des fichiers embarqués prévus par le lot ; la source et la licence de chaque fichier sont écrites.
- Un test par morceau ; la suite du lot est verte avant de dire « fini ».

## Consigne à coller dans Claude Code
```text
Lis CLAUDE.md (« Décisions du 7 nov. »), docs/lots.md (ligne US13e), docs/atelier.md et docs/fiches/US13e.md.
Travaille seulement dans : App/Abonnement/, App/Mouvement/, App/Mesure/, App/Envies/, App/Records/, App/Style/, App/MaFederation/, App/OuChercher/, App/CartePeche/, App/Veille/.
Construis par petits morceaux avec un test par morceau, commite sur la branche lot/anglais-e, pousse-la.
À la fin, lance le test « fini » de la fiche et colle la sortie complète.
```

## Test « fini »
Commande de fusion : `scripts/fusionner.sh lot/anglais-e`. Test qui bloque : `xcodebuild test … -only-testing:BuildChallengeTests/AnglaisETests` vert (suite écrite par ce lot) : chaque texte affiché du dossier a une clé dans la table du lot avec une valeur anglaise ; `grep -rniE "autoris|allowed|legal|tu peux la garder|you can keep"` sur les chaînes anglaises ne trouve rien ; en région France rien ne change
Puis `git diff --name-only fishme-tout` ne montre que les dossiers permis.

## Pièges
- Toucher un dossier d'un autre lot. Parade : le crochet de git refuse le commit.
- Écrire « autorisé » ou « allowed » par réflexe. Parade : le `grep` du test.
- Compiler en même temps que les autres lots : un seul build à la fois (`mkdir /tmp/fishme-build.lock`, le retirer ensuite).

## Si ça coince
- Après 20 min sans avancer : écrire 3 lignes de blocage dans le message de fin et livrer ce qui marche.
