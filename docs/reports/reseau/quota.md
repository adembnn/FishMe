# Quota CloudKit : ce que 1 000 photos et 100 vidéos consomment
Décision débloquée : garder CloudKit base publique pour le feed photo-vidéo (décision 2), ou revenir à un fournisseur externe si la vidéo dépasse le quota ; ouvre L23 (feed) une fois les cases « à mesurer » remplies.
Lu le 19/10/2026 (pages Apple citées). Mesuré le : à mesurer (Sullyvan lance `outils/reseau/` sur son Mac, mode d'emploi dans `outils/reseau/README.md`).

**État honnête : aucune mesure n'existe à ce jour.** Ce fichier fixe la méthode, la formule de projection et ce qu'Apple publie. Les cases « à mesurer » se remplissent avec les sorties du prototype, collées telles quelles, avec date et heure.

## En bref
Image : le quota CloudKit est un entrepôt dont la taille grandit avec le nombre de clients actifs. Les photos sont des cartons, les vidéos des armoires. La question est de savoir à partir de combien de pêcheurs actifs les armoires remplissent l'entrepôt.
Apple dit qu'une app peut stocker jusqu'à 1 Po de données publiques ([CloudKit](https://developer.apple.com/icloud/cloudkit/)). Le détail (stockage par utilisateur actif, requêtes par seconde, taille maximale d'un asset) n'est pas sur les pages Apple que j'ai pu lire le 19/10/2026 : ⚠ non lu. La page de quotas dédiée renvoie une erreur 404 (https://developer.apple.com/icloud/cloudkit/quotas/). Un fil du forum Apple de novembre 2023 note que les informations en ligne sont périmées et que les limites croissent avec les utilisateurs actifs, sans réponse d'Apple ([forum](https://developer.apple.com/forums/thread/740916)).
Source secondaire, non Apple : un ancien calculateur d'Apple donnait environ 100 Mo d'assets par utilisateur actif ([article](https://cur.at/BZMIzad?m=web)) [?] à confirmer dans le tableau de bord. **Ce chiffre ne sert pas de base de décision.**
Le quota « par utilisateur » est une moyenne liée au nombre d'utilisateurs actifs, au sens d'Apple ([forum](https://developer.apple.com/forums/thread/679090)) [?] contenu secondaire. Un prototype à un seul compte ne peut donc pas le mesurer : il mesure la consommation d'une publication, et le tableau de bord donne la limite.

## Le protocole (rappel)
| Étape | Entrée | Sortie à coller |
|---|---|---|
| Avant | tableau de bord, 3 captures | stockage assets, stockage base, requêtes |
| Photos | 1 000 fichiers de 300 Ko | durée, échecs |
| Vidéos | 1 vidéo exportée 720p 15 s, copiée 100 fois | taille réelle, durée, échecs |
| Fil | 50 publications | temps, octets |
| Après | 15 à 30 min plus tard | mêmes 3 compteurs |

## Résultats collés
### Tableau de bord (copie telle quelle)
| Compteur | Avant | Après | Écart |
|---|---|---|---|
| Stockage des assets | à mesurer | à mesurer | à mesurer |
| Stockage de la base de données | à mesurer | à mesurer | à mesurer |
| Requêtes | à mesurer | à mesurer | à mesurer |
| Limite affichée par Apple | à mesurer | à mesurer | sans objet |

### Sorties du prototype
- Photos : durée, échecs : à mesurer.
- Taille réelle d'une vidéo de 15 s après `AVAssetExportSession` 720p : à mesurer.
- Vidéos : durée, échecs : à mesurer.
- Fil de 50 sans médias, avec médias (3 passages) : à mesurer.
- Likes d'un fil, une requête `IN` : à mesurer ; si la requête est refusée, le schéma des likes change (`schema.md`).

## Ce que le calcul de l'écart doit contrôler
1. Écart d'assets attendu : 1 000 × 300 Ko + 100 × (taille de la vidéo) ; l'écart lu sur le tableau de bord doit être du même ordre. S'il est très différent, noter pourquoi (compression, dédoublonnage, retard du compteur).
2. Écart de base de données : les enregistrements eux-mêmes (une `Publication` sans média). À comparer à l'écart d'assets : c'est la part « métadonnées ».
3. Rien n'est retenu si les compteurs n'ont pas bougé : attendre et relever à nouveau, ne pas conclure sur un compteur en retard.

## Projection pour 1 000, 10 000 et 100 000 utilisateurs actifs
Formule (à remplir, aucun chiffre inventé) : consommation mensuelle par pêcheur = (publications photo par mois × 300 Ko) + (publications vidéo par mois × taille réelle d'une vidéo, à mesurer) + (métadonnées mesurées). Mois avant plafond = quota par utilisateur actif (lu dans le tableau de bord) ÷ consommation mensuelle.
| Utilisateurs actifs | Quota total d'après Apple | Conso par pêcheur et par mois | Mois avant plafond |
|---|---|---|---|
| 1 000 | à mesurer | à mesurer | à mesurer |
| 10 000 | à mesurer | à mesurer | à mesurer |
| 100 000 | à mesurer | à mesurer | à mesurer |
Hypothèses d'usage à fixer par Adem (aucune donnée FishMe n'existe) : publications par pêcheur et par mois, part de vidéos. Tant que ce n'est pas fixé, toute projection serait une estimation à étiqueter comme telle.

## Où la vidéo devient le problème
La vidéo pèse plusieurs photos (la taille exacte vient de la mesure). Le point critique est le moment où `p_vidéo × taille_vidéo` dépasse `p_photo × 300 Ko` : à calculer avec les valeurs mesurées. Pistes si le plafond approche, par ordre de coût :
1. Réduire la durée de 15 s à 10 s ou le format à 540p. Recommandation : seulement après mesure ; change avec un budget : non.
2. Supprimer les vidéos de plus de 90 jours (estimation de durée raisonnable) par une purge manuelle dans le tableau de bord. Change avec un budget : non, mais travail humain.
3. Photos seules au départ, vidéo dans une mise à jour (la fiche L23 le prévoit déjà). Change avec un budget : non.
4. Fournisseur externe de stockage vidéo (décision 2, repli). Change avec un budget : oui.

## Coût
CloudKit est gratuit dans la limite du quota de l'app, sans facture ([CloudKit](https://developer.apple.com/icloud/cloudkit/)) ⚠ la page ne précise pas ce qui arrive au-delà ; Apple ne l'a pas écrit selon la source secondaire. Aucun budget pour démarrer. Au-delà du quota : inconnu, à demander à MWM ou au support Apple avant de dépasser. Change avec un budget : oui (si dépassement).

## Ce qui reste hors de la mesure
Débit par seconde en pointe, quota de requêtes par jour, taille maximale d'un asset et nombre maximal d'éléments par requête : ⚠ non lus. Le prototype écrit par lots de 10 photos et 5 vidéos pour rester loin des limites usuelles (estimation) ; toute erreur `limitExceeded` ou `requestRateLimited` doit être collée dans `RESULTATS.md`.
