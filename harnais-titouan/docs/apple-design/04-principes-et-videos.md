# 04 - Principes Apple et vidéos WWDC (synthèse pour Bredouille)

Sources : 3 sessions WWDC, pages Apple Design Awards, Design Resources, SF Symbols.
Légende : [F] fait lu sur la source ; [I] inférence ; ⚠ non vérifié / non lu.
Tout est paraphrasé (aucune citation).

⚠ Limite générale : WebFetch renvoie un résumé produit par un petit modèle, pas la
transcription brute. Les transcriptions intégrales (minutage fin, exemples exacts) n'ont
PAS été lues. Les points ci-dessous sont fiables au niveau des idées, pas au mot près.

---

## 1. WWDC25 - 359 « Design foundations: from idea to interface »

Intervenante : Majo (Design Evangelism). Fil rouge : refonte d'une app fictive de vinyles.

### Idées clés [F]
- Une bonne app répond tout de suite à trois questions : où suis-je, que puis-je faire,
  où puis-je aller ensuite. Une app jolie peut échouer sur ces trois points.
- Quatre chantiers dans l'ordre : structure, navigation, contenu, design visuel.

### Règles et conseils actionnables [F]
- Structure : brainstormer toutes les fonctions, imaginer des usages réels (quand, où,
  comment), puis élaguer, renommer, regrouper. Si l'essentiel n'est pas défini, l'interface
  ne peut pas le communiquer.
- Tab bar : navigation entre sections principales uniquement, peu d'onglets, jamais des actions.
  L'action principale (ex. « Ajouter ») va dans l'écran concerné / la toolbar, pas dans un onglet.
- Toolbar : titre d'écran qui oriente (pas un logo ni un menu), seulement les actions
  essentielles, en SF Symbols.
- Remplacer les icônes maison par des SF Symbols (familiers, cohérents).
- Fusionner les onglets qui ne sont que des regroupements ; nommer clairement.
- Contenu : séparer les types de contenu, divulgation progressive (quelques groupes visibles,
  le reste derrière un contrôle près du titre), transitions cohérentes avec bouton retour.
- Grille vs liste : la grille consomme de la place et gère mal le texte long ; la liste se
  scanne mieux. Pour du contenu visuel (photos, produits) : vue collection, espacement
  constant, peu de texte par cellule.
- Grouper les longs contenus par temps (récents, saison), progression (reprendre), motifs
  (genre, style, similaires).
- Hiérarchie visuelle : un élément ancre plus grand et plus contrasté.
- Typo : styles de texte système + Dynamic Type, pas de tailles bricolées.
- Texte sur image : ajouter un fond discret (dégradé, flou). Lisibilité > esthétique.
- Images hétérogènes = effet décousu : palette limitée (4 couleurs), formes récurrentes,
  règles d'usage simples.
- Couleurs sémantiques système (label, secondarySystemBackground) ; accent couleur avec
  parcimonie (boutons, sélection).

### Conséquence pour Bredouille
- [I] Onglets très limités (ex. Pêche / Collection / Carte / Profil). « Nouvelle prise »
  = action contextuelle (bouton toolbar ou action flottante), pas un onglet.
- [I] Collection de cartes : vue collection (grille) justifiée car contenu visuel, mais
  proposer aussi une liste pour la recherche/tri ; regrouper par espèce, récent, complétion
  (progression de collection = motif « progress »).
- [I] Les cartes sont très colorées : imposer une palette et des formes communes pour
  qu'elles restent cohérentes, et garder l'UI autour en couleurs système.
- [I] Titres/noms d'espèces sur illustration : fond dégradé ou matériau pour rester lisibles.
- [I] Liquid Glass : sert la navigation (tab bar, toolbar), pas le contenu des cartes.

---

## 2. WWDC17 - 802 « Essential design principles »

Intervenant : Mike Stern. Principes universels (le pourquoi, pas le comment).

### Idées clés [F]
- On conçoit pour des humains (besoins pratiques et émotionnels), pas pour des « utilisateurs ».
- Onze principes ; ils peuvent se contredire, le jugement tranche. Trop de n'importe lequel
  nuit (trop de feedback agace, trop de visibilité distrait, trop de divulgation ralentit).

### Règles par principe [F]
1. Wayfinding : chaque écran dit où je suis, où je peux aller, ce que j'y trouve, comment sortir.
2. Feedback : statut, complétion, avertissement, erreur. Toute action doit être confirmée.
   Prévenir les erreurs (validation en direct, corriger l'intention). Test : observer un
   nouvel utilisateur, noter ses hésitations.
3. Visibilité : ne pas cacher l'info de statut derrière de la navigation ; arbitrer avec la densité.
4. Cohérence : externe (conventions de la plateforme, glyphes connus comme le partage iOS)
   et interne (polices, couleurs, glyphes). Innover sur le simple seulement avec forte raison.
5. Modèles mentaux : ne pas casser des habitudes ancrées ; gros changements = tests rigoureux.
6. Proximité : un contrôle près de l'objet qu'il affecte.
7. Regroupement : montre les relations, structure l'écran.
8. Mapping : contrôle qui ressemble à l'objet (slider horizontal pour propriété horizontale) ;
   manipulation directe = meilleur mapping ; un label ne rattrape qu'à moitié.
9. Affordances : signaler visuellement ce qu'on peut faire (boutons arrondis, curseurs).
10. Divulgation progressive : règle 80/20, simple d'abord, avancé à un geste ; attention à
    ne pas enterrer des fonctions utiles.
11. Symétrie : équilibre, ordre ; répétition pour structurer (listes, emplacements réguliers).

### Conséquence pour Bredouille
- [I] Feedback = terrain de jeu : enregistrer une prise doit avoir une confirmation forte
  (animation de carte obtenue, haptique, son optionnel) ; états visibles (GPS/sauvegarde en cours).
- [I] Pêcheur souvent en extérieur, mains mouillées, une main : cibles larges, actions
  principales à portée de pouce, saisie minimale (espèce, taille, photo en 2-3 gestes).
- [I] Divulgation progressive : saisie rapide d'abord, détails (appât, météo, spot) repliés.
- [I] Respecter les conventions iOS (partage, suppression, retour) ; l'originalité va dans les
  cartes, pas dans la navigation.
- [I] Mapping : taille/poids via manipulation directe (slider/règle), pas un champ texte.
- [I] « Bredouille » (rentrer sans prise) doit rester un état de feedback positif, pas une erreur.

---

## 3. WWDC18 - 801 « The qualities of great design »

Intervenante : Lauren Strehlow ; 13 designers interrogés.

### Idées clés [F]
- La qualité = intention, détails, soin et temps ; invisible quand elle réussit.
- Elle se mérite, ne se proclame pas : visible aussi dans captures App Store, description,
  réponses aux avis. Les intentions se sentent (un écran Réglages bâclé affecte tout).
- Quatre aspirations : simplicité, splendeur (polish), intemporalité, impact positif.

### Conseils actionnables [F]
- Simplicité : faire peu, très bien ; navigation/gestes familiers ; usage souvent bref et
  interrompu.
- Polish : les animations suivent exactement le geste ; dans les jeux, apprendre par
  découverte active et récompenser l'essai plutôt que tooltips lourds.
- Intemporel : moins tendance, plus durable.
- Impact : l'app améliore-t-elle la journée de quelqu'un ?
- Techniques : caricaturer une forme pour en discuter ; prototyper et tester en contexte
  réel ; accepter le feedback ; se demander si ça marche en fauteuil roulant, pour un débutant,
  etc. ; fixer tôt les attentes d'équipe.

### Conséquence pour Bredouille
- [I] Soigner les détails invisibles : alignements, états vides, Réglages, erreurs réseau
  (pas de réseau au bord de l'eau !), hors-ligne fonctionnel.
- [I] Onboarding des cartes par découverte (première prise = première carte révélée), pas
  de tutoriel en pop-ups.
- [I] Intemporel : s'appuyer sur composants/typo système et Liquid Glass natif plutôt que sur
  des effets à la mode maison.
- [I] Impact positif : encourager la remise à l'eau / respect des tailles légales, sans
  moralisme. Tester sur le terrain avec de vrais pêcheurs.
- [I] Le jury MWM/Apple peut lire le soin dans les marges : une démo fluide, sans écran bâclé.

---

## 4. Apple Design Awards (page awards) [F]

Six catégories, chacune en Apps et Games :
- Delight and Fun : expériences mémorables, engageantes, satisfaisantes grâce aux technologies Apple.
- Inclusivity : bonne expérience pour tous (origines, capacités, langues).
- Innovation : usage novateur des technologies Apple qui distingue l'app dans son genre.
- Interaction : interfaces intuitives, contrôles sans effort, adaptés à la plateforme.
- Social Impact : améliorer des vies, éclairer des enjeux importants.
- Visuals and Graphics : images soignées, interfaces dessinées avec talent, animations de
  qualité, thème distinct et cohérent.

Gagnants 2026 (apps) : grug (Delight), Guitar Wiz (Inclusivity), NBA Live Games & Scores
(Innovation), Moonlitt (Interaction), Primary: News in Depth (Social Impact), Tide Guide
(Visuals). ⚠ La page ne précise pas gagnant/finaliste ; attribution déduite de la mise en page.
⚠ Aucune grille de notation ni règle d'éligibilité détaillée sur la page ; pages 2025/2024 non lues.

Lecture [I] : Tide Guide (app de marées, données de nature + belle visualisation) et Moonlitt
sont des voisins directs de Bredouille (outdoor, données naturelles, beauté, interaction).

---

## 5. Ressources utiles (Design Resources + SF Symbols)

### Design Resources [F, avec ⚠]
- Kits UI Figma et Sketch : iOS/iPadOS, macOS, watchOS 26, visionOS 26, etc.
- Gabarit d'icône d'app (Figma, Sketch, Photoshop/Illustrator) ; gabarits Live Activities,
  Wallet, Siri/App Shortcuts, TipKit, Sign in with Apple, etc.
- Polices : SF Pro (iOS/iPadOS/macOS/tvOS), SF Compact (watchOS), SF Mono, New York (serif,
  utile en affichage : piste pour les noms d'espèces sur les cartes) ; variantes arabe,
  arménien, géorgien, hébreu.
- Icon Composer : icônes en couches avec Liquid Glass depuis un seul design, avec export
  aplati pour le marketing ; nécessite macOS Sequoia ou plus récent.
- ⚠ Incohérence de versions : la page lue annonce « iOS 27 / macOS 27 / SF Symbols 27 »
  pour les kits iOS, mais « watchOS 26 / visionOS 26 » ailleurs. À revérifier à la main sur
  la page réelle avant de citer un numéro de version (la date du jour est oct. 2026).

### SF Symbols [F, avec ⚠]
- Plus de 7 000 symboles, 9 graisses, 3 échelles, alignés sur le texte.
- Recherche sémantique améliorée (descriptions en langage courant).
- Animations : Bounce, Wiggle, Rotate, Breathe, Magic Replace ; Draw On/Off (tracé
  manuscrit) avec annotations de points guides pour symboles personnalisés.
- Rendu variable : Variable Color (progression par opacité) et Variable Draw.
- Modes de rendu : monochrome, hiérarchique, palette, multicolore, option dégradé.
- Localisation : variantes pour plus de 20 écritures, sens de lecture.
- ⚠ Numéro de version contradictoire : le résumé évoque « SF Symbols 7 » (WWDC25) et un
  fichier « SF-Symbols-27.dmg ». Ne pas figer la version sans ouverture manuelle de la page.
  Téléchargement : macOS Sonoma ou plus récent.

### Conséquence pour Bredouille
- [I] Utiliser SF Symbols pour toute l'UI de navigation ; symboles personnalisés (poisson,
  hameçon, canne) créés avec une structure en couches pour hériter des animations (Draw, Bounce).
- [I] Variable Color pour une jauge de progression de collection ; Magic Replace pour
  basculer favori / non favori.
- [I] Icône d'app via Icon Composer (Liquid Glass natif) ; vérifier lisibilité en clair/sombre/teinté.
- [I] Polices : SF Pro pour l'UI ; New York ou une police arrondie à envisager pour les noms
  d'espèces (reste dans l'écosystème système, ⚠ choix à valider visuellement).

---

## 6. Ce que le jury Apple valorise probablement [I]

Déduit des sessions et des catégories ; aucune source n'énonce un barème pour le défi.
1. Clarté d'orientation à chaque écran (où je suis / que faire / où aller) [I].
2. Usage natif et juste des composants et de Liquid Glass, sans casser les conventions iOS [I].
3. Soin des détails et des états secondaires (vide, erreur, hors-ligne, Réglages) [I].
4. Feedback riche et immédiat : animation, haptique, son aux moments clés (obtention d'une carte) [I].
5. Cohérence visuelle forte (palette limitée, formes récurrentes) avec lisibilité d'abord [I].
6. Accessibilité réelle : Dynamic Type, contraste, VoiceOver, cibles larges, mouvement réduit [I].
7. Usage pertinent des technologies Apple (Photos/caméra, CoreLocation, Widgets, Live
   Activities, App Intents, MapKit) au service du cas d'usage, pas en vitrine [I].
8. Une histoire humaine : plaisir de collectionner + lien à la nature / pratique responsable [I].
9. Simplicité d'usage en situation réelle (extérieur, une main) avec divulgation progressive [I].
10. Démo qui fonctionne de bout en bout, finie plutôt que large [I].

⚠ Non lu : transcriptions intégrales des 3 vidéos, pages ADA 2024/2025, HIG, vidéo
« What's new in SF Symbols » et sessions Liquid Glass.
