# Métadonnées App Store : français (langue principale)

Propriétaire : docs/store. Limites vérifiées par comptage Python le 13/10/2026 (caractères Unicode, espaces compris). Légende : **[F]** fait, **[I]** hypothèse, **⚠** non vérifié.
Les limites (30 / 30 / 170 / 4000 / 100) sont celles d'App Store Connect [F, à revérifier à la saisie : le champ refuse tout dépassement].

| Champ | Limite | Longueur | Valeur |
|---|---|---|---|
| Nom | 30 | 28 | `Bredouille : pêche et cartes` |
| Sous-titre | 30 | 25 | `Une carte à chaque sortie` |
| Texte promotionnel | 170 | 150 | voir ci-dessous |
| Description | 4000 | 2319 | voir ci-dessous |
| Mots-clés | 100 | 99 | `poisson,carnet,prises,espèces,eau douce,carpe,brochet,truite,perche,sandre,album,bestiaire,débutant` |
| Catégorie principale | | | Style de vie (Lifestyle) [I] |
| Catégorie secondaire | | | Sports (Sports) [I] |
| Nouveautés (v1.0) | 4000 | 172 | voir ci-dessous |

## Notes de choix
- **Nom** : « Bredouille » n'est pas vérifié (réservation App Store Connect + INPI). Si le nom est pris, ASC propose un autre nom pour la fiche : garder « pêche et cartes » derrière. Le mot « pêche » dans le nom évite de le répéter dans les mots-clés. Pas de « carte de pêche » : c'est le permis, risque de confusion et de reproche 2.3.
- **Catégorie** : « Style de vie » en principal, « Sports » en secondaire [I]. Il n'existe pas de catégorie pêche. Éviter « Jeux » (déclencherait des questions sur les achats aléatoires, qui n'existent pas) et « Enfants » (interdit ici, voir age-rating-answers.md). Catégories à confirmer à l'écran ⚠.
- **Mots-clés** : séparés par des virgules, sans espace après la virgule. Aucun nom de concurrent (HOOKfr, Fishbrain, FishMan : règle 2.3.7 ⚠), aucun « Pokémon », « Pokédex », « FNPF », « OFB » en mot-clé. Les mots du nom et du sous-titre ne sont pas répétés (ils sont déjà indexés ⚠).
- **Texte promo** : modifiable sans nouvelle version. À changer en février (ouverture de la truite) [I].
- **Aucune promesse** : pas de « reconnu à X % », pas de « tu peux la garder », pas de « première app », pas de chiffre de marché (descriptif §14).
- **Variante si le test d'identification est NO-GO (décision mardi 14 octobre au soir)** : remplacer, dans la description, le 2e paragraphe par « Tu photographies ta prise et tu choisis l'espèce dans la liste de ton département, classée par fréquence, avec une aide visuelle si tu hésites. » et, dans le texte promo, « Photographie ta prise, choisis l'espèce dans ta liste et reçois ta carte. ». Aucun terme « IA » dans ce cas. Les deux variantes sont à recompter avant saisie.
- Les prix sont ceux de la grille retenue dans le descriptif (24,99 €/an, 3,99 €/mois, 7 jours d'essai). La grille gratuit/Pro (15 cartes ou 1 département et 30 prises) reste à trancher : la description ne cite donc **aucun** quota gratuit. Les prix affichés doivent suivre les produits réels d'App Store Connect.
- Hors champs ci-dessus : URL d'assistance `[URL_SUPPORT]`, URL marketing (facultative) `[URL_MARKETING]`, URL de confidentialité `[URL_POLITIQUE]` (voir privacy-policy-fr.md : à héberger en ligne avant la soumission), droits d'auteur `© 2026 [NOM_EDITEUR]`.

## Texte promotionnel (150 caractères)
```
Photographie ta prise, choisis l'espèce parmi trois propositions et reçois ta carte. Une sortie sans poisson rapporte aussi une carte : « Eau calme ».
```

## Description (2319 caractères)
```
Bredouille transforme chaque sortie de pêche en eau douce en carte à collectionner.

Tu photographies ta prise. L'app te propose trois espèces plausibles parmi celles présentes dans ton département, et c'est toujours toi qui confirmes (ou qui réponds « Aucune de ces espèces »). Ta carte apparaît : ta photo détourée, l'espèce, la taille que tu as saisie, le lieu flou, la date.

Pas de poisson aujourd'hui ? Termine ta sortie « bredouille » : tu reçois quand même une carte, « Eau calme ». Cinq bredouilles, et c'est la carte « Patience ».

CE QUE TU TROUVES DANS L'APP
• Une carte par prise, avec une finition qui monte selon la rareté locale
• Le bestiaire de ton département, à compléter à ton rythme
• Un mode « préparer ma sortie » : les espèces plausibles ce mois-ci
• Le relâcher est valorisé ; aucun classement par taille ni par rareté
• Fonctionne sans réseau : au bord de l'eau, ça compte

RESPECTUEUX, HONNÊTE
• Aucun compte, aucune publicité, aucun outil de mesure d'audience : tes photos et ton carnet restent sur ton iPhone.
• Localisation facultative, approximative (ton département), jamais en arrière-plan.
• La rareté d'une carte vient des relevés scientifiques de l'OFB (pêches électriques en rivière) : ce n'est pas une mesure de ce que les pêcheurs prennent.
• L'app ne dit jamais si tu peux garder un poisson. Les règles changent selon le département, le cours d'eau et l'année : consulte la fédération de pêche de ton département. En cas de doute, relâche.
• Les moins de 12 ans pêchent avec un adulte près de l'eau.

BREDOUILLE PRO (FACULTATIF)
Cartes illimitées, albums par bassin, finitions holographiques et cadres, export du carnet. Les bredouilles et ce qui est gratuit aujourd'hui le restent.
• 24,99 € par an, avec 7 jours d'essai gratuit
• 3,99 € par mois
Le paiement est débité sur ton compte Apple à la confirmation de l'achat ; l'essai gratuit est converti en abonnement payant à son terme sauf annulation au moins 24 h avant. L'abonnement se renouvelle automatiquement, sauf annulation au moins 24 h avant la fin de la période en cours. Gestion et résiliation dans Réglages > Compte Apple > Abonnements.
Conditions d'utilisation : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Confidentialité : [URL_POLITIQUE]

Bredouille n'est affiliée ni à la FNPF ni à l'OFB.
```
Obligations couvertes (3.1.2 ⚠ à relire sur la page officielle) : prix, durée, essai, renouvellement automatique, résiliation, lien Conditions, lien Confidentialité. Remplacer `[URL_POLITIQUE]` par l'URL réelle avant de coller.

## Nouveautés, version 1.0 (172 caractères)
```
Première version de Bredouille : photographie ta prise, choisis l'espèce parmi trois propositions, reçois ta carte. Une sortie sans poisson rapporte la carte « Eau calme ».
```
