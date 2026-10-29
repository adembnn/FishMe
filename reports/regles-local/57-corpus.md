Décision débloquée : quels textes de Moselle les deux lecteurs lisent (AUCUN texte 2026 obtenu à ce stade : collecte bloquée)

Textes gardés : 0. Aucun PDF signé n'a été téléchargé, donc corpus.py n'a rien traité (pas de sources.json, pas de manifeste).

Ce qui est accessible (pages de la préfecture, lues une fois) :
- moselle.gouv.fr > Actions de l'État > Environnement > Eau, sécheresse et pêche > Les décisions > « Les décisions dans le domaine de la pêche ».
- Cette liste compte 285 entrées de 2012 à octobre 2026, toutes des pages « fiche » (pas de lien PDF direct dans la liste).
- 2026 (fiches, signature telle qu'affichée dans la liste) : n°3 du 05/02, n°8 du 09/03, n°9 du 20/03, n°15 du 18/03, n°18, n°23 et n°25 du 30/04, n°61 du 10/07, n°66 et n°83 du 07/09, n°74 du 09/09, n°86 du 10/09, n°95 du 14/10.
- Candidats au permanent non vérifiés : la série n°90 à n°99 et n°109 à n°115 (signée le 03/01/2022 et le 03/02/2022). Rien ne prouve encore qu'elle soit en vigueur.
- Le titre de la fiche n°3 porte « 2025-DDT » alors que la date est 2026 : à vérifier sur le PDF.

Ce qui a bloqué :
1. Le site de la préfecture a renvoyé « ENHANCE_YOUR_CALM » (limitation HTTP/2 de l'IP) dès la 9e requête. J'ai arrêté les appels directs.
2. Les fiches 2026 via Exa : erreur CRAWL_UNKNOWN_ERROR sur les 13 URL.
3. L'index Wayback (web.archive.org) : connexion refusée à ce moment-là, donc pas de CDX.
4. Une recherche web : aucun arrêté de pêche 2026 de la Moselle trouvé ; seuls un arrêté 2025 (n°3 du 10/02/2025, cité au RAA n°184 du 02/09/2025) et des arrêtés 2026 de sécheresse ont été vus, à ne pas confondre avec la pêche.

Ce qu'un lecteur doit savoir :
- Le texte qui fait foi n'est pas identifié. Il faut le permanent en vigueur (probablement dans la série 2021-2022 ci-dessus) et l'arrêté annuel 2026 (plusieurs fiches 2026 sont probablement des arrêtés de tronçon ou de lot).
- Pour finir : relancer la collecte quand l'IP n'est plus limitée (ou depuis un autre réseau), ou obtenir les PDF auprès de la fédération (federationpeche57.fr) ou de la DDT.

Pour reprendre : écrire sources.json avec les URL PDF des fiches 2026, puis lancer python3 -I outils/regles/corpus.py 57.
