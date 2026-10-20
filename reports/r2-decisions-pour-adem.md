# R2 : ce que tu as à trancher pour lancer le réseau social

Décision débloquée : lancer ou non la vague 2 (L21 profil, L23 feed, L24 chat, L22 clubs). Lu le 20/10/2026 ; je n'ai rien mesuré ni compilé.
Sources : « rapport/ » = `docs/reports/reseau/` sur `origin/lot/rapport-reseau` (non fusionnée). « passation » = `docs/reports/passation-titouan-19-oct.md` (commit 59fdcd54). « tableau » = `reports/cloudkit-tableau-de-bord.md`. Après le fichier, la section citée.
Mots simples : CloudKit = le classeur iCloud d'Apple, qui sert de serveur gratuit. Base publique = le classeur que tout le monde lit. Conteneur = le classeur de l'app chez Apple. Quota = la taille de classeur qu'Apple accorde, elle grandit avec les pêcheurs actifs.

## 1. Ce que R2 conclut

1. **Quota : aucun chiffre mesuré.** Le rapport écrit « aucune mesure n'existe à ce jour » (rapport/quota.md, « État honnête »). Seul fait lu chez Apple : jusqu'à 1 Po de données publiques. Le quota par pêcheur actif, les requêtes par seconde et la taille max d'un fichier sont « non lus » ; la page Apple des quotas répond 404 (quota.md, « En bref »). Les projections à 1 000, 10 000 et 100 000 pêcheurs sont vides (quota.md, « Projection »). Le « 100 Mo par pêcheur » vient d'un article non Apple, écarté par le rapport lui-même.
2. **Chat : aucune latence mesurée** (rapport/latence.md, « État honnête »). Estimation, pas mesure : un chat « à la minute », l'écran dit « envoyé », jamais « lu » (latence.md, « Conseils »). Non testé : si Apple accepte les notifications sur la zone partagée du chat (latence.md, « Doutes », point 1). Un chat « à la seconde » demande un service payant.
3. **Modération : le circuit est écrit** (rapport/moderation.md, « Le circuit retenu » : signaler, masquer, bloquer, retirer à la main dans CloudKit). Trois écarts avec ta décision 5 : l'e-mail **automatique** est impossible sans serveur ; « retrait sous 24 h » est notre engagement, pas un délai écrit par Apple ; on ne peut pas exclure quelqu'un, il recrée un surnom (moderation.md, « Ce qu'on ne peut pas faire sans serveur »).
4. **Verdict honnête :** R2 ne montre pas que CloudKit bloque le chat ou la modération, mais ne le prouve pas non plus (rapport/decisions.md, « Où on en est » : rien n'est mesuré). Le prototype de mesure n'a jamais été compilé (decisions.md, « Points ⚠ »). Ta décision 2 (CLAUDE.md) garde donc CloudKit.
5. **Ce qui existe :** le code de L21 à L24 est écrit sans compilateur. Seuls les 520 tests du paquet Core passent, dans Docker ; tout `App/` est non vérifié (passation, section 0 ter).

## 2. Décisions

Règle : 3 questions à la fois. Bloc 1 maintenant, blocs 2 et 3 après ta réponse. Sans réponse, le choix par défaut s'applique, réversible avant la mise en ligne.

### Bloc 1 : pour lancer (à répondre maintenant)

**1. Lancer la vague 2 sur CloudKit sans chiffres ?**
- a. Oui : photos, commentaires, chat et clubs partent ; la **vidéo de 15 s** et toute promesse de rapidité du chat attendent les mesures.
- b. Non : on attend les mesures complètes avant d'écrire du code réseau.
- c. Non : on part sur Firebase ou Supabase (repli de ta décision 2).
- Reco : **a** (quota.md, « Où la vidéo devient le problème », piste 3 : photos d'abord, budget : non).
- Défaut : a. Écartée, la plus forte : b, qui évite de bâtir sur un quota inconnu mais bloque tout tant que le conteneur manque (section 3).
- Effet : la vidéo de ta décision 4 (19 oct.) arrive dans une mise à jour.

**2. Qui mesure le quota et le chat, et sur quel classeur ?**
- a. Sullyvan lance `outils/reseau/` sur son Mac, sur un conteneur d'essai à lui (pas celui de l'app), avec 2 comptes iCloud pour le test du chat.
- b. On attend le conteneur de l'app et on mesure dessus.
- Reco : **a** : la fiche R2 l'autorise (`docs/fiches/R2.md`, « Si ça coince ») et ça ne dépend pas de ton droit manquant. Temps de Mac nécessaire : non chiffré (decisions.md, « Questions restantes », point 3).
- Défaut : a. Écartée : b, plus fidèle à la réalité mais bloquée.

**3. Signalement : e-mail automatique ou prérempli ?**
- a. Prérempli (`mailto:`) + un enregistrement « Signalement » que l'équipe lit : gratuit, mais le pêcheur envoie l'e-mail lui-même.
- b. Un petit service payant envoie un vrai e-mail automatique (budget : oui, coût non chiffré).
- c. a + alerte sur l'iPhone du référent via CloudKit, à tester (moderation.md, « Le circuit », option 1).
- Reco : **a**, puis c si le test marche. L'écran n'affiche « signalé » que si l'enregistrement est bien écrit.
- Défaut : a. Écartée : b, la seule qui tient ta décision 5 à la lettre ; utile si le volume dépasse ce que trois personnes lisent.

### Bloc 2 : conditions de L21 à L24 (ensuite)

**4. Qui lit fishme.app@gmail.com chaque jour, week-end compris ?**
- a. Une semaine chacun, en rotation Titouan, toi, Sullyvan ; un autre remplace en cas d'absence (moderation.md, « Qui lit la boîte »).
- b. Toi seul. c. Titouan seul.
- Reco : **a** (budget : non). Défaut : a. Écartée : b, qui évite tout flou mais fait de toi un point unique.

**5. Surnom seul, et réseau gratuit ?** (Titouan a décidé le 19 oct. contre ta décision 3 : rapport/decisions.md, « Décidé le 19 oct. », nos 1 et 10)
- a. Surnom + avatar seulement, plus de nom ni prénom même privés ; rien du réseau derrière le Pro.
- b. Garder nom et prénom facultatifs et privés (ta décision 3).
- c. Identité comme a, mais une partie du réseau réservée au Pro.
- Reco : **a** (moins de données, moins de risque 5.1.2). L'abonnement face aux gratuits reste ouvert (CLAUDE.md).
- Défaut : a. Écartée : c, qui garde une porte vers l'abonnement.

**6. Les clubs créés avant la mise à jour : migrer ou recréer ?**
- Question pour toi : une version avec clubs est-elle déjà chez des testeurs hors équipe ? Si oui, b.
- a. Recréer son club, sans migration : FishMe n'est pas publiée et un club local n'a aucun autre membre (rapport/migration-clubs.md, « Ce qui existe »).
- b. Migrer, avec un écran de consentement par club (environ 1,5 h, estimation de la fiche L22).
- Reco : **a** si non. Défaut : a. Écartée : b, la seule qui ne fait rien perdre à un testeur.

### Bloc 3 : à confirmer avant la mise en ligne

**7. Âge minimum de 15 ans, par simple déclaration ?** (rapport/decisions.md, n° 2)
- a. Oui, relu par un juriste de MWM. b. Pas de réseau avant l'avis du juriste. c. 16 ans.
- Reco : **a**. Défaut : a. Écartée : b, la plus prudente. Le 15 vient de Titouan, non sourcé ; l'outil d'âge d'Apple n'a pas été étudié (passation, section 2).

**8. Lieu d'une publication.**
- a. Défaut « département seul » ; « aucun lieu » = absente du fil de région, visible des amis et clubs ; sur un plan d'eau nommé, seulement « département seul » ou « aucun lieu » (CLAUDE.md, décision 4 ; decisions.md, n° 3 et 4).
- b. « Aucun lieu » apparaît quand même dans le fil de région.
- Reco : **a**. Défaut : a. Écartée : b, plus de contenu par région. Zone grise : cours d'eau + département peut désigner un coin à un connaisseur (decisions.md, « Règles d'or »).

**9. Chat de club : limites acceptées pour la première version ?**
- Seul le fondateur admet des membres ; s'il part, plus d'admission ; retirer un membre ne lui retire pas l'accès ; plafond d'environ 100 participants, non lu chez Apple (passation, section 5, « L24 (club) »).
- a. Oui, on l'écrit dans l'écran. b. Clubs sans chat au départ. c. Fournisseur externe.
- Reco : **a**. Défaut : a. Écartée : c, la seule sans ces limites, mais elle coûte un budget et change ta décision 2.

Appliqué sans question (dis non pour changer) : `Blocage` en base privée du pêcheur (decisions.md, « Questions restantes », point 2) ; une seule liste de mots interdits LDNOOBW, licence CC-BY (moderation.md, « Le filtre ») ; mode démo du feed et du chat gardé en Release pour le relecteur d'Apple (decisions.md, n° 11).

## 3. Ce qui bloque tant que le conteneur n'existe pas

Le conteneur `iCloud.ai.mwm.build.challenge.team.01` est écrit dans `Config/BuildChallenge.entitlements:9`, mais ton compte reçoit « insufficient permissions to modify containers » : il ne peut pas le créer chez Apple. Il faut un rôle plus élevé sur le compte développeur de l'équipe MWM ; rôle exact non vérifié, à demander à MWM (moderation.md, « Qui lit la boîte »).

Bloqué :
- Créer les 15 types (7 publics, 8 privés) et leurs index. Sans index « Queryable », l'app marche en Development et casse en Production (tableau, sections 1 et 5).
- Régler les droits (« Signalement » en création seule, lecture réservée à l'équipe) et déployer le schéma en Production (tableau, sections 2 et 3).
- Tout test réel de L21 à L24 sur iPhone : publier, aimer, commenter, signaler, chat (passation, section 8).
- Abonnements et notifications du chat : `aps-environment` vaut encore `development` (tableau, section 5).
- Les mesures sur le vrai conteneur (question 2).

Non bloqué :
- Les 520 tests Core dans Docker, et les textes juridiques de S2.
- Le mode démo du feed et du chat sans iCloud (passation, section 0 bis, avertissement 4).
- Les mesures sur un conteneur d'essai de Sullyvan (docs/fiches/R2.md).
- Sans iCloud actif, les clubs restent locaux (migration-clubs.md, « Cas limites »).

Non vérifié par moi : si Xcode compile `App/` sans le conteneur (signature, profil d'approvisionnement). À tester par Sullyvan.

Si tu réponds « 1. a / 2. a / 3. a » : je note R2 « validé avec réserves » dans `CLAUDE.md` (décision 1 du 19 oct.) et la vague 2 démarre, vidéo exclue.
