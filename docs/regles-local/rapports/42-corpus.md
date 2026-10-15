Décision débloquée : quels textes de la Loire (42) les deux lecteurs lisent.

Collecte faite depuis le cloud (sites .gouv.fr bloqués, voir D3-CLOUD.md). Les PDF viennent de la fédération (peche42.fr) et d'une mairie (Perreux) ; le dernier texte est rendu par Exa.

Textes gardés (5 dont 1 pour information)
1. Arrêté DT-25-0784 relatif à l'exercice de la pêche en eau douce dans la Loire pour 2026, signé le 22/12/2025, 18 pages, couche texte (40 000 caractères). Fait foi. Copie fédération (peche42.fr/wp-content/uploads/20251222_ap_exercicepeche2026_raa.pdf), même texte que la RAA 42-2025-220 (4,07 Mo sur la préfecture). Articles : ouvertures (art. 1-2), migrateurs (3), tailles et quotas (4), modes de pêche (5-7), carpe de nuit (8), eaux interdites (9), réserves temporaires (10), parcours sans tuer (11), annexes (barrages d'eau potable).
2. Arrêté DT-26-0079 du 09/02/2026 modifiant l'article 4 (présentation, puce sur la Déôme, 23 cm), 4 pages, scan : OCR.
3. Arrêté DT-26-0448 du 08/07/2026 (anguille, RAA spécial 42-2026-127). Réécrit le tableau d'ouvertures de l'article 2 : anguille jaune bassin Loire du 1er avril au 31 juillet 2026 de jour seulement, argentée interdite, déclaration en 24 h du 13/06 au 31/07. Texte lu via Exa, fichier signé non obtenu (corpus/42/ap-2026-anguille-0708.html). Il prime sur l'article 2 de l'arrêté 1.
4. Arrêté du 06/01/2026 de classement des cours d'eau en 1re et 2e catégories (copie signée de la mairie de Perreux, 3 pages, scan : OCR). Beaucoup de cours d'eau ont changé de catégorie en 2026.
5. Dépliant 2026 de la fédération (information, pas une source de règle) : daté d'avant l'arrêté 3, il donne encore l'anguille jaune au 31 août.

Cherchés mais introuvables / écartés
- Fichier signé de l'arrêté DT-26-0448 : seule la RAA de la préfecture le porte, curl refusé (ENHANCE_YOUR_CALM), d'où le texte Exa.
- Arrêtés séparés cités en annexe 2 (Combray, Vidrezonne/Curaize, canal du Forez siphons, réserves de Feurs etc.) : titres seuls dans l'arrêté 1, pas téléchargés. Le détail des réserves temporaires est dans les articles 9 et 10.
- Écartés : arrêtés sécheresse (DT-26-0400, DT-26-0580), arrêtés de navigation Grangent et Villerest, calendrier des activités : sans règle de pêche.
- Géopêche (cartes des parcours) : non lisible comme texte.

Ce qu'un lecteur doit savoir
- Fait foi : l'arrêté 1 modifié par 2 et 3 ; le classement (4) donne la catégorie. Pour les ouvertures, lire le tableau de l'arrêté 3, pas celui de l'arrêté 1.
- Brochet : 60 cm en 2e catégorie, 1 par jour, 3 carnassiers dont 1 brochet ; sandre 50 cm, black-bass 40 cm (art. 4).
- Sandre en 2e catégorie ferme du 26/01 au 05/06 ; black-bass du 26/01 au 03/07 : ces dates sont dans le tableau de l'arrêté 3.
- Contradiction repérée : dépliant (anguille jaune au 31/08) contre arrêté 3 (31/07) ; l'arrêté signé prime.
- Le lecteur doit citer le texte OCR avec prudence : vérifier les chiffres sur l'image si l'OCR est douteux.

Reste à faire : corpus.py 42 (processus 9266) attend le verrou OCR partagé avec 10 autres départements (charge 17) ; les .txt et manifeste.json de 42 apparaîtront à sa fin. Si le processus est tué, relancer `python3 -I outils/regles/corpus.py 42`. Les .txt des textes 2 et 4 (OCR) restent à relire.
