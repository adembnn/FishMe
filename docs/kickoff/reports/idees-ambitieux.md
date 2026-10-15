# Idées angle « ambitieux » : chaînes de briques Apple, effet wow en 10 secondes

Principe commun : un geste (photo, collage, phrase à Siri) puis une chaîne de briques natives (Vision/OCR, Foundation Models avec sortie typée @Generable, App Intents, Live Activity, widget). L'IA fait le travail que l'utilisateur ne veut pas faire : lire un texte minuscule ou désordonné et en sortir des données structurées. Repli sans Apple Intelligence : OCR Vision + saisie guidée (voir fiche terrain, question 8).

Recherches faites pour éviter les doublons : un scanner de panneaux de stationnement avec Live Activity existe déjà (PicPark, Park Here, Parky.AI : idée écartée), Lumical (photo de planning de shifts vers Calendrier) et WOD Tracker (photo de tableau de CrossFit vers journal) existent (idées écartées).

---

## 1. Cuisson Live
**Minuteurs de notice pour étudiants qui cuisinent, pour chaque repas du soir.**
- **Mécanique** : on photographie la notice au dos d'un paquet (pizza surgelée, riz, pâtes, gnocchis) ou une page de livre. Vision lit le texte, Foundation Models sort une liste typée d'étapes (action, température, durée, "retourner à mi-cuisson"), et une Live Activity affiche l'étape en cours avec son compte à rebours sur l'écran verrouillé. « Dis Siri, étape suivante » passe à la suivante (App Intent).
- **Fondement** : les apps de cuisine à minuteurs Live Activity (Crouton, Pestle) exigent d'importer une recette web ; aucune ne part d'un emballage (MacStories : https://www.macstories.net/reviews/ios-16-1-and-apps-with-live-activities-the-macstories-roundup-part-1). Le schéma « un geste photo, un résultat exploitable, IA indispensable » est celui de Cal AI (fiche terrain, 3 réponses réelles, n° 2).
- **Offre** : essai 3 jours puis 2,99 €/mois ou 19,99 €/an, paywall après le premier minuteur réussi (le wow arrive avant le paywall, cf. fiche terrain enjeu 2). Raison de revenir : chaque repas, tous les jours.
- **Briques** : Vision (texte), Foundation Models (@Generable : étapes, durées, températures), Live Activity, App Intents (Siri), widget "mon prochain repas".
- **Probabilité qu'un autre LLM la propose** : 20 %.

## 2. Bac Ce Soir
**Calendrier de ramassage lu depuis le prospectus de la mairie, pour les foyers qui oublient quel bac sortir.**
- **Mécanique** : on photographie (ou on importe en PDF) le calendrier papier de collecte de sa commune. Foundation Models sort un planning typé (type de bac, jour, parité de semaine, exceptions jours fériés). Un widget d'écran de verrouillage affiche « ce soir : sortir le bac jaune », et Siri répond à « quel bac ce soir ? ».
- **Fondement** : chaque collectivité a son format, les apps existantes demandent de tout saisir à la main (Bin Collection Reminder, avis : « 5 bacs de couleurs différentes », https://apps.apple.com/gb/app/bin-collection-reminder/id6743419371) ; les données ouvertes sont éparpillées par commune (exemple Auxerre sur data.gouv.fr). Usage hebdomadaire fixe, toute l'année (pas de pic saisonnier).
- **Offre** : achat unique 3,99 € ou 1,99 €/an (mise à jour du calendrier annuel : c'est la raison de payer chaque année). Pas de compte, donc essai inutile : première utilité immédiate, bac du soir visible à la fin du scan.
- **Briques** : Vision, Foundation Models (extraction typée d'un tableau désordonné), widgets (écran verrouillé), App Intents, notifications locales.
- **Probabilité** : 10 %.
- **Risque honnête** : monétisation faible par utilisateur et un foyer qui a installé le calendrier une fois ne rouvre plus l'app ; le widget doit porter la valeur. À défendre au jury.

## 3. Sac Demain
**Liste « à apporter demain » tirée des messages de l'école, pour les parents d'enfants du primaire, chaque soir.**
- **Mécanique** : le parent partage un message de l'école (ENT, mail, WhatsApp de classe) vers l'app via la feuille de partage. Foundation Models extrait des éléments typés (objet, jour, personne concernée : "piscine jeudi : maillot + bonnet", "sortie mardi : pique-nique + 2 €"). Un widget affiche chaque soir « demain, pour Léa : ... » et une Live Activity du matin liste ce qu'il reste à mettre dans le sac.
- **Fondement** : les messages d'école mêlent plusieurs enfants, dates relatives et consignes noyées dans un paragraphe, ce que seule une extraction par modèle traite. Le payeur est le parent, pas l'enfant ; le canal d'acquisition est le bouche-à-oreille entre parents de la même classe (fiche terrain, question 6). Chiffre à sourcer avant le pitch : nombre d'élèves du primaire en France (environ 6,6 millions, source à confirmer sur education.gouv.fr).
- **Offre** : 2,49 €/mois ou 14,99 €/an, essai 7 jours. Raison de revenir : chaque soir de semaine scolaire (36 semaines), rythmé par l'année scolaire, pas un pic unique.
- **Briques** : Foundation Models (@Generable, dates relatives), Share Extension, widgets, Live Activity, App Intents (« Siri, qu'est-ce qu'il faut demain ? »).
- **Probabilité** : 12 %.
- **Risque** : l'équipe n'est pas parent ; valider avec 5 parents avant jeudi. Données d'enfants : tout reste sur l'appareil (argument App Store et argument de vente).

## 4. Gamelle Juste
**Ration de croquettes lue sur le sachet et partagée entre colocataires, pour les propriétaires de chien ou de chat, chaque jour.**
- **Mécanique** : on photographie le tableau de rationnement du sachet (poids de l'animal en lignes, grammes par jour en colonnes) et on entre le poids. Foundation Models sort la ration typée en grammes par repas ; un widget partagé (CloudKit) affiche « Rex : matin donné, soir à donner » avec un bouton interactif, et Siri enregistre « j'ai nourri Rex » (App Intent).
- **Fondement** : 43 % des foyers français possèdent un chien ou un chat (Facco-Kantar, https://www.facco.fr/wp-content/uploads/2020/09/FACCO-RAPPORT-2020.pdf). Les tableaux de sachets sont illisibles (police minuscule, tranches de poids, plusieurs gammes). Le partage de couple ou de coloc évite le « tu l'as déjà nourri ? », moteur de rétention et de recommandation.
- **Offre** : essai 7 jours puis 2,99 €/mois ou 24,99 €/an ; le partage à 2 inclus. Raison de revenir : deux fois par jour.
- **Briques** : Vision, Foundation Models (lecture d'un tableau et sélection de la ligne), widgets interactifs, App Intents, CloudKit sharing, Live Activity (« en attente du repas du soir »).
- **Probabilité** : 8 %.
- **Risque** : rester sur de l'alimentation courante, sans conseil vétérinaire ni médicament (pas de zone santé animale réglementée). Apps concurrentes de suivi d'animaux existantes (par exemple 11pets) : aucune ne part du sachet, à vérifier.

## 5. Qui Vient
**Liste de joueurs tirée de la conversation WhatsApp, pour l'organisateur du foot, du padel ou du basket entre amis, pour chaque semaine.**
- **Mécanique** : l'organisateur copie le fil WhatsApp ou le partage vers l'app. Foundation Models classe chacun en typé (présent, absent, peut-être, "si je finis à 19h", +1) et indique « il manque 2 joueurs pour jeudi 20h ». Une Live Activity compte les confirmés jusqu'à l'heure du match, un widget affiche l'effectif, et un message de relance prêt à envoyer est généré pour les indécis.
- **Fondement** : les réponses sont en français familier (« chaud », « normalement oui », « je te dis à 17h ») que les sondages classiques ne prennent pas en compte ; Spond, Heja et Doodle exigent que tous les joueurs installent l'app, ici seul l'organisateur l'a. Public cible proche de l'équipe (étudiants, sport entre amis) donc test terrain gratuit cette semaine.
- **Offre** : essai 7 jours puis 1,99 €/mois ou 12,99 €/an ; payeur = organisateur, qui gagne du temps chaque semaine. Raison de revenir : un match par semaine.
- **Briques** : Foundation Models (classification d'intention typée en français), Share Extension, Live Activity, widget, App Intents.
- **Probabilité** : 12 %.
- **Risque** : l'export WhatsApp est un copier-coller manuel ; le geste doit tenir en 3 secondes. Sans scraping ni accès à WhatsApp (l'utilisateur colle lui-même le texte).

## 6. Retrait Colis
**Code de retrait et dernier jour extraits du SMS, pour qui reçoit des colis en point relais, pour ne pas les voir repartir.**
- **Mécanique** : on partage le SMS ou le mail de disponibilité. Foundation Models extrait (enseigne, point relais, date limite, code ou QR) et l'app crée un widget d'écran verrouillé « Vinted chez Tabac Mairie : encore 2 jours, code 4821 », avec une Live Activity le dernier jour. Le QR s'affiche sans ouvrir l'e-mail.
- **Fondement** : Mondial Relay a ramené le délai de retrait à 5 jours calendaires, après quoi le colis repart à l'expéditeur (https://www.journaldugeek.com/2025/10/31/mondial-relay-delais-taille-maximale-lockers-toutes-les-regles-pour-ne-plus-se-faire-avoir ; https://www.mondialrelay.fr/faq/recevoir-un-colis/combien-de-jours-ai-je-pour-retirer-mon-colis-en-locker-ou-point-relais). 12 000 lockers et 7 000 points relais en France (https://www.mondialrelay.fr/). Chaque transporteur a son format de message, donc l'extraction typée est le produit.
- **Offre** : 0 € les 3 premiers colis, puis 1,99 €/mois ou 9,99 €/an. Raison de revenir : chaque colis (Vinted, Temu, marketplaces), plusieurs fois par mois.
- **Briques** : Foundation Models, Share Extension, widgets d'écran verrouillé, Live Activity, App Intents (Wallet-like : « montre mon code »).
- **Probabilité** : 20 %.
- **Risque** : les apps de suivi (Parcel, Mondial Relay lui-même) couvrent déjà une partie ; le produit doit rester étroit (code + délai) et rapide, pas un suivi de colis généraliste.

## 7. Série Vocale
**Journal de séance dicté entre deux séries, pour les pratiquants de musculation en salle, quatre fois par semaine.**
- **Mécanique** : sans toucher l'écran, l'utilisateur dit « développé couché, 8 fois 60 ». Un App Intent envoie la phrase à Foundation Models, qui sort l'entrée typée (exercice normalisé, répétitions, charge) ; une Live Activity démarre le minuteur de repos sur l'écran verrouillé avec la série suivante proposée d'après la dernière séance.
- **Fondement** : la saisie entre deux séries (mains moites, téléphone verrouillé) est le frein des apps comme Strong ou Hevy ; la dictée libre avec normalisation des noms d'exercices en français est le travail du modèle. Fitness non réglementé (pas de conseil médical ni de santé au sens de la carte de rejet : il ne mesure ni ne diagnostique rien).
- **Offre** : essai 7 jours puis 3,99 €/mois ou 29,99 €/an (médiane du marché 34,80 $/an, fiche terrain enjeu 4). Raison de revenir : chaque séance, l'historique alimente la charge proposée.
- **Briques** : App Intents (Siri), Foundation Models (@Generable), Live Activity (repos), widget (prochaine séance), AppIntent via bouton Action.
- **Probabilité** : 25 %.
- **Risque** : marché très encombré (Strong, Hevy, Fitbod) ; la voix en salle bruyante et la gestion de Siri en français (fiche terrain, limites) peuvent faire échouer la démo. À tester dans une vraie salle avant de choisir.

---

## Synthèse

| # | Nom | Probabilité |
|---|-----|-------------|
| 1 | Cuisson Live | 20 % |
| 2 | Bac Ce Soir | 10 % |
| 3 | Sac Demain | 12 % |
| 4 | Gamelle Juste | 8 % |
| 5 | Qui Vient | 12 % |
| 6 | Retrait Colis | 20 % |
| 7 | Série Vocale | 25 % |

Quatre idées sous 20 % : Bac Ce Soir, Sac Demain, Gamelle Juste, Qui Vient.
