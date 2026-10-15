# Récap sur la carte d'accueil

Base : piste A2 (iOS natif, barre d'onglets en verre, carte de la Marne). Le récap se pose sous les boutons Filtres et Ma position, en haut à droite, à 20 pt du bord. Il ne touche ni la barre de recherche, ni le bouton de localisation, ni la feuille du bas, ni la barre d'onglets. Il recouvre le libellé « Joinville » et le repère C (verrouillé), voir les risques.

## 6 idées de forme (probabilité qu'un autre LLM la propose)

1. Vignette double façon BeReal (photo de la prise et photo du lieu) repliée en haut à droite : 45 %.
2. Pile de cartes « ta saison » qui s'ouvre en story plein écran façon Wrapped : 40 %.
3. Pastille de verre qui grossit en carte : 55 %.
4. Carte postale de la dernière session, avec timbre, cachet et verso : 12 %.
5. Ruban de mesure : une languette de mètre dépasse du bord de l'écran, un toucher le déroule et le brochet apparaît à l'échelle du 68 cm : 8 %.
6. Étiquette de prise accrochée au repère B de la carte, comme une étiquette de bagage attachée à l'épingle : 7 %.

Écartée : « il y a un an aujourd'hui » façon Photos. L'app n'a qu'une saison de données, la forme n'a rien à montrer pour l'instant.

Retenues : X (idée 1, celle d'Adem), Y (idée 2, le plus lisible pour la saison), Z (idée 4, sous 20 %).

## X. Double vignette

Référence réelle : BeReal, la prise et la photo de contexte en deux vignettes superposées, avec le geste d'échange entre la petite et la grande.
Quand elle apparaît (proposition) : une fois, après une session terminée, à l'ouverture suivante de la carte. Elle se range d'elle-même après ouverture ou au bout de 48 h.
Replié : deux vignettes inclinées (carte du lieu derrière, brochet devant) et la pastille « 10 oct. ». Cible de toucher 104 x 112 pt.
Ouvert : fiche posée sur la carte floutée. Grande photo du brochet (68 cm, peu commun), petite vignette du lieu en haut à gauche qu'on touche pour intervertir. Croix de 44 pt, toucher hors de la fiche ou touche Échap pour fermer.
Pas de vraie photo : la prise est l'illustration du brochet, le lieu est un extrait de la carte sans libellé, donc pas plus précis que la Marne.
Risque HIG : la vignette masque un repère verrouillé et un nom de commune. Texte « 10 oct. » en 12 pt sur la vignette, sous les 13 pt recommandés pour du texte porteur de sens (il est doublé dans l'ouvert). La petite vignette et la grande ont le même geste, il faut un libellé VoiceOver qui dise laquelle est affichée (fait : le libellé change).

## Y. Pile de cartes puis story

Référence réelle : Spotify Wrapped et les stories Instagram (pages à segments en haut, toucher pour avancer).
Quand elle apparaît (proposition) : à la fin de la saison, et seulement là. En dehors de cette date, la place est libre pour X ou Z.
Replié : trois cartes en éventail (sandre, brochet, truite fario légendaire), pastille « 4 » et libellé « Ta saison ». Cible 100 x 128 pt.
Ouvert : story plein écran en 3 pages (chiffres, les 4 cartes, dernière session). La maquette montre la page 2. Pas d'avance automatique : boutons Suivant et Retour de 54 pt, croix de 44 pt, Échap.
Gardon et sandre : leur rareté n'est pas dans le contenu fourni, ils n'ont donc pas de pastille de rareté et une tuile neutre.
Risque HIG : plein écran modal, la sortie doit rester évidente (croix en haut à droite, toujours visible, mais hors zone de pouce). Un geste de balayage vers le bas pour fermer est à ajouter côté code. Le blanc sur le vert foncé tient le contraste, le texte du segment de progression n'existe pas pour VoiceOver : annoncer « page 2 sur 3 ».

## Z. Carte postale (sous 20 %)

Référence réelle : les cartes postales à grosses lettres de type « Greetings from… » des années 1930 à 1950, et leur verso (timbre, cachet, ligne d'adresse).
Quand elle apparaît (proposition) : le lendemain d'une session, une seule fois, jamais deux jours de suite.
Replié : petite carte inclinée de 4 degrés avec le brochet, et un cachet rouge « 94 ». Cible 128 x 96 pt.
Ouvert : le recto en grosses lettres « LA MARNE » avec le brochet, 68 cm, peu commun, Sam. 10 oct., Coin B, 1 h 20. Le bouton « Retourner la carte » (54 pt) montre le verso : texte de la session, timbre, cachet, quatre timbres pour les cartes de la saison. Croix de 44 pt.
Le retournement est un bouton, pas seulement un geste. Réduction des animations : le retournement devient un changement sec.
Risque HIG : le texte du recto est penché de 1,5 degré, ce qui nuit un peu à la lecture avec une taille de texte système agrandie (Dynamic Type). Le cachet rouge sur crème (14 pt) est décoratif et masqué à VoiceOver. Le verso a un grand vide au milieu : voulu pour l'effet postal, à vérifier avec le client.

## Communs

Aucune ouverture automatique : le récap reste replié tant qu'on ne touche pas. Animations d'entrée coupées sous prefers-reduced-motion. Aucune barre de défilement. La maquette navigue entre replié et ouvert par des liens (recap-x-replie.html et recap-x-ouvert.html).
Dans les captures, « Ton spot » apparaît à gauche du repère B : c'est ce que rend a2.css tel qu'il est dans A2 (l'image A2-carte.png de l'autre dossier est plus ancienne). Non modifié ici.
