# Aquarium v2 (16 oct. 2026, après « les textures sont dégueulasses »)

Rendus : vue-1.png (vue d'ensemble), vue-2.png (gros plan), vue-3.png (à ras du gravier), 1080x1920, Cycles 64 échantillons.
Script : scene.py (Blender 4.5, `--vue 1|2|3 --res --samples --frame --out`, `--out x.blend` pour sauver la scène).

## Ce qui a changé par rapport aux variations V1-V5
- Poissons : fishkit2 (bords lisses par transparence, papier retiré, couleurs corrigées, cornée brillante).
- Volume : nouvelle carte d'épaisseur (outils/epaisseur_corps.py) : corps en ellipse ajusté sous les nageoires, nageoires fines. Supprime les plis pâles à la base des nageoires. Anciennes cartes : textures/propres-v1-epaisseur/.
- Décor réel CC0 : galets ganges_river_pebbles à l'échelle, rochers moussus, galets namaqualand, bois flotté, souche, plantes basses (Poly Haven) ; vallisnéries faites dans le script (aucune plante aquatique CC0).
- Eau : volume léger, surface vue de dessous, lampe à motif de caustiques, bulles.

## iPhone (RealityKit)
- Poissons : maillage grille 220 + lissage 1 en rendu ; pour l'iPhone, grille 80 sans lissage (~6 000 triangles par poisson), même texture 1400 px, matériau PBR simple (couleur, relief en normal map, rugosité), alpha découpé. Nage = vertex shader sinus (pas de clés de forme).
- Décor : modèles Poly Haven à décimer (rochers 57-63k triangles -> 2-3k chacun) ; sol = plan + normal map ; vallisnéries ~4 000 triangles.
- Volume et caustiques : brouillard par distance dans le shader, caustiques en texture animée projetée ; surface = quad avec reflet.

## Dans le dépôt (branche lot/aquarium)
- `App/Aquarium/Ressources/Poissons/<espèce>-couleur.png` (RGBA, silhouette par l'alpha), `-relief.png` (hauteur des écailles, à convertir en normal map), `-epaisseur.png` (16 bits : demi-épaisseur du corps pour bâtir le maillage), `-nageoires.png` (1 = nageoire : rugosité et translucidité). 13 espèces, 1400 px.
- `reports/aquarium-3d/` : fishkit2.py, scene.py, outils de nettoyage, rendus (`vue-*.png`) et fonds de widget sans poissons (`widget/fond-*.png`).
- Le silure (planche à queue courbée) a une carte d'épaisseur fausse : à refaire avant de l'utiliser.
- Les scripts lisent `/mnt/project-files/build/aquarium/3d/` (décor CC0 non commité, voir SOURCES-decor.md).
