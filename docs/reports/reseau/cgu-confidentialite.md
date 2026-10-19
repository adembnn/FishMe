# CGU et confidentialité : les paragraphes à changer pour le réseau social
Décision débloquée : donner à S2 (juridique et fiche) la liste exacte des textes à réécrire avant la vague 2, et à Adem de relire les nouveaux engagements envers les pêcheurs.
Lu le 19/10/2026 (`docs/legal/conditions-fishme.md` version du 16 octobre 2026, numéro 1 ; `docs/legal/frequentation-confidentialite.md`). Je ne modifie pas `docs/legal/` : S2 reprend ces propositions.

## En bref
Les CGU actuelles disent trois choses que le réseau rend fausses : « jamais en public » (article 8), « seulement aux amis que tu as invités » (articles 11 et 13) et un compte qui n'efface que la sauvegarde et les cartes partagées (article 7). Ces phrases deviennent trompeuses : 5.1.2 d'Apple interdit de partager des données sans l'avoir dit ([guidelines](https://developer.apple.com/app-store/review/guidelines/)). Les textes ci-dessous sont des **propositions de brouillon à faire relire** par le juriste de MWM ⚠ (je n'ai pas de compétence juridique ; l'éditeur et le médiateur restent à renseigner par MWM). Après chaque changement : `python3 outils/legal/generer_conditions.py`, et `numero` monte de 1 (nouvelle acceptation).

## CGU : article par article
### Article 2, « Accepter ces conditions »
Actuel : « FishMe est faite pour les 15 ans et plus. »
À ajouter : « Un profil public (surnom, avatar) et des publications exigent d'avoir 15 ans ou plus. » Raison : le surnom et les photos sont visibles de tous. Change avec un budget : non.

### Article 3, « Ce que fait l'app »
Ajouter une phrase : « Tu peux aussi publier des photos et des vidéos de tes prises, commenter, aimer, discuter avec tes amis et dans des clubs. » La carte, les règles et la lecture du Pescedex restent gratuites ; dire si le réseau est gratuit (décision à prendre, voir `decisions.md`, question 5).

### Article 7, « Ton compte et la sauvegarde de ta collection »
Actuel : « Tu peux supprimer ton compte ... Ta sauvegarde iCloud et tes cartes partagées sont alors effacées, et tes amis perdent l'accès à ce que tu as partagé. »
Remplacer par : « ... Ton profil public (surnom et avatar), tes publications, tes commentaires, tes likes et tes messages de club sont alors supprimés, avec ta sauvegarde iCloud et tes cartes partagées. Les messages que tu as envoyés à un ami restent chez lui jusqu'à ce qu'il les supprime. »
Raison : 5.1.1(v) ([guidelines](https://developer.apple.com/app-store/review/guidelines/)) exige la suppression dans l'app quand l'app crée un compte ; le profil de FishMe est un compte de fait. ⚠ Le texte de 5.1.1(v) lu dit « si ton app permet de créer un compte » ; un profil public en est un à mon avis, non confirmé par Apple. Change avec un budget : non.
À vérifier avec L21 : « les messages que tu as envoyés à un ami » sont dans la zone de l'envoyeur ; supprimer la zone les efface chez l'ami aussi (zone partagée). Écrire ce que le code fait réellement.

### Article 8, « Amis et club : ce que tu partages » (à réécrire en entier)
Actuel : « Elle n'est visible que par les personnes que tu invites, jamais en public. Une carte partagée montre au plus le département de ta prise... »
Proposition, trois parties :
1. **Ta collection** : « Ta collection n'est jamais publique. Seuls les amis que tu invites la voient. »
2. **Tes publications** : « Quand tu publies une photo ou une vidéo, elle est visible par tous les utilisateurs de FishMe, pas seulement par tes amis. Tu choisis à chaque publication le lieu affiché : le cours d'eau et le département, le département seul, ou aucun lieu. Jamais ta position GPS ni les coordonnées de ton coin ne sont publiées. »
3. **Les clubs et le chat** : « Les messages d'un club sont lisibles par toute personne qui trouve le lien du club. Les messages entre amis ne sont lisibles que par vous deux. »
Modération (à reprendre de l'actuel et à étendre) : « Aucun contenu choquant, haineux, violent, illégal, sexuel ou cruel envers les animaux n'est toléré. Ne révèle pas le coin exact d'un autre pêcheur. Tu peux signaler et bloquer toute publication, commentaire, message ou personne. Nous traitons chaque signalement sous 24 heures : nous retirons le contenu en cause, et nous pouvons retirer le profil de la personne qui l'a publié. »
Surnom : « Ton surnom est public et doit rester respectueux : pas de nom réel d'une autre personne, pas d'insulte ni de marque. Nous pouvons le retirer. »
Change avec un budget : non pour le texte ; l'engagement de 24 h exige une personne qui lit la boîte (`moderation.md`).

### Article 11, « Ce qui t'appartient »
Actuel : « En les partageant, tu nous autorises seulement à les transmettre aux amis que tu as invités, le temps du partage. »
Remplacer par : « Tes photos et tes vidéos t'appartiennent. En les publiant, tu autorises FishMe à les montrer aux autres utilisateurs selon le choix que tu as fait (amis, club ou tout le monde), tant que tu ne les supprimes pas. Tu peux les supprimer à tout moment. » La licence est limitée à l'affichage dans l'app, sans réutilisation commerciale ni publicité : un engagement à garder. Raison : 5.1.2(ii), pas de réutilisation sans nouveau consentement.

### Article 13, « Données personnelles »
Actuel : « Ta position précise et tes coins de pêche restent sur ton iPhone. Tes photos et ta collection sont sauvegardées dans ton iCloud, et envoyées seulement aux amis que tu invites... »
Remplacer par : « Ta position précise et tes coins de pêche restent sur ton iPhone. Ce que tu publies (photos, vidéos, légendes, lieu choisi, surnom, avatar, commentaires, likes, messages de club) est enregistré dans la base publique iCloud d'Apple associée à FishMe et visible selon ton choix. Ton nom et ton prénom, si tu les donnes, restent privés. La mesure d'usage ne démarre qu'avec ton accord, que tu donnes seulement dans les Réglages. »

### Article 14, « Changements, suspension, fin »
Actuel : « Si nous retirons un contenu ou l'accès au partage, nous t'expliquons pourquoi ... »
Ajouter : « Nous pouvons retirer un profil qui enfreint l'article 8. Nous ne pouvons pas empêcher techniquement la création d'un autre surnom : en cas de récidive, nous signalons à Apple si la loi l'impose. » ⚠ La dernière phrase est une proposition à valider par MWM.

### Nouvel article « Ton surnom et ton profil »
Court : surnom unique, public, 3 à 20 caractères ; avatar public ; nom et prénom facultatifs et privés ; le profil se supprime dans les Réglages.

## Politique de confidentialité (page MWM) : paragraphes à ajouter ou changer
1. **Données publiques** : surnom, avatar, publications, commentaires, likes, messages de club ; base publique iCloud d'Apple ; visibles de tous ; vous restez responsable de ce que vous publiez.
2. **Lieu** : le pêcheur choisit à chaque publication ; département ou cours d'eau ; jamais de coordonnée ; les photos et vidéos sont envoyées sans métadonnées de lieu.
3. **Données privées** : nom et prénom facultatifs dans la base privée du pêcheur ; collection et messages d'amis dans la zone partagée avec l'ami ; FishMe ne les lit pas, mais l'équipe lit le contenu public et les signalements.
4. **Signalements** : un signalement envoie l'identifiant du contenu et de l'auteur à fishme.app@gmail.com ; conservés le temps du traitement (durée à fixer, ⚠ à décider par MWM).
5. **Droits** : accès, suppression dans l'app (profil et publications), contact fishme.app@gmail.com ; pas de profilage ; pas de publicité.
6. **Mesure d'usage** : le consentement se donne seulement dans les Réglages (décision 7) ; un lecteur n'est jamais invité à l'accepter dans le parcours.
7. **Compteur de fréquentation** : paragraphe existant de `docs/legal/frequentation-confidentialite.md` inchangé, sauf mention de la base publique.
8. **Hébergement** : Apple (iCloud/CloudKit), précisions à reprendre de la page Apple lors de la relecture.
Change avec un budget : non pour tout ce qui précède.

## À qui ça sert
S2 reprend ces textes ; A les pose dans l'app (articles affichés, `TexteConditions.swift` régénéré) ; Adem relit les engagements (24 h, licence limitée, gratuité) avant que S2 ne publie. Rien n'est publié hors du dépôt sans son oui.
