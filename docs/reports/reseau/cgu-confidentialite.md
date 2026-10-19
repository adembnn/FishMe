# CGU et confidentialité : les paragraphes à changer pour le réseau social
Décision débloquée : donner à S2 (juridique et fiche) la liste exacte des textes à réécrire avant la vague 2, et à Adem de relire les nouveaux engagements envers les pêcheurs (gratuité, 15 ans, chat réservé aux membres, texte joint aux signalements).
Lu le 19/10/2026 (`docs/legal/conditions-fishme.md` version du 16 octobre 2026, numéro 1 ; `docs/legal/frequentation-confidentialite.md`). Je ne modifie pas `docs/legal/` : S2 reprend ces propositions.

## En bref
Corrigé le 19/10/2026 selon les décisions de Titouan (`decisions.md`). Les CGU actuelles disent trois choses que le réseau rend fausses : « jamais en public » (article 8), « seulement aux amis que tu as invités » (articles 11 et 13) et un compte qui n'efface que la sauvegarde et les cartes partagées (article 7). Ces phrases deviennent trompeuses : 5.1.2 d'Apple interdit de partager des données sans l'avoir dit ([guidelines](https://developer.apple.com/app-store/review/guidelines/)). Les textes ci-dessous sont des **propositions de brouillon à faire relire** par le juriste de MWM ⚠ (je n'ai pas de compétence juridique ; l'éditeur et le médiateur restent à renseigner par MWM). Après chaque changement : `python3 outils/legal/generer_conditions.py`, et `numero` monte de 1 (nouvelle acceptation).

## CGU : article par article
### Article 2, « Accepter ces conditions »
Actuel : « FishMe est faite pour les 15 ans et plus. »
À ajouter : « Un profil public (surnom, avatar) et des publications exigent d'avoir 15 ans ou plus. En créant ton profil, tu déclares avoir 15 ans ou plus et tu acceptes ces conditions. » Décidé : 15 ans minimum par simple déclaration, sans date de naissance ; l'accord aux conditions se donne à la création du profil. Raison : le surnom et les photos sont visibles de tous. Change avec un budget : non.

### Article 3, « Ce que fait l'app »
Ajouter une phrase : « Tu peux aussi publier des photos et des vidéos de tes prises, commenter, aimer, discuter avec tes amis et dans des clubs. » Ajouter : « Le réseau est gratuit. » (décidé le 19 oct. ; la carte, les règles et la lecture du Pescedex restent gratuites aussi). Change avec un budget : non.

### Article 7, « Ton compte et la sauvegarde de ta collection »
Actuel : « Tu peux supprimer ton compte ... Ta sauvegarde iCloud et tes cartes partagées sont alors effacées, et tes amis perdent l'accès à ce que tu as partagé. »
Remplacer par : « ... Ton profil public (surnom et avatar), tes publications, tes commentaires et tes likes sont alors supprimés, avec ta sauvegarde iCloud et tes cartes partagées. Les messages que tu as envoyés dans un club ou à un ami restent visibles de ses membres tant que la zone partagée existe : supprimer ton profil retire ton accès, pas leur copie chez les autres. »
Raison : 5.1.1(v) ([guidelines](https://developer.apple.com/app-store/review/guidelines/)) exige la suppression dans l'app quand l'app crée un compte ; le profil de FishMe est un compte de fait. ⚠ Le texte de 5.1.1(v) lu dit « si ton app permet de créer un compte » ; un profil public en est un à mon avis, non confirmé par Apple. Change avec un budget : non.
À vérifier avec L21 et L24 : la zone d'un chat appartient à son créateur (le fondateur du club, ou l'identifiant `p-…` le plus petit pour une paire) ; supprimer la zone l'efface chez les autres. Écrire ce que le code fait réellement.

### Article 8, « Amis et club : ce que tu partages » (à réécrire en entier)
Actuel : « Elle n'est visible que par les personnes que tu invites, jamais en public. Une carte partagée montre au plus le département de ta prise... »
Proposition, trois parties :
1. **Ta collection** : « Ta collection n'est jamais publique. Seuls les amis que tu invites la voient. »
2. **Tes publications** : « Quand tu publies une photo ou une vidéo, elle est visible par tous les utilisateurs de FishMe, pas seulement par tes amis. Tu choisis à chaque publication le lieu affiché : le département seul (proposé par défaut), le cours d'eau et le département, ou aucun lieu ; sans lieu, ta publication n'apparaît pas dans le fil de ta région. Jamais ta position GPS ni les coordonnées de ton coin ne sont publiées. »
3. **Les clubs et le chat** : « Les messages d'un club ne sont lisibles que par les membres du club. Les messages entre amis ne sont lisibles que par vous deux. Ils ne sont jamais publiés dans la base publique. Si tu signales un message, son texte est joint à l'e-mail de signalement et copié dans notre registre de signalements, pour que nous puissions le lire. »
Modération (à reprendre de l'actuel et à étendre) : « Aucun contenu choquant, haineux, violent, illégal, sexuel ou cruel envers les animaux n'est toléré. Ne révèle pas le coin exact d'un autre pêcheur. Tu peux signaler et bloquer toute publication, commentaire, message ou personne. Nous répondons à chaque signalement sous 24 heures : nous retirons le contenu en cause, et nous pouvons retirer le profil de la personne qui l'a publié. »
Surnom : « Ton surnom est public et doit rester respectueux : pas de nom réel d'une autre personne, pas d'insulte ni de marque. Nous pouvons le retirer. »
Change avec un budget : non pour le texte ; l'engagement de 24 h est tenu par les trois lecteurs de la boîte, un référent par semaine (`moderation.md`).

### Article 11, « Ce qui t'appartient »
Actuel : « En les partageant, tu nous autorises seulement à les transmettre aux amis que tu as invités, le temps du partage. »
Remplacer par : « Tes photos et tes vidéos t'appartiennent. En les publiant, tu autorises FishMe à les montrer aux autres utilisateurs selon le choix que tu as fait (amis, club ou tout le monde), tant que tu ne les supprimes pas. Tu peux les supprimer à tout moment. » La licence est limitée à l'affichage dans l'app, sans réutilisation commerciale ni publicité : un engagement à garder. Raison : 5.1.2(ii), pas de réutilisation sans nouveau consentement.

### Article 13, « Données personnelles »
Actuel : « Ta position précise et tes coins de pêche restent sur ton iPhone. Tes photos et ta collection sont sauvegardées dans ton iCloud, et envoyées seulement aux amis que tu invites... »
Remplacer par : « Ta position précise et tes coins de pêche restent sur ton iPhone. Ce que tu publies (photos, vidéos, légendes, lieu choisi, surnom, avatar, commentaires, likes) est enregistré dans la base publique iCloud d'Apple associée à FishMe et visible selon ton choix. Les messages de club et d'ami sont dans une zone partagée iCloud, lisible seulement par ses membres. FishMe ne te demande ni nom ni prénom : seul ton surnom existe. La mesure d'usage ne démarre qu'avec ton accord, que tu donnes seulement dans les Réglages. »

### Article 14, « Changements, suspension, fin »
Actuel : « Si nous retirons un contenu ou l'accès au partage, nous t'expliquons pourquoi ... »
Ajouter : « Nous pouvons retirer un profil qui enfreint l'article 8. Nous ne pouvons pas empêcher techniquement la création d'un autre surnom : en cas de récidive, nous signalons à Apple si la loi l'impose. » ⚠ La dernière phrase est une proposition à valider par MWM.

### Nouvel article « Ton surnom et ton profil »
Court : un pseudonyme unique, public, 3 à 20 caractères, et rien d'autre (ni nom ni prénom) ; avatar public ; importer une photo de la galerie est possible, elle est publiée sans localisation ; le profil se supprime dans les Réglages. Change avec un budget : non.

## Politique de confidentialité (page MWM) : paragraphes à ajouter ou changer
1. **Données publiques** : surnom, avatar, publications, commentaires, likes ; base publique iCloud d'Apple ; visibles de tous ; vous restez responsable de ce que vous publiez.
2. **Lieu** : le pêcheur choisit à chaque publication ; département ou cours d'eau ; jamais de coordonnée ; les photos et vidéos sont envoyées sans métadonnées de lieu.
3. **Données privées** : collection, messages d'amis et messages de club dans des zones partagées iCloud, lisibles par leurs seuls membres ; FishMe ne les lit pas, sauf le texte d'un message que tu signales toi-même. L'équipe lit le contenu public et les signalements. Pas de nom ni de prénom collectés.
4. **Signalements** : un signalement envoie l'identifiant du contenu et de l'auteur à fishme.app@gmail.com par un e-mail prérempli que tu envoies toi-même, et crée un enregistrement `Signalement` ; **pour un message d'ami ou de club, le texte du message est joint à l'e-mail et copié dans l'enregistrement**, afin que l'équipe (Titouan, Adem, Sullyvan) puisse le lire ; conservés le temps du traitement (durée à fixer, ⚠ à décider par MWM).
5. **Droits** : accès, suppression dans l'app (profil et publications), contact fishme.app@gmail.com ; pas de profilage ; pas de publicité.
6. **Mesure d'usage** : le consentement se donne seulement dans les Réglages (décision 7) ; un lecteur n'est jamais invité à l'accepter dans le parcours.
7. **Compteur de fréquentation** : paragraphe existant de `docs/legal/frequentation-confidentialite.md` inchangé, sauf mention de la base publique.
8. **Hébergement** : Apple (iCloud/CloudKit), précisions à reprendre de la page Apple lors de la relecture.
Change avec un budget : non pour tout ce qui précède.

## À qui ça sert
S2 reprend ces textes ; A les pose dans l'app (articles affichés, `TexteConditions.swift` régénéré) ; Adem relit les engagements (24 h, licence limitée, gratuité) avant que S2 ne publie. Rien n'est publié hors du dépôt sans son oui.
