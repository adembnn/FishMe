# RAD, angle « moments » : 6 idées, une par moment dur

Vérifs web faites : alarme à la voix du partenaire existe déjà (Couple Alarm, Sunchat, Memo Alarm) donc écartée. Entwine existe pour « faire une pause avant l'escalade », mais pour couples en général, sans rendez-vous d'appel ni décalage. Révélation simultanée : seulement comme argument de fonction (Open Heart), pas comme app dédiée à la dispute. Rien trouvé sur les deux autres sous cette forme.

---

## 1. Garder Ça
**Des sons de chez vous, pour celui qui reste, pour les 7 jours après l'adieu à la gare.**
- **Moment vécu** : douleur 4, le creux de 3 à 7 jours après l'adieu. L'appartement est trop calme, la voix de l'autre n'y est plus.
- **Mécanique** : pendant la visite, chacun appuie sur un bouton (Action Button ou Centre de contrôle, sans ouvrir l'app) et l'iPhone garde 10 secondes de son : la bouilloire, un rire, la porte d'entrée. Au départ, ces sons se verrouillent. Les 7 jours suivants, un son arrive chaque soir à l'heure où le silence pèse le plus, sur l'écran verrouillé, et se joue au toucher.
- **Émotion** : on ne reçoit pas une photo d'avant, on réentend la pièce où l'autre était. Le son revient, pas le souvenir posé.
- **Brique Apple** : Controls (iOS 18) + App Intents pour la capture en un geste de poche, Live Activity pour la carte du soir. Test : sans la capture en un geste, personne n'enregistre pendant la visite (on a la tête ailleurs) et l'idée tombe. Sans Live Activity, ça reste une notification : dégradé mais debout. Foundation Models : non, et c'est voulu.
- **Offre** : 6,99 € pour deux, achat unique (une « saison de visites »), + 2,99 € le pack de 12 sons supplémentaires par visite. Revenir : chaque visite (toutes les 4 à 8 semaines) relance une semaine de sons.
- **Probabilité qu'un autre LLM la propose** : 12 %.

## 2. Trêve
**Un rendez-vous d'appel posé en pleine dispute par texto, pour le soir où le décalage empêche de régler.**
- **Moment vécu** : douleur 5. Dispute qui monte à minuit chez l'un, midi chez l'autre, chacun relit et envenime, un « ok » sec reste sans réponse pendant 6 heures.
- **Mécanique** : l'un appuie sur « Trêve », choisit avec l'autre un créneau d'appel dans la seule fenêtre commune. Entre-temps, chacun écrit sa version dans un coffre que l'autre ne voit pas, et plus aucun texto ne passe par l'app. Au créneau, une alarme sonne chez les deux et les deux textes se révèlent côte à côte, en même temps.
- **Émotion** : le soulagement de ne plus avoir à deviner l'état de l'autre pendant des heures. L'écran de trêve dit une seule chose : « Il y a un rendez-vous, vous êtes d'accord là-dessus. »
- **Brique Apple** : AlarmKit (iOS 26), qui perce le silencieux et le mode Concentration, + Live Activity du compte à rebours. Test : sans AlarmKit, le rendez-vous est une notification qu'on ignore quand on boude, et la promesse (« on s'appelle, les deux ») tombe. Idée debout mais bien plus faible.
- **Offre** : abonnement court 3,99 €/mois pour deux, résiliable en un tap, ou 19,99 € pour 12 mois. Revenir : une dispute par mois en moyenne dans une RAD, et l'app est là quand on en a besoin.
- **Probabilité qu'un autre LLM la propose** : 10 %.

## 3. Appel Troué
**Une conversation vocale en tours alternés pour un couple qui ne se croise jamais, pour la nuit où l'autre dort.**
- **Moment vécu** : douleur 1, l'appel manqué parce que l'autre s'est endormi, et douleur 2, les appels qui s'épuisent en « quoi de neuf ».
- **Mécanique** : le premier parle à son téléphone comme à un appel et laisse des silences là où il attend une réponse (l'app détecte la pause). Le second, au réveil, entend la première phrase puis parle dans le trou, phrase après phrase. L'app assemble une vraie conversation avec les respirations, jouable à deux plus tard.
- **Émotion** : la conversation a eu lieu, même à huit heures d'écart. On garde un « appel » réel, pas une pile de vocaux sans fil.
- **Brique Apple** : SpeechAnalyzer / Speech on-device (iOS 26) pour couper aux silences et sous-titrer pendant qu'on répond, plus audio AVFoundation. Test : sans détection des pauses, il faut tout découper à la main et c'est trop lourd, donc l'idée ne survit qu'à moitié (WhatsApp fait déjà des vocaux). La brique est réelle, pas décorative, mais pas irremplaçable.
- **Offre** : 4,99 € pour deux, achat unique, + abonnement 1,99 €/mois pour l'archive audio illimitée. Revenir : le fuseau ne change pas, la nuit revient chaque soir.
- **Probabilité qu'un autre LLM la propose** : 17 %.

## 4. Juste Avant
**Un mot du partenaire qui apparaît 15 minutes avant l'événement redouté, pour le jour chargé (oral, garde, partiel) où l'autre n'a pas le temps d'écrire.**
- **Moment vécu** : douleur 3, le silence des jours chargés et le besoin de montrer qu'on pense à l'autre sans effort.
- **Mécanique** : la personne chargée partage un seul événement de son agenda (« Oral jeudi 14 h »). Le partenaire reçoit « Écris-lui pour 13 h 45 ». Il écrit ou enregistre à l'avance. Le mot s'affiche à l'heure pile sur l'écran verrouillé de l'autre, en silence, sans que l'expéditeur ait été disponible à ce moment.
- **Émotion** : le message arrive quand la personne est seule dans le couloir. Celui qui l'a écrit dormait ou travaillait.
- **Brique Apple** : EventKit (un événement choisi) + Live Activity pour l'affichage à l'heure + App Intents pour que Siri propose « prépare un mot pour son oral ». Foundation Models optionnel : repérer sur l'appareil quels événements sont lourds (« partiels », « entretien ») pour suggérer. Test : sans lien à l'événement, c'est un SMS programmé, donc l'idée tombe. Le lien agenda est la brique. Foundation Models est un plus, non indispensable.
- **Offre** : 2,99 € pour deux, achat unique, + pack saisonnier (partiels, rentrée) à 1,99 €. Revenir : un événement lourd par mois suffit.
- **Probabilité qu'un autre LLM la propose** : 22 %.

## 5. Veillée
**Une présence silencieuse partagée, pour la nuit d'avant les retrouvailles où aucun des deux ne dort.**
- **Moment vécu** : la veille de la visite (non couverte en douleur par la fiche, vécu d'Adem à confirmer) : trop d'adrénaline, on reste en appel sans rien dire alors que la fatigue détruit le créneau commun.
- **Mécanique** : chacun allume une bougie dans l'app. Les deux bougies brûlent au même rythme toute la nuit. Poser le téléphone suffit, aucun appel. Si l'un se lève et reprend l'écran, la flamme de l'autre vacille une seconde. À l'aube, les deux bougies s'éteignent ensemble et affichent l'heure du train.
- **Émotion** : on n'est pas seul à veiller. Aucun mot, pas de caméra, pas de position.
- **Brique Apple** : Live Activity + Dynamic Island (les deux flammes à l'écran verrouillé, sans ouvrir l'app) ; Apple Watch pour le vacillement au poignet. Test : sans Live Activity il faut garder l'app ouverte toute la nuit, donc l'idée tombe.
- **Offre** : 2,99 € pour deux, achat unique, bougies à débloquer en variantes (1,99 €). Revenir : une veillée par visite, donc toutes les 4 à 8 semaines. Fréquence faible, c'est le point faible.
- **Probabilité qu'un autre LLM la propose** : 9 %.

## 6. Parcours Offert
**Une chasse de notes scellées dans la ville de l'autre, pour l'anniversaire où l'on ne peut pas être là.**
- **Moment vécu** : l'anniversaire loin (non couvert par la fiche, à vérifier en entretien). Le cadeau livré par un coursier remplace la présence.
- **Mécanique** : le partenaire absent place 4 à 6 étapes sur la carte de la ville de l'autre (le café du premier rendez-vous, un banc), avec à chacune un mot ou un vocal. Le jour J, chaque note s'ouvre seulement quand la personne arrive à l'endroit. Le donneur voit une seule carte de progression, uniquement ce jour-là, jamais après.
- **Émotion** : la personne marche dans sa propre ville guidée par la voix de l'absent, qui connaît les lieux d'une ancienne visite.
- **Brique Apple** : géorepérage de MapKit / Core Location (zones, pas de suivi continu) + Live Activity de progression partagée. Test : sans le déclenchement à l'arrivée, c'est une liste de notes et l'idée tombe.
- **Offre** : 3,99 € le parcours (consommable) ou 9,99 € les trois. Revenir : deux anniversaires + mensiversaires + fêtes + retours dans une même ville.
- **Probabilité qu'un autre LLM la propose** : 20 %.

---
## Honnêteté
- Sous 20 % : 1 (12 %), 2 (10 %), 3 (17 %), 5 (9 %). Les idées 4 (22 %) et 6 (20 %) sont plus attendues (message programmé, chasse au trésor).
- Risque commun : fréquence d'usage faible pour 5 et 6, donc achat unique plutôt qu'abonnement. 2 est la seule à vivre en abonnement court.
- À valider avec le coéquipier en RAD : l'idée 1 (sons) et l'idée 2 (Trêve) touchent les deux douleurs les plus vécues ; 5 et 6 sont des hypothèses non issues de la fiche terrain.
