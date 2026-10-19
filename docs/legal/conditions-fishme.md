# Conditions d'utilisation de FishMe (CGU)

**BROUILLON À FAIRE RELIRE PAR UN JURISTE DE MWM.** L'équipe n'est pas juridique : ce texte n'a aucune valeur tant qu'il n'a pas été relu, corrigé et validé par MWM, puis par Adem (S2, 19 oct. 2026). Les articles 2, 3, 7, 8, 9, 10, 11, 14, 16 et 17 ont changé avec le réseau social ; les autres sont ceux du 16 octobre (numéros décalés après l'article 8).

Source unique du texte des CGU. L'app l'affiche hors ligne (Réglages, et au premier lancement) : après chaque changement, lancer `python3 outils/legal/generer_conditions.py`, qui réécrit `App/Abonnement/TexteConditions.swift` (fichier de `App/`, régénéré par A dans L25, pas par S2). Un changement qui doit être ré-accepté fait monter `numero` de 1 : passé de 1 à 2 le 19 octobre.
Les crochets `[...]` sont à remplir avant l'envoi à Apple (identité de l'éditeur : MWM ; médiateur : MWM). Rien n'est publié hors du dépôt sans le oui d'Adem ; la version web passe par le serveur MCP de MWM.
Tout ce qui est au-dessus du premier titre `##` n'est pas montré dans l'app.

Points ⚠ (à vérifier avant publication, jamais montrés dans l'app) :
- ⚠ Aucun article de loi n'est cité dans les articles nouveaux : l'équipe n'a pas lu les textes à la source. Le seul renvoi à un texte de loi est celui de l'article 12 (garantie de conformité), repris tel quel du 16 octobre et lui aussi à faire relire.
- ⚠ Âge (article 2) : le seuil de 15 ans est la décision de Titouan du 19 octobre ; son fondement juridique n'est pas vérifié. La déclaration « J'ai 15 ans ou plus » est une déclaration, pas un contrôle : à faire juger par le juriste.
- ⚠ Retrait sous 24 heures (article 10) : engagement de FishMe, pas un chiffre écrit par Apple. Il suppose un référent qui lit la boîte (voir `store/notes-relecteur-reseau-en.md`, « Qui lit la boîte »). Tant que le référent de chaque semaine n'est pas fixé, ne pas publier.
- ⚠ Signalement (article 10) : l'e-mail est préparé par l'app mais envoyé par le pêcheur ; l'enregistrement `Signalement` est la trace sûre. Le texte le dit ainsi, sans promettre un e-mail automatique.
- ⚠ Suppression du profil (articles 7 et 9) : les libellés de boutons et la possibilité de changer de surnom dépendent de L21 ; relire contre le build. Les messages envoyés à un ami : ce que fait réellement la suppression (L21) reste à écrire exactement.
- ⚠ Chat de club : décision de Titouan du 19 octobre, zone partagée par club, lisible par les membres seulement. Le schéma de R2 (`MessageClub` en base publique) et la fiche L24 disent encore l'inverse : à corriger avant d'écrire du code.
- ⚠ Plan d'eau nommé (article 11) : « département seul ou aucun lieu » est un défaut à confirmer par Adem (`CLAUDE.md`, décision 4).
- ⚠ Pas de mention d'une exclusion technique : FishMe ne peut pas empêcher qui que ce soit de recréer un surnom (article 17). La phrase « nous signalons à Apple si la loi l'impose » proposée par R2 n'est pas reprise : à décider par MWM.

<!-- version: 19 octobre 2026 | numero: 2 -->

## 1. Qui édite FishMe

FishMe est éditée par [RAISON SOCIALE DE L'ÉDITEUR, à donner par MWM], [forme juridique et capital], immatriculée au RCS de [ville] sous le numéro [numéro], dont le siège est au [adresse]. Numéro de TVA : [numéro]. Directeur de la publication : [nom].

Contact : fishme.app@gmail.com, téléphone ou formulaire : [à donner par MWM]. Pour une erreur dans une règle de pêche, utilise aussi « Signaler une erreur de règle » dans Mon club.

Hébergement du site web de FishMe : [nom, adresse et téléphone de l'hébergeur, à donner par MWM]. Ta collection est hébergée par Apple, dans ton iCloud. Ce que tu publies est enregistré chez Apple, dans la base publique iCloud de FishMe (article 16).

## 2. Accepter ces conditions

Au premier lancement, l'app te montre un lien vers ces conditions avant que tu continues. En touchant le bouton pour continuer, sous ce lien, tu les acceptes.

FishMe est faite pour les 15 ans et plus. Entre 15 et 18 ans, l'abonnement doit être acheté ou autorisé par un parent. Si tu as moins de 15 ans, ne crée pas de compte sans l'accord de tes parents, donné avec toi : il est nécessaire pour utiliser tes données.

Avoir un profil public, publier, commenter et écrire à d'autres utilisateurs est réservé aux personnes de 15 ans ou plus. Avant de créer ton profil, l'app te demande de déclarer « J'ai 15 ans ou plus ». Elle ne te demande pas ta date de naissance et n'en conserve aucune.

FishMe fonctionne sur iPhone avec iOS 27 ou plus récent.

## 3. Ce que fait l'app

FishMe t'aide à pêcher en eau douce en France : une carte des endroits où pêcher et des poissons qui y vivent (relevés de l'OFB), les règles de pêche avec leur source, la météo et le niveau des rivières, des conseils de pêche, et le Pescedex, ta collection de cartes faites à partir de tes prises.

Si tu as 15 ans ou plus, tu peux aussi créer un profil, publier des photos et des vidéos de tes prises, aimer et commenter, écrire à tes amis et dans des clubs. Ces fonctions de réseau sont gratuites.

La carte, les règles et la lecture de ton Pescedex sont gratuites. Certaines autres fonctions demandent l'abonnement FishMe Pro (article 12).

## 4. Les règles de pêche : l'arrêté fait foi, pas l'app

Les règles affichées (tailles, périodes, quotas, interdictions) viennent des textes officiels : Code de l'environnement et arrêtés préfectoraux. Chaque règle montre sa **source** et sa **citation**, à ouvrir d'un toucher.

Ces règles ont été lues et mises en forme par une intelligence artificielle, puis comparées avec une seconde lecture automatique indépendante. Quand les deux lectures ne concordent pas, l'app n'affiche pas la règle et écrit « vérifie l'arrêté ». Ce contrôle ne remplace pas une relecture humaine : une règle peut être incomplète, dépassée ou fausse, et un arrêté peut changer en cours d'année.

**Le texte officiel signé fait toujours foi**, jamais FishMe. Quand deux textes se contredisent sur une taille, l'app affiche la plus stricte avec ses deux sources. Avant de pêcher, vérifie la réglementation auprès de ta fédération de pêche, de ton association agréée (AAPPMA) ou de la préfecture, et aie sur toi ta carte de pêche.

Tu es responsable de ce que tu pêches, gardes ou relâches. En cas de doute, relâcher est presque toujours le plus sûr. Attention : pour quelques espèces envahissantes (certaines écrevisses, la perche soleil, le poisson-chat), la loi interdit de les remettre à l'eau vivantes.

## 5. La reconnaissance et la mesure ne décident jamais à ta place

À partir de ta photo, l'app **propose** des espèces ; **c'est toi qui choisis** la bonne. Le verdict affiché vient ensuite de la table des règles sourcées, jamais de l'intelligence artificielle.

La taille lue sur une toise, la taille estimée en réalité augmentée et le poids (toujours marqué « estimé ») peuvent se tromper. Pour garder un poisson, mesure-le toi-même avec une vraie toise. La reconnaissance se fait sur ton iPhone : ta photo n'est envoyée à aucun serveur pour être analysée.

## 6. Météo, niveau de l'eau, alertes et sécurité

La météo (Apple Weather), le niveau des rivières (Hub'Eau) et les alertes d'orage ou de crue sont donnés à titre d'information. Ils peuvent être en retard ou faux, et ne remplacent ni la vigilance officielle de Météo-France et de Vigicrues ni ton jugement.

La pêche au bord de l'eau comporte des risques : noyade, berges glissantes, montée rapide de l'eau, orage. Ne pêche pas quand c'est dangereux, et respecte les propriétés privées et les zones interdites.

Les relevés de l'OFB sont montrés avec leur nombre de pêches et l'année du dernier relevé. Ils disent quelles espèces ont été trouvées, pas que tu en prendras.

## 7. Ton compte et la sauvegarde de ta collection

Ton compte, c'est ton identifiant Apple : il n'y a pas d'inscription chez nous. Il sert à retrouver ta collection, tes cartes et ton abonnement quand tu changes d'iPhone ou que tu réinstalles l'app. Ta collection est sauvegardée dans ton propre iCloud, avec ton identifiant Apple : nous ne te demandons pas de mot de passe et nous n'avons pas accès à ton iCloud. Ton abonnement est lié à ton identifiant Apple et se récupère avec « Restaurer les achats ».

Garde ton iPhone et ton identifiant Apple protégés. Si ton iPhone est perdu ou volé, ou si quelqu'un utilise ton compte sans ton accord, préviens Apple et écris-nous dès que possible.

Tu peux supprimer ton profil et ton compte à tout moment dans les Réglages de l'app (Mon compte, « Supprimer mon profil » pour ton profil et ce que tu as publié, « Supprimer mon compte et mes données iCloud » pour tout le reste). Ton profil public (surnom et avatar), tes publications, tes commentaires, tes likes et tes messages de club sont alors supprimés, avec ta sauvegarde iCloud et tes cartes partagées, et tes amis perdent l'accès à ce que tu as partagé. Les messages que tu as écrits à un ami peuvent rester lisibles chez lui. Tes cartes restent sur cet iPhone jusqu'à ce que tu supprimes l'app. Pour effacer aussi les données de mesure d'usage, écris-nous à l'adresse de l'article 1. La suppression du compte ne résilie pas ton abonnement : celui-ci se résilie chez Apple (article 12).

## 8. Amis et clubs : ce que tu partages

Ta collection n'est jamais publique. Tu peux inviter des amis à la voir : seules les personnes que tu invites la voient. Une carte partagée montre au plus le département de ta prise, jamais ton coin de pêche, et ses photos sont envoyées sans position GPS.

Les messages entre amis ne sont lisibles que par vous deux. Les messages d'un club ne sont lisibles que par les membres du club. Un club se rejoint avec un lien : toute personne qui reçoit le lien peut le rejoindre et lire les messages. N'y écris rien de secret.

Écrire à un ami ou dans un club demande d'avoir 15 ans ou plus (article 2). Tu ne partages que des photos que tu as le droit de montrer. Une personne qui apparaît sur ta photo doit être d'accord. Les règles de l'article 10 valent aussi pour les messages.

## 9. Ton surnom et ton avatar

Pour publier, commenter ou écrire, tu crées un profil avec un surnom et un avatar. Ton surnom est unique et compte de 3 à 20 caractères. Ton surnom et ton avatar sont publics : tous les utilisateurs de FishMe les voient, avec ce que tu publies.

Choisis un surnom respectueux : pas le nom réel d'une autre personne, pas d'insulte, pas de marque, pas de lieu précis de pêche. Nous pouvons retirer un surnom ou un avatar qui ne respecte pas ces règles.

Ton nom et ton prénom, si tu les donnes, sont facultatifs et privés : ils ne sont jamais affichés. Tu peux changer ton surnom et ton avatar dans l'app, ou supprimer ton profil (article 7).

## 10. Contenu que tu publies

Tu peux publier des photos, des vidéos de 15 secondes au plus, des légendes et des commentaires, et écrire des messages. Ce que tu publies est visible par les autres utilisateurs de FishMe, pas seulement par tes amis. Tu es responsable de ce que tu publies.

Ce qui est permis : tes prises, tes sorties, ton matériel, tes questions de pêcheur, des contenus dont tu as les droits. Si une autre personne apparaît, elle doit être d'accord.

Ce qui ne l'est pas : un contenu choquant, haineux, violent, illégal, sexuel ou cruel envers les animaux ; le harcèlement ; le spam et la publicité ; la photo d'une personne mineure ou d'une personne sans son accord ; la mise en avant d'une pêche illégale ; le coin exact d'un autre pêcheur ou les coordonnées d'un coin. L'app refuse certains mots à la saisie : ce filtre est limité et ne remplace pas ton jugement.

Tu peux signaler toute publication, tout commentaire, tout message et toute personne. L'app cache aussitôt le contenu sur ton iPhone, prépare un e-mail à fishme.app@gmail.com, que tu envoies depuis ton app Mail, et enregistre ton signalement dans FishMe. Nous ne surveillons pas les contenus en continu : nous agissons sur les signalements. Nous nous engageons à retirer sous 24 heures, après avoir reçu un signalement, le contenu qui enfreint ces conditions. Nous pouvons aussi retirer le profil de la personne qui l'a publié.

Tu peux bloquer une personne : plus rien de ce qu'elle publie ou écrit ne s'affiche chez toi.

Tu peux supprimer à tout moment tes publications, tes commentaires et tes messages. Supprimer ton profil les efface tous (article 7).

## 11. Le lieu de tes publications

À chaque publication, c'est toi qui choisis le lieu affiché : le cours d'eau et le département (par exemple « La Marne · 94 »), le département seul, ou aucun lieu. Rien d'autre ne décrit le lieu de ta publication.

Sur un plan d'eau nommé (un lac, un étang), le nom vaudrait un coin exact : l'app te propose alors le département seul ou aucun lieu, et le département est le choix proposé par défaut. Sans lieu, ta publication n'apparaît pas dans le fil de ta région.

Jamais ta position GPS ni les coordonnées de ton coin ne sont publiées, et tes photos et tes vidéos sont envoyées sans position GPS. Mais le nom d'un cours d'eau et un département peuvent suffire à un connaisseur pour deviner un coin : si tu veux le garder secret, choisis le département seul ou aucun lieu. N'écris pas ton coin exact dans une légende, un commentaire ou un message.

## 12. FishMe Pro : l'abonnement

FishMe Pro ajoute des fonctions (par exemple d'autres spots, la météo sur 7 jours, la courbe du niveau de l'eau, « Préviens-moi », tous les conseils). Le prix en euros toutes taxes comprises, la durée et l'éventuel essai gratuit sont affichés avant l'achat. Le prix payé à ton achat reste celui de ton abonnement tant que tu restes abonné, sauf changement que tu acceptes auprès d'Apple.

L'abonnement est acheté et facturé par Apple, sur ton compte Apple, au moment où tu confirmes l'achat. Il se renouvelle automatiquement pour la même durée, sauf si tu le résilies au moins 24 heures avant la fin de la période en cours. Tu le gères et le résilies dans les réglages de ton compte Apple (ou depuis Réglages, « Gérer l'abonnement ») ; la résiliation prend effet à la fin de la période déjà payée. La partie non utilisée d'un essai gratuit est perdue quand tu achètes un abonnement.

Tu as 14 jours après ton achat pour changer d'avis, sans donner de raison : la demande de remboursement se fait auprès d'Apple, qui encaisse et rembourse (reportaproblem.apple.com), selon ce que tu as accepté au moment de l'achat. Le contrat de licence d'Apple pour les apps (EULA standard) s'applique aussi : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

Pendant toute la durée de ton abonnement, FishMe doit fonctionner comme annoncé. Sinon, tu peux demander la mise en conformité, puis une baisse du prix ou la fin du contrat avec remboursement (garantie légale de conformité, articles L224-25-12 et suivants du Code de la consommation) : écris-nous à l'adresse de l'article 1.

## 13. Ce que tu t'engages à faire

Utiliser FishMe pour toi, dans le respect de la loi, des règles de pêche, des espèces protégées et de la nature, et des articles 9, 10 et 11 pour tout ce que tu publies. Ne pas copier en masse les données de l'app, ne pas essayer de la détourner, de la contourner ou de la décompiler (sauf dans les cas que la loi permet), et ne pas gêner son fonctionnement.

## 14. Ce qui t'appartient, ce qui nous appartient

Tes photos, tes vidéos et tes prises t'appartiennent. En les publiant, tu autorises FishMe à les montrer aux autres utilisateurs dans l'app, selon le lieu que tu as choisi, tant que tu ne les supprimes pas. Cette autorisation sert seulement à les afficher dans FishMe : nous ne les réutilisons ni dans une publicité ni pour un autre usage commercial sans te le demander d'abord. Tu peux les supprimer à tout moment.

En partageant une carte à un ami, tu nous autorises à la lui transmettre, le temps du partage. Si une autre personne apparaît sur un contenu, tu garantis avoir son accord.

L'app, ses illustrations, ses cartes à collectionner, ses textes et ses conseils appartiennent à l'éditeur et à ses partenaires. Les données de l'OFB, de Hub'Eau, d'Apple Weather et les textes officiels gardent leurs propres licences, citées dans la page Sources. Les noms et marques cités appartiennent à leurs propriétaires.

## 15. Responsabilité

Nous faisons de notre mieux pour que l'app marche et que ses informations soient justes, sans pouvoir promettre qu'elle sera toujours disponible ou sans erreur.

Tu es responsable de ce que tu fais avec l'app : si tu gardes un poisson sans avoir vérifié l'arrêté ou sans l'avoir mesuré avec une vraie toise, ou si tu pêches malgré un danger, c'est ta responsabilité.

Les contenus publiés par les utilisateurs restent sous la responsabilité de ceux qui les publient. Si un contenu te pose problème, signale-le (article 10).

Cela ne change rien à ta garantie légale ni à notre responsabilité quand l'app ne fonctionne pas comme annoncé ou quand une erreur de notre part te cause un dommage. Rien dans ces conditions ne limite les droits que la loi te garantit comme consommateur.

## 16. Données personnelles

Ta position précise et tes coins de pêche restent sur ton iPhone. Ta collection et tes photos sont sauvegardées dans ton iCloud, et envoyées seulement aux amis que tu invites, sans position GPS.

Ce que tu publies (photos, vidéos, légendes, lieu choisi, commentaires, likes), ton surnom et ton avatar sont enregistrés dans la base publique iCloud d'Apple associée à FishMe et visibles des autres utilisateurs. Les messages d'amis et de clubs restent dans des zones partagées, lisibles par leurs participants. Ton nom et ton prénom, si tu les donnes, restent privés. L'équipe de FishMe lit les contenus publics signalés et les signalements.

La mesure d'usage est éteinte tant que tu ne l'as pas acceptée. Tu l'acceptes, et tu peux la couper à tout moment, seulement dans les Réglages : l'app ne te la propose jamais ailleurs. Tout est expliqué dans la politique de confidentialité de FishMe, accessible depuis les Réglages.

## 17. Changements, suspension, fin

Nous pouvons faire évoluer l'app, sans frais pour toi, pour suivre une nouvelle loi ou un nouvel arrêté, la corriger, l'améliorer ou suivre une évolution technique. Si un changement te gêne de façon importante, nous te prévenons au moins 30 jours avant, et tu peux alors arrêter gratuitement dans les 30 jours.

Si nous changeons ces conditions, l'app te montre la nouvelle version et te demande de l'accepter ; si tu refuses, tu peux supprimer ton compte et l'app. La date de version est en haut de cette page.

Tu peux arrêter d'utiliser FishMe à tout moment en supprimant ton compte et l'app. Si nous retirons un contenu, un profil ou l'accès au partage, nous t'expliquons pourquoi, sauf urgence ou obligation légale ; tu peux nous répondre à l'adresse de l'article 1 et nous réexaminons ta situation. Une suspension du partage n'enlève rien à ta collection, aux règles ni à ton abonnement.

Nous ne pouvons pas empêcher techniquement une personne dont le profil a été retiré d'en créer un autre avec un autre surnom.

## 18. Droit applicable et litiges

Ces conditions sont soumises au droit français, sans te priver des règles protectrices du pays de l'Union européenne où tu vis.

En cas de problème, tu peux nous écrire à l'adresse de l'article 1 : nous cherchons une solution avec toi. Ce n'est pas obligatoire : tu peux aussi saisir gratuitement le médiateur de la consommation, [NOM, ADRESSE POSTALE ET SITE DU MÉDIATEUR, à donner par MWM], ou le tribunal compétent.

<!-- fin -->
