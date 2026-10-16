Décision débloquée : le socle national que l'app montre partout (national.json, 33 règles le 15 oct., 135 le 16 oct.)

Fichier : docs/regles-local/national.json, même forme que Packages/Core/Sources/Core/Resources/regles/national.json (lot/donnees), à copier tel quel.
Toutes les règles ajoutées sont lues au mot près : Légifrance (arrêtés de 2004, 2024 et 12 juin 2026 lus en ligne le 16 oct.) et la copie du Code francois76/legifrance (août 2024) ; R436-18 recoupé sur Légifrance (version du 26/04/2019, inchangée).

Ajouts (102 règles, statut brouillon) :
- Tailles R436-18 manquantes : huchon 70, cristivomer 35, corégone 30, lamproie fluviatile 20, lamproie marine 40, omble de fontaine 23, omble chevalier 23, mulet 20, 4 écrevisses autochtones 9 cm, grenouilles verte et rousse 8 cm (museau au cloaque).
- Tailles R436-62 (eau douce) : saumon 50, truite de mer 35, grande alose 30, alose feinte 30.
- Écrevisses autochtones (pattes rouges, torrents, pattes blanches, pattes grêles) : ouvertes du 25 juillet au 3 août 2026 (R436-10), fermées avant et après.
- Anguille : civelle interdite aux pêcheurs de loisir partout (R436-65-3), argentée interdite (R436-65-5), anguille jaune fermée du 1er août au 31 décembre 2026 (arrêté du 12 juin 2026, expire le 31/12/2026). Bassins Rhône-Méditerranée et Corse : pêche de loisir interdite à tous les stades (arrêté du 14 mars 2024), écrite département par département pour 18 départements entièrement dans ces bassins (01 04 05 06 13 25 26 2A 2B 30 34 38 39 66 73 74 83 84) ; 07, 11, 21, 42, 48, 69, 70, 71, 88, 90 sont à cheval et n'ont pas la règle.
- Esturgeon européen : capture interdite et remise à l'eau obligatoire (arrêté du 20 décembre 2004, art. 1 et 3).
- Saumon, truite de mer, aloses, lamproies : dates fixées par l'arrêté du département (R436-57, type autre) ; saumon : marque et carnet (R436-65).
- Grenouilles : période fixée par le préfet, dix mois au plus (R436-11).
- 1re catégorie : brochet remis à l'eau du 14 mars au 24 avril (R436-6), ombre fermé jusqu'au 15 mai (R436-6), 2 brochets par jour (R436-21, sort de a_verifier).
- Quota de 10 salmonidés : ombles, cristivomer, huchon et corégones ajoutés à la règle nat-sal-quota.

Contrôle : verifier_regles et verifier_dates de outils/verifier_donnees.py (claude/finir-app-ud5swp) sans erreur.
Pas de règle nationale pour les dates d'anguille jaune par bassin (arrêté du 5 février 2016, tableau non lu) : chaque département les donne.
