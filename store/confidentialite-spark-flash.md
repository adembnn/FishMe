# Confidentialité, étiquettes « App Privacy » et SDK Spark Flash (S1)

> **S2, 19 oct. 2026 :** pour le build qui porte le réseau social, §2 et §3 sont remplacés par `app-privacy.md` (contenu d'utilisateur : oui, plus de « 4+ », `UserID` lié, nouveaux types). Ce fichier reste juste pour le build sans réseau et pour la liste de questions à MWM (§4).

Préparé en avance par Sullyvan (lot S1, tenu par Adem), le 15 oct. 2026. Sources : `CLAUDE.md`, `docs/fiches/S1.md` (Contrat), `docs/app-store.md` (lignes 5, 6, 17, 19), `docs/reports/app-store.md`. **Rien ici n'est un texte juridique** : la politique de confidentialité et les conditions sont assemblées par le questionnaire de MWM (`get_legal_questionnaire`, `save_legal_answers`, `draft_legal_document`), non branché dans cette session. Ce fichier prépare les réponses ; elles doivent être identiques aux étiquettes ci-dessous.

Légende : **[?]** = à confirmer par MWM ou dans le build.

## 1. Les 5 clauses que le brouillon de MWM doit contenir

| # | Clause | Fondement dans le plan | À vérifier dans le brouillon de MWM |
|---|---|---|---|
| 1 | La position précise sert sur l'iPhone seulement ; aucun coin exact n'en sort | `CLAUDE.md` (« Aucun coin de pêche exact ne quitte l'iPhone ») ; E1 | la clause dit « sur l'appareil » et ne parle d'aucun envoi de coin |
| 2 | Les photos enregistrées n'ont pas de GPS | `CLAUDE.md` | la clause existe ; sinon la poser en réponse libre [?] |
| 3 | Spark Flash est nommé ; ses données ne sont pas liées à l'identité | manifeste du SDK 0.5.8 : 7 types, `NSPrivacyTracking` faux | le nom « Spark Flash » et le « non lié » apparaissent |
| 4 | Les collections ne se montrent qu'aux amis invités | décision du 12 oct. ; **les amis sont hors du build soumis** (`parcours-demo.md`) | si les amis ne sont pas dans la version soumise, la clause décrit « aucun partage » et non un partage ; à dire à MWM [?] |
| 5 | Le champ `jurisdictions` couvre la France et l'UE | `fiches/S1.md` | `jurisdictions` contient FR et UE |

Si une clause manque : arrêt, e-mail à build-challenge@mwm.ai (Adem l'envoie). Aucun texte n'est écrit à la place de MWM.

## 2. Déclarations « App Privacy » (App Store Connect), proposées

Règle d'Apple : on déclare ce qui **quitte l'appareil** (collecté, vers nous ou un tiers). Ce qui reste sur l'iPhone ne se déclare pas.

| Donnée | Où elle va | Déclarer ? | Lien à l'identité / suivi | Statut |
|---|---|---|---|---|
| Position précise (carte, spot, règles) | reste sur l'iPhone | non | sans objet | exact selon `CLAUDE.md` ; à vérifier dans le build (aucun appel réseau avec le coin exact) [?] |
| Photos de prises | restent sur l'iPhone, sans GPS | non | sans objet | idem [?] |
| Achats | Apple + Spark Flash (SDK) | oui : Historique d'achats | non lié, pas de suivi | d'après le manifeste du SDK, à confirmer par MWM |
| Interactions avec le produit | Spark Flash | oui : Interaction avec le produit | non lié, pas de suivi | idem ; mesure éteinte tant que l'utilisateur n'a pas consenti (L6, ligne 17) |
| Données de performance | Spark Flash | oui : Données de performance | non lié, pas de suivi | idem |
| Plantages | Spark Flash (MetricKit) | oui : Données de plantage | non lié, pas de suivi | idem |
| Autres données de diagnostic | Spark Flash | oui : Autres données de diagnostic | non lié, pas de suivi | idem |
| Identifiant utilisateur | Spark Flash (identifiant d'installation) | oui : Identifiant utilisateur | non lié d'après le manifeste [?] | à confirmer : un identifiant est souvent classé « lié » par Apple |
| Identifiant d'appareil | Spark Flash (`identifierForVendor`) | oui : Identifiant d'appareil | non lié d'après le manifeste [?] | idem |
| Localisation approximative déduite de l'adresse IP | Spark Flash (conditions du SDK, §6) | **oui si le SDK la tire** : Position approximative | à confirmer | **question n° 3 à MWM** ; absente du manifeste |
| Météo (WeatherKit) | un point arrondi ou la position d'une station OFB, pour servir la requête | par défaut non | sans lien avec l'identité d'après Apple [?] | à confirmer avec MWM (ligne 6, R6) |
| Niveau des rivières (Hub'Eau) | un code de station, rien de personnel | non | sans objet | exact selon `CLAUDE.md` |
| Notifications (« préviens-moi », vigilance) | locales | non | sans objet | à confirmer dans le build [?] |
| Suivi (ATT) | aucun | « Non, aucun suivi » | `NSPrivacyTracking` faux | à confirmer pour le SDK |

Les réponses du questionnaire de MWM reprennent chaque ligne « oui » ci-dessus, sans plus, sans moins.

## 3. Autres déclarations liées

- **Questionnaire d'âge** (ligne 5, site d'App Store Connect) : contenu généré par les utilisateurs non (amis hors build) ; rien qui vise les enfants ; ne pas cocher « Made for Kids » (Spark Flash est interdit aux apps pour moins de 13 ans, `reports/app-store.md` §2.2). Réponses à jouer par la personne qui clique (rôle App Manager). Classification visée par Titouan : 4+, à rejouer avec le questionnaire officiel [?].
- **`ITSAppUsesNonExemptEncryption`** = NON (ligne 9) : à confirmer pour le SDK avec MWM [?].
- **Manifeste `PrivacyInfo.xcprivacy`** (lignes 7 et 19) : celui de l'app doit s'accorder avec celui du SDK ; « Generate Privacy Report » sur l'archive finale. Hors de `store/` : tenu par A.
- **Consentement** (R9, ligne 17) : ni initialisation ni événement du SDK avant le consentement ; refus = SDK éteint. Tant que L6 n'est pas vu dans le build TestFlight, la fiche ne doit pas écrire « aucun suivi » sans nuance : la description dit seulement « aucun compte, aucune publicité ».
- **Notes pour le relecteur** : `notes-relecteur-en.md` nomme Spark Flash et ne dit jamais « no third-party SDK » (la fiche de Titouan le disait à tort, refus R9 probable).

## 4. Liste à demander à MWM (e-mail à build-challenge@mwm.ai, envoyé par Adem)

Numérotée pour qu'une réponse puisse suivre les numéros. Preuve attendue : leur message, rangé dans `store/`.

1. Liste écrite, complète et datée, de ce que collecte Spark Flash 0.5.8 dans cette app : types de données, quand (avant ou après consentement), vers quel serveur, pour quelle durée.
2. Confirmation que le manifeste du SDK (7 types : achats, interactions, performances, plantages, autres diagnostics, identifiant utilisateur, identifiant d'appareil ; `NSPrivacyTracking` faux) est à jour, et que le SDK a son propre `PrivacyInfo.xcprivacy`.
3. Le SDK tire-t-il une localisation approximative de l'adresse IP (conditions §6) ? Si oui, elle est déclarée « Position approximative » ; si non, pourquoi les conditions la citent.
4. Identifiant utilisateur et identifiant d'appareil : MWM les classe-t-il « liés » ou « non liés » à l'identité au sens d'Apple ?
5. Le SDK fait-il quoi que ce soit avant l'appel d'initialisation ? Comment l'éteindre pour un utilisateur qui refuse (aucun envoi, aucune écriture) ?
6. Âge minimal : le SDK interdit les apps visant les moins de 13 ans (conditions §8). Quel avis pour une app de pêche tout public, sans « Made for Kids » ? (En France, le seuil de consentement est 15 ans : `reports/app-store.md` §2.2.)
7. `ITSAppUsesNonExemptEncryption` : le SDK n'emploie-t-il que le chiffrement du système (HTTPS) ?
8. Qui est le vendeur légal qui signe la politique de confidentialité, quelle adresse de contact joignable, et quel nom pour le copyright ?
9. WeatherKit et Hub'Eau : confirmer qu'il n'y a rien de plus à déclarer (point arrondi ou station pour WeatherKit, code de station pour Hub'Eau), et si le quota WeatherKit (500 000 appels par mois) est partagé avec d'autres apps de MWM.
10. Le questionnaire juridique accepte-t-il une version sans amis (collections invisibles pour tout autre utilisateur) pour la clause n° 4 ?
11. Quota de générations du serveur MCP (icône, captures) pour l'équipe : avant de lancer la moindre série.

## 5. À ne pas faire
- Ne rédiger aucune politique ni aucune condition à la place de MWM.
- Ne publier aucune page (`publish_legal_document`, `publish_landing_page`) sans le oui d'Adem écrit.
- Ne coller aucun identifiant de connexion du kit MWM dans ces fichiers, dans git ni dans un message.
