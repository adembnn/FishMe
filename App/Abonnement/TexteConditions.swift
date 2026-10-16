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
    static let version = "16 octobre 2026"
    /// Monte à chaque changement qui doit être ré-accepté.
    static let numeroVersion = 1
    static let articles: [ArticleConditions] = [
        ArticleConditions(id: 1, titre: "Qui édite FishMe", paragraphes: [
            "FishMe est éditée par [RAISON SOCIALE DE L'ÉDITEUR, à donner par MWM], [forme juridique et capital], immatriculée au RCS de [ville] sous le numéro [numéro], dont le siège est au [adresse]. Numéro de TVA : [numéro]. Directeur de la publication : [nom].",
            "Contact : [E-MAIL DE CONTACT, à donner par Adem], téléphone ou formulaire : [à donner par MWM]. Pour une erreur dans une règle de pêche, utilise aussi « Signaler une erreur de règle » dans Mon club.",
            "Hébergement du site web de FishMe : [nom, adresse et téléphone de l'hébergeur, à donner par MWM]. Ta collection est hébergée par Apple, dans ton iCloud.",
        ]),
        ArticleConditions(id: 2, titre: "Accepter ces conditions", paragraphes: [
            "Tu peux lire ces conditions avant de créer ton compte. En touchant le bouton qui crée ton compte, sous la phrase qui renvoie à ces conditions, tu les acceptes.",
            "FishMe est faite pour les 15 ans et plus. Entre 15 et 18 ans, l'abonnement doit être acheté ou autorisé par un parent. Si tu as moins de 15 ans, ne crée pas de compte sans l'accord de tes parents, donné avec toi : il est nécessaire pour utiliser tes données.",
            "FishMe fonctionne sur iPhone avec iOS 27 ou plus récent.",
        ]),
        ArticleConditions(id: 3, titre: "Ce que fait l'app", paragraphes: [
            "FishMe t'aide à pêcher en eau douce en France : une carte des endroits où pêcher et des poissons qui y vivent (relevés de l'OFB), les règles de pêche avec leur source, la météo et le niveau des rivières, des conseils de pêche, et le Pescedex, ta collection de cartes faites à partir de tes prises.",
            "La carte, les règles et la lecture de ton Pescedex sont gratuites. Certaines fonctions demandent l'abonnement FishMe Pro (article 9).",
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
            "Ton compte sert à retrouver ta collection, tes cartes et ton abonnement quand tu changes d'iPhone ou que tu réinstalles l'app. Ta collection est sauvegardée dans ton propre iCloud, avec ton identifiant Apple : nous ne te demandons pas de mot de passe et nous n'avons pas accès à ton iCloud. Ton abonnement est lié à ton identifiant Apple et se récupère avec « Restaurer les achats ».",
            "Garde ton iPhone et ton identifiant Apple protégés. Si ton iPhone est perdu ou volé, ou si quelqu'un utilise ton compte sans ton accord, préviens Apple et écris-nous dès que possible.",
            "Tu peux supprimer ton compte à tout moment dans les Réglages de l'app. Ta collection sauvegardée et tes cartes partagées sont alors effacées, tes amis perdent l'accès à ce que tu as partagé, et les données de mesure d'usage qui te concernent sont supprimées. La suppression du compte ne résilie pas ton abonnement : celui-ci se résilie chez Apple (article 9).",
        ]),
        ArticleConditions(id: 8, titre: "Amis et club : ce que tu partages", paragraphes: [
            "Tu peux inviter des amis à voir ta collection. Elle n'est visible que par les personnes que tu invites, jamais en public. Une carte partagée montre au plus le département de ta prise, jamais ton coin de pêche, et ses photos sont envoyées sans position GPS.",
            "Tu ne partages que des photos que tu as le droit de montrer. Une personne qui apparaît sur ta photo doit être d'accord.",
            "Aucun contenu choquant, haineux, violent, illégal ou cruel envers les animaux n'est toléré. Tu peux signaler une carte ou une personne, et retirer ou bloquer un ami. Nous traitons chaque signalement sous 24 heures : nous retirons le contenu en cause et nous pouvons retirer l'accès au partage à la personne qui l'a envoyé.",
        ]),
        ArticleConditions(id: 9, titre: "FishMe Pro : l'abonnement", paragraphes: [
            "FishMe Pro ajoute des fonctions (par exemple d'autres spots, la météo sur 7 jours, la courbe du niveau de l'eau, « Préviens-moi », tous les conseils). Le prix en euros toutes taxes comprises, la durée et l'éventuel essai gratuit sont affichés avant l'achat. Le prix payé à ton achat reste celui de ton abonnement tant que tu restes abonné, sauf changement que tu acceptes auprès d'Apple.",
            "L'abonnement est acheté et facturé par Apple, sur ton compte Apple, au moment où tu confirmes l'achat. Il se renouvelle automatiquement pour la même durée, sauf si tu le résilies au moins 24 heures avant la fin de la période en cours. Tu le gères et le résilies dans les réglages de ton compte Apple (ou depuis Réglages, « Gérer l'abonnement ») ; la résiliation prend effet à la fin de la période déjà payée. La partie non utilisée d'un essai gratuit est perdue quand tu achètes un abonnement.",
            "Tu as 14 jours après ton achat pour changer d'avis, sans donner de raison : la demande de remboursement se fait auprès d'Apple, qui encaisse et rembourse (reportaproblem.apple.com), selon ce que tu as accepté au moment de l'achat. Le contrat de licence d'Apple pour les apps (EULA standard) s'applique aussi : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
            "Pendant toute la durée de ton abonnement, FishMe doit fonctionner comme annoncé. Sinon, tu peux demander la mise en conformité, puis une baisse du prix ou la fin du contrat avec remboursement (garantie légale de conformité, articles L224-25-12 et suivants du Code de la consommation) : écris-nous à l'adresse de l'article 1.",
        ]),
        ArticleConditions(id: 10, titre: "Ce que tu t'engages à faire", paragraphes: [
            "Utiliser FishMe pour toi, dans le respect de la loi, des règles de pêche, des espèces protégées et de la nature. Ne pas copier en masse les données de l'app, ne pas essayer de la détourner, de la contourner ou de la décompiler (sauf dans les cas que la loi permet), et ne pas gêner son fonctionnement.",
        ]),
        ArticleConditions(id: 11, titre: "Ce qui t'appartient, ce qui nous appartient", paragraphes: [
            "Tes photos et tes prises t'appartiennent. En les partageant, tu nous autorises seulement à les transmettre aux amis que tu as invités, le temps du partage. Si une autre personne y apparaît, tu garantis avoir son accord.",
            "L'app, ses illustrations, ses cartes à collectionner, ses textes et ses conseils appartiennent à l'éditeur et à ses partenaires. Les données de l'OFB, de Hub'Eau, d'Apple Weather et les textes officiels gardent leurs propres licences, citées dans la page Sources. Les noms et marques cités appartiennent à leurs propriétaires.",
        ]),
        ArticleConditions(id: 12, titre: "Responsabilité", paragraphes: [
            "Nous faisons de notre mieux pour que l'app marche et que ses informations soient justes, sans pouvoir promettre qu'elle sera toujours disponible ou sans erreur.",
            "Tu es responsable de ce que tu fais avec l'app : si tu gardes un poisson sans avoir vérifié l'arrêté ou sans l'avoir mesuré avec une vraie toise, ou si tu pêches malgré un danger, c'est ta responsabilité.",
            "Cela ne change rien à ta garantie légale ni à notre responsabilité quand l'app ne fonctionne pas comme annoncé ou quand une erreur de notre part te cause un dommage. Rien dans ces conditions ne limite les droits que la loi te garantit comme consommateur.",
        ]),
        ArticleConditions(id: 13, titre: "Données personnelles", paragraphes: [
            "Ta position précise et tes coins de pêche restent sur ton iPhone. Tes photos et ta collection sont sauvegardées dans ton iCloud, et envoyées seulement aux amis que tu invites, sans position GPS. La mesure d'usage ne démarre qu'avec ton accord, et tu peux la couper dans les Réglages. Tout est expliqué dans la politique de confidentialité de FishMe, accessible depuis les Réglages.",
        ]),
        ArticleConditions(id: 14, titre: "Changements, suspension, fin", paragraphes: [
            "Nous pouvons faire évoluer l'app, sans frais pour toi, pour suivre une nouvelle loi ou un nouvel arrêté, la corriger, l'améliorer ou suivre une évolution technique. Si un changement te gêne de façon importante, nous te prévenons au moins 30 jours avant, et tu peux alors arrêter gratuitement dans les 30 jours.",
            "Si nous changeons ces conditions, l'app te montre la nouvelle version et te demande de l'accepter ; si tu refuses, tu peux supprimer ton compte. La date de version est en haut de cette page.",
            "Tu peux arrêter d'utiliser FishMe à tout moment en supprimant ton compte et l'app. Si nous retirons un contenu ou l'accès au partage, nous t'expliquons pourquoi, sauf urgence ou obligation légale ; tu peux nous répondre à l'adresse de l'article 1 et nous réexaminons ta situation. Une suspension du partage n'enlève rien à ta collection, aux règles ni à ton abonnement.",
        ]),
        ArticleConditions(id: 15, titre: "Droit applicable et litiges", paragraphes: [
            "Ces conditions sont soumises au droit français, sans te priver des règles protectrices du pays de l'Union européenne où tu vis.",
            "En cas de problème, tu peux nous écrire à l'adresse de l'article 1 : nous cherchons une solution avec toi. Ce n'est pas obligatoire : tu peux aussi saisir gratuitement le médiateur de la consommation, [NOM, ADRESSE POSTALE ET SITE DU MÉDIATEUR, à donner par MWM], ou le tribunal compétent.",
        ]),
    ]
}
