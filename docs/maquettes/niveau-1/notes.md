# Niveau 1 : parcours de démo en 9 écrans + raretés

Cible : entre la carte K (sobre, éditoriale) et le niveau 2 (eau claire, pastilles). Structure de K : carte à face sombre gravée, plaque claire inclinée, gros centile (CEN), hiérarchie calme. Quatre indices de jeu seulement : badge hexagonal de rareté, progression « 3 sur 11 espèces » en pastilles, révélation sobre de la prise (gravure, reflet, tampon), titres arrondis Quicksand.

## Choix
- Polices : Quicksand 600/700 (titres, chiffres), Hanken Grotesk 400/600 (texte). Locales (`fonts/`). Rien sous 13 px.
- Fond : quasi plat (#F4FAF8 vers #E6F0EB), aucun grand dégradé. Cartes blanches opaques, une seule ombre douce.
- Verre (Liquid Glass) uniquement sur les contrôles : barre d'onglets, barres d'action, bouton fermer/retour/filtre, sélecteur Les miens / Amis, bouton Terminer / Restaurer.
- Vert d'action #1E8556 vers #156A41 (blanc dessus : 4,7:1 et plus).
- Raretés : variables par palier (`.t-commun` etc. dans `base.css`). Face ardoise claire / teal sombre / argent bleuté à écailles / bronze-or à rayons. Étiquettes en pastille claire texte foncé (AA).
- Badge : hexagone, 1 à 4 points (un point par palier), double filet pour rare et légendaire. En niveaux de gris les quatre cartes restent distinctes : luminosité de face (moyenne, sombre, claire, moyenne-sombre), motif (aucun, anneaux, écailles, rayons), nombre de points, nombre de filets.
- Données : brief « Passe 2 » (gardon 24/29, brochet 10/29, sandre 3/29, truite fario jamais relevée ; heures 17:10, 17:11, 17:42, 17:43, 17:43, 17:44, 17:44, 17:45, 18:55 ; la bredouille est la sortie du sam. 10 oct., Coin D, 1 h 20).
- Pescedex : silhouettes réutilisées de niveau-2 (calculées depuis le canal alpha de chaque espèce), 4 lignes de 3, dernière ligne finie à y = 736, barre d'onglets en haut à y = 762.
- Barre d'onglets : colonne centrale fixe de 96 px, bouton Sortie centré au pixel près (centre mesuré 196,5 = centre de l'écran). Conséquence : Carte et Pescedex à gauche, Moi seul à droite dans une colonne double.
- Prise : portée de `echelle/niveau-1.html`, poisson réduit (292 px, -22°) pour rester dans la carte (bord droit 355,7 sur 369).
- Raretés : carte de 340 px, poisson mesuré à 22 px minimum de chaque bord de la face.

## Détecteur impeccable : corrigé ou justifié
- Corrigé : contraste du bouton vert (3,4:1 vers 4,7:1), texte clair sur bronze (3,4:1 vers blanc sur #8E6D22), `cramped-padding` de `.op`, `.am`, `.mc`.
- `gpt-thin-border-wide-shadow`, `dark-glow` : matière Liquid Glass (bord 1 px + ombre large) ; `dark-glow` lit l'ombre teal comme une lueur sur page sombre, la page est claire. Gardé.
- `clipped-overflow-container` (html, body, main.screen) : cadre d'iPhone 393x852 voulu.
- `repeating-stripes-gradient` : anneaux, écailles et rayons des finitions de rareté (le motif sert de signal de palier, lisible en gris). Gardé.
- `flat-type-hierarchy` (carte, photo, sortie) : petits textes de service entre 14 et 20 px autour d'un titre ou d'un gros chiffre. Gardé.
- `gray-on-color` (#D9E8E3 sur teal, raretés) : texte « centile de taille », contraste supérieur à 8:1. Gardé.
- `cramped-padding` sur `.cd` (raretés) : le pied de plaque est posé en absolu, pas de texte collé au bord. `.g` du verdict : libellés de jauge posés en absolu. Faux positifs.

## Faiblesses
- Moi seul à droite de Sortie : l'équilibre de la barre est asymétrique.
- Carte : aplats et tracé de la Marne à la main, noms de communes indicatifs.
- La « photo » d'identification est le poisson gravé dans un cadre de visée, pas une vraie photo.
- Verdict et sortie laissent de l'air sous la carte (calme voulu, mais un peu vide).
- Contrastes sur verre lus par le détecteur et sur capture, non mesurés partout ; animations vues à 2,8 s (état final), pas en vidéo.


## Passe jury (jury-niveaux.md, 13 oct. 2026)
- Règle : fin légale de pêche = coucher du soleil (18 h 54) + 30 min = 19 h 24 (art. R436-13). Compte à rebours à 17:42 : 1 h 42 (sortie, Live Activity). Brochet ouvert jusqu'au 31 janv. (dernier dimanche de janvier 2027, 2e catégorie), 3 carnassiers par jour dont 2 brochets. Source en petit : « Code de l'environnement, art. R436 · Signaler une erreur » (fiche, verdict, verdict rouge). Valeurs « 3 carnassiers dont 2 brochets » et « 60 cm » reprises du jury et du brief, à revérifier sur l'arrêté préfectoral du 94.
- Démo : bredouille = sortie du sam. 10 oct., Coin D, 1 h 20 sur l'eau, lune 1 % (nouvelle lune le 10 oct.). Pescedex : Sorties 2.
- Nouveaux écrans portés du niveau 0 : accueil (promesse en une phrase, un seul bouton, ouvre la carte sans demander la position), partage (aperçu 9:16 avec code 7K2 M9Q en 48 pt dans l'image, lieu limité au département), verdict-rouge (52 / 60 cm, « À relâcher », croix + texte, pas seulement la couleur), espece-protegee (bouvière, arrêté du 8 déc. 1988 ; silhouette de rotengle provisoire, l'illustration de la bouvière n'existe pas dans assets), live-activity (écran verrouillé + Dynamic Island étendue, compacte, minimale ; 1 h 42 / 19 h 24).
- Paywall : la carte brochet 84e du joueur remplace la truite ; Conditions · Confidentialité (règle 3.1.2), Restaurer les achats, fermeture visible en haut à droite ; offre = cartes et raretés de toute la France, la règle de pêche reste gratuite. Prix « puis 3,99 €/mois » : hypothèse à valider par Adem, pas un choix tranché.
- Transition verdict vers carte : le verdict « Garder possible » ouvre la carte tout seul après 1,5 s (barre de progression fine, plus de bouton « Voir ma carte »). Pas de transition automatique sur le rouge ni sur l'espèce protégée : le joueur doit avoir le temps de lire et de relâcher.
- Retour haptique (à brancher en SwiftUI, non visible sur maquette) : `sensoryFeedback(.success)` pour « Garder possible » ; `.warning` en double impulsion pour « À relâcher » et « Relâche obligatoire ». Réduire les animations : fondu seul à la révélation de la carte.
- VoiceOver : la carte est un seul élément (« Brochet, 68 centimètres, peu commun, 84e centile de taille, garder possible ») ; silhouettes lues « Perche, pas encore pris ».
- Accessibilité : le badge hexagonal a son libellé en texte à côté (verdict, verdict rouge, Pescedex : « Commun », « Peu commun », « Rare », « Légendaire » en 13 pt, qui remplace les points sous le nom ; prise et paywall : « Peu commun » à côté du badge). Rien sous 13 pt ; textes en AA (vérifiés à l'écran, pas par mesure partout).
- Verre : uniquement sur les contrôles (barres d'action, fermer, Enregistrer, Restaurer, onglets) ; action principale teintée en vert ; cartes et contenus opaques. Sur live-activity, le fond de la carte de l'écran verrouillé est un flou système (surface système, pas le contenu de l'app).
- « Moi » à droite de Sortie : non traité ici (avatar en haut à droite recommandé par le jury, à faire au build).

### Détecteur : nouveaux fichiers
- Mêmes faux positifs justifiés que plus haut (`gpt-thin-border-wide-shadow`, `dark-glow`, `repeating-stripes-gradient`, `gray-on-color` #D9E8E3 sur teal 8:1, `clipped-overflow-container`, `cramped-padding` de la jauge `.g`).
- live-activity : `low-contrast` (#14181b sur noir / sur #12302D) lu sur les contours SVG en currentColor et la couleur de base de `base.css` ; à l'écran tous les textes sont blancs ou #D9E8E3 sur fond sombre (13:1 et plus). Faux positif.
- `tight-leading` 1,2 sur `.f` (verdict rouge, hérité de verdict) : lignes de 2 à 3 mots dans des pastilles, gardé.

## Passe HIG (reports/hig-niveau-1.md, 13 oct. 2026)
Décisions par défaut appliquées : (a) 3 onglets Carte / Pescedex / Moi, accessoire « Sortie en cours · 1 h 42 » au-dessus de la barre (pescedex.png), démarrage par « Commencer une sortie » (fiche) ; (b) Quicksand pour titres et chiffres de carte seulement, SF Pro (`fonts/SFProDisplay-*.woff2`) pour tout le reste, Hanken retirée ; (c) paywall à sa place dans le parcours.
- Build SwiftUI : `TabView` à 3 onglets + `tabViewBottomAccessory` (ouvre l'écran sortie) ; `NavigationStack` (Large Title sur fiche et Pescedex) ; `Picker(.segmented)` en `.principal` ; `.sheet` avec `presentationDetents` pour le Coin B ; `ShareLink` pour le partage ; `SubscriptionStoreView` pour le paywall.
- Carte : la feuille Coin B recouvre la barre d'onglets tant qu'elle est ouverte (comportement système) ; les onglets réapparaissent à sa fermeture. Pins et boutons : zones tactiles 44×44 (dessin inchangé). Bouton de position `location` ajouté sous le filtre.
- Paywall : fermeture à gauche (`xmark`), nom « Pescedex France » (nom de travail), « 1 mois gratuit, puis — €/an » (prix = emplacement balisé, à fixer par Adem), « Gratuit : N cartes » (N à fixer), mention de renouvellement automatique, Restaurer, Conditions / Confidentialité en cibles de 44 pt, bas à 34 pt de l'indicateur.
- Verdicts : plus d'auto-avance, bouton « Voir ma carte » (vert : « J'ai relâché le poisson » ; espèce protégée : « C'est relâché »). « Signaler une erreur » = bouton de 44 pt.
- Prise : « Partager » devient le bouton standard en haut à droite (`square.and.arrow.up`). Partage : feuille système affichée (partage.png), « Enregistrer » en double retiré du bouton de page (reste l'action système « Enregistrer l'image »).
- Photo : coche `checkmark` au lieu des cercles, Stepper ±1 cm (44 pt) avec graduations tous les 10 cm, deux boutons de 44 pt. Non fait : état « Identification… » et alerte caméra (états à prévoir au build).
- Bredouille : la croix à gauche enregistre quand même la sortie (aucune perte).
- Live Activity : deux planches. `live-activity` : bannière de 144 pt, un seul bouton (lien profond), heure et date du système en SF grisé, sans lampe ni appareil photo. `live-island` : étendue 371×150 pt, compacte (2 blocs de 52×37 pt, île de 230 pt), minimale (« 1:42 » + anneau). Bouton vert clair #5FD69A texte sombre sur fond sombre (contraste). Sortie : bouton « Réduire » (`chevron.down`) en haut à gauche, pastille remplacée par un texte.
- Verre : seulement sur barre d'onglets, accessoire, boutons ronds de navigation et pastille lieu. Plus de capsule autour des boutons verts ; secondaire = aplat gris léger ; sélecteur Les miens / Amis standard.
- Non fait : variantes sombres et contraste renforcé (catalogue de couleurs au build), écran de lancement (aplat #F4FAF8 sans texte).
- Détecteur : mêmes faux positifs qu'avant. Nouveau : `undersized-ui-text` 10 px sur les libellés d'onglets de pescedex (taille native iOS des onglets, rendue par le système) ; `low-contrast` sur live-activity et live-island lu sur le fond de base.css alors que les textes sont clairs sur fond sombre (13:1 et plus).

### Symboles SF (lookalikes SVG, attribut `data-sf` dans le HTML)
`chevron.backward`, `chevron.forward`, `chevron.down`, `chevron.up`, `xmark`, `line.3.horizontal.decrease`, `mappin.and.ellipse`, `location`, `map.fill`, `books.vertical.fill` (onglet Pescedex), `books.vertical` (bouton « Ranger »), `person.crop.circle.fill`, `calendar`, `checkmark.circle.fill`, `xmark.circle.fill`, `checkmark.shield`, `xmark.shield`, `checkmark`, `drop`, `arrow.right.to.line`, `square.and.arrow.up`, `square.and.arrow.down`, `doc.on.doc`, `minus`, `plus`, `message.fill`, `envelope.fill`, `airdrop`. Symbole personnalisé : `hook.custom` (hameçon, gabarit de `fish`). Badges hexagonaux de rareté et flotteur de la bredouille : dessins maison.
