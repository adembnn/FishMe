Objet : Build Challenge, accès à préparer avant jeudi 9 h (équipe Adem Banni, Titouan Destors, Sullyvan Buckwell)

Bonjour,

Pour que notre jeudi commence par le code et pas par les réglages, pourriez-vous préparer ces points avant jeudi 9 h ?

1. Inviter nos trois comptes Apple dans votre équipe développeur : [e-mail du compte Apple de chacun]. Deux d'entre nous en App Manager (celui qui envoie le build et celui qui remplit la fiche), et l'accès « Certificates, Identifiers & Profiles » coché pour les trois, afin que Xcode puisse signer et enregistrer nos iPhones.
2. Créer l'identifiant de l'app (Bundle ID, par exemple com.mwm.[nom provisoire]) avec les capacités WeatherKit (onglets App Services et Capabilities) et In-App Purchase, puis la fiche de l'app dans App Store Connect avec un nom provisoire.
3. Vérifier que le contrat « Paid Apps Agreement » est actif, et créer le groupe d'abonnement avec un produit annuel et une offre d'essai gratuit d'un mois (nous vous donnons le prix d'ici mercredi).
4. Nous dire qui est le vendeur légal qui signe la politique de confidentialité, et ce que collecte le SDK Spark Flash (son manifeste de confidentialité, s'il utilise un chiffrement non standard, et comment il gère le consentement). Si possible, nous envoyer sa documentation et le fichier StoreKit avant jeudi.
5. Jeudi vers 16 h, juste après l'envoi à Apple, pourrez-vous demander une relecture accélérée en citant le Build Challenge ?
6. Nous confirmer le critère de vendredi 15 h : build envoyé à Apple, ou app en ligne sur l'App Store ?

Merci beaucoup,
Adem

## Complément à envoyer le 15 oct. après-midi (WeatherKit)
Le kit est arrivé avec l'identifiant `ai.mwm.build.challenge.team.01` ; le point 2 se précise ainsi (ligne 21 de `app-store.md`) :

Pourriez-vous activer le service WeatherKit sur l'identifiant `ai.mwm.build.challenge.team.01` (Certificates, Identifiers & Profiles, onglets App Services et Capabilities), ou donner à Adem l'accès pour le faire ? Et nous dire par écrit si le quota de WeatherKit (500 000 appels par mois inclus par compte développeur) est partagé avec les autres apps de MWM ?
