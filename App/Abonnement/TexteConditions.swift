// Généré depuis docs/legal/conditions-fishme.md par outils/legal/generer_conditions.py : ne pas modifier à la main.

import Foundation

/// Un article des conditions d'utilisation : un titre et ses paragraphes (markdown en ligne permis).
struct ArticleConditions: Identifiable, Sendable {
    let id: Int
    let titre: String
    let paragraphes: [String]
}

/// Le texte des conditions, embarqué dans l'app pour se lire hors ligne.
enum TexteConditions {
    /// Date affichée.
    static let version = "20 octobre 2026"
    /// Monte à chaque changement qui doit être ré-accepté.
    static let numeroVersion = 4
    static let articles: [ArticleConditions] = [
        ArticleConditions(id: 1, titre: "Qui édite FishMe", paragraphes: [
            "FishMe est éditée par [RAISON SOCIALE DE L'ÉDITEUR, à donner par MWM], [forme juridique et capital], immatriculée au RCS de [ville] sous le numéro [numéro], dont le siège est au [adresse]. Numéro de TVA : [numéro]. Directeur de la publication : [nom].",
            "Contact : fishme.app@gmail.com, téléphone ou formulaire : [à donner par MWM]. Pour une erreur dans une règle de pêche, utilise aussi « Signaler une erreur de règle » dans Mon club.",
            "Hébergement du site web de FishMe : [nom, adresse et téléphone de l'hébergeur, à donner par MWM]. Ta collection est hébergée par Apple, dans ton iCloud. Ce que tu publies est enregistré chez Apple, dans la base publique iCloud de FishMe (article 16).",
        ]),
        ArticleConditions(id: 2, titre: "Accepter ces conditions", paragraphes: [
            "Au premier lancement, l'app te montre un lien vers ces conditions avant que tu continues. En touchant le bouton pour continuer, sous ce lien, tu les acceptes. Quand tu crées ton profil, l'app te demande en plus de cocher une case pour accepter ces conditions : sans cette case, pas de profil.",
            "FishMe est faite pour les 15 ans et plus. Entre 15 et 18 ans, l'abonnement doit être acheté ou autorisé par un parent. Si tu as moins de 15 ans, ne crée pas de compte sans l'accord de tes parents, donné avec toi : il est nécessaire pour utiliser tes données.",
            "Avoir un profil public, publier, commenter et écrire à d'autres utilisateurs est réservé aux personnes de 15 ans ou plus. Avant de créer ton profil, l'app te demande de déclarer « J'ai 15 ans ou plus ». Elle ne te demande pas ta date de naissance et n'en conserve aucune.",
            "FishMe fonctionne sur iPhone avec iOS 27 ou plus récent.",
        ]),
        ArticleConditions(id: 3, titre: "Ce que fait l'app", paragraphes: [
            "FishMe t'aide à pêcher en eau douce en France : une carte des endroits où pêcher et des poissons qui y vivent (relevés de l'OFB), les règles de pêche avec leur source, la météo et le niveau des rivières, des conseils de pêche, et le Pescedex, ta collection de cartes faites à partir de tes prises.",
            "Si tu as 15 ans ou plus, tu peux aussi créer un profil, publier des photos et des vidéos de tes prises, aimer et commenter, écrire à tes amis et dans des clubs. Ces fonctions de réseau sont gratuites.",
            "La carte, les règles et la lecture de ton Pescedex sont gratuites. Certaines autres fonctions demandent l'abonnement FishMe Pro (article 12).",
        ]),
        ArticleConditions(id: 4, titre: "Les règles de pêche : l'arrêté fait foi, pas l'app", paragraphes: [
            "Les règles affichées (tailles, périodes, quotas, interdictions) viennent des textes officiels : Code de l'environnement et arrêtés préfectoraux. Chaque règle montre sa **source** et sa **citation**, à ouvrir d'un toucher.",
            "Ces règles ont été lues et mises en forme par une intelligence artificielle, puis comparées avec une seconde lecture automatique indépendante. Quand les deux lectures ne concordent pas, l'app n'affiche pas la règle et écrit « vérifie l'arrêté ». Ce contrôle ne remplace pas une relecture humaine : une règle peut être incomplète, dépassée ou fausse, et un arrêté peut changer en cours d'année.",
            "**Le texte officiel signé fait toujours foi**, jamais FishMe. Quand deux textes se contredisent sur une taille, l'app affiche la plus stricte avec ses deux sources. Avant de pêcher, vérifie la réglementation auprès de ta fédération de pêche, de ton association agréée (AAPPMA) ou de la préfecture, et aie sur toi ta carte de pêche.",
            "Tu es responsable de ce que tu pêches, gardes ou relâches. En cas de doute, relâcher est presque toujours le plus sûr. Attention : pour quelques espèces envahissantes (certaines écrevisses, la perche soleil, le poisson-chat), la loi interdit de les remettre à l'eau vivantes.",
        ]),
        ArticleConditions(id: 5, titre: "La reconnaissance et la mesure ne décident jamais à ta place", paragraphes: [
            "À partir de ta photo, l'app **propose** des espèces ; **c'est toi qui choisis** la bonne. Le verdict affiché vient ensuite de la table des règles sourcées, jamais de l'intelligence artificielle.",
            "La taille lue sur une toise, la taille estimée en réalité augmentée et le poids (toujours marqué « estimé ») peuvent se tromper. Pour garder un poisson, mesure-le toi-même avec une vraie toise. La reconnaissance se fait sur ton iPhone : ta photo n'est envoyée à aucun serveur pour être analysée.",
        ]),
        ArticleConditions(id: 6, titre: "Météo, niveau de l'eau, alertes et sécurité", paragraphes: [
            "La météo (Apple Weather), le niveau des rivières (Hub'Eau) et les alertes d'orage ou de crue sont donnés à titre d'information. Ils peuvent être en retard ou faux, et ne remplacent ni la vigilance officielle de Météo-France et de Vigicrues ni ton jugement.",
            "La pêche au bord de l'eau comporte des risques : noyade, berges glissantes, montée rapide de l'eau, orage. Ne pêche pas quand c'est dangereux, et respecte les propriétés privées et les zones interdites.",
            "Les relevés de l'OFB sont montrés avec leur nombre de pêches et l'année du dernier relevé. Ils disent quelles espèces ont été trouvées, pas que tu en prendras.",
        ]),
        ArticleConditions(id: 7, titre: "Ton compte et la sauvegarde de ta collection", paragraphes: [
            "Ton compte, c'est ton identifiant Apple : il n'y a pas d'inscription chez nous. Il sert à retrouver ta collection, tes cartes et ton abonnement quand tu changes d'iPhone ou que tu réinstalles l'app. Ta collection et tes repères privés (article 16) sont sauvegardés dans ton propre iCloud, avec ton identifiant Apple : nous ne te demandons pas de mot de passe et nous n'avons pas accès à ton iCloud. Ta carte de pêche, si tu l'as importée, est gardée sur cet iPhone et suit la sauvegarde de l'iPhone. Ton abonnement est lié à ton identifiant Apple et se récupère avec « Restaurer les achats ».",
            "Garde ton iPhone et ton identifiant Apple protégés. Si ton iPhone est perdu ou volé, ou si quelqu'un utilise ton compte sans ton accord, préviens Apple et écris-nous dès que possible.",
            "Tu peux supprimer ton profil et ton compte à tout moment dans les Réglages de l'app (Mon compte, « Supprimer mon profil » pour ton profil et ce que tu as publié, « Supprimer mon compte et mes données iCloud » pour tout le reste). Ton profil public (surnom et avatar), tes publications, tes commentaires, tes likes et tes messages de club sont alors supprimés, avec ta sauvegarde iCloud et tes cartes partagées, et tes amis perdent l'accès à ce que tu as partagé. Les messages que tu as écrits à un ami peuvent rester lisibles chez lui. Tes repères privés sont effacés avec ta sauvegarde iCloud. Tes cartes restent sur cet iPhone jusqu'à ce que tu supprimes l'app. Pour effacer aussi les données de mesure d'usage, écris-nous à l'adresse de l'article 1. La suppression du compte ne résilie pas ton abonnement : celui-ci se résilie chez Apple (article 12).",
        ]),
        ArticleConditions(id: 8, titre: "Amis et clubs : ce que tu partages", paragraphes: [
            "Ta collection n'est jamais publique. Tu peux inviter des amis à la voir : seules les personnes que tu invites la voient. Une carte partagée montre au plus le département de ta prise, jamais ton coin de pêche, et ses photos sont envoyées sans position GPS.",
            "Les messages entre amis ne sont lisibles que par vous deux. Les messages d'un club ne sont lisibles que par les membres du club. Ils ne sont jamais enregistrés dans la base publique. Une seule exception : si quelqu'un signale un message, le texte de ce message (ses 500 premiers caractères au plus) est joint à l'e-mail du signalement et copié dans l'enregistrement du signalement dans FishMe, que seule l'équipe de FishMe peut lire (article 10). Le reste de la conversation n'est pas transmis. Un club se rejoint avec un lien : toute personne qui reçoit le lien peut le rejoindre et lire les messages. N'y écris rien de secret.",
            "Écrire à un ami ou dans un club demande d'avoir 15 ans ou plus (article 2). Tu ne partages que des photos que tu as le droit de montrer. Une personne qui apparaît sur ta photo doit être d'accord. Les règles de l'article 10 valent aussi pour les messages.",
        ]),
        ArticleConditions(id: 9, titre: "Ton surnom et ton avatar", paragraphes: [
            "Pour publier, commenter ou écrire, tu crées un profil avec un surnom et un avatar. Ton surnom est unique et compte de 3 à 20 caractères. Ton surnom et ton avatar sont publics : tous les utilisateurs de FishMe les voient, avec ce que tu publies. Tu peux choisir ton avatar parmi ceux de l'app ou dans une photo de ta galerie : l'app la recompresse et l'envoie sans position GPS.",
            "Choisis un surnom respectueux : pas le nom réel d'une autre personne, pas d'insulte, pas de marque, pas de lieu précis de pêche. Nous pouvons retirer un surnom ou un avatar qui ne respecte pas ces règles.",
            "FishMe ne te demande ni nom ni prénom : ton surnom est la seule identité de ton profil, et il est public. Tu peux changer ton surnom et ton avatar dans l'app, ou supprimer ton profil (article 7).",
        ]),
        ArticleConditions(id: 10, titre: "Contenu que tu publies", paragraphes: [
            "Tu peux publier des photos, prises avec l'app ou importées depuis ta galerie, des vidéos de 15 secondes au plus, des légendes et des commentaires, et écrire des messages. Une photo importée est recompressée et part sans position GPS. Ce que tu publies est visible par les autres utilisateurs de FishMe, pas seulement par tes amis. Tu es responsable de ce que tu publies.",
            "Ce qui est permis : tes prises, tes sorties, ton matériel, tes questions de pêcheur, des contenus dont tu as les droits. Si une autre personne apparaît, elle doit être d'accord.",
            "Ce qui ne l'est pas : un contenu choquant, haineux, violent, illégal, sexuel ou cruel envers les animaux ; le harcèlement ; le spam et la publicité ; la photo d'une personne mineure ou d'une personne sans son accord ; la mise en avant d'une pêche illégale ; le coin exact d'un autre pêcheur ou les coordonnées d'un coin. L'app refuse certains mots à la saisie : ce filtre est limité et ne remplace pas ton jugement.",
            "Tu peux signaler toute publication, tout commentaire, tout message et toute personne. L'app cache aussitôt le contenu sur ton iPhone, prépare un e-mail à fishme.app@gmail.com, que tu envoies depuis ton app Mail, et enregistre ton signalement dans FishMe. L'e-mail n'est pas envoyé tout seul : c'est toi qui l'envoies. Cette boîte est lue par Titouan, Adem et Sullyvan, de l'équipe de FishMe. Quand tu signales un message d'un ami ou d'un club, le texte de ce message (500 caractères au plus) est joint à l'e-mail et copié dans l'enregistrement du signalement, que seule l'équipe peut lire, pour qu'elle puisse le voir : sans cela, elle ne pourrait pas le lire. Nous ne surveillons pas les contenus en continu : nous agissons sur les signalements. Nous nous engageons à retirer sous 24 heures, après avoir reçu un signalement, le contenu public (publication, commentaire, profil) qui enfreint ces conditions. Pour un message privé, cet engagement vaut pour les messages signalés dont le texte nous a été transmis. Nous pouvons aussi retirer le profil de la personne qui l'a publié.",
            "Tu peux bloquer une personne : plus rien de ce qu'elle publie ou écrit ne s'affiche chez toi, et la liste des personnes que tu bloques reste dans ta sauvegarde privée.",
            "Tu peux supprimer à tout moment tes publications, tes commentaires et tes messages. Supprimer ton profil les efface tous (article 7).",
        ]),
        ArticleConditions(id: 11, titre: "Le lieu de tes publications", paragraphes: [
            "À chaque publication, c'est toi qui choisis le lieu affiché. Par défaut, c'est le département seul (par exemple « 94 »). Tu peux ajouter le cours d'eau (par exemple « La Marne · 94 »), ou choisir aucun lieu. Rien d'autre ne décrit le lieu de ta publication.",
            "Sur un plan d'eau nommé (un lac, un étang), le nom vaudrait un coin exact : l'app te propose alors seulement le département seul ou aucun lieu. Sans lieu, ta publication n'apparaît pas dans le fil de ta région.",
            "Jamais ta position GPS ni les coordonnées de ton coin ne sont publiées, et tes photos et tes vidéos sont envoyées sans position GPS. Mais le nom d'un cours d'eau et un département peuvent suffire à un connaisseur pour deviner un coin : si tu veux le garder secret, garde le département seul ou choisis aucun lieu. N'écris pas ton coin exact dans une légende, un commentaire ou un message.",
        ]),
        ArticleConditions(id: 12, titre: "FishMe Pro : l'abonnement", paragraphes: [
            "FishMe Pro ajoute des fonctions (par exemple d'autres spots, la météo sur 7 jours, la courbe du niveau de l'eau, « Préviens-moi », tous les conseils). Le prix en euros toutes taxes comprises, la durée et l'éventuel essai gratuit sont affichés avant l'achat. Le prix payé à ton achat reste celui de ton abonnement tant que tu restes abonné, sauf changement que tu acceptes auprès d'Apple.",
            "L'abonnement est acheté et facturé par Apple, sur ton compte Apple, au moment où tu confirmes l'achat. Il se renouvelle automatiquement pour la même durée, sauf si tu le résilies au moins 24 heures avant la fin de la période en cours. Tu le gères et le résilies dans les réglages de ton compte Apple (ou depuis Réglages, « Gérer l'abonnement ») ; la résiliation prend effet à la fin de la période déjà payée. La partie non utilisée d'un essai gratuit est perdue quand tu achètes un abonnement.",
            "Tu as 14 jours après ton achat pour changer d'avis, sans donner de raison : la demande de remboursement se fait auprès d'Apple, qui encaisse et rembourse (reportaproblem.apple.com), selon ce que tu as accepté au moment de l'achat. Le contrat de licence d'Apple pour les apps (EULA standard) s'applique aussi : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
            "Pendant toute la durée de ton abonnement, FishMe doit fonctionner comme annoncé. Sinon, tu peux demander la mise en conformité, puis une baisse du prix ou la fin du contrat avec remboursement (garantie légale de conformité, articles L224-25-12 et suivants du Code de la consommation) : écris-nous à l'adresse de l'article 1.",
        ]),
        ArticleConditions(id: 13, titre: "Ce que tu t'engages à faire", paragraphes: [
            "Utiliser FishMe pour toi, dans le respect de la loi, des règles de pêche, des espèces protégées et de la nature, et des articles 9, 10 et 11 pour tout ce que tu publies. Ne pas copier en masse les données de l'app, ne pas essayer de la détourner, de la contourner ou de la décompiler (sauf dans les cas que la loi permet), et ne pas gêner son fonctionnement.",
        ]),
        ArticleConditions(id: 14, titre: "Ce qui t'appartient, ce qui nous appartient", paragraphes: [
            "Tes photos, tes vidéos et tes prises t'appartiennent, y compris les photos que tu importes de ta galerie. En les publiant, tu autorises FishMe à les montrer aux autres utilisateurs dans l'app, selon le lieu que tu as choisi, tant que tu ne les supprimes pas. Cette autorisation sert seulement à les afficher dans FishMe : nous ne les réutilisons ni dans une publicité ni pour un autre usage commercial sans te le demander d'abord. Tu peux les supprimer à tout moment.",
            "En partageant une carte à un ami, tu nous autorises à la lui transmettre, le temps du partage. Si une autre personne apparaît sur un contenu, tu garantis avoir son accord.",
            "L'app, ses illustrations, ses cartes à collectionner, ses textes et ses conseils appartiennent à l'éditeur et à ses partenaires. Les données de l'OFB, de Hub'Eau, d'Apple Weather et les textes officiels gardent leurs propres licences, citées dans la page Sources. Le filtre de mots de FishMe utilise la liste LDNOOBW, sous licence Creative Commons Attribution 4.0 (CC BY 4.0) ; son attribution est dans la page Sources. Les noms et marques cités appartiennent à leurs propriétaires.",
        ]),
        ArticleConditions(id: 15, titre: "Responsabilité", paragraphes: [
            "Nous faisons de notre mieux pour que l'app marche et que ses informations soient justes, sans pouvoir promettre qu'elle sera toujours disponible ou sans erreur.",
            "Tu es responsable de ce que tu fais avec l'app : si tu gardes un poisson sans avoir vérifié l'arrêté ou sans l'avoir mesuré avec une vraie toise, ou si tu pêches malgré un danger, c'est ta responsabilité.",
            "Les contenus publiés par les utilisateurs restent sous la responsabilité de ceux qui les publient. Si un contenu te pose problème, signale-le (article 10).",
            "Cela ne change rien à ta garantie légale ni à notre responsabilité quand l'app ne fonctionne pas comme annoncé ou quand une erreur de notre part te cause un dommage. Rien dans ces conditions ne limite les droits que la loi te garantit comme consommateur.",
        ]),
        ArticleConditions(id: 16, titre: "Données personnelles", paragraphes: [
            "Ta position précise reste sur ton iPhone. Tes repères privés, c'est-à-dire les coins de pêche que tu enregistres avec leurs coordonnées exactes, sont sauvegardés dans ton iCloud privé, chiffré, et ne sont jamais partagés ni publiés. Ta collection et tes photos sont aussi sauvegardées dans ton iCloud, et envoyées seulement aux amis que tu invites, sans position GPS. Si tu importes ta carte de pêche, elle est stockée sur ton iPhone, protégée, et suit la sauvegarde de l'iPhone ; FishMe n'en lit et n'en garde ni le numéro ni le nom, et ne l'envoie nulle part.",
            "Ce que tu publies (photos, vidéos, légendes, lieu choisi, commentaires, likes), ton surnom et ton avatar sont enregistrés dans la base publique iCloud d'Apple associée à FishMe et visibles des autres utilisateurs. Les messages d'amis et de clubs restent dans des zones partagées, lisibles par leurs participants, jamais dans la base publique. FishMe ne collecte ni ton nom ni ton prénom : seulement un surnom. L'équipe de FishMe lit les contenus publics signalés et les signalements ; pour un message d'ami ou de club signalé, elle lit aussi le texte de ce message (500 caractères au plus), joint au signalement dont seule l'équipe a la lecture (article 10).",
            "La mesure d'usage est éteinte tant que tu ne l'as pas acceptée. Tu l'acceptes, et tu peux la couper à tout moment, seulement dans les Réglages : l'app ne te la propose jamais ailleurs. Tout est expliqué dans la politique de confidentialité de FishMe, accessible depuis les Réglages.",
        ]),
        ArticleConditions(id: 17, titre: "Changements, suspension, fin", paragraphes: [
            "Nous pouvons faire évoluer l'app, sans frais pour toi, pour suivre une nouvelle loi ou un nouvel arrêté, la corriger, l'améliorer ou suivre une évolution technique. Si un changement te gêne de façon importante, nous te prévenons au moins 30 jours avant, et tu peux alors arrêter gratuitement dans les 30 jours.",
            "Si nous changeons ces conditions, l'app te montre la nouvelle version et te demande de l'accepter ; si tu refuses, tu peux supprimer ton compte et l'app. La date de version est en haut de cette page.",
            "Tu peux arrêter d'utiliser FishMe à tout moment en supprimant ton compte et l'app. Si nous retirons un contenu, un profil ou l'accès au partage, nous t'expliquons pourquoi, sauf urgence ou obligation légale ; tu peux nous répondre à l'adresse de l'article 1 et nous réexaminons ta situation. Une suspension du partage n'enlève rien à ta collection, aux règles ni à ton abonnement.",
            "Nous ne pouvons pas empêcher techniquement une personne dont le profil a été retiré d'en créer un autre avec un autre surnom.",
        ]),
        ArticleConditions(id: 18, titre: "Droit applicable et litiges", paragraphes: [
            "Ces conditions sont soumises au droit français, sans te priver des règles protectrices du pays de l'Union européenne où tu vis.",
            "En cas de problème, tu peux nous écrire à l'adresse de l'article 1 : nous cherchons une solution avec toi. Ce n'est pas obligatoire : tu peux aussi saisir gratuitement le médiateur de la consommation, [NOM, ADRESSE POSTALE ET SITE DU MÉDIATEUR, à donner par MWM], ou le tribunal compétent.",
        ]),
    ]
}
