# Idées — angle « transfert » (mécanique éprouvée ailleurs, posée sur un usage iPhone du quotidien)

Vérifications web (3 recherches, puis quota de l'outil atteint) : voir la ligne « Concurrence » de chaque idée. Ce qui n'a pas pu être vérifié est marqué « à vérifier ». Écartée après vérification : le chronométrage inversé de plusieurs plats pour un dîner (MealTime, Chef's Multi-Dish Timer, Cooking de Cinnamon Mobile existent déjà).

---

## 1. **Juste Match** — un handicap à la golfeur pour les amis, pour jouer à armes égales ce soir

- **Mécanique** : on dicte « Léa bat Tom 21-15 au ping-pong » (Siri / App Intent), l'app tient un indice de niveau par joueur et par jeu, et avant la partie suivante annonce l'avance à donner (« Tom démarre à 6 points, Léa joue de la main gauche »). Pour un jeu inconnu (« fléchettes, 4 joueurs »), Foundation Models propose la règle d'égalisation en sortie typée (@Generable) : points d'avance, vies, contraintes ; le calcul de l'indice reste déterministe.
- **Cas fondateur** : le World Handicap System du golf permet « à des golfeurs de niveaux différents de jouer sur une base équitable, dans n'importe quel format » ; ~15 M de golfeurs, 131 pays adoptants en mai 2025 (https://www.whs.com/ ; https://www.usga.org/content/usga/home-page/articles/2020/01/world-handicap-system-is-here-2020.html). Personne n'a posé ça sur ping-pong, pétanque, Mario Kart, jeux de société entre amis inégaux.
- **Concurrence** : les apps de handicap sont golf-only (ex. https://apps.apple.com/us/app/golf-handicap-online-golf/id1360641725). Aucune app grand public « handicap multi-jeux » trouvée, à vérifier plus largement (apps Elo / classement de ligue).
- **Offre** : gratuit 1 groupe et 2 jeux ; Pro 14,99 €/an (groupes illimités, saison, carte de classement partageable). Essai 7 jours après la première partie enregistrée. Raison de revenir : chaque soirée de jeu, le classement de saison, le widget « prochain duel et avance ».
- **Brique Apple** : App Intents / Siri (saisie vocale du score), Foundation Models (règle d'égalisation par jeu, extraction du score), widgets, ImageRenderer (carte de saison à partager).
- **Honnêteté IA** : moyenne. Sans l'IA, la saisie manuelle marche ; l'IA rend le « n'importe quel jeu » possible sans catalogue. C'est le point faible à défendre devant le jury.
- **Probabilité qu'un autre LLM la propose : 15 %**

## 2. **Demi-tour** — l'heure de rebroussement des alpinistes pour les randonneurs et cyclistes du week-end, pour ne pas se faire piéger par la nuit

- **Mécanique** : avant de partir, on dicte « boucle de 18 km, 900 m de D+, départ 11h » ; l'app calcule l'heure de demi-tour (allure, coucher du soleil, météo WeatherKit) et les « minimums personnels » (vent, température, lumière) choisis à froid. À l'heure H, une alarme AlarmKit sonne même en silencieux, et une Live Activity affiche « demi-tour dans 12 min ».
- **Cas fondateur** : Everest 1996, huit morts le 10-11 mai ; les guides avaient fixé une heure de rebroussement (14 h) que beaucoup ont dépassée de deux heures et plus (https://www.history.com/articles/the-single-deadliest-day-for-climbers-on-mount-everest ; https://www.nationalgeographic.com/adventure/article/ed-viesturs). Règle appliquée en aviation sous le nom de « minimums personnels ». On transfère l'idée : décider à froid, obéir à chaud.
- **Concurrence** : apps de rando (Komoot, Strava, AllTrails) font itinéraires et suivi, pas d'engagement pré-décidé avec alarme. À vérifier plus largement (recherche non terminée).
- **Offre** : 3 sorties gratuites, puis 19,99 €/an ou 3,99 €/mois ; essai 7 jours après la première alarme programmée. Raison de revenir : chaque sortie (saison longue pour randonnée, vélo, sortie en mer) ; widget « lumière restante aujourd'hui ».
- **Brique Apple** : AlarmKit (iOS 26), Live Activities, WeatherKit, Foundation Models (description libre vers plan typé), Apple Watch en haptique.
- **Honnêteté IA** : moyenne. Le moteur est une formule (Naismith/Tobler) ; l'IA sert à la saisie libre. La capacité Apple (AlarmKit + Live Activity) est la vraie brique indispensable. Ni santé ni sécurité certifiée : on se présente comme « discipline personnelle », pas comme secours.
- **Probabilité qu'un autre LLM la propose : 12 %**

## 3. **Mise Corvée** — une enchère à l'aveugle des tâches pour les colocs et couples, pour répartir sans dispute chaque semaine

- **Mécanique** : on photographie ou dicte la pièce (« salle de bain, poubelles, frigo ») ; Foundation Models sort la liste de tâches avec une durée estimée. Chacun reçoit 100 points et les place en secret sur les tâches qu'il déteste le plus (mode « on passe le téléphone », sans compte ni serveur) ; l'algorithme attribue chaque tâche, la compensation se fait en points ou en tâches. Résultat en carte partageable + widget de la semaine.
- **Cas fondateur** : la répartition équitable par enchère/points est un domaine établi (Spliddit, travaux de Procaccia sur la division équitable) mais n'existe pas en app grand public simple ; les avis Splitwise/Tricount montrent des utilisateurs prêts à payer un pass ponctuel (fiche terrain, enjeu 4). Preuve du besoin : les apps de corvées existantes (Tody, OurHome) assignent à tour de rôle, sans mise. À vérifier : URL Spliddit et études de conflits de colocs.
- **Offre** : gratuit 1 foyer, 1 enchère ; Pro 9,99 €/an par foyer (partage entre foyers, historique d'équité, tâches récurrentes). Raison de revenir : une enchère par semaine (rituel du dimanche), l'équité cumulée « Tom a dépensé 140 points, Léa 60 ».
- **Brique Apple** : Foundation Models (liste de tâches à partir d'une dictée ou d'une photo, durées), widgets, notifications locales, App Intents (« qui sort les poubelles ? »). Partage CloudKit en option v2.
- **Honnêteté IA** : moyenne. L'IA évite la saisie fastidieuse ; le cœur est un algorithme. Premier moment utile en moins de 60 secondes grâce au mode « passe le téléphone ».
- **Probabilité qu'un autre LLM la propose : 15 %** (les LLM pensent « répartition des corvées » mais pas l'enchère à l'aveugle)

## 4. **Trajet Record** — des « splits » de speedrun pour les navetteurs, pour battre son meilleur temps domicile-bureau

- **Mécanique** : l'app découpe le trajet en tronçons (porte, arrêt, métro, correspondance, bureau) détectés par lieux (géorepérage) ; une Live Activity affiche en direct l'écart avec son meilleur chrono (vert/rouge, « tronçon en or »). Le soir : « tu as gagné 3 min sur la correspondance, essaie la voiture 2 ».
- **Cas fondateur** : les « splits » des speedrunners (LiveSplit, comparaison au meilleur temps segment par segment : https://livesplit.org/) et les segments Strava prouvent que comparer à son propre record fait revenir ; mais Strava ne couvre que le vélo et la course, pas les trajets multimodaux. Fondé sur le trajet quotidien, usage 2×/jour, 220 jours/an. À vérifier : app existante équivalente (recherche non aboutie).
- **Offre** : 14 jours d'essai de la première Live Activity ; 19,99 €/an. Raison de revenir : tous les jours ouvrés, record à battre, widget « ton record : 34 min 12 ».
- **Brique Apple** : Live Activities, Core Location (régions), Core Motion (marche/transport), widgets, App Intents (« lance mon trajet »), Foundation Models pour nommer et suggérer les tronçons.
- **Honnêteté IA** : faible. C'est ici la capacité Apple (Live Activity + géorepérage) qui est indispensable, pas l'IA. Retirer l'IA laisse un produit qui marche, ce qui est un point de vigilance sur la carte de rejet (« IA ou capacité Apple indispensable » est satisfait côté Apple).
- **Probabilité qu'un autre LLM la propose : 15 %**

## 5. **Bien Reçu** — la contre-lecture des pilotes pour qui reçoit un accord oral, pour qu'il n'y ait pas de « je n'ai jamais dit ça »

- **Mécanique** : juste après un échange oral (plombier, propriétaire, client, prof, nounou), on dicte « le plombier passe jeudi 9h, devis 480 € HT, il apporte la pièce » ; Foundation Models extrait les engagements (qui, quoi, quand, combien) et génère le message de contre-lecture prêt à envoyer par Messages/WhatsApp : « Pour confirmer : jeudi 9h, 480 € HT, pièce apportée. OK ? ». Le « OK » devient un reçu daté dans l'app.
- **Cas fondateur** : en aviation, la contre-lecture (readback/hearback) est obligatoire pour toute instruction du contrôleur, parce que la mauvaise compréhension orale est une cause récurrente d'incidents (principe FAA/ICAO, à documenter avec URL au kick-off). Transfert aux accords de la vie courante, aujourd'hui sans trace. Reste à vérifier la présence d'une app équivalente (non aboutie).
- **Offre** : 3 contre-lectures gratuites ; Pro 29,99 €/an ou pass 4,99 € « chantier/déménagement ». Raison de revenir : chaque accord oral (plusieurs par semaine pour freelances, propriétaires, parents) ; widget « en attente d'OK » ; relance auto.
- **Brique Apple** : SpeechAnalyzer (dictée on-device), Foundation Models (@Generable engagements), Share Sheet / Messages, App Intents (« Siri, contre-lecture »), widgets.
- **Honnêteté IA** : forte. Sans extraction, on retombe sur une note. Distinct du résumeur : la sortie est un message à envoyer, pas un résumé à lire. Risque : se faire confondre avec « prise de notes » ; la promesse doit rester « message de confirmation en 5 secondes ».
- **Probabilité qu'un autre LLM la propose : 12 %**

## 6. **Prix Net** — l'étiquette de rayon des supermarchés, à retourner au client, pour savoir ce qui a rétréci ou renchéri à chaque course

- **Mécanique** : on photographie ou scanne en direct l'étiquette d'un produit (VisionKit DataScanner) ; Foundation Models normalise le texte brut (« 6×33 cl », « 500 g -10 % ») en prix au kilo ou au litre typé. L'app compare avec les produits équivalents de ta liste et avec la dernière fois que tu as scanné le même produit : « 5 g de moins, +8 % au kilo ». Aucune donnée tierce : uniquement les scans de l'utilisateur, pas de scraping.
- **Cas fondateur** : le prix à l'unité est la mécanique obligatoire des rayons ; la « shrinkflation » est devenue un sujet public en France (mentions obligatoires en rayon à partir de 2024-2025, texte exact à vérifier avant pitch). Même mécanisme que Cal AI : un geste, un résultat chiffré (fiche terrain).
- **Concurrence** : Open Prices (Open Food Facts) est collaboratif ; Yuka note la santé, pas le prix à l'unité. Non vérifié plus avant.
- **Offre** : 10 scans gratuits, puis 19,99 €/an ou 2,99 €/mois ; paywall dur après le premier « gain » affiché (« tu aurais économisé 1,40 € »). Raison de revenir : chaque course, historique par produit, widget « dernier produit surveillé ».
- **Brique Apple** : VisionKit DataScanner / Vision (OCR), Foundation Models (normalisation des libellés en @Generable), widgets, SwiftData.
- **Honnêteté IA** : moyenne à forte (étiquettes bruitées multilingues). Aucune dimension financière réglementée.
- **Probabilité qu'un autre LLM la propose : 30 %** (le « comparateur de prix par scan » est un classique)

## 7. **Étagère Tournante** — l'inventaire tournant du retail, pour les foyers qui jettent des aliments, pour ne jamais refaire un inventaire complet

- **Mécanique** : chaque jour, l'app demande une seule zone (« étagère du bas du frigo ») ; une photo de 5 secondes, Vision et Foundation Models listent les produits et dates visibles, l'app compare à la veille pour déduire ce qui a été consommé ou doit partir en premier. Un widget affiche « 3 à manger avant jeudi ».
- **Cas fondateur** : l'inventaire tournant (cycle counting) remplace l'inventaire annuel complet dans le retail en comptant une petite zone par jour. Pas encore posé sur le frigo : les apps de garde-manger (NoWaste, Pantry) exigent de tout saisir au départ, d'où leur abandon (premier moment utile lent, carte de rejet).
- **Offre** : 14 jours d'essai ; 24,99 €/an foyer. Raison de revenir : une zone par jour, widget quotidien, série de zones couvertes (pas un habit tracker : le contenu est l'objet).
- **Brique Apple** : Vision (OCR dates), Foundation Models entrée image (annoncée WWDC26, repli : Vision + texte), widgets, notifications locales.
- **Honnêteté IA** : forte, mais précision incertaine sur des photos de frigo ; repli prévu. Concurrence réelle (apps anti-gaspi) : différenciation fragile.
- **Probabilité qu'un autre LLM la propose : 30 %**

---

## Récapitulatif (7 idées, 5 sous 20 %)

| # | Nom | Phrase | % |
|---|---|---|---|
| 1 | Juste Match | Handicap multi-jeux pour amis inégaux, pour jouer à armes égales ce soir | 15 |
| 2 | Demi-tour | Heure de rebroussement + alarme pour randonneurs/cyclistes, pour ne pas finir de nuit | 12 |
| 3 | Mise Corvée | Enchère à l'aveugle des tâches pour colocs/couples, pour répartir chaque semaine | 15 |
| 4 | Trajet Record | Splits de speedrun pour navetteurs, pour battre son meilleur trajet | 15 |
| 5 | Bien Reçu | Contre-lecture de pilote pour accords oraux, pour confirmer en 5 secondes | 12 |
| 6 | Prix Net | Prix à l'unité par scan d'étiquette pour acheteurs en rayon, pour traquer la shrinkflation | 30 |
| 7 | Étagère Tournante | Inventaire tournant par une zone/jour pour foyers, pour réduire le gaspillage | 30 |
