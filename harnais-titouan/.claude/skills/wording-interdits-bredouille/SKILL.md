---
name: wording-interdits-bredouille
description: Phrases, mots et chiffres à bannir dans l'app, les métadonnées App Store et le pitch (verdict légal, Pokédex, probabilité de capture, pourcentage d'identification, chiffres faux), avec les alternatives. Se déclenche dès qu'un texte visible par un utilisateur, un relecteur ou un jury est écrit ou relu.
---

# Wording interdit et alternatives

Ce fichier contient volontairement les expressions bannies, à titre d'exemples : le lint de formulations doit **exclure** `.claude/`, `docs/` et `peche/` de ses cibles et ne scanner que le texte affiché (`App/`, `PecheCore/Sources`, `PecheApple/Sources`, `Resources`, métadonnées).

## 1. Légal : jamais de verdict [F, `peche/03` §2.3-2.4]
| Mauvais | Bon |
|---|---|
| « Tu peux la garder. » / « Taille réglementaire » / « Légal ici » | « Cette application ne connaît pas les règles de pêche locales et ne dit jamais si une prise est légale. Consulte la fédération de pêche de ton département. » |
| « Pêche autorisée / interdite » | « Les règles varient selon le département, la catégorie du cours d'eau et la saison. » + lien fédération |
| « Brochet : mesure 60 cm, ok » | « Taille notée : 60 cm (saisie par toi). » |
| Incertain sur une espèce protégée | « Si c'est bien elle, relâche-la immédiatement. » |
Avertissement capture : « Cette carte est une proposition, à confirmer par toi. L'app ne dit pas si tu as le droit de garder un poisson. En cas de doute, relâche. » Aucune autre affirmation sur la légalité, y compris en captures d'écran et métadonnées.

## 2. Marque
Bannir : « Pokémon », « Pokédex », « Pokéball », « Gotta catch them all », « attrape-les tous », noms de marques tierces, logos FNPF/OFB (aucun partenariat officiel).
Bon : « carte à collectionner », « bestiaire », « collection ».

## 3. Rareté : un seul libellé [F, descriptif §5]
| Mauvais | Bon |
|---|---|
| « Probabilité de capture 3 % » / « 3 % de chances de la prendre » | « Présent sur 3 % des stations scientifiques de l'OFB du Loiret » |
| « Poisson rare » (sans territoire) / « Légendaire en France » | « Rare dans le Loiret d'après les relevés scientifiques de l'OFB » |
| « Les meilleures chances de prise » | (rien : promesse non démontrable) |
| Carpe ou sandre « rare » sans nuance | « Mal couvert par les relevés (pêches électriques en rivière) » |
Mention permanente : « Rareté d'après les relevés scientifiques de l'OFB. Ce n'est pas une mesure de la pêche. »

## 4. Identification
Bannir : « Reconnu à 94 % », « 100 % fiable », « notre IA identifie », tout pourcentage de confiance.
Bon : « Probable », « Possible », « Pas sûr ? Aide visuelle », « Aucune de ces espèces ». Pitch : tant que le go/no-go (top-3 >= 85 % sur 200 photos) n'est pas passé, ne pas promettre de reconnaissance par IA ; dire « tu confirmes toujours ».

## 5. Chiffres et affirmations de marché à ne pas utiliser [F, descriptif §14]
- « Aucune app ne relie reconnaissance et règle locale » : faux (HOOKfr, FishVerify).
- « 373 891 pêcheurs de moins de 18 ans » : introuvable. Bon : « environ un quart des cartes concernent des mineurs (FNPF) ».
- « Cartes à la journée +33 % » : le +33,23 % couvre journalières et hebdomadaires cumulées, provisoire ; 2025 final : journée +7 %.
- « 1,4 million de pêcheurs » : ce sont des cartes. Bon : « environ 1,4 million de cartes de pêche en 2025 ».
- « Fishbrain 89,99 € » : environ 79,99 $/an aux États-Unis.
- « Nous sommes les seuls » : bon : « nous visons le débutant et la famille, avec la collection et la prudence juridique ».

## 6. Ton et interface
- Pas d'emoji. Pas de culpabilité sur l'échec (« Tu n'as rien pris ! » -> « Eau calme. Une carte quand même. »). Pas de « streak brisé », pas de rouge sur la bredouille.
- Pas de pression de rareté (« Plus que 2 jours pour… », « Espèce rare près de toi ! »).
- Pas de faux gratuit : « Gratuit » seulement si ce n'est pas un essai ; prix de l'abonnement l'élément le plus visible sur le paywall.
- Pas de texte factice ni d'espèce inventée.

## Procédure
1. Lister les textes ajoutés ou modifiés. 2. Comparer aux tableaux ci-dessus. 3. Pour un doute : appeler l'agent `verificateur-wording`. 4. Le lint `Tools/check/` fait la partie mécanique ; le jugement (« promesse non démontrable ») reste humain.
