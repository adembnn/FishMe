Tenues : 14 · Rejetées : 15 · Questions pour Adem : 3

Contrôle fait sur la branche claude/finir-app-ud5swp. Elle a avancé depuis 493bcb1. J'ai relu le code du dernier commit (52840a4). Les rapports ont été écrits sur 493bcb1, donc certains défauts sont déjà corrigés. Sur 493bcb1, les 9 rapports ne sont pas écrits dans /mnt/project-files/build/banc/passe-3/ pour 4 profils (les agents n'avaient pas le droit d'écrire). Leur texte est dans leur retour, je l'ai lu. Aucune capture n'existe (seulement des widgets dans /home/user/Build-Challenge-Unaite-MWM-Apple-F/reports/ecrans/L15/). Tout ce qui est taille, vitesse ou lisibilité reste non constatable.

CE QUI EST DÉJÀ EN COURS : ça tient, et c'est corrigé dans le code actuel
- Verdict « Taille légale » malgré des lignes à vérifier : le défaut était réel sur 493bcb1 (PriseLogique.swift:123-133). Corrigé : PriseLogique.swift:133-137 (nouveau cas tailleRespecteeAVerifier) et :146-157 (lignes qui bloquent le vert). Le titre vert reste en PriseVuesResultat.swift:278, seulement si rien n'est à vérifier. Le cas du brochet 94 à 65 cm tombe donc.
- Consommation, mode de pêche et carpe de nuit en vert : défaut réel (MoteurRegles.swift:510-512 renvoie « respectée »). Corrigé côté écran : LigneRegleView.swift:123 et PriseLogique.swift:171. Core garde « respectée » par choix, ça ne gêne plus l'affichage.
- Carpe de nuit hors rivière : défaut réel sur 493bcb1 (94.json:923, portée « departement » sans test de l'eau). Je n'ai pas re-testé le correctif.
- Paywall Gratuit / Pro : défaut réel sur 493bcb1 (PaywallVue.swift:129-132). Corrigé par b0067b3 (tableau dans TextesPaywall.swift:121-131). Le mensuel reste absent (ChoixOffres.mensuelRetenu nil) : décision d'Adem, pas un défaut.
- Position refusée : défauts réels sur 493bcb1 (« Pêcher maintenant » sans effet, pas de spot). Corrigé par 62b6dbe (VueCarte.swift:148 : le spot proposé remonte à la racine).
- Textes OFB, dernier relevé, catégorie, niveau « Je débute » : réels. Corrigés par 84ba9f6 (TexteOFB et TexteCategorie dans StyleCarte.swift, CarteAEssayerView.swift:101).
- Pescedex vide : réel, corrigé par 84ba9f6.
- Taille mémorisée, révélation directe, AR jamais traitée comme une saisie : corrigé par 52840a4. Le défaut AR (PriseModele.swift:219) était fondé : docs/parcours-demo.md E5 dit « une mesure en réalité augmentée ne donne jamais de verdict ».
- Truitiste B2 (le tronçon « j'y suis ? » ignoré dans la prise) : corrigé, RootView.swift:427-433 lit maintenant le choix enregistré.

1. BLOQUANT POUR APPLE
1. Lien de confidentialité provisoire : il pointe vers la page de confidentialité d'Apple, pas vers celle de l'app. Preuve : App/RootView.swift:517 (« PROVISOIRE… À remplacer avant l'envoi »), utilisé en :509, :699 et :979 (paywall et Mon club). Aucun profil ne l'a relevé, je l'ai trouvé. Cause de refus classique (5.1.1 et 3.1.2). Correction : mettre la vraie page publiée via le MCP de MWM, une ligne (5 min une fois l'adresse connue). Propriétaire : Adem ou MWM pour l'adresse, puis code sur cette branche.
2. Adresse de contact vide : « Contact » et « Signaler une erreur de règle » n'existent pas dans le build. Preuve : App/Club/ClubDonnees.swift:48 (adresse = ""), ClubView.swift:100-109. Le signalement des amis part avec la même adresse vide (RootView.swift:200, Signalement.swift:4-15). Relevé par aappma et coup (2 profils), prouvé dans le code. Fondé : docs/parcours-demo.md E8 (contact et « signaler une erreur de règle »), règle 1.2 d'Apple si les amis restent. Correction : écrire l'adresse (1 minute). Propriétaire : Adem (donner l'adresse), puis code.

2. BLOQUANT POUR LA DÉMO
Rien de nouveau. Les trois points qui bloquaient la démo (verdict vert, position refusée, tunnel muet) sont corrigés. Le point 2 ci-dessus coupe aussi E8 : un jury qui cherche « signaler une erreur » ne la trouve pas.

3. LE RESTE (tenu, par ordre d'importance)
1. Règles tout en bas de la fiche du coin, après les espèces, et une centaine de lignes sans filtre d'espèce. Preuve : App/Carte/Vues/FicheCoinView.swift:25-32 et :178. Relevé par carpiste, streeteur et truitiste (3 profils). Le filtre d'espèce ne propose que les espèces relevées (FicheCoinView.swift:144-166), donc une truite absente des relevés est inatteignable (truitiste G2). Correction : mettre la ligne du jour (nuit, no-kill, consommation) en tête, et proposer toujours la truite en 1re catégorie (30 min). Propriétaire : code.
2. « Mon club » : association jamais donnée, fédération jamais nommée, deux lignes pour la même adresse. Preuve : RootView.swift:697 (association: nil) ; nomFederation jamais rempli ; ClubView.swift:44 et :51 ouvrent la même page. Relevé par aappma et coup. Le fichier liens-federations.json a le nom du département mais pas celui de la fédération. E8 interdit l'annuaire des associations (pas d'accord), donc le manque est voulu. Reste l'étiquette qui promet plus que le lien. Correction : renommer en « Cartes de pêche, site officiel », supprimer le doublon, afficher « Fédération de l'Ain » depuis le nom du département (15 min). Propriétaire : code.
3. Écran « Ta zone » : zone: nil toujours, la rangée « Conseils de pêche » jamais montrée. Preuve : RootView.swift:657. Un seul profil (debutant), mais prouvé et contraire à CLAUDE.md (« sans spot, conseils et Pescedex restent accessibles »). Correction : brancher la zone choisie et ouvrirConseils (20 min). Propriétaire : code.
4. Verso de la carte : le contrôle est refait avec un lieu vide, et la source affichée est celle de la 1re ligne, pas de la ligne qui décide. Preuve : App/Collection/InfosCarte.swift:49-50. Un seul profil (garde-pêche), prouvé par moi. Risque : « Relâche-la (source : R436-13) » pour une taille. Correction : enregistrer la consigne et sa source au moment de la prise (20 min). Propriétaire : code.
5. Lignes sans date de lecture : MoteurRegles.swift:141-155, :332-361, :581-599 (anguille, espèce protégée, sans URL) et la ligne de carpe de nuit (:637, alors que la règle porte sa date). Contraire à docs/banc/mots-interdits.md:18. Un profil, prouvé. Correction : passer la date de la règle à la ligne de nuit, et nommer une source pour l'anguille (15 min). Propriétaire : code.
6. Quota du jour compté en jour UTC. Preuve : MoteurRegles.swift:481 contre SuiviSession.swift:99 (calendrier de l'app). Une prise entre minuit et 2 h à Paris est comptée la veille. Un profil, prouvé. Correction : calendrier de Paris dans Core (10 min). Propriétaire : code.
7. Données : sur 10 règles tirées au hasard, 4 ont une citation qui ne prouve pas la phrase (16-truite-no_kill-boeme-amont, 68-toutes-interdit-appat, 85-reserve-frayere-lac-du-marillet, 28-tous-interdit-huisne). Je n'ai pas refait le tirage. Un profil, non prouvé par moi. 206 phrases disent « se garde à partir de N cm » hors des 5 départements saisis, ce qui frôle « jamais tu peux la garder » (CLAUDE.md). Correction : réécrire en « taille minimale N cm » par script (15 min), et filtrer les citations trop courtes à la relecture double. Propriétaire : data regles/local.
8. Données : Ain, truite « 25 cm (30 cm sur certains secteurs) » : le seuil bas s'affiche si l'eau n'est pas reconnue. Correction : passer à « vérifie l'arrêté » tant que l'eau n'est pas confirmée. Un profil, non constatable sans géo. Propriétaire : data regles/local.
9. Brochet/sandre 75, 92, 94 : la citation affichée est celle de l'avis 2026 sous le lien de l'arrêté (garde, aappma). La décision d'Adem (11h13) tient, mais il manque la citation de l'arrêté. Correction : une citation par source (20 min, data). Propriétaire : data regles/local.
10. Carte partagée avec les amis : champ date exact (App/Amis/CartePartagee.swift:~13-17), alors que l'image est limitée au mois et à l'année (CarteRectoView.swift:194-195). Un profil, prouvé. Visible seulement par les amis invités. Correction : mois et année (10 min). Propriétaire : code.
11. Détails : « Passer » du tunnel en haut à droite (TunnelPremiersPasView.swift:34) ; texte « Mesure d'audience » ; le chemin d'une prise garde 6 à 9 touchers (voir question 2) ; deux boutons peut-être sous 44 pt (FicheCoinView.swift:74-79, LigneRegleView.swift:53) mais non constatable ; « Lue le » contre « Lu le » (PriseVuesResultat.swift:410, LigneRegleView.swift:85) ; « Restaurer » au lieu de « Restaurer les achats » (PaywallVue.swift:234) ; lien http du 75 et 94 (le JSON l'explique). Propriétaire : code, 20 min en tout.

4. À TRANCHER PAR ADEM (3, la plus lourde d'abord)
1. Les amis partent-ils dans la version envoyée, et quelle est l'adresse de contact ? Docs/app-store.md:46 (R5) dit « amis hors du build, code retiré », parcours-demo.md:27 dit « mise à jour », mais CLAUDE.md (14h42, « tout part chez Apple ») et RootView.swift:716 et :728 montrent « Mes amis » dans le build. a. Amis dans le build : il faut l'adresse et le signalement qui marche (règle 1.2). b. Amis cachés derrière un drapeau jusqu'à la mise à jour. Ma reco : b, plus l'adresse de contact dans les deux cas. Par défaut : je garde les amis, mais Apple peut refuser sans adresse.
2. Une prise coûte 6 à 9 touchers (Valider, Continuer, « Ta prise » gardée/relâchée, Ajouter au Pescedex). Relevé par coup, debutant et streeteur (3 profils). Le seuil de 2 touchers est posé par le banc, pas écrit par Adem (personas.md:168). L'écran « Ta prise » sert au quota (gardée ou non). a. Fusionner « Ta prise » dans l'écran taille avec relâchée par défaut. b. Garder le parcours E5 tel quel. Ma reco : a, 45 min, retire un écran. Par défaut : b. À côté : dix gardons donnent une carte, sans « x10 » (personas.md:168 renvoie à Adem).
3. La session s'arrête à la fin légale (E4, Adem). Le carpiste de nuit voit sa session fermée à 19 h (SuiviSession.swift:135-171). a. Garder E4. b. Ne pas fermer la session si le pêcheur a lu une règle de nuit « autorisée » sur son coin. Ma reco : a, avec une phrase sur l'écran de fin. Par défaut : a. Un seul profil, donc faible.

5. À VOIR (gênant ou goût, tenu)
- Verdict « Gardée/Relâchée » choisi avant de voir le verdict (PriseVuesResultat.swift:137-139) : goût, E5 ne fixe pas l'ordre.
- Carte du verdict différente de la carte révélée (PriseVuesResultat.swift:297-322), commun #6B7780 et peu commun #23885A proches (Style.swift:77-78) : palette validée le 15 oct. 18h30, donc à signaler seulement.
- Brochet 94 « 50 ou 60, vérifie » : décision du 15 oct. 11h13, le ton hésitant est voulu.
- Deux lignes de réserve d'ouvrages (nationale et 94) côte à côte : périmètre à confirmer.
- PAR-M1 : carte de pêche d'un enfant, aucune règle ; à voir.
- Réserves saisonnières toujours « à vérifier » (MoteurRegles.swift:503-505) : prudent, bruyant.

6. REJETÉES
- Question du niveau en plein écran (designer 1) : corrigé en demi-feuille par 84ba9f6.
- Révélation sans fin, taille 78 cm de départ, « Dix gardons » (coup 1, 3) : déjà traité par 52840a4.
- « À essayer » s'ouvre à chaque session (streeteur 4) : E4 de parcours-demo.md l'exige.
- Pas de météo de nuit gratuite (carpiste 5) : décision E2 et E7.
- « Fin légale » en avant pour un pêcheur de nuit (carpiste 6), « no-kill » dans le texte de nuit (carpiste 8) : goût, sans source dans personas.md.
- 24 règles du 94 sans étiquette « non relue » (aappma 6), « aucune règle confirmée » (garde) : Adem a décidé le 15 oct. 11h34 de ne pas étiqueter, et la fusion prudente remplace « confirmée seulement » (docs/donnees.md:62). « brouillon » est le statut normal de 18 920 règles.
- Checklist store/fonctions-du-build.md vide (jure 6) : elle se coche à la porte 3, sur l'iPhone.
- « Tarif fondateur » absent du paywall (debutant) : CLAUDE.md dit « prix de lancement ».
- Spot gratuit figé après la 1re session (streeteur 7), « Choisir un autre spot » ouvre un filtre (debutant 15) : décisions d'Adem du 15 oct. (12h26, 13h24, 13h55).
- Règles expirées au 1er janvier 2027 (truitiste D2) : décision CLAUDE.md (avis 2026 expire le 31/12/2026).
- Textes 11 pt, gros nombres fixes, boutons sous 44 pt, lisibilité au soleil (designer 6, 7 ; aappma 8 ; streeteur 8 ; debutant 7) : non constatables sans app vivante.
- Même icône pour « sous la taille » et « relâche-la » (designer 10) : goût, sans règle.
- Consentement Accepter/Refuser au même poids (jure 5) : conforme, c'est voulu.
- Tunnel sans indication de glissement (designer 8) : non constaté, pas de capture.
- Jure 3 (pas de mensuel) : décision d'Adem encore ouverte, déjà notée dans CLAUDE.md.

Fichiers clés : /home/user/Build-Challenge-Unaite-MWM-Apple-F/App/RootView.swift, /home/user/Build-Challenge-Unaite-MWM-Apple-F/App/Club/ClubDonnees.swift, /home/user/Build-Challenge-Unaite-MWM-Apple-F/App/Club/ClubView.swift, /home/user/Build-Challenge-Unaite-MWM-Apple-F/App/Prise/PriseLogique.swift, /home/user/Build-Challenge-Unaite-MWM-Apple-F/App/Collection/InfosCarte.swift, /home/user/Build-Challenge-Unaite-MWM-Apple-F/Packages/Core/Sources/Core/Regles/MoteurRegles.swift, /home/user/Build-Challenge-Unaite-MWM-Apple-F/App/Carte/Vues/FicheCoinView.swift

---
## Suite donnée (16 oct., ~4h30 UTC, branche claude/finir-app-ud5swp)
- Corrigé : verdict sans coche verte (4a6d90d), interdictions jamais vertes et carpe de nuit (f1c75ef), paywall Gratuit/Pro (b0067b3) et verrous réels (dfdc1f0), position refusée (62b6dbe), textes débutants (84ba9f6), prise rapide (52840a4), fiche du coin (1c17e6a), club, verso, partage (53fd35a), quota au jour de Paris et dates de lecture (885dda3), phrases « se garde » neutres (f1c75ef).
- Reste à Adem : adresse de contact, page de confidentialité MWM, mensuel, amis dans la version soumise (par défaut gardés).
- Reste aux données (regles/local) : citations qui ne prouvent pas la phrase (16, 28, 68, 85), maille de l'Ain, une citation par source pour 75/92/94.
