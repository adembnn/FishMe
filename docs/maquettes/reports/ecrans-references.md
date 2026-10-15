# Références d'écrans : ce qui existe et marche, filtré par le jury

Décision débloquée : la structure de chaque écran des maquettes. Date : 12 oct. 2026.
Légende : [V] vu dans une page ou un extrait ouvert pendant la recherche ; [?] non vérifié ou issu de ma mémoire, à contrôler sur capture avant de copier.
Règle du jury (0-cadrage) : P1 = premier moment utile en quelques secondes ; P2 = raison de revenir ; P3 = paywall après la première valeur. ADA = catégories Delight and Fun, Inclusivity, Innovation, Interaction, Social Impact, Visuals and Graphics.
Décision utilisateur intégrée : vendredi, seules les collections d'amis sont visibles, jamais celles d'inconnus. Aucun pattern de fil public n'est retenu (voir écran 13 et la liste "à ne pas copier" en fin).
Le nom de l'app n'est pas fixé ; "Pescedex" désigne seulement la collection de cartes.

## Repères ADA utiles (sources officielles ouvertes)
- 2026 [V] (apple.com/newsroom/2026/06/apple-reveals-winners-of-the-2026-apple-design-awards) : Delight and Fun app = grug ; Interaction app = Moonlitt ; Visuals and Graphics app = Tide Guide ; Innovation app = NBA Live Games & Scores. Finalistes pertinents : The Outsiders: Athlete Tracker (Gentler Stories, Interaction), Tide Guide (aussi finaliste Interaction), (Not Boring) Camera (Visuals), Structured (Inclusivity).
- 2025 [V] (developer.apple.com/design/awards/2025) : Delight and Fun app = CapWords (appareil photo qui transforme un objet en mot/sticker) ; Inclusivity = Speechify ; Innovation = Play ; Visuals = Feather. Finalistes Delight : Lumy, Denim.
- 2023-2024 : non rouvert, [?] (consulter developer.apple.com/design/awards/2024/).
- Lecture pour nous : les gagnants récents sont des apps à UNE idée et une signature visuelle forte (grug, Tide Guide). Tide Guide est aussi la référence directe pour marées/heures de pêche.

---
## 1. Carte d'accueil : spots autour de moi, espèces par spot
Références :
- AllTrails, écran Map et carte "Explore" : https://mobbin.com/explore/screens/2fc9dd60-78a8-4449-80e5-cdc9cd056f38 [V] (éléments listés : épingles, barre de recherche, carrousel, bouton flottant de bascule liste/carte).
- Apple Maps, carte + bottom sheet : https://mobbin.com/explore/screens/ec7ec84d-e5e5-4705-bab8-059948e47470 [V].
- Fishbrain (leader concurrent, cartes de spots + règles GPS) : https://fishbrain.com/features/rules-and-regulations [V].
- Flighty, carte avec bottom sheet : https://mobbin.com/explore/screens/e867ff22-216e-48b0-b29f-3c489c4dddc8 [V].
Pattern à copier : carte plein écran, une feuille basse à trois crans (replié, mi-hauteur, plein) comme Apple Maps ; carrousel de cartes de spots dans la feuille (AllTrails) ; bouton flottant liste/carte ; épingle = pastille avec le nombre d'espèces non encore dans ton Pescedex, pas un pictogramme générique. Mots : "3 nouvelles espèces ici", pas "3 poissons".
Pourquoi : P1 (utile dès l'ouverture, zéro saisie, localisation seulement) ; P2 (le chiffre "nouvelles espèces" change chaque jour). ADA : Interaction (feuille native, gestes iOS) ; Tide Guide 2026 pour la sobriété de lecture en plein soleil.

## 2. Fiche d'un spot (espèces, règles, meilleur moment)
Références :
- Apple Maps, fiche lieu en 6 écrans : https://mobbin.com/explore/flows/ce26b26e-0dd0-4049-894a-f00eec24b0ae [V].
- AllTrails, fiche sentier + profil d'altitude : https://mobbin.com/explore/screens/a7d0eec3-70dc-4be6-a624-05dbe84f9967 [V].
- Tide Guide (App Store id1406371071, ADA 2026) : courbes heure par heure lisibles d'un coup d'oeil [V pour le prix, mise en page [?] à voir sur captures App Store].
- Fish Rules, détail espèce par lieu : https://fishrulesapp.com/ [V].
Pattern : en-tête photo + nom + distance ; juste dessous une frise horaire "meilleur créneau" (barre horizontale, créneau actuel marqué, façon Tide Guide) ; puis grille d'espèces du spot, chaque vignette portant sa rareté locale et un état (déjà prise / manquante en grisé) ; section "Règles ici" en trois lignes (taille mini, période, parcours de pêche/no-kill) ; bouton principal collant "Y aller" ou "Lancer la sortie". Aucune liste de prises d'inconnus : seulement "2 amis ont pris ici".
Pourquoi : P1 (réponse "quoi, quand, ai-je le droit" sans défiler) ; objet de la promesse (règles locales que Fishbrain ignore). ADA : Visuals (frise horaire).

## 3. Capture photo de la prise et identification sur l'appareil
Références :
- Seek by iNaturalist, caméra : https://www.inaturalist.org/pages/seek_app [V], guide PDF https://static.inaturalist.org/wiki_page_attachments/SeekUserGuide2020.pdf [V] (identification en temps réel sur l'appareil, sans compte, compteur de niveaux taxonomiques qui se remplit).
- Merlin Bird ID, Photo ID hors ligne : https://www.merlinbirds.org/photo-id [V] (liste courte de correspondances).
- Fishbrain Fish Identifier : https://fishbrain.com/features/fish-identifier [V] (photo, choix du plan d'eau pour réduire les espèces possibles, puis meilleure réponse + espèces proches).
- CapWords (ADA 2025 Delight) : appareil photo qui détoure l'objet [?, voir fiche App Store id6738896465].
Pattern : viseur plein écran, un seul bouton d'obturateur ; cadre de détourage qui "accroche" le poisson ; le compteur de Seek devient une jauge de confiance en 5 crans plutôt qu'un pourcentage ; si la confiance est basse, trois candidates en vignettes comme Merlin (jamais une réponse unique fausse) ; le lieu est déjà connu, il filtre les candidates comme chez Fishbrain. Un badge "Sur l'appareil" visible : fonctionne sans réseau au bord de l'eau.
Pourquoi : P1 (la photo EST le moment utile) ; l'IA n'est pas décorative (retirer l'IA = plus de produit). ADA : Innovation (modèle sur l'appareil, cf. Foundation Models) ; Inclusivity (VoiceOver sur l'obturateur, résultat lu à voix haute).

## 4. Révélation de la carte (rareté)
Références :
- Pokémon TCG Pocket, ouverture de paquet : https://press.pokemon.com/en/Pokemon-Trading-Card-Game-Pocket-Launches-Today-Offering-a-Fresh-Take- [V], geste de glisser pour déchirer le paquet [V via dxcollection.com.sg]. Rareté en losanges/étoiles/couronnes, symbole en bas à gauche de la carte [V] (ptcgpocket.gg/pokemon-tcg-pocket-rarity-explained-every-diamond-star-and-crown). Animation spéciale conditionnée à une carte très rare (patch du 29 juil. 2026) [V] : les cartes communes se révèlent sobrement.
- Pokémon GO, écran de capture "nouvelle entrée enregistrée" [?, à contrôler sur vidéo].
- Seek, écran "Observation ajoutée" avec badge [V pour le principe].
Pattern : une seule carte, pas un paquet ; carte face cachée, geste de retournement ; la rareté se lit par un symbole fixe (3 paliers, forme + couleur, jamais la couleur seule) ; l'effet visuel (reflet holographique via gyroscope) n'apparaît qu'à partir du palier 2, comme TCG Pocket qui réserve l'animation spéciale aux raretés hautes. Mention "Rare en Doubs, commun en Loire" : c'est la rareté départementale, notre différence.
Pourquoi : P2 (récompense variable, tirage dépend du lieu, donc de la sortie). ADA : Delight and Fun (grug montre qu'une idée simple très soignée gagne) ; Visuals.
Garde-fou : la réduction de mouvement iOS doit remplacer l'effet par un fondu.

## 5. Verdict "je peux la garder ?" (taille, saison, quota, espèce protégée)
Références :
- Fish Rules : https://fishrulesapp.com/ [V] (en un coup d'oeil : en saison ou non, combien, taille minimale ; fonctionne hors ligne, rappel par GPS et calendrier).
- Fishbrain Rules : https://fishbrain.com/features/rules-and-regulations [V] (par espèce : saison ouverte/fermée, quota, taille mini/maxi, méthodes interdites).
- Merlin / Seek : niveaux de confiance affichés [V].
Pattern : un verdict en haut, en un mot et une couleur plus un pictogramme (GARDER / REMETTRE À L'EAU / PROTÉGÉE : REMISE OBLIGATOIRE), puis la règle qui le justifie sur deux lignes ("40 cm mini, la tienne : 52 cm. Ouverture jusqu'au 31 déc."). Une règle de longueur : réglette visuelle avec la taille mesurée posée sur le minimum. Espèce protégée : l'écran passe en ton calme, pas rouge alarmant, et la carte est quand même gagnée ("relâcher fait partie du jeu"). Mention de la source (arrêté préfectoral, date de mise à jour) et d'un lien de signalement d'erreur.
Pourquoi : P1 (réponse immédiate) ; Social Impact (protection des espèces). ADA : Social Impact ; Inclusivity (ne dépend pas de la couleur : mot + icône).
Risque : valeur juridique. Prévoir "indicatif, vérifier l'arrêté" ; non vérifié côté App Store (review).

## 6. Index de collection (Pescedex) : manquantes grisées, complétion
Références :
- Pokémon TCG Pocket, vue "Pokédex" des cartes manquantes : https://www.pokemon-zone.com/articles/pokemon-tcg-pocket-collection-hacks [V] (bascule Pokédex pour voir ce qui manque, filtre par paquet, pincement pour passer de 3 à 11 colonnes).
- Pokémon GO, Pokédex avec silhouettes : [?].
- Seek / Merlin Life List : https://merlin.allaboutbirds.org/ [V] (liste de vie) ; badges Seek [V].
Pattern : grille de cartes à trois colonnes, pincement pour dézoomer (11 colonnes dans Pocket) ; manquantes en silhouette avec numéro et nom d'indice seulement ("Truite fario, rivières froides"), pas de photo ; bandeau de complétion en tête ("47 / 112 · Bretagne 18/31") ; filtres : département, milieu, rareté ; bascule "Que les manquantes". Les espèces manquantes du département courant remontent en premier : ce qui relie l'index à la carte.
Pourquoi : P2 (la jauge à compléter est la raison de revenir). ADA : Delight and Fun ; Visuals.

## 7. Mission "première prise" (première sortie guidée)
Références :
- Duolingo : onboarding qui fait essayer avant de demander un compte ni des permissions [V] (uxplanet.org/why-permission-priming-is-good-ux-19c675754dbb).
- Seek : « no login or account required » et premier ajout aux observations dès la première visée [V].
- Finch : premiers objectifs déjà posés à l'arrivée, « Your First Goals and Adventure » [V] (help.finchcare.com New User Guide).
- Pikmin Bloom : [?] sortie guidée, à documenter.
Pattern : une seule carte-mission en tête de la carte d'accueil : "Mission première prise : un spot à 12 min, une heure, un montage". Trois étapes cochables (choisir, y aller, photographier). Le spot, l'heure, le montage sont déjà choisis ; l'utilisateur peut les changer, mais n'a rien à régler pour commencer. Fin de mission = première carte + invitation à créer le compte.
Pourquoi : P1 et P2 (la mission finit sur une récompense et propose la suivante). Le jury accepte mal un onboarding lourd : la mission remplace le tutoriel.

## 8. Carte "sortie bredouille"
Références :
- Finch : streak qui pardonne (pause, réparation gratuite toutes les 3 aventures, « gentle consistency, not perfection ») [V] help.finchcare.com/hc/en-us/articles/37780736136205.
- Gentler Streak : séance adaptée à la forme du jour, finaliste ADA 2026 sous The Outsiders (même studio) [V pour le finaliste].
- Duolingo streak freeze [?].
Pattern : une sortie sans prise produit une carte "Sortie" : lieu, durée, météo, espèces qui étaient possibles ici, une phrase d'observation ; rareté nommée "Patience" ou semblable, jamais "raté". Pas de série qui casse : la sortie compte comme jour. Texte : "3 h au bord du Loing. Rien n'a mordu. Carte gagnée."
Pourquoi : P2 (aucune sortie ne casse l'habitude) ; Inclusivity (pas de culpabilité). Écart avec le marché : aucune app étudiée par Adem ne récompense la sortie sans prise.

## 9. Live Activity / Dynamic Island : compte à rebours
Références :
- Apple HIG Live Activities : https://developer.apple.com/design/human-interface-guidelines/live-activities [V] (compact : deux éléments de chaque côté de la caméra ; minimal affiche la donnée utile, ex. le minuteur montre le temps restant plutôt qu'un logo ; expansé au toucher long ; coin de 44 pt).
- Flighty, « Behind the Design » : https://developer.apple.com/news/?id=970ncww4 [V] (une ligne par vol comme un tableau d'aéroport ; bascule en barre de progression ; cercle de progression en minimal).
- Uber (compte à rebours de prise en charge) [V via onesignal.com/blog/best-examples-of-apps-using-live-activities-to-enrich-their-ux] ; Gentler Streak, Slopes [V même source].
- NBA Live Games & Scores, ADA 2026 Innovation [V pour le prix ; lien Live Activity [?]].
Pattern : compte à rebours jusqu'au meilleur créneau ("Brochet : fenêtre dans 42 min"), puis bascule en chronomètre de sortie ; compact : icône de l'espèce à gauche, temps à droite ; minimal : seul le temps ; expansé : spot, créneau, bouton "Photographier". Un seul chiffre, pas de logo décoratif.
Pourquoi : P2 (rappel contextuel, hors de l'app) ; ADA Innovation ; vitrine explicite de la techno demandée par l'organisateur. Limite : 3 activités simultanées sur iPhone 18 Pro [V] (appleinsider, sept. 2026), 2 avant.

## 10. Paywall après la première valeur
Références :
- Finch, historique des paywalls : https://www.paywallscreens.com/apps/finch-mobile-paywall-c882 [V] (liste datée de ses écrans).
- ScreensDesign, 10 écrans d'essai gratuit : https://screensdesign.com/articles/free-trial-onboarding-best-practices [V] (frise de l'essai, rappel, prix annuel, fin d'essai sur le même écran).
- Headspace / Calm : frise "Aujourd'hui, J-2 rappel, J-7 facturation" [?, à voir sur Mobbin].
- Duolingo : une plainte publique sur le rappel d'essai non reçu [V reddit] : si on promet un rappel, il doit partir.
Pattern : le paywall s'ouvre après la première carte révélée, jamais avant. Fond = la carte qu'il vient de gagner, floutée au bord. Bénéfices en une phrase chacun ("Toutes les cartes de France", "Alertes meilleur créneau", "Collections d'amis illimitées"). Frise d'essai en trois points avec la date réelle de facturation. Bouton de fermeture visible, choix annuel/mensuel avec prix par mois du plan annuel. Rappel envoyé 2 jours avant (promesse tenue via notification locale).
Pourquoi : P3 explicite. La frise lève la peur de la facturation, ce qui sert la confiance (Apple refuse les paywalls opaques [?]).
Ne pas faire : paywall avant la première prise, cartes d'inconnus bloquées pour pousser à payer (n'existent plus).

## 11. Image de partage d'une carte
Références :
- Spotify Wrapped : cartes verticales 9:16 une idée par carte, fond plein, un grand chiffre, prêtes pour les stories [?, voir spotify.com/wrapped].
- Duolingo, carte de partage de Friends Quest : coffre au centre, deux avatars, « Nico and I completed the Friend Quest! » [V] blog.duolingo.com/friends-quests.
- Strava, image d'activité avec tracé [?].
Pattern : format 9:16 et 1:1, la carte seule au centre, rareté lisible sans légende, lieu arrondi au département (jamais le spot exact : coin secret protégé), prénom du pêcheur, petite marque en bas. Feuille de partage native avec aperçu avant envoi. Le destinataire qui ouvre le lien arrive sur "Voir la carte de Léa, rejoins-la" : c'est l'entrée de l'écran 13.
Pourquoi : acquisition (promesse compréhensible en une image) sans passer par un fil public. ADA : Visuals.

## 12. Onboarding et permissions
Références :
- Duolingo : essayer d'abord, compte et notifications ensuite, avec la raison donnée [V] (uxplanet.org article).
- Pushengage : « soft-ask » avant la demande système [V], principe d'écran de préparation maison.
- Seek : localisation approximative uniquement, sans compte, rassurant pour les mineurs [V] (App Store / Google Play).
- AllTrails, Flighty : Onboarding listé sur la carte Flighty [V, Mobbin].
Pattern : écran 1 = la carte de France avec ses spots, sans question. Demande de localisation au moment où le premier spot est montré, avec une phrase maison avant le dialogue iOS ("Pour trouver les spots autour de toi"), puis appareil photo seulement à l'ouverture du viseur, notifications seulement après la première carte. Trois permissions, trois moments, aucune au premier lancement. Date de naissance : demandée uniquement pour adapter le texte aux moins de 18 ans [?, cadre légal à vérifier avant maquette].
Pourquoi : P1 (valeur avant friction). 373 891 pêcheurs mineurs (FNPF) : les permissions expliquées comptent plus pour ce public. ADA : Inclusivity.

## 13. Collections d'amis et invitation (nouvel écran, décision utilisateur)
Références :
- Apple Fitness, partage d'activité : https://support.apple.com/guide/iphone/share-your-activity-iph0b826155d/ios [V] (onglet Partage, « Inviter un ami », section "Invités" avec "Inviter à nouveau", glisser pour retirer, anneaux des 7 derniers jours de chaque ami).
- BeReal, ajouter des amis : https://help.bereal.com/hc/en-us/articles/7537949847069-Invite-Add-Friends [V] (inviter par pseudo, depuis les contacts, personnes que vous connaissez). À copier : l'invitation par pseudo et par contacts. À ne pas copier : « Friends of Friends » (https://help.bereal.com/hc/en-us/articles/11773264475933-Friends-of-Friends [V]), c'est justement l'exposition à des inconnus.
- Duolingo, Friends Quests et Friend Streak : https://blog.duolingo.com/friends-quests [V] et https://blog.duolingo.com/friend-streak [V] (série partagée avec jusqu'à 5 amis, invitation à accepter, « shared commitment »).
- Apple Find My, personnes : https://apps.apple.com/us/app/find-my-friends/id466122094 [V] (partage choisi dans les contacts, par e-mail ou numéro, ou par AirDrop, temporaire ou permanent).
- Strava clubs / invitation à une activité : https://support.strava.com/hc/en-us/articles/115001631264-Inviting-a-Friend-to-Your-Activity [V] (bouton "Inviter des amis" qui produit un lien partageable si l'ami n'a pas l'app).
Pattern : onglet "Amis" avec trois blocs. (1) Rangée d'amis, avatar + complétion ("Léa · 63/112") comme les anneaux d'Apple Fitness ; toucher ouvre sa collection en lecture seule, ses cartes avec rareté, ses spots arrondis au département. (2) Carte "Inviter un ami" : lien de partage + AirDrop + contacts, trois boutons, comme Strava/Find My ; invités en attente listés avec "Inviter à nouveau" (Fitness). (3) Défi à deux de la semaine (Duolingo Friends Quest) : "Complétez 5 espèces du bassin de la Loire à deux". Réglage par ami : "Voir mes spots exacts : non" par défaut. Aucune recherche de pseudo ouverte, aucun classement public, aucune suggestion "personnes que tu pourrais connaître" (BeReal).
Pourquoi : P2 (lien social = raison de revenir, déjà établi par Fitness et Duolingo) et acquisition (chaque invitation est un lien de partage de l'écran 11). Réponse aux critères de modération App Store : pas de contenu d'inconnus à modérer, donc moindre risque de rejet (0-cadrage). ADA : Social Impact limité, Delight and Fun.
Question ouverte : l'invitation exige-t-elle un compte, ou un lien suffit-il ? Reco : lien d'invitation + compte Apple.

---
## À ne pas copier (retirés suite à la décision "amis seulement")
- Fil public de prises, abonnés, hashtags, classement ouvert (Fishbrain, FishAngler, Strava feed).
- "Personnes que tu peux connaître", friends-of-friends (BeReal).
- Carte avec prises visibles d'inconnus. La fiche spot ne montre que les amis qui y ont pêché.
- Paywall qui verrouille la vue des inconnus.

## Ce qui reste incertain avant les maquettes
- Pokémon GO, Pikmin Bloom, Headspace/Calm, Spotify Wrapped, Strava feed, Duolingo streak freeze : aucune page de capture ouverte, à compléter via Mobbin ou ScreensDesign avant de figer le détail.
- ADA 2023 et 2024 : non consultés.
- Texte légal sur les règles de pêche et l'âge : à valider par Adem.
