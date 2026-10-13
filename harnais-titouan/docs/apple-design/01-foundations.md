# Apple HIG — Foundations (iPhone, SwiftUI, iOS 26) — pour Bredouille

Source : Apple Human Interface Guidelines, lues le 2026-10-13 via les données JSON publiques des pages
(`developer.apple.com/tutorials/data/design/human-interface-guidelines/<page>.json`, le rendu HTML étant dynamique).
Base URL des pages : `https://developer.apple.com/design/human-interface-guidelines/<page>`.
Légende : MUST = obligatoire, NE PAS = interdit. ⚠ = non lu à la source (valeur de mémoire ou tableau vide à la lecture).
Contexte Bredouille : app de pêche, caméra d'abord, cartes à collectionner, Liquid Glass seulement sur barres/boutons/feuilles.

## 0. Pages d'entrée
- ⚠ `https://developer.apple.com/design/get-started/` : page marketing non lue (rendu dynamique, pas de JSON équivalent testé).
- `.../getting-started` et `.../foundations` : lues, ce sont des pages d'index (liens vers design-principles, designing-for-ios, color,
  typography, layout, materials, accessibility, dark-mode, icons, sf-symbols, motion, launching, app-icons, writing, images,
  inclusion, privacy, branding, etc.). Aucune règle chiffrée.
- ⚠ Non lues (hors liste demandée) : design-principles, designing-for-ios, branding.

## 1. Color — `.../color`
Règles dures
- MUST utiliser les couleurs système quand possible : elles ont déjà variantes clair, sombre et contraste augmenté.
- MUST, pour toute couleur custom : fournir variante claire + sombre + variante « Increase Contrast » de chaque.
  Même si l'app ne sort qu'en un seul mode, fournir clair ET sombre « pour l'adaptativité du Liquid Glass ».
- NE PAS coder en dur les valeurs des couleurs système (elles changent d'une version à l'autre) : utiliser les API (`Color.red`, `Color(.label)`...).
- NE PAS redéfinir le sens sémantique d'une couleur dynamique (ex. ne pas utiliser une couleur de fond comme couleur de texte).
- NE PAS utiliser la même couleur pour des sens différents (ex. couleur de marque = « interactif » ET texte non interactif).
- NE PAS s'appuyer sur la couleur seule pour l'info/l'état : ajouter texte, forme ou glyphe (daltonisme : rouge/vert, bleu/orange).
- Fonds iOS : deux jeux (system, grouped) à 3 niveaux (primary = vue entière, secondary = groupes, tertiary = groupes dans groupes).
  Grouped uniquement pour tables groupées. Textes : label, secondaryLabel, tertiaryLabel, quaternaryLabel, placeholder, separator, opaqueSeparator, link.
- Wide color : Display P3, 16 bits/canal, PNG ; fournir variantes sRGB/P3 dans l'asset catalog si dégradés écrêtés.
- Tester en plein soleil (couleurs plus sombres/ternes), en faible lumière (plus vives), et avec True Tone.
Liquid Glass et couleur (mis à jour déc. 2025)
- Le Liquid Glass n'a pas de couleur propre : il prend celle du contenu derrière. Teinter avec parcimonie, seulement pour une action primaire ou un indicateur d'état.
- Pour mettre en avant une action : colorer le FOND (comme les boutons prominents), pas le symbole/texte. NE PAS colorer le fond de plusieurs contrôles.
- Barres/tab bars : monochromes par défaut (plus sombres sur fond clair, plus claires sur fond sombre). Sur fond très coloré : rester monochrome.
- Au repos (haut d'un écran scrollable), le contenu coloré sous les contrôles ne doit pas nuire à leur lisibilité.
Valeurs
- ⚠ Les tableaux RGB des 12 couleurs système + 6 gris (clair/sombre/contraste) sont vides à la lecture (images). Ne pas les coder : utiliser les API.
Conséquence Bredouille
- Fond photo/caméra = contenu riche : barres et boutons en Liquid Glass monochrome ; UNE seule action primaire teintée (ex. déclencheur ou « Ajouter à la collection »), fond teinté, pas le glyphe.
- Palette des raretés des cartes : jamais la couleur seule ; doubler par icône/forme/étoiles + libellé. Chaque couleur custom = Color Set (clair/sombre/contraste élevé).
- Éviter « vert = poisson relâché / rouge = erreur » sans glyphe associé.

## 2. Typography — `.../typography`
Règles dures
- Défaut iOS 17 pt ; minimum 11 pt (aussi pour polices custom). Polices fines : viser plus grand.
- NE PAS utiliser Ultralight, Thin, Light ; préférer Regular, Medium, Semibold, Bold.
- MUST utiliser les text styles intégrés (Dynamic Type auto). Ne pas embarquer SF : l'utiliser via l'API système (`.font(.body)`, `.fontDesign(.serif)` ⚠ nom d'API non lu = New York, `.rounded`).
- Polices custom : MUST implémenter Dynamic Type et Bold Text comme le système.
- Minimiser le nombre de familles. Garder la hiérarchie relative quand la taille change.
- Interligne : NE PAS serrer (tight) si 3 lignes ou plus.
- Dynamic Type : tester avec Larger Accessibility Text Sizes (Réglages > Accessibilité > Affichage > Texte plus grand) ; minimiser la troncature ; layout empilé aux grandes tailles ; icônes significatives agrandies avec le texte (SF Symbols = auto) ; les titres d'onglets n'ont pas à grossir.
Tailles iOS, taille « Large » (défaut), taille/interligne en pt (tableau lu)
- Large Title 34/41 Regular ; Title 1 28/34 ; Title 2 22/28 ; Title 3 20/25 ; Headline 17/22 Semibold ; Body 17/22 ; Callout 16/21 ;
  Subhead 15/20 ; Footnote 13/18 ; Caption 1 12/16 ; Caption 2 11/13. Poids « emphasized » : Large Title à Title 2 = Bold ; le reste = Semibold.
- Extrêmes : xSmall Body 14/19 ; xxxLarge Body 23/29 ; AX1 Body 28/34 ; AX5 Body 53/62 (Large Title AX5 60/70, Caption 2 AX5 40/48).
  Échelle : xSmall, Small, Medium, Large (défaut), xLarge, xxLarge, xxxLarge, puis AX1 à AX5.
Pièges
- Tableau de tracking iOS vide à la lecture ⚠ ; le système l'applique seul dans l'app (ne régler que dans des maquettes).
Conséquence Bredouille
- Tout en text styles SwiftUI (`.title`, `.body`, `.caption`...), jamais `.system(size:)` fixe. Prévoir tests aux tailles AX1 et AX5.
- Cartes : texte en police système (ou New York pour un cachet « carnet de pêche ») ; police custom => `Font.custom(_, size:, relativeTo:)` ⚠.
- Texte jamais sous 11 pt, y compris sur les cartes ; stats en Footnote (13) minimum.

## 3. Layout — `.../layout`
Règles dures
- MUST respecter les safe areas (Dynamic Island, indicateur d'accueil, barres). Les fonds plein écran s'étendent sous barres/toolbars/tab bars.
- MUST décider du layout par size classes (compact/regular), PAS par modèle ni par orientation.
- MUST adapter : Dynamic Type, Display Zoom, RTL, paysage. Mêmes fonctionnalités quand l'espace change.
- Contrôles vs contenu : NE PAS mettre de fond plein/semi-opaque sous les contrôles ; Liquid Glass + scroll edge effect.
- Hiérarchie : important en haut et côté leading ; aligner ; grouper par espace/forme/séparateur ; divulgation progressive.
- Image de fond : ne pas changer le ratio, la remplir ; effet d'extension de fond possible sous barres.
Valeurs
- Cible tactile 44x44 pt (défaut), 28x28 pt (minimum) : voir section 6 (la page layout n'en donne pas).
- ⚠ Marges latérales standard (souvent 16 pt) et tailles d'écran iPhone 17 : tableaux « Specifications » de layout vides à la lecture. Utiliser `.padding()` / layout guides système, pas de valeur codée.
Conséquence Bredouille
- Viseur caméra plein écran SOUS des barres Liquid Glass (contenu qui s'étend, contrôles flottants). Pas de bandeau opaque derrière les boutons.
- Grille de cartes : `LazyVGrid` adaptative (colonnes selon largeur + Dynamic Type), pas un nombre fixe.

## 4. Materials / Liquid Glass — `.../materials`
Règles dures
- NE PAS utiliser le Liquid Glass dans la couche contenu (fonds, cartes, listes) : réservé aux contrôles et à la navigation flottant AU-DESSUS du contenu (tab bars, barres, boutons, feuilles). Exception : éléments transitoires interactifs (curseur/toggle pendant l'interaction).
- Parcimonie : les composants système l'ont automatiquement ; sur custom, seulement les éléments fonctionnels les plus importants.
- Deux variantes : regular (défaut ; floute et ajuste la luminosité ; pour beaucoup de texte : alertes, sidebars, popovers) et clear (très translucide, SEULEMENT sur fonds riches photo/vidéo).
- Clear sur contenu clair : couche de dimming sombre à 35 % d'opacité. Inutile si contenu sombre ou contrôles AVKit.
- Couche contenu : matériaux standard (ultra-thin, thin, regular, thick) + couleurs vibrantes ; choisir par sens, pas par teinte. Éviter quaternary sur ultra-thin/thin (contraste trop faible).
- Reduce Transparency / Increase Contrast modifient le verre : tester.
Conséquence Bredouille
- Les cartes (contenu) sont OPAQUES ou matière standard, jamais en verre. Verre : tab bar, barre d'outils, déclencheur, boutons flottants, sheets.
- Sur le viseur : clear + dimming 35 % si scène claire (ciel, eau au soleil), sinon regular.

## 5. Dark Mode — `.../dark-mode`
Règles dures
- NE PAS proposer de réglage d'apparence propre à l'app (suivre le système). Supporter l'apparence Auto (bascule en cours d'usage).
- Exception rare : apparence sombre permanente pour une app média immersive.
- Contraste minimum 4.5:1 ; viser 7:1 pour couleurs custom, surtout petit texte.
- Couleurs sémantiques / Color Set (variantes claire et sombre), pas de valeurs en dur.
- Fonds iOS : base (recule) et elevated (avance) ; préférer les fonds système pour que sheets/popovers passent en « elevated » seuls.
- Adoucir les fonds blancs d'images (halo). Icônes : SF Symbols ; variantes claire/sombre d'images via asset catalog.
- Tester Dark + Increase Contrast + Reduce Transparency, séparément et ensemble.
Conséquence Bredouille
- Cartes avec fond papier blanc : assombrir légèrement ou asset sombre dédié. Sheets sur fonds système pour l'élévation auto.
- Ne pas forcer `.preferredColorScheme(.dark)` globalement (hors cas média immersif défendable pour l'écran caméra seul).

## 6. Accessibility — `.../accessibility`
Règles dures
- Texte agrandissable d'au moins 200 % (Dynamic Type).
- Contraste (WCAG AA) : texte jusqu'à 17 pt = 4.5:1 ; 18 pt = 3:1 ; gras (toute taille) = 3:1. Si non atteint par défaut, MUST fournir un schéma plus contrasté quand Increase Contrast est actif. Vérifier en clair ET sombre.
- Cible tactile iOS : 44x44 pt par défaut, 28x28 pt minimum. Espacement : ~12 pt autour d'un élément à bezel, ~24 pt sans bezel.
- Alternative à tout geste (ex. swipe pour fermer => aussi un bouton). Gestes simples, pas de multi-doigts custom.
- VoiceOver : décrire interface et contenu (labels). Voice Control, Switch Control, Full Keyboard Access : étiqueter correctement.
- Son => doubler par haptique et par visuel. Pas d'info audio seule ; sous-titres/transcriptions pour les médias.
- Reduce Motion : réduire zoom/scale/mouvement périphérique, ressorts plus serrés, transitions x/y/z remplacées par fondus, éviter animations d'entrée/sortie de flou.
- Éviter les éléments à minuterie auto-dismiss ; pas d'audio/vidéo en autoplay sans contrôle ; respecter Dim Flashing Lights.
- Assistive Access : confirmation DEUX fois pour action difficile à annuler (ex. suppression).
- Étiquettes de nutrition d'accessibilité (App Store) : à renseigner.
Conséquence Bredouille
- Déclencheur et boutons caméra >= 44x44 pt (idéalement bien plus pour usage à une main, gants, mains mouillées au bord de l'eau) avec ~12 pt d'espace.
- Raretés : couleur + icône + libellé accessible (`accessibilityLabel` ⚠). Retour du déclencheur : haptique + visuel, pas son seul.
- Animations de révélation de carte (flip, tilt, brillance) : variantes Reduce Motion (fondu). Supprimer une prise : confirmation claire.

## 7. SF Symbols et icônes d'interface — `.../sf-symbols`, `.../icons`
Règles dures
- Quatre rendus : monochrome, hierarchical, palette, multicolor. Utiliser des couleurs système pour l'adaptation auto.
- 9 graisses (ultralight à black) alignées sur SF ; 3 échelles (small, medium = défaut, large). Assortir la graisse du symbole à celle du texte voisin.
- Variantes : outline en toolbars/listes, fill pour tab bars iOS et swipe actions/sélection (la vue choisit souvent seule).
- Variable color = changement (capacité, niveau), PAS la profondeur (utiliser hierarchical).
- Animations (SF Symbols 5+): appear, disappear, bounce, scale, pulse, variable color, replace, Magic Replace (défaut). Dégradés : SF Symbols 7+.
- Icônes custom : vecteur PDF/SVG, taille/trait/perspective cohérents, centrage optique, label d'accessibilité, pas de réplique de matériel Apple.
- Selected-state : inutile dans les composants système (tab bars, boutons).
- NE PAS utiliser SF Symbols (ni lookalikes) dans une icône d'app ou un logo.
Conséquence Bredouille
- Icônes d'onglets/outils : SF Symbols (ex. `camera`, `fish` si dispo selon version ⚠ à vérifier dans l'app SF Symbols) ; pas de symbole dans l'icône d'app.

## 8. Motion — `.../motion`
Règles dures
- Mouvement avec but ; ne pas abuser. Rendre optionnel : ne jamais le seul vecteur d'info (doubler par haptique/son).
- Feedback bref et précis, fidèle au geste ; éviter de l'animation sur les interactions fréquentes ; l'animation doit pouvoir être annulée (pas d'attente forcée).
- Jeux : 30 à 60 fps stable.
Conséquence Bredouille
- Révélation de carte rare : spectaculaire OK une fois, mais interruptible (tap pour passer) et dégradée sous Reduce Motion.

## 9. Launching — `.../launching`
- Lancer instantanément ; launch screen quasi identique au 1er écran, sans texte, sans logo/pub (sauf si fixe dans l'écran 1). Splash seulement au début d'un onboarding.
- Restaurer l'état précédent (position de scroll, etc.). iOS : lancer dans l'orientation courante.
Conséquence Bredouille : app « caméra d'abord » => 1er écran = viseur ; launch screen = fond neutre/noir cohérent avec lui, sans texte.

## 10. App icons — `.../app-icons`
- iOS : 1024x1024 px, carré (le système arrondit), couches (fond + 1 ou plusieurs avant-plans) faites dans Icon Composer (Xcode). Apparences : default, dark, clear light, clear dark, tinted light, tinted dark (le système génère celles non fournies).
- Espaces colorimétriques : sRGB, Gray Gamma 2.2, Display P3. Vecteur (SVG/PDF) préféré pour les couches ; fond plein pleine page et opaque.
- NE PAS inclure reflets, ombres entre couches, biseaux, flous (le système les ajoute) ; bords nets ; éviter texte, photo, fines lignes ; centrer.
- Garder les mêmes éléments dans toutes les apparences ; icônes alternatives : leurs propres variantes dark/clear/tinted.
Conséquence Bredouille : icône = 1 forme simple (poisson/hameçon) en couches vectorielles, test dark/tinted.

## 11. Writing — `.../writing`
- Voix constante, ton adapté au contexte ; clair, concis ; boutons = verbe (« Send » mieux que « Let's do it! ») ; « tap » (pas « click ») sur iPhone.
- Cohérence de casse (title/sentence case) ; états vides avec prochaine étape ; erreurs proches du problème, sans blâme, avec solution ; peu de possessifs (« Favorites » plutôt que « Your Favorites »), jamais « we ».
Conséquence Bredouille : textes courts (petit écran, usage extérieur) ; état vide de collection : « Prends ta première photo » avec bouton unique.

## 12. Images — `.../images`
- iOS : fournir @2x ET @3x. PNG désentrelacé pour raster ; photos en JPEG optimisé ou HEIC ; icônes plates en PDF/SVG ; inclure un profil colorimétrique ; tester sur appareils réels.
Conséquence Bredouille : images de cartes/espèces en HEIC ou PNG @2x/@3x avec profil P3/sRGB ; illustrations plates en SVG/PDF.

## 13. Inclusion — `.../inclusion`
- Langage simple, adresse « tu/vous » plutôt que « l'utilisateur » ; éviter jargon, expressions imagées, humour risqué ; ne pas genrer sans nécessité ; figures humaines neutres (SF Symbols `person`/`figure`) ; diversité des représentations.
Conséquence Bredouille : vocabulaire de pêche défini à la première occurrence ; visuels de pêcheurs variés.

## 14. Privacy — `.../privacy`
Règles dures
- Demander seulement les données nécessaires, au moment où la fonction est utilisée (pas au lancement sauf si indispensable). Traiter sur l'appareil si possible.
- Caméra, micro, localisation, photos = permissions système avec chaîne d'usage (purpose string) : phrase active, précise, ex. « The app records during the night to detect snoring sounds » ; PAS de formulations vagues ou impératives.
- Écran pré-alerte : un SEUL bouton qui ouvre l'alerte système ; pas de « Allow » ni d'option d'annuler/fermer. Tracking : alerte système avant toute collecte ; pas de faux écrans (rejet App Review).
- Bouton de localisation Core Location (`LocationButton` ⚠ nom SwiftUI non lu) : autorisation temporaire d'un tap.
- Détails de confidentialité à renseigner sur l'App Store.
Conséquence Bredouille
- Caméra : demander à la 1ère ouverture du viseur (justifié, app caméra d'abord) avec NSCameraUsageDescription ⚠ précise (« pour photographier tes prises »). Localisation (spots de pêche) : au moment de « enregistrer le lieu », via `LocationButton` / Allow Once ; ne pas géolocaliser par défaut ; stocker/traiter les photos sur l'appareil.

## Récap chiffres clés
17 pt défaut / 11 pt min texte ; 44x44 pt cible (28x28 min) ; ~12 pt d'espace (bezel) / ~24 pt (sans) ; contraste 4.5:1 (texte <= 17 pt), 3:1 (18 pt+ ou gras), 7:1 visé en dark ; texte agrandissable >= 200 % ; dimming Liquid Glass clear 35 % ; icône app 1024x1024 px ; images @2x/@3x.
