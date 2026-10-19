# Suivi des tâches : lots, pas les issues GitHub

Le suivi de ce dépôt reste celui de `docs/` : `docs/lots.md` (qui fait quoi, quelle branche, quel test), une fiche par lot dans `docs/fiches/`, et `docs/parcours-demo.md` comme critère commun. Les skills qui « publient dans le suivi » ou « lisent un ticket » écrivent et lisent ces fichiers, pas des issues GitHub.

- **Créer une tâche** : ajouter une fiche dans `docs/fiches/` (ou une ligne dans `docs/lots.md` si elle touche le calendrier), puis lancer `python3 docs/verifier.py` : il doit afficher « 0 trou ».
- **Lire une tâche** : ouvrir la fiche du lot (`docs/fiches/<code>.md`).
- **Décider** : noter la décision datée dans `CLAUDE.md` (section « Le produit » ou « La construction »), comme déjà fait.
- **Fusion** : `scripts/fusionner.sh` uniquement, qui lance `scripts/verif.sh`.
- **Code** : une branche `lot/<nom>` par lot, une copie de travail par `scripts/lot.sh <code>`.

GitHub sert à héberger le dépôt, la CI (`.github/workflows/verif.yml`) et les pull requests. Il ne sert pas de suivi des tâches.
