# Pré-soumission App Store - Bredouille

Rédigé le 13/10/2026. Sources : App Store Review Guidelines (page officielle, "last updated" 8 juin 2026), page App Review d'Apple, presse spécialisée pour le questionnaire d'âge.
Légende : numéro = vérifié sur la page officielle ; ⚠ = non vérifié officiellement, à confirmer dans App Store Connect (ASC) ou auprès d'Apple.
Propriétaires : A = Adem, T = Titouan, B = business (compte, juridique, finance).

## 0. Hypothèses sur l'app
iPhone, eau douce FR. Photo -> espèces proposées par modèle sur l'appareil (Core ML). Cartes à collectionner. Sans compte, hors ligne. Gratuit jusqu'à 15 cartes, puis Pro : 24,99 EUR/an ou 3,99 EUR/mois, essai 7 jours. Localisation et photos. Données ouvertes OFB. Si une hypothèse est fausse, les lignes concernées sont à revoir.

## 1. Sécurité (1.x)
| # | Point | Règle | Risque de rejet pour Bredouille | Preuve | Resp. |
|---|---|---|---|---|---|
| 1.1 | Aucun verdict légal ("taille légale", "espèce protégée, remets-la") présenté comme certain | 1.4 (risque de dommage) ; 1.1.6 (fonction trompeuse) ; ⚠ pas de règle "pêche" dédiée | Moyen : un avis erroné peut faire garder un poisson protégé ou hors taille | Captures des écrans espèce avec mention "indicatif, vérifie la réglementation locale (fédération, OFB)" ; liste des chaînes | T |
| 1.2 | Confiance IA affichée, "propositions" et non "identification" | 1.1.6 ; 2.3 | Moyen : promesse de précision non démontrable | Texte ASC et UI alignés sur "propositions" ; tests de précision internes archivés | T |
| 1.3 | Pas d'incitation à des pratiques dangereuses (berges, nuit, crues) | 1.4.5 | Faible | Revue des textes et de toute notification | T |
| 1.4 | Bien-être animal : pas de contenu cruel, pas de photos de poissons morts gratuites | 1.1.2 (violence réaliste envers les animaux) | Faible à moyen selon les images des cartes | Revue visuelle des illustrations et captures | T |
| 1.5 | Pas de contenu utilisateur publié (pas de compte, pas de flux social) | 1.2 non applicable tant qu'aucun partage public | Faible. Si un partage est ajouté, 1.2 impose filtre, signalement, blocage, contact | Phrase en notes de revue : "aucun contenu utilisateur n'est publié" | A |
| 1.6 | Contact développeur et URL de support accessibles et à jour | 1.5 | Faible mais fréquent | URL support testée (HTTP 200) + email actif | B |

## 2. Complétude (2.1) et démo
| # | Point | Règle | Risque | Preuve | Resp. |
|---|---|---|---|---|---|
| 2.1 | Build final testé sur appareil réel, sans placeholder ni "bientôt" | 2.1(a) | Élevé : Apple indique que plus de 40 % des problèmes non résolus relèvent de 2.1 | Test iPhone physique ; checklist sans lorem ni bouton mort | A |
| 2.2 | Fonctionne hors ligne, y compris au premier lancement sans réseau | 2.1 | Moyen : si données OFB ou modèle téléchargés au 1er lancement, le relecteur peut être sans réseau | Vidéo en mode avion du parcours photo -> carte ; tout embarqué dans le bundle | A |
| 2.3 | Parcours testable sans pêcher : photos d'exemple pour le relecteur | 2.1 ; ⚠ pratique courante | Élevé : le relecteur n'a pas de poisson sous la main et peut conclure "ne marche pas" | 3 à 5 images de poissons en pièces jointes de revue, ou mode démo explicite (⚠ un mode démo exige l'accord préalable d'Apple, cf. 2.1(a)) | A |
| 2.4 | Achats intégrés complets, visibles, fonctionnels pour le relecteur | 2.1(b) | Élevé : produits non prêts ou non rattachés à la version | Capture ASC des 2 produits + groupe d'abonnement, statut OK, attachés à la version | B |
| 2.5 | Pas de crash au refus de permission (caméra, photos, localisation) | 2.1 | Moyen | Test de chaque refus, vidéo | A |
| 2.6 | Compte démo inutile | 2.1(a) ne l'exige qu'en cas de connexion | Nul, mais le dire évite une demande | Notes : "Aucun compte, aucune connexion" | T |

## 3. Métadonnées et captures (2.3)
| # | Point | Règle | Risque | Preuve | Resp. |
|---|---|---|---|---|---|
| 3.1 | Description fidèle : pas de fonction non livrée, pas de "100 % fiable" | 2.3 ; 2.3.1 (fonctions non documentées à décrire en notes) | Moyen | Relecture ligne par ligne vs build | T |
| 3.2 | Captures montrant l'app en usage (pas seulement titre ou splash) | 2.3.3 | Moyen | Jeu de captures ; ⚠ taille de référence actuelle à vérifier dans ASC | A |
| 3.3 | Aperçus vidéo = captures de l'app uniquement | 2.3.4 | Faible | Vidéo enregistrée à l'écran | A |
| 3.4 | Pas de marque tierce (fédérations, marques d'appâts, logo OFB) sans droit | 5.2.1 ; 4.1 | Moyen : un logo OFB laisse croire à un partenariat | Aucun logo OFB ; source citée en texte avec licence ⚠ (Licence Ouverte ? à confirmer) | B |
| 3.5 | Droits sur illustrations et photos d'espèces des cartes | 5.2.1 ; 5.2.2 | Moyen à élevé | Table source/licence par image, ou illustrations maison | T |
| 3.6 | "What's New" informatif ; pas de marque concurrente en mots-clés | 2.3.12 ; ⚠ mots-clés | Faible | Texte final | T |
| 3.7 | Icône et captures acceptables pour la classe d'âge | 2.3.8 | Faible | Revue visuelle | T |

## 4. Abonnements et achats (3.1.x)
| # | Point | Règle | Risque | Preuve | Resp. |
|---|---|---|---|---|---|
| 4.1 | IAP obligatoire pour débloquer Pro (pas de lien de paiement externe, pas de code) | 3.1.1 | Faible si StoreKit seul | Code : seul StoreKit débloque Pro | A |
| 4.2 | Bouton Restaurer les achats visible (paywall et réglages) | 3.1.1 | Élevé : motif de rejet classique | Capture + test sandbox sur 2e appareil | A |
| 4.3 | Décrire ce que l'utilisateur obtient pour le prix avant de demander l'abonnement | 3.1.2(c) | Élevé | Paywall : avantages Pro (cartes illimitées, etc.) | T |
| 4.4 | Mentions du paywall : prix, durée, renouvellement automatique, annulation, fin d'essai, "7 jours gratuits puis ..." | 3.1.2(c) renvoie à l'Annexe 2 du contrat développeur ; liste exacte ⚠ | Élevé | Capture : "7 jours gratuits puis 24,99 EUR/an (ou 3,99 EUR/mois)", "renouvellement automatique sauf annulation 24 h avant la fin de la période", lien gérer l'abonnement, liens CGU et confidentialité | T |
| 4.5 | Prix affichés issus de StoreKit (localisés), pas en dur | ⚠ bonne pratique | Moyen : écart avec ASC | Test sandbox ; Product.displayPrice | A |
| 4.6 | Pas d'abonnement accidentel à deux formules ; annuel et mensuel lisibles | 3.1.2(b) ; ⚠ hiérarchie visuelle | Moyen : 3,99 EUR en gros et l'annuel en petit | Capture avec les deux plans lisibles | T |
| 4.7 | Annuel et mensuel dans le même groupe d'abonnement ; essai 7 jours en offre d'introduction | 3.1.2(b) ; ⚠ config ASC | Moyen | Capture du groupe dans ASC | B |
| 4.8 | Abonnement disponible sur tous les appareils de l'utilisateur | 3.1.2(a) | Faible (sans compte, repose sur l'identifiant Apple / StoreKit) | Test de restauration | A |
| 4.9 | Période d'au moins 7 jours | 3.1.2(a) | Nul (mensuel, annuel) | - | - |
| 4.10 | Les 15 cartes gratuites réellement offertes, sans mur à l'entrée | ⚠ pas de règle propre ; cohérence avec 2.3 | Faible | Test premier lancement | A |
| 4.11 | Accords "Paid Apps" signés, infos bancaires et fiscales saisies | ⚠ prérequis ASC (Business) | Bloquant : sans accord actif, pas d'IAP vendables | Capture ASC > Business : statut "Actif" | B |
| 4.12 | Statut "Trader" (DSA, UE) déclaré pour distribuer en UE | ⚠ exigence ASC, à vérifier | Bloquant pour la France si manquant | Capture du statut ; adresse et téléphone publics | B |

## 5. Design et spam (4.x)
| # | Point | Règle | Risque | Preuve | Resp. |
|---|---|---|---|---|---|
| 5.1 | Valeur propre au-delà d'un catalogue ou d'un site emballé | 4.2 | Moyen : on peut y voir une base d'espèces avec des images | Notes : IA locale, collection, hors ligne | T |
| 5.2 | Pas de copie d'apps d'identification existantes ni de leur marque ; catégorie encombrée | 4.1 ; 4.3(b) | Faible à moyen | Argumentaire : eau douce FR, hors ligne, sans compte, cartes | T |
| 5.3 | Un seul bundle ID, pas de variantes par région | 4.3(a) | Nul | - | - |
| 5.4 | Pas de connexion tierce (ne pas ajouter "Se connecter avec Google") | 4.8 | Nul aujourd'hui | - | - |
| 5.5 | Interface native, pas de WebView plein écran | 4.2 | Faible | - | A |

## 6. Confidentialité (5.1.x)
| # | Point | Règle | Risque | Preuve | Resp. |
|---|---|---|---|---|---|
| 6.1 | Politique de confidentialité en ligne (URL en ASC) ET dans l'app : données, usage, partage, conservation, suppression | 5.1.1(i) | Élevé si absente ou générique | URL fonctionnelle en français ; lien dans Réglages | B |
| 6.2 | Étiquettes "Confidentialité de l'app" : si tout reste sur l'appareil, "Données non collectées" ; vérifier que le SDK d'achats ou d'analytics n'envoie rien | ⚠ règle ASC (non numérotée) | Élevé : incohérence étiquette vs code/SDK | Inventaire des appels réseau (Proxyman ou Instruments), liste des SDK ; capture des réponses ASC | A |
| 6.3 | Manifeste (PrivacyInfo.xcprivacy) : API à "raison requise" (UserDefaults, horodatages fichiers, espace disque...) avec codes de raison ; manifestes des SDK tiers | ⚠ exigence technique Apple, non numérotée | Moyen à élevé : mail d'alerte automatique à l'envoi du binaire | Rapport Xcode "Generate Privacy Report" ; fichier dans le dépôt | A |
| 6.4 | Chaînes d'usage (Info.plist) spécifiques, en français : NSCameraUsageDescription, NSPhotoLibraryUsageDescription (inutile avec PHPicker), NSLocationWhenInUseUsageDescription | 5.1.1(ii)/(iii) ; 5.1.5 | Élevé si générique ("l'app a besoin de la caméra") | Captures des invites ; fichier de localisation fr | A |
| 6.5 | Minimisation : sélecteur de photos hors processus (PHPicker) plutôt qu'accès complet à la photothèque | 5.1.1(iii) | Moyen | Code PHPicker ; pas de lecture complète | A |
| 6.6 | Localisation "quand l'app est active", motif expliqué dans l'app, aucun envoi serveur, refus sans blocage | 5.1.5 | Moyen | Capture de l'écran d'explication | A |
| 6.7 | Aucun suivi publicitaire : pas d'ATT ni d'IDFA | 5.1.2(i) | Faible | Recherche ATT/IDFA, absence de SDK pub | A |
| 6.8 | Pas de compte => pas de suppression de compte en app | 5.1.1(v) | Nul | Notes : "aucun compte" | T |
| 6.9 | Photos des prises traitées sur l'appareil ; tout envoi vers un serveur ou une IA tierce exigerait divulgation et accord explicite | 5.1.2(i) | Nul tant que local, bloquant si changement | Notes : "inférence 100 % sur l'appareil, aucune image transmise" | A |
| 6.10 | Exif/GPS des photos : ne pas conserver ni partager les coordonnées sans le dire | 5.1.2(ii) | Faible | Revue du code d'export et de partage | A |

## 7. Classification d'âge
| # | Point | Règle | Risque | Preuve | Resp. |
|---|---|---|---|---|---|
| 7.1 | Nouveau questionnaire (échelle 4+, 9+, 13+, 16+, 18+), à remplir avant toute soumission (date limite annoncée : 31/01/2026, d'après la presse, ⚠ non revérifié chez Apple). ASC > Informations sur l'app > Classification d'âge | ⚠ règle ASC | Moyen : bloque la soumission si non rempli | Capture des réponses ; viser 4+ si aucun contenu mature | B |
| 7.2 | Répondre honnêtement : violence réaliste (pêche) à décrire sobrement ; achats intégrés oui ; accès web illimité non | ⚠ | Faible | Capture | T |
| 7.3 | Éviter "pour enfants" dans les textes : réservé à la catégorie Enfants | 2.3.8 | Faible | Texte ASC | T |
| 7.4 | Catégorie (Sports ou Style de vie ⚠) ; ne pas se présenter comme service officiel de permis de pêche | 2.3 | Faible | - | T |

## 8. IA et contenu généré
| # | Point | Règle | Risque | Preuve | Resp. |
|---|---|---|---|---|---|
| 8.1 | Aucune règle d'IA dédiée dans la version du 8 juin 2026 (lecture de la page) ; la plus proche : IA tierce et données personnelles | 5.1.2(i) | Faible : modèle local | Notes de revue : modèle embarqué | A |
| 8.2 | Licence du modèle et du jeu d'entraînement compatible usage commercial | 5.2.1 ; ⚠ | Moyen | Fichier LICENSES : modèle, jeu de données, sources OFB | T |
| 8.3 | Afficher la confiance, une option "Autre / je ne sais pas", correction manuelle | 1.1.6 ; 2.3 | Moyen | Capture des propositions + option manuelle | A |
| 8.4 | Pas de texte génératif en ligne (sinon filtrage et signalement, cf. 1.2) | 1.2 | Nul si absent | - | A |

## 9. Notes de revue (App Review Information)
Remplir : contact joignable (nom, téléphone, email), "Aucun compte requis". Texte conseillé :
1. "Bredouille propose des espèces d'eau douce à partir d'une photo, via un modèle Core ML exécuté sur l'appareil (aucune image envoyée)."
2. "Pour tester sans poisson : utiliser les images jointes via le sélecteur de photos."
3. "Fonctionne hors ligne ; localisation optionnelle, quand l'app est active."
4. "Pro : essai de 7 jours, deux formules dans un même groupe ; Restaurer dans Réglages."
5. "Répartition des espèces : données ouvertes OFB (licence ⚠), incluses dans l'app."
6. "Les propositions sont indicatives ; l'app ne donne aucun avis juridique sur la taille ou la protection des espèces."
Preuve : capture de la case de notes + pièces jointes. Resp. T (texte), A (images de test).

## 10. Délais de revue
- Page App Review d'Apple : au moins 50 % des soumissions en moins de 24 h, 90 % en moins de 48 h. Compter 48 h pour une première version.
- Après approbation, jusqu'à 24 h pour apparaître sur toutes les boutiques. Choisir la publication manuelle pour maîtriser la date.
- Soumission incomplète = retard (2.1). Rejets répétés pour le même motif = délai plus long.
- Revue accélérée : réservée à un bug critique ou un événement daté ; ⚠ ne pas en abuser.

## 11. Plan B en cas de rejet
1. Lire le motif dans le Resolution Center ; répondre vite (viser moins de 2 h), avec preuve (capture, vidéo).
2. Rejet du binaire (2.1 etc.) : corriger, renvoyer un build, réponse brève ; compter 24 à 48 h.
3. Rejet de métadonnées seul : modifier dans ASC et resoumettre, sans nouveau binaire.
4. Désaccord : argumenter dans le Resolution Center ; appel possible (⚠ procédure sur la page de contact App Review).
5. Variantes prêtes : (a) paywall sans essai si l'essai est contesté ; (b) version sans localisation ; (c) retrait de la mention OFB ; (d) textes sans "identification" ; (e) mode démo avec accord d'Apple.
6. Si échec vendredi : ne pas forcer ; TestFlight externe comme repli pour le jury (⚠ la revue bêta externe a son propre délai) et vidéo de démo.

## 12. Calendrier

### Jeudi 15 octobre
| Heure | Action | Resp. |
|---|---|---|
| 09:00 | Gel du code. Build Release signé, archive, test sur iPhone réel | A |
| 09:30 | Vérifier xcprivacy, rapport de confidentialité, chaînes d'usage, appels réseau | A |
| 10:30 | Tests achat sandbox : essai, mensuel, annuel, restaurer, annulation | A |
| 11:00 | Accords Paid Apps, statut Trader, produits IAP "Prêt à soumettre" | B |
| 12:00 | Paywall : captures et mentions (4.2 à 4.6) | T |
| 14:00 | Fiche ASC : description, mots-clés, captures, classification d'âge, URL support et confidentialité | T/B |
| 15:30 | Fiche confidentialité ASC cohérente avec le code | A |
| 16:30 | Notes de revue + pièces jointes (images de test) | T |
| 17:30 | Upload du build (Xcode ou Transporter), attendre le traitement | A |
| 18:30 | Relecture croisée de cette liste ; chaque ⚠ résolu ou accepté | T+A |

### Vendredi 16 octobre
| Heure | Action | Resp. |
|---|---|---|
| 09:00 | Build traité ? Le sélectionner, attacher les IAP à la version | A |
| 09:30 | Dernier test du build TestFlight (mode avion, refus de permissions) | A |
| 10:00 | Soumettre pour revue, publication manuelle | B |
| 10:30 -> | Surveiller le Resolution Center | T |
| 18:00 | En attente de revue : rien à faire ; rejet : plan B (section 11) | tous |

Rappel : avec 90 % des revues sous 48 h, soumettre jeudi soir si tout est prêt vaut mieux que vendredi matin.
