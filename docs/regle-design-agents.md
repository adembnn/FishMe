# Règle de design système à coller dans le brief de tout agent qui écrit de l'interface

Écrite le 16 oct. par l'audit du « gardien du design système » (Titouan). Le design système d'Adem est dans `App/Style/Style.swift` et `docs/design-systeme/`.

```
DESIGN SYSTÈME FISHME (App/Style/Style.swift) : jamais d'écart.
1. Couleurs : seulement Palette.*, StyleRarete, CouleursCarte. Jamais Color.red/.green/.white/.black ni hex en dur (texte sur marine : Palette.surMarine). Exception : écran Météo (StyleMeteo).
2. Polices : Police.* (grandTitre, titre, corps, detail, legende) ; Police.taille(n) pour icônes et cadres fixes. Jamais .system(size:).
3. Espace.*, Rayon.*, Gabarit.zoneTactile (44 pt minimum partout) ; surfaces : tuileFishMe() ou Palette.surface/tuile, pas de matériau.
4. Boutons : .buttonStyle(.principal) ou .secondaire ; fermer/retour = BoutonRond(role:). Jamais de bouton rond ou coloré maison.
5. Cartes : toujours CarteCadre, CarteRectoView, CarteAmiMini, StyleRarete, BadgeRarete. Jamais de copie de carte.
6. Chaque écran présenté a un retour/fermeture visible ; titre d'écran en Police.grandTitre, un seul par écran.
7. Textes : français, tutoiement, sans emoji, jamais Pokédex/Pokémon, pas de pourcentage d'identification, chiffre OFB = nombre de pêches + année.
8. Aucun texte sur un dessin ni sur un autre texte : lineLimit, minimumScaleFactor, bande de texte à hauteur réservée.
```

Exception assumée : l'écran Météo (`TesConditionsMeteoView`, `CartesMeteo`, `StyleMeteo`) reprend l'allure de l'app Météo d'Apple (dégradés, texte blanc, matériaux, polices fines) à la demande du chef de projet.
