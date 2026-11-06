Décision débloquée : quelles règles des Pyrénées-Orientales (66) l'app peut afficher en 2026, ligne par ligne, avec leur source (lecteur A).

Textes (corpus/66, manifeste)
- Règlement permanent DDTM/SER/2025346-0001, signé le 2025-12-12 : lu en entier (couche texte). https://www.pyrenees-orientales.gouv.fr/contenu/telechargement/48045/366451/file/2025346-0001.pdf
- Arrêté annuel 2026 DDTM/SER/2025350-0001, signé le 2025-12-16 : lu en entier, annexes III et IV et Soler relues sur l'image des pages 16, 21, 22, 23 (OCR illisible pour l'annexe IV). https://www.peche66.org/sites/default/files/deversements/arreteprefectoralannuel.pdf
- Carte des catégories piscicoles (2023, sans signature) : titre seul, aucune règle.
- Dépliant fédération 2026 : lu en partie, jamais source de règle.

Règles : 329 (325 brouillon, 4 incertain). Par type : reserve 74, interdit 50, mode_peche 48, ouverture 36, no_kill 28, taille_min 26, categorie 18, quota_jour 12, transport_vivant 12, carpe_nuit 10, autre 9, limite_eau_douce 4, remise_eau 1, horaire 1.
Découpe : un parcours no-kill = une règle no_kill + une règle mode_peche (28 parcours) ; un lac nommé = une règle d'appâts naturels ; une ligne de l'annexe IV = une réserve (43) ; carpe de nuit = 10 lieux.

Contradictions
- Brochet, vif et leurres : permanent art. 10 e dit du dernier dimanche de janvier au dernier samedi d'avril (25/01 au 25/04) ; l'annuel art. 7 dit du 26/01 au 24/04. Deux règles, la permanente en incertain. L'annuel devrait primer (plus précis, 2026, cohérent avec l'ouverture du brochet).
- Brochet taille 60 cm : permanent « 2e catégorie », annuel « toutes eaux ». Deux règles, même chiffre.
- Anguille : taille 12 cm (permanent) mais pêche interdite toute l'année (annuel). Les deux sont écrites ; l'interdiction prime.

Ce qui manque ou reste flou
- « Carnassiers » (3 par jour) : le texte ne liste pas les espèces ; j'ai mis brochet, sandre, perche, black-bass, en incertain.
- Réserve du lac de Matemale pour l'Aude : la mention « jusqu'à la date d'ouverture des lacs de montagne » a une portée peu claire (incertain). Réserve à frayères de l'Agly : début déduit (25/04), incertain.
- Annexe I (liste des lacs, OCR bruité) non transformée en règles lac par lac ; une règle générale pour les lacs de plus de 1000 m.
- Fédération seule (non reprise) : black-bass en no-kill et fermeture du 6 avril au 12 juin sur 4 plans d'eau, lac d'Osséja ouvert toute l'année, 1 ligne par pêcheur : à chercher dans un texte signé.
- Dates de l'ouverture des lacs de montagne dégel : l'art. 4 du permanent renvoie à un arrêté annuel, fixé ici au 2 mai.
- Citations de l'annexe IV et des annexes III, Soler : transcrites depuis l'image, pas copiées d'une couche texte ; les lignes de l'annexe IV sont écrites « COMMUNE | COURS D'EAU | LONGUEUR | AMONT | AVAL ».

3 règles les plus risquées
1. 66-carnassiers-quota-jour : liste d'espèces non écrite dans le texte.
2. 66-tous-reserve-matemale-aude et 66-tous-reserve-agly-frayeres : dates et portée devinées sur une cellule de tableau ambiguë.
3. 66-tous-reserve-riviere-* (43 lignes) : relues sur image, une confusion de pont ou de commune est possible.

Vérification : python3 -I outils/regles/valider.py outils/regles/dep/66.json -> OK : 329 règles, 4 textes
