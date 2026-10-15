# Faisabilité pêche : les données

Décision débloquée : quelles données on peut brancher d'ici vendredi, lesquelles on saisit à la main, lesquelles bloquent.
Lu le 12/10/2026. [?] = non vérifié. Le proxy du bac à sable bloque curl vers hubeau.eaufrance.fr (403 CONNECT) : les appels réels sont passés par WebFetch. Légifrance, Wikimedia Commons et fishbase.se n'ont pas répondu à WebFetch.

## 1. Réglementation

**Socle national (Code de l'environnement).** Source vérifiée : le tableau comparatif du projet de décret 2018, qui reproduit le texte en vigueur https://www.consultations-publiques.developpement-durable.gouv.fr/IMG/pdf/tableau_comparatif_decret_peche_v_post_cne.pdf . Le texte consolidé actuel sur Légifrance n'a pas pu être relu : vérifier chaque chiffre avant publication [?].
- 1re catégorie : ouverture générale du 2e samedi de mars au 3e dimanche de septembre (R436-6) ; ombre du 3e samedi de mai à la même fin. Brochet pris en 1re cat. entre le 2e samedi de mars et le dernier vendredi d'avril : remise à l'eau immédiate.
- 2e catégorie, brochet : du 1er janvier au dernier dimanche de janvier, puis du 1er mai au 31 décembre (R436-7). Le projet de 2018 avançait la réouverture au dernier samedi d'avril ; les arrêtés 2024 de Seine-et-Marne et de l'Allier montrent une réouverture fin avril, donc ce changement semble en vigueur [?].
- Tailles minimales (R436-18) : brochet 0,50 m, sandre 0,40 m, black-bass 0,30 m (2e cat.), truite 0,23 m, ombre 0,30 m, huchon 0,70 m, esturgeon 1,80 m, mulet 0,20 m.
- Relèvement par le préfet (R436-19) : brochet à 0,60 m, sandre à 0,50 m, black-bass à 0,40 m, ombre à 0,35 m, truite abaissable à 0,18-0,20 m ou relevable à 0,25-0,30 m.
- Quotas (R436-21) : 10 salmonidés par jour ; en 2e cat., 3 carnassiers par jour dont 2 brochets au plus. Le préfet peut les réduire.
- Non vérifié : R436-8 à R436-13 (détail des ouvertures spéciales, grenouilles, écrevisses) [?].

**Ce que les arrêtés départementaux changent (deux exemples lus).**
- Seine-et-Marne (77), projet d'arrêté permanent 2024 remplaçant l'arrêté 2022/DDT/SEPR/296 : brochet 0,60 m, sandre 0,50 m, black-bass 0,40 m, truite 0,23 m, ombre 0,30 m, anguille jaune 0,12 m. Catégories : 1re = une liste de petites rivières (Lunain, Orvin, Grand Morin amont, Dragon...) ; tout le reste en 2e. Brochet et sandre fermés du dernier dimanche de janvier au dernier samedi d'avril ; leurre interdit en 2e cat. pendant cette fermeture. Carpe de nuit sur parcours désignés. Quotas renvoyés à l'arrêté annuel. https://www.seine-et-marne.gouv.fr/contenu/telechargement/59883/499389/file/PROJET_ARP_PERMANENT_2024.pdf (c'est un projet, numéro et date vides ; chercher la version signée [?])
- Avis annuel 77 pour 2024 (dates) : ombre 18 mai-15 sept. (1re) / 18 mai-31 déc. (2e) ; truite 1-28 janvier puis 27 avril-31 décembre [le texte lu est ambigu, à revérifier] ; reste du poisson ouvert toute l'année. https://www.seine-et-marne.gouv.fr/contenu/telechargement/59882/499384/file/PROJET_DATES_OUVERTURES-2024.pdf
- Allier (03), arrêté 2024 : 6 salmonidés par jour (au lieu de 10), 1 brochet par jour en 1re cat., 2 carnassiers dont 1 brochet et 1 sandre en 2e, brochet 0,60 m, sandre 0,50 m, black-bass et ombre en no-kill total, 24 réserves nommées (19 permanentes, 5 saisonnières), 8 parcours no-kill ou réglementés. https://allier.gouv.fr/contenu/telechargement/14239/98625/file/ARR_reglementation_peche_2024.pdf
- Leçon : tailles et quotas sont des valeurs numériques simples ; les réserves et no-kill sont des listes de lieux nommés, donc de la géométrie.

**Combien de règles pour 80 % des cas ?** Estimation de ma part, pas une mesure [?]. Un pêcheur de loisir attrape surtout 8 à 10 espèces (brochet, sandre, perche, black-bass, truite fario, truite arc-en-ciel, carpe, ombre, anguille jaune). Pour un département : 1 table de catégorie (1re/2e), 4 règles d'ouverture (général 1re, brochet/sandre 2e, truite, ombre), 9 tailles, 3 quotas, soit environ 20 lignes de données. Le socle national fournit environ 15 de ces lignes ; l'arrêté du département pilote en écrase 5 à 8 (brochet, sandre, black-bass, quotas, dates d'ombre/truite). Les réserves nommées et no-kill ne sont pas dans ce compte : elles passent par la couche carte (point 4).

**Légifrance en API : oui.** API Légifrance sur PISTE, gratuite après inscription, Licence Ouverte 2.0, quota par jeton non chiffré sur la page, base https://sandbox-api.piste.gouv.fr ; couvre les codes consolidés (jeu LEGI). https://www.data.gouv.fr/dataservices/legifrance/ . Les arrêtés préfectoraux n'y sont pas : ils sont dans les recueils des actes administratifs (PDF) des préfectures [?]. Pas d'API nationale des arrêtés de pêche trouvée. Vendredi : saisie à la main, pas d'appel API (compte PISTE à créer = délai, clé = fichier .env).

## 2. Classement 1re / 2e catégorie en données ouvertes
- Pas de couche nationale trouvée [?]. Des couches départementales existent, une par DDT, toutes en Licence Ouverte 2.0 :
  - Ille-et-Vilaine (35) : shapefiles + WMS/WFS, màj 2024, source fédération. https://www.data.gouv.fr/datasets/categories-piscicoles
  - Meuse, Alpes-de-Haute-Provence, Côte-d'Or, Puy-de-Dôme : jeux séparés, formats et dates non lus [?]. https://www.data.gouv.fr/datasets/categories-piscicoles-des-cours-deau-et-plans-deau-du-departement-de-la-meuse-et-domanialite · https://www.data.gouv.fr/datasets/categorie-piscicole-lineaire-des-alpes-de-haute-provence · https://www.data.gouv.fr/datasets/cours-deau-du-departement-de-la-cote-dor-classe-en-1ere-categorie-piscicole · https://data.gouv.fr/en/datasets/classement-piscicole-des-cours-deau-puy-de-dome-2005
- Seine-et-Marne : le classement est un texte (liste de rivières 1re cat., le reste en 2e), donc règle "par défaut 2e catégorie" + une courte liste de cours d'eau, sans géométrie ouverte trouvée [?].
- Vendredi : par département pilote, soit la couche DDT si elle existe, soit "défaut + exceptions nommées". Hors pilote : "non couvert".

## 3. Cours d'eau et plans d'eau : BD TOPAGE
- Référentiel hydrographique national OFB/IGN/Sandre ; cours d'eau, plans d'eau, tronçons, nœuds ; échelles 1/5 000 et 1/50 000 ; Licence Ouverte 2.0 ; mise à jour annuelle. https://www.sandre.eaufrance.fr/atlas/srv/api/records/7fa4c224-fe38-4e2c-846d-dcc2fa7ef73e · https://www.data.gouv.fr/datasets/bd-topage-r
- Téléchargement : shapefile zip France métropolitaine 2024 ; GeoJSON/GeoPackage annoncés mais liens non donnés. Taille : non indiquée sur les pages [?] ; à mesurer avant (probablement des centaines de Mo à quelques Go).
- Usage hors ligne : non vérifié. Vu la taille, on découpe par département et on simplifie (outil type mapshaper/tippecanoe, des programmes qui allègent les tracés) avant d'embarquer ; sinon vecteur serveur. Pour vendredi : le département pilote seul, ou aucun tracé (liste de lieux avec points).
- Raccourci : il n'y a pas de lien direct TOPAGE vers catégorie piscicole ; on l'ajoute nous-mêmes [?].

## 4. Parcours, réserves, no-kill, parcours enfants
- Géopêche : app et carte privée, lancée en 2016, parcours + réserves + no-kill + 63 types d'icônes, données tenues par les fédérations, dans 56 départements (avril 2026). Fermée au sens "pas de données ouvertes" ; je n'ai trouvé ni API ni licence de réutilisation [?]. https://www.peche.com/article/51620/geopeche-un-outil-utile-pour-les-pecheurs . Les concurrents (HOOKfr, Génération Pêche) sont dans reports/concurrence-peche.md.
- Open data : rare. Exemple Loir-et-Cher : parcours (zones de pêche de nuit à la carpe), DDT 41, Licence Ouverte 2.0, shapefile/JSON, archivé en 2020. https://www.data.gouv.fr/en/datasets/peche-lineraire-de-parcours-de-peche-en-loir-et-cher/ . Parcours enfants, no-kill : aucun jeu trouvé [?].
- Les arrêtés eux-mêmes listent réserves et no-kill par nom (Allier : 24 réserves, 8 parcours). Saisie à la main possible pour 1 département : environ 30 lieux.
- Partenariat fédération (FDAAPPMA) : plausible mais non testé. Les fédérations tiennent déjà ces données pour Géopêche. Un mail à la fédération du département pilote demandant un export (shapefile ou CSV) avec accord de réutilisation est la voie la plus rapide ; contact et réponse non vérifiés [?]. Décision à valider par Adem : qui écrit, à quelle fédération.

## 5. Poissons : Hub'Eau
**Appel réel (via WebFetch, pas curl) :** `https://hubeau.eaufrance.fr/api/v1/etat_piscicole/observations?code_departement=77&size=5` a répondu : 70 876 observations pour le 77, 5 premières = vairons (Phoxinus phoxinus) mesurés 27 à 55 mm, station L'Yerres à Ozouer-le-Voulgis, pêche électrique du 2025-09-23, environ 90 champs par ligne (lot, effectif, coordonnées Lambert 93 et WGS84, protocole, station).
- Ce que c'est : pêches scientifiques à l'électricité (OFB, base ASPE), 50 ans, France entière, 4 endpoints (opérations, observations, indicateurs, stations), formats JSON/GeoJSON/CSV. https://hubeau.eaufrance.fr/page/api-poisson . Licence : site sous Licence Ouverte 2.0 ; pas de licence propre à l'API, ni limite de débit affichée. https://www.data.gouv.fr/dataservices/hubeau-etat-piscicole-des-rivieres
- Ce qu'on peut en tirer : une présence par espèce et par département (compter les observations ou les stations par espèce). Une "rareté" = part des stations où l'espèce a été vue sur le département, ou rang sur le département. Limites : ce sont des relevés de stations suivies, pas une abondance de pêcheurs ; biais vers les cours d'eau monitorés ; les petites espèces dominent ; les plans d'eau et canaux sont peu couverts [?]. C'est un score défendable pour une carte de jeu, pas une statistique.
- Piège : le champ `code_departement` + 70 876 lignes = il faut agréger côté serveur ou préparer un fichier (espèce x département) une fois, et l'embarquer. Pas d'appel direct depuis l'app.
- Liste des espèces : TAXREF (MNHN/INPN), Licence Ouverte (Etalab), filtrable sur poissons d'eau douce ; sur la page, version citée 4.8 mais maj au 10 oct. 2026 ; certains sites du MNHN sont inaccessibles après une cyberattaque, avec téléchargement de secours côté PatriNat. https://www.data.gouv.fr/datasets/referentiel-taxonomique-taxref/ . Le nombre exact d'espèces d'eau douce ("~80") : non vérifié [?]. Les observations Hub'Eau donnent aussi une liste d'espèces réellement vues.

## 6. Images d'espèces
- FishBase : images et données sous CC BY-NC d'après la consigne ; conditions non relues (le site n'a pas répondu) [?] . NC = usage non commercial : incompatible avec une app avec abonnement. Bloquant. Ne pas utiliser.
- Wikimedia Commons : photos sous licences variées (CC BY, CC BY-SA, CC0, domaine public) ; exige attribution par image, et CC BY-SA oblige à partager l'adaptation sous la même licence (risque pour des cartes retouchées). Licence à contrôler fichier par fichier ; page non lue [?]. Ex. catégorie : https://commons.wikimedia.org/wiki/Category:Esox_lucius
- Voie sûre pour les cartes : illustrations dans le domaine public (gravures anciennes, p. ex. Biodiversity Heritage Library [?]) ou créées par nous, par exemple un style imagé généré par IA (décision de style = à Adem). Et la photo de l'utilisateur sur la carte : droits à régler dans les CGU.
- Vendredi : une silhouette ou illustration maison par espèce pour les 10 espèces courantes ; photos Commons CC BY / CC0 filtrées uniquement si nécessaire, avec crédits.

## 7. Météo et conditions
- WeatherKit : 500 000 appels par mois inclus avec l'Apple Developer Program, ensuite 49,99 $/mois pour 1 million ; iOS 16+ en Swift ; mention "Weather" et lien d'attribution obligatoires. https://developer.apple.com/weatherkit/get-started/ . Question ouverte : le compte MWM fournit-il le droit WeatherKit ? [?]
- Hydrométrie (hauteurs H et débits Q) : Hub'Eau Hydrométrie, temps quasi réel (5 à 60 min côté producteur, interrogé toutes les 2 min), environ 3 000 stations, un mois d'historique en temps réel, Licence Ouverte 2.0. https://www.data.gouv.fr/dataservices/hubeau-hydrometrie . Mon appel réel sur `observations_tr?code_departement=77` a échoué (erreur côté outil), donc le format est non testé [?].
- Température de l'eau : Hub'Eau température, appel réel OK : 325 662 mesures pour le 77, premier relevé Auxence à Vimpelles (station 03013660), 21,7 °C le 2009-07-28, non qualifié. Seules quelques stations ont des données récentes [?]. Pas fiable pour "température de l'eau ici" partout.
- Vigicrues : même source (plateforme PHyC), donc via Hub'Eau ; pas d'accès direct testé [?].

## 8. Table de synthèse

| donnée | source | licence | format | dispo / main / bloquant | minimum vendredi |
|---|---|---|---|---|---|
| Socle national (tailles, ouvertures, quotas) | Code env. R436-6 à R436-21, API Légifrance PISTE | Licence Ouverte 2.0 | texte JSON / HTML | main (chiffres lus via tableau 2018) | table JSON de 15 lignes à la main, chaque ligne avec son article |
| Overrides départementaux | arrêtés préfectoraux (PDF) | domaine public administratif [?] | PDF | main | 1 département pilote saisi (ex. 77), 8 espèces |
| Détection du département | position GPS | n/a | n/a | dispo (iOS CoreLocation + contours) [?] | département par géocodage inverse |
| Classement 1re/2e catégorie | DDT/fédérations sur data.gouv | Licence Ouverte 2.0 | SHP, WMS/WFS | dispo par département (35, 55, 04, 21, 63), pas national | "2e par défaut + liste de rivières 1re" au pilote |
| Cours d'eau, plans d'eau | BD TOPAGE (Sandre/IGN) | Licence Ouverte 2.0 | SHP (GeoJSON/GPKG annoncés) | dispo, taille [?] | tracé du département pilote seulement, ou points |
| Réserves, no-kill | arrêtés, fédération | variable | PDF / noms de lieux | main | liste nommée du pilote |
| Parcours enfants / no-kill carte | Géopêche (fermé), FDAAPPMA | non ouvert | app privée | bloquant (pas de réutilisation) | partenariat fédération ou rien |
| Présence des espèces | Hub'Eau Poissons (OFB/ASPE) | Licence Ouverte 2.0 | JSON/CSV | dispo, appel testé via WebFetch | fichier espèce x département précalculé pour le pilote |
| Liste d'espèces d'eau douce | TAXREF (MNHN/INPN) | Licence Ouverte | CSV | dispo, site MNHN fragile | 20 espèces choisies, nom FR + latin |
| Images d'espèces | Commons / FishBase / illustrations | CC BY-SA, CC BY, CC0 / CC BY-NC | JPG | FishBase bloquant ; Commons main | illustrations créées pour 10 espèces |
| Météo | WeatherKit | 500 000 appels/mois inclus | SDK Swift | dispo si compte MWM le couvre [?] | température, vent, pression, lune à l'enregistrement d'une prise |
| Débit, hauteur d'eau | Hub'Eau Hydrométrie (PHyC) | Licence Ouverte 2.0 | JSON | dispo, appel non testé | rien ou 1 station |
| Température de l'eau | Hub'Eau Température | Licence Ouverte 2.0 | JSON | dispo, couverture inégale | hors périmètre vendredi |
