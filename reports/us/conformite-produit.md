# FishMe US : conformité juridique et produit

**Date : 7 nov. 2026.**
**Décision débloquée : fixer le périmètre minimal de conformité (mineurs, contenu utilisateur, localisation, permis, accessibilité) à boucler avant un lancement pilote US sur l'App Store, et ce qu'on reporte.**

Avertissement : note de recherche, pas un conseil juridique. [?] = non vérifié ou issu de ma connaissance générale sans source confirmée. Les sources sont surtout des cabinets d'avocats et de la presse ; seul le texte d'Apple (guidelines) a été lu directement. Le droit des mineurs en ligne bouge vite (injonctions, appels) : tout statut ci-dessous est daté de ma recherche.

## 1. App Store US

### 1.1 Disponibilité et prix
- Disponibilité par pays et prix se règlent dans App Store Connect (Pricing and Availability) ; les prix et abonnements peuvent être modifiés à tout moment. https://developer.apple.com/news/?id=xymmt0iz
- Taxes : Apple administre des taxes dans 70+ pays/régions et publie un Transaction Tax Report couvrant les taxes de vente/usage qu'Apple administre aux US et au Canada ; les proceeds sont calculés hors taxe. https://ppc.land/apple-announces-tax-and-pricing-updates-affecting-global-developers/ ; https://www.iclarified.com/89810/app-store-connect-updated-with-monthly-transaction-tax-report
- Hypothèse de travail : Apple gère la collecte/remise de la sales tax US sur les achats in-app (cohérent avec le rapport ci-dessus), mais le texte du Paid Applications Agreement n'a pas été lu [?]. À confirmer.
- Small Business Program : commission 15 % sous 1 M USD de proceeds annuels ; inscription à faire avant le lancement. https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/app-store-small-business-program

### 1.2 Règle 1.2 (contenu utilisateur), texte Apple lu
Source : https://developer.apple.com/app-store/review/guidelines/
- Exigences : filtre du contenu répréhensible avant publication, signalement avec réponse rapide, blocage des utilisateurs abusifs, coordonnées publiées. Le blocage doit être effectif (retrait des flux, messages, recherche : commentaire tiers, non officiel). https://developer.apple.com/forums/thread/807358
- 1.2.1 : si FishMe traite des créateurs, le contenu dépassant la classe d'âge doit être restreint selon un âge vérifié ou déclaré.
- 1.5 : contact développeur facile et à jour (page support).
- Chat + clubs + photos/vidéos : chaque surface (post, commentaire, DM, club, profil) doit avoir report/block/modération. Compter un outil de modération et un SLA de traitement.

### 1.3 Vie privée côté Apple (5.1.x, texte lu)
- 5.1.1 : politique de confidentialité liée dans App Store Connect et dans l'app ; consentement avant collecte ; collecte minimale. 5.1.1(v) : suppression de compte dans l'app obligatoire dès qu'il y a création de compte.
- 5.1.2 : permission explicite pour usage/partage ; App Tracking Transparency si pistage ; ne pas exiger notifications ou localisation pour utiliser l'app.
- 5.1.4 (enfants) : tenir compte de COPPA ; pas de métadonnées type « For Kids » hors catégorie Kids ; ne pas viser les enfants comme public principal.
- 5.1.5 (localisation) : usage seulement si directement pertinent, explication et consentement.
- App Privacy (étiquettes nutrition) : à remplir pour l'app ET les SDK de mesure (localisation, identifiants, contenu utilisateur, usage). Détail des catégories non relu ici [?].
- Âge : nouvelle classification 4+/9+/13+/16+/18+, questionnaire à jour à remplir en toute sincérité. https://www.iphoneincanada.ca/2025/07/25/updated-app-store-age-ratings ; https://www.iclarified.com/97995/apple-overhauls-app-store-age-ratings-with-new-13-16-and-18-categories . Avec UGC non filtré par âge, attendre 13+ ou plus [?].

### 1.4 Abonnements (3.1.2, texte lu)
- Durée minimale 7 jours, valeur continue, fonctionnement sur tous les appareils, description claire de ce qui est inclus avant paiement. Restore purchases, mention de renouvellement et lien CGU/politique dans le paywall [?, non lu dans cette version].
- Si des fonctions gratuites passent en payant : ne pas retirer ce que les utilisateurs ont déjà acquis.

## 2. Vie privée et mineurs

### 2.1 COPPA (< 13 ans)
- Règle amendée : publiée le 22 avr. 2025, en vigueur le 23 juin 2025, conformité complète au 22 avr. 2026 (passée). https://www.mondaq.com/unitedstates/privacy-protection/1623784/ftc-finalizes-updates-to-coppa-rule-what-you-need-to-know ; https://www.finnegan.com/en/insights/articles/coppas-amended-rule-is-now-in-full-effect-what-operators-need-to-know.html
- Politique FTC du 25 févr. 2026 : enforcement limité pour les données collectées seulement pour vérifier l'âge (services grand public/mixtes), sans consentement parental préalable. Texte FTC non lu [?]. Source résumée : https://www.mondaq.com/unitedstates/privacy-protection/1623784/ftc-finalizes-updates-to-coppa-rule-what-you-need-to-know (page générale ; la date exacte du communiqué reste à confirmer sur ftc.gov).
- Piège : COPPA s'applique aussi à la « connaissance effective » d'un enfant (compte déclarant < 13, photo/propos révélant l'âge) [?, connaissance générale].
- Choix pilote : app 13+, écran d'âge neutre, pas de compte sous 13 ans, suppression rapide si détecté, SDK de mesure désactivés ou configurés sans données personnelles pour les profils non confirmés adultes.

### 2.2 Lois d'État sur les mineurs : très litigieuses
- Californie, Age-Appropriate Design Code : 9e circuit, 12 mars 2026 (NetChoice v. Bonta), injonction réduite ; estimation d'âge, certaines restrictions d'usage des données et dark patterns restent bloqués. Suites inconnues [?]. https://www.cooley.com/news/insight/2026/2026-03-30-netchoice-v-bonta-ninth-circuit-narrows-injunction-against-californias-ageappropriate-design-code-act ; https://www.hklaw.com/en/insights/publications/2026/03/ninth-circuit-issues-mixed-ruling-on-california-age-appropriate-design-code-act
- Virginie SB 854 (1 h/jour < 16 ans) : injonction préliminaire du 27 févr. 2026. https://lawreview.syr.edu/court-hits-pause-on-virginias-social-media-restrictions-for-minors/
- Arkansas : loi 2023 bloquée définitivement ; Act 900/901 bloquées (avr. 2026). https://arkansasadvocate.com/2026/04/20/federal-judge-blocks-reworked-arkansas-law-restricting-minors-social-media/embed/
- Utah (réseaux sociaux) : statut non établi [?].
- App Store Accountability (Texas, Utah, Louisiane) : Apple propose la Declared Age Range API (catégorie d'âge sans date de naissance) ; Texas : injonction de déc. 2025 puis suspendue par le 5e circuit le 1er juin 2026, statut mouvant. https://appleinsider.com/articles/26/06/03/age-verification-now-mandatory-for-app-store-users-in-texas ; https://www.macrumors.com/2025/11/04/ios-26-2-texas-age-verification-law/ . Pour Utah et Louisiane, dates exactes non confirmées [?].
- Conséquence produit : pas de raison de bâtir un dispositif par État ; appliquer partout le plus prudent (profil mineur privé par défaut, DM limités, pas de localisation précise, pas de notifications nocturnes) et lire l'âge via l'API Apple.

### 2.3 Lois d'État sur la vie privée (CCPA/CPRA, Virginie, Colorado, Texas)
- Géolocalisation précise = donnée sensible : CCPA, rayon 1 850 pieds, droit de limiter l'usage ; Texas : un résumé cite 1 750 pieds avec consentement opt-in (écart à vérifier au texte) [?]. https://www.caprivacy.org/how-prop-24-can-limit-businesses-from-tracking-your-geolocation-and-using-your-sensitive-personal-information/ ; https://compliance.theartofservice.com/controls/texas-data-privacy-act/tdpsa-541-101-geo
- Texas TDPSA : pas de seuil de chiffre d'affaires, mais exemption partielle des « small business » SBA (source : blog éditeur, vérifier au statut). https://www.clym.io/blog/texas-data-privacy-and-security-act
- CCPA : seuils d'applicabilité (revenu ~26,6 M USD ; 100 000 consommateurs ; 50 % de revenus issus de la vente/partage de données) non confirmés par ma recherche [?]. Un petit pilote peut échapper au CCPA mais pas à une partie des lois d'État sans seuil de revenu (Texas) ; à faire trancher.
- Le SDK de mesure peut constituer une « vente/partage » selon son contrat : à qualifier ; prévoir lien « Do Not Sell or Share » et signal Global Privacy Control si applicable [?].
- Colorado : amendements récents sur la vie privée des mineurs (https://www.hunton.com/privacy-and-information-security-law/colorado-legislature-passes-amendments-to-colorado-privacy-act) ; contenu non relu [?].
- Pas de loi fédérale générale ; FTC Act section 5 (pratiques trompeuses) reste le filet [?, connaissance générale].

## 3. Responsabilité du contenu

### Section 230 et DMCA
- Section 230 (47 U.S.C. 230) : protège généralement l'hébergeur contre la responsabilité du contenu tiers ; exclut notamment les droits d'auteur fédéraux et les crimes fédéraux. Aucune source récupérée dans cette recherche [?]. Une modération d'abord de bonne foi n'annule pas la protection [?].
- DMCA 512 : pour la protection contre les réclamations de copyright (photos/vidéos), désigner un agent auprès du Copyright Office (frais cités : 6 USD, validité 3 ans, renouvellement obligatoire sous peine de perte de la protection), publier une procédure de notice-and-takedown et une politique de récidivistes. Sources de 2016-2020 : vérifier frais et règles actuels. https://www.proskauer.com/alert/copyright-office-establishes-new-electronic-dmca-agent-registration ; https://www.mondaq.com/unitedstates/copyright/902198/us-copyright-office-renewal-of-dmca-designated-agent-required-for-dmca-safe-harbor
- Si l'entité exploitante est française, un agent DMCA et une entité/adresse de contact US restent possibles ; question de structure à confirmer par un juriste.
- Signaler et retirer CSAM : obligations fédérales de signalement au NCMEC pour les fournisseurs [?, connaissance générale, non vérifié ici]. À traiter avec la modération.
- Conditions d'utilisation : licence de contenu utilisateur, clause d'arbitrage éventuelle, règles de contenu (photos de poissons sans contenu de braconnage, pas de géolocalisation de spots protégés).

## 4. Localisation précise, braconnage, spots secrets
- Risque : un fil public avec position précise expose spots sensibles (espèces protégées, propriétés privées, frayères), facilite braconnage et harcèlement ; et la position précise est une donnée sensible (voir 2.3). Pas de source juridique spécifique trouvée sur le braconnage via apps ; analyse de risque produit [?].
- Mesures pilotes : floutage par défaut à ~1 mile ou zone/plan d'eau (pas de coordonnées exactes publiques) ; EXIF GPS retiré à l'upload ; partage de spot précis seulement vers amis/club ; localisation « pendant l'utilisation » seulement, jamais en arrière-plan ; permissions expliquées (5.1.5) ; rétention limitée ; signalement de contenu « braconnage/espèce protégée ».
- Éviter toute formulation du type « spot autorisé » ou « pêche permise ici » : voir 6.

## 5. Vente de permis de pêche
- Réalité US : 50 régimes d'État. Achat mobile possible dans tous les États (source 2020 d'un groupe de défense) ; frais parfois plafonnés par la loi (NC 4 USD/transaction, LA 2 USD pour l'app), Texas 5 USD de frais administratifs en ligne. https://congressionalsportsmen.org/policy/hunting-and-fishing-license-e-commerce/ ; https://library.ncleg.gov/EnactedLegislation/Statutes/PDF/BySection/Chapter_113/GS_113-270.1.pdf ; https://www.legis.la.gov/legis/ViewDocument.aspx?d=982692 ; https://www.tpwd.texas.gov/business/licenses/online_sales
- Vendre depuis FishMe suppose agrément (vendor/agent) État par État, souvent via un prestataire de licensing de l'État ; Rhode Island prévoit un vendeur agréé pour le système web. https://webserver.rilegislature.gov/Statutes/TITLE20/20-2/20-2-4.1.htm
- Apple : un achat de permis (bien/service réel) n'est a priori pas de l'IAP, donc paiement externe ; non vérifié au texte 3.1.x [?].
- Recommandation pilote : ne PAS vendre ; renvoyer vers le site/app officiel de l'État, avec lien profond, sans dire que FishMe « vend » ou « garantit » un permis valide. Étudier ensuite 1-2 États pilotes via leur prestataire.

## 6. Localisation produit
- Langue : anglais US (orthographe américaine). Unités : pieds/pouces, miles, livres/onces, °F ; longueur et poids des poissons en in/lb avec bascule métrique.
- Dates et heures : MM/DD/YYYY, 12 h AM/PM ; fuseaux des 6 grandes zones (Eastern/Central/Mountain/Pacific + Alaska/Hawaï) ; horaires de lever/coucher et saison de pêche selon fuseau de l'État, y compris changement d'heure.
- Monnaie USD ; tarifs StoreKit par pays : définir le prix US dans App Store Connect (prix d'abonnement terminant par .99 par convention [?]), laisser Apple proposer les équivalents ailleurs ; le prix affiché est hors taxe de vente aux US, la taxe s'ajoute au paiement [?].
- Phraséologie : le mot « autorisé » est interdit côté produit en France ; transposer la même prudence aux US (éviter « legal », « allowed », « authorized », « permitted » pour spots, tailles, quotas, saisons). Utiliser « check local regulations », « information only, not official », avec lien vers la source de l'État. Les espèces, tailles minimales, quotas et saisons sont régis par chaque État, et les données ne doivent jamais être présentées comme réglementaires sans source officielle ; si FishMe affiche une réglementation, prévoir disclaimers et date de mise à jour.
- Espèces et vocabulaire : base d'espèces US (largemouth bass, trout, catfish...), pas de reprise des espèces françaises ; modèles de leurres, « catch & release » ; concours et classements : attention aux lois sur loteries/sweepstakes si prix en jeu [?].

## 7. Accessibilité
- DOJ Title II (WCAG 2.1 AA, web et apps) : échéances reportées d'un an par règle intérimaire du 20 avr. 2026 ; vise les entités publiques, non FishMe. https://www.mondaq.com/unitedstates/media-entertainment-law/1782220/doj-extends-ada-title-ii-digital-accessibility-deadlines-by-one-year ; https://www.deque.com/blog/what-the-us-doj-adopting-wcag-2-1-a-aa-in-ada-title-ii-for-web-and-mobile-apps-means-for-you/
- Title III (entreprises privées) : pas de règle dédiée (réexamen annoncé sept. 2025) ; contentieux et accords utilisent WCAG 2.1 AA comme repère, sans chiffres vérifiés sur les apps mobiles en 2026 [?]. https://www.jdsupra.com/legalnews/understanding-the-doj-rule-on-web-2286366/
- Pilote : Dynamic Type, VoiceOver (labels sur photos et boutons), contrastes AA, légendes ou texte alternatif pour vidéos si possible, cibles tactiles 44 pt ; déclaration d'accessibilité et adresse de contact.

## 8. À faire relire par un juriste US
1. Structure d'entité (société française) vs obligations US : agent DMCA, adresse de contact, responsabilité.
2. Applicabilité CCPA/CPRA et lois d'État (seuils à jour, Texas small business) ; qualification du SDK de mesure en vente/partage.
3. COPPA : « connaissance effective », écran d'âge, politique FTC de févr. 2026.
4. Statut à jour des lois sur les mineurs (Texas, Utah, Louisiane, Californie AADC, Virginie, Arkansas) et usage de l'API Age Range.
5. Section 230 et exceptions ; procédure notice-and-takedown et CSAM/NCMEC.
6. Géolocalisation précise : consentement, floutage, rétention, seuils (1 850 vs 1 750 pieds).
7. CGU, politique de confidentialité, clauses sur contenu utilisateur et arbitrage.
8. Permis de pêche : agrément État par État, frais, contrat avec prestataires de licensing.
9. Formulation de la réglementation de pêche (disclaimers), concours/sweepstakes.
10. Taxe de vente sur abonnements et traitement par Apple (Paid Applications Agreement).
11. Accessibilité (Title III, WCAG 2.1 AA).

## 9. Recommandation : minimum pour un pilote
Obligatoire avant soumission : politique de confidentialité et suppression de compte dans l'app ; signalement/blocage/modération + contact (1.2, 1.5) ; app 13+ avec écran d'âge, Declared Age Range API si disponible ; consentement localisation « pendant l'utilisation » avec floutage par défaut et EXIF retiré ; App Privacy complète incluant les SDK ; agent DMCA et processus de retrait ; abonnement conforme 3.1.2 ; langage prudent sur la réglementation. Reporter : vente de permis, fonctions réservées aux moins de 13 ans, ciblage publicitaire, expansion hors pilote. Limiter le pilote à quelques États pour mieux contrôler le risque.
