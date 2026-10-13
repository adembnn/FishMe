# Checklists : avant jeudi 9 h, fin du jour 1, soumission, pitch

Rédigé le 13 octobre 2026. **[F]** = exigence écrite dans les documents de l'équipe ; **[I]** = proposition. Le responsable est entre parenthèses : A = Adem, T = Titouan, S = Sullyvan, X = Alexandre. Cocher en remplaçant `[ ]` par `[x]` et dater. Les cases du pas-à-pas App Store Connect sont détaillées dans `docs/store/checklist-soumission.md` (déjà écrit) : ce fichier ne les recopie pas, il les référence.

## (a) Avant jeudi 15 octobre, 9 h

### Règlement et cadre
- [ ] (X) **Demander par écrit aux organisateurs** : (1) le code, les données et les assets préparés avant jeudi sont-ils autorisés (question Q12 du formulaire) ; (2) que veut dire « soumis » : build envoyée sur App Store Connect ou envoyée à la revue ; (3) l'équipe a-t-elle bien quatre membres déclarés (le formulaire n'en listait que trois [F, 00 §13]). **Si le code préparé est interdit, le plan bascule en « MVP strict » (voir `plan/SUIVI.md` §8 et §9).**
- [ ] (S) Déclarer honnêtement dans le formulaire ce qui existe avant le jour 1 : données, paquet Core, jeu d'images ; l'app, l'IA, l'UI et l'intégration sont construites sur place [F, 04].

### Comptes et accords (chaque case prend des jours, à lancer aujourd'hui)
- [ ] (A) Compte Apple Developer **actif** (adhésion payée, vérification d'identité terminée ; 24 à 48 h, plus avec la carte d'un tiers [F, 04]). Plan B : inscription d'un coéquipier.
- [ ] (A) **Accord « Paid Apps »** signé, coordonnées bancaires et fiscales saisies (sans lui, pas d'abonnement testable ni vendu). La validation peut prendre plusieurs jours : si elle n'est pas faite le 14 à 18 h, `paywallEnabled = false`.
- [ ] (A) **Bundle ID** créé : `fr.<équipe>.bredouille` [I] (remplacer `REMPLACER` dans `project.yml`), capacité In-App Purchase seulement.
- [ ] (A, X) Nom « Bredouille » réservé dans App Store Connect ; contrôle INPI en parallèle (le nom n'est pas vérifié [F, 00 §1]).
- [ ] (A) Équipe ASC : Titouan, Sullyvan, Alexandre invités ; groupe TestFlight interne créé ; Apple ID de chacun ajouté.
- [ ] (A) iPhone en mode développeur ; Apple Intelligence activé, modèle téléchargé, langue du système supportée ; **un iPhone iOS 27** disponible pour la mesure d'identification.
- [ ] (A) Xcode 26.6 (CI par défaut) et Xcode 27 installés.

### TestFlight et build à blanc
- [ ] (A) `xcodegen generate` puis build simulateur **verts** (le squelette n'a jamais été compilé) ; temps chronométré (G3).
- [ ] (A) Build à blanc uploadée et « Prête à tester » dans TestFlight interne **avant mercredi 18 h**, installée par au moins un autre membre.
- [ ] (A) Xcode Cloud connecté au dépôt (ou archive manuelle documentée).

### Swift et Python sous Windows (T)
- [ ] (T) Swift pour Windows installé : `winget install --id Swift.Toolchain -e --source winget`, Visual Studio 2022 + SDK Windows 11, mode développeur [F, 04 §0]. `cd PecheCore && swift test` vert ; sinon noter « non exécuté » et s'appuyer sur la CI Linux.
- [ ] (T) Python 3.11+ installé ; `python Tools/check/check_all.py` passe ; `pytest Tools/data-pipeline/tests` passe.
- [ ] (T) Compte GitHub avec 2FA ; dépôt cloné ; CODEOWNERS ajusté par fichier (voir `plan/SUIVI.md` §6bis).

### Jeu d'images et données
- [ ] (T) `Tools/eval/images/` : 12 espèces téléchargées [F, constaté] ; manifeste de licences complet (CC0 et CC-BY uniquement) ; `eval_manifest.csv` rempli (vérité terrain des 40 photos).
- [ ] (S) 5 pêcheurs contactés, ≥ 20 photos « poisson tenu en main » et « sur herbe » reçues, **consentement écrit** pour chacune.
- [ ] (T) Départements : 75, 78, 92, 95 générés [F, constaté] ; 71, 69, 33, 31, 13, 29, 74 relancés ; statuts de protection cohérents entre `species.json` et les fichiers de département.
- [ ] (X, S) Relecture business des fiches d'espèces et des statuts (Légifrance).

### CI
- [ ] (A) Workflows `core.yml`, `ios.yml`, `python.yml` verts ; durée d'un push ≤ 12 min (G4) ; version réelle de Xcode notée (`ls /Applications | grep Xcode`).
- [ ] (A) Décision dépôt public (minutes macOS gratuites) ou privé (x10) [F, 04 §1.9].

### Décisions à avoir prises (mercredi 21 h)
- [ ] Verdict de l'identification (GO / GO conditionnel / NO-GO) et plan B choisi (`docs/calendrier.md` §4).
- [ ] Durée minimale de sortie : 20 minutes ; grille gratuite : 15 cartes ; seuils : profil B ; essai : 3 ou 7 jours ; direction graphique A à E (`plan/SUIVI.md` §5).
- [ ] Agent `inspecteur-harnais` lancé une fois ; `.claude/HOOKS-A-INSTALLER.md` lu par Adem (installer ou non les hooks).

## (b) Fin du jour 1 (jeudi 15, vers 19-20 h)

- [ ] Jalon 2 atteint : **photo → 3 propositions → un tap → carte révélée et enregistrée → collection**, puis bredouille, sur iPhone réel, en mode avion.
- [ ] Budget de friction mesuré (enregistrement d'écran) : ouverture → carte en **2 taps** (seuil d'échec : 4 taps, 15 s [F, 09 E1]) ; lancement à froid à une caméra active ≤ 2 s (E2).
- [ ] Build TestFlight n° 2 installée par Sullyvan et Alexandre ; test T1 fait par 2 personnes non impliquées.
- [ ] Liste de bugs triée (bloquant / gênant / cosmétique) ; chaque bloquant a un propriétaire.
- [ ] CI verte sur `main` ; aucun build cassé non traité (« fix forward » 15 min).
- [ ] État des lots à jour dans `plan/SUIVI.md` (`fini` seulement si compilé et vérifié ; `à compiler` sinon).
- [ ] Décisions de coupe pour vendredi consignées (SUIVI §8) ; les lots coupés passent à `coupé`.
- [ ] Vidéo de secours v1 enregistrée (90 s, écran de l'iPhone, sous-titres) ; fichier copié sur deux appareils.
- [ ] Captures 6,9" : au moins 3 sur 5 prises ; aucune photo de poisson sous droits non libres.
- [ ] Coucher avant 1 h.

## (c) Soumission (vendredi 16)

Le pas-à-pas détaillé est dans `docs/store/checklist-soumission.md`. Points de contrôle propres au plan :

- [ ] (A) **Gel à 11 h** : plus aucun commit fonctionnel ; la build soumise est celle testée sur TestFlight.
- [ ] (A) Upload à 12 h ; build « traitée » avant 13 h 30 (délai 15 à 60 min, R-11) ; marge jusqu'à 14 h.
- [ ] (A) Test sur la build traitée : mode avion, refus de chaque permission, appareil sans Apple Intelligence, photo d'exemple, bredouille, partage, kill de l'app à 10 écrans.
- [ ] (A) **Paywall** : décision à 10 h ; si oui, produits « Prêt à soumettre », capture de l'écran paywall pour la revue, prix lus depuis StoreKit, phrase « Tes cartes restent à toi », « Restaurer » visible ; sinon `paywallEnabled = false`.
- [ ] (X) Métadonnées FR/EN, mots-clés sans marque, captures, URL de confidentialité et d'assistance en ligne (5.1.1(i)).
- [ ] (A, X) Étiquettes de confidentialité : « Aucune donnée collectée », cohérentes avec le code (aucun analytics).
- [ ] (A, X) Classification d'âge répondue honnêtement ; pas de catégorie « Enfants » (règles supplémentaires).
- [ ] (A) `ITSAppUsesNonExemptEncryption = NO` (clé `info:` de `project.yml`).
- [ ] (T, S) **Notes de revue FR + EN** : pas de compte ; l'identification s'exécute sur l'appareil ; sans Apple Intelligence, les modes de repli fonctionnent ; comment accéder à la **photo d'exemple** (appui long sur l'obturateur, Réglages → Mode démo, écran « Je ne vois pas de poisson ») ; le **Mode démo ramène la durée minimale de sortie à 1 minute** (à dire, pour que la bredouille soit testable) ; localisation facultative ; les liens « règle locale » ouvrent le site de la fédération ; comment tester l'abonnement.
- [ ] (T) Contrôles 2.1 (app complète, rien de cassé), 4.3 (différenciation : données OFB par département, bredouille, règle locale sans verdict), 5.1.1 (permissions, repli manuel), 5.2.1 (aucun « Pokémon »/« Pokédex » nulle part, y compris métadonnées et captures).
- [ ] (T) `python Tools/check/check_all.py` vert sur le commit soumis (aucun mot interdit, aucune phrase de verdict, aucun emoji dans l'interface).
- [ ] (A) Soumission à la revue cliquée **par le titulaire du compte** ; heure notée.
- [ ] (A) Rattrapage : dernière build possible à 14 h ; après 14 h, ne plus rien changer.

## (d) Pitch et vidéo de secours

### Pitch (3 minutes, S avec X)
- [ ] Script en 3 temps : (1) le problème et la baseline « Chaque sortie rapporte une carte » ; (2) démo : ouverture sur la caméra → photo → trois espèces → **un tap** → carte révélée avec effet holographique → partager ; (3) la **bredouille** (« Pas de prise, pas de souci ») et l'honnêteté : rareté d'après les relevés scientifiques de l'OFB, jamais de verdict légal.
- [ ] Phrases autorisées vérifiées contre 00 §14 : **jamais** « reconnu à X % », « tu as le droit de la garder », « meilleures chances de prise », « aucune app ne relie reconnaissance et règle locale ».
- [ ] Chiffres sourcés seulement (cartes de pêche, Génération Pêche notée 1,5/5 [F, 00 §2]) ; HOOKfr cité honnêtement comme concurrent.
- [ ] Démo sur un département fourni (78) ou sur le 95 avec ses limites assumées (9 stations).
- [ ] Trois répétitions chronométrées (vendredi 13-16 h), dont une en mode avion.
- [ ] Deux iPhone prêts, chargés, avec la build soumise ; câble et adaptateur ; notifications désactivées.

### Vidéo de secours
- [ ] Enregistrement d'écran de l'iPhone, 90 s, sous-titres, sans son indispensable ; parcours 2 (caméra → carte), 9 (bredouille), 10 (collection) ; photo d'exemple utilisée si pas de poisson réel.
- [ ] Version v1 jeudi 19-20 h avec la build du moment ; version finale vendredi 12-13 h avec la build soumise.
- [ ] Fichier en deux exemplaires (ordinateur du présentateur et clé), format lisible partout (H.264, 1080 x 1920 ou 16:9 avec cadres).
- [ ] Règle de bascule décidée à l'avance : si l'iPhone ne répond pas à la photo en 10 s pendant le pitch, lancer la vidéo sans commentaire d'excuse.
- [ ] Rien dans la vidéo ne présente comme réel un cache de démonstration ; la photo d'exemple est annoncée comme telle.
