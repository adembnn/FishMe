---
name: revue-appstore-checklist
description: Checklist de revue App Review (2.1, 4.3, 5.1.1, 3.1.2, 1.2, 5.2.1, photo d'exemple, confidentialité) adaptée à Bredouille. Se déclenche avant tout build TestFlight ou soumission, et quand on touche aux permissions, au paywall, aux métadonnées ou aux mentions légales.
---

# Checklist App Store (source : `peche/07` §7, `03`, `02`)

Numéros de règles issus des rapports [F pour l'existence, I pour l'interprétation] : à relire sur la page officielle des App Review Guidelines avant soumission.

## 2.1 Complétude / testabilité
- [ ] Le relecteur n'a pas de poisson : lien visible **« Essayer avec une photo d'exemple »** sur l'écran de capture (non caché). Notes de revue : comment tester caméra, bredouille, paywall, restauration. Pas de compte démo (il n'y a pas de compte).
- [ ] Aucun texte factice, aucun lien mort (confidentialité, conditions).
- [ ] Produits d'abonnement créés dans App Store Connect **et soumis avec la 1re version**, capture de revue du paywall incluse.

## 4.3 Spam / apps similaires
- [ ] Différenciation écrite dans les notes de revue : collection de cartes + carte « Eau calme » en cas de bredouille + prudence juridique. Pas de clone ; aucun contenu copié.

## 5.1.1 Données et permissions
- [ ] (i) Politique de confidentialité : URL dans App Store Connect **et** dans l'app (Réglages) ; dit que tout est local.
- [ ] (ii) Une chaîne d'usage précise par ressource, localisée FR/EN : caméra, photothèque en écriture (seulement si export), localisation en cours d'usage (facultative).
- [ ] (iii) Minimisation : `PhotosPicker` (pas de permission de lecture), position ponctuelle ou département manuel.
- [ ] (iv) Chaque refus a une voie alternative ; la fonction payante ne dépend pas d'une donnée accordée.
- [ ] (v) **Suppression de compte : sans objet, il n'y a aucun compte.** Ne jamais ajouter de création de compte sans prévoir la suppression dans l'app.
- [ ] Étiquettes App Privacy cohérentes avec le comportement réel ; manifeste de confidentialité pour les API « raison requise » ⚠ ; pas d'ATT, pas de SDK pub.
- [ ] `ITSAppUsesNonExemptEncryption = NO` ; aucune permission « Toujours » ; aucune clé inutilisée.

## 3.1.1 / 3.1.2 Abonnements
- [ ] Achats via StoreKit uniquement ; **« Restaurer » visible**.
- [ ] Montant facturé = élément de prix le plus visible ; durée, renouvellement automatique, essai et prix après essai écrits ; liens Conditions et Confidentialité sur le paywall et dans les métadonnées.
- [ ] Rien n'est conditionné à un partage ou une invitation ; le paywall ne promet rien qui ne soit livré ; cartes déjà obtenues toujours visibles.
- [ ] Grille de prix tranchée (le descriptif et `04` divergent) avant la soumission.

## 1.2 Contenu généré par l'utilisateur
- [ ] Aucun contenu public, chat, classement ou compte : sans objet au MVP. Si le partage ajoute une publication, revoir 1.2 (signalement, blocage, modération).

## 5.2.1 / propriété intellectuelle
- [ ] Aucun « Pokémon », « Pokédex », visuel de TCG tiers dans nom, captures, mots-clés, métadonnées. Aucun logo FNPF/OFB. Photos : CC0/CC-BY avec attribution (écran « Sources »). Nom « Bredouille » : réservation App Store Connect + contrôle INPI [I, non vérifié].

## Sensibilité du produit
- [ ] Pas en catégorie « Enfants » ; questionnaire d'âge App Store rempli sans contournement ; message « moins de 12 ans : avec un adulte près de l'eau ».
- [ ] Avertissement « pas de verdict légal » visible ; aucune promesse de légalité dans les captures.
- [ ] Captures d'écran : vrais écrans de l'app (jamais les maquettes HTML), sans cadre d'une autre génération.

## Bon / mauvais
- Mauvais : « Pour tester, prenez une photo de brochet. » Bon : « Appuyez sur Essayer avec une photo d'exemple (écran de capture). »
- Mauvais : `NSLocationAlwaysUsageDescription` présent « au cas où ». Bon : seulement `NSLocationWhenInUseUsageDescription`.
