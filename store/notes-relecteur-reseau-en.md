# Notes pour le relecteur d'Apple : version qui porte le réseau social (S2)

**Brouillon, à relire par Adem, à contrôler contre le build TestFlight de la vague 2.** Remplace `notes-relecteur-en.md` (version du 16 octobre, sans réseau) dans le champ « Notes » d'App Store Connect. Écrit par S2 le 19 octobre 2026, mis à jour le même jour avec les décisions de Titouan (mode démo en lecture seule, surnom seul, accord aux conditions à la création du profil, département par défaut, photo importée, texte d'un message signalé transmis), depuis les fiches L21 à L24 et R2, pas depuis un build : chaque crochet `[...]` et chaque libellé de bouton se lit dans le build. Une fonction absente du build sort des notes (jamais de promesse d'une fonction absente). Longueur : 3789 octets comptés par Python (limite 4000) ; recompter après toute modification (`len(texte.encode("utf-8")) <= 4000`).

Cocher « Connexion requise » : non (aucun mot de passe). Le relecteur n'a pas besoin de deuxième compte : le mode démo montre le contenu d'exemple en lecture seule du fil et du chat (règle 2.1 : à faire accepter par Apple, voir ci-dessous). Si un compte de test était un jour ajouté, il serait saisi dans App Store Connect seulement, jamais dans git, jamais dans ce fichier.

⚠ État du code d'après la revue des règles (`C:\w\revues\regles-appreview.md`, point 2) : au moment de la revue, le mode démo de la Release ne remplissait que le Pescedex, les amis et le club ; le fil et le chat n'avait de contenu d'exemple que sous `#if DEBUG`, et n'étaient pas branchés dans `RootView`. Le paragraphe « DEMO MODE » du texte n'est vrai que si L25 étend `demo.communaute` au fil et au chat (lecture seule). Sinon il faut le retirer et fournir deux comptes iCloud. Apple demande un accès ou un mode démo qui montre toutes les fonctions (règle 2.1(a), lue par la revue sur developer.apple.com, pas relue par S2) : ⚠ la réponse d'Apple sur ce mode n'est pas connue.

## Qui lit la boîte (interne, ne va pas chez Apple)
- Lecteurs de fishme.app@gmail.com et des enregistrements `Signalement` : Titouan, Adem et Sullyvan (décision du 19 octobre). Le texte des notes dit « three team members » sans nom.
- Référent de la semaine : [référent de la semaine, à fixer par l'équipe]. Un référent par semaine, remplacé par l'un des deux autres en cas d'absence ; aucun nom n'est choisi ici.
- Au moins une lecture de la boîte et de la liste des signalements par jour, week-end compris, sinon l'engagement de 24 heures des CGU (article 10) n'est pas tenu. ⚠ Le texte promet un retrait sous 24 heures après réception : tant qu'un référent n'est pas fixé pour chaque semaine, ne pas envoyer la version à Apple.
- Journal de modération (un tableau partagé suffit) : date et heure du signalement, identifiant, motif, décision (retiré ou maintenu), heure du retrait, réponse envoyée. Il prouve le délai si Apple le demande.
- Accès au tableau de bord CloudKit (base publique, recherche par `recordName`) : [rôle à demander à MWM].
- Les messages d'ami et de club sont dans des zones partagées (jamais en base publique) : l'équipe ne les lit pas, sauf un message signalé, dont le texte est joint à l'e-mail et copié dans l'enregistrement `Signalement` (décision de Titouan du 19 octobre). ⚠ Retirer le message lui-même de la zone partagée n'est pas possible depuis le tableau de bord de l'équipe : l'action possible est de retirer le profil de son auteur, ou de demander à l'auteur de le supprimer. À préciser avec L24. ⚠ Droits de lecture du type `Signalement` dans CloudKit : s'assurer que seule l'équipe le lit.
- Réponse au relecteur : si le relecteur signale un contenu pendant la relecture, répondre sous 24 heures et retirer le contenu s'il enfreint les conditions.

## Texte à coller dans le champ « Notes » (anglais)

```
FishMe is a freshwater fishing app for France. The map shows fish recorded by the French Office for Biodiversity (OFB) and the rules that apply (each with source and quote); each confirmed catch becomes a collectible card in the user's "Pescedex" (the collection's name). This version adds a community: profile, feed, comments, likes, friend and club chat. All of it is free.

NO PASSWORD. The account is the device's Apple ID. The only identity is a public nickname: no real name or first name is asked or stored.

DEMO MODE (no second account needed). [EXACT PATH FROM THE BUILD, e.g. Settings > "Mode démo"] fills the app with sample content, read-only: the Pescedex, the feed (sample posts and comments) and the chat (sample friend and club conversations). Nothing is sent to iCloud in this mode. [CONFIRM IN THE BUILD: Report and Block menus open on the sample content.] Without demo mode, publishing needs iCloud signed in.

TEST WITHOUT A FISH
1. Launch. Allow location once or refuse and pick a department. Then one question ("Ton niveau ?"), then cards to swipe; "Passer" skips. No sheet appears at launch; usage measurement is only in Settings, off by default.
2. Test spot: Quai de Charenton, Paris, [LAT, LON from the build]. Tap the river: species, rarity, rules with sources.
3. "Commencer une session", "Ajouter une prise", "Essayer avec une photo d'exemple": pick one of 3 species, set the length, "Ranger dans le Pescedex". "Terminer" reveals the card, then the paywall (close it).

COMMUNITY (15+)
A. "Finis ton profil": tick "J'ai 15 ans ou plus" (no birth date kept), tick the box accepting the Terms, choose a nickname and an avatar (built-in, or a photo from the library: re-encoded, no GPS).
B. Publish: photo (camera or library) or 15 s video, caption, and the place, chosen each time. Default: department only; river + department or no place are options (no place: absent from "Dans ta région"). On a named lake only department or none. No coordinate or GPS ever leaves the phone.
C. Report: menu on any post, comment, message, profile or club card, "Signaler", pick a reason. The content hides at once; an e-mail to fishme.app@gmail.com is prefilled (the user sends it; nothing is sent automatically) and a report record is saved. For a friend or club message, its text is attached to the e-mail and copied into the report record so the team can read it.
D. Block: same menu, "Bloquer"; nothing from that person shows any more.
E. Chat: friends and clubs live in private shared iCloud zones, never in the public database. Report and block work on each message.
F. Delete: [EXACT LABELS FROM THE BUILD] "Supprimer mon profil" removes profile, posts, comments, likes, club messages; "Supprimer mon compte et mes données iCloud" removes the rest.

MODERATION. Typed text goes through a bad-words filter (LDNOOBW, CC BY 4.0, credited in Sources). The mailbox fishme.app@gmail.com and the report records are read by three team members. Public content (posts, comments, profiles) reported for breaking the Terms (article 10), and reported private messages whose text we receive, are removed within 24 hours.

LEGAL. Rules shown are indicative; the prefectoral order prevails. The AI only proposes a species; the user confirms; a sourced table gives the rule. Coverage: national baseline plus [DEPARTMENTS FROM THE BUILD].

SERVICES. Apple Maps; OFB and Hub'Eau (station code only); Apple Weather (rounded point, mark shown); species proposals run on device; CloudKit public database for posts and nicknames; MWM Spark SDK only after consent in Settings, not linked to identity, no tracking.

PRIVACY. Exact fishing spots never leave the iPhone; saved photos carry no GPS. Not for children: the community requires 15+.

Contact: [NAME], [PHONE], fishme.app@gmail.com.
```

## Ce qui est encore à lire dans le build
- Libellés exacts : chemin du mode démo, « Finis ton profil », « J'ai 15 ans ou plus », la case d'accord aux conditions, « Publier », « Signaler », « Bloquer », « Supprimer mon profil », « Supprimer mon compte et mes données iCloud ».
- Que le menu « Signaler » existe sur chaque type de contenu (publication, commentaire, message, profil, carte de club) : sinon la ligne C sort ou le type est corrigé (risque 3 de R2).
- Que l'ordre du premier lancement est bien celui de l'étape 1 (position, niveau, cartes à glisser, aucune feuille).
- Coordonnées du quai de Charenton, départements couverts, contenu d'exemple du mode démo : profil et publications d'exemple à signaler ou bloquer (lien de la vidéo de 60 s supprimé du texte pour tenir la limite : le remettre si de la place reste).
