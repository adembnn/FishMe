# Notes pour le relecteur d'Apple : version qui porte le réseau social (S2)

**Brouillon, à relire par Adem, à contrôler contre le build TestFlight de la vague 2.** Remplace `notes-relecteur-en.md` (version du 16 octobre, sans réseau) dans le champ « Notes » d'App Store Connect. Écrit par S2 le 19 octobre 2026, depuis les fiches L21 à L24 et R2, pas depuis un build : chaque crochet `[...]` et chaque libellé de bouton se lit dans le build. Une fonction absente du build sort des notes (jamais de promesse d'une fonction absente). Longueur : 3362 octets comptés par Python (limite 4000) ; recompter après toute modification (`len(texte.encode("utf-8")) <= 4000`).

Cocher « Connexion requise » : non (aucun mot de passe). Mais le relecteur doit avoir un compte iCloud connecté pour publier : c'est dit dans le texte. Les deux comptes de test, créés par Adem ou MWM, sont saisis dans App Store Connect seulement, jamais dans git, jamais dans ce fichier.

## Qui lit la boîte (interne, ne va pas chez Apple)
- Lecteurs de fishme.app@gmail.com et des enregistrements `Signalement` : Titouan, Adem et Sullyvan (décision du 19 octobre).
- Référent de la semaine : [référent de la semaine, à fixer par l'équipe]. Un référent par semaine, remplacé par l'un des deux autres en cas d'absence ; aucun nom n'est choisi ici.
- Au moins une lecture de la boîte et de la liste des signalements par jour, week-end compris, sinon l'engagement de 24 heures des CGU (article 10) n'est pas tenu. ⚠ Le texte promet un retrait sous 24 heures après réception : tant qu'un référent n'est pas fixé pour chaque semaine, ne pas envoyer la version à Apple.
- Journal de modération (un tableau partagé suffit) : date et heure du signalement, identifiant, motif, décision (retiré ou maintenu), heure du retrait, réponse envoyée. Il prouve le délai si Apple le demande.
- Accès au tableau de bord CloudKit (base publique, recherche par `recordName`) : [rôle à demander à MWM].
- ⚠ Les messages de club et d'amis sont dans des zones partagées : l'équipe ne les lit pas. Un message signalé n'est retirable que par son auteur ou par la suppression du profil. À trancher par Adem (voir le rapport de S2).
- Réponse au relecteur : si le relecteur signale un contenu pendant la relecture, répondre sous 24 heures et retirer le contenu s'il enfreint les conditions.

## Texte à coller dans le champ « Notes » (anglais)

```
FishMe is a freshwater fishing app for France. The map shows fish recorded by the French Office for Biodiversity (OFB) and the rules that apply (each with source and quote); each confirmed catch becomes a collectible card in the user's "Pescedex" (the collection's name). This version adds a community: profile, feed, comments, likes, friend and club chat. All of it is free.

NO PASSWORD. The account is the device's Apple ID; iCloud must be signed in to publish. Test accounts for the community: [TWO TEST APPLE IDS, typed in App Store Connect only, never in git].

TEST WITHOUT A FISH
1. Launch. Allow location once or refuse and pick a department. Then one question ("Ton niveau ?"), then cards to swipe; "Passer" skips. No sheet appears at launch; the usage-measurement choice is only in Settings, off by default.
2. Test spot: Quai de Charenton, Paris, [LAT, LON from the build]. Tap the river: species, rarity, rules with sources.
3. "Commencer une session" (the first is always allowed). "Ajouter une prise", then "Essayer avec une photo d'exemple": 3 species as images, "Autre espèce", "Pas un poisson". Pick one, set the length, "Ranger dans le Pescedex". "Terminer" reveals the card, then the paywall (close it; use a sandbox account to buy).

COMMUNITY (15+)
A. Community tab, "Finis ton profil": tick "J'ai 15 ans ou plus" (no birth date kept), choose a nickname and avatar. Both are public; no real name is ever shown.
B. Publish: "Publier" on a Pescedex card or "+" in the feed. Photo or 15 s video, caption, and the place, chosen each time: river + department, department only, or no place (then the post is absent from "Dans ta région"). On a named lake only department or none is offered. No coordinate or GPS ever leaves the phone; media are re-encoded without metadata.
C. Report: menu on any post, comment, message, profile or club card, "Signaler", pick a reason. The content hides at once; an e-mail to fishme.app@gmail.com is prefilled (the user sends it) and a report record is saved.
D. Block: same menu, "Bloquer"; nothing from that person shows any more. A seeded profile "[TEST NICKNAME]" has a post to report or block.
E. Chat: friends (private shared zone) and clubs (members only, joined by link). Report and block work on each message.
F. Delete: [EXACT LABELS FROM THE BUILD] "Supprimer mon profil" removes profile, posts, comments, likes, club messages; "Supprimer mon compte et mes données iCloud" removes the rest.

MODERATION. Typed text goes through a bad-words filter (LDNOOBW, CC BY 4.0). The team reads fishme.app@gmail.com and the report records; reported content that breaks the Terms (article 10) is removed within 24 hours. Contact: fishme.app@gmail.com.

LEGAL. Rules shown are indicative; the prefectoral order prevails. The AI only proposes a species; the user confirms; a sourced table gives the rule. Coverage: national baseline plus [DEPARTMENTS FROM THE BUILD].

SERVICES. Apple Maps; OFB and Hub'Eau (station code only); Apple Weather (rounded point, mark shown); species proposals run on device; CloudKit public database for posts and nicknames; MWM Spark SDK only after consent in Settings, not linked to identity, no tracking.

PRIVACY. Exact fishing spots never leave the iPhone; saved photos carry no GPS. Not for children: the community requires 15+.

Contact: [NAME], [PHONE], fishme.app@gmail.com.
```

## Ce qui est encore à lire dans le build
- Libellés exacts : « Finis ton profil », « J'ai 15 ans ou plus », « Publier », « Signaler », « Bloquer », « Supprimer mon profil », « Supprimer mon compte et mes données iCloud ».
- Que le menu « Signaler » existe sur chaque type de contenu (publication, commentaire, message, profil, carte de club) : sinon la ligne C sort ou le type est corrigé (risque 3 de R2).
- Que l'ordre du premier lancement est bien celui de l'étape 1 (position, niveau, cartes à glisser, aucune feuille).
- Coordonnées du quai de Charenton, départements couverts, compte de test et profil de test (lien de la vidéo de 60 s supprimé du texte pour tenir la limite : le remettre si de la place reste).
