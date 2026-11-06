# Entraîner et noter le modèle (sur un Mac)

Statut : écrit sans Mac, jamais exécuté. Rien ici n'est vérifié tant qu'un Mac ne l'a pas lancé.

1. Sur le PC : `python3 -I outils/reconnaissance/preparer_jeu.py --jeu <photos/jeu> --sortie <dossier hors dépôt>/jeu-prepare --copier` (ajouter `--repli` pour les 6 espèces de repli). Copier `jeu-prepare/` sur le Mac (clé USB, AirDrop) : jamais par git.
2. Sur le Mac (macOS 14+, Xcode, Python 3) : `bash outils/reconnaissance/mac/lancer.sh <jeu-prepare>`.
3. Résultat : `sortie/Poissons.mlmodel`, `journal-createml.csv`, `classes.json`, `confusion.csv` et le verdict de l'examen (code 0 = PASSE, 1 = ECHEC ; seuils dans `EXAMEN.md`).
4. Le modèle ne va dans l'app (`App/Prise/Modele/`) que si l'examen passe, 30 Mo au plus.
5. Comparer à l'IA d'Apple sur 20 photos (Mac en macOS 27, Apple Intelligence en français) :
   `python3 -I comparer.py choisir --manifeste <jeu-prepare>/manifeste.csv > liste.csv`, puis
   `swift apple_ia.swift <jeu-prepare>/test sortie/classes.json liste.csv sortie/journal-apple.csv`, puis
   `python3 -I comparer.py compare --createml sortie/journal-createml.csv --apple sortie/journal-apple.csv --liste liste.csv`.
6. `contextSize` affiché par `apple_ia.swift` : 4096 = iPhone 15 Pro/16 ; 8192 = valable pour iPhone 17 Pro seulement.
   Pour le test sur iPhone 15 Pro lui-même, les mêmes 20 photos de `liste.csv` sont à passer dans une app de test.
