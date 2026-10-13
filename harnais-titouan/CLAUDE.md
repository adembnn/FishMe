# Bredouille — règles non négociables

App iPhone (SwiftUI, iOS 26 minimum, Liquid Glass) de pêche en eau douce en France, avec cartes à collectionner. Build Challenge Apple : build les 15-16 octobre 2026, gel du code vendredi 11 h, envoi vendredi midi [I, calendrier du plan `peche/04`].
Légende : **[F]** fait vérifié, **[I]** hypothèse ou décision à valider. **⚠** = nombre ou nom d'API Apple non vérifié : ne jamais l'écrire sans ce marqueur.

## Socle Apple (à lire en premier)

Le cadre Apple à respecter (HIG, Liquid Glass, composants, patterns, revue App Store, build) tient en une page : [docs/apple-design/00-socle.md](docs/apple-design/00-socle.md). Détail dans `docs/apple-design/01` à `04`, `docs/modalites-build-apple.md`, `docs/preflight-appstore.md`. Décisions produit tranchées : `docs/decisions-produit.md`. Tout agent lit le socle avant de travailler ; en cas de conflit avec une maquette ou un plan, le socle gagne, sauf décision écrite dans `decisions-produit.md`.

## La question qui compte

Avant toute tâche non triviale : **un pêcheur debout au bord de l'eau, une main mouillée, peut-il obtenir sa carte en 2 taps, sans compte, sans réseau, sans que l'app lui dise quoi que ce soit de faux ?** Si la réponse n'est pas clairement oui, la tâche est à retravailler ou à couper.

## Règles numérotées

### A. Honnêteté du produit (aucune exception)
1. **Jamais de verdict légal.** L'app ne dit jamais si on peut garder un poisson, si une taille/période/quota est respecté, ni « tu as le droit ». Texte fixe : « Cette application ne connaît pas les règles de pêche locales et ne dit jamais si une prise est légale. Consulte la fédération de pêche de ton département. » Incertitude : pencher vers « relâche ou vérifie ». Voir skill `wording-interdits-bredouille`.
2. **Jamais « Pokédex », « Pokémon », ni visuel qui y ressemble** (nom, code, commentaires, captures, métadonnées). Règle 5.2.1 [F, `peche/03`].
3. **Libellé de rareté exact** : « présent sur X % des stations scientifiques de l'OFB » (avec le territoire : « du Loiret »). **Jamais** « probabilité de capture », « chance de prise », « poisson rare en général ». Mention permanente : « Rareté d'après les relevés scientifiques de l'OFB. Ce n'est pas une mesure de la pêche. » Voir skill `donnees-ofb-rarete`.
4. **Pas de pourcentage d'identification** (« reconnu à 94 % » est interdit). L'app propose 3 espèces du département, l'utilisateur confirme toujours, « Aucune de ces espèces » est toujours présent.
5. **Pas d'emoji dans l'interface** : SF Symbols uniquement. Vérifiable par recherche texte dans les chaînes affichées.
6. **Photos d'entraînement : CC0 ou CC-BY seulement** (jamais NC, jamais SA ambigu), avec manifeste de licences. Photos de pêcheurs : consentement écrit.

### B. Vie privée et friction
7. **Aucune création de compte, aucun login**, ni « Sign in with Apple ». Pas de SDK d'analytics ni de pub, pas d'ATT. Tout est sur l'appareil.
8. **Hors ligne d'abord** : capture, propositions, révélation, collection, bredouille, partage d'image fonctionnent en mode avion. Aucune requête réseau dans le cœur.
9. **Budget de friction : 2 taps de l'ouverture à la carte révélée** (obturateur, puis tap sur l'espèce) ; l'app s'ouvre sur la caméra ; aucun écran avant ; aucune permission avant le tap qui en a besoin. Le plafond du cahier des charges (E1 : 4 taps, 15 s) est un filet de sécurité, pas la cible. Voir skill `zero-friction-2-taps`.
10. **Localisation facultative, jamais en arrière-plan, jamais exacte dans un partage.** Lieu flou (département ou maille d'environ 5 km). Aucune incitation à se rendre à un endroit précis.

### C. Design
11. **Liquid Glass seulement sur les barres, boutons et feuilles, jamais sur la carte à collectionner ni sur le contenu**, jamais verre sur verre. Voir skill `liquid-glass-swiftui`.
12. **Pas de chasse au gros ni au rare** : XP indépendants de la rareté et de la taille ; espèces protégées = « À observer et relâcher », sans rareté ; exotiques = carte spéciale « Exotique ».

### D. Vérification et honnêteté technique
13. **Rien n'est « fini » sans vérification réellement exécutée.** Pas de « ça devrait marcher ». Il faut distinguer deux niveaux et le dire dans chaque compte rendu :
    - **Vérifiable sous Windows (Titouan)** : scripts Python (`python Tools/check/check_all.py`), tests purs du cœur `PecheCore` (`swift test` si la toolchain Swift Windows est installée ; sinon dire « non exécuté »), lint de formulations (mots interdits, emoji, libellé de rareté), validation des JSON de données, cohérence des licences d'images.
    - **Vérifiable seulement sur le Mac d'Adem** : compilation de l'app (XcodeGen + xcodebuild), rendu des `#Preview`, Liquid Glass réel, holo/Core Motion, caméra, Foundation Models (échoue au simulateur, appareil obligatoire), StoreKit, test mode avion, accessibilité, performances.
    - Formule obligatoire en fin de lot : « Vérifié : X (commande, résultat). Non vérifié, à compiler sur Mac : Y. »
14. **Chaque fichier Swift de Titouan est autonome et a un `#Preview`** (données factices intégrées, aucune dépendance à l'environnement live). Voir skill `ecrire-swift-sans-compiler`. Il ne touche jamais `project.pbxproj` (il n'existe pas dans le dépôt : `project.yml` XcodeGen est la seule source).
15. **Tout nombre ou nom d'API Apple non vérifié est marqué ⚠** (dans le code en commentaire `// ⚠ à vérifier`, dans les docs en texte). Un ⚠ n'est retiré que par quelqu'un qui a ouvert la doc ou compilé.
16. **Une tâche ne touche que son périmètre déclaré** (fiche de lot). Besoin hors périmètre : le signaler, pas l'embarquer.
17. **Les secrets, clés, certificats, profils de provisionnement, `.env` ne sont jamais lus, loggés, ni commités.** Voir skill `securite-livrable` et `.claude/HOOKS-A-INSTALLER.md`.

## Périmètre par propriétaire (un fichier = un propriétaire) [I, repris de `peche/05`]

| Propriétaire | Dossiers |
|---|---|
| **Adem** (Mac, iPhone, soumission) | `PecheApple/`, `project.yml`, `ci_scripts/`, `.github/workflows/`, `App/BredouilleApp.swift`, `App/Features/{Shell,Capture,Map,Paywall,Onboarding}/`, `App/Config/`, signature, App Store Connect |
| **Titouan** (PC Windows, jamais de compilation de l'app) | `PecheCore/`, `Tools/` (pipeline, `check/`, `eval/`), `docs/`, `App/Features/{Collection,Bestiary,Achievements,Card,Identify,Trip,Prepare,Legal,Profile}/` (hors câblage), `App/Design/`, `App/Resources/`, textes, prompts |
| **Business** (les deux autres membres) | Textes marketing et métadonnées App Store, photos de pêcheurs avec consentement, relecture des fiches espèces, contact fédération, pitch et vidéo de secours. Écrit dans `docs/business/` uniquement. |

Un fichier hors de son périmètre : ouvrir une issue ou un message, ne pas l'éditer.

## Méthode « lots » (obligatoire ici : 2 devs + sous-agents en parallèle)

Voir [docs/methode-lots.md](docs/methode-lots.md). Résumé : un lot = une fiche `plan/lots/Lxx.md` avec périmètre de fichiers strict, critères d'acceptation vérifiables, estimation ; une ligne dans `plan/SUIVI.md`, réservée avant de commencer ; commits `Lxx: résumé` ; « fix forward » (un build cassé se corrige dans les 15 minutes).

## Boucle de travail

1. Lire la fiche du lot (périmètre, critères d'acceptation).
2. Construire, petit, sans sur-ingénierie.
3. Vérifier réellement : `python Tools/check/check_all.py` (via `.claude/verify.json`), plus les tests Swift si disponibles. Noter ce qui reste « à compiler sur Mac ».
4. Agents de revue, **seulement aux jalons** (voir `docs/harnais-bredouille.md`) : `verificateur-wording` sur tout texte affiché ; `revue-ux-2taps` sur tout parcours ; `auditeur-donnees` sur tout JSON de données ; `revue-appstore` avant la soumission et sur les diffs sensibles (permissions, paywall, mentions légales) ; `critique` avant de clore un lot non trivial ; `coupeur` quand l'heure avance (jeudi 15 h, vendredi 9 h) ; `inspecteur-harnais` une fois, mercredi.
5. Fin de lot : formule « Vérifié / Non vérifié » (règle 13), commit `Lxx:`, mise à jour de `plan/SUIVI.md`.

## Sous-agents et modèles

Recherche, boilerplate, génération de textes de fiches : modèle léger possible. Agents de jugement (`critique`, `coupeur`, `inspecteur-harnais`, `revue-appstore`, `revue-ux-2taps`, `verificateur-wording`, `auditeur-donnees`) : modèle fort.

## Décisions ouvertes à ne pas trancher en silence [I]

Les rapports se contredisent sur : (a) les seuils et noms des classes de rareté (30/12/4/1 % sur les opérations dans le descriptif et `build_rarete.py` ; 50/25/10/3 % sur les stations dans `04` ; 30/10/3/1 % dans `02`) ; (b) la grille gratuit/Pro (descriptif : 15 cartes ; `04` : 1 département et 30 prises) ; (c) le plafond de friction (2 taps cible, 4 taps/15 s plafond) ; (d) stockage JSON (`05`) ou SwiftData (`06`, `08`) ; (e) moment de la demande de localisation. **Tant que non tranché, suivre `peche/05` (JSON, seuils paramétrables dans un fichier de config) et signaler le point dans le compte rendu.**
