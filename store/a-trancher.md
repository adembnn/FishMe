# À TRANCHER par Sullyvan (lot S1)

Rien n'est décidé ici : chaque point a une recommandation, la décision reste à Sullyvan (ou à Adem là où c'est écrit). Les textes de `fiche-fishme.md` portent des crochets aux endroits concernés.

## 1. À TRANCHER : la décision Q24 de Titouan (leviers Pro et « 15 cartes »)
- Contexte : la fiche de Titouan (ancien produit) décrit un Pro à cinq leviers (bestiaire de tous les départements, finitions de cartes, bilan de saison et export, sauvegarde iCloud, mode Préparer) et un gratuit limité à une grille de cartes. `CLAUDE.md` (Adem, 15 oct. 12h26, 12h28, 13h21) dit autre chose : gratuit = un spot (cercle de 1 km) à sessions illimitées, carte, règles et Pescedex en lecture gratuits pour toujours ; Pro = autres spots, météo, niveau de rivière, alertes, historique, conseils.
- **Recommandation : écarter Q24 pour FishMe.** C'est une décision sur un produit abandonné, contredite par une décision d'Adem plus récente et plus précise ; aucun des cinq leviers n'existe dans le plan de lots de FishMe. La fiche proposée ne cite aucun d'eux. Prévenir Titouan avant qu'il ne réécrive, ou faire trancher par Adem s'il y tient.
- Ce qui change si Sullyvan tranche autrement : les blocs « GRATUIT POUR TOUJOURS » et « FISHME PRO » de la description sont à refaire.

## 2. À TRANCHER : la ligne de prix dans la description
- Option A : écrire le prix (« Abonnement annuel au tarif fondateur de 34,99 € jusqu'au 31 décembre 2026 ; abonnement mensuel à [PRIX] € avec 1 semaine d'essai »).
- Option B : ne pas écrire de prix dans la description ; le paywall et App Store Connect affichent déjà les prix de StoreKit.
- **Recommandation : option B pour la première soumission.** Raisons : (1) `fiches/S1.md` n'autorise le tarif dans le texte que s'il est identique au paywall de L6, que personne n'a encore vu sur un iPhone ; (2) le mensuel retenu n'est pas choisi (`CLAUDE.md`) ; (3) les prix en euros viennent de la colonne France d'App Store Connect, pas encore lue ; (4) un écart entre la description et le paywall est un refus 3.1.2 / R4. On garde dans la description la phrase de renouvellement automatique et la restauration des achats, qui ne dépendent pas des prix. Si Adem tient à citer le tarif fondateur, passer à l'option A **après** avoir vu le paywall et lu les euros, jamais « 49,99 à partir du 1er janvier » avant que ce produit soit joint (il l'est en décembre).
- Aucun essai « 1 mois » dans aucun cas.

## 3. À TRANCHER : les fonctions Pro citées dans la description
- Candidates (décidées « tout d'un coup » le 15 oct. 13h21, mais **rien ne prouve qu'elles seront finies et fusionnées jeudi soir** ; chaque fonction absente est un refus R7) : autres spots, météo du jour et sur 7 jours, niveau de la rivière, « préviens-moi », historique des conditions, conseils de pêche par espèce.
- **Recommandation : deux versions de la phrase, la bonne choisie à la porte 3 (L0 + 10 h) sur le build TestFlight.**
  - Version complète si tout est à l'écran : celle de `fiche-fishme.md`.
  - Version réduite : ne citer que les fonctions vues à l'écran, une par une (par exemple seulement la météo et le niveau de la rivière). Ne rien écrire au futur (« bientôt », « prochainement ») : une fonction pas dans le build ne s'écrit pas du tout.
  - Dans tous les cas, ce qui est Pro est dit Pro, et la sécurité (alerte orage et crue) est dite gratuite.
- La météo ne s'écrit qu'avec « Apple Weather » ; la couverture « toute la France » seulement si le build charge les règles de tous les départements ; la reconnaissance ne promet jamais « toutes les espèces » (N lu dans le modèle de R1, repli à 6 espèces si le modèle à 77 n'est pas prêt).
- Note à confirmer après la porte 3 : toutes les lignes marquées dans la description.

## 4. Autres points (moins lourds)
- **Sous-titre** : `Poissons, règles et Pescedex` (28 car.) recommandé ; alternatives dans `fiche-fishme.md`. À valider par Sullyvan ou Adem.
- **Catégorie principale** : « Sports » par défaut, à confirmer par Adem (`fiches/S1.md`).
- **Couverture des règles dans la description** : lire les départements réellement chargés dans le build. Seuls 75, 92, 93, 94, 77 sont documentés comme saisis à la main ; les pilotes 01, 87, 44 sont partiels (205 règles confirmées sur 287 pour l'Ain). Ne citer qu'une liste lue dans le build [?].
- **Bouton « photo d'exemple »** : les notes pour le relecteur en dépendent ; à confirmer par B à l'écran.
