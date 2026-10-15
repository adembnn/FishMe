# Jury : niveaux 0, 1 et 2 du parcours de démo (13 oct. 2026)

Décision débloquée : quel niveau visuel sert de base au build SwiftUI, et quelles corrections passer avant.
Matériel ouvert un par un : niveau-0/planche.png, planche-k (capture, raretes), les 21 PNG de ecrans/lot-1 à lot-3, les 10 PNG de niveau-1 et les 10 de niveau-2, plus les planches.
Une note simulée n'est pas une validation : ces chiffres ordonnent les corrections, ils ne prédisent rien sur le vrai jury.
Biais à connaître : le niveau 0 dispose de 21 écrans (rouge, espèce protégée, Live Activity, partage, amis), les niveaux 1 et 2 de 9 écrans plus les raretés. Ce que le niveau 0 montre en plus est noté comme un acquis transférable.

## Sources
- Catégories ADA : developer.apple.com/design/awards (2026), /2025, /2024 : Delight and Fun, Inclusivity, Innovation, Interaction, Social Impact, Visuals and Graphics.
- Lauréats qui comptent ici :
  - Tide Guide (2026, Visuals and Graphics) : Liquid Glass, animations sur mesure dans un thème aquatique, widgets puissants, palette qui suit la couleur du ciel au fil de la journée.
  - Guitar Wiz (2026, Inclusivity) : VoiceOver qui décrit tout, Dynamic Type, Increased Contrast, Differentiate Without Color.
  - Moonlitt (2026, Interaction) : utilitaire SwiftUI d'une « élégance simple » sur la lune, sœur de Sunlitt.
  - CapWords (2025, Delight) : on apprend le nom d'un objet en le photographiant, le geste de notre app.
  - Watch Duty (2025, Social Impact) : une information publique vitale, sourcée.
  - Art of Fauna (2025, Inclusivity) : planches animalières d'époque, VoiceOver complet, retour haptique.
  - Crouton (2024, Interaction) : « tout est là où on en a besoin ».
  - Oko (2024, Inclusivity) : retour haptique et sonore, VoiceOver et Dynamic Type sans faute.
- HIG, page Materials : « Don't use Liquid Glass in the content layer ». Le verre est réservé aux contrôles et à la navigation, avec parcimonie. Une teinte signale l'action principale (WWDC25, séance 219). La légende du verre doit rester lisible.
- Droit de la pêche (Legifrance) :
  - R436-13 : la pêche est permise jusqu'à une demi-heure après le coucher du soleil.
  - En 2e catégorie, le brochet reste ouvert jusqu'au dernier dimanche de janvier.

## 1. Notes /5 (justification = écran + élément)

| Critère | Niveau 0 (carte K, éditorial) | Niveau 1 (K + indices de jeu) | Niveau 2 (eau claire, Pokémon GO/Sleep) |
|---|---|---|---|
| ADA Delight and Fun | 3 : la lumière du soleil réel de 17 h 42 sur la carte (prise) fait mouche ; les codes TAI/FRQ/SAI refroidissent | 3 : tampon hexagonal « Peu commun » et 11 pastilles sous la carte (prise) ; la lumière solaire a disparu | 3,5 : barre « 3 sur 11 espèces +1 » (prise), bouchon et ronds dans l'eau (bredouille) ; c'est aussi le registre le plus attendu |
| ADA Inclusivity | 2 : libellés TAI/FRQ/SAI/CEN d'environ 9 pt dans la carte ; silhouettes du Pescedex (K2) à environ 1,4:1 ; rareté donnée par un pictogramme seul | 3 : rareté redondante (forme, 1 à 4 points, texte) ; rien sous 13 px ; mais la carte est une image muette pour VoiceOver | 3 : forme du badge, points et texte en capitales ; Nunito 900 lisible ; contraste sur le verre non mesuré |
| ADA Innovation | 3 : lumière calculée à l'heure de la prise (planche K), Live Activity S2/S3, l'IA propose et l'humain confirme (P2) | 2 : pas de Live Activity dans le parcours, lumière solaire retirée | 2 : même constat que le niveau 1 |
| ADA Interaction | 3 : une seule action par écran ; les noms « Silure » et « Barbeau » passent sous la barre d'onglets (K2) | 4 : barre d'action en verre avec le principal teinté vert, Sortie centré au pixel près | 3 : « Ranger » et « Partager » (prise) ont presque le même poids ; Sortie décalé de 30 px |
| ADA Social Impact | 4 : relâche obligatoire de la bouvière avec la consigne de remise à l'eau et l'arrêté de 1988 (P4) ; « Signaler une erreur » (P3) | 3 : pas d'écran rouge ni d'espèce protégée ; la source se réduit à « Règle nationale, indicative » | 3 : même constat que le niveau 1 |
| ADA Visuals and Graphics | 4 : planches de Bloch, gravure tirée du tracé de la Marne, plaque inclinée ; mais la carte C1 est grise et plate | 4 : la même face sombre gravée sur la prise, la bredouille et les vignettes, la cohérence la plus forte | 3 : dégradé bleu plein écran sur 9 écrans, cadre givré autour de chaque carte, identité générique |
| HIG Liquid Glass | 2 : aucun verre, barre d'onglets en pilule blanche opaque (conforme, mais absent) | 4 : verre limité aux contrôles, cartes opaques, action principale teintée | 2 : verre clair non teinté sur les actions principales, effet de verre dans le contenu (voir les correctifs) |
| MWM Problème clair | 4 : verdict plein écran « Garder possible » + Code de l'environnement (P3) | 3,5 : verdict clair, source amputée | 3,5 : même constat |
| MWM Premier moment utile | 3 : C1 n'annonce que « 3 espèces relevées par l'OFB », il faut toucher pour lire les noms ; A1 et A2 ajoutent 2 écrans et demandent la position avant la carte (contraire à E1) | 4 : la feuille du coin B nomme gardon, brochet et sandre avec leurs vignettes dès l'ouverture, sans toucher | 4 : même constat que le niveau 1 |
| MWM Raison de revenir | 3 : « 3 espèces sur les 11 », sans jauge, silhouettes pâles | 4 : 11 pastilles sur la prise et en tête du Pescedex | 4 : barre jaune « +1 » et « 1 sur 3 légendaires » |
| MWM Monétisation | 3 : le paywall (V1) montre la carte du joueur, avec Conditions, Confidentialité et Restaurer ; prix « à fixer » | 2 : le paywall montre une truite légendaire qui n'est pas au joueur ; pas de liens Conditions et Confidentialité ; prix « à fixer » | 2 : même constat que le niveau 1 |
| MWM Acquisition | 3 : image de partage 9:16 avec le code « 7K2 M9Q » (K4) ; nom de l'app vide | 2 : simple bouton « Partager », aucun aperçu ni code | 2 : même constat |
| MWM Purpose | 3 : A1 « Où pêcher près de toi, et ce que tu peux garder » donne le quoi ; le pour qui est implicite, le pour quand manque | 1 : aucun écran ne formule la promesse | 1 : même constat |
| **Total ADA + HIG (/35)** | **21** | **23** | **19,5** |
| **Total MWM (/30)** | **19** | **16,5** | **16,5** |

Défaut commun aux trois niveaux : ils partent de l'illustration de Bloch, pas de la photo détourée du pêcheur. La carte des écrans recommandait l'option b de la décision 2 : la carte appartient au pêcheur. Un jury peut demander « où est ma photo ? ».

## 2. Correctifs classés par impact sur le jury

### Communs aux trois niveaux (à passer en premier, ils sont vérifiables par le jury)
- **C1. Heure légale fausse.** Sortie : « fin légale 18 h 54 = coucher du soleil » doit devenir **19 h 24**, puisque R436-13 permet de pêcher une demi-heure après le coucher. Le compte à rebours affiché à 17 h 42 passe de « 1 h 12 » à **« 1 h 42 »**. Même correction sur M1 (« 17 h à 18 h 54 ») et sur la Live Activity S2/S3. Une app dont tout le sujet est la règle ne peut pas se tromper de 30 minutes sur l'écran de démo.
- **C2. Date de fermeture du brochet.** Verdict et P3b : « Ouvert jusqu'au 25 janv. » doit devenir **« jusqu'au 31 janv. »** (dernier dimanche de janvier 2027, en 2e catégorie). Ajouter « 3 carnassiers par jour, dont 2 brochets ».
- **C3. Démo incohérente.**
  - Bredouille : « 0 prise, 1 h 39 sur l'eau », le 12 oct. de 17 h 16 à 18 h 55, désigne la même sortie que le brochet de 17 h 43. Dater la bredouille du **13 oct.**
  - Pescedex : « Sorties 1 » avec 4 cartes, que la planche K date de juin, septembre et avril. Afficher **« Sorties 4 »**.
- **C4. Délai avant la carte.** Entre la photo et la carte, la démo passe par 3 écrans (photo, verdict, prise), soit environ 35 s sur les 2 min. La carte des écrans (K1) prévoyait le verdict en bandeau au-dessus de la carte, et les trois niveaux ont déjà ce bandeau sur la prise. Faire passer le verdict seul à la carte au bout de **1,5 s**, sans bouton « Voir ma carte » : on gagne environ 6 s et un toucher.
- **C5. VoiceOver.** La carte rendue en image doit exposer un seul élément, avec le libellé « Brochet, 68 centimètres, peu commun, 84e centile de taille, garder possible ». Toutes les illustrations de poisson ont besoin d'un libellé d'espèce. Chaque silhouette doit se lire « Perche, pas encore attrapée ».

### Niveau 0
1. **C1 carte** : la feuille dit « 3 espèces relevées par l'OFB ». Afficher **« gardon, brochet, sandre » et 3 vignettes de 56 pt**, comme au niveau 1. Retirer A1 et A2 du parcours chronométré : E1 ouvre sur la carte sans demander la position.
2. **Carte K** :
   - remplacer TAI/FRQ/SAI/CEN par « Taille », « Fréquence » et « Centile de taille », et supprimer SAI (273 j, que personne ne sait lire) ;
   - porter les libellés à **11 pt minimum** au lieu d'environ 9 pt ;
   - écrire « Âge estimé » plutôt que « ≈ 4 ans ».
3. **K2 Pescedex** :
   - silhouettes #C9C9C9 sur #E4E6E7 (environ 1,4:1) : passer à **#7F8C93 (3:1 ou plus)** ;
   - ajouter **96 pt de marge basse**, pour que « Silure » et « Barbeau » ne passent plus sous la barre ;
   - ajouter **1 à 4 points** sous le pictogramme de rareté.
4. **Liquid Glass absent** :
   - utiliser le `TabView` natif d'iOS 26 et poser `.glassEffect()` sur la barre d'action ;
   - Sortie et les actions principales en `.buttonStyle(.glassProminent)` teinté **#1E7F4F**.
   L'ADA 2026 cite le verre de Tide Guide ; ici le verre ne coûte presque rien.
5. **Progression** : sous « 3 espèces » (K2) et sur la prise, ajouter **11 pastilles, dont 3 pleines**, celles du niveau 1. C'est la raison de revenir, rendue visible.

### Niveau 1
1. **Promesse** :
   - ajouter un écran 0 repris de A1 : « Où pêcher près de toi, et ce que tu peux garder. » ;
   - y ajouter une ligne qui dit pour qui et pour quand, par exemple « Au bord de l'eau, dès ta première sortie » ;
   - ajouter un titre de 34 pt et un seul bouton.
   Aujourd'hui, le critère Purpose de MWM n'a aucune prise.
2. **Paywall** :
   - remplacer la truite légendaire par **la carte brochet 84e du joueur** (valeur déjà obtenue) ;
   - ajouter **« Conditions · Confidentialité »**, exigés par la règle App Store 3.1.2 sur les abonnements ;
   - remplacer « Prix à fixer » par une vraie ligne « puis X €/mois ».
   Revoir aussi l'offre : faire payer « les règles de tous les départements », c'est faire payer une information légale. Mieux vaut vendre « les cartes et les raretés de toute la France », et laisser la règle gratuite.
3. **Source et cas rouges** :
   - fiche et verdict : remplacer « Règle nationale, indicative » par **« Code de l'environnement, art. R436 · Signaler une erreur »** ;
   - porter P3b (rouge, 52/60) et P4 (relâche obligatoire) du niveau 0 au style du niveau 1. C'est le meilleur argument Social Impact.
4. **Partage** : le bouton « Partager » doit ouvrir l'aperçu K4 du niveau 0, une image 9:16 avec un code d'invitation de 6 caractères en 48 pt.
5. **Accessibilité et barre** :
   - badges hexagonaux sans texte (verdict en haut à droite, vignettes du Pescedex) : `accessibilityLabel("Peu commun, palier 2 sur 4")`, et les points en `accessibilityHidden` ;
   - en-tête du Pescedex : mettre « 3 sur 11 · 1 sur 3 · 1 » dans un `ViewThatFits`, empilé à partir de la taille de texte AX3 ;
   - « Moi » seul à droite de Sortie : le passer en avatar en haut à droite.

### Niveau 2
1. **Verre mal teinté** : « Commencer une sortie », « Continuer », « Voir ma carte », « Ranger dans le Pescedex » et « Commencer l'essai gratuit » sont en verre clair. Ils ont le poids visuel de « Terminer » et « Partager ».
   - les principaux en `.glassProminent`, teinte **#157A4E**, texte blanc ;
   - les secondaires en `.glass` simple.
2. **Verre dans le contenu**, interdit par la HIG :
   - la rangée « Léa et Malo pêchent ici » (fiche) imite le verre sur un dégradé bleu vif ;
   - un liseré givré d'environ 6 px entoure les cartes de contenu (fiche, verdict, prise, bredouille).
   Passer à un fond opaque **#F6FDFF** avec un bord de 1 px **#D5E9F0**.
3. **Dégradé plein écran** (#CBEFF7 vers #2380AA, sur 9 écrans) :
   - fond uni **#EEF7FA** ;
   - réserver l'eau à la carte (C1) et à la fenêtre de la prise.
   Le dégradé fatigue, il pose un contraste incertain sous le verre et il rapproche l'app d'un clone de jeu de capture.
4. **Paywall** : mêmes corrections qu'au point 2 du niveau 1 (carte du joueur, Conditions et Confidentialité, prix, offre).
5. **Promesse et partage** : mêmes corrections qu'aux points 1 et 4 du niveau 1. Remplacer aussi les badges en capitales espacées de 12 pt (« PEU COMMUN ») par des minuscules de **13 pt semibold**, plus lisibles en grand texte.

## 3. Ce qu'auraient les lauréats ADA récents, et qu'aucun niveau n'a
1. **Un widget et une Live Activity dans le parcours** (les widgets cités pour Tide Guide 2026) :
   - « Fin légale dans 1 h 42 » sur l'écran verrouillé, déjà dessiné en S2/S3 au niveau 0 mais absent des 9 écrans ;
   - un widget d'accueil « dernière carte » (K6).
   ActivityKit et WidgetKit : environ 1 jour.
2. **Une palette pilotée par le vrai ciel** (Tide Guide, qui suit la couleur du ciel ; Moonlitt et Sunlitt) : étendre à toute l'app le calcul solaire de la carte K. La teinte du fond et de la carte C1 suit l'heure, et la bredouille de 18 h 55 passe en bleu crépuscule. Un port de SunCalc et une interpolation de `Color` : environ 0,5 jour.
3. **L'accessibilité complète de Guitar Wiz et d'Oko** :
   - VoiceOver sur chaque carte (C5) ;
   - `accessibilityDifferentiateWithoutColor`, qui affiche « 2/4 » à côté du badge ;
   - `colorSchemeContrast` en mode contraste accru, qui épaissit les filets ;
   - la Dynamic Type testée jusqu'à AX5.
   Environ 0,5 jour.
4. **Un retour haptique qui dit le verdict** (Oko, Art of Fauna) :
   - `sensoryFeedback(.success)` pour « Garder possible » et `.warning`, en double impulsion, pour « À relâcher » ;
   - la carte qui s'incline avec CoreMotion à la révélation, et un fondu seul si Réduire les animations est activé.
   On sent le verdict sans regarder l'écran, les mains mouillées. Environ 0,5 jour.

## 4. Recommandation
Le niveau 1 sert le mieux les deux grilles : verre conforme, premier moment utile sans toucher, progression visible et cohérence de la carte K (23/35 ADA, et le meilleur Interaction).
Il perd sur MWM faute de promesse, de partage et de paywall complet. Ces trois manques existent déjà au niveau 0 (A1, K4, V1), avec P3b, P4 et S2/S3 : on les reprend et on les recolorie, sans rien redessiner.
Le niveau 2 est écarté comme base : il fait jeu, mais c'est le registre le plus attendu, et il viole la HIG à deux endroits. Avant toute chose, corriger C1 à C3 dans les trois niveaux.
