# Critique : navigation à 3 volets, pistes A à F (15 oct. 2026)

> **Notes simulées, pas une validation.** Elles viennent d'un relecteur IA qui a lu 13 PNG et les notes ; aucun utilisateur, aucun jury réel, aucun test sur iPhone. Seul un essai du geste sur un vrai téléphone tranchera.

Décision débloquée : quelle piste Adem retient, et quels correctifs passer avant de la monter en SwiftUI.
Écrans lus : A/B/C-centre, A/B/C-pescedex, A/B/C-club, D-centre/pescedex/club, E-centre, F-centre (E et F n'ont pas de volets latéraux).

## 0. Verdict franc
Aucune piste n'est prête à monter telle quelle. D est la meilleure base, à condition de régler un problème qu'aucune note ne traite : **sur le volet central, glisser à l'horizontale déplace la carte**. Une carte MapKit capte le geste de glissement pour se déplacer ; Clash Royale n'a pas ce conflit, son écran Bataille ne bouge pas. Tant que ce point n'est pas tranché (question 1, fin du fichier), le « geste Clash Royale » n'existe que sur Pescedex et Club.
Correction d'une note précédente : le retour par balayage depuis le bord gauche n'est actif que dans un écran poussé (NavigationStack). À la racine des volets, il ne gêne pas. Le vrai conflit oppose la carte au changement de volet.

## 1. Classement (notes sur 10)
Critères : Vision = fidélité aux mots d'Adem (3 volets, carte + 2 actions au centre, « the less the better », pas plus cartoon qu'aujourd'hui). HIG = TabView, barre de verre, cibles 44 pt, un seul fond coloré. Geste = l'écran fait-il deviner qu'on glisse. 1 jour = 3 débutants, SwiftUI, une journée. Démo = effet devant un jury.

| Rang | Piste | Vision | HIG | Geste | 1 jour | Démo | Total /50 |
|---|---|---|---|---|---|---|---|
| 1 | D barre de verre + bords voisins | 8 | 6 | 7 | 6 | 7 | **34** |
| 2 | B Clash Royale | 8 | 4 | 8 | 5 | 7 | 32 |
| 3 | A natif iOS | 5 | 8 | 2 | 9 | 4 | 28 |
| 4 | F flotteur | 6 | 4 | 6 | 5 | 6 | 27 |
| 5 | E boîte à leurres | 7 | 3 | 3 | 7 | 6 | 26 |
| 6 | C carte plein écran | 3 | 5 | 3 | 8 | 4 | 23 |

**D (34).** Vision 8 : la pile de cartes à gauche et les avatars L, M, I à droite disent « il y a quelque chose de chaque côté » sans alourdir. HIG 6 : barre native en verre posée sur la carte, le bon usage du verre ; mais **aucun onglet n'est sélectionné sur les 3 écrans D** (Carte, Pescedex et Club tous gris), et les bords voisins sont des éléments maison dans la zone de contenu. Geste 7 : sur Pescedex et Club, la lamelle avec chevron (‹ sur le coin B, › sur le coin D) se lit bien ; au centre, la pile n'a ni chiffre ni poisson, elle passe pour un autocollant. 1 jour 6 : la note D dit « TabView natif possible », c'est vrai pour le toucher seulement ; une TabView native ne change pas d'onglet au glissement. Pour avoir les deux, il faut une barre maison avec `.glassEffect()` au-dessus d'un défilement par pages, et c'est la partie la plus risquée de la journée. Démo 7 : reconnaissable et sobre.

**B (32).** Meilleur indice de geste (8) : la carte à gauche montre un vrai poisson, les avatars dépassent franchement. HIG 4 : barre hors TabView ; deux grands fonds colorés à l'écran (segment Carte teal plein + bouton vert), contraire à la règle « un seul fond coloré » ; l'avatar M recouvre « Champigny » ; sur Pescedex et Club le segment surélevé colle au bord (x ≈ 26 pt) et la barre devient bancale. Le segment surélevé tire vers le cartoon qu'Adem refuse. 1 jour 5 : barre entière à coder, accessibilité comprise.

**A (28).** La plus propre et la plus simple (HIG 8, 1 jour 9), mais elle ignore la moitié de la vision : rien ne suggère un glissement (2), et la feuille blanche plus la barre mangent 37 % de la hauteur (de y ≈ 1245 à 2000 sur 2000) ; Créteil et la position bleue sont repoussés. Devant un jury, c'est Plans avec des lettres (Démo 4).

**F (27).** Les chevrons « ‹ Carte › » et le flotteur annoncent le glissement mieux que A, C ou E. Mais trois couches empilées en bas (bouton vert, bouton blanc, rivière), des rives en 14 pt sous les 17 pt par défaut, et un curseur qui sert de navigation, ce qu'iOS ne connaît pas. La rivière fait 20 pt de haut : la métaphore ne se voit qu'en la cherchant.

**E (26).** Bonne idée sur le papier : les voisins deviennent des compartiments. À l'écran, on lit trois tuiles, pas une boîte à leurres. Le plateau fait environ 150 pt, « Commencer une session » et « Trouver le meilleur spot » cassent déjà sur 2 lignes à la taille de texte par défaut, les pastilles L, M, I se chevauchent et changent de couleur (voir §3). Rien n'invite à glisser : ce sont des boutons. Facile à coder (une rangée de trois blocs), mais le moins conforme.

**C (23).** La plus grande carte et les plus gros boutons (68 et 58 pt), mais le sélecteur en haut ressemble à un filtre et reste hors de portée du pouce. Le bouton de localisation chevauche « Joinville », et Pescedex et Club n'ont plus aucune barre en bas. C'est l'opposé de Clash Royale, qui met sa navigation sous le pouce.

## 2. Piste D : 8 correctifs, du plus important au moins important
1. **Barre d'onglets, 3 écrans.** Aucun état actif. Correction : onglet courant teinté vert, comme A (`TabView(selection:)` le fait seul).
2. **Geste au centre.** Glisser sur la carte la déplace, et le changement de volet ne part jamais. Correction recommandée pour une journée : carte libre ; on change de volet en touchant un onglet, en touchant la pile ou les avatars, ou en tirant depuis ces deux bords (zones de 44 pt de large, `simultaneousGesture` limité à ces zones). Glissement pleine page seulement sur Pescedex et Club.
3. **Coin B sélectionné sans explication.** Le repère B est foncé et cerclé, mais rien ne dit pourquoi ; « Trouver le meilleur spot » devient ambigu, puisqu'un coin semble déjà choisi. Correction : une ligne au-dessus des boutons, « Coin B · 2,4 km · 3 espèces relevées » (reprise de A), ou aucun coin sélectionné au repos.
4. **Pile de cartes à gauche.** On voit un motif d'écailles et un hexagone, sans poisson ni chiffre, et elle touche « Créteil ». Correction : montrer le dernier poisson gagné et une pastille « 3/11 », 44 pt de large au minimum, `accessibilityLabel("Pescedex, 3 espèces sur 11")`, et éloigner le libellé.
5. **Avatars à droite.** Trois ronds de 38 pt empilés sur 200 pt de hauteur, au niveau du repère E. Correction : un seul bloc de 44 pt avec les initiales serrées et un point vert quand un ami a une nouvelle carte. C'est cette nouveauté qui donne envie de glisser.
6. **Lamelles des volets latéraux.** Celle du Pescedex montre le coin B, celle du Club le coin D : ce ne sont pas la même carte. La grille du Pescedex est rétrécie, avec 16 pt de marge à gauche et environ 60 pt à droite. Correction : même cadrage (coin sélectionné) des deux côtés, lamelle de 20 pt posée sur le contenu plutôt qu'une grille rétrécie, chevron dans une zone de 44 pt.
7. **Pescedex D.** 12 vignettes (le rotengle est revenu) pour « 3 sur 11 », et D a perdu « Les miens / Amis », « 1 sur 3 Légendaires » et « Sorties ». Correction : 11 vignettes, en-tête complet des pistes A à C, sélecteur dans la barre du haut (`Picker(.segmented)` en `ToolbarItem(.principal)`, déjà demandé dans hig-niveau-1).
8. **Club D.** « Signaler ou bloquer », en lien rouge au bas de l'écran, ne vise personne. Le sous-titre « Vos amis seulement, jamais d'inconnus » est un texte inventé, sur la défensive. Correction : Signaler et Bloquer dans le menu « ··· » de chaque ami et de chaque ligne du fil, ce qui satisfait la règle 1.2 ; sous-titre « 3 amis · La Marne (94) ».

## 3. Incohérences de données et de texte
- **Compteur Pescedex.** « 3 sur 11 », alors que 4 cartes sont gagnées. A, B et C affichent 11 vignettes, truite comprise ; si la truite sort des 11, une espèce manque à la grille. D en affiche 12, rotengle compris, alors que la note ABC dit « Rotengle retiré ».
- **Truite fario.** Elle est censée n'être « jamais relevée dans le 94 », mais le joueur l'a, Léa « a rangé une truite fario » (A/B/C-club) et Inès « a gagné la Truite fario » (D-club), toutes deux dans un club du 94. Légendaires « 1 sur 3 » : les 2 autres n'apparaissent nulle part.
- **Dernière carte des amis.** A/B/C : Léa gardon, Malo sandre, Inès brochet. D : Léa sandre, Malo brochet, Inès truite. Les heures changent aussi : Malo « il y a 12 min » dans A/B/C, « hier » dans D.
- **Verbes.** « a rangé » (A/B/C), « a gagné », « a relevé », « a rejoint une sortie » (D). « Relevé » sert déjà aux espèces de l'OFB (« 3 espèces relevées ») : deux sens pour un mot. « A rejoint une sortie » invente une fonction de sortie partagée qui n'existe sur aucun écran.
- **Session ou sortie.** Le bouton dit « Commencer une session » (le mot d'Adem), le compteur dit « 2 Sorties ». Un seul mot partout. Le compteur lui-même : 2 sorties pour 4 cartes, alors que jury-niveaux C3 demandait « Sorties 4 ».
- **Couleurs des avatars.** Dans E, L est bleu, M brun et I vert ; partout ailleurs, L est vert foncé, M bleu et I brun.
- **Position du joueur.** Le point bleu est près de Créteil dans A, B, C, E et F, et au bord de la Marne dans D. « Créteil » change de place (D) ou disparaît (A).
- **Portée du Pescedex.** Sous-titre « La Marne, Val-de-Marne (94) » : une rivière ou un département ? La règle de la truite raisonne par département.
- **Doublon.** « Les miens / Amis » dans le Pescedex montre les cartes des amis, et le Club aussi. Il faut choisir l'endroit.
- **Club ou communauté.** Adem a dit « mon club de pêche, la communauté » ; les écrans montrent 3 amis et rien d'autre (question 3).

## 4. Greffes sur D (3 au plus)
1. **De A :** la ligne d'information « Coin B · 2,4 km · 3 espèces relevées », sans la feuille. Elle donne leur sens aux deux boutons.
2. **De B :** un vrai poisson visible sur la pile de gauche (le sandre de B-centre). La note D a enlevé le poisson pour ne rien tronquer, mais c'est le poisson qui fait lire « collection ». Montrer l'animal entier, plus petit, sur la carte du dessus.
3. **De F :** les chevrons « ‹ › » de part et d'autre de l'onglet actif, seulement au premier lancement, avec un rebond de la carte vers chaque voisin (piste « rebond au démarrage » de premier-lancement.md), puis plus jamais.

## 5. Ce qui manque pour juger
- **Nouveau joueur** : 0 carte, 0 ami. La pile et les avatars disparaissent, donc l'indice de glissement s'en va au moment où il sert le plus. Que montrent les bords ce jour-là ?
- **Premier lancement** : l'écran 0 (« Où pêcher près de toi… ») et la demande de localisation. Sans position, que montre la carte ?
- **Un prototype du geste sur iPhone** (même 20 lignes de SwiftUI) : carte qui défile contre glissement de volet. Aucune maquette fixe ne le prouve.
- **Session en cours** : la barre « Sortie en cours · 1 h 42 » (`tabViewBottomAccessory`) avec les 3 volets.
- **Le résultat de « Trouver le meilleur spot »** et la fiche d'un coin.
- Taille de texte AX3, mode sombre, VoiceOver sur la pile et les avatars.
- 2 ou 3 captures de référence d'Adem qui fixent le niveau « pas plus cartoon », pour juger B et E autrement qu'à l'œil.

## Questions pour Adem
Le décor : D gagne, mais trois points relèvent de toi (produit et périmètre). Défauts proposés entre crochets.
1. Geste au centre : a. carte libre, changement de volet par toucher ou depuis les bords **[défaut]** · b. carte figée en aperçu au repos, qu'on touche pour la déplacer (le glissement Clash Royale marche partout, mais la carte perd sa liberté) · c. pas de glissement du tout, onglets seuls (A).
2. Mot pour une pêche : a. « session » partout (ton mot) **[défaut]** · b. « sortie » partout.
3. Volet droit : a. Club = tes amis seulement pour la démo **[défaut]** · b. ajouter une partie « communauté » (spots publics, prises du 94), avec modération à prévoir.
