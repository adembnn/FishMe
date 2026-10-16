# Nage des poissons FishMe (16 oct. 2026)

Un seul mouvement pour l'aquarium, le widget et la carte. Code de référence : `nage.js` (JavaScript, sans dépendance), utilisé par la page temps réel `index.html` (three.js) publiée en artefact.

## Repère
Poisson de longueur 1, tête vers +X, dos vers +Y, flancs vers ±Z (repère glTF ; dans Blender : flancs ±Y, dos +Z). Mise à l'échelle par l'objet (longueur en mètres).

## 1. Ondulation du corps (shader de sommets)
`t = clamp(0.5 - x, 0, 1)` (0 à la tête, 1 au bout de la queue)
`env = 0.03 + 0.97 * t^2.2`
`z += A * (env * sin(phase - 2π t / 1.05) - 0.12 * sin(phase) * (1 - t))`
`z += courbe * t² * 0.25` (le corps se plie dans les virages)
A = amplitude de l'espèce (0.05 à 0.08 de la longueur), réduite à 55 % au repos.

## 2. Battement
`phase += 2π * f * dt`, `f = 0.9 + 2.2 * vitesse / longueur` (battements par seconde).

## 3. Trajectoire
But tiré au hasard dans le bac (bande de hauteur propre à l'espèce : `bas`/`haut`), virage limité à `virage` rad/s, assiette limitée à ±0.22 rad, vitesse qui rejoint en douceur `croisiere` (longueurs/s). Au but : repos `calme` secondes (le poisson tient son poste en ondulant), puis nouveau but. Banc : les suiveurs visent le meneur plus un écart fixe. Fuite : vitesse x3 pendant 0,6 s. Nourrir : le poisson le plus proche vise la granule, la mange quand sa bouche (position + demi-longueur devant) passe à moins de 12 % de sa longueur.

## 4. Espèces
Voir `ESPECES` dans `nage.js` (croisière, virage, calme, amplitude, bande de hauteur).

## Pour Swift (widget, RealityKit)
- Trajectoire : porter `Nageur.pas(dt)` tel quel (aucune dépendance) ; le widget peut l'évaluer à des instants fixes pour ses images.
- Ondulation : RealityKit `CustomMaterial` (geometry modifier Metal) avec la même formule ; pour des images 2D du widget, déformer la planche le long de X avec le même décalage vertical.

## Fichiers
- `poissons/<espèce>.glb` : 7 000 à 11 500 triangles, texture couleur et normales 1024 px en WebP (exportés par `export_poissons.py`).
- `decor.glb` : sol, roches, bois, plantes, herbiers, 61 000 triangles (`export_decor.py`, à partir de `../scene.py`).
- Textures sources : `App/Aquarium/Ressources/Poissons/` (couleur, normale, relief, épaisseur, nageoires).
