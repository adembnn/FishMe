# Fiche App Store à coller dans la console MWM (version 1.0)

Prépare les 8 champs que la console MWM liste pour « Version 1.0, à écrire avant la revue » : mots-clés, description, page d'assistance, politique de confidentialité, copyright, captures iPhone 6,9 pouces, contact de revue, catégorie.
Légende : **[F]** fait, **[I]** proposition à valider, **⚠** à vérifier. `[ ... ]` = à remplir par une personne de l'équipe, rien n'est inventé.
Règles de rédaction : aucun verdict légal, aucun « Pokédex » ou « Pokémon », aucune probabilité de capture, aucun pourcentage d'identification (`wording-interdits-bredouille`). Les chiffres de prix et la grille gratuite sont **provisoires** (`docs/decisions-produit.md`).
Les compteurs ci-dessous sont comptés par Python, espaces compris.

## 1. Nom et sous-titre

| Champ | Valeur | Limite | Compte |
|---|---|---|---|
| Nom | `Bredouille` | 30 | 10 |
| Sous-titre | `Une carte par sortie de pêche` | 30 | 29 |

Le nom doit être réservé dans la console (contrôle INPI en parallèle). Si pris, prendre un nom de fiche proche.

## 2. Mots-clés (limite 100, séparés par des virgules, sans espace)

```
pêche,poisson,carte,collection,rivière,brochet,carpe,truite,sandre,eau douce,sortie,espèces,pêcheur
```

Choisis pour ne pas répéter le nom ni la catégorie. Aucun nom de marque tiers. [I]

## 3. Description (limite 4 000)

```
Bredouille est l'app de pêche en eau douce où chaque sortie rapporte une carte, même sans poisson.

Tu prends ta prise en photo. L'app te propose trois espèces plausibles dans ton département. Tu touches la bonne, et ta carte à collectionner apparaît. Deux touches, une main mouillée, aucun compte à créer.

Une sortie sans prise ? Elle vaut une carte « Eau calme ». Parce qu'une journée au bord de l'eau compte aussi.

CE QUE TU TROUVES DANS L'APP
- Une carte par prise, avec ta photo, l'espèce, la date et le lieu approximatif.
- Une collection et un bestiaire de ton département : les espèces que tu as déjà croisées, celles qu'il te reste à rencontrer.
- Une rareté par espèce, calculée d'après les relevés scientifiques de l'Office français de la biodiversité (OFB).
- Un mode débutant pour savoir quelles espèces rencontrer ce mois-ci.
- Le partage d'une image de ta carte, sans ton lieu exact.

CE QU'ON FAIT AUTREMENT
- Tu décides toujours. L'app propose, tu confirmes. « Aucune de ces espèces » est toujours là.
- Tout fonctionne sans réseau, et tes cartes restent sur ton iPhone.
- Aucun compte, aucune publicité.
- La rareté vient de relevés scientifiques faits en rivière. Elle ne mesure pas ce que les pêcheurs prennent.

IMPORTANT
Cette application ne connaît pas les règles de pêche locales et ne dit jamais si une prise est légale. Consulte la fédération de pêche de ton département. En cas de doute, relâche le poisson.

BREDOUILLE PRO (OPTIONNEL)
Les premières cartes sont offertes. Un abonnement facultatif débloque la suite. Tes cartes restent à toi, même sans abonnement. L'abonnement se renouvelle automatiquement sauf annulation au moins 24 heures avant la fin de la période, dans les réglages de ton compte Apple. Restauration des achats disponible dans l'app.

Données de rareté : OFB, Hub'Eau, Licence Ouverte 2.0.
```

Ce que le Pro contient réellement (décision `Q24`) : bestiaire de tous les départements, finitions de cartes, bilan de saison et export, sauvegarde iCloud, mode Préparer. **Ne citer dans la description que ce qui est livré dans le build** (règle 2.3 : pas de promesse non tenue). Le paragraphe actuel reste volontairement générique.

À relire avant envoi : la phrase « Les premières cartes sont offertes » remplace « 15 cartes » tant que la grille n'est pas tranchée [I]. Les conditions et la confidentialité doivent aussi être liées dans l'app (paywall et réglages).

## 4. Adresse d'assistance (obligatoire)

`[URL_ASSISTANCE]` : une page publique où l'on peut vous joindre. Option : la page d'accueil de l'app que le MCP de MWM sait publier (outil « landing page »), avec un contact. Ne pas inventer d'adresse. [À faire par : une personne de l'équipe avec accès console]

## 5. Politique de confidentialité (obligatoire)

`[URL_POLITIQUE]` : à publier **via l'outil juridique de MWM** (questionnaire puis publication à une adresse stable). Il assemble un texte à partir de clauses validées par un juriste : on ne colle pas notre propre texte (`docs/store/privacy-policy-fr.md` sert de brouillon de réponses, pas de texte final).
Réponses à fournir au questionnaire : l'app n'a ni compte ni publicité ; photos et cartes stockées sur l'appareil ; localisation approximative facultative ; **le SDK Spark Flash de MWM collecte** historique d'achats, interaction avec le produit, données de performance, de plantage et de diagnostic, identifiant utilisateur et identifiant d'appareil, non liés à l'identité, sans suivi (d'après le manifeste du SDK). Les étiquettes de confidentialité de l'App Store doivent déclarer les mêmes types.

## 6. Copyright

`© 2026 [NOM_DE_L'ÉDITEUR]` : le nom de l'entité juridique qui publie (probablement celle de MWM, car l'app est dans leur compte). À demander à MWM, ne pas écrire un nom au hasard. ⚠

## 7. Catégorie

- Principale : **Sports** [I]
- Secondaire : **Mode de vie** (Lifestyle) [I]
- Ne pas cocher « Made for Kids ». Classification d'âge visée : 4+ (`docs/store/age-rating-answers.md`, à rejouer avec le questionnaire officiel).

## 8. Captures iPhone 6,9 pouces (français)

Taille attendue : à vérifier à l'écran de la console, car la page d'Apple et le plan divergent (6,9 contre 6,3 pouces) ⚠. Ne produire les captures qu'à partir de **vrais écrans** du build ou de TestFlight (jamais de maquettes). Plan : `docs/store/screenshots-plan.md`. Ordre proposé [I] :
1. La carte révélée (photo, espèce, rareté)
2. Les trois propositions d'espèces
3. La collection
4. La carte « Eau calme »
5. Le bestiaire du département

Aucune capture ne montre « Pokédex » ni une personne identifiable. Légendes sobres, sans chiffre non sourcé.

## 9. Contact pour la revue d'Apple

| Champ | Valeur |
|---|---|
| Prénom, nom | `[PRÉNOM NOM]` |
| Téléphone | `[TÉLÉPHONE JOIGNABLE VENDREDI]` |
| E-mail | `[EMAIL]` |
| Connexion requise | Non |

Notes pour le relecteur (en anglais) : `docs/store/review-notes.md`. Y insister sur le lien « Essayer avec une photo d'exemple » (le relecteur n'a pas de poisson).

## 10. Reste à faire côté personnes (rien de tout ça n'est inventé ici)

- [ ] Nom de l'éditeur pour le copyright (demander à MWM).
- [ ] Contact de revue : nom, téléphone, e-mail.
- [ ] Page d'assistance et politique de confidentialité publiées (via la console MWM).
- [ ] Catégorie validée.
- [ ] Captures réelles à produire depuis un build.
- [ ] Remplacer « les premières cartes sont offertes » par le chiffre final si la grille est tranchée.
