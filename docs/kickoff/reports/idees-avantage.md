# Idées angle « avantage » : l'équipe est elle-même la cible (étudiants M1 ESSEC)

Vérifications web faites le 12 oct. 2026 (concurrents cités dans chaque fiche). Fiche terrain = `1-terrain.md`.
Test des 100 premiers utilisateurs : les 3 fondateurs ont accès ce soir à des milliers d'étudiants (Cergy, La Défense, Singapour, Rabat), aux assos et aux groupes WhatsApp de promo.

---

## 1. **Absence Permise** : « le quota d'absences et la note à viser, calculés depuis la photo du syllabus, pour l'étudiant, pour le matin où il hésite à sécher »
- **Mécanique** : l'étudiant photographie la page du syllabus ou du règlement (assiduité, barème, dates). Vision + Foundation Models (@Generable) en extraient absences tolérées, pondérations et dates. Le widget affiche « Compta : 1 absence restante » et « note mini à l'examen : 9,5 ». Siri : « je peux sécher le cours de marketing ? ».
- **Fondement** : les règles d'assiduité et de barème dorment dans des PDF de 20 pages, que personne ne relit. Les apps de notes existantes (Syllabus Grade Metrics, Grademy) exigent une saisie manuelle, ce qui tue le premier moment utile (fiche terrain, enjeu 2). Le vrai test est ce soir : demander à 20 camarades combien d'absences il leur reste (l'équipe peut le faire en 10 minutes).
- **Offre** : gratuit pour 1 cours, 14,99 €/an ou 2,99 €/mois pour tous les cours (paywall après le premier syllabus scanné, donc après la valeur). Raison de revenir : widget quotidien, chaque absence se décompte, chaque note saisie recalcule la cible. Cycle de 2 semestres par an, pas un pic unique.
- **Brique Apple** : Vision (lecture du document), Foundation Models (extraction typée, FR), App Intents (Siri), widgets, Live Activity optionnelle la veille d'un rendu.
- **Retirer l'IA** : il faut saisir 30 champs à la main, donc la valeur disparaît. L'IA est indispensable.
- **Risque** : la sortie IA peut se tromper, d'où un écran de validation en 1 tap. Toujours un repli manuel sur iPhone sans Apple Intelligence.
- **Probabilité qu'un autre LLM la propose** : **12 %**

## 2. **Créneau Commun** : « le créneau libre pour tout un groupe, trouvé à partir des photos d'emplois du temps, pour le bureau d'asso qui cherche une réunion »
- **Mécanique** : chaque membre envoie une capture de son emploi du temps (ou de son calendrier de cours). L'IA lit chaque image (Vision + @Generable) et l'app affiche les 3 meilleurs créneaux communs, partageables en une carte dans le groupe WhatsApp.
- **Fondement** : Doodle et When2meet obligent chacun à cliquer ses disponibilités à la main ; avec 12 personnes, le sondage meurt. Le goulot est la saisie, que l'image supprime. Cible immédiate : les bureaux d'assos ESSEC, les groupes de projet. Au-delà : colocs, clubs de sport, équipes de bénévoles, parents d'élèves.
- **Offre** : gratuit jusqu'à 4 personnes, 3,99 €/mois ou 24,99 €/an pour les responsables de groupe (c'est lui qui paie, c'est lui qui invite). Raison de revenir : une réunion par semaine pour un bureau d'asso.
- **Brique Apple** : Vision, Foundation Models, ShareLink / carte de partage, widgets (« prochaine réunion »), App Intents.
- **Risque** : le partage entre appareils sans backend. Prévoir un lien ou un code compact, ou CloudKit partagé. C'est l'inconnue technique de la semaine.
- **Probabilité** : **18 %**

## 3. **Qui Déjà** : « la mémoire des gens rencontrés, retrouvable par un détail flou, pour l'étudiant qui croise 300 personnes par an »
- **Mécanique** : juste après une rencontre, 5 secondes de voix : « Camille, rencontrée au gala, stage chez L'Oréal, fait du ski ». Foundation Models structure la fiche. Plus tard : « la fille du ski, rencontrée à Singapour » retrouve Camille. Avant un événement, le widget montre « tu vas revoir : ... ».
- **Fondement** : rentrée, intégration, galas, échanges, forums de recrutement : un étudiant rencontre des centaines de personnes. Les CRM perso (Clay, Dex) visent les pros et demandent une saisie lourde (comparatif : getdex.com/blog/dex-vs-clay). Visual Intelligence lit les cartes de visite mais ne retient pas le contexte. Extension : conférences, nouveau job, nouvelle ville, tout le monde qui oublie des prénoms.
- **Offre** : 19,99 €/an, essai 7 jours après 5 fiches créées. Raison de revenir : un geste après chaque rencontre, une consultation avant chaque événement.
- **Brique Apple** : SpeechAnalyzer / dictée on-device, Foundation Models (extraction + recherche sémantique perso), App Intents + Spotlight, widgets. Données locales, argument vie privée fort.
- **Retirer l'IA** : la recherche floue (« la fille du ski ») et la saisie vocale structurée disparaissent. Reste un carnet d'adresses.
- **Probabilité** : **18 %**

## 4. **Prêt Pote** : « qui a quoi (chargeur, livre, perceuse, robe), tenu par une photo et un mot, pour les colocs et les assos qui se prêtent tout »
- **Mécanique** : photo de l'objet, dire « à Théo ». Vision nomme l'objet, le contact est associé, une relance douce part au bout de X jours. Siri : « qui a mon chargeur ? ».
- **Fondement** : observation de vie étudiante (matériel d'asso, colocs, tenues de soirée) sans chiffre publié, **à valider ce soir sur 20 étudiants**. Les apps d'inventaire de prêt existantes (type Libib) sont centrées bibliothèque et lourdes.
- **Offre** : achat unique 3,99 €, ou gratuit pour 5 objets puis 1,99 €/mois. **Faiblesse assumée** : monétisation la plus fragile des sept, usage modeste. À garder en repli.
- **Brique Apple** : Vision (reconnaissance d'objet), Contacts, App Intents, notifications / Live Activity de relance, widget « objets dehors ».
- **Probabilité** : **12 %**

## 5. **Réveil Planning** : « l'alarme qui se règle toute seule d'après la photo de ton emploi du temps, pour l'étudiant (ou le salarié en shifts) dont le premier cours change chaque jour »
- **Mécanique** : une photo de l'emploi du temps de la semaine. L'IA lit les heures de début, déduit l'alarme (début moins trajet moins préparation) et programme de vraies alarmes qui sonnent malgré le mode silencieux. Chaque semaine : une nouvelle photo.
- **Fondement** : AlarmKit (iOS 26) est la nouvelle API Apple que les alarmes tierces viennent d'obtenir, même schéma qu'Opal avec Screen Time (fiche terrain, « 3 réponses réelles »). **Concurrent réel** : MeetAlarm lit déjà un calendrier et crée des alarmes (meetalarm.app/en/blog/calendar-alarm-apps-compared). La différence : pas de calendrier à tenir, une photo suffit ; cible serveurs, étudiants, soignants en shifts.
- **Offre** : 14,99 €/an, gratuit pour 3 alarmes. Raison de revenir : quotidienne, c'est un réveil, et chaque semaine apporte une nouvelle photo.
- **Brique Apple** : AlarmKit, Vision, Foundation Models, Live Activity (« pars dans 12 min »), App Intents.
- **Risque** : fiabilité (une alarme ratée = utilisateur perdu), donc tests sérieux avant vendredi.
- **Probabilité** : **30 %** (AlarmKit est une évidence pour qui connaît iOS 26)

## 6. **Note Cadeau** : « l'idée de cadeau qui se souvient de ce que l'ami a dit en passant, pour les anniversaires qu'on oublie »
- **Mécanique** : au fil de l'année, Siri : « note pour Léa : elle veut un vélo ». Deux semaines avant son anniversaire, une Live Activity propose 3 idées tirées de vos notes, avec un budget.
- **Fondement** : l'anniversaire d'un ami est le moment où tout le monde « ne sait pas quoi offrir » alors que l'ami l'a dit en mars. Concurrents : listes de souhaits partagées (Elfster, Giftwhale), mais elles exigent que l'ami remplisse la liste. Ici c'est l'observateur qui capte. Utilisation étudiante : cagnottes de promo, anniversaires de coloc, mais universelle.
- **Offre** : 14,99 €/an, essai 7 jours. Raison de revenir : une note vocale par semaine, un rappel avant chaque anniversaire.
- **Brique Apple** : App Intents (note à Siri sans ouvrir l'app), Contacts (dates), Foundation Models (tri et suggestions à partir de vos notes), Live Activity, widgets.
- **Risque** : IA un peu décorative (les notes suffiraient à les afficher), donc à pousser sur la recherche floue des notes. Fiche la moins défendable côté « IA indispensable ».
- **Probabilité** : **30 %**

## 7. **État Zéro** : « le constat avant/après d'un logement ou d'un véhicule loué, comparé par l'IA, pour le locataire qui veut récupérer sa caution »
- **Mécanique** : tour guidé de la pièce en photos à l'entrée, même tour à la sortie. Vision et Foundation Models comparent et listent les différences probables (impact mur, rayure). Export PDF daté en un tap.
- **Fondement** : caution de plusieurs centaines d'euros, contestée par le propriétaire à chaque déménagement (colocs, stage à l'étranger, échange à Singapour ou Rabat). **Concurrent récent** : DepositGenie, une app iOS de preuves d'état des lieux (reddit.com/r/SideProject/comments/1omlud6). Extension : trottinettes, voitures de location, matériel d'asso, Airbnb.
- **Offre** : achat par logement 7,99 €, ou 19,99 €/an pour les loueurs de véhicules. Raison de revenir : **faible** (deux moments par an ; la fiche terrain pointe le pic d'été du logement étudiant). Par contre, plusieurs étudiants ont des locations répétées (voiture, matériel).
- **Brique Apple** : Vision, Foundation Models (entrée image annoncée WWDC26), PDFKit, Live Activity « sortie dans 3 jours : refais le tour ».
- **Risque** : à 20 % de chances d'être un faux bon sujet saisonnier. À garder en dernier.
- **Probabilité** : **25 %**

---

## Synthèse
| Rang à jouer | Nom | % LLM | Pourquoi |
|---|---|---|---|
| 1 | Absence Permise | 12 | testable ce soir, valeur immédiate, usage récurrent |
| 2 | Créneau Commun | 18 | le payeur est le chef de groupe, viralité intégrée (la carte partagée) |
| 3 | Qui Déjà | 18 | geste vocal de 5 s, rétention par événement |
| 4 | Réveil Planning | 30 | AlarmKit, rétention quotidienne, mais concurrent présent |
| 5 | Note Cadeau | 30 | rétention par anniversaires, IA la moins indispensable |
| 6 | État Zéro | 25 | gros enjeu d'argent, retour faible |
| 7 | Prêt Pote | 12 | idée originale, monétisation fragile |

Idées éliminées après recherche : Taille Cabine (mesure de bagage à main, saturé : Kayak, easyJet, Luggify, BagSizer), Calcul Cabinet (maths de case interview, saturé : CaseXcel, Consulting Mental Math), Répète Oral (zone « coach IA » interdite).
Sous 20 % : Absence Permise, Créneau Commun, Qui Déjà, Prêt Pote (4 idées).
