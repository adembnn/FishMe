# Sullyvan : ton plan, d'abord sans compiler
Écrit le 19 oct. 2026 d'après le dépôt. Une case = une action. Rien n'est envoyé à personne sans le oui d'Adem. Si un fichier cité manque : « à demander à Adem ».

## 1. Sans compiler, par ordre d'utilité
**A. Textes juridiques (S2)** : branche `lot/store-2`, dossier `C:\w\s2\docs\legal\`. Ce sont des brouillons, aucun n'est envoyé.
- [ ] Lire `conditions-fishme.md` (CGU) et `politique-confidentialite.md` : les lignes marquées ⚠ en haut disent ce qui est incertain.
- [ ] Copier cette liste pour le **juriste de MWM** (brouillon, ne rien envoyer) :
  1. Âge de 15 ans, case « j'ai 15 ans ou plus » : est-ce valable en France ?
  2. Le retrait sous 24 h (art. 10) tient-il si l'équipe est de 3 personnes qui lisent une boîte mail ?
  3. Combien de temps garder les signalements et le texte d'un message signalé ?
  4. Droits des personnes, CNIL, transferts hors UE : quelles phrases exactes ?
  5. Aucun article de loi n'est cité : lesquels ajouter (dont l'art. 12, garantie) ?
  6. Peut-on dire « nous signalons à Apple si la loi l'impose » (art. 17) ?
  7. Un message privé signalé est copié dans l'enregistrement « Signalement » : est-ce permis ?
  8. Qui est l'éditeur et le médiateur à écrire dans les crochets [...] ?
- [ ] Copier cette liste pour **MWM** (`store/confidentialite-spark-flash.md`, §4, 11 questions ; les plus utiles) :
  1. Liste écrite de ce que collecte Spark Flash, et quand ?
  2. Le SDK a-t-il son propre fichier de confidentialité à jour ?
  3. Identifiant d'appareil et d'utilisateur : « liés » ou « non liés » à la personne ?
  4. Le SDK ne fait-il rien avant son initialisation (aucune requête réseau) ?
  5. Avis sur l'âge minimal pour une app de pêche tout public ?
  6. Vendeur légal, adresse de contact, nom du copyright ?
  7. Quota de générations (icône, captures) de l'équipe ?
  8. Notre tableau de revenus dépend-il de Spark ou des données d'Apple (note `store/note-mwm-mesure.md`) ?
  9. Quel rôle nous donner dans CloudKit pour le tableau de bord (notes du relecteur) ?
- [ ] Donner les deux listes à Adem, qui décide qui les envoie.

**B. Tri des photos douteuses (R1)**
- [ ] `outils/reconnaissance/` n'existe pas dans le dépôt : **à demander à Adem ou Titouan** (branche `lot/reconnaissance`).
- [ ] Ce que dit la fiche `docs/fiches/R1.md` : tu reçois des planches de 50 vignettes (`planche.py`) dans ton navigateur ; tu coches ; tu exportes les coches.
- [ ] Tu vois les photos « à revoir » et 10 % des « ok auto ». Si plus de 3 % sont fausses dans une classe, revoir toute la classe.
- [ ] Pour le jeu de test : relire chaque photo (bonne espèce, bon type) ; les 300 boîtes autour du poisson sont tracées à la main.
- [ ] Ne rien mettre dans git ni dans un dossier partagé : les photos restent hors du dépôt.

**C. Recalage des stations (D5)** : branche `lot/hubeau-d5`, dossier `C:\w\d5`.
- [ ] Prérequis : `python3 --version` et `gh auth status` répondent.
- [ ] Essai court : `python3 outils/hubeau/recalage.py stations-especes-brut.json stations-especes.json --departement 94 80` (fichier brut à demander à Titouan).
- [ ] Tout refaire : `outils/hubeau/lancer.sh`. Durée : les appels Hub'Eau ont pris environ 1 h 50 dans le cloud, le tracé des cours d'eau quelques dizaines de minutes de plus. Si ça coupe, relancer la même commande (le cache reprend).
- [ ] À la question « envoyer ? », répondre non et attendre Adem (n'utilise pas `--publier`).
- [ ] Coller à Titouan : la sortie complète du script, dont la ligne du contrôle D5, plus `python3 -m unittest discover -s outils/hubeau/tests`. Succès attendu : 90 % des stations ou plus à `recalee: true`.

**D. Fiche App Store**
- [ ] Lire `C:\w\s2\store\fiche-reseau.md` et `notes-relecteur-reseau-en.md` : ton, fautes, phrases qui promettent trop.
- [ ] Noter chaque correction avec le numéro de ligne. Les textes entre crochets ou marqués [?] : ne pas les remplir, ils se lisent dans le build.
- [ ] Rappel : « Une fonction absente du build ne s'écrit pas » (refus Apple probable).

**E. Marché**
- [ ] Lire `reports/marche/synthese.md` (7 décisions : positionnement, gratuit ou abonnement, fil social, fonctions, 3 canaux, pays suivant, veille).
- [ ] Pour chacune, écrire ton avis en une ligne : d'accord, pas d'accord, ou pourquoi. Donner à Adem, qui tranche.

## 2. Ce qui demande ton Mac
- [ ] Compiler et tester les branches de Titouan, une à la fois : `lot/collection-2` (L18), `lot/prise-2` (L19), `lot/profil` (L21), `lot/feed` (L23), `lot/chat` (L24). Ordre conseillé : le profil avant le feed et le chat ; le reste, à demander à Titouan.
- [ ] Pour chaque branche : lancer `scripts/verif.sh`, ouvrir sur l'iPhone, prendre les captures dans `reports/ecrans/<lot>/`, envoyer à Titouan un retour de 3 lignes.
- [ ] Rappels de `docs/compiler-sur-mac.md` (écrit le 15 oct., ancien) : lier le paquet local `Packages/Core`, un lot à la fois, coller `BUILD SUCCEEDED`. En cas d'erreur Swift 6 de type « MainActor », noter l'erreur et la donner à Titouan.
- [ ] Prototype CloudKit (R2) : suivre `C:\w\r2\outils\reseau\README.md` (environ 2 h, 0 €). Conteneur d'essai à toi, jamais Production. Coller les sorties dans `RESULTATS.md`, rien calculé à la main, puis les donner à Titouan.
- [ ] Mesure d'ouverture (L20) : voir `docs/fiches/L20.md` (Instruments sur l'iPhone, 10 lancements, avant puis après).

## 3. Ce que tu ne fais pas
- Ne pas pousser sur `main`.
- Ne pas modifier `App/RootView.swift` (c'est Adem, lot L25 : écris-lui ce qu'il faut changer).
- Ne pas envoyer de message à MWM, au juriste ou aux organisateurs sans le oui d'Adem.
- Ne jamais coller le mot de passe du kit MWM dans git ou un message.
- Ne pas publier de page ni de fiche (`publish_*`, `send_store_listing`) sans le oui d'Adem.
