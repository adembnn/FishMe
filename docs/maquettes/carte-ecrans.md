# [nom de l'app] : carte des écrans (version du 12 oct. 2026)

Nom : l'app n'a pas encore de nom, noté [nom de l'app]. « Pescedex » désigne seulement la collection de cartes dans l'app. Décision utilisateur du 12 oct. : vendredi, on ne voit que les collections de ses amis, jamais celles d'inconnus.

Repère E1-E9 : chaque écran porte l'id de l'étape du fichier de référence `build/parcours-demo.md` (E1 carte, E2 fiche du coin, E3 mission, E4 session, E5 photo et verdict, E6 carte et Pescedex, E7 paywall, E8 amis, E9 bredouille). « hors parcours » = écran hors des 9 étapes.

Sources lues : dossier-organisateurs, fonctionnalites, pitch, 4-pistes-produit, 5-faisabilite-peche, 6-idees-pendant-peche et les rapports critique-pendant-peche, faisa-tech, faisa-donnees (dossier kickoff/reports). Le fichier .notes/inputs.md n'existe pas. [inféré] = déduction de ma part, pas un fait source. [?] = non vérifié dans les sources.

Mots à connaître. **Parcours héros** : le trajet de la démo, du lancement à la carte. **Live Activity** : une bulle d'information qui reste sur l'écran verrouillé et dans la Dynamic Island (l'encoche animée de l'iPhone). **Foundation Models** : l'IA d'Apple qui tourne dans l'iPhone, sans réseau. **SwiftData** : la mémoire locale de l'app, sur le téléphone. **Paywall** : l'écran qui propose l'abonnement. **OFB / Hub'Eau** : les relevés officiels de poissons et leur site de données ouvertes.

## 1. Parcours héros de la démo (9 étapes)

Vendredi, le social se limite aux collections des amis (E8). Fil rouge : un pêcheur arrive au bord de l'eau, trouve où aller, attrape (ou pas), reçoit sa carte. Le numéro renvoie à la section 2.

1. **Ouverture et choix du profil** [E1] (A1, A2). Deux boutons : « Je pêche déjà » ou « Je débute ». Puis la permission de position, expliquée en une phrase.
2. **La carte** [E1] (C1). L'écran s'ouvre sur les spots autour de soi. On touche un spot.
3. **Fiche du spot** [E2, E3] (C2). Espèces relevées par l'OFB avec l'année des relevés (Paris n'a que 1989-2011), règle en une phrase, bouton « Commencer une sortie » ; les prises de ses amis sur ce spot (C3). Le profil débutant voit en tête la **Mission première prise** (M1) : spot, heure et montage les plus favorables, formulés en « meilleures chances », sans garantie.
4. **Sortie en cours** [E4] (S1). La Live Activity affiche le temps restant avant la fin légale de pêche (coucher du soleil ou heure réglementaire [inféré]).
5. **Photo de la prise** [E5] (P1). L'utilisateur se photographie avec le poisson. Anneau de 10 secondes « poisson hors de l'eau ».
6. **L'IA propose, l'utilisateur confirme** [E5] (P2). Trois espèces proposées dans une liste fermée, puis saisie de la taille au curseur.
7. **Verdict « peux-tu le garder ? »** [E5, fin] (P3). Feu vert, feu rouge, ou « relâche obligatoire » pour une espèce protégée. La règle vient d'une table sourcée, jamais de l'IA.
8. **La carte à collectionner** [E5 fin + E6] (K1). L'écran montre d'abord la bande de verdict en haut (fin de E5), puis la carte (E6). Rareté propre au département ; lieu arrondi à « rivière, département » (ni point exact, ni commune) ; ajout au Pescedex (K2), compteur du type « 4 espèces sur les 11 relevées dans le 94 ». Variante : l'utilisateur n'a rien pris, il termine la sortie et reçoit la **carte bredouille** [E9] (K3).
9. **Partage et paywall** [E8, E7] (K4, F2, V1). Image de la carte pour une story, avec invitation d'un ami (F2). Puis l'offre d'abonnement, placée juste après cette première valeur.

Preuve à produire avant la démo : ce parcours passé de bout en bout sur un vrai iPhone compatible, hors réseau pour les étapes 5 à 8 [inféré : la promesse « sans réseau » doit être démontrée, pas affirmée].

## 2. Inventaire des écrans et surfaces

Priorité : **Must** = vendredi, **Nice** = si le temps le permet, **v2** = hors vendredi. Coût de construction : S (moins d'une demi-journée), M (une demi-journée à un jour), L (plus d'un jour). Les coûts sont mes estimations [inféré], pas des mesures.

### A. Démarrage et permissions

| ID | Écran | Rôle | Contenu clé | États | Tech Apple | Prio | Coût |
|---|---|---|---|---|---|---|---|
| A1 | Accueil / choix du profil [E1] | Orienter vers le bon parcours | Nom, une phrase, deux boutons « Je pêche déjà » / « Je débute » | une seule | SwiftUI | Must | S |
| A2 | Permission position [E1] | Obtenir la localisation « quand l'app est active » | Phrase de motif, bouton, lien « choisir un département à la main » | accordée, refusée, imprécise | CoreLocation | Must | S |
| A3 | Permission appareil photo [E5] | Prendre la photo de la prise, demandée au moment de la prise et non au démarrage [inféré] | Phrase de motif ; repli : choisir une photo de la bibliothèque | accordée, refusée (repli bibliothèque) | AVFoundation, PhotosPicker | Must | S |
| A4 | Compatibilité IA [E5] | Prévenir si l'iPhone n'a pas Apple Intelligence | Message clair, bascule vers la saisie manuelle de l'espèce | compatible, non compatible, modèle pas encore téléchargé | Foundation Models | Must | S |
| A5 | Permission notifications [hors parcours] | Rappels de fin de pêche | Demandée après la première sortie, pas avant [inféré] | accordée, refusée | UserNotifications | Nice | S |

### B. Carte et spots

| ID | Écran | Rôle | Contenu clé | États | Tech Apple | Prio | Coût |
|---|---|---|---|---|---|---|---|
| C1 | Carte des spots [E1] | Montrer où pêcher autour de soi | Carte, épingles de spots, filtre par espèce, bouton « me localiser ». Carte clairsemée hors des spots saisis par l'équipe (OSM ne compte que 1 624 coins de pêche en France) | chargement, aucun spot proche, hors ligne (carte déjà vue + spots embarqués), position refusée | MapKit, GeoJSON embarqué | Must | L |
| C2 | Fiche d'un spot [E2] | Dire ce qu'on y trouve et ce qu'on a le droit d'y faire | Espèces relevées (source OFB) avec l'année des relevés (Paris : 1989-2011 seulement), règle locale en une phrase, source citée, bouton « Commencer une sortie » | données OFB absentes, règle départementale non couverte (« règle nationale, à vérifier »), hors ligne | MapKit, Hub'Eau précalculé | Must | M |
| C3 | Spot : espèces OFB + prises d'amis [E8] | Compléter la fiche C2 avec ce que les amis y ont pris | Bandeau « Tes amis ici » : cartes d'amis de ce spot ; jamais de carte d'inconnu | aucun ami ici, ami ayant masqué le spot | CloudKit (base partagée), Sign in with Apple [?] | Must | M |
| C4 | Spots secrets [hors parcours] | Partager un coin uniquement avec des amis invités | Position exacte visible des seuls invités, floutée sinon | aucun ami, invitation en attente | CloudKit partage [?] | Nice | M |
| F1 | Amis [E8] | Liste d'amis, demandes en attente, accès à leur Pescedex | Liste, pastille de demandes, bouton « Inviter » | aucun ami (état vide avec invitation), demande en attente, ami bloqué | CloudKit, ShareLink | Must | L |
| F2 | Inviter un ami [E8] | Envoyer un lien d'invitation | Lien ou code à partager par message ; lien reçu ouvre l'app sur « Accepter » | lien expiré, déjà ami, app non installée (page App Store) | ShareLink, Universal Links [inféré] | Must | M |
| F3 | Pescedex d'un ami [E8] | Voir la collection d'un ami et comparer | Grille de ses cartes, espèces que tu n'as pas encore, bouton Signaler / Retirer cet ami | ami sans carte, ami supprimé | CloudKit | Must | M |
| F4 | Créer le compte [E8] | Nécessaire pour les amis | Sign in with Apple, pseudo (filtré), consentement de partage ; suppression de compte dans V2 | échec de connexion, pseudo refusé | Sign in with Apple, CloudKit | Must | M |

### C. Mission première prise

| ID | Écran | Rôle | Contenu clé | États | Tech Apple | Prio | Coût |
|---|---|---|---|---|---|---|---|
| M1 | Mission : le spot [E3] | Proposer un spot proche où un poisson facile a été relevé | Spot choisi, pourquoi (relevés OFB), distance | aucun spot dans le rayon, hors zone couverte | MapKit, calcul local | Must | M |
| M2 | Mission : l'heure [E3] | Dire quand y aller | Créneau, météo prévue | météo indisponible | WeatherKit [?] droit MWM à confirmer | Must | S |
| M3 | Mission : le montage [E3] | Dire quoi monter (ex. gardon au pain, cité par la critique) | 3 étapes illustrées, formulation « meilleures chances », sans garantie | une seule | SwiftUI | Must | M |

Le calcul est un tri sur les relevés et la météo, pas de l'IA : à ne pas présenter comme de l'IA (critique-pendant-peche).

### D. Sortie en cours

| ID | Écran | Rôle | Contenu clé | États | Tech Apple | Prio | Coût |
|---|---|---|---|---|---|---|---|
| S1 | Sortie en cours [E4] | Tenir la session et déclencher une prise | Chrono, compte à rebours de fin légale, gros bouton « J'ai une prise », bouton « Terminer » | en cours, après l'heure légale, app fermée puis rouverte | ActivityKit | Must | M |
| S2 | Live Activity (écran verrouillé) [E4] | Montrer l'heure de fin légale sans ouvrir l'app | Compte à rebours, spot, bouton prise [inféré] | active, terminée, expirée | ActivityKit | Must | M |
| S3 | Dynamic Island [E4] | Version compacte du compte à rebours | Icône poisson + temps restant ; étendue : spot et bouton | compacte, étendue, minimale | ActivityKit | Must (même code que S2) | S |
| S4 | Bilan de sortie [E9] | Clore la sortie | Prises du jour, durée, lieu, météo | sortie avec prises, sortie bredouille | SwiftData | Must | S |

### E. Prise, verdict, carte

| ID | Écran | Rôle | Contenu clé | États | Tech Apple | Prio | Coût |
|---|---|---|---|---|---|---|---|
| P1 | Photo de la prise [E5] | Capturer le poisson vite | Caméra, anneau de 10 s hors de l'eau, conseil mains mouillées | permission refusée, photo floue | AVFoundation | Must | M |
| P2 | Identification [E5] | Proposer l'espèce, faire confirmer, saisir la taille | 3 propositions de la liste fermée, curseur de taille en cm, « aucune de ces espèces » | calcul en cours, IA indisponible (repli : 3 espèces les plus fréquentes du département), poisson non reconnu | Foundation Models avec image, liste fermée | Must | L |
| P2b | Poisson non reconnu [E5] | Ne pas inventer | Message « je ne suis pas sûr », choix manuel dans la liste, option « espèce hors liste » | espèce hors liste, photo sans poisson | Foundation Models | Must | S |
| P3 | Verdict « peux-tu le garder ? » [E5] | Répondre oui, non ou « relâche » | Gros feu vert ou rouge, motif (taille, ouverture, quota), source de la règle | vert, rouge taille, rouge fermeture, quota atteint, règle non couverte (« à vérifier ») | table de règles locale, SwiftData | Must | M |
| P4 | Espèce protégée : relâche obligatoire [E5] | Interdire de garder, expliquer la remise à l'eau | Écran distinct du rouge ordinaire, motif légal, consigne courte | espèce protégée | table de règles | Must | S |
| P5 | Mesure automatique du poisson [hors parcours] | Mesurer par la caméra | Curseur manuel en v1 | n/a | ARKit, LiDAR | v2 | L |

La taille saisie est une indication, jamais une preuve devant un garde-pêche (faisa-tech).

### F. Collection

| ID | Écran | Rôle | Contenu clé | États | Tech Apple | Prio | Coût |
|---|---|---|---|---|---|---|---|
| K1 | Carte à collectionner [E5 fin + E6] | Récompenser la prise | Bande de verdict en haut (fin de E5), puis la carte (E6) : poisson détouré, nom, rareté du département, taille, date, météo, lune, lieu arrondi « rivière, département » (ni point exact, ni commune) | rareté commune à légendaire, détourage raté (repli : photo cadrée) | VisionKit détourage, SwiftUI, ImageRenderer | Must | L |
| K2 | Pescedex [E6] | Voir toute sa collection | Grille espèces, silhouettes grisées pour les espèces non encore prises, compteur du type « 4 espèces sur les 11 relevées dans le 94 » | vide, partielle, filtre par département | SwiftData | Must | M |
| K3 | Carte de la sortie bredouille [E9] | Récompenser une sortie sans poisson | Carte distincte : lieu arrondi « rivière, département », météo, lune, heure | bredouille (l'unique état) | SwiftData, ImageRenderer | Must | M |
| K4 | Image de partage [E8] | Générer l'image pour story ou message | Carte en 9:16, nom de l'app discret, aucun GPS exact | partage réussi, annulé | ShareLink, ImageRenderer | Must | S |
| K5 | Détail d'une carte [hors parcours] | Relire une prise | Carte, verdict de l'époque, supprimer | prise supprimée | SwiftData | Nice | S |
| K6 | Widget « dernière carte » [hors parcours] | Montrer la dernière carte sur l'écran d'accueil | Carte réduite | aucune carte (invitation à pêcher) | WidgetKit | Nice | M |
| K7 | Record du quai [hors parcours] | Classement de la plus grosse prise d'un tronçon | n/a | n/a | CloudKit | v2 | L |
| K8 | Détecteur de touche [hors parcours] | iPhone posé contre la canne vibre à la touche | n/a | n/a | CoreMotion | v2 | M |

### G. Offre, compte, états transversaux

| ID | Écran | Rôle | Contenu clé | États | Tech Apple | Prio | Coût |
|---|---|---|---|---|---|---|---|
| V1 | Paywall [E7] | Proposer l'abonnement après la première valeur (juste après la première carte, K1) | Prix lisible (prix à fixer par Adem, essai 30 jours décidé le 12 oct. à 12h40), restauration des achats, fermeture visible | achat en cours, échec, déjà abonné, hors ligne | StoreKit 2, Spark Flash (MWM) | Must | M |
| V2 | Réglages [hors parcours] | Contact, confidentialité, restauration, suppression de compte | Politique de confidentialité, e-mail de contact (exigé par Apple), suppression du compte (exigée dès qu'un compte existe) | connecté, déconnecté | SwiftUI | Must | S |
| V3 | Fiche de règles par département [E2] | Consulter la règle complète | Tailles, ouvertures, quotas, source, date de saisie | département non couvert (lien fédération) | table locale | Nice | S |
| X1 | État vide : Pescedex [E6] | Inviter à la première prise | Silhouettes grisées + « Commence ta première sortie » | n/a | SwiftUI | Must | S |
| X2 | Hors ligne [E5, E6] | Dire ce qui marche sans réseau | Bandeau discret ; carte, identification et verdict restent disponibles | hors ligne, retour du réseau | NWPathMonitor [inféré] | Must | S |
| X3 | Erreurs [hors parcours] | Position introuvable, photo refusée, IA indisponible, achat échoué | Message court + une action | par cas | SwiftUI | Must | S |
| X4 | Signalement et blocage [E8] | Exigence Apple 1.2 : du contenu d'utilisateurs reste visible, même entre amis | Signaler, Bloquer, contact publié, filtre du pseudo | signalé, bloqué | CloudKit | Must | M |
| X5 | Intent Siri « j'en ai un » [réserve (Siri, vers E5)] | Lancer la prise mains mouillées | Phrase Siri / bouton Action | n/a | App Intents | Nice | S |

Total Must : 31 surfaces, dont 4 de coût L (C1, P2, K1, F1) : c'est le risque de planning [inféré]. Les quatre écrans les plus chers sont la carte, l'identification, la carte à collectionner et les amis, à lancer en premier et en parallèle sur des dossiers séparés.

## 3. Structure de navigation

**Recommandation : 3 onglets et un bouton central.**
- Onglet **Carte** (C1, C2, M1-M3 depuis la fiche d'un spot).
- Onglet **Pescedex** (K2, K5, K3), avec en haut un sélecteur « Moi / Amis » (F1 à F3).
- Onglet **Moi** (réglages, abonnement, règles par département).
- Bouton rond central **Sortie** : ouvre S1, puis P1 à P4, puis K1. Ce bouton est visible partout, parce que pendant la pêche on a les mains mouillées et peu de temps.

Pourquoi : le pêcheur a deux gestes (je cherche, j'ai attrapé) et une envie (je regarde ma collection). Trois onglets les couvrent sans cacher le geste principal. La Mission première prise n'est pas un onglet : elle s'affiche en tête de la carte pour le profil débutant, puis disparaît après la première prise [inféré].

**Alternative : pas d'onglets, la carte plein écran.** Comme dans Plans d'Apple : la carte occupe tout l'écran, une feuille qui remonte du bas contient le spot, la sortie puis la collection. Plus sobre et très « Liquid Glass » (le nouveau style visuel d'iOS), mais la collection, qui est la raison de revenir, devient moins visible, et c'est plus délicat à construire pour des non-développeurs [inféré].

## 4. Les 3 décisions avant de construire les écrans

**Décision 1 (prise le 12 oct.) : qui voit quoi vendredi.** Vendredi, un utilisateur ne voit que les collections de ses amis, jamais celles d'inconnus. Les spots montrent les espèces officielles de l'OFB et les prises des amis seulement. Conséquences : l'app a un compte (Sign in with Apple), des amis, et Apple (règle 1.2) exige quand même filtre du pseudo, signalement, blocage et contact (faisa-tech), mais la file de validation des photos publiques n'est plus nécessaire [inféré]. Reste à choisir comment on devient ami :
- a. Lien d'invitation envoyé par message : seuls des gens qui se connaissent s'ajoutent.
- b. Recherche par pseudo : plus rapide, mais ouvre la porte aux inconnus et à la modération.
- c. Code à 6 caractères à saisir en face à face.
- **Recommandation : a**, avec c en secours si le lien universel pose problème. Option écartée la plus forte : b, qui accélère la croissance mais recrée le risque des inconnus. Les cartes d'amis ne montrent jamais de position exacte.

**Décision 2 : le style visuel des cartes.** Contexte : les images d'espèces de FishBase sont interdites (usage non commercial) et Wikimedia impose des crédits par image (faisa-donnees). La photo de l'utilisateur est toujours disponible. Il manque vos 2 ou 3 références visuelles avant que je dessine quoi que ce soit.
- a. Illustration maison par espèce (10 à 12), cadre graphique, pas de photo.
- b. Photo de l'utilisateur détourée, posée sur un cadre graphique ; rareté signalée par la matière du cadre.
- c. Les deux : l'illustration de l'espèce en fond, la photo détourée au premier plan.
- **Recommandation : b**, avec l'illustration en repli si le détourage échoue. Moins de dessin à produire, et la carte reste celle de l'utilisateur. Option écartée la plus forte : c, plus belle mais deux assets à tenir par carte [inféré].

**Décision 3 : jusqu'où va la règle « peux-tu le garder ? » vendredi.** Contexte : vous visez toute la France. Le socle national (Code de l'environnement) est vérifiable pour tout le pays, mais les arrêtés départementaux changent tailles et quotas (le brochet passe de 0,50 m à 0,60 m en Seine-et-Marne, par exemple), et il n'existe pas de classement 1re/2e catégorie national en données ouvertes (faisa-donnees).
- a. Socle national partout, avec la mention « règle départementale à vérifier ».
- b. Socle national partout, plus 3 à 5 départements saisis à la main depuis l'arrêté, marqués « vérifié ».
- c. Seulement les départements saisis ; ailleurs l'app dit « non couvert ».
- **Recommandation : b**, avec une pastille visible « socle national » ou « arrêté du département vérifié le jj/mm ». C'est la seule option qui tient « toute la France » sans afficher un feu vert faux. Option écartée la plus forte : c, la plus prudente juridiquement mais la démo perd son effet hors des départements saisis. Les règles signalées par les utilisateurs restent à valider avant publication (v2). Quels départements : à vous de les nommer.

## À vérifier avant de dessiner les maquettes [?]
- Précision de l'identification d'espèce : test à 20 photos de vraies prises, seuil à fixer (faisa-tech).
- Droit WeatherKit sur le compte MWM, contenu du SDK Spark Flash.
- Le modèle Foundation Models avec image est une fonction d'iOS 27 documentée surtout par une source secondaire : première chose à essayer sur l'iPhone de test.
