# 02 - Patterns HIG (iPhone SwiftUI, iOS 26) - Bredouille

Base URL : https://developer.apple.com/design/human-interface-guidelines/{page}
Lecture : texte récupéré via l'endpoint JSON officiel `developer.apple.com/tutorials/data/design/human-interface-guidelines/{page}.json` (même contenu que les pages HTML, rendues en JS). Lu le 2026-10-13.
Lues intégralement : onboarding, launching, loading, entering-data, feedback, modality, privacy, managing-accounts, settings, offering-help, undo-and-redo, searching, ratings-and-reviews, apple-in-app-purchase, managing-notifications, playing-haptics, collaboration-and-sharing, charting-data.
Hypothèse produit : caméra d'abord, 2 taps, sans compte, hors ligne, permissions au bon moment, abonnement, partage de carte.

---
## 1. Onboarding  /patterns/onboarding
Règles dures
- Flux « rapide, fun et optionnel » ; vient APRÈS le launch.
- Enseigner par l'interactivité ; préférer des tips contextuels (TipKit) à un long tutoriel.
- Tutoriel : skippable, non re-présenté ensuite, retrouvable dans aide/réglages.
- Ne pas enseigner l'OS ; pas de mentions légales (l'App Store s'en charge).
- Reporter les réglages non essentiels ; défauts raisonnables.
- Permission : dans l'onboarding seulement si l'app ne marche pas sans ; sinon à la 1re utilisation de la fonction.
- Laisser essayer l'app avant de demander note ou achat.
- Embarquer le contenu : pas de téléchargement bloquant.
Pièges : slides passives ; paywall écran 1 ; splash long.
Pour Bredouille : aucun onboarding obligatoire ; ouvrir directement sur la caméra. Au plus 1 écran de valeur skippable. Apprentissage par TipKit. Modèle et données embarqués (hors ligne), zéro download au 1er lancement.

## 2. Launching  /patterns/launching
Règles dures
- Lancer instantanément (pas plus de « quelques secondes »).
- Launch screen iOS : quasi identique au 1er écran, sans texte (non localisé), sans logo/branding/pub, même orientation et apparence clair/sombre que l'appareil.
- Splash éventuel = début de l'onboarding.
- Restaurer l'état précédent (scroll, position).
Pièges : flash entre launch screen et 1er écran ; launch screen « artistique ».
Pour Bredouille : launch screen = fond uni de la couleur de la vue caméra, sans texte. Session caméra démarrée en asynchrone sans bloquer le 1er rendu. Restaurer dernier onglet / dernière carte.

## 3. Loading  /patterns/loading
Règles dures
- Montrer quelque chose au plus tôt (placeholders) ; sinon l'absence de contenu = bug perçu.
- Laisser faire d'autres actions pendant le chargement.
- Attente longue : contenu utile et estimation fidèle.
- Déterminé si durée connue, indéterminé sinon (progress-indicators).
Pour Bredouille : analyse d'une photo = indicateur avec libellé précis (« Lecture de la carte »), jamais écran bloquant ; l'utilisateur peut reprendre une photo. Le chemin principal n'a aucun spinner réseau (hors ligne).

## 4. Entering data  /patterns/entering-data
Règles dures
- Minimiser la saisie : récupérer du système, préremplir.
- Choix (picker, menu) plutôt que texte libre ; supporter coller et glisser-déposer.
- Valider dynamiquement ; Continuer actif seulement quand le requis est fourni.
- SecureField pour le sensible ; ne jamais préremplir un mot de passe.
Pour Bredouille : la caméra remplace la saisie ; corrections post-scan via pickers/steppers. Sans compte : aucun champ email/mot de passe.

## 5. Feedback  /patterns/feedback
Règles dures
- Feedback proportionné ; statut passif intégré près de l'objet ; alertes réservées à l'info critique et actionnable (trop d'alertes en réduisent l'impact).
- Combiner couleur + texte + son + haptique (VoiceOver, silencieux).
- Avertir seulement si perte de données inattendue ET irréversible ; confirmer les actions importantes ; expliquer pourquoi une commande est impossible.
Pour Bredouille : succès de scan = changement visuel + haptique success + label VoiceOver ; échec (flou, pas de carte) = message inline qui dit quoi corriger, pas d'alerte. Suppression : toast avec Annuler.

## 6. Modality  /patterns/modality
Règles dures
- Modal seulement avec bénéfice clair ; tâche simple, courte, linéaire ; pas d'« app dans l'app ».
- Plein écran pour caméra/photo/tâche multi-étapes.
- Fermeture évidente (bouton en haut ou swipe down sur iOS) ; titre nommant la tâche.
- Confirmer la fermeture si perte de contenu créé (action sheet avec Enregistrer).
- Jamais deux alertes simultanées ; laisser fermer une modale avant d'en présenter une autre.
Pour Bredouille : résultat de scan = sheet à détents au-dessus de la caméra ; paywall = sheet avec Fermer toujours visible ; une seule modale à la fois.

## 7. Privacy / demande de permissions  /patterns/privacy
(Pas de page `requesting-permissions` : 404. La règle est dans `privacy#Requesting-permission`.)
Règles dures
- Ne demander que le nécessaire, aussi spécifique que possible.
- Demander quand la fonction est utilisée ; pas au lancement sauf si indispensable et évident (ex. navigation = localisation).
- Purpose string : une phrase complète, active, spécifique, sentence case, point final. Bon : « The app records during the night to detect snoring sounds. » Mauvais : « Microphone access is needed for a better experience. » et « Turn on microphone access. »
- Écran pré-alerte : UN seul bouton titré « Continuer »/« Suivant » (jamais « Autoriser »), aucune option fermer/annuler (sauf consentement légal).
- Tracking (ATT) : jamais d'écran trompeur avant l'alerte (incitation, fausse alerte, image de l'alerte, annotation) = rejet App Review.
- LocationButton : autorisation ponctuelle sans ré-alerte.
- Traiter sur l'appareil ; secrets dans le Keychain ; pas d'auth maison.
Pièges : permission photos complète quand PhotosPicker suffit ; pré-écran avec « Plus tard ».
Pour Bredouille : caméra = indispensable à la fonction cœur, donc demande à l'ouverture de l'écran caméra acceptable. Pré-écran optionnel à 1 bouton « Continuer ». Refus = état vide explicatif + bouton vers Réglages + import via PhotosPicker (sans permission). Aucune autre permission (micro, localisation, notifs, ATT) ; pas de tracking. Texte suggéré : « Bredouille utilise la caméra pour lire votre carte. »

## 8. Managing accounts  /patterns/managing-accounts
Règles dures
- Compte seulement si la fonction cœur l'exige ; retarder la connexion le plus possible.
- Sinon : Sign in with Apple, ou passkey ; nommer la méthode (« Se connecter avec Face ID ») ; pas de réglage biométrique propre à l'app ; ne pas dire « passcode ».
- Si création de compte in-app : suppression in-app obligatoire (pas désactivation), prévenir de la date de fin, expliquer que l'abonnement Apple continue après suppression.
Pour Bredouille : aucun compte ; l'achat s'appuie sur l'Apple ID (StoreKit, Restaurer les achats). Pas de suppression de compte à construire. Sync éventuelle via iCloud sans login propre.

## 9. In-App Purchase / abonnement  /technologies/apple-in-app-purchase
(Pas de page patterns/in-app-purchase : 404.)
Règles dures
- IAP = biens virtuels et abonnements ; Apple Pay = biens physiques.
- Laisser essayer avant d'acheter (freemium, paywall mesuré, essai gratuit).
- Prix total facturé affiché pour chaque offre ; noms courts sans troncature ; boutique au style de l'app.
- Feuille de confirmation système : ne pas la modifier ni la répliquer.
- Écran d'inscription : nom, durée et contenu de l'abonnement ; montant localisé ; connexion/restauration des achats ; liens CGU et confidentialité.
- Prix d'intro : prix intro + durée + prix standard ensuite. Essai gratuit : dire qu'un paiement démarre automatiquement à la fin.
- Montrer la valeur dès l'onboarding ; inviter aux moments pertinents (proche de la limite gratuite) ; ne pas proposer à un abonné.
- Lien d'inscription aussi dans Réglages ; résumé avec date de renouvellement ; gestion via showManageSubscriptions ; annulation toujours facile.
- Masquer la boutique si paiements impossibles (canMakePayments).
- Remboursement : bouton simple « Request a Refund » sans barrière.
- Family Sharing : jusqu'à 5 membres supplémentaires.
Pièges : prix mensuel équivalent plus gros que le total facturé ; annulation enfouie ; Fermer caché.
Pour Bredouille : gratuit = scans limités (compteur discret) ; paywall à la limite, jamais avant le 1er scan réussi ; sheet avec Fermer visible ; total facturé en gros, équivalent mensuel en petit ; Restaurer + CGU + confidentialité ; ligne Abonnement dans Réglages. SubscriptionStoreView conforme par défaut.

## 10. Offering help  /patterns/offering-help
Règles dures
- Aide liée à la tâche en cours, facile à ignorer ; ne pas expliquer les composants standards.
- Tip TipKit : 1-2 phrases, actionnable, non promotionnel ; plus de 3 actions = trop complexe pour un tip ; règles d'éligibilité ; cadence ex. une fois par 24 h ; popover pour préserver le flux, inline pour garder le contexte visible ; symbole rempli.
- Bouton dans le tip pour mener aux réglages ou à plus d'info.
Pour Bredouille : 2-3 tips max (cadrage de la carte, partage, historique), cadence 24 h, éligibilité par événement. Un écran Aide/FAQ dans Réglages ; pas de tutoriel.

## 11. Settings  /patterns/settings
Règles dures
- Défauts optimaux ; minimiser le nombre de réglages ; ne pas dupliquer les réglages système (accessibilité, auth).
- Réglages généraux rarement modifiés dans l'app ; options liées à une tâche dans l'écran concerné ; très rares options dans l'app Réglages système + bouton qui l'ouvre.
Pour Bredouille : Réglages minimal : Abonnement, Haptique on/off, Aide, À propos, Restaurer, lien Réglages système (caméra). Pas de réglage de thème. Flash/zoom sur l'écran caméra.

## 12. Undo and redo  /patterns/undo-and-redo
Règles dures
- Résultat prévisible (« Annuler X ») et visible (scroller vers l'élément restauré) ; pas de limite arbitraire.
- Boutons undo/redo seulement si nécessaire (symboles système, barre d'outils) ; iOS : ne pas redéfinir shake ou trois doigts.
Pour Bredouille : UndoManager sur suppression/édition de cartes ; toast « Carte supprimée - Annuler » ; ne pas détourner le shake.

## 13. Searching  /patterns/searching
Règles dures
- Si centrale : place primaire (barre du bas ou onglet Recherche) ; un seul point d'entrée ; scope visible ; suggestions et récents effaçables (vie privée) ; Spotlight via métadonnées.
Pour Bredouille : `.searchable` sur l'historique, indexation Core Spotlight locale des cartes ; pas de recherche web.

## 14. Ratings and reviews  /patterns/ratings-and-reviews
Règles dures
- Demander après engagement démontré (tâche significative) ; jamais au 1er lancement ni dans l'onboarding ni pendant une tâche.
- Au moins une à deux semaines entre demandes.
- Prompt système (RequestReviewAction) : le système limite à 3 affichages par app sur 365 jours.
Pour Bredouille : requestReview après 5e scan réussi (ex.) et retour à l'écran calme, jamais juste après un échec ni sur le paywall.

## 15. Playing haptics  /patterns/playing-haptics
Règles dures
- Patterns système selon leur sens documenté ; cohérence cause-effet ; complément des autres feedbacks.
- Courts, pour événements discrets ; ne pas abuser ; options désactivables ; app utilisable sans.
- iOS : composants standards (toggle, slider, picker) jouent déjà leur haptique ; générateurs Notification / Impact / Selection.
- Attention : une vibration peut perturber caméra, gyroscope, micro.
Pièges : haptique pendant la capture (flou) ; même motif pour succès et échec.
Pour Bredouille : un seul haptique success à la détection (sensoryFeedback), jouer après verrouillage de la capture, pas pendant ; échec = notification warning ; réglage Haptique on/off.

## 16. Managing notifications  /patterns/managing-notifications
Règles dures
- Permission obligatoire avant toute notification ; niveaux : Passive, Active (défaut), Time Sensitive (événement dans l'heure), Critical (entitlement).
- Marketing : opt-in explicite, jamais Time Sensitive ; réglage in-app pour changer le choix.
Pour Bredouille : aucune notification en v1, donc aucune permission.

## 17. Collaboration and sharing  /patterns/collaboration-and-sharing
Règles dures
- Bouton Partager bien placé (barre d'outils) ; en SwiftUI : ShareLink (feuille de partage système).
- Si collaboration : bouton Collaboration, résumés de permissions succincts, liens universels.
Pour Bredouille : ShareLink avec image de la carte rendue (+ texte), dans la barre d'outils du résultat ; 1 tap pour partager ; fonctionne hors ligne (image générée localement) ; pas de collaboration ni SharePlay.

## 18. Charting data  /patterns/charting-data
Règles dures
- Graphique pour mettre en valeur une info clé ; garder simple, détails à la demande ; types courants (barres, lignes) ; texte descriptif (titre, annotations) ; cohérence entre graphiques.
- Accessibilité obligatoire : labels et éléments d'accessibilité (voir charts).
Pour Bredouille : Swift Charts seulement pour stats d'historique ; chaque graphique avec résumé textuel et accessibilityLabel.

---
## Limites et ⚠ non lu
- ⚠ `requesting-permissions` et `in-app-purchase` : pages patterns inexistantes (404). Contenu équivalent lu dans `privacy` et `apple-in-app-purchase`.
- ⚠ `navigation` n'est pas un pattern (c'est le composant `navigation-and-search`) : non lu ici, voir 03-components.md.
- ⚠ Lus partiellement (extraits tronqués à la lecture, plusieurs lignes coupées) : file-management, going-full-screen, drag-and-drop, generative-ai. Retenir seulement : pas de sauvegarde manuelle (autosave) ; plein écran = contrôles essentiels accessibles, laisser l'utilisateur choisir de sortir ; drag-and-drop = prévoir une alternative et l'annulation, drag image dès 3 points ; IA générative = transparence, garder le contrôle, expérience correcte sans IA, modèle sur appareil = hors ligne et privé. Bredouille n'a pas de fichiers, de drag-and-drop ni d'IA générative prévus.
- ⚠ Chiffres non fournis par Apple dans ces pages : délai de lancement exact, durée de loader, détents de sheet. Ne pas inventer.
- Les images/schémas des pages ne sont pas lus (texte uniquement).
