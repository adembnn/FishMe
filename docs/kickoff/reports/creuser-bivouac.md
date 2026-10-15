# Creuser : bivouac en France (« puis-je dormir ici, et quelle météo cette nuit »)

Décision débloquée : cette piste peut-elle devenir une app iPhone monétisée, publiée vendredi par 3 non-développeurs, maintenue ensuite ?
Mesure : Parallel_Search limité en débit, WebSearch/WebFetch en repli. Appel direct à l'API iTunes bloqué par le proxy (403), donc notes lues sur les fiches App Store. [?] = non vérifié.

## 1. Qui fait déjà quoi

| App | Note / avis | Prix | MAJ | Bien / mal |
|---|---|---|---|---|
| park4night (fiche FR) | 4,7 / 6,9 k (monde : ~26 k [?]) | gratuit ; 9,99 €/an ou 1,99 €/mois | v7.3.8, 3 août | + 370 k lieux, 100 pays, avis et photos. − pensé camping-car ; un avis demande de signaler les lieux où la nuit est interdite ; un autre veut un achat unique. https://apps.apple.com/fr/app/park4night/id430946556 |
| iOverlander | 4,2 / ~7,5 k (US) | gratuit ; Pro 59,99 $, Unlimited 99,99 $, mensuel 9,99 à 14,99 $ | v2.6.44, 28 sept. | − « annoyware », lieux « nuit autorisée » qui ne l'étaient pas. https://apps.apple.com/us/app/ioverlander/id1486556203 |
| Hipcamp | 4,8 / ~55 k (US) | gratuit, réservation payée à part | v4.21.0, 1er oct. | + terrains privés, hôtes. − photos non conformes, calendriers non tenus. https://apps.apple.com/us/app/hipcamp-camping-rvs-cabins/id1440066037 |
| Campspace | fiche non lue [?] | réservation chez l'habitant | n.c. | Hôtes en France ; prix par nuit non trouvé. https://www.pariszigzag.fr/paris-au-quotidien/lifestyle/campspace-camping-chez-habitant/ |
| Gaia GPS (fiche FR) | 4,5 / 258 | Premium 59,90 €/an | 2026.6, 14 sept. | + cartes IGN, hors ligne. − « beaucoup trop cher ». https://apps.apple.com/fr/app/gaia-gps-cartes-topo-randonn%C3%A9e/id1201979492 |
| Komoot (FR) | 4,7 / 33 k | Premium 59,99 €/an ; World Pack 29,99 € (achat unique) | 2026.41.0, il y a 4 jours | + itinéraires. − planification mobile peu pratique. https://apps.apple.com/fr/app/komoot-randonn%C3%A9e-v%C3%A9lo/id447374873 |
| IGNrando' | 4,5 / ~24 k | IGNrando' Plus 22,99 € (essai 7 jours) | v1.84, 2 juin | − tracé non modifiable, téléchargement de cartes lent. https://apps.apple.com/fr/app/ignrando-gps-avec-cartes-ign/id1454207995 |
| Visorando | 4,6 / 68 | Premium 25 $/an ; cartes IGN 18,99 $/an | v3.21.4 | − abonnement IGN non reconnu, support muet (avis 2022). https://apps.apple.com/us/app/visorando-gps-randonn%C3%A9e/id969793415?l=fr-FR |
| HexaTrek (GR itinérant) | 4,3 / 3 | parcours 41,99 $ ; étape 7,99 $ | v3.0.2, 11 mai | Seule app trouvée qui affiche zones de bivouac autorisées/restreintes, mais sur un seul itinéraire de 3 034 km. https://apps.apple.com/us/app/id1606022859 |
| Fricamp (Norvège) | 0 avis | gratuit + « Supporter » | sortie 16 mars 2026 | IA qui évalue la légalité d'un spot, hors France : preuve que l'idée existe ailleurs. https://mwm.ai/fr/apps/fricamp/6759742331 |

Lacune : je n'ai trouvé aucune app française qui répond à « ai-je le droit ici ? » sur tout le territoire (recherches web et App Store ; absence non prouvée) [?]. Les guides papier et blogs se contentent de tableaux par parc : https://ulysse.com/news/bivouac-france-regles-zones-autorisees-amendes
Non couverts (limite de temps/outil) : groupes Facebook, Camptocamp, fiche App Store de Campspace, « Bivouac » génériques [?].
Park4night : les fiches sont alimentées par les utilisateurs et une fiche ne vaut pas autorisation : https://hinterland.camp/en/tips/park4night-and-alternatives (site concurrent, point de vue promotionnel).

## 2. Utilisateur précis

- Randonneur itinérant 18-34 ans. 62 % des Français disent avoir randonné en 12 mois (~30 M) ; 27 % de ces randonneurs font de l'itinérance (~8 M) ; 52 % des 18-24 ans ont déjà fait de l'itinérance ; 47 % utilisent une app de rando (69 % chez les plus jeunes). Bivouac non chiffré dans la source. https://www.ffrandonnee.fr/la-randonnee-activite-preferee-des-francais-en-2025
- Bivouaqueur week-end près des massifs (PACA, Alpes, Pyrénées, Vosges) : taille France non trouvée [?]. Les parcs eux-mêmes montent des aires dédiées (Bauges : 11 aires en oct. 2025) et un tableau de réservation (Contamines-Montjoie, 2024), signe de pression : https://www.cipra.org/media/files/vay_bivouac_whitepaper_fr_neu.pdf/@@download/file/VAY_Bivouac_Whitepaper_FR_neu.pdf
- Vanlifer / fourgon aménagé : déjà servi par park4night (hors cible).
- Preuve de paiement : abonnements 59,90 à 59,99 €/an (Gaia, Komoot), 22,99 € (IGNrando'), 25 $/an (Visorando) ; park4night annonce « 400 000 abonnés » à 9,99 €/an, chiffre venu d'un blog de location de camping-cars (https://www.wikicampers.fr/blog/application-camping-car-park4night/) [?]. Estimation tierce opposée : moins de 10 k $ de revenu mensuel, 63 % pub (https://appgoblin.info/apps/430946556) [?]. Les deux ne peuvent pas être vrais : la preuve de paiement est solide pour la rando, floue pour le bivouac seul.

## 3. Le moment

- Ouverture : la veille ou le jour même, sur le parking ou au col, vers 16-19 h, pour décider où planter la tente (les tentes se montent après 19 h dans la plupart des parcs). https://www.ecrins-parcnational.fr/sites/ecrins-parcnational.com/files/article/27274/2606148arretebivouacvf1.pdf
- Fréquence : sorties week-end et été ; la pratique assidue baisse, les occasionnels (jeunes actifs) augmentent : usage saisonnier, quelques nuits par an. https://www.ffrandonnee.fr/la-randonnee-activite-preferee-des-francais-en-2025
- Raison de revenir : règles qui changent (Écrins : arrêté n°148/2026 du 16 juin 2026 remplace celui de 2013) ; interdictions incendie sur les massifs de PACA publiées jour par jour (communiqué du 6 août 2026 : tous les massifs des Bouches-du-Rhône fermés, 25 massifs listés) ; météo de nuit. https://draaf.paca.agriculture.gouv.fr/IMG/pdf/cp_-_massifs_-_risque_incendie_tres_severe_lundi_17_aout_2026.pdf
- Risque : retour faible hors saison. Rétention hivernale non démontrée [?].

## 4. Données et moteur

Règles réelles (combien en saisir ?)
- Base légale : pas de définition nationale du bivouac ; code de l'urbanisme R111-32 à R111-35 ; amende de base 135 €, jusqu'à 1 500 € en espace protégé. Interdit : à moins de 200 m d'un point d'eau de captage, littoral, réserve naturelle (sauf dérogation), voie publique, propriété privée sans accord. https://ulysse.com/news/bivouac-france-regles-zones-autorisees-amendes
- Parcs nationaux (chacun différent) : Écrins 19 h-9 h, tente basse, 1 h de marche des routes, 500 m des lacs Lauvitel/Muzelle (arrêté 148/2026) ; Vanoise 1er juin-30 sept., 19 h-8 h, près des refuges, 5 €/pers. ; Cévennes 50 m de part et d'autre des GR ; Mercantour 1 h de marche, vallée des Merveilles interdite ; Pyrénées 1 h de tout accès motorisé ; Calanques et Port-Cros interdit. https://ulysse.com/news/bivouac-france-regles-zones-autorisees-amendes et https://www.cipra.org/media/files/vay_bivouac_whitepaper_fr_neu.pdf/@@download/file/VAY_Bivouac_Whitepaper_FR_neu.pdf
- PNR (règles différentes) : Vercors 17 h-9 h ; Préalpes d'Azur interdit 1er juil.-30 sept. sous 1 500 m ; Verdon interdit aux bords de lac et gorges ; Haut-Jura sans tente, 20 m des chemins ; Bauges aires dédiées. Même source CIPRA.
- Estimation (pas une mesure) : 80 % des bivouacs tomberaient dans une dizaine de régimes : défaut tolérant + 5 interdits nationaux (littoral, RN, captage, voie publique, privé) + cœurs de 11 PN (7 règles distinctes dont 2 interdictions totales) + PNR + fermetures incendie départementales [?]. Les cœurs de parcs sont le gros du risque d'amende.

Données ouvertes avec polygones
- Parcs nationaux : aire d'adhésion du Mercantour, CC BY, GeoJSON/GeoPackage, maj 22 mai 2026 ; la page indique un jeu séparé pour les contours des 11 parcs. https://www.data.gouv.fr/datasets/5fb4f57986c6efd5d795e36c
- Natura 2000 (INPN) : ZSC/ZPS, maj 8 oct. 2026, 2 fois par an ; licence « non spécifiée » sur la page, certains fichiers indisponibles après une cyberattaque du MNHN. https://www.data.gouv.fr/datasets/inpn-donnees-du-programme-natura-2000/informations
- Base nationale des espaces protégés (MNHN) : aucun fichier sur la page, maj 28 août 2025, Natura 2000 exclu. https://www.data.gouv.fr/datasets/base-de-donnees-espaces-proteges/informations
- Forêts domaniales : seul jeu trouvé = DDT 95 (Val-d'Oise), maj 2019, Licence Ouverte 2.0, donc pas national [?]. https://www.data.gouv.fr/datasets/forets-domaniales-et-publiques/informations
- Conservatoire du littoral : 0 jeu de données sur la page de l'organisation [?]. https://www.data.gouv.fr/organizations/conservatoire-du-littoral/datasets
- Fermetures incendie PACA : communiqués PDF et cartes web par département (risque-prevention-incendie.fr), pas d'API trouvée ; prévisions Météo-France, mise à jour quotidienne. https://risque-prevention-incendie.fr/aude/import_data/20240910.pdf
- Aucune source ouverte trouvée pour les horaires, distances et altitudes : ils sont dans des arrêtés PDF (ex. arrêté Écrins). Conséquence : la couche « règle » est à saisir à la main, ~11 parcs + ~10 PNR.

Briques Apple
- WeatherKit : 500 000 appels/mois inclus au programme développeur, puis 49,99 $ pour 1 M ; prévisions horaires 10 jours (température, vent, précipitations), jour/nuit ; marque « Weather » obligatoire. https://developer.apple.com/weatherkit/get-started/ La rosée et le risque d'orage ne sont pas listés comme champs [?].
- Foundation Models : ~3 Md de paramètres, 4 096 tokens, iPhone 15 Pro et suivants ; français dans la liste Apple Intelligence ; peut halluciner. https://www.atelier-socle.com/en/articles/foundation-models-api-guide et https://www.natashatherobot.com/p/apple-foundation-models
- Faisable en une semaine : carte MapKit + point GPS dans polygones locaux (GeoJSON embarqué) ; fiche de règle écrite à la main par zone ; WeatherKit pour la nuit ; widget et App Intent « puis-je dormir ici ? » qui lit la base locale ; StoreKit.
- Infaisable en une semaine : saisir et tenir à jour les arrêtés de tous les parcs/PNR/communes ; communautés de spots avec modération ; fermetures incendie en temps réel sans API.
- IA : Foundation Models ne doit que reformuler une règle déjà trouvée par le code, jamais décider (sinon risque de réponse fausse, voir §6). Sans l'IA l'app marche encore : « IA décorative » selon la carte de rejet [?].

## 5. Monétisation (2 offres à tester)

- A. Abonnement 14,99 €/an, essai 7 jours : règles + météo de nuit + alertes de fermeture. Repères : park4night 9,99 €/an, IGNrando' 22,99 €, Visorando 25 $, Komoot/Gaia ~60 €.
- B. Achat unique 6,99 €, pas d'abonnement, mises à jour de règles pendant 1 an. Repère : demande d'achat unique dans un avis park4night (2020) ; World Pack Komoot 29,99 € unique.
- Saisonnalité : encaisser en mai-juin ; risque d'annulations après l'été [?].

## 6. Risques

- Responsabilité : l'app dit « autorisé » à tort, l'utilisateur prend 135 € à 1 500 € d'amende ou dort en zone fermée à l'incendie. Réponse de conception : jamais de « autorisé » binaire, mais « règle applicable + source + date + à vérifier ». Avis juridique réel non obtenu [?].
- App Store 1.2 : toute fonction de spots communautaires exige conditions d'utilisation, signalement, blocage, traitement sous 24 h, contact in-app. https://developer.apple.com/forums/thread/807358 Cela alourdit une semaine de build : exclure l'UGC du lot 1 (cohérent avec la carte de rejet).
- Données : licences Natura 2000 à clarifier ; arrêtés = fait public mais pas de licence dédiée [?].
- Concurrence : park4night peut ajouter une couche « zones réglementées » (barrière faible) [?].
- Dépendance : WeatherKit exige l'Apple Developer Program (compte MWM) ; modèle Foundation Models mis à jour par Apple sans version figée.

## 7. Trois angles de différenciation (probabilité qu'un autre LLM les propose)

1. « Règle à l'endroit où tu es » : un point GPS donne la règle exacte du parc/zone (horaires, distance, feu) avec source datée, pas un spot. ~35 %.
2. Fermetures incendie d'été + nuit : la veille au soir, dire si le massif est ouvert demain et si la nuit passe sous un seuil de froid ou de vent. ~15 %.
3. Brevet de « non-bivouac » : refuser plutôt que lister. L'app répond surtout « non, ici non, voici l'endroit légal le plus proche à moins de 1 h » (cœurs de PN interdits, aires dédiées type Bauges). ~10 %.
Probabilités = estimation, pas une mesure.

## 8. Verdict

**À creuser, pas encore go.** Besoin réel et lacune apparente (aucune app FR trouvée sur « ai-je le droit ici »), moteur local faisable en une semaine, preuve de paiement solide côté rando mais pas côté « règle seule ».
Verrous : données de règles non ouvertes (saisie manuelle) et responsabilité en cas d'erreur ; saisonnalité forte.
Test à faire avant : un cas réel de bout en bout sur 2 parcs + 1 massif PACA, et un avis juridique sur la formulation.

## Comparaison avec la pêche de loisir (3-trous.md)
Pêche : même verrou (règle en PDF départemental, ici arrêtés de parcs) mais audience plus petite (~4,5 k notes) et concurrent officiel faible (Génération Pêche 1,6/700). Bivouac : audience plus grande (8 M d'itinérants), concurrents solides sur la carte (park4night, Komoot), mais aucun sur la règle. Dans les deux cas la règle est saisie à la main ; le bivouac y gagne en volume, la pêche en simplicité (un permis, un département).
