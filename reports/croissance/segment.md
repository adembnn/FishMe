# Premier segment de pêcheurs à tester pour FishMe

Question : parmi les pêcheurs français, quel groupe peut éprouver la promesse de FishMe et donner une chance raisonnable d’observer à la fois un usage répété et une conversion payante ? Cette note complète l’étude de marché existante ; elle n’est pas une validation par des entretiens.

## Recommandation provisoire

Commencer par des **pêcheurs réguliers d’eau douce qui pêchent aux leurres les carnassiers (brochet, sandre, perche), possèdent un iPhone et pratiquent dans un département couvert par les règles de FishMe**. Pour le premier recrutement, chercher ces personnes dans un ou deux lieux où Adem et Titouan peuvent réellement les rencontrer et observer une sortie — probablement un club/AAPPMA, un concours ou un groupe local, après vérification de la couverture exacte des règles dans le build.

Le critère prioritaire n’est pas l’âge ni une persona de marque : c’est la possibilité de vivre une sortie réelle avec l’app, de vérifier la valeur du verdict réglementaire et des fonctions de session, puis d’avoir une raison de revenir. Garder le sous-groupe des pêcheurs occasionnels comme comparaison, et ne pas en faire la cible initiale par défaut.

Cette sélection est une **hypothèse de test**, pas un segment démontré comme supérieur. Le choix « carnassiers aux leurres » est cohérent avec les espèces explicitement utilisées dans les parcours et exemples de l’app (brochet, sandre, perche) et avec le besoin d’une réponse locale « garder / relâcher / vérifier ». Les sources publiques consultées ne ventilent pas la pratique iPhone, l’usage d’apps ou la disposition à payer par technique.

## Ce que les données permettent de dire

- La base est assez grande pour éviter une cible nationale trop vague : la FNPF compte **1 393 920 pêcheurs en 2024**, dont 361 530 mineurs et 105 392 femmes. En 2025, elle indique une hausse globale de 3 % des cartes ; la carte majeure représente 713 000 cartes, et les moins de 18 ans environ un quart des effectifs. Ces chiffres décrivent des adhésions, pas les propriétaires d’iPhone ni les utilisateurs d’apps. [FNPF, chiffres 2024](https://www.federationpeche.fr/6684-chiffres-cles-2024-de-la-peche-en-france.htm), [FNPF, chiffres 2025](https://www.federationpeche.fr/7142-chiffres-cles-2025-de-la-peche-en-france.htm)
- La FNPF souligne aussi la progression en 2025 des cartes à la journée (+7 %) et à la semaine (+4 %). Cela établit qu’il existe une pratique ponctuelle mesurable, mais pas que ces pêcheurs seraient plus faciles à convertir ou moins récurrents. [FNPF, chiffres 2025](https://www.federationpeche.fr/7142-chiffres-cles-2025-de-la-peche-en-france.htm)
- La seule étude de pratique nationale trouvée dans les sources du marché est ancienne : enquête BIPE/FNPF menée auprès de 7 900 pêcheurs, portant sur 2011. Elle rapportait une pratique généralement fréquente et plusieurs techniques et espèces ciblées, dont truite, brochet/sandre et carpe. Elle peut aider à générer des hypothèses, mais son âge empêche de l’utiliser pour estimer le segment actuel ou ses comportements numériques. [Étude BIPE/FNPF, données 2011 (PDF)](https://www.federationpeche.fr/cms_viewFile.php?idtf=1509&path=Etude-sur-le-poids-economique-de-la-peche.pdf)
- L’étude déjà faite dans FishMe rapporte que les concurrents français gratuits bien notés mettent en avant des usages d’utilité, de carnet et de partage, et que les plaintes sur prix et fiabilité sont importantes. Elle recommande pour FishMe le bénéfice « Peux-tu garder ce poisson, ici, aujourd’hui ? ». C’est utile pour cadrer le test, mais l’étude précise qu’aucun pêcheur n’a encore été interrogé directement. Voir [`reports/marche/synthese.md`](../marche/synthese.md), [`reports/marche/concurrence-fr.md`](../marche/concurrence-fr.md) et [`reports/marche/methode.md`](../marche/methode.md).

## Pourquoi ce groupe avant les autres

1. **Usage central observable.** Le verdict réglementaire local sur un poisson capturé est une promesse vérifiable pendant une sortie. Un pêcheur qui prend régulièrement l’appareil et cible des espèces présentes dans le périmètre couvert peut éprouver le parcours plus d’une fois.
2. **Meilleur test de rétention.** La répétition se mesure lors d’une nouvelle sortie et d’une nouvelle session, plutôt qu’en se fiant à une installation ou à une intention déclarée. Les pêcheurs de loisir très occasionnels risquent de ne pas revenir simplement parce qu’ils sortent peu ; distinguer leur fréquence de l’attrait du produit.
3. **Apprentissage faisable à budget quasi nul.** Des clubs, AAPPMA et événements locaux donnent des occasions d’observer le contexte réel et de recruter sans acheter de publicité. Le rapport d’acquisition existant documente ces voies comme mécanismes utilisés par des acteurs français ; il ne démontre pas encore qu’elles fonctionneront pour FishMe.
4. **Alignement iOS et offre payante.** Il faut inclure uniquement des utilisateurs iPhone pour tester l’app actuelle. Il faut en revanche mesurer séparément l’intérêt pour les fonctions gratuites et payantes : un segment qui revient n’est pas automatiquement un segment qui paie.

## Choix géographique et limites

Ne pas annoncer « Île-de-France » comme cible ferme avant une vérification simple : liste des départements et règles réellement présentes dans la version que vous allez distribuer, puis accès de l’équipe à des pêcheurs concernés. Les exemples du dépôt incluent notamment le 94 et le 59, mais un exemple de test ne prouve pas que toutes les règles du département sont prêtes pour le public. Si la couverture est insuffisante là où vous pouvez recruter, choisir le département couvert le plus accessible à l’équipe ; ne pas recruter des pêcheurs auxquels FishMe ne peut pas encore fournir la promesse.

À court terme, éviter de fixer une cible d’âge ou de genre. Les chiffres FNPF montrent une communauté composée de profils variés, tandis que les données publiques repérées ne permettent pas de relier ces profils à la possession d’iPhone, à la fréquence des sorties, à la rétention d’une app ou à un achat intégré.

## Questions à vérifier auprès de pêcheurs

Avant de choisir un segment plus étroit, observer des sorties réelles et demander :

- Quelles espèces et techniques utilisent-ils le plus souvent, et sur quels types d’eaux ?
- Comment vérifient-ils aujourd’hui la règle locale après une prise ? À quel moment l’incertitude survient-elle ?
- Est-ce qu’ils utilisent leur iPhone pendant ou après la sortie ? Qu’est-ce qui rendrait acceptable de le sortir au bord de l’eau ?
- Qu’est-ce qui leur donnerait une raison d’ouvrir FishMe à la sortie suivante ?
- Quelles fonctions seraient assez utiles pour justifier un abonnement, une fois les fonctions gratuites testées ? Quelle fonction devrait rester gratuite ?
- Ont-ils pêché au moins une fois récemment dans un département dont la règle est correctement couverte par le build ?

Lors des essais, enregistrer le segment et le département, mais comparer les parcours au niveau individuel : installation, première sortie commencée et terminée, seconde sortie, retour dans l’app, écran paywall vu, démarrage d’essai et paiement. Les définitions exactes des événements et des fenêtres d’observation sont à établir dans le ticket métriques, pas à supposer ici. Ne pas confondre l’exposition au paywall avec la volonté de payer.

## Décision à prendre ensuite

Recruter un premier petit groupe **d’adultes iPhone qui pêchent réellement le carnassier aux leurres dans un département couvert et accessible**, en incluant des pêcheurs fréquents et quelques occasionnels pour comparaison. Après observation des sorties et de la seconde utilisation, décider si FishMe doit élargir à d’autres techniques/espèces ou resserrer davantage. Ne pas engager de dépense d’acquisition sur la base de cette note seule.

## Références internes réutilisées

- [`reports/marche/README.md`](../marche/README.md) — périmètre et questions non résolues.
- [`reports/marche/acquisition.md`](../marche/acquisition.md) — canaux organiques et limites du benchmark.
- [`docs/architecture.md`](../../docs/architecture.md) — parcours, espèces exemples et règles locales.
- [`docs/app-store.md`](../../docs/app-store.md) — iPhone seul et publication pas encore soumise.
