# RAD, idées angle « outil »

Vérification web (3 recherches) : Cupla (500 k couples, « Cupla Assist » qui trouve du temps libre), Howbout (calendrier partagé LDR, import de calendriers, fuseaux) et MeetTime (heure locale, sommeil, « le bon moment pour appeler ») occupent déjà le « créneau commun » brut. Une app qui affiche seulement des plages libres communes est donc un clone. Les six idées ci-dessous visent ce que ces apps ne font pas : arbitrer qui se sacrifie, lire des documents que personne ne veut lire, agir au bon instant, et traiter les moments précis (gare, passage de semestre, appel raté).

## 1. Semestre Miroir
**Carte du semestre à deux, pour le soir où l'un reçoit le calendrier de sa fac d'accueil.**
- Moment vécu : douleurs 1 et 6. Avant un Erasmus, chacun a un PDF d'emploi du temps, un calendrier académique en langue étrangère, des semaines d'examens, de lecture, des fériés différents. Personne ne les croise, on découvre en octobre qu'on ne se voit pas avant décembre.
- Mécanique : chacun glisse ses PDF, captures ou liens d'emploi du temps. Foundation Models les lit (dont l'allemand, l'espagnol, l'italien) et en sort une frise du semestre : semaines mortes de chacun, fenêtres de visite possibles, 3 week-ends classés. Chacun valide en un tap, la fenêtre choisie devient un plan partagé.
- Émouvant : en trois minutes, le semestre de 5 mois qui faisait peur a quatre points lumineux dessus.
- Brique : Foundation Models (lecture de documents désordonnés, extraction structurée en `@Generable`) + Vision pour les captures. Test : sans le modèle, il faut saisir à la main 40 cours par personne, l'idée tombe. Le vivier se renouvelle chaque semestre.
- Offre : 14,99 € pour deux, par semestre (passe semestre, achat unique non renouvelé). Raison de revenir : les emplois du temps changent à mi-semestre, le calendrier se met à jour en collant le nouveau PDF ; chaque nouveau semestre rouvre le besoin.
- Probabilité qu'un autre LLM la propose : 15 %.

## 2. Réveil Duo
**Rattrapage d'appel raté pour les couples à fuseaux décalés, pour le soir où l'un s'est endormi avant l'appel.**
- Moment vécu : douleur 1 (l'appel manqué parce que l'autre s'est endormi) et 5 (le malaise du lendemain).
- Mécanique : l'appel fixé crée une alarme AlarmKit chez les deux (elle traverse le mode silencieux et le Focus, avec un bouton « 10 min de plus »). Si l'un ne répond pas, l'autre ne culpabilise pas : un tap sur « raté » et le modèle propose les 3 prochains créneaux qui respectent leurs sommeils respectifs, l'autre répond d'un tap en se réveillant.
- Émouvant : l'appel raté devient un rendez-vous reprogrammé en deux secondes, sans reproche ni long message au réveil.
- Brique : AlarmKit (seule façon de réveiller pour de vrai sur iOS 26), Apple Watch (l'alarme au poignet), Foundation Models (choix du créneau selon les contraintes). Test : sans AlarmKit, une notification se fait ignorer à 23 h 30, l'idée tombe. Sans modèle, on retombe sur un sélecteur d'heure.
- Offre : 7,99 € pour deux, achat unique. Raison de revenir : chaque appel de la semaine passe par là.
- Probabilité qu'un autre LLM la propose : 15 %.

## 3. Sortie Cours
**Un « je pense à toi » qui arrive pile à la sortie de l'examen de l'autre, pour les jours chargés où il n'y a aucun créneau d'appel.**
- Moment vécu : douleur 3 (le silence des jours chargés, on veut montrer qu'on pense à l'autre sans effort).
- Mécanique : A touche l'Action button ou un widget (App Intent), enregistre un vocal de 5 secondes ou envoie un mot. Le message est retenu. B, lui, reçoit le tout à la fin de son partiel, de son créneau de bloc opératoire ou de sa garde, la seule minute où il a le téléphone en main. Foundation Models devine l'heure de sortie dans un agenda mal rangé (« Partiel Fisc. Amphi B » = fin à 17 h).
- Émouvant : on sort de l'examen, on rallume le téléphone, il y a déjà quelqu'un.
- Brique : App Intents (envoi en un geste), calendrier local (EventKit) + Foundation Models (déduire la fin d'un événement mal intitulé). Test : sans l'intelligence de timing, c'est un simple message vocal et il y en a déjà mille ; c'est l'arrivée à la bonne minute qui fait l'idée.
- Offre : abonnement 1,99 €/mois à deux, ou 9,99 € pour deux par semestre. Raison de revenir : chaque période d'examens ou de gardes.
- Probabilité qu'un autre LLM la propose : 12 %.

## 4. Tour Veille
**Tableau des nuits sacrifiées, pour le couple qui s'épuise à caler tous les appels sur le même fuseau.**
- Moment vécu : douleur 1 (une seule heure de recouvrement) et 5 (la dispute qui monte quand un des deux paie toujours le décalage).
- Mécanique : chacun autorise la lecture de son calendrier et indique son rythme de sommeil. Foundation Models propose la semaine d'appels en minimisant la fatigue totale et en alternant qui se couche tard ou se lève tôt. Un compteur discret montre qui a « payé » le plus de nuits ; la semaine suivante penche en sa faveur.
- Émouvant : l'équité devient visible et se règle sans conversation tendue.
- Brique : Foundation Models (arbitrer des contraintes floues), widget de l'appel du soir. Test : sans le modèle, c'est un calendrier partagé de plus (Howbout, Cupla), l'idée tombe ; avec lui, c'est un arbitre.
- Offre : 29 € par an pour deux, ou 6 € par mois pour un semestre. Raison de revenir : la semaine change, le compteur d'équité aussi.
- Probabilité qu'un autre LLM la propose : 40 %. Idée la plus proche du marché existant.

## 5. Pont Aérien
**Suivi d'un voyage de retrouvailles pour l'attente à la gare ou à l'aéroport, le jour de la visite.**
- Moment vécu : douleurs 4 et 6. Le jour de l'arrivée, l'autre refait vingt fois « t'es où ? » et la jauge d'impatience monte ; le départ, trois jours plus tard, est le pire moment.
- Mécanique : A transfère à l'app l'e-mail de confirmation (train ou vol). Foundation Models en extrait numéro, horaires, quai. Une Live Activity s'affiche chez B sur l'écran verrouillé : « il arrive à 19 h 42, quai 4, retard +7 min », sans localisation permanente, juste les données du billet. À l'arrivée, un tap de A déclenche une fin de trajet partagée.
- Émouvant : l'attente devient un décompte qui avance dans la poche, avec l'heure exacte du premier regard.
- Brique : Live Activities (+ Dynamic Island) et Foundation Models (extraire un billet d'un e-mail). Test : sans Live Activity, c'est un SMS ; sans modèle, saisie manuelle d'un numéro de train, l'idée tient moins bien.
- Offre : achat à la visite, 0,99 € par trajet partagé, ou 12 € par an pour deux. Raison de revenir : chaque visite, soit 8 à 15 fois par an.
- Probabilité qu'un autre LLM la propose : 25 %.

## 6. Va-et-vient
**Équité des déplacements et budget de la prochaine visite, pour le moment où l'on se demande qui vient cette fois.**
- Moment vécu : douleur 6 (plan flou de la prochaine visite) et la tension silencieuse sur qui voyage et paie.
- Mécanique : l'app garde le registre des trajets (qui est venu, combien, quel prix). À chaque visite à planifier, Foundation Models croise congés, examens et budget saisis, et propose « c'est ton tour de recevoir, week-end du 14, budget 94 € ». Un tap pour accepter ou proposer autre chose.
- Émouvant : la question gênante de l'argent et du tour est posée par l'app, pas par l'un des deux.
- Brique : Foundation Models (arbitrage entre disponibilités et budget), widget de la prochaine visite. Test : sans le modèle, c'est un tableur partagé ; la formulation d'un compromis est ce qui reste.
- Offre : 19 € par an pour deux. Raison de revenir : chaque visite, mise à jour du registre.
- Probabilité qu'un autre LLM la propose : 35 %.

## Récapitulatif

| # | Nom | Probabilité |
|---|-----|-------------|
| 1 | Semestre Miroir | 15 % |
| 2 | Réveil Duo | 15 % |
| 3 | Sortie Cours | 12 % |
| 4 | Tour Veille | 40 % |
| 5 | Pont Aérien | 25 % |
| 6 | Va-et-vient | 35 % |

Trois idées sous 20 % : Semestre Miroir, Réveil Duo, Sortie Cours. Limite à valider avec le coéquipier et les couples de l'école : aucun témoignage francophone ne confirme que les couples paient pour ces services.
