# Plan des captures d'écran App Store (iPhone 6,9 pouces)

Légende : **[F]** fait, **[I]** hypothèse, **⚠** non vérifié. Source des règles : revue-appstore-checklist (« vrais écrans de l'app, jamais les maquettes HTML, sans cadre d'une autre génération »), peche/03 §2.4 et §3.3, descriptif §3 et §14.

## Format ⚠
- Classe **6,9"** : tailles acceptées à relire dans App Store Connect au moment du dépôt ; valeurs usuelles **1320 x 2868** px (portrait) ou **1290 x 2796** px ⚠. Un jeu 6,9" suffit : Apple en déduit les tailles inférieures pour iPhone ⚠.
- **1 à 10** captures par langue ⚠ ; viser **7**. PNG ou JPEG sans transparence, sans coins arrondis ajoutés.
- Source : simulateur ou iPhone réel avec la **build soumise** (TestFlight). Captures de l'iPhone via bouton latéral + volume haut (aucun cadre de téléphone n'est obligatoire).
- Données affichées : jeu de démonstration **réaliste et honnête** : département de démonstration (95 Val-d'Oise ou autre pilote), espèces du catalogue, photos CC0/CC-BY (manifeste de licences) ou photos de pêcheurs avec consentement écrit. Aucun faux avis, aucune fausse note, aucun chiffre d'utilisateurs.
- Bandeaux de légende : texte court (4 à 7 mots) en police système, ni emoji, ni logo FNPF/OFB, ni mot « Pokémon/Pokédex », aucune promesse de légalité ni de pourcentage de reconnaissance.
- Déclinaisons FR (principal) et EN (secondaire) du même visuel. Fichiers à nommer `store/screens/fr/01-capture.png`, etc. (dossier à créer par Adem, hors périmètre docs).

## Les 7 captures (ordre = ordre de lecture sur la fiche)

| # | Écran réel | Ce qu'on y voit | Légende FR | Légende EN | Garde-fou |
|---|---|---|---|---|---|
| 1 | Capture (viseur) avec « Essayer avec une photo d'exemple » visible | Un poisson (photo de démonstration) dans le viseur, gros obturateur, lien visible | Photographie ta prise | Photograph your catch | Pas de poisson tenu hors de l'eau trop longtemps : privilégier une photo dans l'eau ou sur tapis humide (peche/03). |
| 2 | « Quelle espèce ? » | 3 propositions (probable, possible), « Aucune de ces espèces », « Tu confirmes toujours » | Trois propositions, tu confirmes | Three suggestions, you confirm | Aucun pourcentage d'identification ; même texte « Tu confirmes toujours » visible. **Absente si test NO-GO** : remplacer par la liste du département. |
| 3 | Révélation de la carte | Carte avec photo détourée, espèce, nom latin, taille, relâché, lieu flou, mention de rareté | Ta carte, ta prise | Your catch, your card | Mention « Rareté d'après les relevés scientifiques de l'OFB. Ce n'est pas une mesure de la pêche. » **lisible** ; pas de verre sur la carte (CLAUDE.md règle 11). |
| 4 | Bestiaire du département | Grille de cartes obtenues et silhouettes grises, compteur « 12 sur 34 » (valeurs réelles du jeu de démo) | Complète le bestiaire de ton département | Complete your département's bestiary | Pas de classement par taille ou par rareté. |
| 5 | Carte « Eau calme » (bredouille) | La carte série « Eau calme » avec sa citation, message doux | Même sans poisson, une carte | No fish? You still get a card | Aucun point de rareté, ton doux. C'est le différenciateur (4.3). |
| 6 | « Préparer ma sortie » | Espèces plausibles ce mois-ci, lien vers la fédération du département, avertissement fixe | Prépare ta sortie | Plan your outing | Texte fixe visible : « ne dit jamais si une prise est légale ». Aucune date d'ouverture affichée en dur comme certaine. |
| 7 | Écran « Confidentialité » / réglages ou mode avion | Accueil en mode avion (icône avion visible) + mention « Tes cartes sont sur cet iPhone » | Sans compte, sans réseau | No account, no network | Vrai uniquement si le cœur marche réellement hors ligne (règle 8). Ne pas écrire « données chiffrées » ni « 100 % sécurisé ». |

Option 8 (seulement si la carte est publiée) : la carte des relevés de l'OFB avec la mention « Station de relevé scientifique, pas une recommandation de pêche ni un droit d'accès », jamais une position de prise.

## À ne pas montrer
- Les maquettes HTML (`peche/maquettes/index.html`) : Liquid Glass simulé en CSS, pas le vrai rendu.
- Le paywall dans les 7 captures : il n'est pas indispensable dans la galerie. La **capture de revue de l'abonnement** (écran du paywall réel, avec prix, durée de l'essai, Restaurer, Conditions, Confidentialité) se téléverse **séparément** dans chaque produit d'abonnement, résolution à relire dans ASC ⚠ ; elle n'est pas visible du public.
- Une capture annonçant « -X % » ou un compte à rebours.
- Des prises de poissons protégés (anguille, saumon, esturgeon…) présentées comme trophées ; si présentes, avec le libellé « À observer et relâcher ».
- Le nom d'un concurrent, le logo FNPF/OFB/Hub'Eau, la mention « Pokédex ».

## Procédure de production (propriétaires)
1. **Adem** : installer la build soumise sur iPhone, charger le jeu de démonstration, enregistrer les 7 captures (FR puis EN en changeant la langue de l'appareil).
2. **Business** : ajouter les bandeaux de légende (police système, contraste suffisant, taille lisible) ; contrôle des chiffres affichés.
3. **Titouan** : relecture wording (aucun terme interdit, descriptif §14) et licences d'images (manifeste CC0/CC-BY).
4. Échéance : captures finales vendredi 16 octobre avant 12 h (peche/04 §3, ligne 11-12 h).

## Vérification finale (case à cocher)
- [ ] 7 images FR + 7 images EN, même taille, ordre vérifié
- [ ] Aucune légende n'affirme une légalité, un pourcentage ou une exclusivité
- [ ] La mention de rareté et l'avertissement de légalité sont lisibles sur au moins une capture
- [ ] Les captures viennent de la build soumise (numéro de build noté : ____)
