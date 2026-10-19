# Pays : où FishMe peut sortir après la France, et ce que ça coûte

Décision débloquée : le prochain pays de sortie de FishMe, au vu du coût en données et en règles.
Recherche du 19/10/2026. [?] = non trouvé ou non revérifié. Sources : liens en ligne et fiches de `donnees/` en (§…).

En deux phrases : le Royaume-Uni est le seul pays où les trois briques de FishMe (permis en ligne national, règles publiées, relevés poissons en données ouvertes) existent déjà ; les Pays-Bas sont un bon second (VISpas unique, app fédérale faible). L'Allemagne est le plus gros marché mais le plus fragmenté (16 Länder, examen obligatoire), l'Espagne et l'Italie sont éclatées en régions sans portail unique.

## France (étalon)
1. Pêcheurs : 1 434 142 cartes de pêche vendues en 2025, dont 713 194 « personne majeure » (FNPF via https://www.lechasseurfrancais.com/peche/plus-de-1-400-000-pecheurs-en-france-en-2025-185724.html et http://www.federationpeche.fr/7142-chiffres-cles-2025-de-la-peche-en-france.htm). Prix carte majeure annuelle 2026 : 87 € en Seine-et-Marne, 114 € l'interfédérale, 14,30 € la journée (https://www.federationpeche77.fr/4231-cartes-de-peche.htm) ; varie un peu par département.
2. Permis : vendu en ligne sur https://www.cartedepeche.fr/ (site FNPF) ou chez les dépositaires ; la carte matérialise l'adhésion à une AAPPMA. Point de contact unique national, potentiellement ouvert à un partenaire (la FNPF édite déjà Génération Pêche — concurrent, pas partenaire).
3. Règles : socle national (Code de l'environnement) + arrêtés préfectoraux par département et par tronçon ; publiés en PDF sur les sites des préfectures, pas en données ouvertes ; les tailles légales varient par département (ex. brochet 60 cm dans le 94).
4. Données : pêches électriques OFB par station (espèces, effectifs) en accès libre (licence ouverte), niveaux des rivières via l'API Hub'Eau (gratuite) — l'étalon du rapport.
5. Apps locales : Génération Pêche FNPF 1,54★/723 notes, Fishing Grid 4,76★/131, HOOKfr 5,0★/2 (§concurrence-fr.md).
6. Verdict : étalon — tout est disponible, l'app officielle est défaillante.

## Allemagne
1. Pêcheurs : ~1,8 M de Fischereischeine valides en 2024 et ~61 000 examens réussis par an (autorités des Länder, compilé par le DAFV : https://www.pressebox.de/pressemitteilung/provimedia-gmbh/angelfischerei-bleibt-breit-verankert-1-8-millionen-gltige-fischereischeine-und-rund-61-000-bestandene-prfungen-im-jahr-2024/boxid/1308851 ; 6,64 M pêchent au moins une fois par an, https://dafv.de/service/zahlen-und-fakten-rund-um-das-angeln). Prix du permis annuel : variable par Land [?], plus examen payant une fois [?].
2. Permis : examen (Fischerprüfung) obligatoire puis Fischereischein délivré par l'autorité du Land ; pas de portail national unique ; il faut en plus une Gewässerkarte du club ou du propriétaire de l'eau. Point de contact de la licence fragmenté : pas de partenaire unique.
3. Règles : fischereirecht de chaque Land, publié en PDF ; les tailles varient par Land et par eau ; pas de base de données nationale.
4. Données : monitoring WRRL géré par les Länder ; niveaux via Pegelonline (API fédérale gratuite). Relevés de poissons par station : non trouvé en accès libre national [?].
5. Apps locales : ALLE ANGELN 4,78★/8 585 notes (Echo Projects, carte et spots), Angel App 4,57★/755, hejfish 4,09★/296, Fishing Points 4,57★/2 223 (§fiche-1095645023-de.json, §fiche-1564557199-de.json, §fiche-1203032512-it.json).
6. Verdict : partiel — marché énorme, mais 16 règlements et un permis à examen ; obstacle n°1 : l'éclatement Länder des règles et des données.

## Pays-Bas
1. Pêcheurs : 708 160 VISpassen émises en 2024, ~746 000 membres de clubs dont ~40 000 jeunes (Compendium voor de Leefomgeving, https://www.clo.nl/indicatoren/nl127510-omvang-van-de-nederlandse-sportvisserij-1990-2024). Prix : VISpas via cotisation de club (montant variable [?]), Kleine VISpas moins chère [?].
2. Permis : la VISpas s'obtient via un club affilié à Sportvisserij Nederland, en ligne ; la Kleine VISpas se demande seule sans club (https://www.clo.nl/indicatoren/nl127510-omvang-van-de-nederlandse-sportvisserij-1990-2024). Un seul point de contact national, déjà éditeur d'apps — partenaire structuré, mais concurrent potentiel.
3. Règles : nationales (lijst van wetten via VISpas) + règles par eau affichées dans les outils de la fédération ; publicées en ligne, structurées par eau dans VISplanner — le modèle le plus proche de la France.
4. Données : inventaires de poissons en données ouvertes via les portails néerlandais (NDFF/observation.org) [?] ; niveaux d'eau via l'API Rijkswaterstaat. Équivalent OFB par station : non trouvé [?].
5. Apps locales : MijnVISmaat 4,57★/1 881 notes, plus mise à jour depuis déc. 2019, et VISplanner 2,37★/276 (toutes deux publiées sous le nom « Koninklijke Sportvisunie », la fédération Sportvisserij Nederland, §fiche-522384282-nl.json, §fiche-6780822269-nl.json), Vissengids 3,06★/79 (§avis-6780822269-nl.csv).
6. Verdict : oui — permis unique, règles par eau, app officielle mal notée (2,37★) ; obstacle : données de présence par espèce à trouver.

## Royaume-Uni
1. Pêcheurs : 934 000 rod licences vendues en Angleterre en 2024/25, £24,15 M de revenus (Environment Agency, https://www.gov.uk/government/publications/fisheries-annual-report-2024-to-2025-how-we-spend-fishing-licence-income/fisheries-annual-report-2024-to-2025-how-we-spend-fishing-licence-income). Prix : £36,80 l'année (2 cannes, https://www.gov.uk/fishing-licences/buy-a-fishing-licence).
2. Permis : acheté en ligne sur gov.uk en 5 min (EA), par téléphone, ou en poste ; pas d'examen. Point de contact national unique et déjà numérique — ouvert à un partenaire ? L'EA est une agence, pas un éditeur d'app : place libre.
3. Règles : nationales (freshwater rod fishing rules, gov.uk) + byelaws régionales EA et règles de chaque pêcherie ; publiées en ligne, pas en base de tailles par lieu [?] ; la permission du propriétaire de la rive compte autant que la licence.
4. Données : EA fish survey data et rod licence sales sur https://www.data.gov.uk/ (licence OGL), niveaux des rivières via l'API hydrology de l'EA (environment.data.gov.uk). Pas aussi granulaire que l'OFB par station, mais ouvert.
5. Apps locales : FishAngler 4,76★/617 notes, Fishbrain 4,65★/921, Carpcraft 4,47★/1 421 (§fiche-1073941118-gb.json, §fiche-477967747-gb.json, §avis-1073941118-gb.csv). Pas d'app « règles + spots » dominante.
6. Verdict : oui — permis en ligne national, données ouvertes OGL, pas de fédération-éditeur ; obstacle : la permission de rive privée, que la licence ne couvre pas.

## Espagne
1. Pêcheurs : 796 000 licencias de pesca continental en 2018 (INE, via l'étude IMEDEA-CSIC https://imedea.uib-csic.es/files/get/45b14be01ef7ade27b553de31435c0fe ; indicateur national IEPNB https://pro.iepnb.gob.es/sites/default/files/2025-04/22_LicenciasCazaPesca.pdf). Prix de la licence annuelle : variable par comunidad [?].
2. Permis : chaque comunidad autónoma délivre sa licence (compétence exclusive, IEPNB) ; en ligne dans certaines régions [?]. Pas de point de contact national : 17 interlocuteurs.
3. Règles : ordres de pêche par comunidad (vedas, tallas) publiés en PDF au BOE/boletines régionaux ; pas de base nationale ouverte ; tailles variables par région et par réserve.
4. Données : inventaires par comunidad, pas de portail unifié ; MITECO pour le national ; équivalent OFB par station non trouvé [?] ; niveaux via les systèmes de confederaciones hidrográficas [?].
5. Apps locales : WeFish 4,76★/2 414 notes mais société fermée en mars 2023, fiche encore en ligne et dernière version d'avril 2024 (§fiche-1272125949-es.json ; § acquisition.md, §1), Fishing Points 4,62★/2 199, RadarFish 4,82★/261.
6. Verdict : partiel — marché réel mais 17 réglementations et pas de licence nationale ; obstacle : la fragmentation régionale des règles.

## Italie
1. Pêcheurs : ~245 000 tesserati FIPSAS (https://fipsas.it/wp-content/uploads/2026/06/Bilancio-Sociale-FIPSAS-2025.pdf ; ~60-70 000 licenza B en Lombardie seule, presse locale) ; le nombre national de licenza B n'est pas centralisé [?]. Prix : 23 €/an en Lombardie (https://fipsasbrescia.it/licenza-di-pesca/), variable par région.
2. Permis : licenza B = reçu de paiement de la taxe régionale (portail de la région), plus carte d'une association pour certaines eaux ; pas d'examen, pas de portail national. Point de contact éclaté par région.
3. Règles : lois régionales et règlements des zones (bacini, ambiti) publiés en PDF ; pas de base nationale ; tailles variables par région et par eau.
4. Données : ISPRA et agences régionales ; pas de portail unifié de relevés de poissons trouvé [?] ; niveaux par les services hydrologiques régionaux [?].
5. Apps locales : aucune app italienne dominante trouvée — Fishing Points 4,65★/3 937 notes, Pescatori (previsioni) 4,53★/425 (§fiche-1203032512-it.json, §fiche-1494865951-it.json, §avis-1494865951-it.csv).
6. Verdict : non pour l'instant — marché fragmenté, pas de licence nationale, données poissons introuvables ; obstacle : tout est régional, règles comme permis.

## Synthèse

| Pays | Pêcheurs (permis/cartes) | Permis en ligne | Règles en données | Relevés poissons ouverts | Concurrent local fort | Verdict |
|---|---|---|---|---|---|---|
| France | 1,43 M cartes 2025 (§fiche France) | oui (cartedepeche.fr) | PDF départementaux | oui (OFB, Hub'Eau) | Génération Pêche (1,54★) | étalon |
| Royaume-Uni | 934 k licences 2024/25 (§fiche Royaume-Uni) | oui (gov.uk) | en ligne, partiel | oui (data.gov.uk, OGL) | FishAngler, Fishbrain | oui |
| Pays-Bas | 708 k VISpassen 2024 | oui (clubs VISpas) | par eau, structurées | à trouver [?] | MijnVISmaat (fédération) | oui |
| Allemagne | 1,8 M scheine 2024 | non (Länder + examen) | PDF par Land | non trouvé [?] | ALLE ANGELN (8 585 notes) | partiel |
| Espagne | 796 k licencias 2018 | partiel, par région | PDF par comunidad | non trouvé [?] | aucun vivant (WeFish fermée) | partiel |
| Italie | ~245 k tesserati FIPSAS | non (taxe régionale) | PDF par région | non trouvé [?] | aucun dominant | non |

## Recommandation
- Le Royaume-Uni est le candidat n°1 : licence nationale en ligne, données en Open Government Licence, concurrents faibles sur les règles (§Royaume-Uni, §synthèse).
- Les Pays-Bas en second, à condition de valider l'équivalent OFB avant tout engagement (§Pays-Bas point 4, non trouvé aujourd'hui).
- Ne pas cibler l'Allemagne en première expansion : le coût des 16 règlements et de l'examen dépasse le gain (§Allemagne points 2-3).
- Espagne et Italie : hors périmètre, la fragmentation régionale rend notre promesse « règle sourcée » intenable à ce coût (§Espagne, §Italie).
- Prochaine étape avant décision : vérifier que l'EA fish survey data couvre espèces par site (granularité OFB) et chiffrer la lecture des byelaws (§Royaume-Uni point 4).
