# Alignement à la fusion (simulation C:\w\merge, branche tmp/fusion-test)

Ordre simulé depuis origin/main : core-moderation, profil, collection-2, prise-2, feed, chat. Aucun conflit de fusion.
Ces alignements dépendent de lot/profil (L21) : ils ne compilent pas sur la branche seule, donc ils ne sont PAS codés sur les
branches d'origine. Ils sont à appliquer APRÈS la fusion de lot/profil, en un commit « alignement L21 » (commit f28ac341 de la simulation
à rejouer : `git cherry-pick f28ac341` sur la branche de fusion, ou refaire les diffs ci-dessous).

1. EffaceurFeed (App/Communaute/GestionFeed.swift) : supprimer le protocole `EffaceurContenuFeed` et son commentaire ;
   `struct EffaceurFeed: EffaceurContenuFeed` devient `struct EffaceurFeed: EffaceurContenu`.
2. EffaceurChat (App/Chat/GestionChat.swift) : `struct EffaceurChat: EffaceurMessages` devient `: EffaceurContenu` ;
   supprimer le protocole `EffaceurMessages` dans App/Chat/AnnuaireChat.swift. Garder `effacerMesMessages()` (ChatTests l.245).
3. MotifSignalementMessage (App/Chat/SignalementMessage.swift) : supprimer l'énumération, écrire `typealias MotifSignalementMessage = MotifSignalement`.
   MotifSignalementPublication (App/Communaute/ModelesFeed.swift) : idem, `typealias MotifSignalementPublication = MotifSignalement`.
   Cas, rawValue, titres et symboles sont identiques à ceux de L21 (vérifié) ; les tests rawValue de ChatTests/FeedTests passent inchangés.
4. AnnuaireChat.bloques() : l'adaptateur de A (et AnnuaireExemple dans App/Chat/ChatExemple.swift) renvoie
   `ListeBlocages.partage.profilsCaches()` (bloqués + masqués ; `bloques()` seul oublierait les profils signalés).
5. Publication.auteur : `PublicationFeed.auteurNom` / champ CloudKit `auteur` doit contenir l'`id` d'un `ProfilPublic`
   (`p-` + surnom normalisé, `ProfilModele.id`), jamais le surnom brut. Contrat de valeur, pas de changement de type : à vérifier dans
   PublierVue / GestionFeed.monNom quand A branche le profil (monNom = `ProfilModele.id`).

Renommages faits dans lot/chat (compatibles branche seule, commit 9b7e2a96) pour les collisions top-level :
`ResultatSignalement` devient `ResultatSignalementMessage` (collision avec L21), `SignalementEnAttente` devient `SignalementMessageEnAttente`
(collision avec L23), `DonneesExemple` devient `DonneesExempleChat` (collision avec L23).
