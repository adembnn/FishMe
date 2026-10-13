# 03 - Composants HIG pour Bredouille (iPhone, SwiftUI, iOS 26)

Source : pages HIG lues via le JSON de la doc Apple (`developer.apple.com/tutorials/data/design/human-interface-guidelines/<page>.json`), contenu identique aux pages `https://developer.apple.com/design/human-interface-guidelines/<page>`. WebFetch ne rend pas ces pages (JS), d'où le JSON. Dernières mises à jour HIG vues : 8 juin 2026 (tab-bars), 24 mars 2026 (sheets), 16 déc. 2025 (toolbars, Liquid Glass).
Légende : ⚠ = non lu / non vérifié. URL de base ci-dessous abrégée en `HIG/<page>`.

## Pages non lues
- ⚠ `HIG/navigation-bars` : 404. Depuis juin 2025 la guidance « navigation bar » est intégrée à `HIG/toolbars` (change log : « incorporated navigation bar guidance »).
- ⚠ `HIG/content-views` : 404 (page inexistante). ⚠ `HIG/liquid-glass`, `HIG/adopting-liquid-glass` : 404 dans le JSON HIG ; `adopting-liquid-glass` est un article de documentation développeur (SwiftUI/Technologies), non lu. Liquid Glass lu via `HIG/materials`.

## Tab bars - HIG/tab-bars
- Quand : naviguer entre sections de premier niveau, jamais pour des actions (actions = toolbar).
- Règles dures : tab bar toujours visible (sauf modale qui la couvre) ; ne jamais désactiver ni cacher un onglet même vide (expliquer pourquoi c'est vide) ; éviter l'overflow « More » ; libellés d'un seul mot si possible ; symboles SF préférés, variantes remplies ; badge = ovale rouge, chiffre ou « ! », réservé à l'info critique ; éviter une couleur d'onglet proche des fonds du contenu (préférer monochrome si contenu coloré).
- Chiffres : aucun nombre max d'onglets sur iPhone dans la page ; ≤ 5 par défaut cité seulement pour la personnalisation iPad.
- iOS 26 : la barre flotte en bas, sur fond Liquid Glass ; avec accessoire (type MiniPlayer) elle peut se minimiser au scroll vers le bas, retour en touchant un onglet ou en remontant en haut ; un onglet Recherche dédié peut être placé en fin (trailing).
- SwiftUI : `TabView`, `TabBarMinimizeBehavior`, `TabViewBottomAccessoryPlacement` (docs liées par la page).
- Bredouille : Collection / Bestiaire / ... = onglets texte court (1 mot), icônes SF remplies, jamais masqués ni grisés (état vide expliqué : « Pas encore de bredouille »). La caméra n'est PAS un onglet-action : si capture plein écran, la présenter en `fullScreenCover` (voir Sheets) ou onglet central assumé comme section, pas comme bouton d'action. Badge seulement pour une vraie nouveauté (nouvelle espèce débloquée). Minimisation au scroll envisageable sur la Collection.

## Toolbars / barres de navigation - HIG/toolbars
- Quand : titre de la vue + navigation (retour, recherche) + actions de la vue. Sur iOS la « navigation bar » est une toolbar de navigation.
- Règles dures : peu d'items, le reste dans un menu « More » ; réduire fonds et teintes custom (laisser le Liquid Glass, utiliser `ScrollEdgeEffectStyle` si besoin) ; ne pas colorer les labels de façon proche du contenu ; composants standard (rayons concentriques avec la barre) ; boutons Retour/Fermer standard, jamais du texte « Retour »/« Fermer » ; symboles système sans bordure ; une seule action principale `.prominent` (Done/Submit), à droite (trailing) ; max 3 groupes ; séparer par `fixedSpace` les boutons texte voisins de boutons symbole.
- Chiffres : titre < 15 caractères ; grand titre (`prefersLargeTitles`) qui se réduit au scroll sur iOS.
- Emplacements : leading (retour, titre), centre, trailing (actions importantes, recherche, More, action principale).
- SwiftUI : `Toolbars` (SwiftUI), `fixedSpace`, `ScrollEdgeEffectStyle`.
- Bredouille : grand titre court sur Collection/Bestiaire (« Collection »), pas le nom de l'app ; 1-2 icônes max en trailing (filtre, recherche) ; tri/filtres dans un menu ; bouton de validation du choix d'espèce = `.prominent` trailing.

## Sheets - HIG/sheets
- Quand : tâche courte et ciblée liée au contexte (choisir, saisir). Tâches longues/caméra/photo : plein écran (`fullScreen`).
- Règles dures : une seule sheet à la fois (en fermer une avant d'en ouvrir une autre) ; Done toujours accompagné de Cancel ou Back ; jamais Cancel+Done+Back ensemble ; swipe pour fermer supporté ; si changements non sauvés au swipe, action sheet de confirmation ; grabber dans une sheet redimensionnable (tap = cycle des detents, utile VoiceOver).
- Chiffres : 2 detents système : `large` (plein) et `medium` (≈ moitié) ; medium seul interdit l'extension ; custom detents possibles. Sheet à une vue : Cancel/Close leading, Done trailing.
- Sheets iOS peuvent être non modales (ex. mise en forme dans Notes).
- SwiftUI : `sheet(item:onDismiss:content:)`, `detents`, `prefersGrabberVisible`.
- Bredouille : feuille de choix des 3 espèces = sheet `medium` + `large`, grabber visible, 3 choix lisibles sans scroll dans medium, Cancel leading, bouton de confirmation trailing `.prominent`, swipe-down autorisé (confirmation seulement si une sélection non enregistrée). Caméra = plein écran, pas une sheet. Ne jamais empiler résultat-de-capture par-dessus la feuille d'espèces : fermer l'une avant l'autre.

## Materials et Liquid Glass - HIG/materials
- Principe : Liquid Glass = couche fonctionnelle (tab bars, barres, contrôles) FLOTTANT au-dessus du contenu ; interdit dans la couche de contenu (utiliser matériaux standards). Exception : contrôles transitoires (sliders, toggles) qui prennent l'aspect glass à l'activation.
- Règles : l'utiliser avec parcimonie sur des contrôles custom (`glassEffect(_:in:)`) ; variante `regular` par défaut (beaucoup de texte : alertes, popovers, sidebars) ; variante `clear` seulement par-dessus médias riches (photos/vidéos) ; sur contenu clair, ajouter un voile sombre de 35 % d'opacité ; pas de voile si contenu sombre ou contrôles AVKit.
- Les réglages d'accessibilité (réduire la transparence, contraste) changent l'apparence des deux variantes.
- Matériaux standards iOS (couche contenu) : 4 épaisseurs ultra-thin, thin, regular (défaut), thick ; couleurs vibrantes label/secondary/tertiary/quaternary (éviter quaternary sur thin et ultraThin), fills fill/secondary/tertiary, 1 séparateur. Plus épais = plus de contraste texte ; plus fin = plus de contexte.
- SwiftUI : `glassEffect(_:in:)`, `Material`, article « Applying Liquid Glass to custom views », `clear`.
- Bredouille : tab bar et boutons de la caméra plein écran = glass `clear` sur le viseur (+ voile 35 % si fond clair) ; cartes de la Collection/Bestiaire = fonds standards, pas de glass ; paywall : contenu sur matériau standard, seuls les boutons système en glass.

## Buttons - HIG/buttons
- Quand : action instantanée. Un bouton = style + contenu + rôle.
- Règles dures : zone tactile >= 44x44 pt ; état pressé obligatoire sur bouton custom ; 1 à 2 boutons proéminents par vue ; distinguer le choix préféré par le style, jamais par la taille ; icône familière (`square.and.arrow.up` = partager) ou verbe court (« Add to Cart ») ; rôles : normal, primary, cancel, destructive ; ne jamais donner le rôle primary à une action destructive ; label monochrome si contenu coloré.
- iOS : un bouton peut afficher un indicateur d'activité et changer de libellé (« Checkout » -> « Checking out… ») pendant une action non instantanée.
- SwiftUI : `Button` (SwiftUI). Rôles via `ButtonRole`.
- Bredouille : tous les boutons >= 44 pt (déclencheur caméra inclus) ; paywall : un seul bouton proéminent « S'abonner », secondaire en style discret de même taille ; spinner dans le bouton pendant l'achat StoreKit ; « Restaurer » en texte.

## Lists and tables - HIG/lists-and-tables
- Quand : texte à parcourir/hiérarchie ; pour beaucoup d'images ou tailles variées -> collection.
- Règles : texte succinct par ligne ; ellipse au milieu possible pour garder début et fin ; feedback de sélection (surbrillance persistante en navigation, coche brève pour options) ; sur iOS il faut un mode édition pour sélectionner ; bouton info = plus d'infos seulement, `disclosureIndicator` pour descendre dans la hiérarchie ; pas d'index alphabétique si chevrons à droite des lignes. Style groupé (en-têtes/pieds) sur iOS (`ListStyle`).
- SwiftUI : `List`, `Tables` (SwiftUI).
- Bredouille : Réglages, historique, détail d'espèce (liste de caractéristiques) = `List` groupée ; pas pour la grille de créatures.

## Collections - HIG/collections
- Quand : contenu visuel/images ; layout ligne ou grille standard ; texte seul -> liste.
- Règles : pas de layout custom exotique ; marges suffisantes autour des images ; tap = sélection, appui long = édition, swipe = scroll ; animations à l'insertion/suppression/réordonnancement ; éviter de changer le layout pendant l'interaction sauf action explicite.
- Page courte, aucun chiffre. SwiftUI : ⚠ non cité (page donne UICollectionView ; équivalent usuel `LazyVGrid`, hors page).
- Bredouille : Collection/Bestiaire = grille adaptative standard de vignettes ; animation à l'ajout d'une nouvelle bredouille ; espèces non découvertes = silhouette, toujours présentes.

## Menus - HIG/menus
- Quand : commandes en espace réduit (tri, filtre, plus d'actions).
- Règles : étiquettes à verbe, capitalisation de titre, sans articles ; item indisponible = grisé, menu toujours ouvrable ; « … » si l'action demande plus d'infos ; icônes avec parcimonie, toutes ou aucune dans un groupe ; important en premier, groupes séparés ; sous-menus rares, 1 niveau, au-delà d'environ 5 items créer un autre menu ; libellé changeant ou coche pour les états.
- iOS : 3 mises en page : small (4 items icône seule en haut), medium (3 items icône + court libellé), large (liste, défaut) ; `preferredElementSize`.
- SwiftUI : `Menu`.
- Bredouille : menu de tri/filtre de la Collection avec coches (par espèce, rareté, date) ; pas plus d'un niveau.

## Alerts - HIG/alerts
- Quand : info critique immédiate (problème, destruction irréversible, confirmation d'achat). Avec parcimonie ; jamais seulement informatif, jamais au lancement, pas pour des actions courantes annulables.
- Règles : titre précis (pas « Error »), <= 2 lignes ; message seulement s'il apporte ; max 3 boutons ; titres de 1-2 mots à verbe ; « OK » seulement si purement informatif ; « Cancel » toujours ainsi nommé, jamais bouton par défaut ; bouton par défaut en trailing/haut ; style destructif seulement pour une action non voulue délibérément ; sur iOS éviter une alerte qui scrolle ; utiliser une action sheet (pas une alerte) pour des choix liés à une action volontaire.
- SwiftUI : `alert(_:isPresented:actions:)`.
- Bredouille : alertes réservées à : suppression irréversible d'une bredouille, échec d'achat. Pas d'alerte « permission caméra » inventée : message en contexte dans l'écran caméra.

## Action sheets - HIG/action-sheets
- Quand : choix liés à une action volontaire (ex. quitter avec/sans enregistrer). En SwiftUI = `confirmationDialog`.
- Règles : titre sur une ligne, message seulement si nécessaire ; Cancel en bas (inclus par défaut) ; actions destructives en haut, style destructif ; ne pas scroller ; préférer à un menu quand c'est une réaction à une action.
- Bredouille : confirmer « Supprimer / Garder » ; confirmation au swipe-down de la feuille d'espèces avec sélection non enregistrée (exigence de la page sheets).

## Pickers - HIG/pickers
- Quand : listes moyennes à longues de valeurs ; liste courte -> bouton pull-down ; très longue -> liste/table.
- Règles : valeurs prévisibles et ordonnées ; afficher le picker en contexte (pas de changement de vue) ; minutes par défaut 0 à 59, intervalle possible s'il divise 60 (ex. 15). Date picker iOS : styles compact / inline / wheels / automatic ; modes date, heure, date+heure, compte à rebours (max 23 h 59, indisponible en inline/compact). Compact si peu de place.
- SwiftUI : `Picker`.
- Bredouille : pas de picker pour les 3 espèces (choix visuel, voir sheets) ; éventuellement `Picker` pour réglages.

## Segmented controls - HIG/segmented-controls
- Quand : 2+ choix liés qui changent un objet/état/vue ; sur iOS, basculer entre sous-vues proches ; sections complètement séparées -> tab bar.
- Règles : texte OU images, pas mélange ; noms/groupes nominaux ; segments de largeur égale ; ne pas mélanger sélection et actions.
- Chiffres : au plus environ 5 segments sur iPhone (5 à 7 en interface large).
- SwiftUI : `segmented` (style de `Picker`) ; momentary : `isMomentary` (UIKit).
- Bredouille : filtre Tout / Vues / Manquantes dans la Collection = 3 segments texte ; NE PAS l'utiliser pour Collection vs Bestiaire (sections = tab bar).

## Search fields - HIG/search-fields
- Règles : placeholder indiquant le périmètre ; chercher dès la frappe ; suggestions/recents ; résultats triés par pertinence ; scope bar pour filtrer (défaut = périmètre large) ; tokens pour filtres.
- iOS : trois emplacements : onglet de la tab bar (2 styles : standard avec page d'accueil de recherche, ou « button appearance » clavier immédiat), toolbar bas ou haut (bas si place, haut s'il y a du contenu critique en bas), champ inline au-dessus de la liste (peut s'épingler en haut au scroll).
- SwiftUI : `searchable(text:placement:prompt:)`.
- Bredouille : recherche inline dans Bestiaire (filtrer des espèces) via `searchable` ; pas besoin d'onglet Recherche tant que le contenu est limité.

## Text fields - HIG/text-fields
- Règles : petite saisie seulement (sinon text view) ; placeholder + label séparé (le placeholder disparaît) ; `SecureField` pour données sensibles ; taille proportionnée ; validation au bon moment (email : au changement de champ) ; clavier adapté au contenu ; sur iOS bouton Clear en fin de champ, icône d'objet au début.
- SwiftUI : `TextField`, `SecureField`.
- Bredouille : saisie du nom d'une bredouille = `TextField` avec bouton Clear, clavier par défaut.

## Toggles - HIG/toggles
- Règles : deux états opposés qui gèrent l'état d'un contenu/vue (sinon autre composant) ; différence d'état évidente, pas seulement par la couleur.
- iOS : style switch uniquement dans une ligne de liste (pas de label, la ligne donne le contexte) ; couleur par défaut verte, ne la changer que si nécessaire et avec contraste suffisant ; hors liste, bouton qui se comporte comme un toggle (fond teinté quand actif, sans label explicatif).
- SwiftUI : `Toggle`, `ToggleStyle`, `changesSelectionAsPrimaryAction` (cité).
- Bredouille : Réglages (haptique, sons, rappels) = `Toggle` dans `List` ; favori sur une fiche = bouton-toggle (coeur plein/vide), pas un switch.

## Sliders - HIG/sliders
- Règles : min côté leading, max côté trailing ; icônes min/max possibles ; ajouter champ texte + stepper si plage large ; jamais pour le volume audio (utiliser une vue volume).
- SwiftUI : `Slider`. Page : pas de chiffres.
- Bredouille : éventuel réglage de zoom caméra : à éviter comme slider visible, préférer pincement ; si présent, glass transitoire à l'activation.

## Progress indicators - HIG/progress-indicators
- Règles : préférer le déterminé (barre qui se remplit gauche->droite, cercle sens horaire) ; progression régulière (pas 90 % en 5 s puis 5 min pour 10 %) ; toujours en mouvement ; passer d'indéterminé à déterminé dès que possible ; ne jamais passer de spinner à barre ; description précise (éviter « loading ») ; emplacement constant ; Cancel si possible, Pause en plus si l'annulation perd du travail ; alerte de confirmation si l'annulation fait perdre.
- iOS : contrôle de rafraîchissement (pull-to-refresh) masqué par défaut ; prévoir aussi des mises à jour automatiques ; titre seulement s'il informe (ex. dernière mise à jour).
- SwiftUI : `ProgressView`.
- Bredouille : analyse de l'image (identification de l'espèce) = indéterminé court, texte « Analyse de la bredouille… » ; spinner dans le bouton d'achat ; Cancel possible pendant l'analyse.

## Labels - HIG/labels
- Règles : texte non éditable ; polices système et Dynamic Type par défaut ; 4 couleurs de label : primaire, secondaire (sous-titre), tertiaire (indisponible), quaternaire (filigrane) ; rendre sélectionnable un texte utile (erreur).
- SwiftUI : `Label`, `Text`.
- Bredouille : nom d'espèce en `label`, détails en `secondaryLabel`, espèce non débloquée en `tertiaryLabel` ; `Label(title, systemImage:)` pour les lignes.

## Context menus - HIG/context-menus
- Quand : actions directement liées à un élément, révélées par appui long sur iOS (cachées par défaut, donc jamais seul accès).
- Règles : peu d'items pertinents ; cohérent dans toute l'app ; tout item doit aussi exister dans l'interface principale ; sous-menu = 1 niveau ; masquer (pas griser) les items indisponibles ; au plus environ 3 groupes ; destructif (Delete/Remove) en dernier et style destructif (rouge) ; icônes système ; pas de raccourcis clavier affichés ; contexte menu OU menu d'édition, pas les deux ; aperçu graphique avec clipping path aux coins arrondis.
- SwiftUI : `contextMenu(menuItems:)`.
- Bredouille : appui long sur une vignette = Partager, Favori, Renommer, Supprimer (dernier, rouge) ; ces actions aussi dans la fiche détail.

## Popovers - HIG/popovers
- Règles : petite quantité d'info/fonctionnalité ; un seul à la fois, jamais en cascade ; rien par-dessus sauf alerte ; ne pas servir d'avertissement (alerte) ; sauvegarder si fermé automatiquement ; Close/Cancel/Done seulement si utile.
- iOS : éviter dans les vues compactes (iPhone) ; utiliser une sheet à la place.
- SwiftUI : `popover(isPresented:attachmentAnchor:arrowEdge:content:)`.
- Bredouille : iPhone portrait = compact, donc pas de popover : sheet (voir plus haut).

## Scroll views - HIG/scroll-views
- Règles : gestes de scroll par défaut ; rendre le scroll évident (contenu partiel au bord) ; pas de scroll view imbriquée de même orientation (horizontal dans vertical OK) ; pagination (`PagingScrollTargetBehavior`) avec `page controls` mais sans indicateur de scroll sur le même axe ; zoom : bornes min/max raisonnables.
- Scroll edge effect (Liquid Glass, iOS 26) : sépare barres flottantes et contenu ; préférer le style automatic (plus opaque pour barres chargées, texte hors contrôles glass, en-têtes épinglés) ; soft à tester ; seulement quand un scroll view passe derrière des éléments flottants ; un seul effet par vue ; non décoratif. MAJ 8 juin 2026.
- SwiftUI : `ScrollView`, `ScrollEdgeEffectStyle`.
- Bredouille : grille de Collection en `ScrollView` plein bord sous la tab bar glass ; laisser l'effet automatic ; bande horizontale d'espèces dans un scroll vertical = acceptable.

## Status bars - HIG/status-bars
- Règles : transparente par défaut ; ne pas laisser croire que le contenu derrière est interactif -> flou via scroll edge effect ; masquer temporairement pour médias plein écran ; jamais de façon permanente, avec geste simple pour la ré-afficher (tap).
- SwiftUI : ⚠ non cité (UIKit : `UIStatusBarStyle`, `preferredStatusBarStyle`).
- Bredouille : caméra plein écran : barre masquable, mais permettre de la revoir (tap) ; sur Collection la laisser visible.

## Tab views - HIG/tab-views
- Page = composant macOS (non supporté sur iOS/iPadOS). Sur iOS la page renvoie vers les segmented controls. Règles hors sujet iPhone (max 6 onglets macOS). -> Pour Bredouille, la navigation par onglets = `tab-bars`. SwiftUI : `TabView` (citée).

## Content views - HIG/content-views
- ⚠ Page introuvable (404) ; non lue.

## Récapitulatif Bredouille
- Navigation : tab bar glass (1 mot/onglet, jamais masquée/désactivée) ; titres de toolbar < 15 caractères ; un `.prominent` trailing par écran.
- Caméra : plein écran (`fullScreen`, pas sheet) ; contrôles glass `clear` + voile 35 % si fond clair ; statut bar masquable puis ré-affichable.
- Choix des 3 espèces : sheet medium+large, grabber, Cancel leading / confirmer trailing, une seule sheet à la fois.
- Paywall : sheet/plein écran, un bouton proéminent, spinner dans le bouton, Restaurer, alerte seulement en cas d'échec.
- Pas de Liquid Glass dans le contenu (cartes, grille) ; pas de popover sur iPhone ; boutons >= 44x44 pt.
- ⚠ Non lus : navigation-bars, content-views, liquid-glass, adopting-liquid-glass (404 ou hors HIG).
