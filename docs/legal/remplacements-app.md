# Remplacements de textes dans `App/` (pour L25)

Écrit par S2 le 20 octobre 2026. S2 ne touche pas `App/` (sauf `TexteConditions.swift`, sortie du script). L25 applique ces phrases telles quelles. Brouillons à faire relire par un juriste de MWM (voir `docs/legal/questions-juriste.md`) ; aucun avis juridique. Numéros de ligne lus sur `lot/store-2` au 20 octobre : à relire sur le build fusionné.

## 1. `App/RootView.swift:1209`
- Ancienne : « Pas de compte à créer : ton profil reste sur cet iPhone. »
- Nouvelle : « Ton Pescedex reste sur cet iPhone. Un profil public, avec un surnom seulement, est facultatif. »

## 2. `App/RootView.swift:1216` (pied de la ligne « Mode démo »)
- Ancienne : « Remplit le Pescedex, les amis et le club avec des exemples. Rien n'est envoyé. »
- Nouvelle : « Remplit le Pescedex, le fil, les amis et le club avec des exemples, en lecture seule. Rien n'est envoyé. » (vraie seulement si L25 branche `demo.communaute` au fil et au chat)

## 3. `App/RootView.swift:1197` (champ « Ton nom de profil »)
- Ancienne : `TextField("Ton nom de profil", ...)`
- Nouvelle : « Ton surnom » (FishMe ne demande ni nom ni prénom ; surnom unique de 3 à 20 caractères, public). Idem pour tout champ nom ou prénom de `ReglagesProfilView.swift` (lignes vues par la revue : 73-80).

## 4. `App/Abonnement/ConfidentialiteView.swift:4` (commentaire)
- Ancienne : « Ne dit que ce que fait le build soumis : aucun coin exact ne quitte l'iPhone, photos sans GPS, pas de compte. »
- Nouvelle : « Reprend docs/legal/politique-confidentialite.md : profil public à surnom seul, repères privés dans l'iCloud privé, carte de pêche sur l'iPhone, signalements lus par l'équipe. »

## 5. `App/Abonnement/ConfidentialiteView.swift:9` (bloc « Ta position »)
- Ancienne : « Ta position sert à te montrer la carte, les règles et les relevés autour de toi. Elle reste sur ton iPhone : aucun coin de pêche exact n'est envoyé. »
- Nouvelle : « Ta position sert à te montrer la carte, les règles et les relevés autour de toi. Elle reste sur ton iPhone. Tes repères privés (les coins de pêche que tu enregistres, avec leurs coordonnées exactes) sont sauvegardés dans ton iCloud privé, chiffré : ils ne sont jamais partagés ni publiés. »

## 6. `App/Abonnement/ConfidentialiteView.swift:10` (bloc « Tes prises et tes photos »)
- Ancienne : « Ta collection et tes photos restent sur ton iPhone. Les photos enregistrées par FishMe n'ont pas de position GPS. »
- Nouvelle : « Ta collection et tes photos sont sauvegardées dans ton iCloud, et envoyées seulement aux amis que tu invites. Les photos enregistrées, publiées ou importées n'ont pas de position GPS. Si tu importes ta carte de pêche, elle reste sur ton iPhone, protégée, et suit la sauvegarde de l'iPhone ; FishMe n'en lit ni le numéro ni le nom. »

## 7. `App/Abonnement/ConfidentialiteView.swift`, blocs à AJOUTER avant « Contact » (ligne 14)
- Titre « Ton profil et ce que tu publies » : « Si tu as 15 ans ou plus, tu peux créer un profil. FishMe te demande seulement un surnom : ni nom ni prénom. Ton surnom, ton avatar, tes publications, tes commentaires et tes likes sont visibles de tous les utilisateurs de FishMe, dans la base publique iCloud d'Apple. Tu choisis le lieu affiché à chaque publication : le département par défaut, jamais une coordonnée. Tu peux tout supprimer dans Réglages, « Supprimer mon profil ». »
- Titre « Messages, signalements et blocage » : « Les messages d'amis et de clubs ne sont jamais dans la base publique. Si tu signales un message, son texte (500 caractères au plus) est joint à l'e-mail préparé pour fishme.app@gmail.com et copié dans l'enregistrement du signalement, que seule l'équipe de FishMe (Titouan, Adem et Sullyvan) peut lire. Nous retirons sous 24 heures les contenus publics signalés qui enfreignent les conditions. Tu peux bloquer une personne : la liste reste dans ta sauvegarde privée. »

## 8. `App/Abonnement/ConfidentialiteView.swift:12` (bloc « Mesure d'audience »)
- Ancienne : « Avec ton accord seulement, l'app mesure son usage de façon anonyme pour s'améliorer. Tu peux refuser sans rien perdre. »
- Nouvelle : « Avec ton accord seulement, donné dans les Réglages, l'app mesure son usage pour s'améliorer, sans te suivre et sans publicité. Tu peux refuser ou couper à tout moment sans rien perdre. » (« anonyme » retiré : le SDK envoie des identifiants d'installation et d'appareil)

## 9. `App/Compte/CompteView.swift:116`
- Ancienne : « Pas de mot de passe : ton compte, c'est ton identifiant Apple. Rien n'est envoyé chez nous. Tes coins de pêche exacts restent sur cet iPhone. »
- Nouvelle : « Pas de mot de passe : ton compte, c'est ton identifiant Apple. Tes repères privés sont sauvegardés dans ton iCloud privé, chiffré, et ne sont jamais partagés. »

## 10. `App/Club/MesClubs.swift:407`
- Ancienne : « Ton coin exact ne quitte jamais ton iPhone. Les amis invités voient tes cartes, personne d'autre. »
- Nouvelle : « Ton coin exact n'est jamais partagé. Les amis invités voient tes cartes, personne d'autre. »

## 11. `App/Mesure/FeuilleConsentement.swift:75`
- Ancienne : « FishMe compte seulement des usages anonymes, sans te suivre d'une app à l'autre. Aucun coin de pêche ne quitte ton iPhone. »
- Nouvelle : « FishMe compte seulement des usages, sans te suivre d'une app à l'autre. Aucun coin de pêche n'est partagé ni publié. »

## 12. Page Sources (Profil, Sources) : attribution de la liste de mots interdits
`App/Abonnement/ReglagesView.swift:34-40` : ajouter à `sources` la ligne `("Filtre de mots", "LDNOOBW, CC BY 4.0")` et, au toucher, afficher le texte exact ci-dessous (feuille de texte : `RootView.page(de:)` n'ouvre aujourd'hui que des URL).

Texte exact :

« Filtre de mots : liste « List of Dirty, Naughty, Obscene, and Otherwise Bad Words » (LDNOOBW), © Shutterstock, Inc., fichier français, publiée sous licence Creative Commons Attribution 4.0 International (CC BY 4.0). Source : https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words. Licence : https://creativecommons.org/licenses/by/4.0/. Modifié par FishMe : des mots de pêche ou de langage courant sont retirés (par exemple tanche, bite, bitte, gueule, gerbe, suce, pédale, turlutte, cul, folle) ; des insultes et propos haineux courants sont ajoutés ; les pluriels et féminins sont listés. La liste est fournie « en l'état », sans garantie. »

Vérification (20 oct., page publique du dépôt lue par S2) : licence CC BY 4.0 ; propriétaire « Shutterstock, Inc. » (pied de page 2012-2020). À relire sur le dépôt le jour de la soumission (mention de copyright exacte). Les modifications décrites sont celles de l'en-tête de `Packages/Core/Sources/Core/Moderation/MotsInterditsFR.swift` : si la liste change, la phrase change.
