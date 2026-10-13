# Les 20 parcours de Bredouille

Rédigé le 13 octobre 2026. Sources : `peche/00-DESCRIPTIF`, `02-design-produit-mvp`, `04-plan-build-lots`, `06-ux-capture-collection`, `09-ux-peche-exterieur`, maquettes v2 (8 écrans). **[F]** = exigence ou fait écrit dans ces documents ; **[I]** = choix ou estimation proposé ici, à valider.

Nouvelle information intégrée : l'app **s'ouvre directement sur la caméra** ; **un tap sur une proposition d'espèce confirme et enregistre la carte** ; budget de friction : **2 taps** de l'ouverture à la carte révélée (objectif de conception [F, 06 §4.1]) ; le test d'usage échoue au-delà de **4 taps ou 15 s** (E1 [F, 09]).

Statuts : **MVP** (entre dans la version soumise), **Optionnel** (si le temps le permet, voir « Ce qu'il faut couper en premier » dans `plan/SUIVI.md`), **V2** (hors des deux jours). Lots : voir `plan/lots/<code>.md`. Les taps sont comptés depuis l'écran précédent ; « T » = touche.

## Vue d'ensemble

| # | Parcours | Taps (cible) | Statut | Lots principaux |
|---|---|---|---|---|
| 1 | Premier lancement | 0 avant la caméra, +1 alerte caméra, +1 localisation | MVP | L13, L14, L28, L21 |
| 2 | Nouvelle prise | **2** | MVP | L14, L15, L16, L17, L7, L4 |
| 3 | Prise depuis la galerie | 3 | MVP | L14, L15, L16 |
| 4 | Photo d'exemple | 3 | MVP | L14, L24, L16 |
| 5 | Espèce incertaine | 2 (À identifier) à 8 (questionnaire) | MVP (version courte) | L8, L16, L30 |
| 6 | Espèce exotique ou protégée | 2 | MVP | L3, L4, L37, L34 |
| 7 | Modifier une carte | ≤ 3 | MVP (taille, relâché, espèce) | L29, L18 |
| 8 | Sortie de pêche | 1 (démarrer), 2 (ajouter), 2 (terminer) | MVP | L20, L14 |
| 9 | Bredouille | **2** | MVP | L20 |
| 10 | Collection | 2 | MVP | L18, L7 |
| 11 | Bestiaire du département | 2 (grille), +1 (fiche) | MVP (grille), Optionnel (fiches) | L18, L31 |
| 12 | Niveaux, succès, « Ma saison » | 2 | Optionnel | L32 |
| 13 | Partage d'une carte | **2** | MVP (statique) | L38 |
| 14 | Abonnement Pro (paywall doux 16e carte) | 1 pour fermer | Optionnel (décision ven. 10 h) | L22 |
| 15 | Siri, raccourcis, Action Button | 0 (voix) | Optionnel | L23 |
| 16 | Préparer (mode débutant) | 2 | Optionnel | L41 |
| 17 | Règles locales | 2 | MVP | L21, L34 |
| 18 | Carte des coins | 2 | Optionnel (stations) ; V2 (spots privés) | L19, L6, L35 |
| 19 | Rappel d'ouverture de saison | 2 (opt-in) | V2 (Optionnel si temps) | L36 |
| 20 | Profil et réglages | 2 | MVP (réduit) | L33, L21 |

## Détail par parcours

### 1. Premier lancement
- **Écrans** : caméra plein écran (écran d'ouverture) ; bandeau « carte responsable » non bloquant ; alerte système caméra ; alerte système localisation « en utilisation » au premier cliché ; sélecteur de département si refus.
- **Lots** : L13 (onglet caméra par défaut), L14 (permissions en contexte), L28 (bandeau, conseils de cadrage 3 fois), L21 (textes).
- **Friction** : **0 tap avant la caméra**, aucun compte, aucun écran de présentation [F, 06 principe 1, erreur 2]. Maximum **1 alerte système** avant la première carte hors alerte caméra (E3). Lancement à froid à une caméra active en **≤ 2 s** (E2).
- **Précisions** : la permission caméra est demandée sur la vue caméra ; la localisation au premier cliché avec une raison immédiate ; **aucune notification** demandée. « Carte responsable » : [I] bandeau de rappel (relâcher si la règle locale l'autorise, l'app ne dit jamais si une prise est légale) ; définition à confirmer.
- **Statut** : MVP.

### 2. Nouvelle prise
- **Écrans** : caméra → « Quelle espèce ? » (3 propositions) → révélation de la carte → partager / modifier.
- **Lots** : L14 (obturateur, original écrit avant analyse), L15 (identification), L8/L4 (pipeline, rareté), L16 (confirmation en un tap, révélation 2,5 s passable), L17 (carte, holo), L7 (enregistrement automatique), L38 (partage), L29 (modification).
- **Friction** : **2 taps** (obturateur, tap sur l'espèce) ; la carte s'enregistre sans autre action ; révélation passable par un tap ; « Partager » ajoute 2 taps ; « Modifier » reste facultatif et ne bloque jamais. Latence photo → 3 propositions : 4 s au maximum côté go/no-go (00), 2 s visées (E9).
- **Règles** : trois propositions, vocabulaire « probable » / « possible », jamais de pourcentage ; « Aucune de ces espèces » et « Je ne sais pas » toujours présents ; département mémorisé ; « relâché » coché par défaut, taille vide ; toast « Annuler » de 5 s.
- **Statut** : MVP.

### 3. Prise depuis la galerie
- **Écrans** : caméra → sélecteur système de photos (`PhotosPicker`) → propositions → révélation.
- **Lots** : L14, L15, L16.
- **Friction** : **3 taps** (bouton galerie, photo, espèce). **Aucune permission** Photos (le sélecteur tourne hors processus) [F, 04 L14].
- **Précisions** : [I] la date et le lieu de la prise peuvent différer de ceux de l'import ; la carte porte la date du jour sauf édition (L29) ; ne pas lire les métadonnées de position de la photo.
- **Statut** : MVP.

### 4. Photo d'exemple
- **Écrans** : caméra → feuille « Photo d'exemple » (3 ou 4 vignettes) → propositions → révélation ; aussi proposée sur l'écran « Je ne vois pas de poisson » et en Réglages → Mode démo.
- **Lots** : L14, L24 (images), L16 (NoFishView), L33 (mode démo).
- **Friction** : 3 taps (appui long sur l'obturateur ou lien, vignette, espèce).
- **Pourquoi** : le relecteur Apple n'a pas de poisson (R-07 [F, 04]) ; la photo d'exemple passe par la vraie chaîne d'identification, hors cache secret. Elle est décrite dans les notes de revue.
- **Statut** : MVP (indispensable à la soumission).

### 5. Espèce incertaine
- **Écrans** : « Quelle espèce ? » → « Aucune de ces espèces » → liste du département → questionnaire visuel (5 questions) → nouvelles propositions → révélation ; ou « Je ne sais pas » → carte « À identifier ».
- **Lots** : L8 (logique), L16 (boutons), L30 (liste, questionnaire, carte À identifier), L18 (affichage séparé).
- **Friction** : « Je ne sais pas » → carte À identifier : **2 taps** ; « Aucune » → questionnaire : ≤ **8 taps** et ≤ 30 s [I]. Jamais d'impasse [F, 06 principe 8].
- **Règles** : carte « À identifier » en silhouette, rareté inconnue, hors bestiaire et hors succès, à corriger plus tard (L29).
- **Statut** : MVP en version courte (liste + À identifier) ; le questionnaire visuel complet est la partie coupable.

### 6. Espèce exotique ou protégée
- **Écrans** : mêmes que le parcours 2, avec une carte au style différent et une mention.
- **Lots** : L3 (statuts), L4 (aucun palier), L37 (styles de carte), L34 (avertissement renforcé et lien fédération).
- **Friction** : 2 taps, comme une prise normale.
- **Règles** [F, 00 §5, 02 §2.3] : exotique envahissante (silure, poisson-chat, perche-soleil…) = carte « Exotique », sans rareté ni bonus ; protégée ou à statut (anguille, saumon, esturgeon…) = « À observer et relâcher », pas de rareté à chasser ; **aucun verdict légal**, jamais « tu peux la garder ».
- **Statut** : MVP (éthique, risques R-15 et R-17).

### 7. Modifier une carte
- **Écrans** : détail de carte → feuille de modification (taille, relâché, note) → correction d'espèce.
- **Lots** : L29, L18, L7.
- **Friction** : corriger l'espèce en **≤ 3 taps** et ≤ 15 s depuis la carte ouverte (E10) ; XP et photo conservés ; suppression avec toast « Annuler » et corbeille 30 jours (E16).
- **Statut** : MVP pour taille, relâché, espèce ; optionnel pour notes et conditions.

### 8. Sortie de pêche
- **Écrans** : puce « Sortie » sur la caméra (démarrer) → « Sortie en cours » (chrono, « Ajouter une prise » très grand, « Terminer ») → révélation des cartes ou carte bredouille.
- **Lots** : L20, L14 (emplacement de la puce), L7, L13.
- **Friction** : démarrer **1 tap** ; ajouter une prise = parcours 2 ; terminer **2 taps**, sans pop-up de confirmation. La sortie survit au redémarrage, chrono recalculé depuis l'heure de début (E15). Pas de position en arrière-plan (E12).
- **Statut** : MVP. Live Activity : V2 [F, 02 §3.2].

### 9. Bredouille
- **Écrans** : « Terminer la sortie » sans prise → carte « Eau calme » (illustration, citation) ; à la 5e : carte « Patience ».
- **Lots** : L20.
- **Friction** : **2 taps** depuis la caméra (Terminer, Terminer) [F, 06 §4.3].
- **Règles** : message doux, aucun rouge, aucune série brisée, aucun XP affiché ; durée minimale **20 minutes** (résolution proposée, SUIVI §5.1), une carte par sortie, une bredouille par jour au plus.
- **Statut** : MVP (c'est le cœur du pitch).

### 10. Collection
- **Écrans** : onglet Collection (grille, filtre par palier, entête « 12 sur 34 ») → détail de carte en zoom ; état vide soigné.
- **Lots** : L18, L7, L17.
- **Friction** : retrouver une carte en **2 taps** [F, 06 §4.3]. Cartes obtenues toujours visibles, même après expiration d'un abonnement (E13).
- **Statut** : MVP.

### 11. Bestiaire du département
- **Écrans** : Collection → segment Bestiaire (silhouettes grises tant que non obtenue, compteur) → fiche d'espèce.
- **Lots** : L18 (grille), L31 (fiches), L3, L2.
- **Friction** : 2 taps pour la grille, +1 pour la fiche.
- **Règles** : les silhouettes ne révèlent aucun spot ; les exotiques et protégées ont leur mention.
- **Statut** : MVP (grille) ; Optionnel (fiches).

### 12. Niveaux, succès, « Ma saison »
- **Écrans** : Profil → niveau et XP ; Succès (8) ; « Ma saison » (sorties, espèces, record, bredouilles).
- **Lots** : L32, L7, L20.
- **Règles** [F, 02 §2.5, 06] : XP indépendant de la rareté et de la taille ; série **par saison**, jamais quotidienne ; pas d'XP sur la révélation.
- **Friction** : 2 taps (onglet Profil, section).
- **Statut** : Optionnel. Le bilan annuel partageable (type « Wrapped ») est V2.

### 13. Partage d'une carte
- **Écrans** : révélation ou détail → « Partager » → feuille de partage iOS.
- **Lots** : L38, L17.
- **Friction** : **2 taps** (E20). Image 4:5 et 9:16 générée localement (marche en mode avion), **sans lieu précis ni EXIF** ; carte bredouille partageable aussi.
- **Statut** : MVP (statique). Vidéo de l'effet holo : V2.

### 14. Abonnement Pro (paywall doux à la 16e carte)
- **Écrans** : Collection après la 15e carte révélée → écran Pro (prix, essai 3 jours, date de renouvellement, « Plus tard », « Restaurer »).
- **Lots** : L22.
- **Friction** : fermeture en **1 tap** (E13). Jamais pendant capture, propositions, révélation ni sortie. Phrase obligatoire : « Tes cartes restent à toi, même sans abonnement ».
- **Règles** : grille gratuite proposée = **15 cartes**, bredouilles hors quota (SUIVI §5.2). Mode Famille : pas de paywall sans contrôle parental (E19).
- **Statut** : Optionnel ; décision go/no-go **vendredi 10 h** (R-06). Repli : `paywall = false`.

### 15. Siri, raccourcis, Action Button
- **Écrans** : aucun écran propre ; app ouverte sur la caméra par l'intent.
- **Lots** : L23 (+ L14 pour le bouton volume, qui n'est pas un intent).
- **Friction** : 0 tap (voix ou bouton).
- **Statut** : Optionnel ; le bouton volume (E5) est MVP et vit dans L14.

### 16. Préparer (mode débutant)
- **Écrans** : onglet Préparer → « Ma prochaine sortie » (espèces plausibles ce mois-ci, montage générique, matériel, sécurité, lien fédération).
- **Lots** : L41, L3, L5, L34.
- **Règles** : contenu embarqué, lisible hors ligne ; mention « indicatif » ; aucune promesse de capture ni verdict.
- **Statut** : Optionnel (maquette 7). Reformulation Foundation Models : V2.

### 17. Règles locales
- **Écrans** : Réglages ou fiche d'espèce → « Règles de pêche de mon département » → lien Safari vers la fédération + avertissement fixe.
- **Lots** : L21 (vue, textes), L34 (données, points d'entrée), L5 (fédérations).
- **Règles** [F, 00, 04] : « Cette application ne connaît pas les règles de pêche locales et ne dit jamais si une prise est légale. » Pas de verdict, pas de taille minimale, pas de date d'ouverture présentée comme ferme.
- **Friction** : 2 taps. Hors ligne : « disponible en ligne », sans pop-up d'erreur (E4).
- **Statut** : MVP.

### 18. Carte des coins
- **Écrans** : onglet Préparer → bouton « Carte » → stations de relevé OFB du département → fiche station ; (V2) mes spots privés floutés.
- **Lots** : L19, L6 (données), L35 (spots privés).
- **Règles** : libellé « Station de relevé scientifique, pas une recommandation de pêche ni un droit d'accès » ; jamais la position d'une prise.
- **Statut** : Optionnel (stations, 38 pour le 95 [F, 04]) ; spots privés V2.

### 19. Rappel d'ouverture de saison
- **Écrans** : ligne « Truite fario : ouverture dans N jours » ; réglage opt-in d'une notification locale.
- **Lots** : L36, L33.
- **Règles** : aucune notification push ; opt-in ; jamais pendant une sortie ; dates **indicatives** (2e samedi de mars en 1re catégorie [F, 02 §3.3]), avec renvoi à l'arrêté préfectoral.
- **Statut** : V2 (Optionnel si le temps le permet).

### 20. Profil et réglages
- **Écrans** : onglet Profil : niveau, département (sélecteur manuel), mode démo, mode gants, rappels, corbeille, sources, légal, « Restaurer les achats ».
- **Lots** : L33, L21, L7.
- **Règles** : aucun compte, donc aucune suppression de compte à prévoir [F, 09 plainte 8]. Mode gants : cibles agrandies, pas d'appui long.
- **Statut** : MVP (réduit : département, mode démo, légal).

## Matrice lot → parcours (vérification de couverture)

Chaque parcours a au moins un lot propriétaire : 1 (L28), 2 (L16), 3 (L14), 4 (L14), 5 (L30), 6 (L37), 7 (L29), 8 (L20), 9 (L20), 10 (L18), 11 (L31), 12 (L32), 13 (L38), 14 (L22), 15 (L23), 16 (L41), 17 (L34), 18 (L19), 19 (L36), 20 (L33).
