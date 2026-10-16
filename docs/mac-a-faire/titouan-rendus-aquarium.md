# Rendus 3D de l'aquarium : la moitié de Titouan

Adem (16 oct. 08h53) : « pour les animations 3D de l'aquarium et widgets, n'hésite pas à envoyer des lots à Titouan », « il faut paralléliser ».
Ce document suffit seul : tout ce qu'il faut est dans ce dépôt, branche `lot/aquarium`.

## À refaire (16 oct. 09h50 UTC)
Un deuxième œil apparaît sur le haut de la tête (relecture du dos) : tanche, chevesne, rotengle, brème, ablette, barbeau, gardon, perche, sandre, truite-fario. Correction : `PART_DOS=0.1` dans la commande (déjà mis ci-dessous). Qui refait quoi : le cloud refait gardon, perche, sandre, truite-fario (et fait le carassin) ; le fil de renfort refait tanche, chevesne, rotengle ; un autre fil cloud refait brème, ablette, barbeau. Si Titouan est disponible, il peut reprendre parmi ses 6 celles qui n'ont pas encore été repoussées avec la correction (regarder `git log origin/lot/aquarium` : un commit « … PART_DOS=0.1 » ou « deuxième œil » après 09h50 UTC veut dire déjà refaite).

## Le partage
- **Titouan** : tanche, chevesne, rotengle, breme-commune, ablette, barbeau, carassin.
- **Le cloud** (déjà en cours) : gardon, perche, sandre, truite-fario, carpe-commune, black-bass, silure. Le brochet est fait.

## Ce qu'il faut
- Blender 4.5 (gratuit, blender.org), utilisé sans écran (`-b`).
- Python 3 avec Pillow (`python3 -m pip install pillow`) pour le recadrage.
- Le dépôt sur la branche `lot/aquarium` (`git fetch origin lot/aquarium && git checkout lot/aquarium`).

Le kit est dans `reports/aquarium-3d/kit-rendu/` : `sprites.py` (le rendu), `fishkit2.py` (le poisson en volume), `recadrer_commun.py`, et `textures/` (les 7 espèces de Titouan).

## La commande (une espèce à la fois, depuis la racine du dépôt)
macOS (Blender dans Applications) :
```sh
K=reports/aquarium-3d/kit-rendu
for e in tanche chevesne rotengle breme-commune ablette barbeau carassin; do
  PART_DOS=0.1 IMAGES=16 /Applications/Blender.app/Contents/MacOS/Blender -b --python $K/sprites.py -- $K/textures rendus-brut/$e $e:$e > rendus-brut/$e.log 2>&1
  python3 $K/recadrer_commun.py rendus-brut/$e reports/aquarium-3d/widget-ocean/poissons-3d/$e
done
```
Windows (PowerShell) : même boucle, avec `$env:IMAGES="16"; $env:PART_DOS="0.1"` et `& "C:\Program Files\Blender Foundation\Blender 4.5\blender.exe" -b --python ...`.
`mkdir rendus-brut` d'abord ; ce dossier ne se commite jamais (images brutes).

Réglages par défaut du script, à ne pas changer : 13 angles (`nage`, lacet ±15 à ±90 tous les 15°), 16 images par battement, épaisseur ×1,25, battement 0,16, caméra à 20°, fond transparent. Compter environ 10 minutes par espèce sur 4 cœurs.

## Ce qui doit sortir (format du widget)
Dans `reports/aquarium-3d/widget-ocean/poissons-3d/<espèce>/`, 208 PNG transparents de 600 px de large au plus, tête à droite, tous dans le même cadre :
- `<espèce>-nage-0..15` (profil) ;
- `<espèce>-lacet-15-k` … `-lacet-90-k` (il part vers le fond) ;
- `<espèce>-lacet-m15-k` … `-lacet-m90-k` (il vient vers nous), k = 0..15.
Modèle : `poissons-3d/brochet/`.

## Vérifier avant de pousser
Ouvrir `-nage-4`, `-lacet-45-4`, `-lacet-m45-4` et `-lacet-90-4` : le poisson est entier, tête à droite, sans trou ni trait noir sur le dos, et ses nageoires bougent d'une image à l'autre.

## Pousser
Une espèce par commit, sur `lot/aquarium`, jamais en force :
```sh
git add reports/aquarium-3d/widget-ocean/poissons-3d/<espèce>
git commit -m "Aquarium : <espèce> en volume, 13 angles × 16 images"
git pull --no-rebase origin lot/aquarium && git push origin lot/aquarium
```
Le fond océan du widget est déjà poussé : `reports/aquarium-3d/widget-ocean/ocean-v2/`.
