# Notes pour l'App Review (champ « Notes » d'App Store Connect)

Légende : **[F]** fait, **[I]** hypothèse, **⚠** non vérifié. Les notes sont en **anglais** (le relecteur lit l'anglais). Le champ est limité à 4000 octets ⚠ ; le bloc A ci-dessous est compté par Python et reste sous cette limite.

## Avant de coller : 5 choses à vérifier dans le build réel (sinon les notes mentent)
1. Le lien « Essayer avec une photo d'exemple » est visible sur l'écran de capture, sans le chercher (guideline 2.1).
2. Il existe un accès direct au paywall depuis Réglages (entrée « Bredouille Pro ») : le paywall normal ne se déclenche qu'à la 16e carte, trop long pour un relecteur [I, à confirmer avec Adem ; sinon adapter la phrase 5 du bloc A].
3. « Restaurer mes achats » est visible sur le paywall et dans Réglages.
4. Le texte exact « Aucune de ces espèces » et l'avertissement « ne dit jamais si une prise est légale » sont visibles.
5. Choisir le bloc A1 ou A2 selon le résultat du test d'identification (décision mardi 14 octobre au soir, peche/00 §6) ; ne jamais décrire dans les notes un comportement qui n'est pas dans la build.

## Pas de compte, pas de démo à fournir
Dans « Informations de connexion » : cocher « Connexion non requise ». Aucun nom d'utilisateur ni mot de passe. Ne pas inventer de compte factice.

## Bloc A (à coller). Variante A1 : identification assistée par l'IA de l'appareil
```
Bredouille is a freshwater fishing app for France: the user photographs a catch, the app suggests three plausible species present in the user's French département, the user always confirms, and a collectible card is created. An outing with no fish still earns a card ("Eau calme"). Everything stays on the device.

NO ACCOUNT. There is no sign-in, no login and no account to delete (5.1.1(v) not applicable). No demo credentials are needed.

HOW TO TEST WITHOUT A FISH (2.1):
1. Launch the app: it opens on the capture screen.
2. Tap "Essayer avec une photo d'exemple" (visible link under the shutter button). The app uses a bundled sample fish photo, no camera or permission required.
3. Three species are proposed; tap one to confirm (or "Aucune de ces espèces"). A card is revealed and saved automatically.
4. Empty-handed outing: Home > "Je pars pêcher", then "Retour bredouille" > the "Eau calme" card. (An outing needs 30 minutes by design; in this build a review shortcut is available in Settings > Review.)  [REMOVE IF NOT IMPLEMENTED]
5. Subscription: Settings > "Bredouille Pro" opens the paywall. Annual 24.99 EUR with a 7-day free trial, or monthly 3.99 EUR; "Restaurer mes achats", Terms and Privacy links are on the paywall. Use a sandbox account. Free features stay free; cards already earned remain visible.

ON-DEVICE AI. Species suggestions use Apple's on-device Foundation Models (image input) ⚠ when Apple Intelligence is available, with a fallback to a visual questionnaire and a département species list ranked by frequency on devices without it. No photo leaves the device; no server, no third-party SDK, no analytics, no ads, no tracking (no ATT). The app works in airplane mode.

PERMISSIONS (each requested at the moment of use, each refusal has an alternative):
- Camera: first tap on the shutter. If refused: photo picker or sample photo.
- Photos: system PhotosPicker only (no library read access). Add-only access when saving a card image.
- Location: optional, "While Using" only, one-time, approximate, to find the département. Manual département picker is the alternative. Never background.

DIFFERENCE FROM OTHER APPS (4.3): a collectible card per outing, a card even when nothing is caught, local rarity computed from the French OFB's open scientific survey data (Hub'Eau, Licence Ouverte 2.0), released fish rewarded, and a strict no-verdict rule: the app never says whether a fish may be kept and always refers to the local fishing federation. No third-party game franchise is used or imitated.

SAFETY AND CONTENT: no user-generated public content, chat or ranking (1.2 not applicable). Not in the Kids category. Not affiliated with FNPF or OFB. Contact: [EMAIL_CONTACT].
```

## Variante A2 (si le test d'identification est NO-GO)
Remplacer le paragraphe « ON-DEVICE AI » par :
```
SPECIES CHOICE. The app does not claim automatic recognition: the user picks the species from a list of the département's species ranked by frequency, with a visual guide (body shape, colour, barbels, size). Nothing leaves the device; no server, no third-party SDK.
```
et, dans le premier paragraphe, remplacer « the app suggests three plausible species » par « the app lists the species present in the user's département ».

## Points sensibles que le relecteur peut soulever (réponses prêtes)
- **« Pourquoi une photo de poisson si aucun modèle n'est garanti ? »** : l'app ne promet pas de reconnaissance : elle propose, l'utilisateur confirme, « Aucune de ces espèces » est toujours disponible.
- **Légalité de la pêche** : l'app n'émet aucun verdict ; avertissement permanent + lien vers la fédération départementale.
- **Photo d'exemple utilisée** : image sous licence CC0/CC-BY avec attribution dans l'écran « Sources » [I, à vérifier au manifeste de licences].
- **Abonnement sans compte** : l'achat passe par StoreKit et le compte Apple ; restauration par « Restaurer mes achats ».

## Comptage
Bloc A1 : 2710 caractères, 2718 octets (Python, 13/10/2026) ; bloc A2 : 266 caractères. Si tu modifies le texte, recompter : `len(texte.encode("utf-8")) <= 4000`.
