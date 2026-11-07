# FishMe USA — Cadre juridique et forme des règles de pêche

Décision débloquée : choisir si FishMe US vise un « verdict de conservation par plan d'eau » (granularité réaliste seulement État par État, avec des sources hétérogènes) ou un MVP « carte + fiche de règles par État + lien officiel », sans verdict « tu peux garder ce poisson ».

Date de recherche : 6 nov. 2026. Méthode : recherches web (WebSearch) sans lecture intégrale des textes de loi ; beaucoup de sources secondaires, signalées. [?] = non vérifié.

## 0. Résumé en 6 points
- La pêche récréative en eau douce est régie par chaque État ; le fédéral n'ajoute que des couches (refuges, parcs, espèces listées, interdictions de transport d'espèces invasives). Le « modèle espèce × département » français n'a pas d'équivalent national.
- L'unité réelle de règle aux USA est souvent « État × plan d'eau (ou tronçon) × espèce », avec des exceptions qui l'emportent sur la règle générale.
- Un verdict « permissif » (« tu peux garder ») exigerait ce niveau de détail, la saison, le permis, le timbre et l'ensemble des fermetures. Réaliste seulement pour quelques États pilotes avec données ouvertes.
- Les agences elles-mêmes écrivent que leurs livrets ne sont qu'un guide. Une app tierce hérite du même risque, sans l'autorité.
- Le principe français « jamais permissif » doit devenir : afficher des règles, jamais un feu vert.
- Recommandation : démarrer par 2 à 3 États pilotes, modèle de données à 3 niveaux (État / zone / plan d'eau-tronçon) et verdict limité à « interdit / à vérifier ».

## 1. Qui fait la loi

### 1.1 États : source principale
- Le droit de la pêche est étatique. Exemple : Wisconsin a un code administratif dédié par thème (chap. NR 23 pour les eaux frontalières) https://docs.legis.wisconsin.gov/code/admin_code/nr/001/23
- Même pour les terres fédérales, la règle fédérale renvoie en général à l'État : pour les refuges (NWR), 50 CFR 32.5 impose la licence d'État requise en plus des règles du refuge https://chanrobles.com/usa/uslaws/cfr/title50/50-6.0.1.2.15.1.1.5.php (miroir non officiel ; texte eCFR à confirmer [?]).
- Les refuges de pêche suivent les lois de pêche de leur État et ajoutent leurs règles propres https://www.fws.gov/refuge/shawangunk-grasslands/visit-us/activities/fishing ; exemple : National Elk Refuge (Wyoming) exige licence d'État plus conservation stamp pour les titulaires de licence annuelle (même résultat de recherche, page non ouverte [?]).

### 1.2 Permis obligatoire
- Une licence d'État est requise en pratique presque partout (refuges : https://www.fws.gov/refuge/shawangunk-grasslands/visit-us/activities/fishing). Exceptions : enfants (seuil d'âge variable, p. ex. moins de 16 ans dans certains parcs, https://home.nps.gov/goga/planyourvisit/fishing.htm), seniors, vétérans, pontons précis (Fort Baker, https://www.nps.gov/thingstodo/fort-baker-fishing.htm).
- Seuils d'âge et conditions de résidence : variables par État [?] (non compilé).

### 1.3 Timbres et permis additionnels
- Pennsylvanie : permis truite distinct (14,97 $) et permis Lac Érié (9,97 $) pour 16 ans et plus, d'après la page officielle pa.gov https://pa.gov/agencies/fishandboat/fishing/buy-fishing-license-permit.html (tarifs cités par la recherche, page non rouverte [?]).
- Washington : carte de capture (catch record card) obligatoire pour saumon, esturgeon, flétan, steelhead https://wdfw.wa.gov/licensing/fishing.html
- Wyoming : conservation stamp (voir 1.1).
- Conséquence : le modèle doit porter des « exigences d'accès » (licence + timbres) séparées des règles de capture.

### 1.4 Eaux tribales
- La licence d'État n'est généralement pas valable en eaux de réserve ; il faut le permis de la tribu. Cas judiciaires : United States v. Pollmann (lac Flathead, Montana) https://law.counselstack.com/opinion/united-states-v-pollmann-mtd-1973 ; Quechan https://law.justia.com/cases/federal/district-courts/FSupp/424/969/1444773/
- Des accords existent (Nez Perce–Idaho : licence tribale ou d'État sur le Clearwater dans la réserve) https://idfg.idaho.gov/press/nez-perce-tribal-license-not-valid-outside-reservation
- Certaines tribus ne vendent pas de permis aux non-membres [?] (source commerciale : https://windrider.com/blogs/tips-and-tricks/ice-fishing-on-tribal-waters-permit-rules-float-suit-safety).
- Règles de rive vs bateau selon les tribus : seulement des forums https://cdn.northwestfishingreports.com/Forum/viewtopic.php?p=155629 [?]
- Limites des réserves : un jeu de polygones officiel est nécessaire (non vérifié, voir section 3).

### 1.5 Parcs nationaux (NPS) et forêts
- NPS : en règle générale la loi d'État s'applique et le parc peut ajouter des restrictions ; exemples : Sleeping Bear Dunes (Michigan) https://www.nps.gov/slbe/planyourvisit/fishing.htm ; Chickasaw (Oklahoma) https://www.nps.gov/cana/fishing.htm (URL non confirmée pour Chickasaw [?]).
- Exception : Great Smoky Mountains a un texte fédéral propre ; une licence de Tennessee ou de Caroline du Nord vaut dans tout le parc, hors eaux fermées (d'après la recherche NPS, source primaire à rouvrir [?]).
- Permis supplémentaires locaux : Acadia exige un permis gratuit pour transporter engins vers les « Great Ponds » (https://nps.gov/acad/planyourvisit/fishing.htm).
- Forêts nationales (USFS) : non couvertes par mes recherches [?].

### 1.6 Eaux frontalières et réciprocité
- Ohio River : Kentucky et Indiana (et Kentucky–Ohio) se reconnaissent la licence sur le cours principal, hors baies et affluents https://apps.legislature.ky.gov/law/kar/titles/301/001/220/ ; page KDFWR https://fw.ky.gov/Fish/Pages/Reciprocal-Hunting-and-Fishing-Agreements.aspx
- Kentucky–Virginie-Occidentale : accord sur Big Sandy et Tug Fork, rétabli https://digital-release.wvnstv.com/outdoors-wildlife/west-virginia-division-of-natural-resources-announces-reinstatement-of-reciprocal-fishing-agreement-with-kentucky/ ; à noter que l'accord a été suspendu puis rétabli (réciprocité instable) https://fw.ky.gov/News/Pages/Reciprocal-fishing-and-waterfowl-hunting-agreements-back-in-place.aspx
- Wisconsin–Michigan, Wisconsin–Minnesota : chapitres réglementaires dédiés ; licence reconnue sur les eaux limitrophes https://law.justia.com/codes/wisconsin/chapter-29/section-29-045/
- Lac Michigan : pas de réciprocité générale entre tous les États riverains (source journalistique) https://www.wired2fish.com/news/lack-of-state-fishing-license-leads-to-tournament-catch-being-disqualified [?]
- Michigan–Ohio sur le lac Érié : seulement des guides grand public [?].
- Implication : une « eau frontalière » est un objet à part, avec 2 États, une définition géographique (cours principal / rive / bateau) et une date de validité.

### 1.7 Espèces protégées (ESA) et invasives
- ESA : à Washington, les steelhead sauvages sont listés menacés ; dans ces zones tout steelhead sauvage doit être relâché ; distinction par nageoire adipeuse intacte (ancien texte WAC 2002 ; vérifier le WAC actuel) https://wdfw.wa.gov/publications/01784 [?] et https://lawfilesext.leg.wa.gov/Law/WSR/2002/21/02-21-059.htm
- Cadre fédéral ESA (loi, autorisations de pêche accessoire) : non couvert par une source ouverte ici [?].
- Invasives (Lacey Act) : les carpes à grosse tête et argentée figurent sur la liste fédérale des espèces nuisibles ; transporter vivantes d'un État à l'autre, y compris œufs et hybrides, est interdit sauf permis https://www.fws.gov/story/2011-03/bighead-carp-added-federal-list-injurious-wildlife ; carpe argentée listée administrativement en 2007 https://webarchive.library.unt.edu/eot2008/20081011130302/http://edocket.access.gpo.gov/2007/07-5141.htm
- Peine : jusqu'à 6 mois et 5 000 $ pour un individu (même résultat de recherche, texte non vérifié sur eCFR [?]).
- La possession de poissons invasifs est en outre régie par chaque État (liste par État non compilée [?]).

## 2. Anatomie d'une règle américaine

### 2.1 Champs récurrents
| Champ | Remarque |
|---|---|
| Saison | souvent « ouvert toute l'année » par défaut ; Colorado : eaux ouvertes jour et nuit toute l'année sauf exceptions https://CPW.STATE.CO.US/Documents/RulesRegs/Brochure/fishing.pdf |
| Taille minimale | par espèce |
| Slot limit (fourchette protégée) | Texas : fourchette 14–18 pouces sur le lac Nasworthy supprimée en 2023, exemple de règle par plan d'eau https://mail.scttx.com/node/39698 |
| Taille maximale | par espèce / plan d'eau [?] |
| Bag limit (quota journalier) et possession limit (stock détenu) | deux valeurs distinctes ; propre aux USA |
| Engins | nombre de lignes, hameçons, leurres [?] |
| Appâts vivants | restrictions par État / plan d'eau [?] |
| Zones et fermetures | frayères, eaux fermées (GSMNP) |
| Jours gratuits | chaque État en offre, dates variables et divergentes selon les agrégateurs https://fishingbooker.com/blog/free-fishing-days/ ; Kansas confirme que les limites restent en vigueur https://kdwpt.ks.gov/KDWP-Info/News/2026-News-Releases/02-11-26-Kansas-Department-of-Wildlife-and-Parks-Announces-Free-Fishing-and-State-Park-Entrance-Days-for-2026/Kansas-Department-of-Wildlife-and-Parks-Announces-Free-Fishing-and-State-Park-Entrance-Days-for-2026 ; New York : sources contradictoires 2026 https://dec.ny.gov/get-involved/events/2026/6/free-fishing-day-statewide |
| Âges | exemptions et tarifs selon l'âge, variables [?] |
| Registre de capture | Washington (carte), California (carte steelhead) https://wildlife.ca.gov/Conservation/Inland-Fisheries/Steelhead-Report-Card/FAQ |

### 2.2 Hiérarchie des règles
- Règle spéciale locale l'emporte sur la règle générale : Minnesota, les régulations spéciales priment même sur les zones de brochet (selon un forum citant le DNR, https://fishingminnesota.com/forums/topic/210675-outdoormn-news-special-regulations-vs-northern-pike-zones-which-wins) [?].
- Minnesota : plus de 90 plans d'eau avec règles spéciales sur le brochet ; la règle spéciale n'a pas de date de fin, l'expérimentale dure typiquement 10 ans, révisions annuelles (processus 2026 : https://www.dnr.state.mn.us/news/2026/06/15/minnesota-dnr-seeks-input-proposed-special-fishing-regulations).
- Texas : exceptions lac par lac publiées dans l'Outdoor Annual ; la version en ligne n'intègre les changements qu'à la mi-août https://lakeconroe.com/lake-conroe-area-news/leblanc-it-pays-to-read-the-tpwd-outdoor-annual (article de presse locale).
- Colorado : les brochures contiennent des règles par plan d'eau, plus des règles distinctes pour les State Wildlife Areas https://cpw.state.co.us/thingstodo/Pages/FishingSeasonDatesFees.aspx

### 2.3 Comparaison avec le modèle français « espèce × département »
| Axe | France (FishMe) | USA |
|---|---|---|
| Autorité | un code de l'environnement national + arrêtés préfectoraux | 50 États, 50 régimes |
| Unité de règle | espèce × département (catégorie 1/2 par cours d'eau, [?]) | État × plan d'eau/tronçon × espèce, avec exceptions |
| Permis | carte de pêche unique, AAPPMA | licence d'État + timbres + permis locaux/tribaux |
| Quotas | essentiellement taille mini et fermetures | bag limit + possession limit |
| Sources | texte officiel | livret annuel PDF + pages web + cartes |
| Cadence de changement | annuelle, relativement stable | annuelle voire en cours de saison ; propositions publiques chaque année |

Où le modèle casse :
1. Par plan d'eau : la clé « département » ne suffit plus ; il faut un identifiant d'eau stable (NHD, id d'agence).
2. Par tronçon : une rivière a des limites amont/aval, des « catch and release only » sur quelques kilomètres.
3. Par comté : certains États découpent par comté ou par zone de gestion [?] (non vérifié État par État).
4. Frontières : un point peut dépendre de deux États (réciprocité, section 1.6).
5. Propriété : refuge, parc, tribu, forêt, ajoutent des règles sur la même eau.

## 3. Quelles données pour « peux-tu garder ce poisson ici aujourd'hui ? »

### 3.1 Minimum nécessaire
1. Position et identification du plan d'eau / tronçon (géométrie ou id d'agence).
2. État, éventuellement comté ou zone.
3. Espèce (identification fiable, souvent la partie la plus difficile ; cartes à collectionner : source de rareté OFB à remplacer par une source US [?]).
4. Date et heure (saison, jours gratuits).
5. Règle générale de l'État + toutes les exceptions applicables à cette eau.
6. Statut du terrain (refuge, parc, tribu, frontalier).
7. Statut du pêcheur (permis, timbres, âge) : en général hors périmètre de l'app.
8. Mesure du poisson, quota déjà atteint : la taille et le décompte viennent de l'utilisateur.

### 3.2 Données ouvertes trouvées (non testées sur le terrain)
- New Jersey : couche des plans d'eau avec règles, deux tables liées (espèces, plans d'eau), source NJDEP https://geo.btaa.org/catalog/de834ab850224517b11ac0fcddba1bf9
- Californie : carte des règles d'eau douce, licence CC-BY, dernière modification déc. 2019 d'après data.gov https://catalog.data.gov/dataset/freshwater-sport-fishing-regulations (donnée possiblement périmée).
- Vermont : couche « Special Fishing Regulation Lakes/Ponds » https://catalog.data.gov/dataset/special-fishing-regulation-lakes-ponds ; service de test non production [?] https://anrmaps.vermont.gov/arcgis/rest/services/test_services/MAP_ANR_FISHREGULATIONS_CARTO/MapServer
- Arkansas : inventaire de plans d'eau sans règles https://gisec2.agfc.com/arcgis/rest/services/Fisheries/WaterBodyList_Service/FeatureServer/0
- Alaska : limites de régions de gestion https://gis.adfg.alaska.gov/ags/rest/services/sf_public/SF_Reg_Boundaries/MapServer (contenu non vérifié [?]).
- Minnesota : Lake Finder (outil web) ; listes régionales de règles spéciales, pas d'API vérifiée https://www.dnr.state.mn.us/areas/fisheries/littlefalls/specialregs/index.html
- Texas, Colorado : PDF / web, pas de jeu de données vérifié [?].

### 3.3 Niveau réaliste
- Niveau A (réaliste, tous États) : fiche État (licence, jours gratuits, lien vers l'agence).
- Niveau B (États pilotes avec jeu SIG) : règle par plan d'eau pour un ou deux États (NJ, VT, éventuellement CA).
- Niveau C (verdict par poisson et par lieu partout) : non réaliste sans accord de données ou saisie manuelle, et contraire à la prudence juridique (section 4).
- Recommandation : A pour tous, B pour 1 à 3 États, C hors périmètre.

## 4. Responsabilité

### 4.1 Disclaimers officiels
- Colorado CPW : les règles du livret sont paraphrasées et ne sont qu'un guide ; textes complets sur cpw.info/regulations https://CPW.STATE.CO.US/Documents/RulesRegs/Brochure/fishing.pdf
- Texas : l'application officielle prévient que les informations peuvent changer par décision de la commission, du législateur ou du fédéral https://apps.apple.com/us/app/id874391813
- Apps tierces : Fish Rules indique un contenu à titre informatif, sans force légale, et un éditeur privé non lié aux agences https://apps.apple.com/us/app/id1534481224 ; https://apps.apple.com/app/id597875361 (le texte exact diffère selon les fiches).
- Comparaison : l'app officielle du Queensland dit être un guide https://www.qld.gov.au/recreation/activities/boating-fishing/rec-fishing/app/privacy
- Équivalent français « le livret fait foi » : aux USA, formulation « le texte des règlements fait foi ».

### 4.2 Risques d'une règle fausse
- Pour l'utilisateur : amende ou saisie, non évaluées ici [?] ; un mauvais conseil sur une tribu ou un parc expose à une infraction (Pollmann).
- Pour l'éditeur : responsabilité civile ou atteinte à la marque ; les disclaimers d'apps tierces n'ont pas été testés en justice [?]. À faire valider par un juriste américain avant lancement.
- Risques d'obsolescence : changements en cours de saison (Texas mi-août ; accords de réciprocité suspendus puis rétablis au Kentucky).
- Risque de licence des données : certaines couches sont CC-BY (Californie), d'autres non précisées [?].
- Les règles de l'Apple App Store sur les contenus réglementaires : non vérifié [?].

### 4.3 Bonnes pratiques
1. Ne jamais afficher « autorisé » ; afficher « règles connues + vérifier la source ».
2. Chaque règle porte : source (URL), date de collecte, édition du livret, niveau de confiance.
3. Afficher la fraîcheur : « mis à jour le … » et bloquer le verdict quand la donnée est périmée (saison passée).
4. Lien direct vers l'agence d'État et le texte légal, bouton « signaler une erreur ».
5. Alerte forte sur eaux tribales, refuges, parcs, eaux frontalières, espèces ESA.
6. Pas de géolocalisation envoyée côté serveur sans nécessité (vie privée).
7. Journal de versions des règles pour prouver ce qui était affiché à une date donnée.

## 5. Recommandation : modèle de données minimal USA

### 5.1 Entités
- Jurisdiction : id, type (état / tribu / fédéral), nom, URL agence, URL texte légal.
- Water : id, id source (NHD ou agence), nom, géométrie, jurisdiction(s), type (lac, rivière, tronçon).
- Segment (optionnel) : water_id, bornes amont/aval, géométrie.
- Species : id, nom commun/scientifique, statut (indigène, invasive, ESA) ; statut ESA par région [?].
- Rule : id, scope (state | zone | water | segment), scope_id, species_id (nullable = toutes), saison début/fin, taille mini, taille maxi, slot (min, max), bag, possession, engins, appâts, statut (ouvert / fermé / relâcher obligatoire), priorité (spécifique > générale), valide_du, valide_au.
- Requirement : jurisdiction, type (licence, timbre, carte de capture, permis tribal), âges concernés, exemptions, URL.
- FreeDay : jurisdiction, dates, licence_exemptée, remarque (limites toujours valables).
- Reciprocity : eau frontalière, deux jurisdictions, périmètre (cours principal, rive, bateau), date de validité, source.
- Source : url, publisher, édition, date_collecte, hash du document, licence de réutilisation.

### 5.2 Verdict
- Valeurs : « interdit ou fermé (sourcé) » / « règles connues, à vérifier » / « données absentes ». Jamais « permis ».
- Calcul : la règle la plus spécifique l'emporte ; en cas de conflit ou de donnée absente, descendre au niveau « à vérifier ».

### 5.3 Ce qui change par rapport à la France
| Sujet | France | USA |
|---|---|---|
| Clé de règle | espèce × département | scope hiérarchique (État → zone → plan d'eau → tronçon) |
| Verdict | jamais permissif | idem, mais plus de cas « à vérifier » |
| Quotas | rares | bag et possession obligatoires dans le modèle |
| Accès | carte de pêche | licence + timbres + permis tribaux/locaux (Requirement) |
| Frontières | peu pertinent | entité Reciprocity |
| Rareté des cartes | relevés OFB / Hub'Eau | équivalent US non étudié ici [?] (hors périmètre de ce volet) |
| Mise à jour | annuelle | annuelle + corrections en saison ; versionner |
| Sources | peu nombreuses, nationales | 50 agences, formats mixtes (PDF, SIG, web) |

### 5.4 Prochaines vérifications
- Lire eCFR 50 CFR 32.5 et 36 CFR 2.3 (officiel), pas seulement des miroirs.
- Choisir 2 à 3 États pilotes et tester les services SIG (NJ, VT, CA) : fraîcheur, licence, champs.
- Faire valider les disclaimers et le périmètre par un juriste US.
- Vérifier ESA, forêts nationales (USFS), invasives par État.
