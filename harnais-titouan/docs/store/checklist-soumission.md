# Checklist de soumission : App Store Connect pas à pas

Légende : **[F]** fait, **[I]** hypothèse, **⚠** non vérifié. Menus et libellés d'App Store Connect (ASC) évoluent : suivre l'intention, relire à l'écran. Plan : peche/04 L26 et §3 vendredi (gel du code 11 h, upload 12 h, soumission 12-13 h, marge jusqu'à 14 h). **Titulaire du compte = seul à pouvoir accepter les accords.**

## 0. Aujourd'hui et demain (mardi 13 - mercredi 14) : ce qui prend des jours
- [ ] Compte Apple Developer **actif** (adhésion payée, rôle Account Holder identifié). Si pas actif : plan B (second compte, peche/04 R-11).
- [ ] **Accord « Paid Apps »** : ASC > Business (ou Accords, fiscalité et banque) ⚠ > accepter l'accord Paid Apps (Account Holder). **Sans lui, les abonnements ne sont pas testables ni vendus.** Renseigner : coordonnées bancaires, informations fiscales, contacts. La validation bancaire peut prendre plusieurs jours ⚠ : **à lancer maintenant**.
- [ ] Réservation du **nom** « Bredouille » dans ASC (Apps > + > Nouvelle app) ; si pris, autre nom de fiche. Contrôle INPI en parallèle (peche/00 §1).
- [ ] **Bundle ID** créé (Certificates, Identifiers & Profiles) avec les capacités strictement nécessaires (In-App Purchase). Aucune capacité inutile.
- [ ] Politique de confidentialité **en ligne** (URL publique, sans connexion) : privacy-policy-fr.md avec les 3 champs remplis. Page d'assistance en ligne.

## 1. Fiche de l'app (Informations sur l'app)
- [ ] Langue principale : français (France). Ajouter l'anglais.
- [ ] Nom, sous-titre : metadata-fr.md / metadata-en.md (28 et 25 caractères, comptés).
- [ ] Catégories : metadata-fr.md. Ne pas cocher « Made for Kids ».
- [ ] **Droits sur le contenu** : l'app ne contient pas de contenu tiers sous licence non déclarée ; photos CC0/CC-BY attribuées dans « Sources » ; Hub'Eau / OFB Licence Ouverte 2.0 cités.
- [ ] **Classification d'âge** : age-rating-answers.md (niveau calculé noté).
- [ ] URL de confidentialité, URL d'assistance, URL marketing (facultative).
- [ ] **App Privacy** : app-privacy-answers.md (« Aucune donnée collectée »).
- [ ] Disponibilité : storefront France [I]. Tarification de l'app : gratuite (avec achats intégrés).

## 2. Abonnements (Monétisation > Abonnements)
Règle clé : **les produits sont créés et soumis avec la 1re version** (peche/07 §7).
- [ ] Créer un **groupe d'abonnements** « Bredouille Pro ». Nom localisé FR/EN affiché dans l'app et sur la fiche.
- [ ] Produit 1 : annuel, **24,99 €**, durée 1 an. Offre d'introduction : **essai gratuit 7 jours** pour les nouveaux abonnés ⚠ (type d'offre à choisir à l'écran).
- [ ] Produit 2 : mensuel, **3,99 €**, durée 1 mois. Essai : non [I, à confirmer ; peche/07 ne le prévoit que sur l'annuel].
- [ ] Ordre de niveaux dans le groupe (annuel au-dessus) ; partage familial : décision à prendre (peche/07 §4 le recommande).
- [ ] Pour chaque produit : nom d'affichage, description, **capture d'écran de revue** (écran paywall réel, voir screenshots-plan.md), note de revue.
- [ ] Les prix du paywall dans l'app doivent venir de StoreKit (jamais écrits en dur) et correspondre aux produits.
- [ ] La grille gratuit/Pro (15 cartes ou 1 département et 30 prises) est **tranchée avant la saisie** : c'est la description du Pro qui en dépend (CLAUDE.md, décisions ouvertes (b)).
- [ ] Statut des produits : « Prêt à soumettre » ⚠ ; les rattacher à la version dans la section « Achats intégrés et abonnements » de la version.
- [ ] Compte **Sandbox** (Utilisateurs et accès > Sandbox) pour l'essai et pour que le relecteur puisse acheter.

## 3. TestFlight interne (mercredi 14 : build à blanc)
- [ ] Créer une build via la CI (Adem) : archive, signature, upload. Délai de traitement 15-60 min [peche/04 R-11].
- [ ] **Testeurs internes** : membres de l'équipe ASC (jusqu'à 100) ⚠. **Pas de bêta externe avant le pitch** : le premier build externe passe par la Beta App Review (~24 h) [peche/03 §6.3].
- [ ] Informations de test TestFlight : description, e-mail de retour, notes « quoi tester ».
- [ ] Vérifier sur iPhone réel : mode avion, refus de chaque permission, photo d'exemple, bredouille, paywall (Sandbox), Restaurer, appareil sans Apple Intelligence.

## 4. Version 1.0 (vendredi 16 : gel 11 h, upload 12 h)
- [ ] Build traitée sélectionnée dans la version. Numéro de build noté.
- [ ] Captures 6,9" FR+EN : screenshots-plan.md. Texte promo, description, mots-clés, Nouveautés : metadata-*.md.
- [ ] **Informations de revue** : coordonnées (nom, téléphone, e-mail) joignables vendredi ; « Connexion non requise » ; Notes : review-notes.md (bloc A1 ou A2 selon le test d'identification).
- [ ] **Conformité à l'export** : export-compliance.md (`ITSAppUsesNonExemptEncryption` = NO dans la build).
- [ ] **Publicité (IDFA)** : non. **Contenu de l'utilisateur** : non.
- [ ] Mode de publication : « Libérer manuellement » [I] (pour décider de la mise en ligne après approbation).
- [ ] « Ajouter pour vérification » > « Soumettre à l'App Review ». Vérifier le statut « En attente de vérification ».

## 5. Pièges de revue et corrections prêtes
- **2.1 Complétude** : relecteur sans poisson → lien « Essayer avec une photo d'exemple » visible ; notes de revue claires ; aucun écran vide, aucun lien mort (confidentialité, assistance, conditions) ; produits d'abonnement soumis avec le build.
- **4.3 Spam / copie** : écrire la différenciation (cartes, « Eau calme », prudence légale, données OFB) dans les notes ; pas de nom ni d'esthétique de franchise tierce ; description sans copier celle d'un concurrent.
- **5.1.1 Données et permissions** : une chaîne d'usage précise par ressource, localisée FR/EN (peche/07 §3) ; `PhotosPicker` sans lecture complète ; localisation ponctuelle ; chaque refus a une alternative ; fonction payante indépendante d'une permission ; politique accessible dans l'app (Réglages) ET dans ASC ; réponses App Privacy identiques à la politique ; pas de compte donc pas de suppression de compte requise.
- **3.1.2 Abonnements** : le montant facturé est l'élément de prix le plus visible du paywall ; durée, renouvellement automatique, essai, prix après essai écrits ; « Restaurer » visible ; Conditions et Confidentialité sur le paywall ET dans la description ; rien n'est conditionné à un partage ; promesses limitées à ce qui est livré ; « gratuit » n'apparaît que comme « 7 jours offerts ».
- **5.2.1 PI** : ni « Pokémon », ni « Pokédex » dans le nom, les captures, les mots-clés ; pas de logo FNPF/OFB.
- **1.2 UGC** : sans objet tant qu'il n'y a ni publication ni chat.
- **Rejet** : répondre dans ASC (Resolution Center) dans l'heure, corriger, re-soumettre ; marge prévue jusqu'à 14 h puis 16 h (peche/04 R-11). Ne pas réutiliser une capture de conversation du relecteur ailleurs.

## 6. Dernier contrôle avant le bouton (case à case)
- [ ] Aucun `[URL_POLITIQUE]`, `[EMAIL_CONTACT]`, `[NOM_EDITEUR]` restant dans les textes (recherche texte dans docs/store).
- [ ] Les limites de caractères sont respectées (comptées dans metadata-*.md).
- [ ] Les chiffres affichés sont ceux d'ASC (prix, durée d'essai).
- [ ] Aucun terme du descriptif §14 n'apparaît dans les textes.
