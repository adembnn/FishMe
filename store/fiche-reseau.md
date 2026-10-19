# Fiche App Store de FishMe : version qui porte le réseau social (S2)

**Brouillon, à relire par Adem ; les textes juridiques cités sont des brouillons à faire relire par un juriste de MWM.** Écrit par S2 le 19 octobre 2026 pour la version de la vague 2 (L21 à L24 fusionnées). Il complète `fiche-fishme.md` (S1, version du 16 octobre, sans réseau) : tout ce qui n'est pas repris ici reste comme dans S1 (nom, sous-titre, catégorie, mots-clés, texte promo). Écrit depuis les fiches de lots, pas depuis un build : une phrase dont la fonction n'est pas à l'écran dans le build TestFlight sort du texte (refus R7). Rien n'est écrit au futur. Les captures sont à refaire par A quand L23 est dans le build (`docs/app-store.md`, ligne 4) ; S2 n'en produit aucune.

Légende : **[?]** = à lire dans le build. Les crochets `[...]` sont à remplir ; aucun n'est inventé.

## Ce qui change par rapport à S1
| Champ | Valeur | Longueur |
|---|---|---|
| Nouveautés | voir ci-dessous | 186 car., 192 octets (limite 4000 car.) |
| Description | S1 + bloc « LA COMMUNAUTÉ » + deux lignes changées | 3838 car., 3945 octets avec les crochets non remplis (limite 4000 car.) |
| Connexion requise | Non (pas de mot de passe) ; le relecteur doit avoir iCloud connecté pour publier, c'est dit dans les notes | |
| Notes pour le relecteur | `notes-relecteur-reseau-en.md` | 3362 octets (limite 4000) |
| Confidentialité, âge | `app-privacy.md` | |
| Classement par âge | à rejouer (contenu d'utilisateur : oui) ; plus de « 4+ » | [à lire dans App Store Connect] |

Longueurs comptées par Python (`len()` en caractères, `len(.encode("utf-8"))` en octets), espaces compris. **Marge : 162 caractères.** `[COUVERTURE]` et les deux URL du texte seront plus longs une fois remplis : recompter avant de coller, et si ça dépasse, raccourcir « LE PESCEDEX » ou « FISHME PRO », pas la communauté.

### Nouveautés
```
Nouveau : la communauté. Crée ton profil (15 ans et plus), publie tes prises en choisissant le lieu affiché, aime, commente, écris à tes amis et à tes clubs. Signaler et bloquer partout.
```

## Description (réseau inclus)
Les changements par rapport à S1 : le bloc « LA COMMUNAUTÉ » ; « GRATUIT POUR TOUJOURS » cite la communauté ; « Aucun compte, aucune publicité » devient « Pas de mot de passe : ton compte est ton identifiant Apple. Aucune publicité » (avec un surnom public, « aucun compte » serait faux).

```
FishMe est l'app de pêche en eau douce qui te montre où pêcher, quels poissons y vivent et quelles règles s'y appliquent, puis transforme chacune de tes prises en carte à collectionner.

LA CARTE
- Autour de toi, les poissons relevés par l'Office français de la biodiversité (OFB), en images, avec le nombre de pêches et l'année du dernier relevé.
- Touche un coin : ses espèces et leur rareté dans le département, les conditions du moment (vent, pluie, pression, aube, crépuscule) et la jauge de la rivière.
- Les règles du jour en lignes courtes : taille, quota, ouverture. La source et la citation de chaque règle s'ouvrent d'un toucher.
- Règles couvertes : le socle national partout, et les règles locales de [COUVERTURE]. Ailleurs, l'app le dit et donne le lien de la préfecture.
- Une vigilance orage ou crue s'affiche en haut de la carte.

LA SESSION
- Lance une session : chrono, heure de fin légale, tes prises du jour, et une carte « à essayer » (appât, hameçon, technique) pour les espèces ouvertes.
- Photographie ta prise : l'app propose 3 espèces en images, sans aucun pourcentage, et c'est toi qui choisis. « Autre espèce » ouvre toutes les espèces de France en images ; « Pas un poisson » est toujours là.
- Pose ton poisson sur ta toise : l'app lit la graduation et tu confirmes la taille. Le poids est estimé à partir de la longueur, et marqué comme tel.

LE PESCEDEX
- Chaque prise confirmée devient une carte : au recto le poisson, sa rareté (commune, peu commune, rare, légendaire) et sa taille ; au dos ta vraie photo et les conditions du moment.
- Les cartes rares et légendaires ont un reflet qui suit l'inclinaison de ton iPhone.
- Toutes les espèces pêchables en France, en images, avec ton compteur pour ta zone.
- Au premier lancement, glisse les espèces que tu as déjà pêchées : elles entrent au Pescedex comme cartes déclarées, à part de tes vraies prises.
- Rentré bredouille ? Tu reçois quand même ta carte de sortie.
- Partage une image de ta carte : jamais ton coin exact.

LA COMMUNAUTÉ (15 ans et plus)
- Crée ton profil avec un surnom et un avatar, publics.
- Publie une photo ou une vidéo de 15 secondes, et choisis à chaque fois le lieu affiché : le cours d'eau et le département, le département seul, ou aucun lieu. Jamais de coordonnée.
- Aime et commente, écris à tes amis et dans les clubs dont tu es membre.
- Signale ou bloque une publication, un commentaire, un message ou une personne. Un contenu signalé qui enfreint les conditions est retiré sous 24 heures.
- Ta collection n'est jamais publique.

GRATUIT POUR TOUJOURS
La carte, les règles, ton Pescedex et la communauté. Un spot gratuit (un cercle de 1 km) avec des sessions illimitées, et sur ce spot la météo du jour et le niveau de l'eau. Le premier conseil de chaque espèce. Les alertes orage et crue, partout.

FISHME PRO
Des sessions sur d'autres spots, la météo sur 7 jours heure par heure, la courbe de la rivière sur 48 h, « Préviens-moi », tous les conseils de chaque espèce et « Tes conditions » après 10 sorties.
L'abonnement se renouvelle automatiquement, sauf résiliation au moins 24 heures avant la fin de la période, dans les réglages de ton compte Apple. Tu peux restaurer tes achats dans l'app.

RESPECTUEUX
- Pas de mot de passe : ton compte est ton identifiant Apple. Aucune publicité. Tes coins de pêche exacts ne quittent jamais ton iPhone, et tes photos sont enregistrées sans position GPS.
- L'IA ne décide jamais si un poisson peut être gardé : elle propose l'espèce, tu confirmes, la règle sourcée s'affiche.

IMPORTANT
Les règles affichées sont indicatives : l'arrêté préfectoral fait foi. Vérifie aussi les panneaux sur place. En cas de doute, relâche.

Données : OFB et Hub'Eau (Licence Ouverte 2.0). Météo : Apple Weather.
Conditions d'utilisation : [URL_CONDITIONS]
Confidentialité : [URL_CONFIDENTIALITE]
```

### Qui prouve quoi (les lignes nouvelles ; celles de S1 restent)
| Phrase | Source dans le plan | État |
|---|---|---|
| Profil avec surnom et avatar, publics | décision 3 du 19 oct., L21 | à voir à l'écran [?] |
| Photo ou vidéo de 15 secondes | décision 4, L23 | à voir [?] ; si la vidéo est repoussée (R2, `quota.md`), retirer « ou une vidéo de 15 secondes » |
| Lieu choisi à chaque publication, trois choix, jamais de coordonnée | décision 4, L23, CGU article 11 | à voir [?] |
| Aimer et commenter | L23 | à voir [?] |
| Écrire à ses amis et dans les clubs dont on est membre | décision 6 et décisions de Titouan du 19 oct. (chat de club réservé aux membres), L24 | à voir [?] ; retirer ce qui manque |
| Signaler ou bloquer sur chaque type de contenu | décision 5, règle 1.2 d'Apple | un bouton par type à vérifier au `/banc` [?] |
| Retrait sous 24 heures | CGU article 10 ; référent de la semaine à fixer (`notes-relecteur-reseau-en.md`) | **ne pas publier tant que le référent n'est pas fixé** |
| 15 ans et plus | décision de Titouan du 19 oct., CGU article 2 | à voir (déclaration avant le profil) [?] |
| Collection jamais publique | règle d'or, `schema.md` (aucun type « Collection » en base publique) | exact selon R2 |
| La communauté est gratuite | décision de Titouan du 19 oct. | exact ; le paywall ne la liste pas en Pro [?] |

Ce qui n'est pas écrit, exprès : « sûr », « modéré en continu », « 24 h sur 24 » (nous agissons sur les signalements, nous ne surveillons pas en continu) ; « privé » pour un club (un club se rejoint par un lien) ; un nombre de membres ; « amis » comme fonction de partage des cartes tant que la page Amis n'est pas vue dans le build ; aucune promesse de « notification en temps réel » (le chat est « à la minute », `latence.md`) ; aucun nom de concurrent ; aucun mot de `docs/banc/mots-interdits.md`.
