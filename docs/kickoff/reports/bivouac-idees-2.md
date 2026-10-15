# Bivouac : 20 idées nouvelles (lot 2)

Décision débloquée : choisir 2 ou 3 mécaniques à ajouter au socle (feu tricolore, ta nuit, jeudi, cartes, dernier signal, réveil) pour la démo et la rétention.
Hors liste (déjà aimées) : feu tricolore, ta nuit, micro-aventure du jeudi, carnet en cartes, dernier signal, réveil au lever du soleil.
Probabilités = estimation de ma part, pas une mesure. 13 idées sur 20 sont sous 15 %. Test « IA décorative » : noté quand l'IA n'est pas indispensable.
Règle maintenue : l'IA reformule, la règle vient de la table sourcée.

Triées par % croissant. Format : nom | phrase | geste | brique Apple | pourquoi on revient | %.

## 1. Demi-Tour (5 %) | après / gamification
- Phrase : un badge rare pour le bivouaqueur qui renonce, pour le soir où l'orage, le feu interdit ou le froid disent non.
- Geste : appuie sur « Je renonce » ; une carte « Demi-tour » (raison, heure, lieu flou) rejoint le carnet.
- Brique : App Intents (bouton dans le widget et Siri : « je rentre »), Live Activity qui s'arrête proprement.
- Pourquoi on revient : la progression récompense le jugement, pas la durée ni la série ; contre-pied exact des streaks. Un renoncement vaut plus de points que une nuit facile.
- IA : aucune (marche sans).

## 2. Café Altitude (6 %) | matin
- Phrase : un minuteur de café ajusté à l'altitude et au froid pour celui qui lève le camp à 2 100 m, pour 7 h du matin.
- Geste : un tap sur « café » ; l'app donne le point d'ébullition local (≈ 93 °C à 2 100 m), le temps d'infusion et le gaz consommé.
- Brique : CoreLocation / baromètre (CMAltimeter), Live Activity minuteur, Apple Watch.
- Pourquoi on revient : c'est le geste du matin, quotidien en itinérance ; l'app est ouverte au moment où la fiche de rangement suit.
- IA : aucune (marche sans).

## 3. Pression Chute (7 %) | sur place, orage
- Phrase : une veille barométrique hors ligne pour celui qui dort sans réseau, pour la nuit où le temps tourne.
- Geste : pose le téléphone chargé près de la tente (mode « veille ») ; l'iPhone réveille par haptique et son doux si la pression chute vite.
- Brique : CMAltimeter (baromètre), AlarmKit, Apple Watch (tap au poignet), WeatherKit en amont.
- Pourquoi on revient : la prévision de la veille se vérifie en direct ; chaque nuit enregistre la courbe réelle contre la prévue. Limite : aide, jamais garantie de sécurité, à écrire dans l'app.
- IA : aucune (marche sans).

## 4. Orientation Tente (8 %) | installation
- Phrase : la direction où poser la porte de la tente pour celui qui plante à 19 h, pour avoir vent dans le dos, soleil du matin et vue sur le ciel.
- Geste : tourne le téléphone sur la boussole jusqu'à ce que le trait vert se cale ; l'app affiche vent de la nuit, azimut du lever du soleil, côté de la Voie lactée.
- Brique : boussole CoreLocation, WeatherKit (vent horaire), calcul solaire.
- Pourquoi on revient : à chaque installation ; un geste de 10 secondes qui a un résultat visible sur la nuit.
- IA : aucune (marche sans).

## 5. Frileux Calibré (8 %) | saison morte, froid
- Phrase : un seuil de froid personnel appris pour celui qui hésite entre deux duvets, pour décider de partir en dessous de 2 °C.
- Geste : le matin, un curseur « j'ai eu : chaud / bien / froid » ; l'app croise avec la température réelle de la nuit.
- Brique : Foundation Models (lit tes 10 dernières notes et formule « tu as froid sous 6 °C avec ce duvet »), SwiftData, WeatherKit.
- Pourquoi on revient : « Ta nuit » devient exacte pour toi après 5 nuits ; le seuil bouge avec le matériel. Sans l'IA, une simple moyenne marche (IA un peu décorative sauf pour la phrase).

## 6. Bruit Rassurant (9 %) | sur place, peur
- Phrase : un écouteur de nuit qui nomme les bruits pour le débutant qui entend « quelque chose » à 2 h, pour le rassurer.
- Geste : appuie sur « C'est quoi ce bruit ? » ; 10 secondes d'écoute ; l'app répond « cerf en rut, à 150 m environ » ou « pas de bruit identifié ».
- Brique : SoundAnalysis (classifieur sur l'appareil), Foundation Models pour la phrase calme, tout hors ligne ; audio jamais envoyé.
- Pourquoi on revient : la peur de la première nuit est le frein n°1 ; une fois rassuré, on repart. Limite : classes d'animaux français à entraîner (Create ML), précision à tester.

## 7. Note Gantée (9 %) | sur place et matin, froid
- Phrase : un journal parlé pour celui qui a les doigts gelés, pour noter sans sortir les mains du duvet.
- Geste : « Siri, note : 3 °C, vent, tente humide » ; l'entrée rejoint le carnet de la nuit avec heure, altitude, température.
- Brique : App Intents + dictée, Foundation Models (structure la phrase en champs), Apple Watch.
- Pourquoi on revient : alimente le carnet et Frileux Calibré ; marche sans réseau.
- IA : sans IA, un champ texte brut marche (la structuration est le plus).

## 8. Nuit Parrainée (10 %) | social, première nuit
- Phrase : une checklist validée à distance par un ami expérimenté pour le débutant, pour la veille de sa première nuit.
- Geste : le débutant envoie son plan (lieu, sac, météo) par iMessage ; le parrain coche ou corrige en un tap ; un pastille verte « validé par Léa » s'affiche.
- Brique : CloudKit Sharing / Messages, App Intents, Foundation Models (résume le plan pour le parrain en 3 lignes).
- Pourquoi on revient : le parrain installe l'app pour valider (acquisition) puis reçoit les cartes de son filleul ; ce n'est pas un réseau, c'est un binôme.

## 9. Braise Virtuelle (11 %) | sur place, feu interdit
- Phrase : un écran braise rouge, sans lumière blanche, pour celui qui n'a pas le droit au feu, pour la soirée du massif fermé.
- Geste : pose l'iPhone en StandBy contre la gamelle ; l'écran passe en rouge doux avec : heure, température qui baisse, ciel, minutes avant lever.
- Brique : StandBy, widgets, Live Activity (coucher du soleil → lever), mode nuit rouge pour garder la vision nocturne.
- Pourquoi on revient : transforme l'interdiction en rituel du soir ; chaque soirée de bivouac l'ouvre. Sans IA, marche (aucune IA ici).

## 10. Sac Pesé (12 %) | avant le départ
- Phrase : le sac étalé en photo pour celui qui prépare le soir d'avant, pour savoir ce qui manque et ce qui pèse trop.
- Geste : une photo du sac vidé sur le sol ; l'app entoure les objets, estime le poids, dit « pas de réchaud, pas de lampe frontale » et « duvet 0 °C pour une nuit à −2 °C ».
- Brique : Vision (détection / reconnaissance d'objets), Foundation Models (compare à la nuit prévue par WeatherKit), hors ligne.
- Pourquoi on revient : avant chaque sortie ; la liste mémorise ton matériel (duvet, tente) et nourrit Frileux Calibré. Limite : reconnaissance d'objets imparfaite, le geste de corriger est prévu.

## 11. Avant Après (13 %) | matin, ne laisser aucune trace
- Phrase : un cadrage fantôme pour celui qui lève le camp, pour prouver que le lieu est rendu comme trouvé.
- Geste : photo à l'arrivée ; le matin la caméra superpose la photo en transparence, tu cales l'angle, le déclencheur prend l'après ; un diptyque se range dans la carte de la nuit.
- Brique : Vision (empreinte d'image pour valider le même cadre), PhotoKit, Journal. Une liste de 5 gestes (déchets, cendres, herbe, toilettes, bruit) précède le déclencheur.
- Pourquoi on revient : chaque bivouac produit un diptyque partageable (acquisition douce) ; valorise le « ne laisser aucune trace » sans moralisme. Vision sert à cadrer, pas à juger.

## 12. Heure Légale (14 %) | sur place, installation
- Phrase : un compte à rebours de l'heure légale de montage et de départ pour celui qui arrive tôt au col, pour savoir quand sortir la tente.
- Geste : valide le lieu ; la Live Activity affiche « tente autorisée dans 38 min » (19 h Écrins) puis « levée du camp avant 9 h : 7 h 40 restantes ».
- Brique : Live Activity / Dynamic Island, AlarmKit (alarme de démontage), horaires de la table de règles.
- Pourquoi on revient : lie la règle à une action concrète et au bon moment ; rend le feu tricolore actif, pas seulement lu. Sans IA, marche.

## 13. Panneau Lu (14 %) | sur place, règle
- Phrase : un scan de panneau pour celui qui trouve un écriteau de parc, pour comparer ce qui est écrit à la table de règles.
- Geste : photo du panneau ; l'app lit le texte, le compare à la fiche de la zone et dit « le panneau dit 20 m des sentiers, ta fiche dit 50 m : le panneau gagne, fiche signalée ».
- Brique : Vision (reconnaissance de texte en français, VNRecognizeTextRequest), Foundation Models pour rapprocher, tout hors ligne.
- Pourquoi on revient : chaque scan répare la base (file de relecture privée, pas de contenu public) ; réponse au risque de règles périmées du rapport creuser-bivouac §6.

## 14. Charge Partagée (16 %) | social, entre amis
- Phrase : un partage de matériel entre amis pour un groupe de 4, pour que personne ne porte deux tentes et zéro réchaud.
- Geste : chacun photographie son sac (cf. Sac Pesé) ; l'app répartit tente, réchaud, eau, gaz et envoie la répartition dans iMessage.
- Brique : CloudKit Sharing, Foundation Models (équilibre en poids à partir des champs), App Intents, Messages.
- Pourquoi on revient : toute sortie à plusieurs, y compris les amis qui n'ont pas l'app (lien web) ; sans IA un tableur fait presque pareil (IA moyenne).

## 15. Calendrier Légal (17 %) | saison morte, planification
- Phrase : un calendrier des ouvertures pour celui qui rêve en février, pour savoir quand chaque zone devient bivouaquable.
- Geste : épingle des massifs « à faire » ; en retour : « Vanoise : ouvre le 1er juin, 5 €/pers. » ; compte à rebours en Live Activity.
- Brique : Live Activity, EventKit (ajout au calendrier), widgets, notifications locales ; table de règles.
- Pourquoi on revient : donne une raison d'ouvrir en plein hiver ; l'ouverture est une date réelle (1er juin, 1er juil.-30 sept.).

## 16. Gare Tente (18 %) | avant le départ, trajet en train
- Phrase : un bivouac atteignable sans voiture pour l'étudiant sans permis, pour le samedi qui part de la gare.
- Geste : choisis ta gare et ton dernier train retour ; l'app propose 3 zones légales à moins de 2 h de marche et dit à quelle heure partir.
- Brique : MapKit (itinéraires piétons et transports), Plans hors ligne pour la marche, Live Activity du trajet, table de règles.
- Pourquoi on revient : pas d'équivalent en France ; public jeune sans voiture ; se combine avec la micro-aventure du jeudi.

## 17. Repli Prévu (18 %) | sur place, orage / froid
- Phrase : trois replis pré-calculés pour celui qui perd le réseau, pour le soir où le plan A tombe.
- Geste : avant de monter, un tap télécharge le plan B : abri, refuge ouvert, parking ; il s'affiche d'un geste, hors ligne, avec distance et temps de marche.
- Brique : Plans hors ligne / MapKit, WeatherKit (déclenche la suggestion), Foundation Models (explique le choix), Live Activity.
- Pourquoi on revient : à chaque sortie, comme une assurance ; différencie des apps de carte (park4night, Komoot) par la règle plus le repli légal.

## 18. Poignet Légal (20 %) | sur place, Apple Watch
- Phrase : une complication pour celui qui marche à la tombée du jour, pour savoir en un coup d'œil si l'endroit est autorisé et jusqu'à quand.
- Geste : lève le poignet ; vert / orange / rouge, l'heure du lever de camp et la température qui baisse.
- Brique : Apple Watch (complication, WidgetKit), CoreLocation, base locale.
- Pourquoi on revient : l'usage devient glanceable, gants mis ; remplace de sortir le téléphone par −5 °C.

## 19. Page Journal (22 %) | après, souvenir
- Phrase : une page prête dans Journal pour celui qui a dormi dehors, pour garder le souvenir sans rien écrire.
- Geste : le matin, un tap « enregistrer la nuit » ; Journal reçoit l'entrée : lieu flou, ciel, température, une photo choisie, une phrase.
- Brique : Journaling Suggestions API, Foundation Models (phrase d'ouverture à partir du carnet), Photos.
- Pourquoi on revient : pousse l'app dans l'écosystème de souvenirs d'Apple ; le souvenir remonte des mois plus tard, y compris en saison morte. Sans IA, l'entrée marche (l'IA ajoute la phrase).

## 20. Nuit Noire (28 %) | sur place et planification, étoiles
- Phrase : les nuits de nouvelle lune et ciel dégagé pour celui qui veut voir la Voie lactée, pour le prochain week-end.
- Geste : choisis un lieu ; l'app classe les 14 prochaines nuits par noirceur (lune absente, nuages, humidité) et envoie « samedi : ciel noir ».
- Brique : WeatherKit (couverture nuageuse), calcul lunaire, widget, notification locale.
- Pourquoi on revient : nuits rares, alerte attendue chaque mois. Idée probable chez d'autres LLM (étoiles) : à garder seulement comme couche de « Ta nuit ».

## Recommandation pour la suite (3 pistes à tester d'abord)
1. Demi-Tour (5 %) : l'angle de gamification le plus distinctif, coût d'implémentation très bas, parle de la décision, cœur de l'app.
2. Heure Légale (14 %) : donne un geste actif au feu tricolore, démo claire (Live Activity), 1 jour de build.
3. Gare Tente (18 %) : acquisition par le jeune sans voiture, absent des concurrents, à valider avec des vrais trajets avant d'investir.
Idée à écarter si le temps manque : Bruit Rassurant (classifieur à entraîner, risque de fausses réponses).
