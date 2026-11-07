# FishMe US - Données de présence des poissons et méthode de rareté

Date : 7 nov. 2026
Volet : données de présence et rareté (adaptation États-Unis)

**Décision débloquée : choisir l'unité géographique et la définition de rareté pour les USA (fréquence d'occurrence par HUC8, pas « % des pêches électriques » national), et valider un État pilote (Wisconsin ou Minnesota en premier choix, Michigan en repli) avant d'investir dans un pipeline national.**

Légende : [?] = non vérifié dans cette recherche. Aucune statistique chiffrée n'est avancée sans source. Les licences et statuts d'API sont à revalider avant l'intégration (recherche faite par moteur de recherche, pages primaires non toutes ouvertes).

---

## 1. Constat principal

Il n'existe pas d'équivalent US de la base OFB « pêches électriques standardisées, France entière ». Les données sont éclatées : un protocole fédéral probabiliste (EPA NRSA, peu de sites), des bases fédérales agrégées (USGS BioData / Water Quality Portal), des observations opportunistes (GBIF, iNaturalist) et des enquêtes d'agences d'État, très riches mais hétérogènes (lacs en filets maillants, cours d'eau en pêche électrique, formats variables). Le calcul « % des pêches où l'espèce est trouvée » n'est faisable proprement que sur des sous-ensembles (un État, un type de milieu, un engin).

---

## 2. Inventaire des sources

### 2.1 USGS NAS (Nonindigenous Aquatic Species)
- URL : https://nas.er.usgs.gov/ ; API : https://nas.er.usgs.gov/api/documentation.aspx (base v2 : http://nas.er.usgs.gov/api/v2)
- Licence : fiche data.gov USGS = domaine public (US government public domain) ; des miroirs affichent CC0 (GBIF) ou CC-BY (copie californienne) : se fier à la fiche USGS. https://catalog.data.gov/dataset/nonindigenous-aquatic-species-nas-usgs-ds731
- Format : API REST (observations de spécimens, listes d'espèces), jeu aussi publié sur GBIF (https://www.gbif.org/dataset/d6cc311c-c5ab-4f23-9a20-10514f9eb9c4).
- Couverture : espèces NON indigènes uniquement (introduites/transplantées), pas les natives. Utile pour le statut « introduite » par État/HUC.
- Granularité : point GPS + HUC + comté + État [champs exacts ?].
- Année la plus récente : base vivante, mise à jour continue [?].
- Accès : facile. Un ancien descriptif (2014) mentionne 100 enregistrements par requête en anonyme et une clé après échange avec l'équipe ; à revérifier. Plus simple : passer par GBIF.

### 2.2 GBIF (inclut ex-BISON)
- URL : https://www.gbif.org/ ; API de téléchargement documentée sur le site.
- Licence : par enregistrement, uniquement CC0, CC BY ou CC BY-NC (GBIF n'accepte pas CC BY-SA/ND). Filtre de licence possible au téléchargement. Citation du DOI de téléchargement obligatoire en pratique.
- Format : CSV/Darwin Core, API. Les données BISON ont été intégrées à GBIF [?].
- Couverture : agrège museums, iNaturalist, jeux d'agences, NAS. Occurrences (présence), pas d'effort d'échantillonnage dans la plupart des jeux.
- Granularité : point GPS (précision variable, coordonnées parfois floutées).
- Année la plus récente : continue.
- Accès : facile à moyen (téléchargement asynchrone, volumes importants). Implication licence : le jeu iNaturalist est affiché en CC BY-NC sur GBIF (https://gbif.org/dataset/50c9509d-22c7-4a22-a47d-8c48425ef4a7) : usage non commercial par défaut ; FishMe étant potentiellement commerciale (abonnement/pub), filtrer CC0 et CC BY ou obtenir l'accord des auteurs.

### 2.3 iNaturalist
- URL : https://www.inaturalist.org/ ; API https://api.inaturalist.org/v1/docs ; export https://www.inaturalist.org/observations/export
- Licence : choisie par chaque observateur (CC0, CC BY, CC BY-NC, ou tous droits réservés). Seules les licences ouvertes partent vers GBIF. Source : https://www.inaturalist.org/posts/30692-tech-tip-tuesday-understanding-licensing
- Format : API JSON, export CSV, miroir GBIF.
- Couverture : observations « research grade » ; très forte densité urbaine/touristique, poissons sous-représentés (observations surtout de plongée, rives, prises par pêcheurs).
- Granularité : point GPS (peut être obscurci pour espèces sensibles).
- Accès : API limitée (ordre de 10 000 requêtes/jour cité par un forum, à confirmer dans la doc officielle [?]) ; iNaturalist demande de préférer les exports en masse.
- Usage pour FishMe : complément de présence et vérification, pas base de fréquence (biais d'observateur fort).

### 2.4 EPA NRSA / NARS (National Rivers and Streams Assessment)
- URL : https://www.epa.gov/national-aquatic-resource-surveys/nrsa ; données 2018-19 : zip « NRSA 2018-2019 Data Files » sur les pages EPA (rapport EPA-841-R-22-004). TSD : https://www.epa.gov/system/files/documents/2023-11/nrsa-2018-19-tsd-final-11072023.pdf
- Licence : données fédérales EPA (domaine public attendu) [?].
- Format : fichiers CSV/zip ; fiches de tissus de poissons en xlsx (mercure, PCB, PFAS) ; assemblages de poissons mentionnés dans le TSD, jeu téléchargeable séparé non confirmé [?].
- Couverture : design probabiliste national (échantillon de sites par campagne ; cycles 2008-09, 2013-14, 2018-19, campagne 2023-24 en cours/publication [?]). C'est le plus proche d'un échantillonnage statistiquement représentatif, mais peu de sites par État et par HUC8.
- Granularité : point GPS par site + écorégion ; peu de répétitions par HUC8.
- Accès : moyen (fichiers lourds, dictionnaires de données).
- Usage : calibrer/valider la rareté nationale et fournir des fréquences par écorégion, pas par comté.

### 2.5 USGS BioData / Water Quality Portal (WQP)
- URL : https://aquatic.biodata.usgs.gov/ ; WQP https://www.waterqualitydata.us/ ; doc BioData https://pubs.usgs.gov/fs/2011/3112
- Licence : données fédérales (domaine public) [?] ; WQP agrège aussi des données non fédérales.
- Format : export CSV via WQP (API de services web) ; espèces codées par TSN ITIS.
- Couverture : protocoles NAWQA et NRSA, extensions plus récentes pour protocoles divers d'États et fédéraux ; intégration de données de communautés de poissons BioData + STORET dans le WQP décrite vers 2015. État actuel de la couverture à confirmer [?].
- Granularité : point GPS (station), avec effort d'échantillonnage dans les métadonnées d'activité (plus exploitable que GBIF).
- Accès : moyen (WQP exige de bien choisir les profils « biological results »).
- Intérêt : seule source nationale qui distingue des événements de pêche (échantillons) ; donc compatible avec un calcul « % des échantillons », limité en densité.

### 2.6 Agences d'État

| État | Source trouvée | Format / accès | Statut |
|---|---|---|---|
| MN | DNR : rapports de lac individuels (PDF, filets maillants/seines) https://files.dnr.state.mn.us/areas/fisheries/windom/lakes/surveys/ ; compilation de recherche UMN (6 espèces, plus de 1 000 lacs) https://doi.org/10.13020/p4rw-z926 | PDF à scraper ; CSV (jeu de recherche, périmètre limité) | Pas d'export DNR global trouvé ; contacter la DNR [?] (LakeFinder / Fish Sampling data requests) |
| WI | SWIMS et Surface Water Data Viewer (DNR) ; USGS ScienceBase : échantillons DNR de poissons par électropêche 1945-2014 https://sciencebase.gov/catalog/item/53c57a0be4b0b58d96eeb70b | ScienceBase téléchargeable ; SWIMS demande un identifiant | Bon candidat : électropêche, longue série, historique ouvert (date de fin 2014 : à actualiser via DNR) |
| MI | Portail ouvert, Fish Atlas https://gis-michigan.opendata.arcgis.com/datasets/midnr::fish-atlas-2 ; CHANGES Fish Collection (Deep Blue, CC0) ; Statewide Creel (Grands Lacs, Access) | Service cartographique + CSV | Données accessibles, Fish Atlas à vérifier en contenu [?] |
| TX | TPWD : rapports par réservoir (PDF, annexe « catch rates » électropêche) https://tpwd.texas.gov/publications/pwdpubs/media/lake_survey/ ; base interne d'électropêche citée dans la littérature | PDF ; demande probable | Pas de téléchargement public confirmé |
| NY | DEC : non couvert par la recherche | - | [?] à rechercher |
| PA | PFBC : non couvert par la recherche | - | [?] à rechercher |

Remarque : pour les lacs, les agences publient des CPUE par engin (filet maillant, électropêche de rive) ; l'unité « pêche » est donc le lac-année-engin, pas le cours d'eau.

### 2.7 StreamNet (Nord-Ouest Pacifique : WA, OR, ID, MT, CA)
- URL : https://www.streamnet.org/ ; service cartographique https://gis.psmfc.org/server/rest/services/StreamNet/FishDistStreams_AllSpecies_20260312/MapServer (mise à jour 12 mars 2026 selon la métadonnée)
- Licence : texte non trouvé [?] ; mentions « Use limitations » dans les métadonnées de chaque jeu.
- Format : shapefiles, service ArcGIS, Data Store.
- Couverture : aire de distribution (présence par tronçon) des salmonidés surtout, pas de fréquence d'occurrence ; couvre CA via CalFish.
- Granularité : tronçon de cours d'eau (lignes), rattachable à HUC.
- Accès : facile (GIS) ; contact StreamNetGIS@psmfc.org.
- Usage : couche « présence/historique » pour les salmonidés de l'Ouest (hors pilote Est/Midwest).

### 2.8 FishBase
- URL : https://www.fishbase.org/ ; accès programmatique via rfishbase (CRAN, package sous licence CC0).
- Licence : données CC BY-NC (un forum rOpenSci et Wikipédia) : non commerciale, donc incompatible avec une app commerciale sans accord [?].
- Format : tables (parquet/CSV via rfishbase, hébergement HuggingFace selon les versions récentes).
- Couverture : fiches espèces mondiales (noms communs, taille, biologie), pas de fréquence locale.
- Usage : noms communs/fiches seulement, avec risque licence ; préférer ITIS, USGS NAS et fiches d'agences pour le contenu éditorial. Alternative pour noms : American Fisheries Society (liste de noms) [?].

---

## 3. Tableau de synthèse

| Source | Granularité | Effort connu | Natives | Introduites | Licence | Accès |
|---|---|---|---|---|---|---|
| USGS NAS | Point/HUC | Non | Non | Oui | Domaine public | Facile |
| GBIF | Point | Non | Oui | Oui | CC0/BY/BY-NC par ligne | Moyen |
| iNaturalist | Point | Non | Oui | Oui | Par observateur | Moyen |
| EPA NRSA | Site | Oui | Oui | Oui | Domaine public [?] | Moyen |
| BioData / WQP | Station | Oui (partiel) | Oui | Oui | Public [?] | Moyen |
| Agences d'État | Lac/site | Oui | Oui | Oui | Variable | Dur à moyen |
| StreamNet | Tronçon | Non | Oui (salmonidés) | Partiel | [?] | Facile |
| FishBase | Espèce | - | - | - | CC BY-NC | Facile |

---

## 4. Méthode de rareté proposée

### 4.1 Unité géographique
- **HUC8 (sous-bassins versants)** comme unité de calcul : les poissons suivent l'eau, pas les frontières administratives. Les comtés US sont trop nombreux et trop irréguliers pour la plupart des données ; les États sont trop grossiers (un État contient des écosystèmes très différents).
- **Repli hiérarchique** : si un HUC8 a trop peu d'échantillons, remonter au HUC6/HUC4, puis à l'État ; indiquer la source du repli à l'utilisateur.
- **Affichage app** : l'utilisateur voit sa position (GPS) projetée sur son HUC8 (jeu de limites WBD de l'USGS, https://www.usgs.gov/national-hydrography/watershed-boundary-dataset [?]), plus simple que la logique « département » française.

### 4.2 Définition
Le « % des pêches où l'espèce est trouvée » est faisable uniquement si les données portent un identifiant d'événement d'échantillonnage (cas de NRSA, BioData/WQP, bases d'agences). Sur GBIF/iNaturalist, il n'y a pas d'effort, donc pas de « pêches vides ».

Recommandation : **fréquence d'occurrence par HUC8 = nombre d'événements d'échantillonnage où l'espèce est capturée / nombre d'événements d'échantillonnage du HUC8**, calculée par type de milieu (cours d'eau / lac) et par engin quand l'État le permet (électropêche et filets ne capturent pas les mêmes espèces). Seuils de classes (commun / peu commun / rare / légendaire) à définir par quantiles de la distribution des fréquences, à calibrer avec l'État pilote ; ne pas copier les seuils OFB sans test.

Cas particuliers :
- Moins de N échantillons (N à fixer lors du pilote) : classe « donnée insuffisante » plutôt qu'une rareté fausse.
- Espèces grosses/peu capturées par l'engin (muskie, esturgeon) : la fréquence d'occurrence sous-estime la présence. Prévoir un statut « légendaire » basé sur le statut de gestion (espèce trophée) plutôt que sur la fréquence seule.
- Profondeur temporelle : fenêtre glissante (par exemple 10-15 ans) pour éviter les espèces disparues ou les introductions récentes.

---

## 5. Pièges

1. **Biais d'échantillonnage** : les agences ciblent les lacs pêchés et les espèces de gestion ; les cours d'eau peu accessibles sont sous-échantillonnés. NRSA corrige par un plan probabiliste mais avec peu de sites.
2. **Natives vs introduites** : NAS donne le statut introduit, mais « natif » dépend de la rivière (le même poisson peut être natif d'un bassin et introduit dans le voisin). Il faut un champ statut par HUC/État, pas global.
3. **Sportives vs non sportives** : les données d'agences sur lacs sont centrées sur les sportives ; les petites espèces (cyprins, dards) viennent d'électropêche de cours d'eau. Attention à ce que la « rareté » ne reflète pas l'intérêt de gestion. Afficher aussi la catégorie.
4. **Engin** : filet maillant vs électropêche vs seine : fréquences non comparables entre eux.
5. **Taxonomie** : synonymes et noms communs régionaux ; utiliser un identifiant stable (TSN ITIS, déjà employé dans BioData, ou GBIF taxonKey).
6. **Espèces protégées/sensibles** : coordonnées obscurcies ; ne pas afficher de localisation précise de populations menacées (risque de braconnage).
7. **Licence** : le non commercial (FishBase, iNat BY-NC) peut bloquer un modèle payant ; privilégier domaine public et CC0/BY, et conserver les attributions.
8. **Gamification vs gestion** : un poisson « légendaire » dans un lac peut être juste un poisson stocké, d'où la valeur du statut de gestion.

---

## 6. Recommandation d'État pilote

- **Premier choix : Wisconsin.** Longue série d'électropêche accessible via ScienceBase (jusqu'en 2014 pour l'archive ouverte), SWIMS pour le plus récent, bonne densité de cours d'eau et de lacs, forte culture de pêche. Réserve : exiger un identifiant SWIMS et vérifier les droits d'usage.
- **Deuxième choix : Minnesota** (population de pêcheurs très importante, lacs) mais données par PDF à extraire ou demande à la DNR : plus de travail.
- **Repli : Michigan** (portail de données ouvert, CHANGES en CC0), à valider côté contenu des Fish Atlas.
- Éviter pour un premier pilote : Texas (réservoirs, pas de téléchargement public confirmé), Ouest/StreamNet (présence sans fréquence).

Étapes du pilote : (1) télécharger données d'État + NRSA/WQP du même État ; (2) calculer les fréquences par HUC8 et type de milieu ; (3) comparer avec GBIF et NAS pour détecter les anomalies (espèce introduite classée « commune » mais absente de NAS, etc.) ; (4) revue par un biologiste d'agence [?] ; (5) décider des seuils.

---

## 7. À vérifier ensuite
- Contenu exact de la couche Fish Atlas du Michigan et accès aux jeux DNR (WI, MN) ; NY (DEC) et PA (PFBC) non couverts ici.
- Jeu « assemblages de poissons » NRSA dans le zip EPA et campagne 2023-24.
- Licence StreamNet et clé API NAS actuelle.
- Statut des intégrations BioData vers WQP.

---

## Résumé (10 lignes)
1. Pas d'équivalent OFB US : données éclatées entre fédéral, GBIF/iNat et États.
2. Seules NRSA, BioData/WQP et les bases d'agences ont un effort d'échantillonnage.
3. NAS = introduites uniquement (domaine public) ; GBIF/iNat = présence sans effort, licences par ligne.
4. FishBase et le jeu iNat sur GBIF sont BY-NC : risque pour une app commerciale.
5. Unité recommandée : HUC8 avec repli HUC6/État.
6. Définition : fréquence d'occurrence par HUC8 (événements avec l'espèce / événements totaux), par milieu et engin.
7. « % des pêches » faisable seulement avec identifiants d'événements ; sinon classe « donnée insuffisante ».
8. Pièges : biais de ciblage, natif vs introduit, sportive vs non, engins, coordonnées sensibles.
9. Pilote : Wisconsin (repli Michigan, puis Minnesota) ; NY/PA/TX non confirmés.
10. Beaucoup de points [?] à vérifier (licences, accès SWIMS, NRSA assemblages).
