# Classification d'âge (questionnaire App Store Connect), justifiée

Légende : **[F]** fait, **[I]** hypothèse, **⚠** non vérifié. Contexte : depuis la refonte d'Apple, les tranches sont 4+, 9+, 13+, 16+, 18+ et le niveau est **calculé** par Apple à partir des réponses du questionnaire (peche/03 §3.2). Les intitulés exacts du questionnaire changent : relire chaque question à l'écran. Réponses valables pour le comportement décrit dans CLAUDE.md et peche/00.

## Verdict recommandé
- **Répondre honnêtement à chaque question et accepter le niveau calculé.** Avec les réponses ci-dessous, le résultat attendu est **4+** [I ⚠, à lire à l'écran, je ne l'ai pas calculé avec l'outil Apple].
- **Ni 16+ ni 18+ ne se justifient** : aucun jeu d'argent, aucune boîte à butin, aucun contenu adulte, aucune publicité, aucun contenu généré par l'utilisateur visible par d'autres, aucun chat, aucun accès web libre.
- **13+** ne se justifierait que si l'on ajoutait de l'UGC public, un chat, un navigateur intégré ou des achats aléatoires. Les concurrents sociaux (Fishbrain) sont en 13+ parce qu'ils ont des comptes et des publications (peche/03 §1.1). Nous n'en avons pas.
- **Ne pas relever artificiellement la tranche** pour « se couvrir » : une classification trop haute n'est pas un rejet mais prive les jeunes pêcheurs (un quart des cartes sont des mineurs [F, FNPF]) d'une app conçue pour eux. Si l'équipe veut tout de même un plancher plus haut, Apple propose un réglage manuel de tranche d'âge ⚠ (à chercher dans la section Classification d'âge) ; à décider consciemment, pas par défaut.
- **Hors catégorie « Enfants » (Kids Category)** : ne pas cocher « Made for Kids ». Cette catégorie interdit l'analyse et la pub tierces et impose des portes parentales (peche/07 §7, guideline 1.3 ⚠) ; l'app n'est pas conçue pour les moins de 12 ans seuls. L'avertissement « moins de 12 ans : avec un adulte » reste dans l'app (CLAUDE.md / peche/03 garde-fou 12).

## Réponses question par question

| Thème du questionnaire ⚠ | Réponse | Justification |
|---|---|---|
| Violence dessinée / fantastique | Aucune | Aucun combat, aucune scène. |
| Violence réaliste | Aucune | Photos de poissons pris à la ligne et relâchés : pas de mise à mort montrée ni encouragée (relâcher est valorisé). |
| Violence réaliste prolongée, sanglante | Aucune | Aucun contenu. |
| Armes (réalistes) | Aucune | Un matériel de pêche n'est pas une arme ; l'app n'en montre pas. |
| Contenu sexuel, nudité | Aucun | |
| Langage grossier / humour cru | Aucun | Textes écrits en interne et relus (verificateur-wording). |
| Horreur / thèmes effrayants | Aucun | |
| Alcool, tabac, drogues | Aucun | |
| Médical / santé / bien-être | Aucun | Aucune fonction de santé. |
| Jeux d'argent simulés | **Non** | Pas de casino, pas de mise. |
| Jeux d'argent réels | **Non** | |
| Concours / loteries | **Non** | |
| **Boîtes à butin / achats aléatoires** | **Non** | Cartes obtenues par une prise réelle ou une sortie, jamais tirées au sort contre de l'argent. Le Pro vend des finitions et des albums à contenu connu (peche/03 garde-fou 10). |
| Contenu généré par l'utilisateur partagé avec d'autres | **Non** | Tout est local. Le partage d'image de carte passe par la feuille de partage système, sans publication dans l'app. |
| Messagerie / chat | **Non** | |
| Accès web non restreint | **Non** | Pas de navigateur intégré. Un lien « fédération de pêche » ouvre Safari, hors de l'app. |
| Publicité | **Non** | Aucun SDK pub. |
| Contrôle parental / vérification d'âge dans l'app | Non | Pas d'API Declared Age Range au MVP ⚠. |
| Achats intégrés | **Oui** (abonnement) | Abonnement Pro. Compté par Apple comme achat intégré ; la portée de ce critère sur la tranche est à lire à l'écran. |
| Localisation | Oui (facultative, approximative) | N'influence pas la tranche d'âge ; renseignée dans les permissions et App Privacy. |

## Cohérences
1. **Captures et textes** : aucune image de poisson maltraité ou hors de l'eau trop longtemps comme « héros » (peche/03 §3.3 : photo responsable). Éviter aussi toute capture qui montre des armes ou de l'alcool au second plan.
2. **Mineurs et achats** : l'abonnement passe par Apple ; la validation d'achat des comptes enfants (« Demander à acheter ») relève du compte familial Apple. Le paywall n'est jamais déclenché par une pression (pas de minuteur, pas de fausse rareté).
3. **Âge de consentement numérique en France : 15 ans** [F, CNIL] : sans compte ni collecte, l'article 8 du RGPD n'est pas sollicité (peche/03 §3.2). Cette position s'effondre si un compte, un classement ou un partage public est ajouté.
4. **COPPA (États-Unis)** : limiter la distribution au storefront France (et pays francophones décidés) tant qu'aucune analyse n'est faite [I] (peche/03 §3.2).
5. **Après la saisie** : noter ici le niveau réellement affiché par App Store Connect et la date, pour la traçabilité : `Niveau calculé : ____ (saisi le ____ par ____)`.
