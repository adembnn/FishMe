# Note à MWM : la mesure d'usage de FishMe sera presque vide (décision 7)

**Brouillon écrit par S2 le 19 octobre 2026. À relire par Adem avant tout envoi : rien n'est envoyé à MWM sans son oui.** Ce n'est pas un texte juridique. Destinataire probable : build-challenge@mwm.ai, envoyé par Adem (`store/confidentialite-spark-flash.md`, §4).

## Le message

Objet : FishMe, mesure d'usage Spark : très peu de données attendues, et pourquoi

Bonjour,

Pour la version de FishMe qui porte le réseau social, nous changeons l'endroit où le pêcheur donne son accord à la mesure d'usage (SDK Spark).

**Ce que nous avons décidé (Adem, 19 octobre 2026).** L'accord à la mesure ne se demande plus dans le parcours de démarrage. Il se donne uniquement dans les Réglages de l'app (« Mesure d'usage »), il est éteint par défaut, et l'app ne le propose nulle part ailleurs. Nous avions envisagé un interrupteur dans l'écran du niveau du pêcheur ; nous l'avons écarté pour ne pas ralentir les trois premières minutes.

**Ce que cela change pour vos chiffres.**
- Tant que le pêcheur n'a pas accepté, Spark n'est ni initialisé ni appelé : aucun événement ne part, ni installation, ni session, ni achat, ni plantage.
- Presque personne n'ouvre les Réglages pour allumer une mesure. Nous nous attendons donc à ce que presque aucune donnée Spark ne remonte pour FishMe. Nous ne pouvons pas donner de pourcentage : nous n'en avons mesuré aucun et nous n'en inventons pas.
- Le peu qui remonte vient de pêcheurs qui sont allés dans les Réglages : un échantillon petit et biaisé vers les plus investis. Il ne faut pas en tirer de taux de conversion, de rétention ni de comptage d'utilisateurs.
- Ce n'est pas un défaut de l'intégration : c'est un choix de produit.

**Ce que nous pouvons vous donner à la place**, sans accord du pêcheur dans l'app (⚠ disponibilité et seuils à vérifier dans App Store Connect avant de les promettre) :
- les ventes et les abonnements d'App Store Connect (unités, renouvellements, annulations) ;
- les statistiques d'App Store Connect : impressions, visites de la page de l'app, téléchargements, sessions et plantages des personnes qui acceptent de partager leurs données avec les développeurs ;
- les retours et plantages de TestFlight pendant les tests.

**Ce que nous vous demandons.**
1. Votre tableau de bord des abonnements et des revenus de l'équipe dépend-il d'événements envoyés par Spark, ou des données d'Apple ? Si c'est Spark, ces chiffres seront vides pour FishMe aussi.
2. Un accord donné dans les Réglages seulement vous convient-il pour le SDK et pour vos conditions ? Où le SDK enregistre-t-il cet accord ?
3. Le SDK ne fait rien du tout avant son initialisation, y compris aucune requête réseau ? (question 5 de notre liste du 15 octobre)
4. La liste écrite de ce que Spark envoie une fois allumé (questions 1 à 4 de la même liste), pour que notre politique de confidentialité et nos étiquettes « App Privacy » disent exactement la même chose.

Si vous préférez plus de mesure, ce serait une autre décision de produit, à prendre avec Adem : elle heurterait le choix de ne rien poser sur le parcours de démarrage.

Merci,
[signature d'Adem]

## Pour Adem (ne fait pas partie du message)
- Rien n'est chiffré : si MWM demande « combien », la réponse honnête est « nous ne savons pas, tant que le build n'est pas dans les mains de testeurs ».
- Le texte des CGU et de la politique de confidentialité dit la même chose (« éteinte par défaut, acceptée dans les Réglages seulement »). Si tu changes la décision 7, il faut changer ces deux textes et `store/app-privacy.md`.
- La question 1 ci-dessus peut aussi se régler en lisant le tableau de bord de l'équipe.
