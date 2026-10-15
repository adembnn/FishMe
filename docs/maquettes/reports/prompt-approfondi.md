# La tâche maquettes, en plus profond

Tâche de départ : « fais les maquettes de l'app de pêche, style jeu, Liquid Glass, avec les critères Apple Design Awards et MWM ».

## 1. Ce qu'un pro ferait sans qu'on le lui demande
- Il ne dessine pas un « écran d'accueil » mais **les 30 premières secondes** : de l'ouverture de l'app à la première carte gagnée. L'accueil se juge par le temps qu'il faut pour arriver à ce moment.
- Il part du **contenu réel** (une vraie photo de brochet de la Marne, une vraie carte) plutôt que d'un bloc de texte et d'un emplacement « nom de l'app ».
- Il choisit **un seul moment signature** (la révélation de la carte) et met tout l'effort de mouvement et de matière dessus.
- Il **maquette directement en SwiftUI**, parce que le vrai Liquid Glass (`.glassEffect`) n'existe que là. En HTML, ce n'est qu'une imitation floutée.
- Il teste à taille réelle, **sur un iPhone**, en mode sombre et avec le texte agrandi (Dynamic Type).

## 2. La matière la plus brute
- Les **parcours de premier lancement** d'apps qui marchent, écran par écran (Mobbin, connecteur déjà branché ici). Pas mes résumés.
- Le **kit officiel iOS 26 d'Apple** (Apple Design Resources) et les vrais SF Symbols, au lieu de mes copies.
- Des **photos de prises postées par de vrais pêcheurs** (Fishbrain, Instagram #pecheauxcarnassiers) : ce qu'ils montrent, comment ils posent, ce qu'ils écrivent.
- Les **captures App Store** des apps de la catégorie : ce qu'elles vendent dans la 1re image.

## 3. Méthodes et outils
- Mobbin : 3 parcours d'onboarding découpés (Merlin Bird ID, Seek, Pokémon Sleep, Duolingo), avec le nombre d'écrans avant le premier « moment magique ».
- Le kit Apple iOS 26 dans Figma, ou les previews SwiftUI dans Xcode le jeudi.
- **Test des 5 secondes** : on montre l'écran 5 s, la personne dit ce que fait l'app et ce qu'elle toucherait.
- **Test du premier clic** sur la carte et le Pescedex.
- La checklist HIG déjà faite (reports/hig-niveau-1.md) comme garde-fou, pas comme objectif.

## 4. Ce qui prouve que c'est bon (hors toi et moi)
- **5 pêcheurs ou camarades** passent le test des 5 secondes : au moins 4 disent « je prends en photo mes poissons et je les collectionne » sans aide.
- L'écran tourne **sur l'iPhone de test de MWM**, en SwiftUI, avec le vrai Liquid Glass.
- Le **mentor MWM** choisit l'écran qu'il mettrait en 1re capture App Store.
- Une note de jury simulé n'en est pas une preuve.

## Le prompt réécrit
> Structure imposée (Adem, 15 oct.) : 3 volets façon Clash Royale, la carte au centre (« Commencer une session », « Trouver le meilleur spot »), le Pescedex à gauche, le club et la communauté à droite, le moins d'écrans possible. Le découpage final suit le fil « Plan de construction de l'app ».
> Conçois les 30 premières secondes de l'app (ouverture → première carte gagnée), pas une série d'écrans.
> Pars de matière brute : 3 parcours de premier lancement réels sur Mobbin (Merlin, Seek, Pokémon Sleep), le kit iOS 26 d'Apple, et 10 vraies photos de prises de pêcheurs. Cite chaque source.
> Donne-moi 3 pistes d'accueil sur une planche A/B/C, chacune construite autour d'une vraie photo et de la carte, sans bloc de texte ni nom d'app inventé. J'en choisis une avant que tu fasses le reste.
> La piste choisie est montée en SwiftUI jeudi (vrai Liquid Glass), testée sur l'iPhone de MWM en clair, en sombre et en texte agrandi.
> C'est validé par le mentor MWM (Adem, 15 oct. : pas de test des 5 secondes), pas par la note d'un agent.
