# Idées angle « gestes » : ce que des communautés font déjà à la main

Recherches web (12 oct. 2026). Constat clé : tout ce qui est « gestion d'équipe sportive / RSVP / paiement des cotisations » est saturé (Spond, 12 M d'utilisateurs, gratuit ; TeamSnap 24 M ; Squaddle ; Steerer ; Vanta). Je l'écarte. Les idées ci-dessous visent le geste manuel que ces apps ne touchent pas : transformer une parole, une photo ou un export de chat en donnée utile, sans saisie.

Gestes observés (sources) :
- Équipes amateurs : « WhatsApp + tableur » reste la base gratuite, avec relances à la main (https://www.sportplan.net/drills/Football/guides/best-free-grassroots-football-apps-2026.jsp). Un parent est dans 5 à 10 groupes WhatsApp, infos noyées dans le bavardage, bénévoles épuisés (https://clubzap.com/gb/blog/from-whatsapp-chaos-to-calm).
- Jeux de société : feuille de papier, Notes (« mise en page nulle ») ou Google Sheet avec tableau croisé que « les amis n'ouvrent jamais » (https://rivalboard.app/blog/how-to-track-board-game-scores ; https://www.reddit.com/r/boardgames/comments/1jzixe1/what_are_some_apps_people_use_to_keep_track_of/).
- Grimpeurs : carnet + notes + tableur ; retrouver un bloc noté il y a des mois est pénible, et le bloc a changé entre-temps (https://www.mountainproject.com/forum/topic/119608805/training-logbook-app-an-idea-for-people-who-know-how-to-write-apps ; tableur de progression https://www.reddit.com/r/climbing/comments/8y0g12/i_made_a_spreadsheet_you_can_use_to_track_your).
- Levain : des boulangers font un tableur pour suivre plusieurs levains en parallèle (https://www.facebook.com/groups/1006060197306320/posts/1451201832792152).

Coût IA : Foundation Models on-device et Private Cloud Compute gratuit sous 2 M de téléchargements (fiche terrain), donc marge intacte. Aucune idée n'utilise de scraping : les données viennent de la voix, de la photo ou d'un export de chat fait par l'utilisateur (partage manuel), jamais d'un site tiers.

---

## 1. Cartable Veille
**Les devoirs, sorties et « à apporter » noyés dans les groupes WhatsApp de classe, pour les parents, pour la veille au soir.**
- Mécanique : le parent exporte la conversation du groupe de classe (Partager > Exporter la discussion) vers l'app. Foundation Models (@Generable) extrait uniquement les actions : sortie vendredi, apporter un pique-nique, tenue de sport, argent à rendre. L'app les range par enfant et les pousse dans Rappels/Calendrier.
- Le soir, une Live Activity / un widget « Demain dans le cartable » liste ce qu'il faut préparer pour chaque enfant. Ce n'est pas un résumé de chat : c'est une liste de choses à faire datées.
- Fondement : 5 à 10 groupes WhatsApp par parent, infos importantes enterrées (ClubZap, URL ci-dessus). Les parents d'élèves sont dans la liste des cibles du brief.
- Offre : 2,99 €/mois ou 19,99 €/an, essai 7 jours avec paywall après le premier import réussi. Raison de revenir : chaque soir d'école, chaque semaine un nouvel export (rythme scolaire, pas saisonnier unique).
- Brique Apple : Foundation Models (extraction typée, FR), App Intents (« Siri, qu'est-ce qu'il faut préparer demain ? »), widgets, Live Activities, EventKit.
- Risque : limite 4096 tokens, donc découper l'export ; données d'enfants, tout reste on-device (argument de confiance). WhatsApp n'impose rien : l'export est un geste de l'utilisateur.
- Probabilité qu'un autre LLM la propose : **25 %**.

## 2. Score Dictée
**Le carnet de parties de la soirée jeux, dicté à voix haute, pour le groupe d'amis, pour la fin de chaque partie.**
- Mécanique : on dit « Wingspan : Léa 87, Tom 64, Inès 102 » ; SpeechAnalyzer transcrit, Foundation Models transforme en partie typée (jeu, joueurs, scores, gagnant), fautes de prénom corrigées contre le groupe. Aucun écran à remplir.
- Le classement de la saison, les têtes-à-têtes et les « Tom n'a jamais battu Léa à Catan » se mettent à jour, s'affichent dans un widget et se partagent en carte image à poster dans le groupe.
- Fondement : le tableur partagé que personne n'ouvre, et le score en Notes à la « mise en page nulle » (rivalboard et r/boardgames, URL ci-dessus). Honnêteté : des apps existent déjà (RivalBoard, BG Stats), la différence est la dictée, sans saisie.
- Offre : gratuit pour 1 groupe, 14,99 €/an pour groupes illimités + historique + carte de saison. Raison de revenir : chaque soirée jeux, bilan de saison à partager.
- Brique Apple : SpeechAnalyzer/Speech, Foundation Models (@Generable), App Intents (Siri « ajoute une partie »), widgets, ShareLink/ImageRenderer.
- Probabilité : **30 %**.

## 3. Table Mémoire
**Le carnet de ce que j'ai servi à qui, pour l'hôte qui reçoit souvent, pour la veille du prochain dîner.**
- Mécanique : après un dîner, on dicte « Marc, gratin dauphinois, il a adoré, pas de porc ; Sana est végétarienne ». Foundation Models fiche les invités (régimes, goûts) et les plats servis. Avant le prochain dîner, on sélectionne les invités : l'app propose 3 menus qu'ils n'ont jamais mangés chez moi et compatibles avec tous les régimes, plus la liste de courses.
- Fondement : les cuisiniers bricolent déjà Evernote/Notes pour recettes et photos (https://www.reddit.com/r/Cooking/comments/18ej07f/how_do_you_keep_recipes_is_there_an_app). Le lien « invité, plat déjà servi » est mon hypothèse : aucune source chiffrée trouvée, à tester avec 5 hôtes. Risque : allergies, donc afficher « à confirmer avec l'invité », ne jamais garantir (pas de santé réglementée).
- Offre : achat unique 12,99 € ou 1,99 €/mois. Raison de revenir : chaque réception, la mémoire s'enrichit (effet de verrouillage doux).
- Brique Apple : SpeechAnalyzer, Foundation Models (extraction + génération contrainte), Contacts, App Intents, Rappels (liste de courses).
- Probabilité : **12 %**.

## 4. Pâton Pilote
**Le minuteur de levain qui regarde le bocal, pour le boulanger du dimanche, pour savoir quand enfourner.**
- Mécanique : on pose un élastique sur le bocal et on photographie au départ. Toutes les heures environ, une photo ; l'app mesure la hausse de la pâte par rapport à l'élastique et affiche « +62 %, enfournez dans ~40 min » dans une Live Activity. Plusieurs pâtons en parallèle, chacun avec sa jauge.
- Fondement : des boulangers montent un tableur pour gérer plusieurs levains en même temps (groupe Facebook, URL ci-dessus). Le temps de pousse varie avec la température de la cuisine, donc un minuteur fixe échoue : c'est la vraie douleur.
- Offre : achat unique 4,99 € + pack recettes/hydratations 9,99 €, ou 14,99 €/an. Raison de revenir : une fournée par semaine, les pâtons passés servent de journal.
- Brique Apple : Vision (détection d'élastique et de ligne de pâte) ; entrée image de Foundation Models annoncée à la WWDC26 pour estimer quand c'est incertain ; Live Activities, notifications, widgets.
- Risque : sans le modèle image, la mesure repose sur Vision seul. Prévoir repli : l'utilisateur ajuste du doigt la ligne de pâte, l'app apprend la vitesse. Si on retire l'IA/Vision il reste un minuteur, donc la mesure doit être le produit.
- Probabilité : **7 %**.

## 5. Relais Bénévole
**Le planning de buvette ou de kermesse qui se fabrique en parlant, pour le bénévole organisateur, pour le week-end d'événement.**
- Mécanique : l'organisateur dicte les besoins (« samedi buvette 14h-18h, 4 personnes ; Julie pas avant 16h ; Karim une heure max ») au lieu de remplir le tableur. Foundation Models transforme en contraintes typées et un algorithme local compose un roulement équitable ; export en image/ICS à poster dans le groupe, relances prêtes à copier.
- Fondement : « WhatsApp + tableur » comme base des clubs, avec relances manuelles (Sportplan) et bénévoles épuisés (ClubZap), URL ci-dessus. Ce n'est PAS la gestion de présence de Spond (saturée), c'est la fabrication du planning à partir de contraintes dites.
- Offre : pass événement 4,99 € ou abonnement 24,99 €/an pour associations. Payeur = l'organisateur, canal = bouche à oreille entre associations (un planning partagé montre le logo de l'app). Raison de revenir : chaque événement de la saison, plannings recopiés d'une édition à l'autre.
- Brique Apple : SpeechAnalyzer, Foundation Models (@Generable, tool calling pour le solveur), Calendrier/ICS, ShareLink, widgets.
- Risque : usage par pics (événements), donc viser clubs avec événements toute l'année (buvette du samedi). Pas de contenu utilisateur modéré : planning privé.
- Probabilité : **15 %**.

## 6. Répète Notes
**Le compte rendu de répétition d'un groupe amateur, extrait de l'enregistrement, pour le chanteur ou guitariste, pour la veille de la prochaine répète.**
- Mécanique : on lance l'enregistrement pendant la répétition. SpeechAnalyzer garde uniquement les prises de parole, Foundation Models les rattache à chaque morceau de la setlist (« reprendre le pont, trop rapide », « Tom, entrée en retard ») et produit par morceau une liste « à retravailler » et par musicien ses points. Envoi en un tap dans le groupe.
- Fondement : hypothèse issue de mon observation des gestes de groupes : les remarques de répète vivent en vocaux WhatsApp et en Notes. Aucune source web chiffrée trouvée, à valider auprès de 5 groupes (cercle d'amis, étudiants). Angle administratif du groupe, pas d'instrument ni de DJ (créneau MWM évité). 
- Offre : 3,99 €/mois ou 29,99 €/an, essai gratuit pour 3 répétitions. Raison de revenir : chaque répétition (hebdomadaire).
- Brique Apple : SpeechAnalyzer, Foundation Models, App Intents (« Siri, démarre la répète »), Live Activities (enregistrement en cours), partage.
- Probabilité : **10 %**.

## 7. Bloc Voix
**Le carnet de grimpeur dicté entre deux essais, pour le grimpeur en salle, pour la séance.**
- Mécanique : mains pleines de magnésie, il dit « bleu 6B pan gauche, 3e essai, raté au dernier mouvement, changer la prise de pied ». L'app structure (voie, grade, essai, note) et prend une photo du mur pour marquer le bloc. Live Activity de repos entre essais ; rappel de « reset » quand la salle change ses blocs, pour ne plus chercher une note devenue fausse.
- Fondement : un grimpeur note à la main les blocs par nom, et la note ne marche plus car le bloc a changé (Mountain Project, URL ci-dessus) ; tableurs de progression (r/climbing, URL ci-dessus). Honnêteté : SendLog, Crimpd et Lattice existent, la différence est la dictée et le rappel de reset.
- Offre : 29,99 €/an, essai 7 jours après la première séance dictée. Raison de revenir : 2 à 3 séances par semaine.
- Brique Apple : SpeechAnalyzer, Foundation Models, Live Activities, App Intents (démarrer un essai en Action Button), PhotoKit/Vision.
- Probabilité : **22 %**.

---
Récap des probabilités : Cartable Veille 25, Score Dictée 30, Table Mémoire 12, Pâton Pilote 7, Relais Bénévole 15, Répète Notes 10, Bloc Voix 22 (4 sous 20 %).
