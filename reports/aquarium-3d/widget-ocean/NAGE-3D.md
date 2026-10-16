# Nage en 3D dans l'océan (Adem, 16 oct. 07h48 : « aller vers le fond et toutes les directions »)

Modèle de référence : `apercu-nage-3d.html` (fonction `pas`). À porter tel quel dans le widget ou l'aquarium.

- Monde : x gauche/droite, y haut/bas, z profondeur de ZP = 1,1 (tout près) à ZF = 7 (au fond, dans la brume).
- Projection sur le point de fuite (cx, cy) = (50 % W, 45 % H), focale F = 0,62 W :
  sx = cx + x / z · F ; sy = cy + y / z · F ; largeur à l'écran = L · 1,35 · F / z.
- Chaque poisson vise un but au hasard : 25 % des buts tout au fond (z entre ZF-2 et ZF), 25 % hors champ
  (|x/z| jusqu'à 1,4) pour sortir par un bord et revenir ailleurs. Nouveau but à moins de 0,4.
- Cap dans le plan x/z (virage max 0,9 rad/s), tangage limité à ±0,5 rad ; vitesse propre à l'espèce.
- Dessin : image retournée si le poisson va vers la gauche (cos cap < 0) ; raccourci horizontal
  max(0,28, |cos cap|) quand il plonge vers le fond ou remonte vers nous ; légère rotation selon le tangage.
- Brume : b = (z - ZP)/(ZP..ZF) ; saturation 1 - 0,55 b, luminosité 1 + 0,25 b, flou 1,6 b px, opacité 1 - 0,45 b ;
  ordre d'affichage par z décroissant.
