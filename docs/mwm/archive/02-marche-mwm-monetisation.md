# 02 - Marché App Store, MWM et monétisation (recherche au 30/09/2026)

Légende : **[F]** fait sourcé, **[I]** inférence de notre part. Limites : interview Authority Magazine de J.-B. Hironde inaccessible (403), pas de données Appfigures obtenues, aucun cas d'indie "Foundation Models" avec chiffres de revenu vérifié.

## 1. MWM

**Portefeuille et échelle**
- [F] Éditeur parisien, 1 Md+ de téléchargements, 200+ apps construites, 70+ apps live. Levée > 75 M$ (Eurazeo, Bpifrance, NJJ...). [Yahoo Finance](https://finance.yahoo.com/sectors/technology/articles/mwm-ai-platform-behind-1-150000071.html)
- [F] Historique musique/création : Edjing (150 M+ DL), Beatwave, Beat Maker Pro, Tuner & Metronome, Piano/Guitar/Drums ; extension vers "créatif pour tous" (photo, dessin, vidéo). [Music Ally](https://musically.com/2020/03/03/after-400m-downloads-music-apps-firm-mwm-raises-e50m/)
- [F] Rachat de Swipewipe (nettoyage photos Gen Z, iOS only), plus grosse acquisition, > 10 M€ de revenu annoncé pour l'année. [TechCrunch](https://techcrunch.com/2024/06/25/gen-z-photos-app-swipewipe-sells-to-french-publisher-mwm-in-its-largest-acquisition-to-date/)

**Modèle économique**
- [F] Éditeur/publisher en revenue share : gère UA, ASO, création de pubs, monétisation (SDK, paywall builder testable sans mise à jour), finance le budget d'acquisition ; le dev garde le produit. Cherche des apps avec traction (cohortes, LTV, rétention, payback). [MWM Publishing](https://mwm.ai/publishing)
- [F] Combine abonnement + pub native (a retiré des interstitiels peu performants sur Swipewipe) ; détecte les apps via KPIs, notes, usage. [TechCrunch](https://techcrunch.com/2024/06/25/gen-z-photos-app-swipewipe-sells-to-french-publisher-mwm-in-its-largest-acquisition-to-date/)
- [F] Pivot 2026 : **MWM AI** (apps Swift natives générées par prompt, ~7 min, TestFlight, A/B tests, paywalls) ; partenariat Google Cloud "AI Mobile Squad" (juin 2026). [PR Newswire](https://www.prnewswire.com/news-releases/mwm-ai-partners-with-google-cloud-to-launch-new-mobile-agents-for-app-creators-and-entrepreneurs-302790646.html)

**Ce que dit le CEO**
- [F] Hironde : "Winning in the app economy is about two things: time to market and time to scale." [Yahoo Finance](https://finance.yahoo.com/sectors/technology/articles/mwm-ai-platform-behind-1-150000071.html)
- [I] Ce que le jury valorisera probablement : preuve de signal marché (pas juste une démo), monétisation pensée dès le jour 1 (paywall, essai, prix), potentiel de scaling via ASO/UA payante, exécution rapide et propre. Un build natif Swift/iOS bien fini colle à leur direction MWM AI.

## 2. Monétisation : benchmarks 2025-2026

Source principale : [RevenueCat State of Subscription Apps 2026](https://www.revenuecat.com/state-of-subscription-apps) (115 000+ apps, 16 Md$) et [synthèse blog](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026).

- [F] Hard paywall : conversion médiane D35 10,7 % contre 2,1 % en freemium ; revenu/install J60 3,09 $ vs 0,38 $. Rétention à 1 an quasi identique (27 % vs 28 %).
- [F] Trial→payant médian par catégorie : Travel 43,5 %, Health & Fitness 37,7 %, Gaming 25 %, **Photo & Video 22,2 % (le plus bas)**.
- [F] Download→payant D35 : Health & Fitness 2,9 %, Business 2,6 %, Gaming 1,0 %. Amérique du Nord 2,8 %, Europe de l'Ouest 2,0 %.
- [F] Essais : 55,4 % des annulations d'essais 3 jours ont lieu le jour 0 ; essais 17-32 j convertissent 42,5 % vs 25,5 % pour < 4 j (mais 46,5 % des apps utilisent < 4 j).
- [F] Prix : mensuel médian 9,99 $ (Education, Health & Fitness, Social), ~7-8 $ Productivité, 4,99 $ Gaming ; annuel médian 39,99 $ (Amérique du Nord), 39,44 $ (Europe de l'Ouest). Écart de prix mensuel Europe/NA : 15,25 $ vs 10,95 $ (chiffre du résumé de recherche, non revérifié dans le rapport).
- [F] Rétention/LTV : 35 % des abonnements annuels coupent le renouvellement dès le mois 1 ; Y1 RLTV/payeur médian 23 $ (NA 32 $). Productivité = 77 % du revenu en plans mensuels ; Business RLTV Y1 35,48 $.
- [F] Apps IA (27 % des apps abonnement) : conversion trial→payant 8,5 % vs 5,6 %, revenu annuel/user 30,16 $ vs 21,37 $, MAIS rétention annuelle 21,1 % vs 30,7 % et mensuelle 6,1 % vs 9,5 % ; remboursements 4,2 % vs 3,5 %. [TechCrunch](https://techcrunch.com/2026/03/10/ai-powered-apps-struggle-with-long-term-retention-new-report-shows)
- [F] Polarisation : top 25 % des apps > +80 % de MRR YoY, bottom 25 % < -33 %.
- [F] Marché global (Sensor Tower) : 167 Md$ de dépenses IAP 2025 (+10,6 %), 79,5 Md$ d'abonnements ; pour la 1re fois les apps non-jeux dépassent les jeux ; plus gros non-jeux : réseaux sociaux, streaming, dating ; AI Assistants et short drama en tête de croissance ; DL gen-AI +148 %. [Sensor Tower](https://sensortower.com/blog/state-of-mobile-2026)
- [I] Catégories les plus "abonnement-friendly" pour une équipe étudiante : Health & Fitness/bien-être, Productivité/business, Education. Photo & Video convertit mal en trial malgré 61 % d'adoption IA.

## 3. IA on-device, Foundation Models, App Intents

- [F] Foundation Models (iOS 26) : inférence on-device gratuite, hors ligne, privée. WWDC 2026 : plateforme hybride on-device + cloud, multimodal (images), "custom skills". [Appbot](https://appbot.co/blog/apple-wwdc-2026-ai-foundation-model-update/)
- [F] Apps citées par Apple (usages concrets, pas de chiffres de revenu) : SmartGym (routines depuis texte), Stoic (prompts de journal), Stuff (tâches parlées/écrites), Agenda, OmniFocus 4, Signeasy (résumés), Grammo, Lil Artist, Streaks, Essayist, Detail. [Apple Newsroom](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/)
- [F, source secondaire non vérifiée] Selon des blogs : App Intents devient la seule voie d'accès de Siri aux apps ; PCC gratuit pour < 2 M de premiers téléchargements ; couche d'abstraction permettant d'échanger le modèle. [DEV](https://dev.to/hariharanjagan/whats-new-in-apples-foundation-models-framework-at-wwdc-2026-5227), [DEV App Intents](https://dev.to/malik_chohra/wwdc-2026-app-intents-foundation-models-and-what-rn-devs-should-ship-3o8a)
- [F] Réalité indie : médiane des apps qui gagnent < 50 $/mois ; > 80 % ne passent jamais 1 000 $/mois ; 500-10 000 $/mois pour une niche étroite en 18-24 mois. [AppOpportunity](https://appopportunity.com/blog/indie-app-revenue-models-2026)
- [I] Le schéma des apps Apple ci-dessus : l'IA on-device est une *fonction* qui retire de la friction (structurer, résumer, catégoriser) dans un usage récurrent existant, pas le produit. Cela répond à la faiblesse de rétention des "apps IA pures".

## 4. Niches saturées à éviter

- [F] Généralistes : to-do, habit trackers génériques ("bloodbath"), expense trackers généraux, clones de dating, utilitaires génériques. [AppOpportunity](https://appopportunity.com/blog/underserved-app-niches-2026)
- [F] Apple durcit la guideline 4.3 sur les apps "low-value" en catégories saturées ; risque de retrait du programme développeur en cas de spam d'apps quasi identiques. [AppStoreReview](https://appstorereview.app/guides/apple-app-review-low-value-apps-2026)
- [I] À éviter aussi : chatbot/wrapper IA générique, éditeur photo IA générique, scanner QR/PDF, nettoyeur de stockage (marché tenu par des acteurs à gros budget UA, dont MWM/Swipewipe).
- [F, source secondaire] Niches sous-servies : habitudes pour condition précise (TDAH, douleur chronique), micro-journal + insights IA, finance verticale (freelances, locatif), focus/détox adulte, apps seniors. [AppOpportunity](https://appopportunity.com/blog/underserved-app-niches-2026) (volumes de recherche à prendre avec prudence)

## 5. Cinq enseignements actionnables

1. **Choisir une niche verticale et un utilisateur précis** (ex. TDAH, freelances, musiciens), pas une catégorie large : les généralistes sont saturés et Apple sanctionne le low-value.
2. **Intégrer Foundation Models comme fonction on-device** dans un usage récurrent (structurer/résumer/suggérer), avec fallback sans IA ; ajouter des App Intents (Siri/Raccourcis/Spotlight) : bon signal technique pour Apple et pour MWM.
3. **Concevoir le paywall dès J1** : hard paywall ou essai long, aha moment en < 60 min, annuel poussé (~39,99 $ comme repère NA/EU), mensuel ~9,99 $ ; présenter un plan de test de paywall (MWM fournit un builder).
4. **Cibler la rétention, pas seulement le téléchargement** : les apps IA convertissent mieux mais churnent plus vite ; prévoir une boucle d'usage (widgets, rappels, streaks, données personnelles qui s'accumulent).
5. **Pitcher comme un dossier de publisher MWM** : signal marché, hypothèses chiffrées (CAC, conversion 2-3 % download→payant, payback), stratégie ASO (mots-clés, screenshots, vidéos de pub) et vitesse d'exécution ("time to market, time to scale"), avec un build App Store Connect propre et natif.
