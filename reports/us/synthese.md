# Synthèse : FishMe aux États-Unis, ce que l'étude dit avant d'y aller

Décision débloquée : aller ou non aux USA, avec quel État, quel modèle de règles, quelle rareté, quel modèle de reconnaissance, quelle conformité et quel prix.
Recherche des 6 et 7 nov. 2026. Cette page ne contient aucun chiffre nouveau : chaque chiffre renvoie à un des dix rapports de `reports/us/` (fichier + section). `[?]` = non vérifié dans le rapport source. « Ma reco » = jugement de cette synthèse, pas un fait. Les décisions sont à Adem ; les lignes « par défaut » valent s'il ne tranche pas.

## En deux phrases
Le marché américain est 4 à 5 fois la France (57 M de pêcheurs, `marche-concurrence.md` §1) mais il est saturé en apps sociales et cartes, et le vide « règle sourcée avec verdict prudent » y est un vide de qualité, pas de présence ; surtout, la règle y est par État et souvent par plan d'eau, donc le modèle français espèce × département ne passe pas (`reglementation-cadre.md` §2.3). Ma reco : rester France seule pour le produit publié en 2027, et ne préparer qu'un seul État (Wisconsin) par des lots de données sans engagement de sortie, avec une porte de décision fondée sur les licences obtenues, pas sur la technique.

## 1. Ce qui est solide, ce qui ne l'est pas
Réserve générale : presque tout vient de moteurs de recherche, de presse et d'agrégateurs ; seuls les textes d'Apple ont été lus directement (`conformite-produit.md`, avertissement) et plusieurs sites d'agences ont répondu 403 (`reglementation-etats.md`, Limites ; `reglementation-etats-passe2.md`, Lecture rapide). « Solide » veut donc dire : confirmé par deux rapports ou par une page officielle citée.

### Faits solides
- Le droit de la pêche est étatique ; le fédéral ajoute des couches (refuges, parcs, ESA, Lacey Act) (`reglementation-cadre.md` §0, §1.1, §1.7).
- L'unité de règle est État × plan d'eau ou tronçon × espèce, la règle spéciale l'emporte sur la générale, bag limit et possession limit sont deux valeurs (§2.1, §2.2). Minnesota : plus de 90 plans d'eau à règle spéciale sur le brochet (§2.2).
- Les agences disent que leurs livrets ne sont qu'un guide ; les apps tierces le disent aussi (§4.1).
- Prix de permis eau douce confirmés : NC 32 $ / 56 $, FL 17 $ / 47 $, MI 26 $ / 76 $, VA 28 $ / 72 $ (`reglementation-etats-passe2.md`, Lecture rapide) ; WI 20 $ / 55 $ (même fichier, Tableau).
- Aucun des 10 grands États ne publie, à ce qu'on a trouvé, un jeu ouvert de règles par plan d'eau sous licence claire ; les plus proches sont WI, MI et FL (passe2, Lecture rapide).
- Il n'existe pas d'équivalent de la base OFB ; seuls NRSA, BioData/WQP et les bases d'agences ont un effort d'échantillonnage (`raretes-donnees-poissons.md` §1, §3).
- Aucun jeu ne dit « on peut pêcher ici légalement » ; PAD-US dit si la terre est publique, pas si l'eau est atteignable (`zones-acces.md` §1.3, §1.7).
- USGS retire `waterservices.usgs.gov` ; partir sur `api.waterdata.usgs.gov` (`conditions-donnees.md` §1, §11).
- Apple : règle 1.2 (signaler, bloquer, modérer, contact), 5.1.1(v) suppression de compte, 5.1.5 localisation (`conformite-produit.md` §1.2, §1.3).
- Concurrence : Fishbrain 4,66 / 76 687 notes, Fish Rules 3,89 / 199, onX Fish 4,65 / 1 800 (`marche-concurrence.md` §2) ; 22 avis sur 50 de Fish Rules à 1-2 étoiles, dont des règles fausses (§3, échantillon d'une seule app).

### Points non vérifiés [?] qui comptent
- Licence de réutilisation de presque tous les jeux de règles : à demander par courriel à chaque agence (`reglementation-etats.md`, Limites ; passe2, Reste à faire).
- Droit d'usage du service « règles par lac » du Wisconsin (« © DNR », résumé interprétatif, lacs intérieurs seulement) et accès SWIMS (passe2, fiche WI ; `raretes-donnees-poissons.md` §2.6).
- Dernière année des pêches électriques ouvertes du Wisconsin : 2014 pour l'archive ScienceBase (`raretes-donnees-poissons.md` §2.6).
- Position d'iNaturalist sur l'entraînement commercial depuis son bucket (CGU non lues) (`especes-reconnaissance.md` §2.1).
- Nombre de photos CC0/CC BY des 78 espèces : mesuré sur 15 espèces seulement, via un résumeur (§2.1) ; décompte de la liste lui-même `[?]` (§1).
- Quotas de la clé USGS, part des stations avec température (2 842 sites en 2018 seulement) (`conditions-donnees.md` §2, §13).
- Statut des lois d'État sur les mineurs, applicabilité CCPA, Section 230, traitement de la sales tax par Apple, structure d'entité (`conformite-produit.md` §2.2, §2.3, §3, §1.1, §8).
- Cinq régimes d'accès aux cours d'eau : synthèse de travail, pas une classification juridique (`zones-acces.md` §1.7).
- Reddit, groupes Facebook, CPI propre à la pêche, conversion gratuit-payant : rien de lu (`acquisition-monetisation.md`, Trous).

### Contradictions entre rapports (non tranchées par les rapports)
1. État pilote : Wisconsin d'abord, Minnesota ensuite, Michigan en repli (`raretes-donnees-poissons.md` §6) ; Minnesota candidat principal, choix MN/WI laissé ouvert (`zones-acces.md` §4) ; Californie, Minnesota, Washington, « provisoire » (`reglementation-etats.md`, en-tête et Pistes) ; Wisconsin et Michigan comme plus proches du « règles en données » (passe2, Pour le choix des pilotes). Ce n'est pas un vrai désaccord : chaque rapport juge une couche différente, et la passe 2 n'a pas ré-instruit CA, MN, WA. Mais aucun rapport ne montre un État qui réunit règles, rareté et géographie.
2. Californie : licence CC-BY, dernière modification déc. 2019 (`reglementation-cadre.md` §3.2) contre licence « non lue » (`reglementation-etats.md`, ligne CA) ; la passe 1 la recommande alors que sa donnée peut être périmée.
3. Jeux ouverts « niveau B » : NJ, VT, CA (`reglementation-cadre.md` §3.3) contre WI, MI, FL (passe2, Lecture rapide) ; NJ et VT n'ont jamais été re-testés.
4. Nombre de pêcheurs : 57 M (6 ans et +) / 57,9 M en 2024 / 40 M (USFWS, 16 ans et +) / 31,0 M de permis payants (`marche-concurrence.md` §1) ; 49 M cités de Forbes 2018 (`acquisition-monetisation.md` §5). Ma reco : ne citer que la fourchette 20-30 M adressables, qui est une estimation de ce rapport (§1), et le plancher de 31 M de permis.
5. Volumes de permis par État : année 2021, presse, un permis n'est pas un pêcheur (passe2, Volumes) ; le Minnesota y est absent et vaut environ 1,2 M de licences par an ailleurs (`acquisition-monetisation.md` §3).
6. Prix de permis qui changent d'un passage à l'autre : NC 30 $ « prévu à 32 $ » devenu 32 $ ; VA 12 $/30 $ puis 23 $ puis 28 $/72 $ ; OH 25 $/50,96 $ contre 74 $ au Code ; TN résident inconnu (`reglementation-etats.md` Tableau ; passe2 fiches).
7. Prix des concurrents : Fishbrain 74,99 $/an ou 79,99 $ ; FishAngler 69,99 $ ou 49,99 $ ; Fishidy 49,99 $ sans date (`acquisition-monetisation.md` §1). Surtout : « aucune ne descend sous 49,99 $ » (§1) est contredit par onX Fish à 34,99 $/an (`marche-concurrence.md` §2). La fourchette « 50-80 $ » omet donc le concurrent direct le plus bas.
8. Rareté : le rapport données recommande la fréquence par HUC8 (`raretes-donnees-poissons.md` §4) ; le rapport zones dit de ne pas afficher de rareté en v1 et qu'une « rareté par département » est impossible au national (`zones-acces.md` §2, §4).
9. API USGS : base `/v1` (`conditions-donnees.md` §2) contre `/v0` (`zones-acces.md` §2) ; clé « nécessaire au-delà de quelques requêtes » (conditions §2) contre « facultative » (zones §3) ; dates d'arrêt (22 févr. 2027) venant d'un seul tiers dans les deux (conditions §1 ; zones §2).
10. Licences : le jeu iNaturalist sur GBIF est BY-NC, les photos sont CC BY-NC par défaut mais choisies photo par photo (`raretes-donnees-poissons.md` §2.2 ; `especes-reconnaissance.md` §2.1) ; FishBase est BY-NC alors que son package est CC0 (`raretes-donnees-poissons.md` §2.8) ; NAS est domaine public mais des miroirs affichent CC0 ou CC BY (§2.1). La décision d'Adem du 15 oct. (photos non libres permises pour entraîner, prise pour la France) est antérieure à ce constat et le contredit en partie (`especes-reconnaissance.md` §2.3 ; `CLAUDE.md`).
11. Géolocalisation sensible : 1 850 pieds (CCPA) contre 1 750 pieds (Texas) d'après un résumé, au texte à vérifier (`conformite-produit.md` §2.3).
12. Fish Rules : lien avec Fishbrain « non confirmé » (`reglementation-etats.md`, Agrégateurs) puis rachetée par Fishbrain (`marche-concurrence.md` §2 ; `acquisition-monetisation.md` §1). Les derniers rapports tranchent ; en Floride, la passe 2 hésite encore entre Fish Rules et Fishbrain (passe2, fiche FL).

## 2. Les décisions

### Décision 1 : aller aux USA maintenant, ou rester en France
- Fait : les trois options du rapport marché sont « France seule en 2027 » (la plus prudente), « un État pilote en eau douce », « large via le social » (à éviter) (`marche-concurrence.md` §6).
- Fait : la barrière est le volume de données : 50 États, souvent plan d'eau par plan d'eau, donc l'avantage de rigueur de FishMe devient son coût principal (§5). Aucun canal d'acquisition ne marche sans jeu de données d'État (`acquisition-monetisation.md`, cadrage et §5).
- Fait : le marché recule pour la première fois depuis 2021 et 19 M de pêcheurs ont décroché en 2024-25 (`marche-concurrence.md` §1). onX Fish couvre 13 États avec règles par lac pour 34,99 $/an (§2) ; la liste des États n'est pas dans le rapport [?].
- Recommandation : France d'abord. Pas de version US sur l'App Store en 2027 ; on lance des lots de données sur le Wisconsin (section 3) pour répondre à une seule question : peut-on obtenir des règles par lac avec une licence écrite ? Porte de décision : licence écrite des règles par lac du Wisconsin, plus une relecture réussie sur un échantillon de lacs (taille de l'échantillon à fixer par Adem).
- Change si : MWM finance et veut du volume (alors Texas ou Floride par volume de permis, passe2, Volumes) ; ou si la DNR du Wisconsin refuse la licence (alors Michigan ou rien).
- Option la plus forte écartée : un pilote US publié en 2027 dès que le Wisconsin est lu ; écartée car la France n'est pas encore publiée et que le Midwest est le terrain d'onX Fish [inférence : liste des 13 États non lue].

### Décision 2 : quel État pilote
- Fait : WI a un service de règles par lac, un service d'empoissonnement annuel, un service de points d'accès, 20 $/55 $ et 1 434 816 permis en 2021, mais ses cartes de profondeur sont des PDF (passe2, fiche WI et Volumes ; `zones-acces.md` §1.4, §1.6). Fishidy est née au Wisconsin (`acquisition-monetisation.md` §1).
- Fait : MN a rampes en 3 formats, bathymétrie vecteur d'environ 1 900 lacs et LakeFinder (4 500 lacs), mais le DNR garde le copyright de ses cartes et publie ses relevés de pêche en PDF (`zones-acces.md` §1.2, §1.4 ; `reglementation-etats.md`, ligne MN ; `raretes-donnees-poissons.md` §2.6).
- Fait : MI a un service ArcGIS « DNR Fisheries » fourni « as is » et CHANGES en CC0, mais un contenu à vérifier (passe2, fiche MI ; `raretes-donnees-poissons.md` §2.6).
- Recommandation : Wisconsin, Michigan en repli, Minnesota comme référence de géographie seulement. Raison : la passe 2 a trouvé les points d'accès du Wisconsin, ce qui lève la réserve de `zones-acces.md` §4 ; WI réunit règles par lac, électropêche, empoissonnement et accès, il ne lui manque que la bathymétrie vecteur. Un seul État : pas de fusion de plusieurs.
- Change si : la DNR du Wisconsin ne répond pas ou refuse (Michigan) ; ou si la licence des cartes du Minnesota est levée par courriel, car MN a la meilleure géographie.
- Option la plus forte écartée : Californie, Minnesota, Washington, la reco provisoire de la passe 1 ; la donnée californienne date peut-être de 2019 (`reglementation-cadre.md` §3.2), Washington n'a pas de données ouvertes confirmées et une appli officielle à 4,33 / 6 961 notes (`reglementation-etats.md` Pistes ; `marche-concurrence.md` §2).

### Décision 3 : modèle de règles par plan d'eau et verdict
- Fait : l'unité française casse sur cinq points : plan d'eau, tronçon, comté ou zone, frontière à deux États, propriété (refuge, parc, tribu) (`reglementation-cadre.md` §2.3).
- Fait : les agences portent des exceptions au livret annuel et les corrigent en cours de saison (Texas mi-août, accord Kentucky suspendu puis rétabli) (§2.2, §4.2).
- Recommandation : un scope hiérarchique État → zone → plan d'eau → tronçon, avec les entités Jurisdiction, Water (identifiant NHD ou 3DHP), Segment, Rule (bag et possession séparés, priorité du plus spécifique), Requirement (licence, timbres, permis tribal), FreeDay, Reciprocity, Source (URL, édition, date, hash, licence) (`reglementation-cadre.md` §5.1 ; `zones-acces.md` §1.1).
- Recommandation : verdict à trois valeurs seulement, « interdit ou fermé (sourcé) » / « règles connues, à vérifier » / « données absentes », jamais « permis » ; règle périmée ou en conflit : on descend à « à vérifier » (`reglementation-cadre.md` §5.2, §4.3). Alerte forte sur eaux tribales, refuges, parcs, eaux frontalières, espèces ESA (§4.3). Ma reco : « interdit » s'affiche comme l'état de tête « Il faut relâcher », les deux autres valeurs comme l'état « Voir la réglementation » de la décision 10 du 19 oct. (`CLAUDE.md`).
- Recommandation : les jours gratuits viennent de l'agence seulement, les agrégateurs divergent (`reglementation-cadre.md` §2.1). Aucun feu vert sur l'accès légal ; les cinq régimes d'accès restent hors de l'app (`zones-acces.md` §1.7).
- Change si : la licence du service wisconsinien est refusée (alors lecture IA de PDF, comme pour les arrêtés français, `reglementation-etats-passe2.md`, Lecture rapide).
- Option la plus forte écartée : un verdict par poisson et par lieu partout (niveau C) ; non réaliste sans accord de données et contraire à la prudence juridique (`reglementation-cadre.md` §3.3).

### Décision 4 : la rareté américaine
- Fait : « % des pêches où l'espèce est trouvée » n'est faisable que sur des données avec identifiant d'événement (NRSA, BioData/WQP, agences) ; GBIF et iNaturalist n'ont pas d'effort (`raretes-donnees-poissons.md` §4.2).
- Fait : pièges : biais de ciblage, engins non comparables, natif contre introduit par bassin, poisson stocké pris pour rare, coordonnées d'espèces sensibles (§5).
- Recommandation : définir dès maintenant la fréquence d'occurrence par HUC8 (événements avec l'espèce ÷ événements du HUC8), par milieu et par engin, avec repli HUC6, HUC4 puis État annoncé à l'écran, classe « donnée insuffisante » sous N événements (N à fixer au pilote), seuils par quantiles et jamais les seuils OFB sans test, fenêtre glissante de 10-15 ans, « légendaire » par statut de gestion (§4.1, §4.2). Ma reco pour concilier les deux rapports : ne l'afficher qu'après le pilote et la revue d'un biologiste d'agence ; en attendant, afficher présence connue, nombre d'événements, dernière année (la règle de `CLAUDE.md`) et statut introduit (NAS).
- Change si : la série du Wisconsin s'arrête vraiment en 2014 (`raretes-donnees-poissons.md` §2.6) : alors pas de rareté, seulement présence.
- Option la plus forte écartée : compter les observations GBIF et iNaturalist, la voie facile ; pas d'effort, biais d'observateur, licence BY-NC (`raretes-donnees-poissons.md` §2.2, §2.3).

### Décision 5 : reconnaissance et licences des photos
- Fait : 13 classes européennes sont la même espèce que des espèces américaines ; sandre, perche et black-bass ont des sœurs proches mais différentes ; bluegill, crappies, catfish, gars, muskie n'ont rien (`especes-reconnaissance.md` §1). Liste proposée : 78 espèces ou hybrides (§1, noms latins à faire relire [?]).
- Fait : avec seulement CC0 et CC BY il reste environ 5 à 10 % des observations iNaturalist : bluegill 4 695, largemouth 2 212, lake trout 45, bowfin 51 (§2.1, lu via un résumeur). Les photos de terrain donnaient 47,9 % de top-1 contre 82,5 % sur prises de pêcheurs (§2.1, cité de `reports/etat/reconnaissance.md`).
- Recommandation : un tronc DINOv2-small partagé et une tête par région (tête Europe inchangée, tête US de 78 espèces plus « autre poisson » et « pas un poisson »), environ 30 Ko par tête (calcul à refaire), 30 Mo au plus (§5). Démo à 6 espèces : largemouth bass, bluegill, channel catfish, rainbow trout, walleye, northern pike (§5).
- Recommandation : photos par le bucket AWS, jamais l'API ; noyau d'entraînement CC0 + CC BY seulement ; CC BY-NC seulement après un avis écrit d'Adem et la réponse d'iNaturalist ; publication (cartes, fiche) : domaine public, CC0, CC BY ; écrire à help@inaturalist.org (§2.1, §2.3). Examen avant embarquement : découpage par observateur, au moins le niveau européen de 82,5 % top-1 et 91,6 % top-3 sur prises de pêcheurs (proposition du rapport, §5).
- Change si : iNaturalist répond que son bucket est régi par la licence des seules photos (alors CC BY-NC reste à arbitrer), ou si Adem maintient sa décision du 15 oct. pour les États-Unis.
- Option la plus forte écartée : un modèle mondial à une seule tête, ou deux modèles complets (44 Mo pour une limite de 30 Mo) ; et les API (iNaturalist réservé, Fishial sans conditions lues, Fishbrain fermé) (`especes-reconnaissance.md` §4, §5).

### Décision 6 : conformité
- Fait : COPPA amendée, conformité complète depuis le 22 avr. 2026 ; piège de la « connaissance effective » d'un enfant (`conformite-produit.md` §2.1). Les lois d'État sur les mineurs sont toutes litigieuses : Californie, Virginie, Arkansas, Texas (§2.2). La géolocalisation précise est une donnée sensible (§2.3).
- Fait : chaque surface (post, commentaire, message, club, profil) exige signaler, bloquer, modérer ; un agent DMCA est à désigner (frais cités de 6 $, 3 ans, sources de 2016-2020) (§1.2, §3).
- Recommandation : le minimum du rapport : app 13+, écran d'âge neutre, pas de compte sous 13 ans, Declared Age Range API si disponible, politique de confidentialité et suppression de compte, localisation seulement pendant l'usage, EXIF retiré, App Privacy incluant les SDK (dont Spark de MWM, à qualifier en « vente ou partage » [?]), agent DMCA, langage prudent (`conformite-produit.md` §9, §6). Un juriste américain relit la liste du §8 avant toute soumission.
- Recommandation (ma reco, à décider) : au pilote, ni fil public ni chat, donc carte, règles, conditions, prise et carnet privé ; le social ajoute modération, DMCA et exposition COPPA pour un gain d'acquisition que le rapport ne mesure pas (`conformite-produit.md` §1.2, §3 ; `marche-concurrence.md` §6, fonctions « à valider avec des pêcheurs américains »).
- Change si : le juriste valide la modération minimale de la décision 5 du 19 oct. (`CLAUDE.md`) pour les États-Unis ; ou si le réseau social sort en France avant le pilote.
- Option la plus forte écartée : lancer avec le réseau social complet comme en France ; chaque surface devient une obligation de modération (§1.2).

### Décision 7 : vente de permis
- Fait : les licences sont vendues par des prestataires qui appartiennent aux agences (Aspira, Brandt, PayIt/Sovereign) ; aucune app tierce lue n'encaisse de commission, aucun revenu partagé public trouvé (`acquisition-monetisation.md` §3). Vendre suppose un agrément État par État (`conformite-produit.md` §5).
- Recommandation : non, ni au pilote ni avant d'avoir des utilisateurs ; lien profond vers le site ou l'app officiels de l'État, sans écrire que FishMe « vend » ou « garantit » un permis (`conformite-produit.md` §5, §9). Pas de pitch aux prestataires avant d'avoir de la base (`acquisition-monetisation.md`, À ne pas faire).
- Change si : un prestataire propose un cadeau d'abonnement ou un revenu partagé, comme Fishbrain × Aspira en 2022 (offre non confirmée après) (`acquisition-monetisation.md` §2 canal 1).
- Option la plus forte écartée : devenir revendeur agréé de la DNR du Wisconsin ; frais plafonnés (NC 4 $, LA 2 $) et paiement externe à Apple non vérifié [?] (`conformite-produit.md` §5).

### Décision 8 : conditions (USGS, NOAA, WeatherKit)
- Fait : base `api.waterdata.usgs.gov` (OGC API), collections `continuous` et `latest-continuous`, codes 00060 débit et 00065 hauteur ; 12 165 stations en 2024 ; température seulement sur une partie des stations (`conditions-donnees.md` §2).
- Fait : une clé unique embarquée serait partagée par tous les utilisateurs, sans clé erreurs 429 (§2). Crue : NWPS ; alertes : api.weather.gov avec en-tête User-Agent ; WeatherKit : 500 000 appels/mois inclus (§4, §5, §8).
- Recommandation : petit proxy avec cache et clé côté serveur, qui ne reçoit qu'un identifiant de station, jamais la position du pêcheur (`conditions-donnees.md` §2 ; `reglementation-cadre.md` §4.3). Ma reco : un Worker Cloudflare, déjà utilisé pour la liste d'attente (`CLAUDE.md`). Station sans température : afficher la plus proche avec sa distance ; données provisoires marquées ; unités impériales, fuseau du point de pêche (`conditions-donnees.md` §2, §10, §11).
- Change si : les quotas publiés de la clé sont trop bas pour le cache (non publiés [?], §2) ; ou si WeatherKit ne renvoie pas les alertes américaines pour un point (à tester, §8).
- Option la plus forte écartée : appeler `waterservices.usgs.gov` en attendant ; retrait annoncé, dates précises d'un seul tiers (§1).

### Décision 9 : prix et acquisition
- Fait : onX Fish 34,99 $/an, Fishidy 49,99 $, FishAngler 49,99 $ ou 69,99 $, Fishbrain 74,99 $ ou 79,99 $ ; tous sont freemium (`marche-concurrence.md` §2 ; `acquisition-monetisation.md` §1, §3). Les Américains détestent qu'on retire le gratuit (Navionics) (`marche-concurrence.md` §3). Fishbrain se justifie par « un sondeur dans la poche » (`acquisition-monetisation.md` §3).
- Fait : le coût d'installation médian « Sports » est de 26,70 $ [?] sur Apple Ads US, sans valeur propre à la pêche (`acquisition-monetisation.md` §2 canal 8). La boutique et l'affiliation n'ont pas converti chez Fishbrain (§2 canal 10, §3).
- Recommandation : même structure qu'en France (règles et carte gratuites, un spot gratuit) ; annuel à 34,99 $, le niveau d'onX Fish, parce qu'une seule couverture d'État ne justifie pas 50-80 $ face à Fishbrain à 30+ États ; mensuel non fixé. Prix à régler dans App Store Connect, inscription au Small Business Program avant le lancement (`conformite-produit.md` §1.1).
- Recommandation : acquisition sans budget : référencement « où pêcher dans le Wisconsin » avec jour gratuit ; un tournoi ou club local sans outil officiel ; un courrier à la DNR et à RBFF contre données anonymisées sur le modèle iFish Forever (33 000 $ du Minnesota) ; pas de pub payante ni d'affiliation (`acquisition-monetisation.md`, Recommandation et À ne pas faire).
- Change si : MWM finance (alors test Apple Ads plafonné après mesure) ; ou si le pilote montre moins de couverture que onX Fish sur le Wisconsin, auquel cas gratuit.
- Option la plus forte écartée : se placer à 49,99-79,99 $ comme Fishidy et Fishbrain (`acquisition-monetisation.md`, À ne pas faire dit « sous Fishbrain, niveau Fishidy ») ; écartée car onX Fish, le concurrent direct, est à 34,99 $ (`marche-concurrence.md` §2).

## 3. Ce qu'il faudrait construire (lots proposés, aucun créé)
Format de `docs/lots.md`. Codes provisoires US0 à US11, dossiers proposés ; durées en jours de travail d'une personne avec Claude, estimation de cette synthèse, non mesurée. Les délais de réponse des agences ne sont pas comptés.
| Lot | Dossier | Dépend de | Durée (estimation) |
|---|---|---|---|
| US0 Courriels et avis juridique : DNR du Wisconsin (licence règles, SWIMS, accès), DNR du Minnesota (copyright), iNaturalist, juriste US (liste de `conformite-produit.md` §8) | `reports/us/courriers/` | décisions 1, 2, 5 | 2 j de rédaction, réponses incertaines |
| US1 Banc de données Wisconsin : mesurer fraîcheur, champs et licence des services de règles, d'empoissonnement, d'accès, d'électropêche | `outils/us/wi/` | US0 | 3 à 5 j |
| US2 Modèle de règles et verdict à trois valeurs (Core, tests Linux) | `Packages/Core/Sources/Core/ReglesUS/` | contrats existants (C0) | 4 à 7 j |
| US3 Pipeline des règles du Wisconsin (service ou lecture IA de PDF, deux lectures, consensus) puis relecture | `outils/us/regles/` | US1, US2 | 6 à 10 j, relecture comprise |
| US4 Socle géographique d'un État : NHDPlus HR ou 3DHP, PAD-US filtré, accès, avis EPA avec date | `outils/us/geo/` | US1 | 4 à 7 j |
| US5 Conditions : proxy USGS avec cache et clé, NWPS, api.weather.gov, WeatherKit, unités et fuseau | `outils/us/proxy/` et `Packages/Core/Sources/Core/ConditionsUS/` | clé api.data.gov | 5 à 8 j |
| US6 Rareté HUC8 pilote : événements, fréquences, seuils par quantiles, comparaison NAS et GBIF | `outils/us/rarete/` | US1, limites WBD | 5 à 8 j, plus revue d'un biologiste |
| US7 Comptage des photos CC0/CC BY des 78 espèces par le bucket | `outils/us/photos/` | avis d'iNaturalist (US0) | 2 à 3 j |
| US8 Tête US de reconnaissance (6 espèces puis 78), examen par observateur | `outils/reconnaissance/` (lot R1 existant) | US7, modèle R1 | 1 à 2 semaines (R1 France : 40 à 75 h, `docs/lots.md`) |
| US9 Localisation US : anglais, unités, dates, vocabulaire sans « legal » ni « allowed » | `App/` (dossier par lot) | lots d'écrans France | 5 à 8 j |
| US10 Conformité du pilote : 13+, âge, DMCA, politique, App Privacy | `docs/legal/` | US0 (avis juridique) | 3 à 5 j |
| US11 Fiche App Store US, prix et mesure du pilote (installations, rétention) | `docs/app-store.md` | S1, US10 | 2 j |

## 4. Les trous de recherche qui restent
- Licences écrites de toutes les sources de règles ; aucune lue en direct (`reglementation-etats.md`, Limites).
- Minnesota, Californie et Washington jamais ré-instruits en passe 2 ; OH, GA, TN, MO, AL, ID, UT presque vides (`reglementation-etats.md`, Tableau). NY et PA absents de l'étude des relevés (`raretes-donnees-poissons.md` §7).
- Volumes de permis par État de l'USFWS (WSFR en 403), à la place des chiffres 2021 de presse (passe2, Reste à faire).
- Liste des États d'onX Fish et couverture de ses règles par lac ; avis de Fishbrain, Reddit, Fishing Points, Fishidy non lus (`marche-concurrence.md` §2, §7).
- Pêcheurs américains jamais interrogés : carte à collectionner, clubs et rareté sont « à valider » (`marche-concurrence.md` §6).
- Jeu « assemblages de poissons » de NRSA, licence StreamNet, clé NAS, dernières années des séries d'État (`raretes-donnees-poissons.md` §7).
- Tailles de téléchargement des couches géographiques ; forêts nationales, ESA, invasives par État, polygones des réserves tribales (`zones-acces.md` §3 ; `reglementation-cadre.md` §5.4).
- Photos de pêcheurs en licence libre pour le jeu de test : aucune ; opt-in ou relecture manuelle (`especes-reconnaissance.md` §5).
- Taux de conversion gratuit-payant, CPI propre à la pêche, état de l'offre Fishbrain × Aspira (`acquisition-monetisation.md`, Trous).
- Texte des lois : COPPA et politique FTC de févr. 2026, Section 230, CCPA, Paid Applications Agreement (`conformite-produit.md` §2, §3, §1.1).
