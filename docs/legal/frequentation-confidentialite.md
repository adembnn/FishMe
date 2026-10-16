# Compteur de fréquentation : textes de confidentialité

À reprendre dans la politique de confidentialité (page MWM) et l'étiquette App Store **le jour où le compteur iCloud est branché**. Le build soumis le 16 oct. n'a pas iCloud : son compteur reste sur l'iPhone et n'envoie rien, donc ces textes n'y sont pas encore nécessaires. Décisions : `docs/frequentation.md`.

## Politique de confidentialité (paragraphe à ajouter)
**Compteur de fréquentation.** Pour éviter que trop de pêcheurs se retrouvent au même endroit, FishMe compte combien de pêcheurs différents ont pêché sur un même tronçon de rivière ces 7 derniers jours. Au début d'une session, l'app enregistre dans la base publique iCloud d'Apple trois informations : le tronçon (désigné par la station de relevés OFB la plus proche, un point public), le jour, et un code tiré au hasard qui change chaque jour. Ni ta position exacte, ni ton nom, ni tes prises ne sont envoyés. iCloud associe chaque écriture à un identifiant propre à FishMe ; nous ne le lisons pas et ne nous en servons pas. Rien ne s'affiche tant que moins de 5 pêcheurs différents sont passés, et l'app n'affiche jamais un nombre, seulement « calme », « normal » ou « chargé ». Tu peux arrêter de participer dans Réglages, « Compteur de fréquentation » ; tu continues alors de voir les niveaux.

## Étiquette de confidentialité App Store (App Store Connect)
- Type de donnée : **Localisation approximative**.
- Utilisation : **Fonctionnalités de l'app**.
- Liée à l'identité : **Non**. Utilisée pour le suivi : **Non**.

## Réglages (texte de l'interrupteur)
- Titre : « Compteur de fréquentation »
- Sous-titre : « Compte les pêcheurs par tronçon, sans ta position exacte, pour éviter la foule sur les mêmes coins. »

## Phrase de la première session
« FishMe compte les pêcheurs par tronçon pour répartir la pression de pêche. Ta position exacte reste sur ton iPhone. »
