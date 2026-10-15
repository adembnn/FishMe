# Idées, angle « Adopter → Adapter → Scaler » (slug : adopter)

Fil rouge : Cal AI a prouvé « un geste photo → un résultat chiffré ». Ce qui change depuis la WWDC26 (8 juin 2026) : le modèle on-device de Foundation Models **accepte les images**, et il peut appeler OCR et lecture de codes-barres de Vision comme outils. Il est gratuit sous 2 M de téléchargements via Private Cloud Compute. Sources : https://developer.apple.com/wwdc26/guides/ios , https://developer.apple.com/videos/play/wwdc2026/241 , https://developer.apple.com/videos/play/wwdc2026/237 . C'est le « moment Opal » : saisir une API Apple neuve avant les autres. Les 7 idées reprennent cette mécanique sur des publics et des moments où personne ne l'a encore posée.

Écartées après vérification (déjà occupées) : scanner d'étiquettes de lavage (Laundry Master, Laundry Lens, plusieurs autres), lecteur de panneaux de stationnement (Park Here gratuit, Parky.AI, Park Snap), partage d'addition par scan (Zplit).

Garde-fou commun : sur iPhone sans Apple Intelligence (ou iOS < 27), repli = Vision OCR + correction à la main. L'IA reste indispensable, mais l'app ne plante pas.

---

## 1. **Ardoise WOD** — un timer prêt à lancer pour les pratiquants de CrossFit/Hyrox, à l'instant où le coach écrit le WOD au tableau

- **Mécanique** : on photographie l'ardoise de la salle. Le modèle lit l'écriture manuscrite et sort un entraînement typé (@Generable : format AMRAP/EMOM/For Time/Tabata, durée, mouvements, reps, charges H/F). Le timer plein écran démarre en un tap, avec Live Activity (round en cours, temps restant) et une alarme de fin.
- **Cas fondateur** : Cal AI, un geste photo → un résultat, IA indispensable, paywall dur, ~30 M$ ARR (fiche terrain, « 3 réponses réelles » n°2). HabitKit/Habit Pixel pour la niche étroite et le prix localisé (n°3). Vérifié le 12 oct. : les apps existantes (Hyro, WOD Log, WOD Timer 365) demandent de saisir le WOD à la main. Je n'ai trouvé aucune app qui part de la photo du tableau (recherche rapide, pas exhaustive). Ex. : https://apps.apple.com/br/app/hyrox-crossfit-tracker-hyro/id6753948941
- **Offre** : 1 photo gratuite, puis paywall dur. 3,99 €/mois ou 29,99 €/an, essai 7 jours. Achat unique non proposé, l'usage est quotidien. **Raison de revenir** : 3 à 5 séances par semaine. Le score saisi alimente un mur de records et une carte de résultat partageable (« Fran : 4:32 ») façon passeport Flighty, qui amène d'autres membres de la salle.
- **Brique Apple** : Foundation Models avec entrée image + outil OCR de Vision (le tableau manuscrit est le cœur), Live Activities, AlarmKit pour la fin de round, widget « WOD d'hier ».
- **Risque** : pas de donnée de santé (c'est un chrono). Le jury peut tester en direct avec un tableau blanc.
- **Probabilité qu'un autre LLM la propose : 7 %**

## 2. **Dernière Main** — un compteur de points par photo pour les soirées jeux entre amis, à la fin de chaque manche

- **Mécanique** : à la fin d'une manche, chacun pose ses cartes restantes (ou ses tuiles) et on prend une photo. Le modèle reconnaît les cartes, calcule les points du jeu choisi (Rami, Skyjo, Uno, Tarot…) et les ajoute au tableau. Le joueur corrige d'un tap si une carte est mal lue.
- **Cas fondateur** : Cal AI (photo → chiffre, saisie manuelle supprimée). Passeport partageable de Flighty, repris pour une « carte de saison » (champion, pire perdant, série de victoires) qui sert à inviter. Les apps de score existantes se saisissent à la main (non vérifié en détail).
- **Offre** : 2 jeux gratuits, pack tous jeux en achat unique 6,99 €, plus « Saison » (classements, cartes à partager) à 14,99 €/an. **Raison de revenir** : soirée jeux hebdomadaire entre les mêmes amis, classement cumulé, widget de leaderboard.
- **Brique Apple** : Foundation Models image + Vision (détection de cartes), widgets, App Intents (« Siri, ajoute 23 points à Léa »), Live Activity pour le score en cours.
- **Risque** : précision de lecture (compter des valeurs sur une photo est plus fragile qu'un texte). D'où l'étape « confirmer les cartes » en un écran. À tester en priorité le jour 1.
- **Probabilité qu'un autre LLM la propose : 5 %**

## 3. **Ma Ligne** — tes horaires extraits d'un planning de service en photo, pour les étudiants en job (restauration, retail, événementiel), chaque semaine

- **Mécanique** : on photographie (ou on importe) le planning d'équipe, souvent un tableau papier ou une image WhatsApp pleine de prénoms. On indique son prénom une seule fois. Le modèle isole la ligne de la personne et en tire les services (jour, début, fin, poste). Ils arrivent dans Calendrier (EventKit), avec une alarme de départ et un widget « prochain service ».
- **Cas fondateur** : Opal, qui a saisi une API Apple neuve avant tout le monde (~10 M$ ARR, 11 salariés) : ici image input + AlarmKit, tous deux récents. Cal AI pour « un geste → le résultat qu'on veut ». Aucune app de calendrier native ne sait choisir « sa » ligne dans un tableau (je n'ai pas trouvé d'app dédiée en 12 oct., recherche non exhaustive).
- **Offre** : 3 plannings gratuits, puis 19,99 €/an (essai 7 jours après le premier planning lu). **Raison de revenir** : un nouveau planning chaque semaine ou chaque mois, donc usage récurrent par construction. Les prénoms des collègues restent sur l'iPhone (argument vie privée).
- **Brique Apple** : Foundation Models image + OCR (le tableau est la difficulté), EventKit, AlarmKit, Live Activity « départ dans 40 min », App Intents (« Siri, je bosse quand jeudi ? »), widget.
- **Risque** : mise en page de planning très variable. Prévoir un écran de confirmation avec la ligne surlignée.
- **Probabilité qu'un autre LLM la propose : 8 %**

## 4. **Total Marge** — l'addition des points annotés dans les marges, pour les enseignants qui corrigent des copies, à chaque paquet de copies

- **Mécanique** : l'enseignant photographie la copie corrigée. Le modèle lit les points écrits à la main dans les marges (par question), contrôle la somme et propose la note sur 20 avec le détail. Un tap valide, la copie suivante s'ouvre.
- **Cas fondateur** : Cal AI (une photo → un chiffre), HabitKit pour l'outil de niche très soigné qui se vend à un public précis (fiche terrain §3). Non vérifié : concurrents. Je pense à des apps de QCM/scan optique, qui exigent un format imprimé spécial, pas une copie manuscrite libre.
- **Offre** : 20 copies gratuites, puis 24,99 €/an (le payeur est l'enseignant, pas l'établissement). **Raison de revenir** : devoirs et copies toute l'année, pics aux examens. Export CSV des notes, statistiques de classe.
- **Brique Apple** : Foundation Models image + OCR manuscrit de Vision, traitement 100 % on-device (argument fort : copies d'élèves, RGPD), App Intents « copie suivante », export Fichiers/CSV.
- **Risque** : écriture des chiffres. Les cases douteuses sont surlignées, jamais validées sans l'enseignant. Canal d'acquisition : le réseau de profs des 3 étudiants. Aucune donnée de santé ni financière.
- **Probabilité qu'un autre LLM la propose : 6 %**

## 5. **Prix Kilo** — le prix au kilo réel d'un produit, par photo de l'étiquette, pour les étudiants qui font leurs courses, chaque semaine

- **Mécanique** : devant le rayon, on photographie l'étiquette (ou deux produits côte à côte). Le modèle lit le prix, la quantité, les formats multiples (« lot de 6 x 33 cl ») et les promotions (« le 2e à -50 % », « 3 pour 2 »). Il affiche le prix réel au kilo ou au litre et un verdict : « Prends B : 0,80 €/kg de moins ». Le calcul est fait par du code, pas par le modèle.
- **Cas fondateur** : Cal AI (photo → chiffre). L'IA est utile pour lire le texte de promotion et les formats, que les calculateurs manuels de prix unitaire laissent à l'utilisateur (non vérifié en détail). Fiche terrain §5 : fatigue des abonnements, d'où une offre simple.
- **Offre** : 5 scans gratuits par semaine, puis 2,99 €/mois ou 19,99 €/an. Argument de vente : « tu économises plus que ça en un panier ». **Raison de revenir** : courses hebdomadaires, widget « économisé ce mois », carte partageable.
- **Brique Apple** : Foundation Models image + sortie @Generable (prix, quantité, promo en champs typés), widgets, App Intents (« Siri, compare avec le précédent »).
- **Risque** : pas de scraping (seule la photo de l'utilisateur est lue), pas de finance réglementée. Idée la plus « évidente » du lot, donc la plus exposée à un concurrent.
- **Probabilité qu'un autre LLM la propose : 18 %**

## 6. **Bol Plein** — la ration quotidienne exacte lue sur le sac de croquettes, pour les propriétaires de chien ou chat, tous les jours

- **Mécanique** : on photographie le tableau de rations imprimé au dos du sac, puis on saisit le poids de l'animal. Le modèle lit le tableau et donne les grammes par jour, répartis par repas, plus « il reste 11 jours dans ce sac ». Un widget interactif (« Rex a mangé ✓ ») sert de rappel et de journal.
- **Cas fondateur** : Cal AI (photo → quantité chiffrée), transposé du repas humain au repas animal : pas de santé humaine, et on lit uniquement la recommandation du fabricant. Le tableau est différent sur chaque marque, c'est ce qui justifie l'IA. Le public paie volontiers pour son animal (non chiffré ici).
- **Offre** : 1 sac gratuit, puis 14,99 €/an, essai 7 jours. **Raison de revenir** : repas quotidiens, compte à rebours du sac, rappel de rachat. Le partage du foyer (CloudKit) est un bonus, hors périmètre de la semaine.
- **Brique Apple** : Foundation Models image + OCR (tableau de rations), widgets interactifs, Live Activity (repas du soir), App Intents (« Siri, j'ai nourri Rex »).
- **Risque** : mention claire « selon l'emballage », pas de conseil vétérinaire. Proche d'un suivi de routine, mais la photo du sac est le geste central, ce qui évite l'habit tracker générique.
- **Probabilité qu'un autre LLM la propose : 12 %**

## 7. **La Passe** — le déroulé minute par minute d'un dîner, à partir de photos de recettes, pour celui qui reçoit, le soir où il reçoit

- **Mécanique** : on photographie une ou plusieurs recettes (livre ou carnet) et on indique « à table à 20h30 ». Le modèle extrait les étapes et leurs durées, puis fusionne les recettes en un seul planning à rebours (« 19h05 four à 200 °, 19h40 eau des pâtes »). Une Live Activity affiche l'étape en cours, et Siri répond « étape suivante » mains sales.
- **Cas fondateur** : Cal AI (photo → résultat prêt). Flighty pour le proactif : le plan se met à jour sur l'écran verrouillé sans ouvrir l'app. Aucune fonction native Apple ne fusionne plusieurs recettes en un planning (non vérifié contre les apps de recettes, qui ont des minuteurs mais partent d'une seule recette).
- **Offre** : 1 dîner gratuit, puis 3,99 €/mois ou 24,99 €/an. **Raison de revenir** : chaque repas pour invités, week-end surtout. Le planning se partage à un co-cuisinier.
- **Brique Apple** : Foundation Models image + @Generable (étapes, durées, dépendances), Live Activities, AlarmKit pour les minuteurs, App Intents pour la voix.
- **Risque** : usage plutôt hebdomadaire que quotidien. L'idée la plus attendue du lot (recette + minuteur), d'où une probabilité plus haute.
- **Probabilité qu'un autre LLM la propose : 25 %**

---

## Récapitulatif

| # | Nom | Public / moment | % |
|---|-----|-----------------|---|
| 1 | Ardoise WOD | Pratiquants CrossFit/Hyrox, au tableau du coach | 7 |
| 2 | Dernière Main | Amis en soirée jeux, fin de manche | 5 |
| 3 | Ma Ligne | Étudiants en job, nouveau planning | 8 |
| 4 | Total Marge | Enseignants, paquet de copies | 6 |
| 5 | Prix Kilo | Étudiants, courses de la semaine | 18 |
| 6 | Bol Plein | Propriétaires d'animaux, repas quotidien | 12 |
| 7 | La Passe | Hôtes de dîner, soir de réception | 25 |

Six idées sur sept sont sous 20 %. Point commun technique : une seule brique centrale (Foundation Models avec image + OCR), donc un socle partagé si l'équipe hésite entre plusieurs idées avant jeudi. Premier test à faire le jour 1 : photographier 10 vrais supports (tableau, planning, sac, copie, cartes) et mesurer le taux de lecture correcte avant de choisir.
