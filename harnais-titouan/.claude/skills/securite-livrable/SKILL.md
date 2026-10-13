---
name: securite-livrable
description: Checklist sécurité et vie privée avant de livrer ou de soumettre Bredouille (secrets, signature, données, partage d'image). Se déclenche avant toute soumission, TestFlight, partage de dépôt ou ajout d'un fichier de configuration.
---

# Sécurité avant livraison (Bredouille)

## Secrets et signature
- Aucun `.env`, clé API, `.p8`, `.p12`, `.cer`, `.mobileprovision`, mot de passe, token dans le dépôt. La signature passe par la signature automatique d'Xcode sur le Mac d'Adem ; `DEVELOPMENT_TEAM` est un identifiant, pas un secret, mais ne jamais committer d'export de certificat.
- `.gitignore` contient `*.xcodeproj`, `.env*`, `*.p8`, `*.p12`, `*.mobileprovision`, `Tools/data-pipeline/cache/`, `Data-images/`.
- Les workflows CI utilisent des *secrets GitHub*, jamais des valeurs en clair.

## Données utilisateur (aucun compte, tout local)
- Aucune requête réseau dans l'app finale (le pipeline Hub'Eau tourne sur le PC de Titouan, pas dans l'app).
- Le département est mémorisé, **jamais les coordonnées**. Position uniquement « quand l'app est utilisée », jamais en arrière-plan.
- **Image de carte partagée : aucun EXIF de position, aucune coordonnée exacte** (à vérifier sur un export réel).
- Les messages d'erreur affichés ne contiennent ni chemin de fichier ni trace.
- Pas d'ATT, pas de SDK de pistage. Si un SDK est ajouté, la politique de confidentialité et les étiquettes App Privacy sont à refaire.

## Données de référence
- Licences : Hub'Eau/OFB (Licence Ouverte 2.0 pour le jeu de données [F] ; licence de l'API elle-même non explicite [I]) et photos CC0/CC-BY avec attribution dans l'écran « Sources ».

## Bon / mauvais
- Mauvais : `let apiKey = "sk-…"` dans un fichier Swift ; un `.mobileprovision` « pour que ça marche chez Titouan ».
- Bon : aucune clé nécessaire dans l'app ; Titouan n'a pas besoin de signer.
- Mauvais : stocker `latitude/longitude` d'une prise dans `collection.json`. Bon : `departement: "95"` et une maille floutée.
