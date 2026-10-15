# Kit de départ MWM (équipe 01, « Frétille »)

Source : archive `01.zip` reçue des organisateurs (README du kit, projet Xcode, SDK Spark Flash 0.5.8, fichier StoreKit, plugin du MCP de MWM 0.30.5), lue le 15 octobre 2026 sans rien exécuter.
Légende : **[F]** lu dans le kit. **[I]** déduction. **⚠** à vérifier.
**Secrets.** Le README du kit contient un identifiant et un mot de passe de l'équipe pour la console MWM et le MCP, et les clés publiques du SDK. Ils ne sont ni recopiés ici, ni dans le dépôt. L'archive ne doit pas être commitée. Elle reste dans les Téléchargements.

## Ce que contient le kit [F]

| Élément | Contenu |
|---|---|
| Projet Xcode `BuildChallenge` | App SwiftUI minimale (un bouton qui envoie un événement), cible iOS 27.0, Xcode 27, signature automatique avec l'équipe MWM, identifiant `ai.mwm.build.challenge.team.01`, familles d'appareils iPhone et iPad, Swift 5.0, isolation par défaut sur l'acteur principal, tests et tests d'interface vides. |
| SDK Spark Flash 0.5.8 | Paquet Swift local (binaire) : mesure d'événements, enregistrement des achats, mesure de session. iOS 15 minimum. Déjà configuré dans `BuildChallengeApp.swift` avec les clés de l'équipe (bac à sable en Debug, production en Release). **Ne pas appeler `Spark.configure` une seconde fois** (erreur fatale). |
| `TestConfig.storekit` | Fichier StoreKit local : les achats sont simulés sans compte Apple. |
| Plugin MCP MWM | 14 skills et 3 commandes pour le serveur distant `mcp.mwm.ai/mcp` (voir plus bas). |
| README | Mise en route, abonnements, liens utiles, adresse de contact des organisateurs. |

**Règles de l'équipe** [F] : garder l'identifiant de l'app (les abonnements y sont liés) ; garder l'arborescence (le projet référence le SDK par chemin relatif) ; si on part d'un autre projet, ajouter le paquet local du SDK, copier la configuration des clés et sélectionner le fichier StoreKit dans le schéma.

## Abonnements disponibles [F]

Groupe « Premium Plan », 6 produits en dollars, à choisir parmi :

| Période | Prix (USD) | Essai gratuit |
|---|---|---|
| 1 mois | 4,99 / 6,99 / 9,99 | 1 semaine |
| 1 an | 34,99 / 49,99 / 69,99 | aucun |

Charger avec `Product.products(for:)` ; afficher un paywall prêt à l'emploi avec `SubscriptionStoreView`. Nom et description à définir dans App Store Connect une fois les produits choisis.

## Ce que le SDK collecte [F, fichier PrivacyInfo.xcprivacy du SDK]

Historique d'achats, interaction avec le produit, données de performance, données de plantage, autres données de diagnostic, identifiant utilisateur, identifiant d'appareil. Aucune donnée liée à l'identité, aucun suivi (`NSPrivacyTracking` faux). Le journal des modifications mentionne aussi l'envoi d'informations sur l'appareil, de données de transaction de l'App Store et de métriques système.

## MCP de MWM [F]

Serveur distant `https://mcp.mwm.ai/mcp`, authentification OAuth avec le compte d'équipe. Il donne accès aux données de marché de MWM et au compte App Store Connect :
- **Fiche App Store :** audit, rédaction, vérification des limites, envoi des textes, des captures, de l'en-tête iOS 27.
- **Visuels :** icônes, captures générées depuis de vrais écrans.
- **Légal :** questionnaire, puis politique de confidentialité et conditions publiées à une adresse stable. Le texte vient d'une bibliothèque de clauses validée par des juristes ; l'agent ne rédige pas, et ne reprend pas un texte existant.
- **Version et revue :** état de la version (de « modifiable » à « en ligne »), builds traités, création de la version et **soumission à la revue d'Apple**.
- **Autres :** analyse des avis, pages produit personnalisées, événements dans l'app, page web de l'app.
Installation : dans Claude Desktop, Plugins puis Ajouter puis Importer l'archive du plugin, ou en ligne de commande `claude mcp add --transport http mwm https://mcp.mwm.ai/mcp` puis `/mcp` pour se connecter. L'authentification est à faire par un humain de l'équipe (mot de passe), jamais par un agent.

## Ce que ça change pour Bredouille [I]

1. **Compte, signature, identifiant : réglés par MWM.** Plus de compte Apple Developer à nous (fin de la question Q6). Le premier build part du projet du kit.
2. **Nos prix n'existent pas.** On avait 3,99 €/mois et 24,99 €/an avec 7 jours d'essai. Le kit propose du dollar : 4,99 / 6,99 / 9,99 par mois (essai d'une semaine), 34,99 / 49,99 / 69,99 par an (sans essai). Adem avait écrit « essai d'un mois » dans son brouillon à MWM : c'est impossible. Décision à prendre (voir `decisions-produit.md`).
3. **Le SDK contredit « aucun analytics ».** Notre règle 7 et `docs/store/app-privacy-answers.md` annonçaient « données non collectées ». Il faut déclarer dans les étiquettes de confidentialité les types listés ci-dessus et mettre à jour la politique de confidentialité. L'app reste sans compte et sans publicité. Le SDK doit se taire hors ligne (`try?` autour des appels), sans bloquer un achat.
4. **Le SDK impose de ne pas l'activer dans une app destinée aux moins de 13 ans** (rapport d'Adem sur les conditions du SDK). Notre choix « public général, 4+ » doit être relu avec cela : 4+ n'est pas « destinée aux enfants », mais à confirmer avec MWM ⚠.
5. **Le projet du kit remplace notre `project.yml`.** Adem tranche : ajouter nos dossiers au projet du kit, ou le décrire en XcodeGen. À corriger côté kit : cible iPhone seulement (le kit déclare aussi iPad), version de Swift, identifiant à ne pas changer.
6. **Le MCP prend en charge une grande partie de la soumission** (textes, captures, politique de confidentialité, version, revue). `gardien-appstore` et `ingenieur-release` doivent s'y adosser. Réserves : ne pas coller notre propre politique de confidentialité (le MCP veut sa bibliothèque de clauses) ; icônes générées par IA : à vérifier avec notre règle d'authenticité avant usage.
7. **Versions :** Xcode 27 et iOS 27 minimum (le kit le fixe). Cela lève le doute sur la lecture d'image par le modèle d'Apple, qui demande iOS 27.

## À mettre à jour dans le harnais (non fait)

- `docs/store/app-privacy-answers.md`, `privacy-policy-fr.md` : SDK Spark.
- `docs/decisions-produit.md` : prix et essai ; Q6 close.
- `docs/modalites-build-apple.md`, `docs/preflight-appstore.md` : compte MWM, projet du kit, MCP.
- `CLAUDE.md` règle 7 (aucun SDK d'analytics) : exception Spark Flash, imposée par les organisateurs.
