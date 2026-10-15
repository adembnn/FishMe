# Socle Apple de Bredouille

Une page. Tout agent de design, de construction, de test ou d'évaluation la lit avant de travailler. Détail et sources : `01-foundations.md`, `02-patterns.md`, `03-components.md`, `04-principes-et-videos.md`, `05-prototypage-apple.md` (même dossier), et `../modalites-build-apple.md`, `../preflight-appstore.md`.
Légende : **[F]** lu à la source Apple. **[I]** déduction ou décision d'équipe. **⚠** non vérifié : jamais présenté comme un fait.
Limite : les pages HIG ont été lues via leur JSON public (même contenu), les vidéos via des résumés, pas des transcriptions.

## 1. Règles dures (ne pas déroger)

**Tactile et texte**
1. Cible tactile 44 x 44 pt par défaut, 28 x 28 pt au minimum absolu ; espace autour d'un élément : environ 12 pt avec fond, 24 pt sans. [F]
2. Texte 17 pt par défaut, 11 pt minimum ; Dynamic Type géré (styles de texte, pas de tailles fixes) ; la mise en page survit aux plus grandes tailles. [F]
3. Contraste WCAG AA : 4,5:1 jusqu'à 17 pt, 3:1 à 18 pt ou en gras ; en mode sombre viser 7:1, 4,5:1 minimum. [F]
4. L'information ne passe jamais par la couleur seule. [F]
5. Mode sombre pris en charge ; ne pas coder en dur les valeurs RGB des couleurs système (utiliser les couleurs sémantiques). [F]

**Liquid Glass**
6. Le verre est réservé à la couche de navigation et aux contrôles : barres, boutons, feuilles. **Jamais dans la couche contenu : ni cartes à collectionner, ni grille, ni listes.** [F]
7. Pas de verre empilé sur du verre. Variante « clear » seulement sur photo ou vidéo, avec un voile noir de 35 % sur fond clair. [F]
8. Composants système d'abord : un contrôle natif obtient le verre sans effort. [F]

**Navigation et composants**
9. Barre d'onglets : ne jamais masquer ni désactiver un onglet ; éviter l'onglet « More ». [F] La caméra est une section, pas une action dans la barre. [I]
10. Titre de barre d'outils : moins de 15 caractères. [F]
11. Feuilles à deux hauteurs (medium environ la moitié, large) avec poignée. [F] Le choix des 3 espèces est une feuille. [I]
12. Contrôle segmenté : environ 5 segments au maximum sur iPhone. Menu contextuel : 3 groupes au maximum. [F]
13. Pas de popover sur iPhone en vue compacte : utiliser une feuille. [F]
14. Un seul bouton proéminent par écran (paywall compris). [F]

**Icônes et symboles**
15. SF Symbols pour toute l'interface, aucun emoji (règle projet). Icône d'app 1024 x 1024 px, créée avec Icon Composer (icône Liquid Glass). [F]
16. Images en @2x et @3x. [F]

**Parcours**
17. Onboarding minimal : ne demander une permission qu'au moment où le besoin est évident, avec une explication honnête ; un refus a toujours une voie de repli. [F]
18. Aucun écran de lancement décoratif ; l'app s'ouvre prête à servir. Décision d'équipe : ouverture directe sur la caméra. [F/I, voir `../decisions-produit.md`]
19. Demande de note (`requestReview`) : 3 par 365 jours au maximum, 1 à 2 semaines entre deux ; jamais après une erreur. [F]
20. Haptiques et animations : sobres, respecter « Réduire les animations ». [F]

## 2. Règles de revue App Store qui touchent le design (guidelines mises à jour le 8 juin 2026)

- 2.1 : l'app doit fonctionner sans poisson sous la main pour le relecteur. Prévoir « Essayer avec une photo d'exemple » et des images de test dans les notes de revue.
- 3.1.2 : abonnement avec « Restaurer », montant facturé le plus visible, liens conditions et confidentialité.
- 4.x : composants natifs, pas de copie d'une autre app, minimum de fonctionnalité.
- 5.1.1 : chaînes d'usage précises (caméra, photos, localisation), cohérentes avec les étiquettes de confidentialité.
- 5.2.1 : aucune référence à Pokémon ou Pokédex.
- SDK : Xcode 26 ou plus récent, iOS 26 (exigé depuis le 28 avril 2026). Aucune exigence Xcode 27 lue : revérifier avant l'envoi.

## 3. Ce que le jury valorise probablement [I]

Une app qui se sent native (composants système, Liquid Glass bien placé), une seule idée lisible en quelques secondes, un usage réel du matériel Apple (caméra, intelligence sur l'appareil), de l'accessibilité et un état de finition soigné. Les Apple Design Awards ne publient aucune grille ; les plus proches de nous parmi les gagnants 2026 lus : Tide Guide (visuels), Moonlitt (interaction). Détail : `04-principes-et-videos.md`.

## 4. Contradictions possibles avec notre existant à contrôler

- Maquettes `peche/maquettes/` : textes sous 11 pt, cibles sous 44 pt, verre sur contenu, contrastes. À faire passer par `evaluateur-design` avant de choisir la direction.
- Paywall : un seul bouton proéminent ; pas de sélecteur d'offre qui en crée deux.
- Succès, bestiaire et autres écrans : jamais de dépendance à la couleur seule pour la rareté (libellé texte obligatoire).
- Titres de toolbar de plus de 14 caractères : à raccourcir.

## 5. Ce qui reste à vérifier à la main (⚠)

Marges latérales et tailles d'écran iPhone, tracking, valeurs RGB système (tableaux vides à la lecture) ; pages `get-started`, `design-principles`, `designing-for-ios`, `branding`, `adopting-liquid-glass` non lues ; numéros de version de SF Symbols et des kits (incohérents sur la page Apple) ; noms d'API SwiftUI cités de mémoire dans `01-foundations.md`.
