# L'atelier

Le plan (`lots.md`) dit quoi construire. L'atelier fait que chaque agent construit juste sans qu'on le surveille : il connaît son poste, ne peut pas déborder sur celui du voisin, ne peut pas dire « fini » sur un test rouge, et passe devant des relecteurs avant de rejoindre la version commune (`main`).

## Démarrer un lot
```bash
scripts/lot.sh L3          # crée ta copie de travail du lot L3 (un second dossier du même dépôt, sur la branche lot/prise)
cd <le dossier affiché>    # lot.sh affiche la commande exacte
claude                     # puis tape /lot
```
`/lot` rappelle ta fiche, tes dossiers et ton test, propose un plan de 4 lignes et attend ton « ok ».

## Ce qui se passe tout seul
| Moment | Ce que fait l'atelier | Où |
|---|---|---|
| Ouverture de Claude Code | la fiche du lot est donnée à l'agent avant ton premier message | `.claude/hooks/contexte.py` |
| Avant chaque écriture | refus hors des dossiers du lot, avec le nom du lot propriétaire ; `.env` et réglages du projet Xcode toujours refusés | `.claude/hooks/garde-lot.py` |
| Après chaque fichier Swift | mise en forme automatique (sur Mac) | `.claude/hooks/formate.sh` |
| Quand l'agent veut s'arrêter | `scripts/verif.sh --rapide` ; rouge = il continue à corriger (3 fois au plus), sauf s'il te pose une question ou commence par « ROUGE : » | `.claude/hooks/preuve.py` |
| À chaque commit, même sans Claude | refus hors du lot, sur `main`, de `.env`, des données fabriquées, de « Poké » (marque de Nintendo) | `.githooks/pre-commit` |
| Envoi vers `main` | seulement par `scripts/fusionner.sh`, qui relance toute la vérification | `.githooks/pre-push` |
| Sur GitHub | la vérification Linux tourne à chaque envoi | `.github/workflows/verif.yml` |

Toutes les règles viennent de `docs/lots.md` (colonnes « Branche » et « Dossier ») : si un garde-fou se trompe, on corrige le tableau, pas le script.

## Les commandes dans Claude Code
- `/lot` : où j'en suis, et on démarre.
- `/fusion` : vérification, trois relecteurs en parallèle, corrections, puis fusion dans `main` et un point de 3 lignes.
- `/ecran` : sur Mac, l'agent lance l'app dans le simulateur, parcourt les étapes du lot et prend une capture par étape (`reports/ecrans/`).
- `/envoi` : revue finale, puis archive et envoi sur TestFlight. Le clic « envoyer à Apple » reste humain.
- `/point` : point d'étape en 3 lignes.

## Les relecteurs
| Relecteur | Modèle | Ce qu'il regarde |
|---|---|---|
| `relecteur-apple` | Sonnet | refus probables d'Apple (R1 à R9 de `app-store.md`), vie privée, consentement, paywall |
| `relecteur-code` | Sonnet | Swift 6 et SwiftUI, frontières entre dossiers, tests |
| `relecteur-regles` | Sonnet | verdicts de pêche, rareté, sources, chiffres OFB |
| `testeur-ecran` | Sonnet | l'app à l'écran, étape par étape (Mac) |
| `revue-finale` | Opus | tout `main` avant l'envoi à Apple |
Ils ne corrigent rien eux-mêmes : ils rendent au plus 10 points `fichier:ligne`, bloquants d'abord.

## Sans Claude Code
Les mêmes règles tournent dans git : `scripts/lot.sh <code>`, puis tes commits comme d'habitude, `scripts/verif.sh` pour voir où tu en es, `scripts/fusionner.sh` pour rejoindre `main`.

## Urgences
- Un garde-fou bloque à tort : relance `ATELIER_LIBRE=1 claude`. Chaque écriture est alors signalée ; corrige ensuite `docs/lots.md`.
- Les crochets de git se contournent avec `--no-verify` : réservé aux humains, refusé aux agents.

## Vérifier l'atelier
- `python3 outils/atelier/essai.py` : provoque chaque erreur et vérifie qu'elle est bloquée (Linux ou Mac, une vingtaine de secondes).
- `scripts/docteur.sh` : contrôle ta machine, une ligne verte ou rouge par point, avec la commande de réparation.
- Mac : la page `atelier-mac.md`, à suivre une fois sur chaque Mac avant jeudi.
- Cloud (sans Mac) : `scripts/cloud-pret.sh` démarre Docker et récupère Swift 6.4 ; la session le lance seule au démarrage.
