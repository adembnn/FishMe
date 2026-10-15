# Contrôle HIG : maquettes niveau 1 (15 écrans)

Audit du 13 oct. 2026. Sources : HIG (pages JSON officielles lues le jour même), App Review 3.1.2, WWDC25 session 359. Valeurs lues dans `base.css` et dans chaque `.html` (1 px de maquette = 1 pt, cadre 393×852 = iPhone 15/16).
Format des lignes : **règle (lien) · élément · constaté · correction exacte**.

Repères iOS utilisés : marge sûre haute 59 pt et basse 34 pt (393×852) ; cible tactile 44×44 pt par défaut, 28×28 pt au minimum ([Accessibility][a11y]) ; texte 17 pt par défaut, 11 pt au minimum ; contraste 4,5:1 jusqu'à 17 pt, 3:1 pour le gras ou à partir de 18 pt ([Accessibility][a11y]). Styles : Large Title 34, Title1 28, Title2 22, Title3 20, Headline 17 semibold, Body 17, Callout 16, Subhead 15, Footnote 13, Caption 12/11.

## Défauts communs (comptés une fois, valables pour tous les écrans)
- [Typo, Dynamic Type][dt] · tout le texte · tailles en px fixes, blocs en `position:absolute` à des y fixes · chaque texte = un style iOS via `Font.custom("Quicksand", size:, relativeTo:)` ; mise en page en VStack/ScrollView ; tester en AX5 (taille de texte +200 % demandée par [Accessibility][a11y]).
- [Typo, polices personnalisées][cf] · Quicksand 600/700 et Hanken 400/600 · les polices personnalisées doivent aussi suivre Dynamic Type et Texte en gras · réagir à `legibilityWeight == .bold`. Hanken n'apporte rien face à SF Pro (même famille grotesque) : texte courant en SF Pro. Quicksand se justifie pour les titres et chiffres de carte (identité « jeu »), sinon SF Pro Rounded fait le même travail ([Typography][typo] : « rounded variants… alternative typographic voice »).
- [Typo][typo] · SF obligatoire · barre d'état, libellés de la barre d'onglets, bouton retour, alertes de permission, feuille de partage, feuille de confirmation StoreKit, horloge de l'écran verrouillé · ne rien dessiner en Quicksand dans ces zones (le système les rend lui-même).
- [Layout, safe areas][safe] · `.circ` top 56, `.hd` top 58, `.where` 58, titre Pescedex 56 · 1 à 3 pt dans la zone de la barre d'état (59 pt) · utiliser NavigationStack et sa barre : le contenu part de 59 + 44.
- [WWDC25 359][w359] + [SF Symbols][sfs] · environ 15 icônes SVG dessinées à la main · retour `chevron.backward`, fermer `xmark`, filtre `line.3.horizontal.decrease`, lieu `mappin.and.ellipse`, onglets `map.fill` / `rectangle.stack.fill` / `person.crop.circle.fill` (HIG : préférer les symboles pleins), calendrier `calendar`, `checkmark.circle.fill`, `xmark.circle.fill`, `checkmark.shield`, `xmark.shield`, `drop`, `arrow.right.to.line`, partage `square.and.arrow.up`, Pescedex `books.vertical.fill`. L'hameçon n'a pas d'équivalent (seulement `fish` et `figure.fishing`) : symbole personnalisé tiré du gabarit de `fish` ([Custom symbols][sfc]). Les badges hexagonaux de rareté restent des dessins maison, c'est légitime.
- [Materials, Liquid Glass][lg] · `.bar.glass` : une capsule de verre autour du bouton vert, sur 10 écrans posés sur un fond plat · verre sur verre teinté, sans contenu dessous à laisser voir ; la HIG demande « use Liquid Glass effects sparingly » · supprimer la capsule : `.buttonStyle(.glassProminent).tint(#176B42)` pour l'action principale, `.buttonStyle(.glass)` pour la secondaire, le tout dans `safeAreaBar(edge: .bottom)`.
- [Color][color] · aucune variante sombre · fournir des couleurs claires et sombres (la HIG l'exige « même si l'app n'a qu'un mode », pour l'adaptation du verre), et un jeu Augmenter le contraste.
- [Accessibility, contraste][a11y] · couleurs mesurées : ink2 #4A5258 sur fond 6,8:1, blanc sur #1E8556 4,6:1, pastilles 7,4 à 9,9:1, rouge #8A1F10 sur #FBE6E1 7,7:1, #D9E8E3 sur teal 7,8:1 · tout est conforme sauf le libellé « Sortie » (voir carte).

## 1 · accueil
- [Layout, safe areas][safe] · `.fine` (13 pt, 2 lignes) · bas à 22 pt, dans la zone de l'indicateur d'accueil (34 pt) · `bottom: 42`, ou laisser la marge sûre du système.
- [Typo][typo] · titre `.h` · 32 pt · Large Title 34 ou Title1 28 ; `.h2` 16 = Callout, conforme.
- [Launching][launch] · écran de lancement non prévu · aplat #F4FAF8 sans texte ni logo, au plus près du premier écran.
- [Privacy][priv] · bouton « Voir les coins près de moi » · conforme : la position est demandée en contexte, pas au lancement. Déclencher l'alerte système au toucher de ce bouton, la position approximative suffit (département).
- Carte réduite à 0,5 (textes de 6,5 pt) · illustration, avec un `aria-label` · acceptable : un seul élément VoiceOver.

## 2 · carte
- [WWDC25 359][w359] + [Tab bars][tb] · « Sortie » dans la barre d'onglets · une action, pas une section (« tabs are for navigation, not for taking action ») · voir la décision 1.
- [Tab bars][tb] · grille `1fr 1fr 96px 2fr` · Moi fait 132 pt de large contre 66 pt pour Carte et Pescedex, barre déséquilibrée · TabView native, onglets de largeur égale.
- [Tab bars][tb] · libellés 13 pt en Hanken · la TabView native rend en SF 10 pt · ne pas personnaliser.
- [Accessibility][a11y] · libellé blanc 13 pt gras sur le haut du dégradé Sortie (#289662) · 3,7:1 : passe la règle 3:1 d'Apple pour le gras, échoue au WCAG AA (texte de moins de 14 pt) · fond plein #176B42 (6,5:1).
- [Color, Liquid Glass][lgc] · trois commandes à fond vert à l'écran (Voir le coin, Sortie, onglet actif en vert) · « refrain from adding color to the background of multiple controls » · un seul fond vert par écran.
- [Sheets][sheets] · carte « Coin B » posée à bottom 116 · panneau fixe · `.sheet` avec `presentationDetents([.height(180), .medium, .large])` et `.presentationBackgroundInteraction(.enabled(upThrough: .medium))`, comme Plans ; le verre est alors appliqué par le système.
- [Buttons][btn] · repères A, C, D, E · 36×44 pt · zone tactile de 44×44 (le dessin peut rester à 36).
- [Layout][layout] · bouton de recentrage absent · ajouter `MapUserLocationButton` en verre, sous le filtre.
- Conforme : `.where` et le filtre en verre au-dessus de la carte (couche des commandes), cible de 44 pt, carte en plein écran.

## 3 · fiche
- [Toolbars][tbar] · en-tête maison (`.circ` + titre 26 pt) · NavigationStack : retour système, `navigationTitle("Coin B")` en grand titre de 34 pt qui se replie au défilement.
- [Typo][typo] · `.list h2` 19 → Title3 20 ; `.row b` 19 → Headline 17 ; `.row span`, `.src` 14 → Subhead 15 ; `.rule b` 18 → Headline 17.
- [Buttons][btn] · lien « Signaler une erreur » (13 pt, dans la ligne) · environ 18 pt de haut, sous le minimum de 28 · bouton à part de 44 pt de haut, aligné à gauche (`.buttonStyle(.borderless)`).
- [Lists][lists] · ligne « Léa et Malo pêchent ici » (58 pt) · on croit pouvoir la toucher, rien ne l'indique · ajouter `chevron.forward` si elle ouvre une vue, sinon ne pas la mettre en carte cliquable.
- Conforme : couleur doublée d'un badge et d'un texte pour la rareté, action principale en bas, unique.

## 4 · sortie
- [Tab bars][tb] + [Modality][modal] · plein écran sans barre d'onglets ni moyen de réduire · pendant une sortie on ne peut plus voir le Pescedex · `tabViewBottomAccessory` « Sortie en cours · 1 h 42 » (modèle du mini-lecteur de Musique), qui rouvre cet écran au toucher.
- [Buttons][btn] · pastille teal « 0 prise · depuis 17 h 16 » · capsule de 54 pt, même forme que les boutons, mais rien ne se passe au toucher · texte simple en Subhead 15, couleur secondaire, sans capsule.
- [Typo][typo] · « 1 h 42 » 46 pt · chiffres proportionnels, le compteur va sauter · `.monospacedDigit()` (vérifier que Quicksand a les chiffres tabulaires `tnum`, sinon SF Pro Rounded) et `Text(timerInterval:)`.
- [Typo][typo] · `.bigbar .btn` 19 → 17 ; `.ringw span`, `.leg small` 14 → Subhead 15.

## 5 · photo
- [Loading][load] · aucun état entre la prise de vue et les propositions · afficher la photo et un indicateur « Identification… » tout de suite.
- [Privacy][priv] · écran de capture et alerte caméra absents · demander l'accès à la caméra au premier « J'ai une prise », avec une phrase d'usage claire.
- [Lists][lists] · cercles radio vides de 26 pt · motif Android ; iOS marque le choix par une coche · `List(selection:)`, une `checkmark` à droite de la ligne choisie seulement.
- [Sliders][slider] · taille de 10 à 120 cm sur 297 pt, soit 2,7 pt par cm · réglage imprécis au doigt · ajouter un `Stepper` à ±1 cm à côté de « 68 cm » ; graduations tous les 10 cm.
- [Buttons][btn] · « Aucune de ces espèces » et « Pas un poisson » (15 pt + 10 px de marge) · 35 pt de haut, et le point séparateur est mal aligné · deux boutons `.bordered` de 44 pt.
- [Typo][typo] · `.cap` 18 → Headline 17 ; `.op i`, `.tk` 14 → Subhead 15.

## 6 · verdict
- [Accessibility, éléments minutés][a11y] · ouverture automatique de la carte après 1,5 s · « Minimize use of time-boxed interface elements » · garder un bouton « Voir ma carte » ; auto-avance seulement si VoiceOver et Réduire les animations sont coupés, et 3 s au moins.
- [Typo][typo] · `.id b` 26 → Title2 22 ; `.vd .k` 29 → Title1 28 ; `.vd .m` 19 → Title3 20 ; `.lbl`, `.v`, `.mn` 14 → Footnote 13 ou Subhead 15.
- [Buttons][btn] · « Signaler une erreur » · environ 18 pt · 44 pt (voir fiche).
- Conforme : coche + texte + couleur, retour haptique `.success` prévu ([Haptics][hap] : motifs système selon leur sens).

## 7 · prise
- [Activity views][share] · « Partager » dans la barre du bas · le partage passe par le bouton Partager standard · bouton rond en verre `square.and.arrow.up` de 44 pt en haut à droite, qui ouvre `ShareLink`.
- [Dynamic Type][dt] · « Ranger dans le Pescedex » en 15 pt dans un bouton de 224 pt · plus petit que les autres boutons (17) et coupé dès les grandes tailles de texte · bouton seul sur toute la largeur, 17 pt.
- [Typo][typo] · `.where` 14 → 15 ; `.rar` 14 → Subhead 15.
- Conforme : Réduire les animations remplacé par un fondu ([Accessibility][a11y]), révélation en 2,4 s, une seule action principale.

## 8 · paywall
- [App Review 3.1.2(c)][ar312] + [In-App Purchase][iap] · « Prix à fixer » · ni montant, ni durée, ni nom d'abonnement : rejet presque sûr · « 1 mois gratuit, puis 3,99 € par mois » en Headline 17 au moins, juste au-dessus du bouton ; le montant facturé doit être l'élément de prix le plus visible.
- [In-App Purchase, essai gratuit][iap] · « Puis un abonnement, résiliable à tout moment » · le prélèvement automatique en fin d'essai n'est pas dit · « Renouvellement automatique sauf résiliation au moins 24 h avant la fin de l'essai, dans Réglages ».
- [In-App Purchase][iap] · « Cartes illimitées » · la limite de la version gratuite n'est écrite nulle part · écrire « Gratuit : N cartes » (chiffre à fixer).
- [Sheets][sheets] · fermeture `xmark` en haut à droite · iOS place Annuler/Fermer à gauche (bredouille et partage le font déjà) · `ToolbarItem(placement: .cancellationAction)`.
- [Buttons][btn] · liens Conditions et Confidentialité (14 pt + 6 px de marge) · 26 pt, sous le minimum de 28 · 44 pt de haut, et `bottom` à 42 au lieu de 24 (zone de l'indicateur d'accueil).
- [Typo][typo] · `.h1` 30 → Title1 28 ; `.hero b` 24 → Title2 22 ; `.legal` 14 → Footnote 13.
- Raccourci : `SubscriptionStoreView` (StoreKit, SwiftUI) affiche le prix, la durée, Restaurer et les liens légaux conformes, avec un fond personnalisable.
- Conforme : Restaurer les achats, liens légaux, fermeture visible, « la règle de pêche reste gratuite ».

## 9 · pescedex
- [Materials][lg] · `.segc` « Les miens / Amis » en verre au milieu du contenu · « Don't use Liquid Glass in the content layer » · `Picker(.segmented)` standard dans la barre du haut (`ToolbarItem(placement: .principal)`).
- [Toolbars][tbar] · titre maison 34 pt en position absolue · `navigationTitle("Pescedex")` en grand titre (34 pt, le bon style), qui se replie au défilement.
- [Dynamic Type][dt] · lignes de grille fixes à 112 pt, noms en 14 pt · débordement en AX · `LazyVGrid(columns: [.adaptive(minimum: 104)])`, hauteur libre ; noms en Subhead 15.
- Barre d'onglets : mêmes remarques que pour la carte.
- Conforme : 11 cases dont 8 silhouettes nommées (lisible sans couleur), liseré or du légendaire, Large Title de 34 pt.

## 10 · bredouille
- [Modality][modal] · `xmark` à gauche et « Ranger avec mes sorties » · que fait la croix : jette la sortie ou l'enregistre ? Risque de perte · la croix enregistre quand même (aucune perte), ou bien on la retire et on garde un seul bouton « OK ».
- [Typo][typo] · `.sts span` 13 = Footnote, conforme ; `.msg` 16 = Callout, conforme.
- Conforme : carte en face pleine (contenu, pas de verre), message sans culpabiliser.

## 11 · verdict-rouge
- [Accessibility][a11y] · déjà corrigé ailleurs : la croix et le texte doublent la couleur, la jauge rouge #B3261E est à 6,5:1.
- [Buttons][btn] · « Voir ma carte » pour un poisson à relâcher · le libellé ne dit pas l'action attendue · « J'ai relâché le poisson » (verbe d'abord, comme le recommande la HIG), puis la carte.
- [Typo][typo] · mêmes écarts que le verdict (26, 29, 19, 14).
- « Signaler une erreur » · 18 pt → 44 pt.

## 12 · espece-protegee
- [Buttons][btn] · « Voir ma carte » · même remarque · « C'est relâché ».
- [Typo][typo] · `.ban b` 27 → Title1 28 ; `.sp b` 26 → Title2 22.
- Conforme : `.warning` prévu, pas d'auto-avance, consigne de remise à l'eau en Body.
- À compléter : la silhouette est provisoire (dessin du rotengle).

## 13 · live-activity ([Live Activities][la], tableau « iOS dimensions », 393×852)
- Étendue (Dynamic Island) · `.isl` 369×180 pt · hauteur maximale 160 pt, largeur 371 · retirer la ligne « La Marne (94) » ou réduire le bouton à 36 pt, pour tenir dans 160.
- Écran verrouillé · `.la` environ 361×187 pt · 160 pt au maximum · enlever soit la barre de progression soit le bouton ; marges de 14 pt (la maquette en a 16).
- Compacte · une barre de 293 pt · en vrai, deux éléments de 52,33×36,67 pt collés de part et d'autre de la caméra TrueDepth (île de 230 pt au total) · à gauche l'hameçon, à droite `Text(timerInterval:)` en « 1:42 ».
- Minimale · l'hameçon seul · « display updated information rather than just a logo » · anneau de progression du temps restant, ou « 1:42 ».
- Composition · l'île étendue et la bannière de l'écran verrouillé sont montrées ensemble · le système ne les affiche jamais en même temps · deux planches distinctes.
- Horloge « 17:42 » en Quicksand 92 pt, lampe de poche et appareil photo dessinés · c'est l'interface système · ne pas les dessiner (ou alors en SF, grisés, pour le contexte seulement).
- Bouton « J'ai une prise » · le bouton unique est conforme ; la caméra exige que l'app soit ouverte · lien profond (`Link` / `OpenURLIntent`) vers l'écran photo, pas une `LiveActivityIntent` qui tourne en arrière-plan.
- Couleurs · fond de l'app #12302D utilisé comme fond d'écran · tester sur un fond d'écran clair et en mode Always-On ; fond de bannière fixé par `activityBackgroundTint` (on ne peut pas imposer un flou de l'arrière-plan).
- Conforme : texte gras 600/700 et chiffres de 40 à 44 pt, une seule commande, durée de moins de 8 h, fin légale = fin de l'activité.

## 14 · partage
- [Activity views][share] · « Envoyer à un ami » et « Enregistrer » · « Avoid creating duplicate versions of common actions » : Enregistrer l'image est déjà dans la feuille de partage · un seul `ShareLink(item: image, preview: SharePreview("Brochet 68 cm", image:))` libellé « Partager » ; retirer « Enregistrer ».
- [Privacy][priv] · si « Enregistrer » est gardé · prévoir l'alerte d'accès en ajout seul à Photos (`NSPhotoLibraryAddUsageDescription`), au toucher.
- [Typo][typo] · `.note` 14 → Subhead 15.
- Conforme : fermeture à gauche, aperçu 9:16, lieu limité au département. Le code « 7K2 M9Q » en 48 pt dans l'image (export 1080×1920, environ 144 px) se lit bien.

## 15 · raretes (planche 1600×900, pas un écran iOS)
- [Accessibility][a11y] · palier visible sans la couleur (motif, nombre de points, filets) · conforme. Texte blanc sur bronze #8E6D22 à 4,8:1, conforme.
- Faces de carte : ce sont du contenu, donc ni verre ni matière, conforme.

## Top 10 des corrections, par impact
1. **Paywall** : afficher le prix, la durée, le nom et le renouvellement automatique (3.1.2(c)), sinon l'app est refusée. Le plus simple : `SubscriptionStoreView`.
2. **Sortie sort de la barre d'onglets** : WWDC25 359 et la HIG Tab bars le disent explicitement. Voir la décision 1.
3. **Dynamic Type** : styles iOS partout (`relativeTo:`) et mises en page en piles. Aujourd'hui, rien ne grandit.
4. **Live Activity** : 160 pt au maximum (180 et 187 aujourd'hui), compacte en deux éléments de 52 pt, minimale avec le temps restant, horloge système non dessinée.
5. **Cibles tactiles** : « Signaler une erreur » (18 pt, 4 écrans), liens légaux (26 pt), liens de la photo (35 pt), repères de la carte (36 pt) passent à 44 pt.
6. **Verre** : retirer la capsule de verre autour des boutons (10 écrans), sortir le sélecteur du Pescedex du contenu, carte « Coin B » en feuille à crans (`.sheet` + detents).
7. **Navigation native** : NavigationStack et barres d'outils au lieu des en-têtes maison ; fermeture toujours à gauche (le paywall l'a à droite) ; respecter les 59 pt du haut et les 34 pt du bas (accueil, paywall).
8. **Partage** : feuille de partage système, bouton Partager standard sur la prise, plus de bouton « Enregistrer » en double.
9. **Verdict** : supprimer l'ouverture automatique après 1,5 s (élément minuté), ou la couper avec VoiceOver.
10. **Symboles et police** : SF Symbols pour les 15 icônes génériques, SF Pro pour le texte courant et l'interface système, variantes sombres.

## À garder tel quel
Un écran d'accueil avec un seul bouton, sans compte ; la position demandée au moment où on en a besoin ; contrastes AA presque partout (mesurés) ; couleur toujours doublée d'une icône et d'un texte (verdicts, raretés) ; 4 onglets avec des libellés d'un mot ; boutons de 54 pt et ronds de 44 pt ; une seule action principale par écran ; Réduire les animations géré ; libellés VoiceOver de la carte ; haptiques `.success` et `.warning` du système ; Restaurer et liens légaux sur le paywall ; une seule commande dans la Live Activity ; badges de rareté maison (aucun symbole SF ne convient).

## Décisions pour Adem (recommandation en gras ; si pas de réponse, l'option par défaut s'applique)
1. Sortie : **a. 3 onglets (Carte, Pescedex, Moi) + « Commencer une sortie » sur la fiche + barre « Sortie en cours » au-dessus des onglets pendant la sortie (défaut)** · b. un vrai onglet « Sorties » (journal + démarrer) · c. garder le bouton central en relief (pas natif, barre d'onglets à refaire à la main).
2. Polices : **a. Quicksand pour les titres et chiffres, SF Pro pour le texte (défaut)** · b. SF Pro Rounded partout, plus de police embarquée · c. garder Quicksand et Hanken.
3. Paywall : **a. au moment où l'on atteint la limite gratuite (défaut)** · b. juste après la première prise (comme aujourd'hui) · c. seulement depuis « Moi ».

[a11y]: https://developer.apple.com/design/human-interface-guidelines/accessibility
[dt]: https://developer.apple.com/design/human-interface-guidelines/typography#Supporting-Dynamic-Type
[cf]: https://developer.apple.com/design/human-interface-guidelines/typography#Using-custom-fonts
[typo]: https://developer.apple.com/design/human-interface-guidelines/typography
[safe]: https://developer.apple.com/design/human-interface-guidelines/layout#Guides-and-safe-areas
[layout]: https://developer.apple.com/design/human-interface-guidelines/layout
[sfs]: https://developer.apple.com/design/human-interface-guidelines/sf-symbols
[sfc]: https://developer.apple.com/design/human-interface-guidelines/sf-symbols#Custom-symbols
[lg]: https://developer.apple.com/design/human-interface-guidelines/materials#Liquid-Glass
[lgc]: https://developer.apple.com/design/human-interface-guidelines/color#Liquid-Glass-color
[color]: https://developer.apple.com/design/human-interface-guidelines/color
[tb]: https://developer.apple.com/design/human-interface-guidelines/tab-bars
[tbar]: https://developer.apple.com/design/human-interface-guidelines/toolbars
[sheets]: https://developer.apple.com/design/human-interface-guidelines/sheets#iOS-iPadOS
[modal]: https://developer.apple.com/design/human-interface-guidelines/modality
[btn]: https://developer.apple.com/design/human-interface-guidelines/buttons
[lists]: https://developer.apple.com/design/human-interface-guidelines/lists-and-tables
[slider]: https://developer.apple.com/design/human-interface-guidelines/sliders
[load]: https://developer.apple.com/design/human-interface-guidelines/loading
[launch]: https://developer.apple.com/design/human-interface-guidelines/launching
[priv]: https://developer.apple.com/design/human-interface-guidelines/privacy
[hap]: https://developer.apple.com/design/human-interface-guidelines/playing-haptics
[share]: https://developer.apple.com/design/human-interface-guidelines/activity-views
[la]: https://developer.apple.com/design/human-interface-guidelines/live-activities
[iap]: https://developer.apple.com/design/human-interface-guidelines/apple-in-app-purchase#Auto-renewable-subscriptions
[ar312]: https://developer.apple.com/app-store/review/guidelines/#subscriptions
[w359]: https://developer.apple.com/videos/play/wwdc2025/359/
