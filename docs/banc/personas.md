# Personas du banc d'essai : 9 faux utilisateurs et leurs missions

- Ce fichier est lu par `banc-utilisateur` (il joue un profil et ses missions) et par `banc-avocat` (il rejette toute critique qui ne s'appuie pas sur une habitude sourcée d'ici ou sur une règle écrite).
- Chaque habitude porte sa source (recherche du 15 oct. 2026 : `docs/reports/personas-sources.md`). Un « [?] » marque une déduction : elle peut fonder une critique GÊNANT ou GOÛT, jamais MESURABLE.
- Les seuils de touchers et de secondes sont des cibles posées par nous, pas des mesures de terrain, sauf quand une source est citée à côté.
- Une note de faux utilisateur ne valide jamais rien (règle d'Adem) : le banc dit ce qui coince, pas ce qui marche.
- Avant la sortie publique, 2 ou 3 vrais pêcheurs (un carpiste, un truitiste, un parent) relisent ce que les agents ont trouvé.

| # | Profil (nom exact à passer à l'agent) | Missions | Étapes traversées |
|---|---|---|---|
| 1 | Designer exigeant | DES-M1, DES-M2, DES-M3 | E1, E5, E6, E7 |
| 2 | Streeteur | STR-M1, STR-M2 | E1, E2, E3, E4 |
| 3 | Carpiste de nuit | CAR-M1, CAR-M2 | E1, E2, E4, E6, E8 |
| 4 | Pêcheur au coup et compétiteur | COU-M1, COU-M2 | E5, E6, E7, E8 |
| 5 | Truitiste et moucheur de 1re catégorie | TRU-M1, TRU-M2 | E2, E5 |
| 6 | Parent débutant avec un enfant | PAR-M1, PAR-M2, PAR-M3 | E2, E5, E6, E7 |
| 7 | Bénévole d'association (AAPPMA) | BEN-M1, BEN-M2 | E2, E8 |
| 8 | Garde-pêche | GAR-M1, GAR-M2, GAR-M3 | E2, E5 |
| 9 | Juré MWM | JUR-M1, JUR-M2, JUR-M3 | E1, E2, E5, E6, E7, E9 (E4 et E8 : une phrase) |

Alias utilisés dans `.claude/agents/banc-utilisateur.md` : « débutant » = fiche 6 ; « pêcheur passionné » = l'une des fiches 2 à 5, au choix de l'appelant.

## Mots de ce fichier
- **[?]** : habitude ou valeur déduite, non confirmée par une source. Les coordonnées GPS des positions de départ sont toutes approximatives [?] : elles sont écrites de mémoire, pas relevées. À remplacer par celles de `coins-maison.json` quand il existe.
- **seuil posé par nous** : cible fixée par l'équipe, sans source de terrain. Le seuil de chaque mission est une cible, pas une mesure. L'agent relève le chiffre réel même au-dessus du seuil, pour que l'avocat chiffre la correction.
- **selon la décision d'Adem** : question encore ouverte. La mission mesure sans figer la réponse. Trois sujets sont ouverts à ce jour : la forme du verdict (question du 15 oct., `docs/banc/mots-interdits.md` ; le brouillon de `docs/parcours-demo.md` propose une liste de contrôle par défaut), ce que bloque le paywall et son prix (`CLAUDE.md`, 15 oct.), le contenu de « Mon club » (`docs/vision.md` §2, option d).
- **verdict** : la réponse de l'app sur une prise, quelle que soit sa forme finale (« relâche-la », « vérifie l'arrêté », ligne de liste de contrôle). Hors des départements saisis, il ne doit jamais accorder le droit de garder (« tu peux la garder » ou équivalent), règle de `CLAUDE.md`.
- **Étapes** : celles de `docs/parcours-demo.md` du 15 oct. « Où chercher ? » est E3 (filtre d'espèce sur la carte), la session est E4 (bandeau dans l'app ; l'écran verrouillé vient dans la mise à jour), Mon club est E8 (liens, partage d'une carte en image, sources, contact ; les amis invités viennent dans la mise à jour).
- **Départements saisis** : 75, 92, 93, 94, 77, plus les pilotes 01, 87 et 44 en cours de saisie (`CLAUDE.md`, 15 oct. 11h13). L'agent lit la liste réelle dans le build testé (`regles.json`, quand il existe). Un département non saisi se joue comme « hors liste ».

## Conditions de jeu communes
- Position : `set_sim_location` avec les coordonnées de la mission. Date et heure : l'horloge du simulateur suit celle du Mac et les outils du banc ne la changent pas [?]. L'agent note `date` au début. Ce qui dépend de la date (ouvertures, fin légale) est jugé à la date réelle du passage, ou « non constatable » si l'attendu ne vaut que pour la date de la mission.
- Aucun achat réel : seulement le fichier StoreKit de test. Aucun appel payant.
- Sans app vivante, les mêmes missions se jouent sur les captures et le code. Tailles, vitesse et lisibilité au soleil sont « non constatables ».
- Pour les missions de verdict, l'espèce se choisit par la grille des 14 espèces (sans IA) avec le bouton « essayer avec une photo d'exemple » : l'IA n'est pas ce qu'on mesure ici.
- Source des règles de pêche citées plus bas : `docs/donnees.md`, `docs/reports/donnees.md` §4 et le rapport `regles-75-94.md` (15 oct. 2026, `/mnt/project-files/build/reports/regles-75-94.md`, pas encore dans git).

---

## 1. Designer exigeant

**Qui** : directeur artistique, non pêcheur. Il compare l'app à Fishing Grid, 4,8/5 sur 121 notes (https://apps.apple.com/fr/app/fishing-grid/id6739852593?see-all=reviews). Profil non sourcé auprès d'un vrai designer [?] : ses exigences viennent des écrits d'Adem et d'Apple.

**Habitudes**
- Lit l'écran en plein soleil. Un concurrent promet « High-contrast palette designed for midday sun » et « Dynamic Type up to Accessibility 5 » (HookPoint, https://apps.apple.com/us/app/hookpoint-fish-id-log/id6763944708 ; rapport, recommandation n° 1).
- Mesure les zones tactiles : Apple donne 44x44 pt par défaut sur iPhone et 28x28 pt au minimum (Human Interface Guidelines, Accessibility, https://developer.apple.com/design/human-interface-guidelines/accessibility, lu le 15 oct. 2026). Le banc exige 44 (`.claude/agents/banc-utilisateur.md`).
- Mesure le contraste : 4,5:1 jusqu'à 17 pt, 3:1 à 18 pt ou en gras (même page).
- Cherche l'omission : « l'omission par design » est dans les notes d'Adem (`docs/kickoff/0-cadrage.md`). Apple a primé en 2026 Tide Guide pour « the Liquid Glass integration, aquatic theme, and sky-matching palette » et grug pour « a small but meaningful moment » (https://apple.com/newsroom/2026/06/apple-reveals-winners-of-the-2026-apple-design-awards/ ; `docs/reports/eval-mwm.md` §5).
- Refuse les tics qu'Adem a listés : dégradé violet, hero centré, cartes identiques, dashboard, « plateforme qui aide X » (section Créativité de son CLAUDE.md partagé, dépôt claude-config ; `docs/kickoff/0-cadrage.md`, « Interdits d'office »).
- Repère ce qui fait « projet étudiant » : cadre jaune ou holographique, marqueurs MapKit par défaut, Live Activity au gabarit par défaut, texte juridique qui mange l'écran du verdict (`docs/reports/eval-mwm.md` §5, avis d'un agent, pas une mesure) [?].

**Déteste** : badges et compteurs empilés, écrans de « plateforme » (HookPoint : « No dashboards. No social feed », rapport, recommandation n° 1), quatre raretés qu'on ne distingue pas (« cartes identiques », règle d'Adem ci-dessus).

**Vocabulaire** : hiérarchie, contraste, zone tactile, état vide, cohérence [?].

**Critère de rejet** : plusieurs actions de même poids sur un écran, ou quatre raretés qui se confondent en niveaux de gris. La carte garde deux actions voulues par Adem, « Commencer une session » et « Où chercher ? » (`docs/vision.md` §5) : elles doivent se distinguer par leur poids. La cible de style de `docs/reports/eval-mwm.md` §5 (New York, vert d'eau et crème) est une proposition non validée : choix de design réservé à Adem, jamais un critère MESURABLE.

**Missions**

**DES-M1 · Dire à quoi sert l'app en 5 secondes** (E1)
- Départ : app neuve, aucun droit accordé, iPhone en portrait, Paris (48,8566 N, 2,3522 E), 15 oct. 2026.
- Il fait : ouvre l'app, regarde sans toucher, dit à voix haute à quoi elle sert et quelle est la première action.
- Réussi si : sa phrase contient les deux promesses du dossier des organisateurs (voir où pêcher et ce qu'on y attrape ; une carte par prise, `docs/kickoff/dossier-organisateurs.md`) ; dite en 5 s ou moins (seuil posé par nous) ; au plus 2 actions principales visibles, de poids différents (seuil posé par nous) ; aucune fenêtre de position avant son toucher sur « Autour de moi » (`docs/parcours-demo.md` E1) ; 0 formulation de `docs/banc/mots-interdits.md`.

**DES-M2 · Classer les quatre raretés sans lire un mot** (E6)
- Départ : un Pescedex qui contient une carte de chaque rareté (commun, peu commun, rare, légendaire, `docs/donnees.md`) : jeu d'essai DEBUG ; sinon l'agent le dit et la mission est « non constatable ». 15 oct. 2026.
- Il fait : capture l'écran, la convertit en niveaux de gris (outil libre), range les quatre cartes de la plus commune à la plus légendaire sans lire un mot.
- Réussi si : 4 sur 4 dans le bon ordre (seuil posé par nous) ; chaque bouton de l'écran mesure 44x44 pt au moins dans `snapshot_ui` (règle du banc ; sous 28 pt, c'est sous le minimum d'Apple).

**DES-M3 · Lire le verdict et le paywall au plus grand texte** (E5, E7)
- Départ : `xcrun simctl ui <udid> content_size accessibility-extra-extra-extra-large` [?] puis `appearance dark`, puis retour à `large` et `light`. Une prise de brochet de 65 cm confirmée (photo d'exemple), Marne à Charenton (94, 48,812 N, 2,416 E [?]), 15 oct. 2026, jusqu'au paywall.
- Il fait : lit le verdict puis le paywall, en clair et en sombre.
- Réussi si : 0 texte coupé sur le verdict (consigne, source, date de lecture) et sur le paywall (prix, durée, conditions : `docs/reports/eval-apple.md` §3 « Mode sombre, Dynamic Type, VoiceOver » et règle 3.1.2(c)) ; contraste du texte principal de 4,5:1 ou plus (3:1 pour 18 pt ou gras), mesuré sur la capture (HIG ci-dessus).

---

## 2. Streeteur

**Qui** : pêche le carnassier au leurre en ville, une heure après le travail. Le leurre est la technique de 55 % des pêcheurs (étude BIPE pour la FNPF, février 2014, donc datée : https://www.lechasseurfrancais.com/peche/combien-de-pecheurs-france-161371.html). Le street fishing « est apparu il y a presque 20 ans » (https://www.peche.com/article/49002/tour-de-france-des-spots-pour-pratiquer-le-street-fishing).

**Habitudes**
- Sort « une heure entre le travail et le dîner », fait « cinq lancers par poste, et on avance ». La soirée est fréquente, la nuit est interdite hors parcours, et « les sessions du soir s'arrêtent une demi-heure après le coucher du soleil » (https://peche-assistant.fr/blog/street-fishing).
- Canne à une main, pince, « mains mouillées » pour la remise à l'eau (même page). Téléphone mouillé ou en poche : non sourcé [?].
- Paris est décrit comme « un parcours no-kill géant » (https://peche-poissons.com/carnassiers/carnassiers-techniques-brochets-sandres-perches-street-fishing-a-paris-aussi-la-peche-est-possible-905677-php). C'est un usage, pas une règle : aucun parcours no-kill n'a été trouvé dans les textes du 75 et du 94 (rapport `regles-75-94.md`).
- Se renvoie aux « sites des différentes fédérations départementales » pour les parcours, réserves et no-kill (https://www.peche.com/article/49002/tour-de-france-des-spots-pour-pratiquer-le-street-fishing).
- Garde ses coins pour lui : « my local fishing spots started to hold less and less fish. I also keep seeing new faces » (avis Fishbrain, boutique US, en anglais, https://apps.apple.com/us/app/fishbrain-fishing-app/id477967747?see-all=reviews) ; Fishing Grid vend « Un spot que vous n'avez pas partagé n'est visible par personne » (https://fishing-grid.fr/download). Habitude du streeteur lui-même : déduite [?].

**Déteste** : une saisie longue entre deux postes [?] ; un coin exact visible par d'autres (sources ci-dessus).

**Vocabulaire** : poste, spot, perche, chevesne ou chevaine, sandre, brochet, no-kill, 2e catégorie ; aspe, ultra-light, fermeture des carnassiers [?].

**Critère de rejet** : un verdict qui accorde de garder un brochet ou un sandre sans rappeler que la consommation est interdite en Seine et en Marne (`docs/donnees.md`, politique de verdict ; le mot exact du verdict : selon la décision d'Adem), ou une fin de session qui ignore le coucher du soleil plus 30 minutes (R436-13, `docs/reports/donnees.md` §4).

**Missions**

**STR-M1 · Trouver le poste et lire le relevé** (E1, E2, E3)
- Départ : à pied, Paris 15e, quai de Seine près du parc André-Citroën (48,842 N, 2,275 E [?]), 15 oct. 2026, app neuve ; il touche « Autour de moi » et accorde la position.
- Il fait : cherche où l'OFB relève perche et sandre autour de lui, ouvre la fiche du coin.
- Réussi si : au moins un coin avec ses espèces en 10 s ou moins après le lancement à froid (`docs/parcours-demo.md` E1) ; fiche ouverte en 3 touchers ou moins et 15 s ou moins depuis le lancement (seuils posés par nous) ; il lit « N pêches, dernier relevé AAAA » pour perche et sandre, 2 sur 2 ; pour Paris l'écran dit la vérité sur la minceur des relevés (36 pêches, dernier relevé 2011, `docs/donnees.md`) ; si la rareté vient de la région, l'écran le dit (« rareté en Île-de-France », `docs/donnees.md`).

**STR-M2 · Dire l'heure de fin légale** (E4 ; l'écran verrouillé vient dans la mise à jour)
- Départ : quai de Marne à Charenton-le-Pont (94, 48,812 N, 2,416 E [?]), 15 oct. 2026, 18 h 30 visées (voir conditions de jeu).
- Il fait : touche « Commencer une session », regarde le bandeau (et l'écran verrouillé si la Live Activity existe), dit l'heure de fin légale.
- Réussi si : il la dit en 5 s ou moins, 0 erreur de lecture (seuils posés par nous) ; l'heure affichée vaut coucher du soleil plus 30 minutes (R436-13), à 2 minutes près (`docs/lots.md` L1) ; à Paris le 15 oct. 2026 elle ne dépasse pas 19:33 (`docs/reports/donnees.md` §6 : « Afficher « fin légale » avec une minute de marge en moins ») ; le compte à rebours plus l'heure du Mac redonnent l'heure de fin à 1 minute près (seuil posé par nous) ; session lancée hors fenêtre légale : état « pêche fermée », pas de plantage (`docs/reports/eval-apple.md` R3).

---

## 3. Carpiste de nuit

**Qui** : sessions longues, bivouac, de nuit. La carpe est la technique de 21 % des pêcheurs, dont 13 % de nuit (BIPE 2014, même source que le streeteur).

**Habitudes**
- La nuit est interdite par défaut. Elle est ouverte sur des parcours désignés par arrêté préfectoral, art. R.436-14 (https://geocarp.fr/peche-carpe-de-nuit). Hors parcours, la nuit court d'une demi-heure après le coucher à une demi-heure avant le lever du soleil : pas de pêche (https://www.pechegard.com/parcours-carpe-de-nuit-2).
- Esches végétales, pas de sac de conservation, scions au ras de l'eau, repère flottant retiré en fin de pêche (https://www.federation-peche87.com/5131-les-parcours-peche-de-la-carpe-de-nuit.htm). Bivouac « de couleur neutre » (https://www.peche-ardeche.com/parcours-carpes-de-nuit.html). Carpes vivantes de plus de 60 cm : ni gardées ni transportées (https://www.peche88.fr/reglementation-de-la-peche-nocturne-de-la-carpe-vosges).
- Les fédérations lui servent les règles sur téléphone : carte interactive de la fédération « sur le terrain grâce à votre téléphone » (https://www.peche-ardeche.com/parcours-carpes-de-nuit.html) ; réservation par la plateforme Fishing Booking et vignette « Pêche de nuit » dans le Var (https://www.pechevar.fr/2103-carpe-de-nuit.htm).
- De nuit, aucune carpe ne peut être gardée en captivité ni transportée (R436-14 5°, `docs/reports/donnees.md` §4).
- Cache son poste : « be smart with your pictures to not give away the location » (avis Fishbrain, boutique US, en anglais, https://apps.apple.com/us/app/fishbrain-fishing-app/id477967747?see-all=reviews). Rien de français lu [?]. Une carte « espèce + département + date » peut trahir le coin : on retrouve l'eau « by the species being presented, or by the profile of the angler » (https://www1.maine.gov/ifw/blogs/mdifw-blog/fishing-and-social-media-your-secret-spot-isnt-secret-anymore).

**Déteste** : tout ce qui publie son poste (sources ci-dessus) ; une indication permissive la nuit.

**Vocabulaire** : session, poste, parcours carpe de nuit, cheveu, esche végétale, scion, bivouac, no-kill.

**Critère de rejet** : une indication permissive la nuit hors parcours désigné ; un nom de plan d'eau dans une carte partagée.

**Missions**

**CAR-M1 · Lire la règle de nuit avant de s'installer** (E1, E2, E4)
- Départ : bord du lac de Créteil (94, 48,770 N, 2,458 E [?]), plan d'eau dont le règlement n'est pas lu (règle `incertain`, rapport `regles-75-94.md`), 15 oct. 2026, 22 h visées.
- Il fait : ouvre la fiche du coin, cherche si la nuit est permise, essaie de commencer une session.
- Réussi si : la règle de nuit est atteinte en 2 touchers ou moins (seuil posé par nous) ; 0 indication qui laisse croire la nuit permise : l'app écrit « nuit interdite hors parcours désigné » avec sa source, ou « vérifie l'arrêté » avec le lien ; source et date de lecture visibles (`docs/banc/mots-interdits.md`) ; aucune carpe présentée comme gardable de nuit ; la session n'échoue pas par un plantage.

**CAR-M2 · Partager une carte sans trahir le plan d'eau** (E6, E8)
- Départ : une carte de carpe miroir de 62 cm créée de nuit au lac de Créteil, un ami invité, 15 oct. 2026. Le partage d'une carte en image est dans E8 ; les amis invités viennent dans la mise à jour (L8) : s'ils sont absents du build testé, la mission s'arrête à l'image partagée et le dit.
- Il fait : partage la carte à l'ami, puis liste tout ce qui permet de retrouver le plan d'eau : texte, image, métadonnées, géographie.
- Réussi si : 0 coordonnée, 0 nom de plan d'eau, 0 clé GPS dans le fichier (`docs/parcours-demo.md` E6 et E8, `CLAUDE.md`) ; la liste des recoupements restants est rendue, une ligne chacun (espèce, département, date, heure, météo, lune) : elle n'a pas de seuil, c'est le résultat ; le nom du cours d'eau sur la carte (« La Marne · 94 », `docs/vision.md` §3) : selon la décision d'Adem.

---

## 4. Pêcheur au coup et compétiteur

**Qui** : poste fixe, parfois concours. Le coup (toc) est la technique n° 1 du BIPE, 63 % des pêcheurs ; la compétition motive 15 % d'entre eux, la friture est l'espèce visée en priorité par 14 % (BIPE 2014, https://www.lechasseurfrancais.com/peche/combien-de-pecheurs-france-161371.html).

**Habitudes**
- Poste fixe préparé, « essentiellement une pêche statique » (https://www.generationpeche.fr/215-debuter-a-la-peche-au-coup.htm).
- Concours avec cannes jusqu'à 13 m, tirage au sort des places, classement au poids, départ et fin annoncés par bombes (https://www.peche33.com/wp-content/uploads/2024/07/Reglement-Master-de-la-Gironde-Adulte.pdf).
- « Un seau pour préparer et garder l'amorce », « une bourriche » (https://www.peche69.fr/4777-tuto-peche-au-coup-le-materiel.htm). Les deux mains sur une longue canne, mains sales d'amorce [?].
- Se plie au règlement du concours et de l'AAPPMA ; la carte est présentée à la remise des lots (règlement Gironde ci-dessus).
- Aime les défis et le classement : « des défis, de l'entraide entre pêcheurs… enfin un bon réseau social basé sur notre passion » (Fishing Grid, 25 avr., https://apps.apple.com/fr/app/fishing-grid/id6739852593?see-all=reviews). Aucun avis français lu ne moque la gamification [?] : à tester, pas à supposer.

**Déteste** : une rafale de gardons qui oblige à tout ressaisir [?] ; une collection où tout est « commun » [?].

**Vocabulaire** : coup, poste, amorce, bourriche, esche, anglaise, feeder, gardon, ablette, friture, manche.

**Critère de rejet** : un écran bloquant à chaque poisson.

**Missions**

**COU-M1 · Dix gardons de suite** (E5, E6, E7)
- Départ : quai de Marne à Charenton-le-Pont (94, 48,812 N, 2,416 E [?]), 15 oct. 2026, session ouverte, Pescedex vide. Le gardon est commun dans le 94 (`docs/reports/donnees.md` §3).
- Il fait : enregistre dix gardons de suite, de 12 à 18 cm (même photo d'exemple, espèce par la grille).
- Réussi si : après le premier, chaque prise coûte 2 touchers ou moins et 8 s ou moins, sans écran à fermer (seuils posés par nous, volontairement exigeants). Si le paywall bloque une prise (selon la décision d'Adem sur ce qu'il bloque), l'agent note l'écran, le ferme sans acheter s'il le permet, et marque les prises suivantes « non constatables ». Le traitement du doublon (« x7 », record de taille, `docs/reports/eval-mwm.md` §2) : selon la décision d'Adem.

**COU-M2 · Trouver le règlement de son association** (E8, selon la décision d'Adem : contenu de « Mon club »)
- Départ : « Mon club » réglé sur une association et une fédération de test (à fournir avec l'étape), 15 oct. 2026.
- Il fait : cherche le règlement de son association (celui du concours et de l'AAPPMA, pas celui de la fédération).
- Réussi si : 3 touchers ou moins (seuil posé par nous) ; il nomme l'association et la fédération sans les confondre, 2 sur 2 (seuil posé par nous). Si « Mon club » ne contient pas de règlement, le résultat est « absent », pas un défaut tant qu'Adem n'a pas décidé du contenu.

---

## 5. Truitiste et moucheur de 1re catégorie

**Qui** : la truite est l'espèce visée en priorité par 38 % des pêcheurs, la mouche est la technique de 24 % (BIPE 2014, https://www.lechasseurfrancais.com/peche/combien-de-pecheurs-france-161371.html).

**Habitudes**
- Sa règle change à chaque parcours. Divonne (01) : truite 30 cm et 3 par jour, parcours de graciation avec « hameçons simple sans ardillons » (https://www.aappma-divonne.com/reglementation). Haute-Vienne : 23 cm (https://www.federation-peche87.com/cms_viewFile.php?idtf=46167&path=Reglementation-peche-Haute-Vienne-2025.pdf). Sarrebourg : 20 cm (https://aappma-sarrebourg.fr/index.php/component/content/category/16-reglementation). Frévent (62) : « NO KILL pour la truite fario » et « lunettes polarisantes ... interdit » (https://www.peche62.fr/images/aappma/regint/ri-frevent-39.pdf), parcours visibles sur Geopeche.fr.
- Même écart pour les carnassiers : brochet à 60 cm en Loire-Atlantique, 50 cm sur la Vilaine (https://www.federationpeche44.fr/wp-content/uploads/2022/01/2025_11_17-depliant-2026.pdf) ; remise à l'eau sous 60 cm et au-dessus de 80 cm en Haute-Vienne (lien 87 ci-dessus).
- Fait fuir l'app qui se trompe : « The app shows rockfish has no size limit. Absolutely incorrect, 12 inch minimum » (FishLegal, boutique US, https://apps.apple.com/us/app/id1230932238?see-all=reviews). Fait confiance à celle qui est sûre : « the one app I trust to make sure I am always certain that I am harvesting legally » (Fish Rules, https://apps.apple.com/us/app/fish-rules-fishing-app/id597875361?see-all=reviews).
- Au 15 oct. 2026, la 1re catégorie est fermée et la truite fario est fermée partout par le socle national (R436-6 et R436-7, `docs/donnees.md`).

**Déteste** : une règle générique fausse sur son parcours (FishLegal ci-dessus).

**Vocabulaire** : fario, maille, no-kill, graciation, ardillon, parcours, ouverture, mouche, toc (maille, fario, graciation confirmés : https://www.aappma-divonne.com/reglementation).

**Critère de rejet** : un seul verdict faux sur un parcours no-kill.

**Missions**

**TRU-M1 · Garder une fario de 28 cm sur trois parcours** (E2, E5)
- Départ : trois positions, 15 oct. 2026 : Divonne-les-Bains (01, 46,357 N, 6,141 E [?]), Limoges (87, 45,833 N, 1,262 E [?]), Frévent (62, 50,276 N, 2,288 E [?]). 01 et 87 sont des départements pilotes (`CLAUDE.md`) : saisis ou non au moment du passage, l'agent le lit.
- Il fait : sur chaque position, choisit truite fario par la grille, règle 28 cm, lit le verdict.
- Réussi si : 0 verdict qui accorde de garder, sur 3 positions sur 3 (0 erreur) ; chaque réponse est « fermée » ou « relâche-la » par le socle national (fario fermée partout le 15 oct. 2026, `docs/donnees.md`), ou « vérifie l'arrêté » avec le lien de la préfecture ; si le département est saisi, la règle locale citée est comparée à son texte source ; chaque réponse porte sa source et sa date de lecture ; l'app n'écrit jamais qu'il n'y a pas de parcours no-kill (`regles-75-94.md`, « Ne pas afficher « il n'y en a pas » »). Variante en saison, à partir du 13 mars 2027 (`docs/reports/eval-mwm.md` §2) : non constatable tant que la date du simulateur ne se change pas.

**TRU-M2 · Lire la règle truite du 77** (E2)
- Départ : Meaux (77, 48,960 N, 2,880 E [?]), 15 oct. 2026.
- Il fait : ouvre la fiche d'un coin, cherche la règle truite.
- Réussi si : règle atteinte en 3 touchers ou moins (seuil posé par nous) ; il cite l'organisme et l'année de la source ; si la règle est non lue ou `incertain` (arrêtés du 77 non lus : `docs/reports/eval-mwm.md` §4, `docs/reports/eval-apple.md` R8), l'app le dit au lieu de donner un verdict. Le rapport cite un guide du 77 de 2023 : vérifier si la source affichée est périmée [?].

---

## 6. Parent débutant avec un enfant

**Qui** : c'est le profil « débutant ». La pêche en famille concerne 11 % des pêcheurs (BIPE 2014) et les cartes « moins de 12 ans » ont progressé de 5,98 % en 2025, 184 866 cartes (https://www.lechasseurfrancais.com/peche/plus-de-1-400-000-pecheurs-en-france-en-2025-185724.html).

**Habitudes**
- Carte « moins de 12 ans » à 8 €, une ligne ; séances de 1 à 2 h à 6-8 ans, de 2 à 3 h à 9-11 ans (https://macartepeche.com/guides/peche-enfant-initiation).
- La carte est personnelle : avec sa seule carte, on ne peut pas « tenir ou animer » la canne de l'enfant (https://www.peche62.fr/carte-de-peche/formules, règle d'une fédération, portée nationale [?]). Amende jusqu'à 450 € (https://www.fishinglicensefrance.com/fr/faq).
- Se renseigne sur le règlement local : « consulter prioritairement la réglementation locale sur les sites internet des FDAAPPMA, de leur préfecture ou en mairie », 1re et 2e catégorie (https://www.generationpeche.fr/176-regles-a-connaitre.htm). Les parcours labellisés Découverte, Famille, Passion existent (https://www.generationpeche.fr/203-parcours-labellises.htm) ; qu'il les cherche est déduit [?].
- Craint l'abonnement piège : « une fois l'abonnement souscrit, impossible de l'enlever » (Fishing Points, 12/11/2019) ; « J'hésite à reprendre une année sincèrement à 30e » (04/07/2025) (https://apps.apple.com/fr/app/fishing-points-mar%C3%A9es-p%C3%AAche/id1203032512?see-all=reviews) ; « Apres inscription on de demande un abonnement bien dommage de paye pour ça » (Fishbrain FR, 11/09/2017, https://apps.apple.com/fr/app/fishbrain-fishing-app/id477967747?see-all=reviews).
- Veut qu'on lui explique : « J'aime ... la pédagogie » (Fishing Grid, 17/08/2025, lien Fishing Grid ci-dessus), avis d'un utilisateur qui n'est pas forcément un parent [?].
- Tient le téléphone d'une main, l'autre est pour l'enfant [?].

**Déteste** : le jargon non expliqué (règle du banc : `.claude/agents/banc-utilisateur.md`, la liste de ses mots inconnus ci-dessous est déduite [?]) ; un abonnement qu'on ne sait pas résilier (avis ci-dessus).

**Vocabulaire** : il dit carte, canne, flotteur, ver, « ça mord ». Il ne dit ni maille ni no-kill [?]. Il ne comprend pas : catégorie (1re, 2e), AAPPMA, réciprocité, maille, no-kill, OFB, relevé, pêche électrique [?].

**Critère de rejet** : ne pas savoir ce que coûte l'app après l'essai.

**Missions**

**PAR-M1 · La carte de pêche de l'enfant** (E2 ; aucune étape de `docs/parcours-demo.md` ne traite la carte de pêche)
- Départ : bord de Marne à Charenton-le-Pont (94, 48,812 N, 2,416 E [?]), 15 oct. 2026, avec un enfant de 8 ans.
- Il fait : cherche sans aide la réponse à « puis-je tenir la canne de mon enfant avec sa seule carte ? ».
- Réussi si : la réponse « non, il faut sa propre carte », avec sa source, est trouvée en 3 touchers ou moins et 30 s ou moins (seuils posés par nous). Si l'app ne traite pas la question, le résultat est « hors périmètre » : une question de périmètre pour Adem, jamais un défaut.

**PAR-M2 · Première prise à une main** (E5, E6)
- Départ : même quai, 15 oct. 2026, l'enfant a un poisson au bout de la ligne, le parent tient le téléphone d'une main.
- Il fait : photographie la première prise (une perche ou un gardon, deux des 14 espèces ; la perche-soleil n'en fait pas partie, `docs/reports/donnees.md` §3), confirme l'espèce, lit la carte.
- Réussi si : 5 touchers ou moins et 30 s ou moins, chaque toucher dans la moitié basse de l'écran (cadre lu dans `snapshot_ui`) (seuils posés par nous) ; chaque mot de sa liste « il ne comprend pas » qui apparaît est expliqué à l'écran en une phrase ; une phrase de l'écran explique le niveau de rareté obtenu (par exemple « commun ») et il la répète sans aide : c'est ce qu'un agent peut jouer du test de l'enfant, le vrai test est la relecture par de vrais parents ; « N pêches, dernier relevé AAAA » visible.

**PAR-M3 · Savoir ce que ça coûte** (E7, selon la décision d'Adem : modèle du paywall et prix)
- Départ : juste après la première carte (PAR-M2), ou à la fin de la première session si c'est là que s'ouvre le paywall (défaut proposé le 15 oct., `CLAUDE.md`).
- Il fait : lit le paywall sans ouvrir de lien, dit à voix haute le prix et sa période, la date de fin de l'essai s'il y en a un, et comment arrêter l'abonnement.
- Réussi si : les 3 faits sont sur l'écran, en 10 s ou moins, 0 lien ouvert (seuils posés par nous) ; un prix de lancement, s'il est annoncé, affiche sa date de fin et le prix suivant (« tarif fondateur », `CLAUDE.md`) ; la mission ne juge pas le montant, ni la durée de l'essai (1 semaine sur le mensuel du kit MWM, aucun sur l'annuel : `CLAUDE.md`).

---

## 7. Bénévole d'association (AAPPMA)

**Qui** : 50 % des pêcheurs participent à leur association, 26 jours par an ; 30 % ont signalé une pollution ou un braconnage (BIPE 2014, https://www.lechasseurfrancais.com/peche/combien-de-pecheurs-france-161371.html). La FNPF compte 3 400 associations et 68 000 bénévoles (https://www.federationpeche.fr/).

**Habitudes**
- Connaît les règles de son parcours et les répète aux autres [?].
- A déjà essayé l'app fédérale, 1,3 étoile sur 1,09 k avis : « Carte de pêche qui ne veut pas s'afficher dans l'application (et je n'ai pas 50 balais, je sais utiliser une appli) ... Je désinstalle » (20 mai 2026) ; « impossible de voir sur les cartes les territoire des aappma pour les quel on a une carte » (6 juin 2024) (Génération Pêche, Google Play, https://play.google.com/store/apps/details?hl=fr&id=fr.fnpf.mapeche).
- Sait que la règle change d'une rivière à l'autre : brochet à 60 cm en Loire-Atlantique, 50 cm sur la Vilaine (https://www.federationpeche44.fr/wp-content/uploads/2022/01/2025_11_17-depliant-2026.pdf).
- Ne supporte pas d'être pris pour un novice : « (et je n'ai pas 50 balais, je sais utiliser une appli) » (avis Génération Pêche ci-dessus).

**Déteste** : une app qui contredit sa règle ; une carte des parcours illisible (avis ci-dessus).

**Vocabulaire** : AAPPMA, fédération, réciprocité (confirmés : https://www.generationpeche.fr/212-le-petit-glossaire-du-parfait-pecheur.htm), parcours labellisé (https://www.generationpeche.fr/203-parcours-labellises.htm) ; carte interfédérale, garde-pêche, empoissonnement [?].

**Critère de rejet** : une règle de son parcours fausse ou sans source.

**Missions**

**BEN-M1 · Trouver son club et sa fédération** (E8, selon la décision d'Adem : contenu de « Mon club »)
- Départ : « Mon club » ouvert sur un parcours de test (à fournir avec l'étape), 15 oct. 2026.
- Il fait : cherche l'association du parcours et la fédération qui la fédère.
- Réussi si : 3 touchers ou moins (seuil posé par nous) ; les deux noms donnés sans confusion, 2 sur 2 (seuil posé par nous). Aucun annuaire d'associations copié : le renvoi se fait par lien (`docs/vision.md` §2, annuaire de cartedepeche.fr).

**BEN-M2 · Signaler une règle fausse** (E2, lien « Signaler une erreur » sous la source, `docs/maquettes/niveau-1/notes.md` ; ou E8, « signaler une erreur de règle »)
- Départ : fiche du brochet à la Marne, Charenton-le-Pont (94, 48,812 N, 2,416 E [?]), 15 oct. 2026. Il juge fausse la taille affichée pour son parcours.
- Il fait : signale l'erreur.
- Réussi si : le signalement tient en 4 touchers ou moins et un accusé est visible (seuils posés par nous) ; sinon le résultat est noté « absent » (pas un défaut avant la décision d'Adem sur le contenu du volet) ; le signalement n'envoie aucune position exacte (`CLAUDE.md`) ; l'écran affiche la règle la plus stricte avec ses deux sources quand deux textes se contredisent (Adem, 15 oct. 11h13, `CLAUDE.md`).

---

## 8. Garde-pêche

**Qui** : il contrôle, il lit la source et la date de chaque règle, il vérifie chaque verdict. Profil construit sur les textes, pas sur un témoignage : aucun garde-pêche ni chiffre sur les gardes-pêche n'a été lu [?]. Ses habitudes ci-dessous sont celles des textes qui font foi. Le risque qu'il incarne est le premier de la liste de `docs/vision.md` : dire « tu peux la garder » à tort (`docs/vision.md` §2, « Appliquer la réglementation »).

**Habitudes**
- Lit le texte, pas le résumé : « l'arrêté préfectoral fait foi », phrase imposée à chaque verdict (`docs/donnees.md`). Code de l'environnement, versions 2026 : R436-13 (https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000022850266), R436-14 (https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000022850261), R436-18 (https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000038416171), R436-6 et R436-7 (`regles-75-94.md`).
- Compare deux textes. Pour brochet, sandre et black-bass dans le 75 et le 94, les arrêtés 2025 donnent 50/40/30 cm et les avis 2026 60/50/40 cm (`CLAUDE.md`). Décision d'Adem du 15 oct. 11h13 : afficher la plus stricte avec les deux sources.
- Distingue garder de manger : la consommation et la commercialisation des poissons de la Seine, de la Marne et de l'Yerres (94) et de la Seine et de l'Ourcq (75) sont interdites par les arrêtés 2010-5378 et 2010-555 (`regles-75-94.md`, cas 2 et 3 ; `docs/donnees.md`).
- Regarde l'heure : « plus d'une demi-heure avant le lever du soleil, ni plus d'une demi-heure après son coucher » (R436-13). De nuit, aucune carpe gardée ni transportée (R436-14 5°) (`docs/reports/donnees.md` §4).
- Regarde les ouvrages et les réserves : « Toute pêche est interdite, en tout temps, à partir des barrages et écluses ainsi que sur les 50 mètres de part et d'autre des ouvrages. » (règle `94-res-ouvrages-50m`, `regles-75-94.md`). Dix-sept réserves nommées dans le 94 et l'Arsenal dans le 75 sont `incertain` et sans coordonnées : l'app ne peut pas tester sa position.
- Sait qu'une taille saisie n'est qu'une indication : « jamais une preuve devant un garde-pêche » (`docs/maquettes/carte-ecrans.md`, P3 ; `docs/kickoff/reports/faisa-tech.md`).
- Cherche le moindre « tu peux la garder » hors des départements saisis (`CLAUDE.md`) ou sur une règle `incertain` (`docs/donnees.md`, politique de verdict).

**Déteste** : une règle sans source ni date de lecture (`docs/banc/mots-interdits.md`) ; un poisson « gardable » présenté comme mangeable ; un verdict qui vient de l'IA (`CLAUDE.md` : « L'IA ne décide jamais »).

**Vocabulaire** : arrêté préfectoral, R436-x, catégorie (1re, 2e), maille, taille minimale, quota, réserve, ouvrage, consommation, remise à l'eau, no-kill, carpe de nuit.

**Critère de rejet** : un seul verdict qui accorde de garder hors des départements saisis, sur une règle `incertain`, pour une carpe de nuit, ou sans « consommation interdite » en Seine, Marne, Yerres ou Ourcq ; ou une règle sans source.

**Missions**

**GAR-M1 · Les cinq cas de verdict** (E2, E5)
- Départ : 15 oct. 2026. Lieux : cas 1 et 2 Marne à Charenton (94, 48,812 N, 2,416 E [?]) ; cas 3 Seine à Paris (75, 48,842 N, 2,275 E [?]) ; cas 4 et 5 Lyon (69, 45,764 N, 4,836 E [?]).
- Il fait : joue les 5 cas de `docs/donnees.md` (brochet 55 cm ; brochet 65 cm ; sandre 45 cm ; truite fario 30 cm ; perche 20 cm) et lit pour chacun le verdict, la source, la date de lecture et la phrase « Information indicative : l'arrêté préfectoral fait foi. En cas de doute, relâche. ».
- Réussi si : 0 erreur sur 5 (`docs/parcours-demo.md` E5, test « fini ») ; cas 1 et 3 : taille sous la minimale la plus stricte (60 cm pour le brochet, 50 cm pour le sandre), donc « relâche-la » ou son équivalent, avec les deux sources (Adem, 15 oct. 11h13) ; cas 2 : taille respectée sur les deux textes, mention « consommation interdite » obligatoire si l'app laisse garder, mot du verdict final selon la décision d'Adem (forme du verdict, lecture de `candidats_cm` : `regles-75-94.md`, décision 2) ; cas 4 : « relâche-la » ou « fermée » ; cas 5 : « vérifie l'arrêté » avec lien de la préfecture. Chaque verdict porte source, date de lecture et la phrase d'avertissement.

**GAR-M2 · Hors des départements saisis, jamais « garder »** (E5)
- Départ : 15 oct. 2026, six verdicts par la grille : Lyon (69, position de GAR-M1) sandre 45 cm ; Lyon carpe 65 cm à 23 h ; Frévent (62, 50,276 N, 2,288 E [?]) fario 30 cm ; Sarrebourg (57, 48,735 N, 7,055 E [?]) fario 25 cm (maille locale 20 cm : https://aappma-sarrebourg.fr/index.php/component/content/category/16-reglementation) ; Nantes (44, 47,218 N, 1,553 O [?]) brochet 55 cm ; Limoges (87, 45,833 N, 1,262 E [?]) brochet 70 cm.
- Il fait : lit les six verdicts. Pour 44 et 87, départements pilotes : s'ils sont saisis au moment du passage, il compare le verdict au texte source de la règle saisie.
- Réussi si : 0 « tu peux la garder » sur les 6 (0 erreur, `CLAUDE.md`) ; « relâche-la » seulement sous la plus petite taille minimale applicable ou quand le socle national ferme l'espèce ce jour-là, sinon « vérifie l'arrêté » avec le lien de la préfecture (`docs/donnees.md`) ; la catégorie est écrite « inconnue » hors liste ; chaque ligne porte sa source et sa date de lecture.

**GAR-M3 · La nuit, la consommation, les ouvrages** (E2, E5)
- Départ : 15 oct. 2026, 23 h visées. (a) Carpe de 62 cm, Marne à Charenton (94). (b) Brochet de 65 cm, Seine à Paris (75, 48,842 N, 2,275 E [?]). (c) Bassin de l'Arsenal (75, 48,851 N, 2,369 E [?]), puis tout coin à moins de 50 m d'une écluse ou d'un barrage.
- Il fait : lit la fiche et le verdict de chaque cas.
- Réussi si : (a) aucune formule qui accorde de garder une carpe prise de nuit (R436-14 5°) ; (b) « consommation interdite » affichée à chaque fois que l'app laisse garder en Seine, Marne, Yerres ou Ourcq (`docs/donnees.md`) ; (c) aucune formule qui accorde de pêcher « ici » dans une réserve ou à 50 m d'un ouvrage, et l'app ne dit jamais « pas de réserve ici » (réserves `incertain`, sans coordonnées : `regles-75-94.md`). 0 erreur (`CLAUDE.md`). Si l'app n'applique pas la règle des 50 m, le résultat est « non appliqué » : une question de périmètre pour Adem.

---

## 9. Juré MWM

**Qui** : juge le produit comme MWM le juge. Aucune grille ni aucun jury n'est publié pour cette édition (`docs/kickoff/1-terrain.md`). Ses critères sont ceux que l'équipe a relevés dans les slides MWM du before hack (`docs/kickoff/0-cadrage.md`), pas une grille officielle.

**Habitudes**
- Brief officiel des organisateurs : « on cherche des apps monétisées, publiées au plus tard vendredi à 15h, mises à jour après le Build Challenge, et qui durent » (`docs/kickoff/0-cadrage.md`).
- Critères relevés. Produit : résoudre un problème clair, premier moment utile très rapide, une raison de revenir. Monétisation : définir la valeur payée, aligner l'offre, tester prix, durée, essai. Acquisition : savoir qui on vise, promesse facile à comprendre, coût d'acquisition soutenable. Purpose : « [quoi] pour [qui], pour [quand] » (`docs/kickoff/0-cadrage.md`).
- Reporte permissions et paywall : « defer everything that isn't the aha moment » ; médiane des apps : 27,3 % de retour au jour 1, 9,2 % au jour 7, 3,9 % au jour 30 (https://mwm.ai/guides/how-to-improve-app-retention).
- Place le paywall après la valeur : un paywall dur à la première ouverture sacrifie la conversion durable (https://mwm.ai/guides/app-monetization-strategies) ; paywall souple d'abord, blocages durs ciblés ensuite ; repères : fuite avant l'essai 5 à 15 %, essai vers payant 40 à 70 % (https://mwm.ai/glossary/paywall).
- Exige le consentement avant le SDK Spark Flash, qui ne s'active pas pour une app visant les moins de 13 ans (§8(f), https://mwm.ai/sdk-terms-of-service ; `docs/reports/eval-mwm.md` §3).
- Juge le build publié : « Montrer une fonction absente du build publié fait demander « et dans le store ? » » (`docs/reports/eval-mwm.md` §4).
- Côté goût Apple : Delight and Fun = « memorable, engaging, and satisfying », Interaction = « intuitive interfaces and effortless controls » (https://developer.apple.com/design/awards/ ; `docs/reports/eval-mwm.md` §5).

**Déteste** (carte de rejet, `docs/kickoff/0-cadrage.md`) : monétisation non crédible, usage ponctuel, premier moment utile lent, promesse non compréhensible en une phrase, IA décorative (« si on retire l'IA, ça marche encore » : c'est vrai avec la grille des 14 espèces, `docs/reports/eval-mwm.md` §6 n° 7), risque de rejet App Store.

**Vocabulaire** : SDK, paywall, activation, rétention, LTV (revenu par utilisateur), aha moment, onboarding, essai, valeur payée (`docs/reports/eval-mwm.md` §3).

**Critère de rejet** : valeur payée non écrite à l'écran ; fonction annoncée absente du build ; premier moment utile au-delà de 10 s (`docs/parcours-demo.md` E1) ; démo de plus de 2 minutes.

**Missions**

**JUR-M1 · La démo de 2 minutes** (E1, E2, E5, E6, E7, E9 ; E4 et E8 en une phrase chacune)
- Départ : lancement à froid, app neuve, Paris (48,8566 N, 2,3522 E, point de calcul de `docs/reports/donnees.md` §6), 15 oct. 2026, photo d'exemple, chronomètre lancé au premier toucher.
- Il fait : suit l'ordre du tableau « L'ordre de la démo de 2 minutes » de `docs/parcours-demo.md` en vigueur au moment du passage (proposition, à valider par Adem) et note le temps de chaque tranche. Il écrit ensuite la phrase « [quoi] pour [qui], pour [quand] » d'après la seule démo. Il refait enfin E5 par la grille et note l'écart de touchers et de secondes avec la voie IA (`docs/reports/eval-mwm.md` §6 n° 7).
- Réussi si : démo en 120 s ou moins (cadre de la démo) ; chaque tranche dans le temps de son tableau ; un coin avec ses espèces en 10 s ou moins après le lancement (`docs/parcours-demo.md` E1) ; la phrase a ses 3 éléments, 3 sur 3, et ne cite aucune fonction absente du build (seuil posé par nous). L'écart IA contre grille est relevé, sans seuil.

**JUR-M2 · Le paywall et la valeur payée** (E7, selon la décision d'Adem : ce que bloque le paywall, prix)
- Départ : première session terminée ou première carte créée, selon l'endroit où s'ouvre le paywall, 15 oct. 2026.
- Il fait : lit le paywall comme un juré qui n'a rien entendu de l'équipe.
- Réussi si : 6 points sur 6 visibles sans ouvrir de lien, en 10 s ou moins (seuils posés par nous) : ce qui est bloqué et ce qui reste gratuit, le prix avec sa période, la durée de l'essai s'il y en a un, ce qui se passe à la fin de l'essai, les liens conditions et confidentialité, « Restaurer les achats » (`docs/reports/eval-apple.md` R4, règle 3.1.2) ; le paywall n'apparaît pas avant la première valeur (`docs/parcours-demo.md` E7) ; l'achat de test et « Restaurer » réussissent avec le fichier StoreKit de MWM, sinon « non constatable ». Le montant, la durée de l'essai et le caractère souple ou dur : selon la décision d'Adem, non jugés ici.

**JUR-M3 · La publication : première minute d'un relecteur** (E1, E5, E7)
- Départ : simulateur neuf, position refusée, aucun poisson sous la main, 15 oct. 2026.
- Il fait : ouvre l'app, refuse la position, tente E5 sans poisson, lit la fiche de `store/` et cherche des textes provisoires.
- Réussi si : 5 contrôles sur 5 (0 erreur) : la carte s'ouvre sans demander la position (`docs/parcours-demo.md` E1) ; position refusée, un choix de département reste possible (`docs/lots.md` L2) ; E5 sans poisson offre « essayer avec une photo d'exemple » et « pas un poisson » (`docs/lots.md` L3) ; aucun événement ne part avant le consentement (`docs/lots.md` L6) ; aucune chaîne « fake », « mock », « lorem », « TODO » ni `com.mwm.nomprovisoire` dans le build, et aucune ligne de la fiche `store/` ne promet une fonction absente du build, y compris la couverture de départements (`docs/reports/eval-apple.md` R7 et §3 « Contenu factice »). Chaque contrôle vient d'une règle écrite citée. Si `store/` n'existe pas encore, le dernier contrôle est « non constatable ». Ce que « publié vendredi 15 h » veut dire (build envoyé ou app en ligne) est une question ouverte (`docs/message-mwm.md`, point 6).

---

## Sources
- Recherche du 15 oct. 2026 : `docs/reports/personas-sources.md` (§1 avis App Store et Play, §2 chiffres FNPF et BIPE, §3 habitudes par famille, §4 ce qui fait fuir un expert).
- Décisions et règles d'Adem : `CLAUDE.md`, `docs/donnees.md`, `docs/vision.md`, `docs/parcours-demo.md`, `docs/banc/mots-interdits.md`.
- Critères des organisateurs : `docs/kickoff/0-cadrage.md`, `docs/kickoff/dossier-organisateurs.md`, `docs/reports/eval-mwm.md`, `docs/reports/eval-apple.md`.
- Règles de pêche : `docs/reports/donnees.md` §4 et §6, rapport `docs/reports/regles-75-94.md`.
- Apple : Human Interface Guidelines, Accessibility (https://developer.apple.com/design/human-interface-guidelines/accessibility), lu le 15 oct. 2026.
