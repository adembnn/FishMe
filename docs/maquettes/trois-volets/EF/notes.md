# Pistes E et F : navigation entre les 3 volets
Cinq idées, avec la probabilité qu'un autre LLM les propose :
1. Boîte à leurres : la barre et les actions fusionnent en un plateau à compartiments (cartes à gauche, actions au centre, avatars à droite). 9 %.
2. Flotteur sur la rivière : un curseur-flotteur glisse entre deux rives, Pescedex à gauche, Club à droite. 7 %.
3. Carte-sélecteur : une carte de collection posée en bas, dont on tourne la face pour changer de volet. 12 %.
4. Moulinet : un cadran rotatif dans le coin du pouce, un cran par volet. 5 %.
5. Carnet de pêche à onglets de tranche sur le bord droit, comme un répertoire papier. 17 %.
Retenues : 1 (piste E) et 2 (piste F). Rejetées : 4 (rotation non découvrable, aucun équivalent iOS) et 3 (le retournement masque les deux actions).

## E, boîte à leurres
- Référence réelle : boîte à leurres à cloisons (plateau Plano, Rapala). Les compartiments voisins montrent leur contenu, le central est le seul clair et ouvert.
- Les trois zones sont des boutons de 80 x 138 pt (côtés) et 171 x 68 / 48 pt (actions). Glissement horizontal sur la carte, même geste que Clash Royale.
- Risque HIG : barre personnalisée sans UITabBar (VoiceOver, Dynamic Type : « Trouver le meilleur spot » tient sur 2 lignes à 14 pt et cassera au-delà) ; le plateau de 150 pt couvre plus de carte qu'une barre d'onglets (-45 pt de carte vs B).

## F, flotteur sur la rivière
- Référence réelle : bouchon (flotteur) sur la ligne entre deux berges ; clin d'œil à la Marne affichée sur la carte, avec la même teinte d'eau.
- Le flotteur de 80 x 52 pt se glisse vers une rive, ou on touche une rive (100 x 54 pt). Chevrons de part et d'autre pour signaler le glissement.
- Risque HIG : un curseur utilisé comme navigation n'existe pas en natif ; il faut l'exposer comme contrôle ajustable pour VoiceOver et prévoir le retour système par balayage de bord. Le texte des rives est à 14 pt, sous les 17 pt par défaut. La barre reste en bas comme B, seule la forme change.
- Non vérifié : contraste AA à l'œil, aucun glissement animé, pastilles L, M, I de E se chevauchent un peu.
