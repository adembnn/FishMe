# Soumission App Store : check-list

Version du 12 oct., 17h. Tiré de `reports/app-store.md` (règles et sources) et `reports/eval-apple.md` (relecture simulée, refus R1 à R9).
Délai d'Apple : au moins 50 % des relectures en moins de 24 h, 90 % en moins de 48 h ([Apple](https://developer.apple.com/help/app-review/after-submitting-for-review/request-expedited-review)). Un refus coûte une file entière : on vise un seul tour.

## Check-list
| # | Point | Qui | Quand |
|---|---|---|---|
| 0 | Accès : contrat « Paid Apps Agreement » actif, 3 invitations avec l'accès « Certificates, Identifiers & Profiles », identifiant de l'app créé, capacités WeatherKit et achats intégrés, fiche créée avec un nom provisoire, statut de vendeur européen (DSA) | MWM (message dans `message-mwm.md`) | avant jeudi 9 h |
| 1 | Xcode 27.0, cible iPhone seulement | A | mercredi |
| 2 | Textes de fiche : nom (30 car.), sous-titre, mots-clés, description qui nomme les 5 départements, liens conditions et confidentialité dans la description | C | avant jeudi, dès que le nom existe |
| 3 | Pages web : confidentialité (MWM nommé pour le SDK) et assistance avec un vrai contact | C, validé par MWM | avant jeudi |
| 4 | Captures 6,9 pouces (1320 x 2868), prises sur le build TestFlight, sans fonction absente | B | jeudi 15 h 30 |
| 5 | Questionnaire d'âge : contenu d'utilisateurs non (E8 hors build), rien qui vise les enfants | C (rôle App Manager, sur le web) | jeudi 15 h 30 |
| 6 | Étiquettes « App Privacy » avec la liste de collecte de Spark Flash | C + MWM | jeudi 15 h 30 |
| 7 | Manifeste `PrivacyInfo.xcprivacy` (app et SDK) | A | jeudi, à T5 |
| 8 | Textes d'autorisation : caméra, position pendant l'usage ; import par le sélecteur système, sans accès à la photothèque | A | L0 |
| 9 | `ITSAppUsesNonExemptEncryption` = NON (à confirmer pour le SDK) | A | L0 |
| 10 | Abonnement : groupe, produit, prix (à fixer par Adem), essai « 1 mois » (Apple ne propose pas « 30 jours »), joint à la version | MWM ou A | avant jeudi 9 h |
| 11 | Notes pour le relecteur, en anglais : départements couverts, coordonnées d'un quai, chemin vers la photo d'exemple, chemin d'achat, vidéo de 60 s, avertissement légal | C | jeudi 14 h |
| 12 | Disponibilité France, droits sur le contenu tiers, sortie manuelle | MWM | jeudi |
| 13 | TestFlight : envoi du squelette à 10 h 30 (T4), du build final à 16 h | A | jeudi |
| 14 | Envoi à la relecture, puis demande de relecture accélérée par MWM ([formulaire](https://developer.apple.com/contact/app-store/?topic=expedite)) avec l'événement dans les notes | MWM | jeudi 16 h à 17 h 30 |
| 15 | Lecture de l'e-mail d'Apple dès 7 h et publication à la main | Adem | vendredi |

## Les refus probables et où on les corrige
| Refus (`reports/eval-apple.md`) | Règle | Correction | Lot |
|---|---|---|---|
| R1 le relecteur n'a pas de poisson, ne voit jamais la carte ni le paywall | [2.1](https://developer.apple.com/app-store/review/guidelines/#app-completeness) | bouton « essayer avec une photo d'exemple » (photo à nous) | L3 |
| R2 la liste fermée donne trois poissons pour une tasse | 2.1, 2.3.1 | choix « pas un poisson », message si le détourage ne trouve rien | L3, L4 |
| R3 plantage en démarrant une session hors de la fenêtre légale | 2.1 | dans la version suivante (E4), plage de dates sûre | L5 |
| R4 achat introuvable ou paywall incomplet | 3.1.1, 3.1.2 | produit joint, durée, prix et essai venus de StoreKit, liens, « Restaurer » | L6 |
| R5 partage entre amis non vérifiable seul | 1.2, 5.1.1(v) | E8 hors du build soumis, code retiré (pas de fonction dormante) | L8 |
| R6 météo sans mention Apple Weather | 5.2.5 | pas de météo dans le build soumis ; logo et lien partout ensuite | L7 |
| R7 la fiche promet plus que le build | 2.3.1, 2.3.3 | fiche écrite depuis le build ; ni « toute la France », ni amis, ni Siri | S1 |
| R8 rien à voir pour la position du relecteur | 2.1, 5.1.1(iv) | carte ouverte sur l'Île-de-France, choix du département, bandeau des départements couverts | L2 |
| R9 SDK qui collecte sans consentement | 5.1.1(ii) | écran de consentement avant le SDK ; refus = SDK éteint | L6 |

## Marques
« Pokémon » et « Pokédex » sont des marques de Nintendo : jamais dans la fiche, les captures, les notes ni l'app. « Pescedex », nom de la collection : risque faible (`reports/app-store.md` §2.4). Pas de cadre jaune ni d'effet holographique sur les cartes.
