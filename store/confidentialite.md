# Politique de confidentialité de FishMe (brouillon)

Version du 16 octobre 2026. Le champ `jurisdictions` du questionnaire MWM doit contenir FR et UE (clause 5). Brouillon écrit dans git, non publié : la publication passe par le serveur MCP de MWM après le oui d'Adem. Les crochets `[...]` sont à remplir avant l'envoi. Les réponses de `etiquettes-confidentialite.md` doivent rester identiques à ce texte.

---

## Français

**Éditeur** : [ÉDITEUR, à demander à MWM]
**Contact** : [EMAIL de contact, donné par Adem]
**Date** : 16 octobre 2026

### En deux phrases
FishMe n'a pas de compte et n'affiche aucune publicité. Ta position précise, tes coins de pêche et tes photos restent sur ton iPhone.

### 1. Ta position reste sur ton iPhone
FishMe demande ta position (« quand l'app est utilisée ») pour centrer la carte, te proposer un spot et appliquer les règles de ton département. Cette position précise sert **sur l'iPhone seulement** : aucun coin de pêche exact ne quitte ton téléphone. Si tu refuses la position, tu choisis ton département ou ta commune sur la carte, sans GPS, et l'app marche pareil.

### 2. Tes photos n'ont pas de position
Les photos de tes prises sont enregistrées **sans GPS**. Elles restent sur ton iPhone. Tu choisis toi-même si tu en enregistres une copie dans tes photos ou si tu la partages.

### 3. Mesure d'usage : Spark Flash (MWM), seulement si tu es d'accord
FishMe utilise le SDK de mesure **Spark Flash**, fourni par MWM. Au premier lancement, l'app te demande ton accord. **Avant ta réponse, le SDK n'est pas démarré. Si tu refuses, il reste éteint** et rien n'est envoyé. Tu peux retirer ton accord à tout moment dans « Mon club ».
Si tu acceptes, l'app envoie des compteurs d'usage (écran de carte prêt, prise commencée, carte créée, session commencée ou finie, paywall montré avec son motif) et les achats d'abonnement. Aucun de ces événements ne contient de photo, d'espèce, de taille, de position ni de texte libre.
D'après le manifeste de confidentialité du SDK (version du dépôt : 0.5.7), Spark Flash peut recevoir : historique d'achats, interactions avec le produit, données de performance, données de plantage, autres données de diagnostic, identifiant utilisateur, identifiant d'appareil. Ces données ne sont **pas liées à ton identité** et **ne servent pas à te suivre** (pas de suivi publicitaire, aucune autorisation « suivi » demandée). La liste écrite et complète de MWM : [à confirmer par MWM].

### 4. Amis : tes collections ne se montrent qu'aux amis que tu invites
Les amis sont facultatifs. Si tu invites quelqu'un, FishMe utilise **iCloud (CloudKit)** d'Apple : tes cartes partagées sont écrites dans ta zone iCloud privée, partagée par un lien **seulement avec les personnes que tu invites**. Il n'y a **jamais** de collection publique. Une carte partagée contient : l'espèce, la rareté, la date, la taille, « bredouille » ou non, le **département** (jamais un lieu plus précis) et l'image de la carte, ré-encodée **sans GPS ni métadonnées**. Cette image peut montrer ton visage si tu t'es photographié avec ton poisson : à toi d'en tenir compte avant d'inviter.
Tu peux retirer ou bloquer un ami, signaler une carte, et supprimer toutes tes cartes partagées (elles disparaissent chez tes amis ; ton Pescedex local reste intact). Nous n'avons pas accès à ton iCloud : les données restent entre Apple, toi et tes invités.

### 5. Où ça s'applique
Cette politique s'applique aux utilisateurs en France et dans l'Union européenne.

### Ce qui sort de ton iPhone, flux par flux
- **Météo (WeatherKit, Apple)** : l'app envoie un **point arrondi ou la position d'une station de relevés**, jamais le coin exact, pour obtenir la météo et les alertes. La marque Apple Weather est affichée. Comme pour toute requête réseau, Apple voit ton adresse IP.
- **Niveau des rivières (Hub'Eau)** : l'app envoie **le code d'une station** de mesure, rien de personnel. Le service public voit, comme tout site, ton adresse IP.
- **Abonnements (App Store, StoreKit)** : l'achat est géré par Apple. FishMe lit l'état de ton abonnement ; le paiement et tes coordonnées bancaires ne passent jamais par nous.
- **Reconnaissance de l'espèce** : le modèle tourne **sur ton iPhone**. Ta photo n'est envoyée à aucun serveur. Tu confirmes toujours l'espèce toi-même.
- **Widgets et écran verrouillé** : ils lisent des données partagées entre l'app et le widget sur ton iPhone (App Group). Le widget aquarium montre des espèces et leur rareté ; l'activité de l'écran verrouillé montre l'heure de début, l'heure de fin légale et le nombre de prises. Jamais de lieu, car ces écrans sont vus par d'autres.
- **Notifications** : elles sont programmées sur l'iPhone, sans serveur.
- **Compte et publicité** : aucun compte à créer, aucune publicité, aucun courtier de données.

### Ce que nous ne faisons pas
Nous ne vendons aucune donnée. Nous ne te suivons pas d'une app à l'autre. Nous ne lisons ni tes photos ni ta position.

### Durée de conservation
- Sur ton iPhone (Pescedex, sessions, spots) : jusqu'à ce que tu les supprimes ou désinstalles l'app.
- Dans ton iCloud (cartes partagées) : jusqu'à ce que tu les supprimes dans l'app ou dans iCloud.
- Mesure d'usage Spark Flash : [durée à confirmer par MWM]. Aucune donnée n'est envoyée sans ton accord.
- Météo et niveaux d'eau : les requêtes sont traitées par Apple et par Hub'Eau selon leurs propres règles ; FishMe ne garde sur l'iPhone que le dernier résultat.
- Messages envoyés à notre contact (par exemple un signalement) : le temps de les traiter, [12 mois au plus, à confirmer par Adem].

### Sous-traitants et destinataires
- **Apple** : iCloud/CloudKit (amis), WeatherKit (météo), App Store (abonnements).
- **MWM** (Spark Flash) : mesure d'usage et achats, seulement après ton accord.
- **Hub'Eau** (service public de données sur l'eau) : niveaux des rivières, par code de station.

### Tes droits (RGPD)
Tu peux demander l'accès à tes données, leur rectification, leur effacement, la limitation ou l'opposition au traitement, et la portabilité. Tu peux retirer ton accord à la mesure d'usage à tout moment dans « Mon club ». Écris à [EMAIL de contact, donné par Adem]. Tu peux aussi saisir la CNIL (cnil.fr). Les données que nous ne possédons pas (ta position, tes photos, ton iCloud) ne peuvent pas être effacées par nous : tu les contrôles directement sur ton iPhone et dans iCloud.

### Enfants
FishMe n'est pas destinée aux moins de 13 ans. Spark Flash l'interdit, et en France le seuil de consentement numérique est de 15 ans : [à confirmer par MWM, question 6].

### Changements
Si cette politique change, la date en haut change et l'app te le dit quand le changement concerne tes données.

---

## English

**Publisher**: [PUBLISHER, to be confirmed with MWM]
**Contact**: [Contact EMAIL, provided by Adem]
**Date**: 16 October 2026

### In two sentences
FishMe has no account and shows no advertising. Your precise location, your fishing spots and your photos stay on your iPhone.

### 1. Your location stays on your iPhone
FishMe asks for your location ("while using the app") to centre the map, suggest a spot and apply your département's rules. This precise location is used **on the iPhone only**: no exact fishing spot ever leaves your phone. If you decline, you pick your département or town on a map, without GPS, and the app works the same.

### 2. Your photos carry no location
Photos of your catches are saved **without GPS**. They stay on your iPhone. You decide whether to save a copy to your photo library or share it.

### 3. Usage measurement: Spark Flash (MWM), only with your consent
FishMe uses the **Spark Flash** measurement SDK, provided by MWM. On first launch the app asks for your consent. **Before you answer, the SDK is not started. If you decline, it stays off** and nothing is sent. You can withdraw consent at any time in "Mon club".
If you accept, the app sends usage counters (map ready, catch started, card created, session started or ended, paywall shown with its reason) and subscription purchases. None of these events contains a photo, species, size, location or free text.
According to the SDK's privacy manifest (version in the repository: 0.5.7), Spark Flash may receive: purchase history, product interaction, performance data, crash data, other diagnostic data, user ID, device ID. This data is **not linked to your identity** and **not used to track you** (no advertising tracking, no tracking permission requested). MWM's complete written list: [to be confirmed by MWM].

### 4. Friends: your collections are visible only to friends you invite
Friends are optional. If you invite someone, FishMe uses Apple's **iCloud (CloudKit)**: your shared cards are written to your private iCloud zone, shared by a link **only with the people you invite**. There is **never** a public collection. A shared card contains: species, rarity, date, size, "empty-handed" or not, the **département** (never a more precise place) and the card image, re-encoded **without GPS or metadata**. The image may show your face if you photographed yourself with your fish: consider this before inviting.
You can remove or block a friend, report a card, and delete all your shared cards (they disappear for your friends; your local Pescedex stays intact). We have no access to your iCloud: data stays between Apple, you and your invitees.

### 5. Jurisdictions
This policy applies to users in France and the European Union.

### What leaves your iPhone, flow by flow
- **Weather (WeatherKit, Apple)**: the app sends a **rounded point or the position of a measurement station**, never the exact spot, to get weather and alerts. The Apple Weather mark is shown. As with any network request, Apple sees your IP address.
- **River levels (Hub'Eau)**: the app sends **a station code**, nothing personal. The public service sees your IP address, like any website.
- **Subscriptions (App Store, StoreKit)**: purchases are handled by Apple. FishMe reads your subscription status; payment and bank details never pass through us.
- **Species recognition**: the model runs **on your iPhone**. Your photo is sent to no server. You always confirm the species yourself.
- **Widgets and Lock Screen**: they read data shared between the app and the widget on your iPhone (App Group). The aquarium widget shows species and rarity; the Lock Screen activity shows start time, legal end time and number of catches. Never a place, because these screens are seen by others.
- **Notifications**: scheduled on the iPhone, no server.
- **Account and advertising**: no account to create, no advertising, no data broker.

### What we do not do
We sell no data. We do not track you across apps. We read neither your photos nor your location.

### Retention
- On your iPhone (Pescedex, sessions, spots): until you delete them or uninstall the app.
- In your iCloud (shared cards): until you delete them in the app or in iCloud.
- Spark Flash usage measurement: [duration to be confirmed by MWM]. Nothing is sent without your consent.
- Weather and water levels: requests are handled by Apple and Hub'Eau under their own rules; FishMe only keeps the latest result on the iPhone.
- Messages sent to our contact (for example a report): as long as needed to handle them, [12 months at most, to be confirmed by Adem].

### Processors and recipients
- **Apple**: iCloud/CloudKit (friends), WeatherKit (weather), App Store (subscriptions).
- **MWM** (Spark Flash): usage measurement and purchases, only after your consent.
- **Hub'Eau** (public water data service): river levels, by station code.

### Your rights (GDPR)
You may request access, rectification, erasure, restriction or objection, and portability. You can withdraw consent to usage measurement at any time in "Mon club". Write to [Contact EMAIL, provided by Adem]. You may also lodge a complaint with the CNIL (cnil.fr). We cannot erase data we do not hold (your location, photos, iCloud): you control it on your iPhone and in iCloud.

### Children
FishMe is not intended for children under 13. Spark Flash forbids it, and in France the age of digital consent is 15: [to be confirmed by MWM, question 6].

### Changes
If this policy changes, the date above changes and the app tells you when the change concerns your data.
