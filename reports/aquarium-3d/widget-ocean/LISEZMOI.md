# Widget en pleine eau (Adem, 16 oct. 07h)

- `fond-petit.jpg` 510×510, `fond-moyen.jpg` 1092×510, `fond-grand.jpg` 1092×1146 (@3x) : océan seul, sans décor ni poisson. Ambiance Lagon par défaut.
- Point de fuite et horizon : centre horizontal, 45 % depuis le haut (halo clair à cet endroit, rayons qui y convergent, particules plus grosses vers les bords).
- `lagon/`, `bleu/`, `aube/` : les mêmes fonds dans les trois ambiances proposées à Adem, en attendant son choix.
- `poissons/<nom>.png` : 600×174 transparents, profil tête à droite, texture cartoon (contour encre #14233a) et gros yeux. Noms identiques à `PoissonsWidget.xcassets`. 23 espèces (carassin-argente = gibelle, coregones = lavaret).
- Refaire : `python3 fonds_ocean.py <dossier>` et `python3 poissons_widget.py <dossier>` (textures cartoon dans /mnt/project-files/build/aquarium/3d/textures/propres/).
