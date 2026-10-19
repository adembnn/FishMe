# Modération : le circuit minimal conforme à la règle 1.2 d'Apple
Décision débloquée : valider le circuit de signalement et nommer qui lit fishme.app@gmail.com, condition de L21, L22, L23 et L24 (décision 5 du 19 oct.) ; sans ce nom la fiche R2 n'est pas finie.
Lu le 19/10/2026 (règles App Review lues sur https://developer.apple.com/app-store/review/guidelines/ ; code `App/Amis/Signalement.swift`, CGU article 8).

## En bref
Image : un café avec un tableau d'affichage. La loi d'Apple demande un videur à l'entrée (filtre), un bouton pour dénoncer, un moyen de mettre quelqu'un dehors, et un numéro de téléphone du patron. Le patron doit décrocher. Ici, le patron est une personne qui lit une boîte mail chaque jour.

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
| 3. Alerter | l'app | e-mail prérempli à fishme.app@gmail.com avec l'identifiant de l'enregistrement et celui de l'auteur ; un `Signalement` écrit en base publique | `Signalement.swift` (à étendre) |
| 4. Lire | la personne de garde | lit la boîte et le tableau de bord chaque jour, y compris le week-end | voir plus bas |
| 5. Retirer | la personne de garde | supprime l'enregistrement dans le tableau de bord (base publique, recherche par `recordName`) | tableau de bord |
| 6. Bloquer | le pêcheur | « Bloquer l'auteur » : plus rien de lui chez le pêcheur (filtre local) | L21, L23, L24 |
| 7. Répondre | la personne de garde | écrit au signalant et à l'auteur si besoin (CGU article 14) | e-mail |

⚠ **Écart avec la décision 5 : l'e-mail n'est pas automatique.** Sans serveur, CloudKit n'envoie pas d'e-mail. `Signalement.url` ouvre un e-mail prérempli (`mailto:`) que le pêcheur doit envoyer lui-même, et seulement s'il a un compte mail dans Mail. Un pêcheur qui ferme l'écran n'envoie rien. La parade du circuit : le `Signalement` écrit en base publique est la trace sûre ; la personne de garde lit donc **deux** sources : la boîte et la liste des `Signalement` triée par date. Recommandation : garder le `mailto:` plus l'enregistrement ; change avec un budget : non.
Option : un abonnement `CKQuerySubscription` sur `Signalement` dans l'app installée sur l'iPhone de la personne de garde donne une alerte sur son téléphone ⚠ à vérifier (droits de lecture du rôle). Recommandation : à tester avec `latence.md` ; change avec un budget : non.
Option : un petit service qui envoie un vrai e-mail automatique (fonction hébergée). Recommandation : seulement si le volume dépasse ce qu'une personne lit ; change avec un budget : oui.

## Qui lit la boîte
- Personne de garde (titulaire) : [à renseigner par Adem].
- Remplaçant (absence, vacances, week-end) : [à renseigner par Adem].
- Horaire de lecture : [à renseigner par Adem]. Contrainte : au moins une lecture par jour, tous les jours, pour tenir 24 h.
- Accès au tableau de bord CloudKit de l'identifiant du conteneur : [à renseigner par Adem] (rôle à demander à MWM, voir `docs/reports/amis.md`, mise en place).
- Aucun nom n'est inventé ici. Le lot L23 ne passe pas son test « signalement » tant que ces trois lignes sont vides, car le test vérifie qu'un e-mail arrive chez quelqu'un qui le lit.
Recommandation : deux personnes nommées, pas une ; un titulaire seul est le point faible de la promesse de 24 h ([CGU article 8](docs/legal/conditions-fishme.md)). Change avec un budget : non (du temps de personne).

## Le filtre à la saisie
- Où : légende, commentaire, message, surnom, nom de club. Refus à la saisie, message court (« ce mot n'est pas accepté »), pas de liste affichée.
- Comment : normaliser (minuscules, sans accents, tirets et espaces ignorés dans les mots collés, `0`→`o`, `1`→`i`, `3`→`e`, `@`→`a`), puis recherche par **mot entier** ; jamais par sous-chaîne (un mot de pêche peut contenir un fragment grossier).
- Source de départ : la liste française « List of Dirty, Naughty, Obscene, and Otherwise Bad Words », licence CC-BY-4.0, attribution à ajouter dans Sources ([dépôt](https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words)). ⚠ Je n'ai pas relu la liste ; L23 la lit et enlève les faux positifs de pêche. Le fichier `docs/banc/mots-interdits.md` est une autre liste (le vocabulaire interdit dans les textes de l'app), il ne sert pas de filtre.
- Spécifique FishMe : un motif refuse tout texte qui ressemble à une coordonnée (deux nombres décimaux de 3 chiffres ou plus après la virgule, « lat », « lon »), un lien de carte (Google Maps, Plans, Waze, what3words) et une adresse précise. Raison : protéger la règle d'or, aucun coin exact public. Un pêcheur qui écrit « mon coin est au pont de X » n'est pas arrêté : on filtre les formats, pas le sens ; la parade est le signalement. Recommandation : ce motif en plus de la liste ; change avec un budget : non.
- Limites assumées : un filtre de mots n'arrête ni une image, ni une insulte déguisée. C'est le minimum de la règle 1.2, pas une garantie.

## Les motifs de signalement (liste fermée)
Contenu choquant ou violent · haine ou harcèlement · nudité ou contenu sexuel · cruauté envers un animal · pêche illégale (espèce protégée gardée, taille, période) · coin de pêche exact révélé · personne mineure ou photo sans accord · spam ou publicité · autre. Peu de texte, des icônes, conforme à la consigne d'Adem (écrans).

## Ce qu'on ne peut pas faire sans serveur
- Interdire à une personne d'écrire : CloudKit identifie par compte iCloud, pas de liste noire côté serveur. Une personne exclue crée un autre surnom. La sanction réelle est : suppression du contenu, du profil, mention dans la réponse. ⚠ À assumer dans la décision d'Adem. Change avec un budget : oui (un service qui vérifie une liste).
- Supprimer l'enregistrement d'un autre depuis l'app : impossible en base publique (seul le créateur). Tout retrait passe par le tableau de bord (`schema.md`).
- Vérifier l'âge : l'app est faite pour les 15 ans et plus (CGU article 2), sans contrôle technique.

## Ce qu'on ajoute plus tard, et ce que ça coûte
| Ajout | Effet | Coût | Change avec un budget |
|---|---|---|---|
| Analyse d'image de l'appareil (framework Apple `SensitiveContentAnalysis`) avant publication ⚠ à vérifier (droit à demander à Apple, réglage utilisateur) | refuse la nudité à l'envoi | 0 € ; 2 à 3 h de développement (estimation) | non |
| Masquage automatique à un seuil de signalements | retire vite | écarté par Adem le 19 oct. (brigadage possible) | non |
| Service d'e-mail automatique et liste noire | e-mail réel, sanction réelle | hébergement + développement | oui |
| Modération externe (prestataire) | 24 h / 7 j sans personne de garde | contrat récurrent | oui |
| Réponse automatique au signalant | « reçu, traité sous 24 h » | aucun coût (estimation) | non |

## Ce que la personne de garde tient (journal)
Date et heure du signalement · identifiant · motif · décision (retiré / maintenu) · heure du retrait · réponse envoyée. Un tableau partagé suffit. Ce journal prouve le délai de 24 h si Apple le demande.

## Pour la relecture d'Apple
Dans les notes pour la relecture : où signaler, où bloquer, l'adresse de contact, et l'engagement de retrait. Voir `juridique-et-risques.md`.
