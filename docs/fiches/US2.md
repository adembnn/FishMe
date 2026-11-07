# US2 Niveau 1 : les 50 États
B (Titouan) · branche `lot/us-etats` (créée par `scripts/lot.sh US2`) · étapes : hors parcours · travail d'une session seule : 1 à 2 j · lancé le 7 nov. (décision 8)

## But
Fabriquer le niveau 1 de la couverture américaine : un enregistrement par État (permis requis, prix, lien officiel de l'agence), tous au verdict « à vérifier ». C'est le socle sur lequel US3 ajoute les règles par espèce.
Décisions du 7 nov. (`CLAUDE.md`) : 2 (niveau 1 : 50 États, permis, prix, lien officiel, verdict « à vérifier ») et 3 (lien agence, source et date toujours là).

## Avant de commencer
- [ ] `reports/us/synthese.md` et le rapport sur la réglementation par État de `reports/us/` lus.
- [ ] `outils/regles/consensus.py` et `outils/verifier_donnees.py` lus : la façon de vérifier un fichier de données.
- [ ] `docs/donnees.md` lu : tu y ajouteras la ligne du fichier avec sa source et sa licence (fichier commun).

## Dossiers
- Permis : `outils/us/etats/`.
- Interdit : `Packages/Core` (US1), `outils/us/regles/` (US3), `App/`, `scripts/`. Tout le reste du dépôt, y compris les dossiers des autres lots du 7 nov. (W1, US1 à US9, C1, F2, M2, H3).

## Contrat
- `etats.json` (fabriqué, publié en pièce jointe de release privée comme les autres, jamais dans git) : 50 États, code postal à 2 lettres, nom, agence, `lienAgence` https, `permisRequis`, `prix` (ou absent), `source`, `date`.
- Verdict du niveau 1 : « à vérifier » partout ; aucun mot « autorisé », « legal », « allowed ».
- Un script `verifier_etats.py` sort 1 s'il manque un État, un lien non https ou une date absente ; ses tests (`test_*.py`, stdlib seulement) sont dans le dossier.
- Aucun prix inventé : prix inconnu = champ absent.

## Consigne à coller dans Claude Code
```text
Je suis débutant. Lis CLAUDE.md (« Décisions du 7 nov. »), docs/lots.md (ligne US2), docs/atelier.md et docs/fiches/US2.md.
Travaille seulement dans : outils/us/etats/. Fais un plan de 4 lignes et attends mon « ok ».
Construis par petits morceaux, un agent par morceau indépendant, avec un test par morceau. Une phrase après chaque fichier pour m'expliquer.
À la fin, lance `cd outils/us/etats && python3 -I -m unittest discover -s . -p 'test_*.py'` et colle la sortie complète.
```

## Test « fini »
Commande de fusion : `scripts/fusionner.sh lot/us-etats`. Test qui bloque : `cd outils/us/etats && python3 -I -m unittest discover -s . -p 'test_*.py'` vert : 50 États exactement, chacun avec permis requis (oui ou non, ou « à vérifier »), prix si connu, lien https de l'agence officielle, source, date, verdict « à vérifier » et rien d'autre.
Puis `git diff --name-only fishme-tout` ne montre que les dossiers permis.

## Pièges
- Un lien qui change de domaine ou meurt. Parade : le test vérifie la forme (https, domaine en `.gov`, `.us` ou liste blanche écrite) et la date de contrôle.
- Remplir un prix de mémoire. Parade : « absent » plutôt qu'un chiffre non sourcé.
- Compter DC ou les territoires comme États. Parade : 50 exactement, test sur la liste.

## Si ça coince
- Après 20 min : message de 3 lignes à Titouan (l'État dont la source manque) ; en retard, publie les États faits et marque les autres « donnée absente ».
