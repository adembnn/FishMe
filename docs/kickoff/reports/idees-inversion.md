# Idées — angle INVERSION (point de vue de celui qui subit le problème d'un autre, ou de ce que le leader ne peut pas faire)

Méthode : au lieu de servir celui qui cause le problème (l'élève, le voisin, le client en retard), on sert celui qui le subit (le prof, le coach bénévole, le parent, le voisin gêné). Il a une vraie douleur récurrente, et personne ne lui a fait d'app. Recherches web faites le 12 oct. 2026 pour vérifier l'existant.

---

## 1. **Temps Égal** — un minuteur de remplacements équitables pour l'entraîneur bénévole de foot de gamins, pour chaque match du week-end

- **Mécanique** : avant le coup d'envoi, il dicte ou tape « 11 présents, Lucas arrive à la mi-temps, Emma gardienne en 1re période ». L'app calcule les rotations, lance une Live Activity (qui sort / qui entre dans 2 min, vibration au poignet) et ajuste en direct quand il dit « Lucas boite » (App Intents / Siri).
- **Cas réel** : Project Play (Aspen Institute) recommande le temps de jeu égal jusqu'à 12 ans et note que beaucoup d'enfants quittent faute de temps de jeu ; un parent-coach y raconte chronométrer des changements toutes les 5 min avec le chrono de son iPhone (https://projectplay.org/news/2018/1/11/why-project-play-recommends-equal-playing-time-for-kids). Le top des plaintes des joueurs actuels est « mauvais coaching » 23 % (https://projectplay.org/news/aspen-institute-national-survey-of-youth-and-sports-15-key-findings). Existant : PitchTime et Put Me In (startups américaines non financées, anglophones, rien de dominant en France) — à tester, pas à ignorer.
- **Offre** : gratuit pour 1 équipe et 1 match ; 14,99 € par saison (achat ponctuel, sans abonnement fatigant) ou 3,99 €/mois. Raison de revenir : un match chaque week-end, 9 mois par an, l'historique des minutes par enfant sert à répondre aux parents.
- **Brique Apple** : Live Activities + App Intents (commande vocale mains pleines) + Foundation Models pour transformer la phrase libre en contraintes typées (@Generable). Honnêtement l'IA n'est que le parseur de contraintes ; sans elle il reste un formulaire, donc c'est la voix mains libres au bord du terrain qui doit être le coeur.
- **Probabilité qu'un autre LLM la propose** : 4 %

---

## 2. **Marge Rouge** — un correcteur à la voix qui écrit les commentaires de copie dans le style du prof, pour la pile de 30 copies du dimanche soir

- **Mécanique** : le prof photographie la copie (ou saisit juste le nom), dit trois mots (« fil rouge manquant, belle intro, orthographe »). L'app génère 2 phrases de commentaire à son ton, apprises sur ses 10 premiers exemples, qu'il recopie ou copie dans Pronote. Un widget affiche « 11 copies restantes ». Les noms d'élèves ne quittent jamais l'iPhone (on-device).
- **Cas réel** : douleur du prof qui subit 30 copies × 3 trimestres d'appréciations. Aucun chiffre sourcé trouvé dans mes recherches (recherche sur le temps de correction sans résultat exploitable) : à vérifier auprès de 2 profs avant de l'affirmer. Argument de fond : les données d'élèves sont sensibles, ce qui rend l'on-device (Foundation Models, FR inclus, fiche terrain) un vrai avantage face aux chatbots cloud que l'Éducation nationale déconseille.
- **Offre** : 6,99 €/mois ou 49 €/an, essai 7 jours après la première copie corrigée. Raison de revenir : correction toute l'année scolaire, 2 à 4 fois par semaine ; payeur = utilisateur (le prof paie de sa poche, comme pour ses outils).
- **Brique Apple** : Foundation Models (génération stylée en français, entrée image annoncée WWDC26, ancrage sur des exemples en contexte, 4096 tokens), Vision pour l'OCR du nom/note, widget.
- **Risque assumé** : canal d'acquisition difficile (profs), 3 non-devs ESSEC sans réseau profs ; risque que le ton paraisse « générique ». Le test de survie : si on retire l'IA, il ne reste qu'un dictaphone, donc l'IA est bien le produit.
- **Probabilité qu'un autre LLM la propose** : 20 %

---

## 3. **Prix Vrai** — un scan de deux étiquettes de rayon qui dit lequel est vraiment le moins cher au kilo, pour l'instant où on hésite devant le rayon

- **Mécanique** : en rayon, on pointe l'iPhone sur deux étiquettes (ou deux emballages) ; l'app lit « 3 + 1 offert, 4 × 330 ml, -30 % sur le 2e » et affiche le vrai prix au litre/kilo et un verdict en un mot, avec le nombre de grammes disparus si on a déjà scanné ce produit (réduflation). L'enseigne ne peut pas faire cela : son modèle repose sur l'opacité des promotions.
- **Cas réel** : l'UFC-Que Choisir relève 60 € d'écart moyen sur un panier de 98 produits entre l'enseigne la moins chère et la plus chère (https://www.quechoisir.org/decryptage-prix-a-la-consommation-de-gros-ecarts-entre-supermarches-n98760). Les promotions du type « 2+1 » rendent le calcul mental impossible, et les étiquettes sont non standardisées, d'où le besoin d'une lecture intelligente et non d'un simple OCR. Existant : calculateurs de prix au kilo manuels (saisie) ; Yuka/Open Food Facts ne comparent pas le prix. Pas de scraping : tout vient de la caméra.
- **Offre** : 3 scans gratuits/jour ; 2,99 €/mois ou 19,99 €/an (promesse : « se rembourse au 2e passage en caisse »). Raison de revenir : courses hebdomadaires, historique perso des prix, widget « dernier prix vu ».
- **Brique Apple** : Vision (reconnaissance de texte sur étiquettes) + Foundation Models (@Generable pour structurer « 3 pour 2, 330 ml × 6 » en nombres, tolérance aux formats foireux) ; Visual Intelligence d'iOS 26 lit les étiquettes mais ne compare pas, c'est là le trou.
- **Probabilité qu'un autre LLM la propose** : 22 %

---

## 4. **Constat Vaisselle** — un procès-verbal pince-sans-rire d'huissier du lavabo, pour le colocataire qui en a marre, au moment où il pousse la porte de la cuisine

- **Mécanique** : on photographie l'évier (ou le salon, ou le frigo). Vision note l'état (assiettes, casseroles, durée estimée depuis la dernière photo) ; le modèle écrit un « constat d'huissier » daté, solennel et absurde (« le 12 oct. à 19h42, constatons 7 assiettes en situation de squat »), exporté en carte à envoyer dans le groupe de coloc. Streak de « jours sans constat » en widget.
- **Cas réel** : aucun chiffre sourcé (à valider par 5 entretiens de colocs). Argument structurel : la viralité est la raison d'être, chaque carte envoyée montre l'app à 3-5 colocs (question 7 de la fiche terrain).
- **Offre** : gratuit avec filigrane ; 1,99 €/mois ou 9,99 € à vie pour les « juridictions » (tons : huissier, tribunal de commerce, commentateur sportif) et sans filigrane. Raison de revenir : tension quotidienne tant qu'il y a des colocs. **Point faible honnête** : le consentement à payer est incertain (c'est un jouet) et la durée de vie est courte une fois la blague vue ; à classer comme idée à fort partage, faible monétisation, à garder seulement si le jury valorise le fun.
- **Brique Apple** : Vision (classification de la scène) + Foundation Models (rédaction à ton imposé, image en entrée WWDC26) + ShareLink / Messages.
- **Probabilité qu'un autre LLM la propose** : 8 %

---

## 5. **Preuve Voisin** — un journal sonore daté et recevable pour le locataire exaspéré par la musique d'à côté, pour la nuit où il n'en peut plus

- **Mécanique** : le soir, on pose l'iPhone et on lance. Il classe localement (SoundAnalysis) musique, cris, perceuse, aboiements, sans conserver l'audio, mesure l'intensité et horodate les épisodes. Le matin : une main courante claire et un modèle de courrier au voisin/syndic adapté au ton choisi (amiable → mise en demeure), prêt à envoyer en PDF.
- **Cas réel** : 17 % des Français disent avoir eu une altercation de voisinage liée au bruit entre déc. 2023 et déc. 2024 (https://www.ladepeche.fr/2025/04/20/conflits-de-voisinage-nombre-et-frequence-des-litiges-phenomene-estival-les-troubles-entre-voisins-augmentent-ils-vraiment-12636308.php) ; la gêne de voisinage est centrée sur le comportement des voisins à 62 % (CidB, https://www.bruit.fr/images/pdf/Enqute_sur_lvolution_de_la_perception_du_bruit_lie__la_crise_sanitaire.pdf) ; le CidB publie un guide « constat sans mesurage », preuve que le sujet est procédural.
- **Offre** : 4,99 € le « dossier » (achat ponctuel par litige) ou 3,99 €/mois ; premier épisode détecté gratuit pour voir la valeur dès la première nuit. **Point faible honnête** : usage lié à un conflit, il s'éteint quand le conflit se règle ; la raison de revenir est la surveillance nocturne tant que le bruit dure. Éviter toute allégation juridique (« preuve recevable » : écrire « journal de constat ») et ne pas enregistrer de voix, pour la review App Store et la vie privée.
- **Brique Apple** : SoundAnalysis (classifieur de sons on-device) + Foundation Models (courrier à ton gradué à partir des épisodes) + Live Activity pour « enregistrement en cours » + App Intents.
- **Probabilité qu'un autre LLM la propose** : 12 %

---

## 6. **Relance Douce** — un tableau de relances polies mais fermes pour le freelance ou l'étudiant en groupe qui attend la réponse d'un autre, pour chaque jour où on n'ose pas relancer

- **Mécanique** : on ajoute une attente en une phrase (« Camille doit m'envoyer sa partie avant jeudi », « le client n'a pas validé le devis »). Chaque matin, le widget affiche « 2 relances à envoyer ». Un tap génère le message au bon niveau d'insistance selon le nombre de relances déjà faites et l'enjeu, prêt à envoyer par Messages/Mail.
- **Cas réel** : le malaise de relancer est universel chez les 21-22 ans en travaux de groupe (cible naturelle de l'équipe, ce qui rend les 100 premiers utilisateurs gratuits à atteindre). Aucun chiffre sourcé : à valider par 5 entretiens avant vendredi. Attention : la réécriture est native iOS 26 (fiche terrain), donc la valeur doit être le suivi de l'escalade, pas la reformulation.
- **Offre** : 4,99 €/mois ou 29,99 €/an, essai 7 jours ; gratuit jusqu'à 3 attentes en cours. Raison de revenir : la liste vit tant qu'il y a des retards (quotidien).
- **Brique Apple** : widgets + Live Activity (« relance due ») + App Intents (« Siri, relance Camille ») + Foundation Models pour doser le ton selon l'historique.
- **Risque** : proche de « Rappels + réécriture » natifs. L'IA est moins indispensable que dans 2 ou 3, d'où une note de confiance faible.
- **Probabilité qu'un autre LLM la propose** : 18 %

---

## 7. **Méthode Maman** — un briefing de 20 secondes pour le parent qui doit aider sur des devoirs qu'il ne comprend plus, au moment du « papa, j'ai pas compris »

- **Mécanique** : le parent photographie la leçon ou l'exercice du cahier. L'app ne donne pas la réponse à l'enfant (l'inverse de Photomath et consorts) mais au parent : « la méthode attendue en 5e pour ça, la phrase pour l'expliquer, l'erreur classique, une question à poser pour que l'enfant trouve seul ».
- **Cas réel** : les apps de résolution de devoirs servent l'élève, donc le modèle économique du leader suppose que l'enfant obtienne la réponse (et elles sont accusées de favoriser la triche) ; le parent, lui, subit le décalage de méthode. Aucun chiffre sourcé trouvé : à valider en demandant à 5 parents (équipe : parents ou fratrie de collégiens autour de soi).
- **Offre** : 5,99 €/mois ou 39 €/an, essai 3 jours ; 2 briefings gratuits. Raison de revenir : devoirs quotidiens de septembre à juin (usage saisonnier mais long, à la différence du logement ou des candidatures).
- **Brique Apple** : Foundation Models avec entrée image (WWDC26) ; PCC gratuit sous 2 M de téléchargements pour les cas où le modèle on-device raisonne mal en maths. Vision pour le cadrage.
- **Risque** : le petit modèle on-device se trompe en maths, donc ne couvrir que français, histoire-géo et méthode avant de promettre les maths ; contenu de mineurs (aucune donnée enfant stockée). Concurrence indirecte : les apps de soutien scolaire et les chatbots généralistes.
- **Probabilité qu'un autre LLM la propose** : 25 %

---

## Récapitulatif

| # | Nom | Probabilité |
|---|-----|-------------|
| 1 | Temps Égal | 4 % |
| 2 | Marge Rouge | 20 % |
| 3 | Prix Vrai | 22 % |
| 4 | Constat Vaisselle | 8 % |
| 5 | Preuve Voisin | 12 % |
| 6 | Relance Douce | 18 % |
| 7 | Méthode Maman | 25 % |

Sous 20 % : Temps Égal, Constat Vaisselle, Preuve Voisin, Relance Douce (4 idées ; Marge Rouge est à la limite).

Classement perso (monétisation + raison de revenir + faisabilité) : Marge Rouge, Temps Égal, Prix Vrai ; Constat Vaisselle est la plus virale mais la plus fragile à vendre.
