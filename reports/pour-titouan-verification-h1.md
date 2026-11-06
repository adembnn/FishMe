# Pour Titouan : lancer la vérification de H1 sur ta machine (27 oct.)

Adem ne peut plus faire tourner les tests de l'app : sur son Mac (8 Go), démarrer le simulateur iOS 27 suffit à saturer la machine (charge à plus de 300). La vérification de `lot/atelier-2` (H1) est donc bloquée sur la partie « App ».

## Ce qu'il y a à faire
Dans une copie de `lot/atelier-2` (branche à jour : commit `df455fe0` ou plus récent), lance :

```bash
scripts/fusionner.sh
```

Ce que j'ai déjà vérifié (sortie du script, 27 oct.) :
- dossiers : ✓ (le diff reste dans H1) ;
- documents : ✓ (0 trou, 22 lots) ;
- lots et atelier : ✓ (202/202) ;
- Core : ✓ (255 tests) ;
- App : ✗ lors de ma dernière vraie exécution (883 s) : 9 tests rouges, dont 5 tests d'interface lancés sous une charge de 52 (faux rouges possibles) et 2 tests de l'aquarium déjà rouges le 20 oct. Aucun ne vient de H1 (H1 ne touche qu'à l'atelier).

## Ce que je te demande de me renvoyer
La dernière ligne du script (« Fusionné : … » ou la ligne ✗), et la liste des tests rouges s'il y en a.

## Ce qui a changé dans ta branche
J'ai fusionné `origin/lot/atelier-2` dans la mienne (conflits sur `essai.py`, `lots.py`, `essai-lots.md` : ta version gardée), et ajouté les fiches `docs/fiches/N1.md` à `N6.md` et `D2B.md` pour N1 à N6 et D2B. Ce sont des squelettes : la section « Contrat » dit « À décider ». Les décisions de produit de ces lots sont à écrire par toi ou par Adem. La colonne « Qui » de N3 est passée de « B et A » à « B ».
