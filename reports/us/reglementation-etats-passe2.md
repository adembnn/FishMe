# FishMe US : règles d'eau douce, 2e passe (TX, FL, NY, MI, WI, OH, NC, GA, VA, TN)

Date : 7 nov. 2026. Complète `reglementation-etats.md` (6 nov.).

**Décision débloquée : choisir les États pilotes US sur des faits (prix réel du permis, volume de pêcheurs, format des règles, licence des données) pour 10 grands États, et savoir lesquels peuvent se traiter en données ouvertes plutôt qu'en lecture IA de PDF.**

## Lecture rapide

- Aucun des 10 États ne publie, à ce que j'ai trouvé, un jeu ouvert « règles de pêche par plan d'eau » sous licence claire. Les plus proches : Wisconsin (service cartographique des règles par lac), Michigan (service ArcGIS « DNR Fisheries »), Floride (zones de gestion des poissons, environ 80 plans d'eau).
- Le reste est PDF annuel ou site interactif. La lecture IA de PDF reste donc le chemin par défaut aux États-Unis, avec le même principe : verdict jamais permissif.
- Les prix du 1er passage sont en partie corrigés : NC 32 $ / 56 $ (confirmé), VA 28 $ / 72 $ (officiel, les 12 $ / 30 $ du Code et les 23 $ de l'agrégateur sont périmés), FL 17 $ / 47 $ (confirmé), MI 26 $ / 76 $ (confirmé).
- Réutilisation : eRegulations (WA, IN, GA, OH, WI, NC, TN, FL...) porte « © eRegulations, All Rights Reserved » (https://www.eregulations.com/texas/fishing/freshwater). C'est un éditeur privé : ne pas reprendre son texte, aller à l'agence.
- Méthode : l'accès direct aux agences a donné 403 pour myfwc.com (règles), michigan.gov (règles) et tn.gov (prix). Contournements : eRegulations pour les prix FL et TN, communiqué officiel MI (govdelivery), requêtes de recherche pour le reste. Archive.org est bloqué dans cet outil (non utilisé).

## Tableau

Prix : annuel pêche en eau douce, adulte, année en cours.

| État | Agence | Rés. / non-rés. | Format règles | MàJ | Appli officielle | Données ouvertes ? |
|---|---|---|---|---|---|---|
| TX | TPWD | 30 $ / 58 $ | site Outdoor Annual + appli | permis au 31 août ; règles [?] | Outdoor Annual | aucune trouvée [?] |
| FL | FWC | 17 $ / 47 $ | site + livret ; appli tierce | [?] | Fish Rules (partenariat 2020) [?] | FMA (ArcGIS), attribution demandée |
| NY | DEC | 25 $ / 50 $ | guide PDF + HuntFishNY | [?] | HuntFishNY | jeu data.ny.gov, licence « non spécifiée » |
| MI | DNR | 26 $ + 1 $ / 76 $ + 1 $ | site + PDF + cartes truite | 1er avr. au 31 mars | Hunt Fish | service ArcGIS DNR Fisheries |
| WI | DNR | 20 $ / 55 $ | PDF 2026-27 + outil lacs | saison 2026-27 | Fishing Finder (web) | service lacs, droit « © DNR » |
| OH | ODNR | 25 $ / 50,96 $ | PDF + HuntFish OH | 1er mars au 28 févr. | HuntFish OH | lacs : couche interne [?] |
| NC | NCWRC | 32 $ / 56 $ | PDF / FlippingBook | 1er août au 31 juil. | Go Outdoors NC | carte d'accès, pas de hub trouvé |
| GA | GA DNR WRD | 15 $ / 50 $ | guide PDF | 1er juil. au 30 juin | Outdoors GA | aucune trouvée |
| VA | DWR | 28 $ / 72 $ | PDF + site | biennale, 1er janv. 2027 | Go Outdoors VA | ArcGIS, sur permission |
| TN | TWRA | résident [?] / 49 $ ou 98 $ | guide PDF | 2026-27 | TWRA On the Go | ArcGIS, « display only » |

## Volumes de permis payants (USFWS, année 2021, relayés par la presse)

TX 2 099 153 ; FL 1 743 139 ; NC 1 487 575 ; WI 1 434 816 ; MI 1 190 933 ; GA 1 083 120 ; TN 923 447 ; NY 911 677 ; OH 909 854 ; VA 595 755. Source : https://247wallst.com/special-report/2024/01/29/states-where-the-most-people-fish/ (article de presse, pas la table USFWS). Limite : un permis payant n'est pas un pêcheur (les non-résidents et les doubles comptes y sont). Source primaire : tableaux de bord WSFR, https://www.fws.gov/story/2022-10/new-dashboards-make-decades-license-and-apportionment-data-more-accessible (non ouverts, 403 sur le site wsfrprograms). Total national 2024 : environ 31 millions (Statista, non vérifié [?]).

## Fiches

**TX (Texas Parks and Wildlife).** Règles dans le site « Outdoor Annual » et l'appli officielle gratuite iOS et Android, avec les exceptions par plan d'eau (https://tpwd.texas.gov/regulations/outdoor-annual/app/). Permis : forfait eau douce 30 $ (résident) et 58 $ (non-résident), valable jusqu'au 31 août ; tout-eaux 40 $ et 68 $ (https://tpwd.texas.gov/regulations/outdoor-annual/licenses/fishing-licenses-stamps-tags-packages/fishing-licenses-and-packages/). Fréquence de mise à jour de l'appli : non dite. Données ouvertes : rien trouvé ; adresse de contact OutdoorAnnual@tpwd.texas.gov (page de l'appli). Licence : [?]. Premier marché en volume, mais sans source machine-lisible : IA sur site.

**FL (FWC).** Prix 17 $ / 47 $, 79 $ pour 5 ans résident (https://www.eregulations.com/florida/fishing/freshwater/licenses, mis à jour le 20 juil. 2026). Page règles du FWC en 403 ; elle signale l'appli Fish Rules (communiqué 2020, https://content.govdelivery.com/accounts/FLFFWCC/bulletins/29ceb4f), mais une autre version de la page cite Fishbrain : à confirmer [?]. Zones de gestion (environ 80 plans d'eau, règles spéciales) publiées en couche ouverte : https://gis.myfwc.com/hosting/rest/services/Open_Data/Fish_Management_Areas_Florida/MapServer ; le service voisin demande qu'on cite le FWC-FWRI comme source (https://atoll.floridamarine.org/arcgis/rest/services/FWC_GIS/OpenData_Boating/FeatureServer/1), ce n'est pas une dédicace au domaine public. Les limites de la couche sont « une carte de référence générale ». Le texte de loi fait foi (FLRules.org).

**NY (DEC).** Prix 25 $ (16 à 69 ans), 5 $ à partir de 70 ans, 50 $ non-résident ; 7 jours 12 $ / 28 $ ; 1 jour 5 $ / 10 $ (http://dec.ny.gov/regulatory/permits-licenses/sporting-and-use/sporting/fishing-license). Règles : guide PDF (https://extapps.dec.ny.gov/docs/fish_marine_pdf/fishguide.pdf, PDF non lu : binaire illisible par l'outil, édition [?]) et appli HuntFishNY, qui contient la fonction Tackle Box (règles, empoissonnement, accès) ; compte DECALS requis (https://dec.ny.gov/get-involved/huntfishny-mobile-app et https://wyrk.com/tackle-box-ny/). Open data : jeu « Recommended Fishing Rivers and Streams », CSV/JSON, modifié le 16 janv. 2025, licence « non spécifiée » (https://data.amerigeoss.org/dataset/recommended-fishing-rivers-and-streams, source data.ny.gov/d/jcxg-7gnm) ; il ne s'agit pas des règles du guide. L'empoissonnement est aussi en open data (même licence non précisée).

**MI (DNR).** Prix 26 $ + 1 $ de frais / 76 $ + 1 $ ; senior 11 $ ; valables jusqu'au 31 mars 2027 ; appli Hunt Fish (https://content.govdelivery.com/accounts/MIDNR/bulletins/40c40a7, 2 mars 2026). Règles 2026 : guide en ligne et cartes truite/saumon, du 1er avril 2026 au 31 mars 2027, avec une erreur d'impression corrigée dans la version numérique (https://www.michigan.gov/dnr/about/newsroom/releases/2026/04/01/2026-fishing-season-opens-wednesday ; page règles en 403). Données : service ArcGIS « DNR Fisheries » (https://services3.arcgis.com/Jdnp1TjADvSDxMAX/ArcGIS/rest/services/DNRFisheriesDataOPENDATA/FeatureServer) et couche de règles truite/saumon ; la couche « Blue Ribbon » est dépréciée (https://geo.btaa.org/catalog/f008b72be87648f496f7f956c649e6d9_2). Fournies « as is ». Licence exacte : [?]. Meilleur candidat « règles en données » avec WI.

**WI (DNR).** Prix 20 $ / 55 $ (https://www.eregulations.com/wisconsin/fishing/fishing-licenses-and-fees, 24 avr. 2025 ; année de permis du 1er avril : [?], agrégateur seulement). Règles : guides PDF 2026-27 (pêche à la ligne, truite, etc.) et outil « Online Fishing Regulations » (lacs, par nom ou comté, avec carte) ; appli : l'outil web Wisconsin Fishing Finder, appli mobile officielle [?] (https://dnr.wisconsin.gov/topic/Fishing/regulations). Pied de page « © Wisconsin Department of Natural Resources », pas de politique de données ouvertes lue. Services cartographiques : règles par lac (https://dnrmaps.wi.gov/arcgis2/rest/services/FM_WFF/FM_WFF_LAKE_REGULATIONS_WTM_EXT/MapServer/info/iteminfo), points d'accès (copyright « DNR », https://dnrmaps.wi.gov/arcgis2/rest/services/PR_Recreation/PR_Boat_Access_Shore_Fishing_WTM_Ext/MapServer), règles truite par comté sur data-wi-dnr.opendata.arcgis.com. Le service des lacs se présente comme un résumé interprétatif des règles, limité aux lacs intérieurs (même recherche). Le portail wsfr était injoignable (connexion refusée) pour le statut.

**OH (ODNR).** Prix résident 25 $ (1 an), senior 10 $, non-résident 50,96 $, valable 365 jours (https://www.eregulations.com/ohio/fishing/licenses-fees, 7 avr. 2025). Attention : le Code de l'Ohio 1533.32 cité dans la recherche donne d'autres montants (non-résident 74 $) ; conflit non tranché [?]. Règles : PDF annuel du 1er mars au 28 février (2025-26 vu, 2026-27 annoncé) et appli HuntFish OH (https://dam.assets.ohio.gov/image/upload/ohiodnr.gov/documents/wildlife/laws-regs-licenses/Ohio%20Fishing%20Regulations%20ENGLISH.pdf). Open data : le portail DataOhio (mot-clé « Fish ») héberge empoissonnements et tableaux de bord ; la couche de lacs du serveur ODNR est marquée usage interne (https://gis.ohiodnr.gov/arcgis/rest/services/OIT_Services/DNR_Fed_Lands_Nav_Base/MapServer/layers). Licence : [?].

**NC (NCWRC).** Prix 32 $ / 56 $ (https://www.eregulations.com/northcarolina/fishing/fishing-licenses, 13 juil. 2026). Cela tranche la hausse « proposée » du 1er passage : elle est en vigueur. Règles : digest 2026-27 en PDF et FlippingBook, du 1er août 2026 au 31 juil. 2027 (https://www.eregulations.com/assets/docs/guides/26NCAB_LR2_2026-07-28-191846_hsin.pdf). Appli officielle Go Outdoors North Carolina, gratuite, avec règlements (https://apps.apple.com/app/id6443992281). Carte interactive des accès : export de données possible pour les attracteurs de poissons, WGS84 (https://www.ncwildlife.gov/fishing/wheretofish, page lue par recherche, non ouverte). Hub open data : non trouvé. Licence : [?].

**GA (DNR, Wildlife Resources Division).** Prix 15 $ (16 à 64 ans) / 50 $ (https://www.eRegulations.com/georgia/fishing/recreational-fishing-license-fees, 27 août 2026 ; le Code de Géorgie 27-2-23 concorde, https://law.justia.com/codes/georgia/2021/title-27/chapter-2/article-1/section-27-2-23/). Guide chasse et pêche 2026-27 effectif du 1er juil. 2026 au 30 juin 2027, en ligne et imprimé (https://gadnr.org/summer-reading-list-2026-2027-georgia-hunting-fishing-regulations). Appli Outdoors GA (permis et règles de chasse, gratuite) ; couverture des règles de pêche dans l'appli [?] (https://albanyherald.com/local-2/state-dnr-adds-another-tool-to-outdoors-toolboxes/). Données ouvertes : rien trouvé pour la WRD (les services ArcGIS repérés sont de la division côtière). Licence : [?]. Le permis est le moins cher du lot.

**VA (DWR).** Prix officiels : 28 $ résident, 72 $ non-résident ; truite des eaux empoissonnées en plus : 28 $ / 48 $ (https://dwr.virginia.gov/fishing/regulations/licenses/, sans date d'entrée en vigueur). Règles : PDF 2026 (truite, limites de prise) ; beaucoup de plans d'eau ont des règles affichées sur place ; prochain train de changements au 1er janv. 2027 (https://dwr.virginia.gov/blog/2026-fishing-boating-and-nongame-endangered-species-regulations-scoping-period/). Appli Go Outdoors VA, gratuite, achat et synchronisation de permis (https://dwr.virginia.gov/app/). Données : couche ArcGIS « Public Fishing Lakes » ; accès limité aux entités ayant la permission de l'agence, citation obligatoire, publication 2008, mise à jour « au besoin » (https://services.dwr.virginia.gov/arcgis/rest/services/HUB_Layers/DWR_Public_Fishing_Lakes/MapServer/0/metadata). Donc non réutilisable sans accord écrit.

**TN (TWRA).** Prix non-résident : 49 $ sans truite, 98 $ toutes espèces ; résident : pas de permis de pêche seule dans le tableau lu, seulement le Sportsman 165 $ (16-64 ans), 49 $ senior, et le supplément truite 21 $ (https://www.eregulations.com/tennessee/fishing/license-fees, 10 sept. 2026). Le prix du permis de pêche résident reste [?] (tn.gov en 403 ; chiffres 33-34 $ relevés chez des tiers). Guide 2026-27 en PDF avec « exceptions aux règles de pêche par plan d'eau » et copyright sans reproduction sans accord écrit (https://campbell.isportsman.net/files/TWRA-TN-Hunting-Guide_26-27.pdf, copie hébergée par un tiers). Appli officielle TWRA On the Go (https://apps.apple.com/us/app/-/id757097014) ; partenariat avec Hunt Regs pour la recherche de règles (https://www.wbbjtv.com/?p=2687139). Données : service ArcGIS TWRA (lacs, accès, WMA), fournies « pour affichage » seulement, sans garantie (https://tnmap.tn.gov/ArcGIS/rest/services/ENVIRONMENTAL/TWRA/MapServer).

## Pour le choix des pilotes

1. Données les plus proches de l'usage : WI (règles par lac en service cartographique) et MI (service Fisheries). Licence à écrire à l'agence avant tout usage commercial.
2. Volume : TX, FL, NC en tête ; FL a des zones spéciales en couche ouverte, TX non.
3. Prix : GA (15 $) et FL (17 $) font peu de valeur par permis ; VA, TN, MI, WI, NC plus élevés pour les non-résidents.
4. Concurrence officielle : toutes les 10 agences ont une appli, souvent seulement permis et règles de base.

## Reste à faire

- TN : prix résident officiel ; OH : conflit Code / eRegulations.
- Lire la licence de chaque service ArcGIS (WI, MI, FL) et écrire aux agences (TX, GA, NC, OH).
- Obtenir le tableau USFWS par État (WSFR, 403 ici), pour remplacer les chiffres 2021 de presse.
- Ouvrir le guide PDF de NY et celui de MI (illisibles ou en 403 dans cette passe).
