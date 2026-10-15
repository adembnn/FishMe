# Notes pour le relecteur d'Apple (champ « Notes » d'App Store Connect)

Brouillon en anglais, 3060 octets comptés par Python (limite 4000). Écrit depuis `docs/fiches/S1.md`, `docs/app-store.md` (ligne 11) et `docs/parcours-demo.md`, pas depuis le build : chaque ligne marquée `[?]` ou entre crochets se lit dans le build TestFlight de la porte 3 ; une fonction coupée à la porte 3 sort des notes. Repris par A le 15 oct. en fin d'après-midi : premier lancement (niveau puis cartes à glisser, décision de 16h), 3 propositions plus « Autre » et toise (17h), carte Apple (MapKit, E1) au lieu d'OpenStreetMap, modèle Core ML sur l'appareil (R1) au lieu de l'IA d'Apple, qui n'est testée qu'en bonus. Rien n'est inventé : les coordonnées du quai de Charenton, le lien de la vidéo, la couverture des règles et le contact manquent. Recompter après toute modification (`len(texte.encode("utf-8")) <= 4000`).

Pas de compte à l'ouverture : cocher « Connexion non requise » dans App Store Connect, aucun compte démo.

```
FishMe is a freshwater fishing app for France. The map shows where fish were recorded by the French Office for Biodiversity (OFB), the rules that apply (each with its source and quote), and every confirmed catch becomes a collectible card in the user's "Pescedex" (the name of the collection).

NO ACCOUNT. No sign-in, no demo credentials needed.

HOW TO TEST WITHOUT A FISH OR A RIVER
1. Launch. The app asks for location once. Allow it, or refuse and pick a department on the map; both work. Then one question (fishing level, can be skipped), then a short deck of common species: swipe right for "already caught", left for "never". Right swipes become "declared" cards, kept apart from real catches.
2. Test spot: Quai de Charenton, near Paris, [LAT, LON from the build]. Tap a spot on the river to see species, rarity, conditions and rules with sources. Outside France the map still opens and says no French rules apply.
3. Tap "Commencer une session" (start a session). The first session is always allowed; its place becomes the free spot (1 km circle).
4. Catch: tap "Ajouter une prise", then the sample-photo button [B to confirm in the TestFlight build]. The app proposes 3 species as images, never a percentage; "Autre" opens all French species as images; "Pas un poisson" is always there. The user confirms, then sets the length (read from a measuring board if one is in the photo, otherwise a slider); weight is shown as an estimate.
5. End the session: the card is revealed, then the paywall opens and can be closed (the user keeps the free spot with unlimited sessions). Choosing a second spot, or tapping a Pro feature such as "7 jours" in a spot's conditions, opens the paywall. Use a sandbox account. Prices, the 1-week trial on the monthly plan and renewal terms come from StoreKit. "Restore" and the Terms and Privacy links are on the paywall.
6. Always free: map, rules, Pescedex, the free spot, and the storm and flood alerts.

60-second video of this path: [LINK, from B].

LEGAL NOTICE. Rules shown are indicative; the prefectoral order prevails. The AI never decides whether a fish may be kept: the AI proposes the species, the user confirms, and a sourced rules table gives the answer. Rule coverage in this build: national baseline plus [DEPARTMENTS READ FROM THE BUILD]; elsewhere the app says so and links to the prefecture.

EXTERNAL SERVICES
- Apple Maps (MapKit) for the map.
- OFB fish surveys and Hub'Eau hydrometry (Licence Ouverte 2.0); Hub'Eau receives only a station code.
- Apple Weather (WeatherKit): receives a rounded point or an OFB station location, never the exact position; shown with the Apple Weather mark and legal link.
- Species proposals run on the device (our Core ML model); photos stay on the device.
- MWM Spark Flash SDK: purchase and usage diagnostics, not linked to identity, no tracking; started only after the user consents.

PRIVACY. Precise location is used on the device only; no exact fishing spot leaves the iPhone. Saved photos carry no GPS. Not made for kids.

Contact: [NAME], [PHONE], [EMAIL].
```


## Ce qui est encore à lire dans le build (porte 3)
- Bouton de photo d'exemple (B) ; coordonnées du quai de Charenton ; départements couverts (`departementsCouverts()`) ; lien de la vidéo de 60 s (B) ; contact d'Adem.
- Ordre réel du premier lancement (position, niveau, cartes à glisser, consentement de L6) : la note suit l'écran, pas le plan.
- Si le modèle ne passe pas l'examen de R1, l'étape 4 devient : « the app shows all French species as images; the user picks one ».
- Si une fonction Pro n'est pas dans le build, elle sort de l'étape 5.
