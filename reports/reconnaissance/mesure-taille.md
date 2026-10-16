# Mesure de la taille en réalité augmentée (demande d'Adem, 16 oct. 2026, 2h21)

Adem : « au moins une fourchette d'estimation avec la première mesurée en réalité augmentée avec l'appareil photo ».

## Ce que l'écran fait
1. Après la photo, bouton « Mesurer » : vue ARKit (`ARSCNView`/`RealityKit`), le pêcheur pose un point sur le museau puis un sur le bout de la queue, poisson à plat (sol, toise, tapis).
2. Avec LiDAR (iPhone Pro) : raycast sur le maillage de scène (`ARWorldTrackingConfiguration.sceneReconstruction = .mesh`). Sans LiDAR : raycast sur le plan horizontal détecté (`planeDetection = .horizontal`), moins précis.
3. Distance 3D entre les deux points = longueur totale L.
4. **Fourchette affichée, jamais un chiffre sec** : « 52 à 56 cm ». Marge par défaut à valider sur de vrais poissons : ±2 cm (ou ±4 %) avec LiDAR, ±4 cm (ou ±8 %) sans LiDAR, la plus grande des deux.
5. Le pêcheur peut corriger à la main (toise) ; la carte note la méthode : « mesurée (AR) » ou « saisie ».
6. **Poids estimé** = a·L^b de l'espèce confirmée (table `poids-longueur/poids_longueur.csv`, en cours, avec sources), calculé aux deux bornes : « ≈ 1,6 à 2,0 kg (estimé) ». Jamais présenté comme une pesée.
7. Garde-fou : si L sort de la plage plausible de l'espèce (95e centile des prises connues, dans la même table), demander de remesurer.

## Ce qui reste à vérifier
- La marge réelle : mesurer 10 objets de longueur connue (30 à 100 cm) avec et sans LiDAR et ajuster la fourchette.
- La taille officielle pour la règle de capture se mesure du museau au bout de la queue (longueur totale) : c'est bien L.
- Aucune donnée de position n'est gardée par ARKit dans la prise (pas de coin de pêche qui quitte l'iPhone).
