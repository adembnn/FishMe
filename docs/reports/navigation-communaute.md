# Navigation à 3 volets et volet communauté
Décision débloquée : la navigation à 3 volets façon Clash Royale et ce qu'on met dans le volet communauté pour vendredi.
Lu le 15/10/2026. Rien n'a été compilé ni testé (pas de Mac ici) : « possible » veut dire « possible d'après la doc ». Les heures sont des estimations.

## En bref
Image : Clash Royale est une rangée de trois pièces (ici) avec une barre de boutons en bas ; la pièce du milieu est la maison, on glisse d'une pièce à l'autre ou on touche le bouton. Chez nous, la maison est une carte plein écran, et c'est là que le glissement se bat avec le doigt qui déplace la carte.
- Navigation : une barre de 3 boutons toujours visible, glissement en plus (jamais à la place). Les HIG ne disent rien sur le glissement entre onglets. Base sûre en 1 h (barre système), glissement ensuite (3 à 5 h) avec repli si le test sur iPhone échoue.
- Communauté : pas de Game Center ni de CloudKit dans la version de vendredi. Le volet de droite devient « Mon club » : ta fédération, ton AAPPMA, ta carte de pêche, avec lien vers cartedepeche.fr. Aucun contenu d'autres utilisateurs, donc la règle 1.2 ne s'applique pas à ce volet.
- Données : le site cartedepeche.fr interdit la réutilisation sans autorisation écrite. Les 5 fédérations (75, 92, 93, 94, 77) se saisissent à la main depuis leurs sites officiels. Une liste nationale des AAPPMA existe via le Répertoire national des associations (Licence Ouverte), pour plus tard.

## 1. Navigation
### 1.1 Ce que fait Clash Royale
- Barre du bas toujours visible : « les utilisateurs ne se perdent pas, ils peuvent toujours revenir » ([The Rookies](https://www.therookies.co/blog/education/game-design-ux-best-practices-detailed-breakdown-of-clash-royale)). Deux façons d'aller d'un écran à l'autre : glisser à gauche ou à droite, ou toucher l'icône du bas (même source).
- Le jeu est pensé pour le portrait et « utilise la navigation par glissement horizontal entre les écrans » ([Karim Muhtar](https://karimmuhtar.com/ux-design/clash-royale)). Les fenêtres ne sont jamais plein écran et un toucher à côté les ferme (Rookies).
- Inférence : l'onglet du milieu est une scène avec un gros bouton, pas une surface qu'on fait glisser. Il n'y a donc pas de conflit de doigt chez eux, il y en aura chez nous.
- [?] 5 onglets, onglet « Combat » au centre et ouvert par défaut, icône qui grossit et libellé qui apparaît sur l'onglet actif : de mémoire, absent des sources lues. Une base d'écrans existe pour vérifier ([Game UI Database](https://gameuidatabase.com/gameData.php?id=1299)). Nous n'avons que 3 volets : le principe suffit.

### 1.2 Ce que disent les Human Interface Guidelines (lues en entier le 15/10)
- Barre d'onglets ([HIG](https://developer.apple.com/design/human-interface-guidelines/tab-bars)) : la barre reste visible, « sinon on oublie dans quelle zone on est » ; moins d'onglets, c'est plus facile ; ne jamais désactiver ni cacher un bouton, une section vide explique pourquoi ; des libellés ; sur iOS elle flotte sur un fond Liquid Glass ; si le contenu est coloré, une barre monochrome. Le mot « swipe » n'apparaît pas : aucun avis des HIG sur le glissement entre onglets.
- Gestes ([HIG](https://developer.apple.com/design/human-interface-guidelines/gestures)) : un geste personnalisé doit être « pas le seul moyen d'accomplir une action importante » ; « un raccourci par geste complète les gestes standard, il ne les remplace pas, même si cela coûte un toucher de plus » ; éviter les conflits avec les gestes qui ouvrent le système.
- Points de page ([HIG](https://developer.apple.com/design/human-interface-guidelines/page-controls)) : pour une série de pages, pas plus d'une dizaine de points. Nos 3 volets sont des sections : on garde les libellés, pas de points.
- Donc : barre de 3 boutons = chemin principal ; glissement = raccourci. Cela règle aussi VoiceOver (lecteur d'écran) et le Contrôle de sélection, qui n'ont pas à glisser.

### 1.3 Trois façons de le faire en SwiftUI (iOS 27)
| # | Façon | Proba qu'un autre LLM la propose (estimation) | Heures | Verdict |
|---|---|---|---|---|
| 1 | `TabView` standard avec `Tab` : barre flottante Liquid Glass du système, `tabBarMinimizeBehavior` ([Apple](https://developer.apple.com/documentation/swiftui/view/tabbarminimizebehavior(_:))) | 70 % | 1 | Base sûre. VoiceOver et HIG gratuits. Pas de glissement : il n'existe qu'avec le style `.page` ([Stack Overflow](https://stackoverflow.com/questions/79325367/disable-tabview-paging-gesture-while-keeping-scrollview-gesture)) |
| 2 | `TabView` en `.tabViewStyle(.page(indexDisplayMode: .never))` + barre maison | 55 % | 3 à 4 | Glissement natif, mais la barre système disparaît. Défaut signalé avec le SDK iOS 26 : pages décalées avec `.edgesIgnoringSafeArea(.vertical)` ([forum](https://developer.apple.com/forums/thread/815574), 1 message, 0 réponse, [?] reproductibilité) |
| 3 | `ScrollView(.horizontal)` + `scrollTargetBehavior(.paging)` + `scrollPosition(id:)` + barre maison ([WWDC23](https://developer.apple.com/videos/play/wwdc2023/10159)) | 25 % | 4 à 5 | Le plus de contrôle : `scrollDisabled` selon le volet, position pilotée par la barre. Un peu plus de code |
| 4 | Carte plein écran + feuille persistante à détentes, comme Localiser d'iOS 26 ([forum](https://developer.apple.com/forums/thread/787208), suggestion non vérifiée) | 8 % | 5 à 7 | Ni conflit de doigt ni onglets : mais ce n'est plus Clash Royale |
| 5 | Barre maison seule, sans glissement, animations Clash (icône qui grossit) | 15 % | 2 | Repli si les tests de glissement échouent |

### 1.4 Les pièges
- Carte et glissement : MapKit capte les glissements horizontaux sur la carte. [?] Aucune source trouvée sur `Map` dans un `TabView` paginé, à tester sur iPhone. Contournement qui ne dépend pas du résultat : sur le volet du centre, le glissement ne part que d'une bande de 24 pt à chaque bord ; ailleurs la carte garde ses doigts. Les volets de gauche et de droite glissent partout (sauf leurs propres défilements).
- VoiceOver : une barre maison dans un `TabView` paginé n'annonce pas « onglet 1 sur 3 ». Un ingénieur Apple parle de « bug possible » (rapport FB19401153, [forum](https://developer.apple.com/forums/thread/795761), aucun contournement donné). Parade à tester : `accessibilityLabel("Pescedex, onglet 1 sur 3")`, `accessibilityAddTraits(.isSelected)`, boutons d'au moins 44 pt.
- Mouvement réduit : les animations de l'icône active s'éteignent quand « Réduire les animations » est actif (bonne pratique, pas de source Apple lue).
- Geste de retour du système : un balayage depuis le bord gauche d'une pile de navigation entre en conflit avec un `TabView` paginé ([Stack Overflow](https://stackoverflow.com/questions/69207607/swipe-back-when-using-a-custom-navigation-bar-and-a-tabview-swiftui)). Les pages poussées (fiche d'un poisson) n'appartiennent pas au pager.
- Contraintes du plan : seul A touche `App/RootView.swift` ; chaque volet vit dans son dossier (`App/<lot>/`).

## 2. Volet communauté sans serveur
### 2.1 Game Center (GameKit) en 2026
- Ce que c'est : classements, succès, amis, et depuis iOS 26 l'app Jeux préinstallée qui les met en avant ([Apple](https://developer.apple.com/games-app)).
- Dans une app qui n'est pas un jeu ? Aucun texte lu ne l'interdit : la page d'activation d'une version dans App Store Connect ne cite aucune restriction de catégorie ([Apple](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-an-app-version-for-game-center)). Mais tout est écrit pour les jeux : « Game Center is Apple's social gaming network » ([HIG](https://developer.apple.com/design/human-interface-guidelines/game-center)) ; l'app Jeux affiche « les jeux disponibles sur l'App Store ». [?] Nos catégories Sports ou Style de vie n'ont aucun bénéfice de découverte, et aucun cas d'app non-jeu lu.
- Blocage possible : « pour ajouter un jeu avec Game Center à un nouveau bundle, le jeu doit être Ready for Distribution dans au moins une boutique » ([Apple](https://developer.apple.com/help/app-store-connect/configure-game-center/overview-of-game-center)). Le texte dit « jeu » ; [?] s'applique-t-il à nous (nouveau bundle, première version) ?
- Revue à part : classements et succès ont leurs statuts (En attente, En revue, Accepté, Live ; [Apple](https://developer.apple.com/help/app-store-connect/reference/game-center/leaderboards)). Une version approuvée avec Game Center ne peut plus le désactiver. Un développeur reçoit « A Game Center enabled app version must be added for review » ([forum](https://developer.apple.com/forums/thread/807474), sans réponse).
- Règles d'usage : ne pas afficher les identifiants de joueur, ne pas les exploiter (4.5.3 et 4.5.5, [règles](https://developer.apple.com/app-store/review/guidelines/)). Nous modérons les scores via « Manage scores and players » (100 premiers scores, blocage de joueurs, [Apple](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-scores-and-players)).
- Risque produit propre à nous : un classement qui récompense les cartes rares ou légendaires pousse à garder ou chercher des espèces protégées ou sous la taille. C'est exactement ce qui « peut nous être reproché ». Des succès sans classement (diversité, bredouilles, relâchers) évitent le problème.
- Qui crée quoi : MWM donne un rôle App Store Connect (Admin, App Manager, Developer ou Marketing suffit pour configurer) ; A ajoute la capacité Game Center dans Xcode (il est le seul à toucher aux capacités) ; B ou C crée les composants dans le portail (identifiant de classement permanent, 100 caractères, noms et formats en français) ; la version cochée « Game Center » part en revue avec eux.
- Temps : 3 à 5 h de code ([reports/amis.md](amis.md)) + 1 à 2 h de portail + une revue en plus [?]. Hors vendredi.

### 2.2 Les alternatives
| # | Option | Proba (estimation) | Heures | Règle 1.2 ? | Verdict |
|---|---|---|---|---|---|
| 1 | Game Center : classements + succès | 60 % | 4 à 7 | [?] alias et scores d'inconnus | Pas vendredi. Succès seuls en V2 |
| 2 | `CKShare` entre amis invités (CloudKit : partage sans serveur) | 50 % | 10 à 18 (L8) | oui, par prudence | Prévu en version suivante, déjà décidé dans `amis.md` |
| 3 | Partage d'une carte en image par la feuille de partage (`ShareLink`) | 45 % | 1 à 2 | a priori non [?] | Vendredi : bouton sur chaque carte |
| 4 | Fichier `.pescedex` par AirDrop | 25 % | 3 à 5 | minimal [?] | Repli de `amis.md` |
| 5 | Objectifs de collection personnels (« 4 sur 11 dans le 94 ») dans « Mon club » | 12 % | 1 | non | Déjà dans E6 : à réutiliser |
| 6 | Carte de pêche et fédération en tête du volet (rappel légal, lien d'achat) | 8 % | 2 à 3 | non | Recommandé pour vendredi |
| 7 | Rien à droite, 2 volets | 10 % | 0 | non | Refusé par Adem : 3 volets |
Probas : estimations, pas des mesures. Les lignes 5 et 6 sont sous 20 %.

## 3. Règles 1.2 et 5.1.1 : ce qui les déclenche
- Texte de 1.2 ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)) : les apps « with user-generated content or social networking services must include » un filtre des contenus choquants, « a mechanism to report offensive content and timely responses », « the ability to block abusive users » et « published contact information ». Pas de seuil d'audience, pas d'exception pour le privé (lecture de `app-store.md`, section 2.1).
- Ce qui déclenche : afficher à quelqu'un du contenu écrit ou photographié par un autre utilisateur. Rien d'autre.
| Fonction | Contenu d'un autre utilisateur affiché dans l'app ? | 1.2 |
|---|---|---|
| Pescedex, Mon club (fédération, carte de pêche) | non | non |
| Partage en image (`ShareLink`) | non : l'utilisateur envoie, nous n'hébergeons ni n'affichons | a priori non [?], aucun précédent trouvé |
| Game Center : classement mondial | oui : alias et scores d'inconnus | [?] ; Apple donne les outils de blocage |
| `CKShare` entre amis | oui : cartes d'amis | oui par prudence : signaler, retirer, contact, pas de texte libre |
- 5.1.1 : (i) lien vers la politique de confidentialité dans la fiche et dans l'app, pour toute app : mettre le lien dans « Mon club » ou les réglages. 5.1.1(v) (suppression de compte dans l'app) ne vaut que si l'app crée un compte ; ni Game Center ni iCloud n'en créent chez nous [?] (voir `app-store.md`). Les données d'un mineur sont couvertes par 5.1.4 si une fonction les partage (`app-store.md`, 2.2).
- Un contact publié reste exigé de toute façon (1.5 selon `app-store.md`) : une adresse e-mail dans « Mon club ».

## 4. « Mon club de pêche » : les données
- cartedepeche.fr, site de la FNPF, a bien un annuaire : une page par AAPPMA avec contact, dépositaires, degré de réciprocité, sa fédération et le guide départemental en PDF ([exemple](https://www.cartedepeche.fr/association/4/124-annuaire-des-associations.htm)). Pas d'API, pas d'export. La page des fédérations ([lien](https://www.cartedepeche.fr/127-federations-departementales.htm)) annonce 94 fédérations mais ne donne que code et nom.
- Réutilisation : « Toute utilisation du contenu du site doit avoir préalablement fait l'objet d'une autorisation expresse » ([mentions légales](https://www.cartedepeche.fr/160-mentions-legales.htm)). Donc pas de copie de l'annuaire dans l'app sans l'accord écrit de la FNPF. [?] CGU et robots.txt non lus. Lier vers une page est autre chose que la copier : [?] aucun texte lu.
- Données ouvertes : le Répertoire national des associations (RNA) donne objet et adresse du siège, sous Licence Ouverte, mise à jour apparemment mensuelle ([data.gouv.fr](https://www.data.gouv.fr/datasets/repertoire-national-des-associations), zips de 94 à 391 Mo). On y filtre les associations dont l'objet est la pêche et la protection du milieu aquatique : nom et adresse, ni téléphone ni e-mail. L'API Association est ouverte à 10 appels par minute et par IP ([data.gouv.fr](https://www.data.gouv.fr/dataservices/api-association)). [?] Nombre d'AAPPMA, qualité du filtre, géocodage des adresses : non mesurés. 4 à 6 h, par script `scripts/donnees.sh`, jamais commité.
- Fédérations sur data.gouv.fr : la page de la fédération du Bas-Rhin affiche 0 jeu de données ([data.gouv.fr](https://www.data.gouv.fr/organizations/federation-du-bas-rhin-des-associations-agreees-pour-la-peche-et-la-protection-du-milieu-aquatique/datasets)) ; des lots de pêche existent localement (Alpes-de-Haute-Provence, Pas-de-Calais) mais ne couvrent pas nos 5 départements [?].
- Pour vendredi : un `federations.json` de 5 lignes (code, nom officiel, site officiel, date de relevé), saisi à la main depuis les sites des fédérations, vérifié par une 2e personne (comme D1), et un bouton qui ouvre la page de cartedepeche.fr. L'achat de la carte de pêche reste hors de l'app (lien seulement) : [?] 3.1.3(e) (biens et services hors de l'app) non lu, à vérifier avant d'écrire « acheter ».

## Recommandation
Structure : barre de 3 boutons en verre, toujours visible, ouverte sur le centre. Gauche « Pescedex » (E6), centre « Carte », droite « Club ». Glissement en raccourci, jamais seul chemin.
- Centre : carte plein écran (E1, E2) et deux boutons en verre au-dessus de la barre, « Commencer une session » (L5) et « Trouver le meilleur spot » (L7). Ces deux lots sont dans la version suivante : tant qu'ils ne sont pas fusionnés, ne pas afficher de bouton grisé (HIG) et garder « J'ai un poisson » (E5).
- Droite « Mon club » : (1) ma fédération et mon AAPPMA, lien vers cartedepeche.fr ; (2) « J'ai ma carte de pêche cette année » (case locale, rappel sans verdict) ; (3) politique de confidentialité et contact. Partage d'une carte en image sur chaque carte du Pescedex, pas dans le volet. Plus tard : amis `CKShare` (L8), succès Game Center, liste nationale des AAPPMA via le RNA.
- Rien de Game Center vendredi : pas de texte qui l'interdit, mais trois inconnues (nouveau bundle, revue séparée, bénéfice de l'app Jeux réservé aux jeux) et un classement qui pousse vers les espèces rares.
Heures (estimation) : barre système 3 volets 1 h (A) ; glissement + barre maison + passe VoiceOver 3 à 5 h (A), à ne tenter qu'une fois la base fusionnée ; `federations.json` 1 à 2 h (C, avec test dans `Core`) ; `App/Club/` 2 à 3 h (B) ; `ShareLink` 1 à 2 h (propriétaire du Pescedex) ; soit 8 à 13 h en tout. Ajouter à `docs/lots.md` un lot « Club » (dossier `App/Club/`) : c'est un changement du plan.
Test d'arrêt du glissement : sur un iPhone, un doigt qui déplace la carte ne change pas de volet et la bande de 24 pt le fait. Sinon, option 5 du tableau 1.3 (barre seule).
Option la plus forte écartée : Game Center avec classement d'amis, qui donne gratuitement amis, notifications et app Jeux, mais dépend d'une revue à part et n'affiche aucune carte.
Questions (3 au plus, défauts si pas de réponse) :
1. « Club » veut dire : a) l'association de pêche réelle (AAPPMA, fédération) ; b) le groupe d'amis dans l'app ; c) les deux, amis plus tard. Reco et défaut : c.
2. Carte au centre : a) plein écran, glissement par les bords et la barre ; b) aperçu non interactif qui s'ouvre en plein écran (zéro conflit, un toucher de plus en E1 et E2) ; c) barre seule, sans glissement. Reco et défaut : a, repli c.
3. Classements : a) aucun avant la version suivante ; b) succès Game Center seulement ; c) classement d'amis via `CKShare`. Reco et défaut : a.
