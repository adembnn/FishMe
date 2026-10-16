# Check-list de soumission : état au 16 oct. 2026 (S1 avancé par Sullyvan ; version soumise avec Amis, widget et Live Activity)

Reprend les lignes de `docs/app-store.md` et les prérequis de `docs/fiches/S1.md`. Case cochée = fait **et prouvé**. « Brouillon prêt » = texte écrit dans `store/`, pas encore validé. Tout le reste : « à faire ». Cette session n'a ni le serveur MCP de MWM, ni App Store Connect, ni le build TestFlight : aucune ligne qui les demande n'est cochée. **[?]** = non confirmé. Les preuves de code citées dans ce fichier se lisent sur `origin/claude/finir-app-ud5swp` (504ee2e, avance sur `mac/integration` 5780585) ; elles prouvent le code, pas le comportement sur iPhone ni dans App Store Connect.

## Prérequis de la fiche S1 (« Avant de commencer »)

| Case | Prérequis | État | Preuve |
|---|---|---|---|
| [x] | Nom de l'app choisi | fait : FishMe (Adem, 15 oct. 12h36) | `CLAUDE.md`, ligne « Nom de l'app » |
| [ ] | Serveur MCP de MWM connecté (`get_store_text_rules` répond ; `get_store_connections`) | à faire : le serveur répond 401 depuis le cloud (joignable, connecteur pas encore autorisé) ; suite d'appels prête dans `appels-mwm.md` | |
| [ ] | `store_send` et `store_publish` sur `confirm` | à faire (`get_assistant_settings`) | |
| [ ] | Quota de génération demandé à MWM | à faire : question n° 11 de `confidentialite-spark-flash.md` | réponse de MWM à ranger dans `store/` |
| [x] | Aucun identifiant de connexion du kit dans git | fait pour `store/` : recherche des deux mots du compte (anglais et français) dans `store/` : zéro résultat (relancée avant chaque commit) | sortie vide, le 15 oct. |
| [ ] | Questionnaire d'âge et « App Privacy » : réponses préparées | **brouillon prêt** : `confidentialite-spark-flash.md` §2 et §3 ; clic dans App Store Connect (rôle App Manager) à faire | |
| [ ] | Liste des fonctions réellement dans le build, refaite à la porte 3, validée par Adem | **liste à cocher prête** : `fonctions-du-build.md` ; liste provisoire = les 9 étapes E1 à E9 de `parcours-demo.md` avec les fonctions du 15 oct. après-midi, **non vérifiées dans un build** [?] | |
| [ ] | Vendeur légal, contact, prix en euros (colonne France) | à faire : question n° 8 à MWM + lecture de la colonne France | |
| [ ] | Bouton « photo d'exemple » dans TestFlight | libellé « Essayer avec une photo d'exemple » lu dans `lot/prise` (`PriseRacineView.swift:78`) ; à confirmer à l'écran par B | |
| [ ] | Liste écrite de MWM sur Spark Flash | à faire : questions n° 1 à 7 de `confidentialite-spark-flash.md` | message de MWM à ranger dans `store/` |

## Check-list de `docs/app-store.md`

| Case | # | Point | État | Preuve ou reste à faire |
|---|---|---|---|---|
| [ ] | 0 | Accès MWM (Paid Apps Agreement, invitations, DSA, délai de grâce) | à faire (A, avant L0) | réponse de MWM |
| [ ] | 1 | Xcode 27.0, iPhone seul, portrait | hors `store/` (A) | |
| [ ] | 2 | Textes de fiche | **brouillon prêt**, aligné sur E1 à E9, les décisions de 16h-17h et le paywall de L6 (15 oct. fin d'après-midi) : `fiche-fishme.md` (comptes faits à la main) ; reste : `review_store_text`, mots-clés tirés de `search_market_apps` / `analyze_market_keywords`, couverture des règles, nombre d'espèces reconnues, fonctions Pro à la porte 3, ligne de prix, catégorie | voir `a-trancher.md` |
| [ ] | 3 | Pages web : confidentialité et conditions par le questionnaire de MWM | **réponses préparées** : `confidentialite-spark-flash.md` §1 ; questionnaire, brouillon et vérification des 5 clauses à faire | |
| [ ] | 4 | Captures (écrans bruts par B, habillage par S1) | à faire, après le build ; une capture avec météo garde la marque Apple Weather visible | |
| [ ] | 5 | Questionnaire d'âge | **réponses préparées** (§3 de `confidentialite-spark-flash.md`), clic à faire | |
| [ ] | 6 | Étiquettes « App Privacy » | **réponses préparées** (§2), à confirmer avec la liste de MWM, puis clic | |
| [ ] | 7 | `PrivacyInfo.xcprivacy` de l'app | **fichier présent** : `App/PrivacyInfo.xcprivacy` (pas de suivi, aucune donnée collectée déclarée, `UserDefaults` raison CA92.1) ; **pas** de manifeste pour l'extension `FishMeWidget` (le widget lit un fichier de l'App Group, `WidgetAquarium/InstantaneAquarium.swift:77`, pas `UserDefaults` : probablement sans objet [?]) ; Amis envoie les cartes dans l'iCloud privé de la personne, jamais chez nous : à confirmer au moment de remplir « App Privacy » [?] ; case cochée seulement après « Generate Privacy Report » (A) | |
| [ ] | 8 | Textes d'autorisation en français | **présents dans le code** (`Config/BuildChallenge-Info.plist` : appareil photo, position en cours d'usage, ajout à la photothèque ; plus `CKSharingSupported`, `NSSupportsLiveActivities` au `project.pbxproj:550`) ; aucun accès aux contacts (le partage passe par `ShareLink`) ; à relire sur le build [?] | |
| [ ] | 9 | `ITSAppUsesNonExemptEncryption` = NON | hors `store/` ; confirmation du SDK : question n° 7 à MWM | |
| [ ] | 10 | Abonnements : seuls les produits montrés sont joints | **mensuel du paywall pas choisi** : `ChoixOffres.mensuelRetenu = nil` (`App/Abonnement/Produits.swift:24`), le paywall n'affiche que l'annuel tant qu'Adem n'a pas tranché (4,99 / 6,99 / 9,99) ; le mensuel choisi et l'annuel à 34,99 sont les seuls à joindre à la version | décision d'Adem |
| [ ] | 11 | Notes pour le relecteur, en anglais | **brouillon prêt**, 3531 octets (Python), étapes 7 à 9 ajoutées (Amis, widget, Live Activity) ; boutons et chaînes relus dans le code, tableau de preuves dans `notes-relecteur-en.md` ; manquent : coordonnées du quai de Charenton, lien de la vidéo (B), couverture des règles, contact, Apple ID de test pour le côté « recevoir » d'Amis, vérification sur le build | |
| [ ] | 12 | Disponibilité France, droits, sortie manuelle | à faire avec MWM | |
| [ ] | 13 | TestFlight | hors `store/` (A) | |
| [ ] | 14 | Envoi à la relecture | à faire sur le oui d'Adem ; `get_store_submission` doit ne lister ni `blockers` ni `missing` | |
| [ ] | 15 | E-mail d'Apple, publication à la main | vendredi dès 7 h | |
| [ ] | 16 | Projet MWM, identifiant jamais changé | hors `store/` (A) | |
| [ ] | 17 | SDK : rien avant le consentement | hors `store/` (A, L0 et L6) ; à relire sur le build [?] | |
| [ ] | 18 | Publication des pages par le MCP | à faire sur le oui d'Adem | |
| [ ] | 19 | « Generate Privacy Report » | hors `store/` (A) | |
| [ ] | 20 | Retrait du produit à 34,99 le 1er janv. 2027 | rappel au nom d'Adem [?] | |
| [ ] | 21 | WeatherKit : capacité et service sur l'identifiant | **entitlement présent** (`Config/BuildChallenge.entitlements`, `com.apple.developer.weatherkit`) ; **à cocher par Adem** dans le portail développeur sur l'identifiant `ai.mwm.build.challenge.team.01` (service WeatherKit, onglet App Services) | tableau de bord, « Bloquant pour Apple » |

## Capacités et identifiants, version avec Amis, widget et Live Activity

Tout se coche sur developer.apple.com (Adem) ; les entitlements du code ne suffisent pas, le profil de signature doit les contenir. Rien ci-dessous n'est coché : aucune preuve côté portail.

| Case | Capacité ou réglage | Preuve dans le code | À faire (Adem) |
|---|---|---|---|
| [ ] | iCloud / CloudKit, conteneur `iCloud.ai.mwm.build.challenge.team.01` | `Config/BuildChallenge.entitlements` (`icloud-container-identifiers`, `icloud-services` = CloudKit) ; même nom dans `App/Amis/ServiceAmis.swift:8` ; `CKSharingSupported` dans `Config/BuildChallenge-Info.plist` | cocher iCloud + CloudKit sur l'identifiant, créer le conteneur ; **déployer le schéma CloudKit en production** (les types d'enregistrement ne se créent qu'en développement) [?] |
| [ ] | App Group `group.ai.mwm.build.challenge.team.01` | dans les deux entitlements (`BuildChallenge.entitlements`, `FishMeWidget.entitlements`) ; lu par `WidgetAquarium/InstantaneAquarium.swift:69` | cocher le groupe sur **deux** identifiants : l'app et l'extension `ai.mwm.build.challenge.team.01.widget` (`project.pbxproj:704`) ; sans cela le widget reste vide |
| [ ] | Notifications push | **absente de l'entitlement** (pas de `aps-environment`) ; le code n'utilise aucun abonnement CloudKit (`CKSubscription` : zéro occurrence dans `App/`) et l'activité démarre avec `pushType: nil` (`Widget/Session/PilotageActivite.swift:22`) ; l'acceptation d'un `CKShare` passe par le délégué de scène (`App/Amis/RelaisInvitations.swift:48`) | aucune capacité Push exigée par le code actuel ; la case iCloud d'Xcode peut en ajouter une seule : la laisser si le profil la porte |
| [ ] | WeatherKit | `com.apple.developer.weatherkit` dans `BuildChallenge.entitlements` | cocher la capacité **et** le service WeatherKit sur l'identifiant MWM |
| [ ] | Live Activities | `INFOPLIST_KEY_NSSupportsLiveActivities = YES` (`project.pbxproj:550`) ; cible `FishMeWidget` intégrée à l'app (`project.pbxproj:14`, `:48`) | aucune capacité de portail ; à voir sur iPhone, réglage « Activités en direct » activé |
| [ ] | Cible widget signée | `CODE_SIGN_ENTITLEMENTS = Config/FishMeWidget.entitlements` (`project.pbxproj:689`) | créer l'identifiant de l'extension et son profil |

## Autres bloquants de la soumission

| Case | Point | État |
|---|---|---|
| [ ] | Vraie URL de confidentialité | **manque** : le code pointe vers la page d'Apple, provisoire (`App/RootView.swift:472`, utilisée au paywall et dans Mon club) ; brouillon en cours (`confidentialite-spark-flash.md`) ; publication par le MCP de MWM seulement après le oui d'Adem ; l'URL ira dans App Store Connect et remplacera la constante |
| [ ] | Texte de confidentialité à compléter | doit nommer iCloud (partage entre amis invités, supprimable par « Supprimer mes cartes partagées », `App/Amis/AmisView.swift:205`), WeatherKit, Hub'Eau, Spark Flash |
| [ ] | Mensuel du paywall | pas choisi (voir ligne 10) |
| [ ] | Contact de revue, lien vidéo, coordonnées du quai de Charenton | crochets laissés dans les notes |
| [ ] | Apple ID de test pour le côté « recevoir » d'Amis | à décider par Adem ; sans lui, le relecteur ne voit que l'invitation (notes, étape 7) |
| [ ] | Règle 1.2 (contenu d'utilisateurs) : signaler, bloquer | **code présent** (`App/Amis/PescedexAmiView.swift:49`, `:70`) ; à voir sur iPhone ; contact de signalement = adresse d'Adem, vide aujourd'hui (`ContactClub.adresse`) |

## Tests « fini » de `fiches/S1.md` : ce qui est déjà vérifiable dans `store/`

| Test | Résultat au 15 oct. |
|---|---|
| 4. Notes ≤ 4000 octets | 3531 octets (Python) : OK pour le brouillon |
| 5. `grep` des marques, des mots interdits, de les autres mots interdits sur `store/` | zéro résultat à chaque commit ; la recherche des marqueurs provisoires de la commande du test 5 est aussi vide, mais les crochets `[...]` et `[?]` du texte restent à remplir avant l'envoi |
| 5. Dernier `grep` sur `App/` (« viendra », « bientôt », « prochainement ») | hors `store/`, à faire à l'archive |
| 6. Relecture par S, phrase par phrase contre les captures | à faire après le build ; son nom ira dans le message du commit |
| 7. « Première minute » sur TestFlight | à faire sur l'iPhone |
| 8. Icône (2 appels de génération au plus) | à faire, aucun appel lancé |
| 9. Soumission | à faire sur le oui d'Adem |

## Refus probables (rappel R1 à R9) et ce que cette fiche en tient

- R7 (la fiche promet plus que le build) : la description a trois blocs conditionnels marqués ; rien n'est affirmé sur la couverture, les espèces reconnues ni les fonctions Pro avant la porte 3.
- R6 (météo sans Apple Weather) : « Apple Weather » est cité dans la description et la page Sources ; captures à contrôler.
- R9 (SDK sans consentement) : notes et déclarations nomment Spark Flash ; le consentement reste à vérifier dans le build.
- R4 (achat) : la ligne de prix est laissée en décision (point 2 de `a-trancher.md`).
