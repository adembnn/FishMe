# Modération : le circuit minimal conforme à la règle 1.2 d'Apple
Décision débloquée : valider le circuit de signalement (décision 5 du 19 oct.) ; la boîte fishme.app@gmail.com est lue par Titouan, Adem et Sullyvan (décidé le 19 oct.), condition de L21, L22, L23 et L24.
Lu le 19/10/2026 (règles App Review lues sur https://developer.apple.com/app-store/review/guidelines/ ; code `App/Amis/Signalement.swift`, CGU article 8).

## En bref
Image : un café avec un tableau d'affichage. La loi d'Apple demande un videur à l'entrée (filtre), un bouton pour dénoncer, un moyen de mettre quelqu'un dehors, et un numéro de téléphone du patron. Le patron doit décrocher. Ici, le patron est une équipe de trois qui lit une boîte mail chaque jour.

## Ce qu'Apple exige (règle 1.2)
Une app avec du contenu d'utilisateur doit avoir ([guidelines](https://developer.apple.com/app-store/review/guidelines/)) :
1. « A method for filtering objectionable material from being posted to the app » ;
2. « A mechanism to report offensive content and timely responses to concerns » ;
3. « The ability to block abusive users from the service » ;
4. « Published contact information so users can easily reach you ».
⚠ Le texte lu ne contient aucun chiffre en heures. **« Retrait sous 24 h » est l'engagement de FishMe** (CGU article 8, déjà publié), pas une exigence écrite d'Apple. Pour Apple c'est « timely » ; nous tenons 24 h parce que nous l'avons écrit aux utilisateurs.

## Le circuit retenu (choix 5 du 19 oct.)
| Étape | Qui | Ce qui se passe | Où dans le code |
|---|---|---|---|
| 1. Signaler | le pêcheur | menu « Signaler » sur chaque publication, commentaire, message, profil, carte de club ; motif dans une liste fermée, pas de texte libre | L21 à L24 |
| 2. Masquer | l'iPhone du signalant | le contenu disparaît tout de suite pour lui | L21 à L24 |
| 3. Alerter | l'app | e-mail prérempli (`mailto:`) à fishme.app@gmail.com avec l'identifiant de l'enregistrement et celui de l'auteur, **et le texte du message si c'est un message d'ami ou de club** ; un `Signalement` écrit en base publique, texte du message compris | `Signalement.swift` (à étendre) |
| 4. Lire | le référent de la semaine | lit la boîte et le tableau de bord chaque jour, y compris le week-end | voir plus bas |
| 5. Retirer | le référent de la semaine | supprime l'enregistrement dans le tableau de bord (base publique, recherche par `recordName`) | tableau de bord |
| 6. Bloquer | le pêcheur | « Bloquer l'auteur » : plus rien de lui chez le pêcheur (filtre local) | L21, L23, L24 |
| 7. Répondre | le référent de la semaine | écrit au signalant et à l'auteur si besoin (CGU article 14) | e-mail |

**Pas d'e-mail automatique.** Sans serveur, CloudKit n'envoie pas d'e-mail ; un e-mail automatique demande un petit service payant (budget : **oui**, à prévoir pour plus tard). `Signalement.url` ouvre donc un e-mail prérempli (`mailto:`) que le pêcheur doit envoyer lui-même, et seulement s'il a un compte dans Mail. Un pêcheur qui ferme l'écran n'envoie rien. La parade : le `Signalement` écrit en base publique est la trace sûre, et **l'écran ne dit « signalé, merci » que si l'écriture de l'enregistrement a réussi** ; hors ligne, le signalement attend dans une file locale rejouée à la reconnexion, et le contenu n'est pas masqué en silence. Le référent lit **deux** sources : la boîte et la liste des `Signalement` triée par date. Recommandation : garder le `mailto:` plus l'enregistrement ; change avec un budget : non.
**Message d'ami ou de club signalé** : ces messages vivent en zone partagée, que l'équipe ne peut pas lire. Le texte est donc joint au `mailto:` (l'utilisateur le voit et peut le modifier avant d'envoyer) et copié dans l'enregistrement `Signalement` (500 caractères au plus). Ce transfert volontaire est déclaré dans la politique de confidentialité et la CGU article 8 (`cgu-confidentialite.md`). ⚠ Si le tableau de bord ne permet pas de réserver la lecture de `Signalement` à l'équipe, ne pas copier le texte (`schema.md`, type 7). Change avec un budget : non.
Option : un abonnement `CKQuerySubscription` sur `Signalement` dans l'app installée sur l'iPhone du référent donne une alerte sur son téléphone ⚠ à vérifier (droits de lecture du rôle). Recommandation : à tester avec `latence.md` ; change avec un budget : non.
Option : un petit service qui envoie un vrai e-mail automatique (fonction hébergée). Recommandation : seulement si le volume dépasse ce qu'une équipe de trois lit ; change avec un budget : oui.

## Qui lit la boîte (décidé le 19 oct.)
- La boîte fishme.app@gmail.com est lue par **Titouan, Adem et Sullyvan**.
- Un référent par semaine, à tour de rôle : [référent de la semaine, à fixer par l'équipe]. Proposition de relais : Titouan, Adem, Sullyvan, puis on recommence. Si le référent est absent, l'un des deux autres le remplace ce jour-là.
- Réponse sous 24 h ; au moins une lecture par jour, week-end compris (le référent, ou son remplaçant).
- Accès au tableau de bord CloudKit : à donner aux trois (rôle à demander à MWM, voir `docs/reports/amis.md`, mise en place).
- Le test « signalement » de L23 vérifie qu'un e-mail et un enregistrement arrivent, et que la boîte est bien lue (un des trois répond à un signalement d'essai).
Recommandation : trois lecteurs et un référent par semaine, plutôt qu'un titulaire seul, pour tenir 24 h ; change avec un budget : non (du temps de personne).

## Le filtre à la saisie
- Où : légende, commentaire, message, surnom, nom de club. Refus à la saisie, message court (« ce mot n'est pas accepté »), pas de liste affichée.
- Comment : normaliser (minuscules, sans accents, tirets et espaces ignorés dans les mots collés, `0`→`o`, `1`→`i`, `3`→`e`, `@`→`a`), puis recherche par **mot entier** ; jamais par sous-chaîne (un mot de pêche peut contenir un fragment grossier).
- Source : la liste française « List of Dirty, Naughty, Obscene, and Otherwise Bad Words », licence CC-BY-4.0, attribution dans les Sources de l'app ([dépôt](https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words)). **Une seule liste, dans `Core`** (`MotsInterditsFR`), utilisée par L21, L22, L23 et L24. Pluriels et accords sont couverts par un second passage (forme sans « s » final) et un test. ⚠ Je n'ai pas relu la liste ; on enlève les faux positifs de pêche. Le fichier `docs/banc/mots-interdits.md` est une autre liste (le vocabulaire interdit dans les textes de l'app), il ne sert pas de filtre.
- Spécifique FishMe : un motif refuse tout texte qui ressemble à une coordonnée (deux nombres décimaux de 2 chiffres ou plus après la virgule, « lat », « lon »), un lien de carte (maps.google, google.fr/maps, bing.com/maps, g.co/maps, Plans, Waze, what3words) et une adresse précise. Raison : protéger la règle d'or, aucun coin exact public. Un pêcheur qui écrit « mon coin est au pont de X » n'est pas arrêté : on filtre les formats, pas le sens ; la parade est le signalement. Recommandation : ce motif en plus de la liste ; change avec un budget : non.
- Limites assumées : un filtre de mots n'arrête ni une image, ni une insulte déguisée. C'est le minimum de la règle 1.2, pas une garantie.

## Les motifs de signalement (liste fermée)
Contenu choquant ou violent · haine ou harcèlement · nudité ou contenu sexuel · cruauté envers un animal · pêche illégale (espèce protégée gardée, taille, période) · coin de pêche exact révélé · personne mineure ou photo sans accord · spam ou publicité · autre. Peu de texte, des icônes, conforme à la consigne d'Adem (écrans).

## Ce qu'on ne peut pas faire sans serveur
- Interdire à une personne d'écrire : CloudKit identifie par compte iCloud, pas de liste noire côté serveur. Une personne exclue crée un autre surnom. La sanction réelle est : suppression du contenu, du profil, mention dans la réponse. ⚠ À assumer dans la décision d'Adem. Change avec un budget : oui (un service qui vérifie une liste).
- Supprimer l'enregistrement d'un autre depuis l'app : impossible en base publique (seul le créateur). Tout retrait passe par le tableau de bord (`schema.md`).
- Vérifier l'âge : 15 ans minimum par déclaration, sans date de naissance (décidé le 19 oct.), sans contrôle technique.

## Ce qu'on ajoute plus tard, et ce que ça coûte
| Ajout | Effet | Coût | Change avec un budget |
|---|---|---|---|
| Analyse d'image de l'appareil (framework Apple `SensitiveContentAnalysis`) avant publication ⚠ à vérifier (droit à demander à Apple, réglage utilisateur) | refuse la nudité à l'envoi, y compris pour une photo importée de la galerie | 0 € ; 2 à 3 h de développement (estimation) | non |
| Masquage automatique à un seuil de signalements | retire vite | écarté par Adem le 19 oct. (brigadage possible) | non |
| Service d'e-mail automatique et liste noire | e-mail réel, sanction réelle | hébergement + développement | oui |
| Modération externe (prestataire) | 24 h / 7 j sans référent | contrat récurrent | oui |
| Réponse automatique au signalant | « reçu, traité sous 24 h » | aucun coût (estimation) | non |

## Ce que le référent tient (journal)
Date et heure du signalement · identifiant · motif · décision (retiré / maintenu) · heure du retrait · réponse envoyée. Un tableau partagé par les trois suffit. Ce journal prouve le délai de 24 h si Apple le demande.

## Pour la relecture d'Apple
Dans les notes pour la relecture : où signaler, où bloquer, l'adresse de contact, et l'engagement de retrait. Voir `juridique-et-risques.md`.
