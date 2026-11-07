# Passation FishMe — 7 nov. 2026

À lire en premier par la nouvelle session. Dossier de travail : `~/FishMe/travail/FishMe`, branche `fishme-tout` (poussée sur `adembnn/FishMe`).
Lancer la session avec le mode « contournement des autorisations » choisi dès le départ (impossible à changer en cours de route).

## Décisions de Titouan (détail : CLAUDE.md, « Décisions du 7 nov. »)
- US : tous les États, 3 niveaux (50 États en niveau 1 ; règles par espèce en niveau 2 par double lecture ; par plan d'eau en niveau 3 si un jeu ouvert existe).
- Verdicts : interdit / à vérifier / donnée absente + lien de l'agence. Jamais « autorisé », « allowed », « legal », « tu peux la garder » dans un texte affiché.
- Niveau 1 sans règle par espèce → « donnée absente » + lien de l'agence.
- Règles françaises : conserver, mais réécrire les phrases « autorisé » en gardant le sens exact.
- Une app, plusieurs régions (FR / US). Communauté : écran « bientôt » en v1, réseau en v2.
- Photos : non libres admises pour l'entraînement, mais iNaturalist l'interdit (robots.txt) → GBIF, licences CC seulement. Aucune photo dans git.
- Compte Apple : compte personnel de Titouan ; confirmation en attente (il écrit à Apple).
- Spark (SDK MWM) : attendre le SDK annoncé par MWM, ne rien changer. Les clés Spark du code sont celles de MWM : à retirer avant publication sans accord MWM.
- Appel MWM : résumé dans `~/FishMe/travail/session/transcriptions/` (local, hors git, jamais envoyé à un service externe). Ne jamais ouvrir ni committer le README MWM (mot de passe).

## État
- Fusion d'environ 40 branches dans `fishme-tout` ; app compile ; 673 tests Core verts.
- Recherche US : `reports/us/*.md` (10 rapports + synthèse). Outils : `outils/us/`.
- Niveau 1 : 32/51 États vérifiés (`outils/us/etats/`).
- Réécriture des phrases « autorisé » (4 lots) : chiffres identiques, seuls la phrase et le lieu changent (`reports/reformulation-regles/`).
- Widget aquarium : piste `douce` (30 copies, 3 images/s sur 10 s, échelle constante, balancement lent avec demi-tour). Plus de carrés ni de texte de debug. Mesure simulateur : 19 Mo en régime, 32 Mo en pic.

## Reste à faire
1. Widget : pic de 32 Mo, proche du plafond d'environ 30 Mo sur appareil. Réduire (moins de copies, moins d'entrées de timeline, moins de poissons) et mesurer en Release ; tester medium/large, « Réduire les animations », texte accentué ; vérifier sur un vrai iPhone.
2. Tests app : lancer `xcodebuild test`. UI tests rouges connus : tests communauté (il faut `-communaute.reseau YES`), Pescedex ×2 (non investigués). B5/B6 ouverts, B10 non reproduit.
3. Règles FR : 2 phrases « est permis » dans `regles/54.json` ; `valeur.texte` « autoris… » volontairement gardé.
4. US : consensus TX/FL/NC/NY non fait, MI partiel ; seuls WI et MN sont chargés dans `regles-us/` ; NC-A vient d'eRegulations (tiers).
5. États niveau 1 non vérifiés : AZ CA ID KS KY LA ME MD MA MI MS MT NE NH NJ NM NC RI TN.
6. Écrans US : bloc règles à 3 verdicts, âge minimum 13+, anglais complet (30 chaînes dans `Localizable.xcstrings`).
7. Modèle de reconnaissance : réentraîner avec les espèces US (photos GBIF CC).
8. Apple : Bundle ID / Team ID et compte en attente ; `scripts/migration/migrer-identifiants.py` (en simulation seulement). Réponse MWM : demander à Martin le SDK et la clé pour le nouveau Bundle ID ; on peut livrer sans.
9. CLAUDE.md : ajouter les décisions plus tardives (niveau 1 « donnée absente + lien », réécriture « autorisé », Spark en attente, widget).

## Recette technique
- PATH : inclure `/Applications/Xcode.app/Contents/Developer/usr/bin` (git, xcodebuild).
- Build : `xcodebuild build FISHME_ICLOUD=NO -project BuildChallenge.xcodeproj -scheme BuildChallenge -configuration Debug -destination 'platform=iOS Simulator,id=0177EFBF-7994-4955-AD32-589A5FE26AB6' -derivedDataPath /private/tmp/claude-501/dd-final CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual`
- Un seul build à la fois : verrou `mkdir /tmp/fishme-build.lock`.
- Lancer l'app avec `-FishMeForcerPro YES`.
- `gh` portable : `~/FishMe/travail/bin/gh` (se reconnecter par code si le jeton est invalide).
- Mesure mémoire du widget : `footprint <pid>` (champ `phys_footprint_peak`).
- Harnais : `docs/atelier.md`, `docs/lots.md`, `docs/verifier.py`, `outils/atelier/lots.py verifier` (0 trou à ce jour).
- Limite : 20 sous-agents simultanés. `/tmp` est vidé au redémarrage.
