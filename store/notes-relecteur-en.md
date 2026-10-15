# Notes pour le relecteur d'Apple (champ « Notes » d'App Store Connect)

Brouillon en anglais, 2755 octets comptés par Python (limite 4000). Écrit depuis `docs/fiches/S1.md`, `docs/app-store.md` (ligne 11) et `docs/parcours-demo.md`, pas depuis le build : chaque ligne marquée `[?]` ou entre crochets se lit dans le build TestFlight de la porte 3 ; une fonction coupée à la porte 3 sort des notes. Rien n'est inventé : les coordonnées du quai de Charenton, le lien de la vidéo, la couverture des règles et le contact manquent. Recompter après toute modification (`len(texte.encode("utf-8")) <= 4000`).

Pas de compte à l'ouverture : cocher « Connexion non requise » dans App Store Connect, aucun compte démo.

```
FishMe is a freshwater fishing app for France. The map shows where fish were recorded by the French Office for Biodiversity (OFB), the rules that apply (each with its source and quote), and every confirmed catch becomes a collectible card in the user's "Pescedex" (the name of the collection). No third-party brand is used.

NO ACCOUNT. No sign-in, nothing to delete, no demo credentials needed.

HOW TO TEST WITHOUT A FISH OR A RIVER
1. Launch. The app asks for location (one prompt). Allow it, or refuse and pick a department; both work. Outside France the map still opens and says "no French rules here" [?: exact wording to confirm in the build].
2. Coordinates for a test spot: Quai de Charenton, Paris area, [LAT, LON to be entered from the build]. Tap a spot to see species, rarity and rules with sources.
3. Tap "Commencer une session" (start a session). The first session is always allowed and its place becomes the free spot. It runs to the end of session and then the paywall.
4. Catch: tap "Ajouter une prise" and use the sample-photo button [?: B must confirm it is in the TestFlight build]. The app proposes species with images, never a percentage; the user confirms. "Not a fish" is always available.
5. Subscription: end the first session; the paywall opens and can be closed (the user keeps one free spot with unlimited sessions). Choosing a second spot, or tapping a Pro feature such as "7 jours", opens the paywall. Use a sandbox account. Prices, trial and renewal terms come from StoreKit. "Restore" and the Terms and Privacy links are on the paywall.
6. Always free: map, rules, Pescedex (read), and the storm and flood alert.

60-second demo video: [LINK, from B].

LEGAL NOTICE. Rules shown are indicative; the prefectoral order prevails. The AI never decides whether a fish may be kept: the AI proposes the species, the user confirms, and a sourced rules table gives the answer. Rule coverage in this build: national baseline plus [DEPARTMENTS READ FROM THE BUILD]; elsewhere the app says so.

EXTERNAL SERVICES
- OFB fish surveys via Hub'Eau (Licence Ouverte 2.0); Hub'Eau hydrometry receives only a station code.
- OpenStreetMap for map tiles.
- Apple Weather (WeatherKit) [only if in this build]: receives a rounded point or an OFB station location, shown with the Apple Weather mark and legal link.
- Apple on-device AI [?] for species proposals; photos stay on the device.
- MWM Spark Flash SDK: purchase and usage diagnostics, not linked to identity, no tracking; started only after the user consents [?: confirm L6 in build].

PRIVACY. Precise location is used on the device only; no exact fishing spot leaves the iPhone. Saved photos carry no GPS. Not for children; not "Made for Kids".

Contact: [NAME], [PHONE], [EMAIL].
```
