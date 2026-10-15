# Create ML sur Mac : même photos, même jeu de test que le banc d'essai du cloud

But : comparer Create ML (l'« œil » d'Apple, modèle de moins de 1 Mo) au modèle du cloud, sur le même examen. Repère à battre : DINOv2-S + tête, 87 % en 1re proposition sur les photos de prises ; modèle cloud complet 93,5 % (voir `../README.md`).

1. Copier tout le dossier `banc-essai/` sur le Mac (il faut `mac/` et `manifestes/`).
2. Dans un dossier de travail vide (environ 4 Go libres) :
   ```
   python3 -m pip install torch opencv-python-headless pillow
   python3 /chemin/banc-essai/mac/prep_mac.py      # télécharge AFFiNe, GBIF, Unsplash ; recadre ; 30 à 90 min
   swift /chemin/banc-essai/mac/entrainer.swift   # entraîne et note ; 30 à 90 min
   ```
3. Coller la sortie de `entrainer.swift` dans le fil « Photos et modèle de reconnaissance ».

Règles : les photos ne vont jamais dans git ni dans le dossier partagé ; elles sont réencodées sans EXIF (pas de GPS). Le jeu de test suit la même règle qu'au cloud (un photographe sur quatre, par l'empreinte de son nom). Différence connue : ici, pas de photos Openverse ni « autre poisson » (filtrées par Fishial au cloud) ; c'est sans effet sur les photos de test.
