# 4. Pistes produit : pêche en eau douce et bivouac (premier jet, avant l'analyse de concurrence)

Règle MWM appliquée : un problème clair, un premier moment utile en secondes, une raison de revenir. À recaler quand l'analyse de concurrence revient.

## Pêche en eau douce

**Moment héros (les 10 premières secondes)** : j'arrive au bord de l'eau, j'ouvre l'app, elle me dit en une phrase : « Ici : 2e catégorie, brochet ouvert, taille légale 60 cm, 3 carnassiers max par jour. » Source citée.
- Verrou honnête : la règle n'existe qu'en PDF par département. Version vendredi = 3 à 5 départements saisis à la main (là où vous et vos testeurs pêchez), le reste affiché « non couvert, voici le lien de la fédération ». On étend département par département après.

**Features**
1. « Ai-je le droit ici ? » : position → département, catégorie de cours d'eau, ouvertures, tailles, quotas.
2. Carnet de prise en 5 secondes : une photo, l'app propose l'espèce (Vision / modèle image d'Apple), et enregistre seule la météo, la pression, la lune, l'heure, le spot (WeatherKit).
3. « Ton carnet apprend » : après 10 sorties, l'IA d'Apple lit ton carnet et te dit « tes brochets mordent quand la pression baisse en fin de journée ». C'est la vraie raison de revenir, et elle grandit avec l'usage.
4. Alerte « conditions idéales demain sur ton spot » (notification + widget « indice du jour »).
5. Compte à rebours des ouvertures (truite en mars, brochet) en Live Activity, et rappel des fermetures.

**Pourquoi revenir** : chaque sortie (carnet), chaque semaine (alerte conditions), chaque ouverture (compte à rebours). Hors saison : les carpistes pêchent l'hiver, et le carnet se relit.

**Offre** : gratuit pour la règle et le carnet ; Pro 19,99 €/an (analyses du carnet, alertes, spots hors ligne) ; achat transparent, sans prélèvement piège (le défaut de Fish AI).

**Ce qu'on met en avant** : la réponse claire « je peux / je ne peux pas » (personne ne l'a), et l'honnêteté du prix.

Angles (probabilité qu'un autre LLM le propose) : règle locale claire 55 % ; carnet qui apprend tes conditions gagnantes 20 % ; achat honnête contre les apps piège 8 %.

## Bivouac

**Moment héros** : j'ouvre l'app sur place, la carte me répond en feu tricolore : vert « bivouac toléré de 19 h à 9 h, à plus d'1 h de marche de la route (Parc national des Écrins) », orange « zone Natura 2000, vérifie la commune », rouge « massif fermé aujourd'hui : risque incendie ». Hors ligne.

**Features**
1. Feu tricolore légal : position → contours des parcs nationaux, réserves, forêts domaniales, fermetures de massifs l'été (données ouvertes), règle en une phrase avec source.
2. « Ta nuit » : choisis un lieu et une date, l'app donne la nuit qui t'attend (WeatherKit) : température minimale, vent, orage, rosée, lune, lever du soleil, et si ton duvet suffit.
3. La micro-aventure du week-end : chaque jeudi, « nuit claire et douce samedi, à 1 h de chez toi, bivouac autorisé ici ». C'est la raison de revenir chaque semaine.
4. Passeport des nuits : chaque nuit dehors s'ajoute à ta carte (photo, ciel, température), partageable. Ça fait venir les amis, comme le passeport de vols de Flighty.
5. Siri : « est-ce que je peux dormir ici ? » (App Intents) ; widget de la prochaine nuit.

**Pourquoi revenir** : le jeudi (le plan du week-end), sur place (la règle), après (le passeport). Hors saison : bivouac d'hiver et préparation.

**Offre** : gratuit pour le feu tricolore autour de soi ; Pro 24,99 €/an (cartes hors ligne, prévisions de nuit, alertes du jeudi, passeport complet).

**Ce qu'on met en avant** : la seule app qui répond « tu as le droit de dormir ici cette nuit, et voici la nuit qui t'attend ».

Angles : feu tricolore légal 40 % ; micro-aventure du week-end à 1 h de chez toi 20 % ; passeport des nuits partageable 12 %.

## Point commun
Les deux apps reposent sur le même moteur : une position, une règle locale expliquée en une phrase, la météo Apple et un carnet. On peut construire ce moteur une fois et choisir la peau (pêche ou bivouac) selon les tests.

## Comment on coche les attentes du jury

**L'argument central de l'IA sur l'appareil** : au bord d'une rivière ou en montagne, il n'y a souvent pas de réseau. Une IA qui tourne dans l'iPhone, sans serveur, est la seule qui marche là où l'app sert. Ce n'est pas un gadget : c'est la condition d'usage. Et elle ne coûte rien par requête (pas de facture d'API), ce qui protège la marge.

| Attente | Pêche | Bivouac |
|---|---|---|
| Foundation Models (IA d'Apple sur l'iPhone) | reformule la règle officielle en une phrase ; lit ton carnet et sort tes conditions gagnantes ; hors ligne | reformule la règle du parc en une phrase ; prépare la liste de matériel selon la nuit prévue ; hors ligne |
| Vision / entrée image | identifie l'espèce sur la photo de la prise | (optionnel) lit un panneau de parc photographié |
| Siri et App Intents | « Siri, je peux garder un brochet de 55 cm ici ? » | « Siri, est-ce que je peux dormir ici ? » |
| WeatherKit | pression, vent, température de l'eau [?] pour l'indice de pêche | la nuit qui t'attend : minimum, vent, orage, rosée |
| Live Activities / Dynamic Island | compte à rebours de l'ouverture | la nuit en cours : coucher du soleil, température qui baisse, lever |
| Widgets | indice de pêche du jour | prochaine nuit prévue |
| Liquid Glass | carte et fiches au nouveau style iOS | idem |
| StoreKit + SDK Spark Flash (MWM) | essai 7 jours puis 19,99 €/an, prix testés | essai 7 jours puis 14,99-24,99 €/an, prix testés |
| Critères MWM | réponse en 3 s à l'ouverture ; revient à chaque sortie ; paywall après la première valeur | réponse en 3 s ; revient chaque jeudi (plan du week-end) ; passeport partageable = acquisition gratuite |

Règle de sécurité : l'IA ne décide jamais si c'est autorisé. La règle vient d'une table saisie et sourcée ; l'IA ne fait que l'expliquer.

## Ce que dit la recherche bivouac (reports/creuser-bivouac.md)
- Aucune app française ne répond « ai-je le droit ici ? » partout ; seul HexaTrek le fait sur un itinéraire, et Fricamp (Norvège, mars 2026) avec de l'IA.
- ~8 M de Français font de la randonnée itinérante, 52 % des 18-24 ans en ont déjà fait, 47 % utilisent une app de rando (69 % chez les plus jeunes). Le bivouac seul n'est pas chiffré.
- ~10 régimes de règles couvriraient 80 % des cas (estimation) ; contours des parcs nationaux et Natura 2000 en données ouvertes ; horaires et distances à saisir à la main depuis les arrêtés ; fermetures incendie PACA sans API.
- Concurrents forts sur la carte (park4night 4,7/6,9 k, Komoot, Gaia, IGNrando'), aucun fort sur la règle.

## Mise à jour 12 oct. midi : idées d'Adem

### Pêche : le « Pokédex » de prises
- Déjà tenté ailleurs, jamais en France : CatchDex (US, bêta, cartes « FishDex » à collectionner, spots gardés privés) https://www.producthunt.com/p/self-promotion/we-re-building-catchdex-a-private-fishdex-for-real-world-anglers ; VISDEX (Pays-Bas, 4,9/32 notes, 1 k+ téléchargements, classements) https://mwm.ai/apps/visdex/6775490949 ; Fishdex (identification photo seule, aucune note) https://apps.apple.com/sg/app/fishdex/id6471892324 .
- FishFriender et Fishing Points font carnet + communauté, pas de cartes à collectionner : https://apps.apple.com/FR/app/id1103927041
- Différenciateur possible : la rareté de la carte calculée sur les vrais inventaires de poissons de l'OFB (Hub'Eau poissons, données ouvertes) par département. Un brochet en Seine-et-Marne n'a pas la même rareté qu'en Savoie.
- Point de vigilance : les pêcheurs cachent leurs coins. La carte est publique, le spot reste privé (alias, zone floue), comme CatchDex.
- « Où pêcher pas loin » : Géopêche a les parcours mais ses données sont fermées. À vérifier : données ouvertes de classement piscicole des cours d'eau [?].

### Bivouac : features proposées (probabilité qu'un autre LLM la propose)
1. Feu tricolore « je peux dormir ici ? » hors ligne, avec la règle en une phrase et sa source (35 %)
2. « Ta nuit » : température minimale, vent, orage, rosée, et si ton duvet suffit (15 %)
3. La micro-aventure du jeudi : une nuit claire, à 1 h de chez toi, autorisée (20 %)
4. Le carnet des nuits en cartes à collectionner : chaque nuit dehors devient une carte (lieu, altitude, phase de lune, température, ciel), le pendant de ton Pokédex de pêche (10 %)
5. « Dernier signal » : avant de perdre le réseau, tu laisses ton spot et ton heure de retour à un proche ; si tu ne pointes pas au retour, il est prévenu, sans suivi de position (12 %)
6. Réveil lever de soleil : alarme réglée sur l'aube du lieu, direction du soleil levant, Live Activity de la nuit (15 %)
7. Siri hors ligne : « est-ce que je peux dormir ici ? » (25 %)
