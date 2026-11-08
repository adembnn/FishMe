# Textes de l'onboarding (FR / EN)

Source : `App/Onboarding/TextesOnboarding.swift` (parcours en écran de dialogue, variante A choisie par Titouan le 8 nov.) et `App/Onboarding/CompteReglagesView.swift` (Réglages). Relu le 8 nov. : orthographe, tutoiement constant en français, aucun mot interdit (« autorisé », « allowed », « legal », « tu peux la garder »), aucune promesse de capture (Papy dit même qu'il ne prend rien certains jours). Les titres de section de l'ancien parcours ont disparu : l'écran n'a plus que la bulle de Papy, des champs et des choix.

| Clé | Français | English |
|---|---|---|
| `replique1` | Approche, petit. Avant de pêcher, trois mots… D'abord : dans quelle langue on cause ? | Come on over, kid. Before we wet a line, a few quick things… First: which language do we speak? |
| `replique2` | Un pêcheur sans surnom, c'est une canne sans moulinet. Comment on t'appelle ? | An angler with no nickname is like a rod with no reel. What should I call you? |
| `replique3` | Où traînes-tu ta ligne ? Pas de promesse : même moi, certains jours, je ne prends rien. | Where do you wet a line? No promises: some days even I come home empty-handed. |
| `replique4` | Direction l'eau ! Dis-moi quels poissons tu as déjà attrapés, et on remplit ton Pescedex. | To the water! Tell me which fish you've already caught, and we'll fill your Pescedex. |
| `passer` | Passer la présentation | Skip intro |
| `continuer` | Continuer | Continue |
| `champSurnom` | Surnom | Nickname |
| `aideSurnom` | 3 à 20 caractères : lettres, chiffres, tiret. | 3 to 20 characters: letters, numbers, hyphen. |
| `placeholderEmail` | nom@exemple.com | name@example.com |
| `champEmail` | E-mail (facultatif) | Email (optional) |
| `aideEmail` | Pour recevoir des nouvelles de FishMe et retrouver ton compte. | To get FishMe news and recover your account. |
| `consentement` | J'accepte que FishMe m'écrive à cette adresse. | I agree that FishMe may email me at this address. |
| `confidentialite` | Politique de confidentialité | Privacy policy |
| `age` | J'ai \(ageMinimum) ans ou plus | I am \(ageMinimum) or older |
| `continuerSansEmail` | Continuer sans e-mail | Continue without email |
| `erreurEmail` | Cette adresse e-mail n'a pas l'air valide. | This email address doesn't look valid. |
| `erreurConsentement` | Coche la case pour que FishMe garde ton e-mail, ou continue sans e-mail. | Tick the box so FishMe keeps your email, or continue without email. |
| `erreurAge` | Coche la case de l'âge pour créer ton surnom. | Tick the age box to create your nickname. |
| `aideZone` | Pour voir les poissons et les règles près de toi. | To see the fish and the rules near you. |
| `maPosition` | Utiliser ma position | Use my location |
| `surLaCarte` | Choisir sur la carte | Choose on the map |
| `cestParti` | C'est parti | Let's go |
| `langueReglage` | Langue | Language |
| `erreurSurnom.tropCourt` | Au moins 3 caractères. | At least 3 characters. |
| `erreurSurnom.tropLong` | 20 caractères au plus. | 20 characters at most. |
| `erreurSurnom.caractereInterdit` | Lettres, chiffres et tiret seulement. | Letters, numbers and hyphen only. |
| `erreurSurnom.tiretMalPlace` | Le tiret va entre deux lettres. | The hyphen goes between two letters. |
| `erreurSurnom.motRefuse` | Ce mot n'est pas accepté. | This word is not accepted. |
| `reglages.compte.surnom` | Surnom | Nickname |
| `reglages.compte.email` | E-mail | Email |
| `reglages.compte.aucun` | Aucun | None |
| `reglages.compte.supprimer-email` | Supprimer mon e-mail | Delete my email |
| `reglages.compte.supprimer-compte` | Supprimer mon compte | Delete my account |
| `reglages.compte.titre-email` | Supprimer ton e-mail ? | Delete your email? |
| `reglages.compte.titre-compte` | Supprimer ton compte ? | Delete your account? |
| `reglages.compte.message-email` | Ton adresse est effacée de cet iPhone, et de nos listes si elle y était. | Your address is erased from this iPhone, and from our lists if it was there. |
| `reglages.compte.message-compte` | Ton surnom et ton e-mail sont effacés de cet iPhone. Tes cartes restent. | Your nickname and email are erased from this iPhone. Your cards stay. |
| `reglages.compte.supprimer` | Supprimer | Delete |
| `reglages.compte.annuler` | Annuler | Cancel |
| `langues (noms propres)` | Français | English |

## Langue par défaut (8 nov.)
L'app s'ouvre en ANGLAIS tant que le pêcheur n'a rien choisi, quelles que soient la langue du téléphone et la région. Le premier écran propose « English » et « Français » (noms écrits dans leur propre langue) ; un toucher sur « Français » fait tout passer en français, et le choix est mémorisé (`langue.choix`), puis ne bouge plus avec la région ni la position. « Passer » sur le premier écran garde l'anglais. Les textes d'autorisation système (position, caméra, photos) suivent la langue du téléphone : `Config/InfoPlist.xcstrings` les a déjà en FR et EN.

## Corrections faites à la relecture
- EN réplique 1 : « Come on over, kid. Before we wet a line, a few quick things… » (au lieu d'une traduction littérale de « trois mots »).
- EN réplique 2 : « An angler … like a rod with no reel. What should I call you? » ; réplique 3 raccourcie en deux phrases (FR et EN) pour la bulle du dialogue : « Where do you wet a line? No promises: some days even I come home empty-handed. »
- EN champ e-mail : « name@example.com » ; Réglages : « Email » (et non « E-mail »).

- Bouton du haut : « Passer la présentation » / « Skip intro » (dit ce qu'il saute) ; images de Papy recompressées (PNG 256 couleurs, moins de 250 Ko chacune), originaux gardés hors du build.

## À décider par Titouan
- Les blagues de Papy : « une canne sans moulinet » (réplique 2) et « même moi, certains jours, je ne prends rien » (réplique 3). Gardées.
- Âge (« J'ai 15 ans ou plus » / « I am 13 or older ») : avis juridique COPPA toujours requis avant publication.
- Politique de confidentialité : lien provisoire (page de la liste d'attente).
