# Prototyper comme Apple le propose (« Design a Simple App »)

Source : ressource Apple Education, 4 tutoriels lus en entier sur education.apple.com (projet T049524A, tutoriels T049525A à T049528A). Les organisateurs la recommandent avant le Build Challenge et préciseront la phase de prototypage le jour J. Durée totale annoncée : 2 h.
Légende : **[F]** lu sur les pages Apple. **[I]** déduction ou décision d'équipe. **⚠** non lu.
Le modèle Keynote officiel (79,9 Mo, `designasimpleapp-project.key`, téléchargé chez Apple à la demande de Titouan) a aussi été ouvert et son texte extrait. Il n'est pas versionné dans le dépôt. Les images, la vidéo et les consignes sous forme de dessins n'ont pas été regardées ⚠ ; seul le texte des diapositives a été lu.

## Les quatre étapes [F]

| # | Étape | Durée | Ce qu'Apple demande |
|---|---|---|---|
| 1 | Brainstorm et plan | 40 min | Dix idées en 10 min. Trois à cinq personnes choisissent leur préférée. Cinq prototypes rapides en 15 min sur gabarits vierges. Retour d'au moins trois personnes. Choix d'un design d'après les retours. |
| 2 | Prototype Keynote | 40 min | Une diapositive par écran ; liens entre diapositives ; présentation en mode « Links Only » pour que l'on ne navigue que par les liens ; animations (apparition, action, disparition) ; vérifier chaque chemin pour qu'il n'y ait aucune impasse. |
| 3 | Évaluer | 15 min | Montrer le prototype à au moins trois personnes. Elles remplissent le formulaire du modèle. Observer les signes de joie et d'incompréhension. |
| 4 | Promouvoir | 25 min | Étudier la page App Store de Swift Playground et répondre aux questions du modèle, puis remplir le gabarit de page produit. |

Consigne de fond (message des organisateurs) : un prototype « moche mais clair » qui montre le flux vaut mieux qu'un bel écran sans logique. Un retour au début coûte 5 minutes ; le même en plein build coûte 5 heures. Le crayon et le papier sont acceptés.

## Ce que contient le modèle Keynote [F]

- **Portée de l'app (notes du présentateur)** : une app petite, avec **une seule fonction principale**, réalisable en 40 minutes. Exemples donnés : une blague, un fait au hasard, trouver un ami pour une activité, une affirmation positive, un message gentil à un favori.
- **Vote** : trois à cinq personnes placent une étoile (petite, moyenne, grande) à côté de l'idée préférée.
- **Retours d'un testeur** : trois fiches identiques. Questions : note de 1 (le plus bas) à 5 sur l'expérience ; « mon app était-elle facile à utiliser ? » ; « qu'est-ce qui vous a plu ? » ; « quelles améliorations ? ».
- **Exemple de prototype** : une app d'affirmations avec trois boutons en haut ; un tap affiche une carte avec un texte ; une croix la ferme. Tout chemin ramène à l'écran de départ.
- **Fiche de retour par prototype rapide** : noter qui a préféré quel prototype et pourquoi (exemple : « la plus simple, elle savait quoi faire »).
- **Page produit (gabarit)** : titre de l'app, sous-titre, icône, catégorie, tranche d'âge, description, emplacements pour les captures. Questions préalables sur la page Swift Playground : quels mots de la description donnent envie d'utiliser l'app ; dans quelle catégorie elle est classée ; quelles données elle collecte.
- Le modèle est conçu pour iPad et adaptable au Mac. Le mode « liens seulement » supprime le tap n'importe où pour avancer.

## Ce que ça change pour Bredouille [I]

1. **Ce qu'on a déjà couvre l'étape 2.** Les maquettes HTML (`peche/maquettes/`) jouent le rôle de Keynote. Keynote demande un iPad ou un Mac, ce que Titouan n'a pas. Rien n'oblige l'équipe à le refaire : l'important est que le prototype soit cliquable et sans impasse. Il manque à nos maquettes les liens entre écrans. Un prototype HTML « liens seulement » (chaque bouton mène quelque part, l'écran « Aucune de ces espèces » inclus) est le livrable à produire.
2. **Le test d'impasse devient un contrôle.** `testeur-parcours` vérifie déjà les 8 parcours. Il ajoute : « suivre tous les chemins possibles ; aucune impasse ».
3. **Évaluation avec trois personnes (étape 3).** Reprendre les quatre questions d'Apple (note sur 5, facilité, ce qui a plu, améliorations) en ajoutant le nombre de taps. Les tester sur le parcours n°2 (2 taps jusqu'à la carte) : combien de taps, où elles hésitent, où elles sourient. À faire avec des pêcheurs si possible, pas avec des collègues du hackathon. Notes dans `docs/evaluations-prototype.md` (à créer).
4. **Page App Store (étape 4).** Elle recoupe `docs/store/` (pitch, captures, métadonnées). Le gabarit Apple tient en : titre, sous-titre, icône, catégorie, âge, description, captures, plus la question « quelles données sont collectées ». Vérifier que `docs/store/` répond à ces six champs.
5. **Portée.** Apple recommande une seule fonction principale. Le parcours n°2 (photo, un tap, carte) est notre fonction unique ; le reste (bestiaire, succès, carte, Pro) est une extension. À garder en tête pour les coupes de jeudi 15 h. Les dix idées en dix minutes sont sans objet : l'idée est tranchée, et les cinq directions artistiques (`directions.html`) tiennent lieu des cinq prototypes rapides.
6. **« Functional description ».** Les organisateurs appellent le brainstorm et plan le « functional description » attendu sur les projets. Notre `peche/00-DESCRIPTIF-APP-BREDOUILLE.md` en tient lieu ; à relire avec cette question en tête : quoi, pour qui, pourquoi (en une page).

## À faire [I]

- Rendre les maquettes HTML cliquables de bout en bout (parcours 1, 2, 4, 5, 9, 14) avec un mode de navigation par liens seulement. Propriétaire : Titouan (agent `designer-apple`).
- Trois essais utilisateur avant jeudi 9 h si possible, sinon vendredi matin (agent `testeur-parcours`).
- Garder le temps annoncé : la phase de prototypage officielle est proposée le jour J ; on arrive avec un prototype prêt pour passer plus vite à la construction.
