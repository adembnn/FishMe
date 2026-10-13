# Conformité à l'export (chiffrement)

Légende : **[F]** fait, **[I]** hypothèse, **⚠** non vérifié. Je ne suis pas juriste ; la réglementation américaine (EAR) et française sur le chiffrement est résumée de mémoire et à confirmer sur les pages Apple « Complying with Encryption Export Regulations » ⚠.

## Réponse recommandée
- **Info.plist : `ITSAppUsesNonExemptEncryption` = `NO`** (booléen faux) [F pour la clé, I pour la valeur]. Cette clé évite la question à chaque upload TestFlight/App Store Connect (checklist revue-appstore : « ITSAppUsesNonExemptEncryption = NO »).
- Elle doit être posée dans `project.yml` (XcodeGen, propriétaire Adem), pas à la main dans un `.plist` généré.

## Pourquoi « NO » est exact pour Bredouille [I, à confirmer au code]
| Élément | Chiffrement | Exemption |
|---|---|---|
| Stockage local (fichiers JSON, photos) | Protection de fichiers d'iOS (fournie par Apple) | Pas d'algorithme propre à l'app. |
| Achats et abonnement | StoreKit : chiffrement fourni par le système | Utilisation du chiffrement standard de l'OS. |
| Réseau éventuel (Plans, liens) | HTTPS via URLSession/MapKit (système) | Idem. |
| IA / Vision / Foundation Models | Aucun lien avec le chiffrement | Sans objet. |
| Cryptographie propre (CryptoKit, CommonCrypto, OpenSSL) | **Aucune** prévue | Si le code en utilise pour autre chose que l'authentification/signature, voir le point 2 ci-dessous. |

L'exemption visée est celle des apps qui n'emploient que le chiffrement **fourni par le système d'exploitation Apple** et aucun algorithme propriétaire ou non standard [I ⚠].

## À vérifier avant de cliquer
1. **Recherche dans le code** : `grep -ri "CryptoKit\|CommonCrypto\|SecKey\|CCCrypt\|OpenSSL\|AES\|RSA\|sha256" App Packages` (hors tests). Un hachage pour contrôler l'intégrité d'un fichier de données peut compter comme usage de crypto : à lire par Adem.
2. **Si l'app utilise de la cryptographie propre** (pas le cas prévu) : répondre « oui » aux questions d'App Store Connect, puis à « algorithmes exemptés ? » et suivre les étapes (auto-classification, éventuelle déclaration annuelle aux autorités américaines). Documents à garder.
3. **Distribution en France** : Apple demande, pour les apps qui utilisent du chiffrement non exempté, des documents supplémentaires pour la France ⚠ (ex. déclaration à l'ANSSI). Avec `NO` et sans chiffrement propre, il n'y a pas de document à fournir [I].
4. **Aucun SDK tiers** (ni analytics, ni pub, ni abonnement) : ils pourraient embarquer du chiffrement propre et changer la réponse. Voir app-privacy-answers.md.
5. **Questions dans App Store Connect** (au moment de soumettre le build) : si la clé est dans l'Info.plist, ces questions ne sont plus posées. Sinon les réponses à saisir sont : « Utilisez-vous du chiffrement ? » → selon le point 1 ; pour Bredouille, « Non, uniquement le chiffrement fourni par l'OS, exempté ». Libellé à relire à l'écran ⚠.
6. **Tracer** : noter ci-dessous le résultat de la recherche et la date.
   `Recherche crypto faite le ____ par ____ : ____ occurrences.`

## Marché export
Distribution prévue : France (storefront) [I]. Aucun pays sous embargo ciblé ; Apple filtre les pays soumis à restrictions américaines ⚠.
