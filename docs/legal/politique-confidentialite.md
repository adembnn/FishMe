# Politique de confidentialité de FishMe (réseau social inclus)

**BROUILLON À FAIRE RELIRE PAR UN JURISTE DE MWM.** L'équipe n'est pas juridique : ce texte n'a aucune valeur tant qu'il n'a pas été relu, corrigé et validé par MWM, puis par Adem. Écrit par S2 le 19 octobre 2026 pour la version qui porte le réseau social, mis à jour le même jour avec les décisions de Titouan (surnom seul, département par défaut, photo importée, texte d'un message signalé transmis). Il ne remplace pas la page assemblée par le questionnaire juridique de MWM (`get_legal_questionnaire`, `save_legal_answers`, `draft_legal_document`) : c'est le texte à comparer avec elle, ligne à ligne, et à faire coller aux étiquettes « App Privacy » (`store/app-privacy.md`) et au manifeste `PrivacyInfo.xcprivacy`. Rien n'est publié hors du dépôt sans le oui d'Adem.

Source : décisions du 19 octobre (`CLAUDE.md`), rapport R2 (`docs/reports/reseau/`), CGU (`docs/legal/conditions-fishme.md`), compteur de fréquentation (`docs/legal/frequentation-confidentialite.md`, repris ci-dessous), SDK Spark de MWM (`store/confidentialite-spark-flash.md`).
Les crochets `[...]` sont à remplir par MWM. Aucun article de loi n'est cité : l'équipe n'a lu aucun texte à la source.

Points ⚠ (à vérifier avant publication) :
- ⚠ Écrit avant la fin de L21 à L24 : il décrit le schéma de R2 et les décisions de Titouan du 19 octobre, pas un build. À relire après L23, champ par champ.
- ⚠ Chats d'ami et de club : décision de Titouan (zones partagées, jamais en base publique, participants seulement) ; R2 `schema.md` disait « base publique » pour le club. Le texte suit la décision. Quelle base iCloud héberge la zone d'un club (celle du fondateur ?) et ce qui arrive quand le fondateur supprime son profil : à écrire exactement après L22/L24.
- ⚠ Message signalé (§6) : décision de Titouan, le texte du message est joint à l'e-mail de signalement et copié dans l'enregistrement `Signalement`. Les deux endroits sont lisibles par l'équipe seulement (⚠ droits de lecture du type `Signalement` : la revue L24 ne les a pas vérifiés ; si le type est lisible par tous dans la base publique, le texte d'un message privé deviendrait public : à contrôler avant de publier). Durée de conservation : crochets pour MWM.
- ⚠ La liste des blocages en base privée suit la recommandation de R2 (question 4 de `decisions.md`, défaut « oui », pas encore validée par Adem). Si Adem la veut publique, §3 et §6 changent.
- ⚠ Durées de conservation : aucune n'est fixée par une décision (signalements, texte des messages signalés, e-mails). Les crochets sont à remplir par MWM.
- ⚠ Photo importée de la galerie (avatar, publication) : décision de Titouan ; « sans GPS, ré-encodée » et l'usage du sélecteur système sont à vérifier dans le build (L21, L23).
- ⚠ Droits des personnes, autorité de contrôle, cadre juridique du traitement, transferts hors de l'Union : formulés en termes généraux, sans article cité, à compléter par le juriste.
- ⚠ Ce qui est « collecté » au sens d'Apple pour la base privée et les zones partagées : voir `store/app-privacy.md`.
- ⚠ Ce que Spark envoie exactement : liste de MWM attendue (`store/confidentialite-spark-flash.md`, §4, questions 1 à 5).

## En bref

- Ta position précise, tes coins de pêche et les coordonnées de tes photos ne quittent jamais ton iPhone.
- Tu n'as pas de mot de passe : ton compte est ton identifiant Apple.
- Si tu as 15 ans ou plus et que tu publies, ton surnom, ton avatar et tes publications sont visibles de tous les utilisateurs de FishMe.
- À chaque publication, tu choisis le lieu affiché. Par défaut, le département seul ; tu peux ajouter le cours d'eau, ou choisir aucun lieu.
- Ta collection n'est jamais publique. FishMe ne te demande ni nom ni prénom : seulement un surnom.
- Tes messages d'amis et de clubs ne sont jamais dans la base publique. Si tu en signales un, son texte est transmis à l'équipe.
- La mesure d'usage est éteinte. Elle ne s'allume que si tu l'acceptes dans les Réglages. L'app ne te la propose jamais ailleurs.
- Il n'y a aucune publicité et aucun suivi.

## 1. Qui est responsable

[RAISON SOCIALE DE L'ÉDITEUR, à donner par MWM], [adresse]. Contact : fishme.app@gmail.com. Délégué à la protection des données, s'il y en a un : [à donner par MWM].

## 2. Où vont tes données

| Où | Quoi | Qui peut le lire |
|---|---|---|
| Ton iPhone seulement | ta position précise, tes coins de pêche, tes réglages, la photo brute avant recadrage | toi |
| Ta base privée iCloud (ton compte Apple) | ta sauvegarde : cartes, photos sans position GPS, sorties, niveau, clubs ; la liste des personnes que tu as bloquées | toi. Nous n'y avons pas accès (⚠ voir `store/app-privacy.md`) |
| Une zone partagée entre amis (iCloud), jamais la base publique | les cartes que tu partages à un ami et vos messages | toi et cet ami |
| Une zone partagée par club (iCloud), jamais la base publique | les messages du club | les membres du club |
| La base publique iCloud de FishMe | ton surnom, ton avatar, tes publications (photo ou vidéo, légende, lieu choisi, espèce et rareté de la carte liée), tes commentaires, tes likes, les clubs et leurs membres, les signalements (avec le texte du message, s'il s'agit d'un message d'ami ou de club) | les autres utilisateurs de FishMe pour le profil et les publications ; l'équipe de FishMe pour les signalements (§6) |
| MWM (SDK Spark), seulement si tu l'as accepté | des données d'usage (article 7) | MWM |

Apple héberge toutes les bases iCloud (iCloud, CloudKit). ⚠ À reprendre de la page d'Apple lors de la relecture : lieu d'hébergement, durée de conservation côté Apple, sous-traitants.

## 3. Ce qui est public

Si tu crées un profil et que tu publies, ces données sont visibles de tous les utilisateurs de FishMe, aussi longtemps que tu ne les supprimes pas :
- ton surnom (unique, de 3 à 20 caractères) et ton avatar ;
- tes publications : photo (prise avec l'app ou importée de ta galerie) ou vidéo de 15 secondes au plus, légende, lieu que tu as choisi, et si tu les as liées à une carte, l'espèce, la rareté et la taille ;
- tes commentaires et tes likes ;
- les clubs que tu as créés, ton appartenance à un club, ton rôle dans le club.

Tu es responsable de ce que tu publies. Les règles sont dans les conditions d'utilisation (articles 9, 10 et 11). Tu acceptes ces conditions en cochant une case quand tu crées ton profil. FishMe n'utilise pas ces contenus pour de la publicité et ne les revend pas.

Ce qui n'est jamais public : ta collection, tes messages d'amis et de clubs, ta position, tes coins de pêche, la liste des personnes que tu bloques.

## 4. Le lieu de tes publications

À chaque publication, tu choisis le lieu affiché. Le choix proposé par défaut est le département seul. Tu peux aussi choisir :
- le cours d'eau et le département (par exemple « La Marne · 94 ») ;
- aucun lieu.

Sur un plan d'eau nommé, le nom vaudrait un coin exact : l'app te propose seulement le département seul ou aucun lieu. Si tu choisis « aucun lieu », ta publication n'apparaît pas dans le fil de ta région.

Jamais une coordonnée, jamais ta position GPS ne sont publiées. Tes photos et tes vidéos, y compris une photo importée de ta galerie, sont recompressées avant l'envoi et partent sans métadonnées de position. Ton département ou ton cours d'eau est la seule indication de lieu qui sort de ton iPhone, et seulement parce que tu l'as choisi. Un cours d'eau et un département peuvent suffire à un connaisseur pour deviner un coin : garde « département seul » ou choisis « aucun lieu » si tu veux le garder secret.

## 5. Ce qui ne part jamais de ton iPhone

- ta position précise et celle de tes coins de pêche ;
- les coordonnées GPS enregistrées dans une photo (tes photos, y compris celles que tu importes de ta galerie, sont enregistrées sans elles) ;
- la photo envoyée à l'analyse de l'espèce : la reconnaissance se fait sur ton iPhone ;
- ton nom et ton prénom : FishMe ne les demande pas et ne les collecte pas.

Pour la météo, l'app envoie à Apple (WeatherKit) un point arrondi ou la position d'une station de relevés de l'OFB, jamais ta position exacte, pour obtenir la réponse. Pour le niveau des rivières, elle envoie à Hub'Eau un code de station. Les notifications d'orage ou de crue sont calculées sur ton iPhone. Les notifications de messages passent par le service de notifications d'Apple, après ton accord (⚠ à relire après L24 : l'app ne les demande qu'au premier message envoyé).

## 6. Les signalements et les blocages

- Tu peux signaler une publication, un commentaire, un message, un profil ou un club. L'app cache le contenu sur ton iPhone, prépare un e-mail à fishme.app@gmail.com, que tu envoies depuis ton app Mail, et enregistre un signalement dans la base publique : l'identifiant du contenu, l'identifiant de son auteur, le motif (choisi dans une liste), ton surnom et la date. Si le contenu signalé est un message d'ami ou de club, le texte de ce message est joint à l'e-mail et copié dans l'enregistrement du signalement, pour que l'équipe puisse le lire. Tu vois et tu peux modifier l'e-mail avant de l'envoyer. L'e-mail n'est jamais envoyé automatiquement.
- L'équipe de FishMe lit la boîte fishme.app@gmail.com et les signalements. Elle voit ce qui est public ; elle ne voit pas les messages d'amis ni de club, sauf le texte du message que tu signales. Seuls Titouan, Adem et Sullyvan, de l'équipe de FishMe, lisent la boîte et les signalements (⚠ les droits de lecture des enregistrements `Signalement` sont à vérifier dans CloudKit). Nous traitons les signalements et nous nous engageons à retirer sous 24 heures les contenus publics (publications, commentaires, profils) qui enfreignent les conditions et, pour les messages privés, les messages signalés dont le texte nous a été transmis (article 10).
- Nous gardons le signalement, le texte du message qui y est joint et l'échange par e-mail [durée à fixer par MWM, le temps du traitement et du suivi] pour traiter le signalement et pouvoir montrer que le délai a été tenu. Le texte du message n'est utilisé que pour examiner ce signalement.
- Quand tu bloques une personne, FishMe masque ce qu'elle publie et écrit chez toi. La liste des personnes que tu bloques est dans ta base privée : personne d'autre ne la voit.

## 7. La mesure d'usage (SDK Spark de MWM)

La mesure d'usage est éteinte par défaut. Elle ne s'allume que si tu l'acceptes dans les Réglages (« Mesure d'usage »), et tu peux la couper au même endroit à tout moment. L'app ne te la propose pas au premier lancement ni ailleurs dans le parcours. Tant que tu ne l'as pas acceptée, le SDK n'est pas lancé et rien n'est envoyé à MWM.

Si tu l'acceptes, le SDK Spark de MWM envoie à MWM des données d'usage : tes achats, tes interactions avec l'app, des mesures de performance, les plantages et des données de diagnostic, ainsi que des identifiants (un identifiant d'installation et un identifiant d'appareil) qui ne sont pas liés à ton identité. Il n'y a aucun suivi publicitaire. [Liste complète, base juridique, durée et lieu de conservation : à donner par MWM.] ⚠ Il reste à confirmer avec MWM si le SDK tire une position approximative de l'adresse IP (`store/confidentialite-spark-flash.md`, question 3).

Pour effacer les données de mesure d'usage, écris à fishme.app@gmail.com.

## 8. Le compteur de fréquentation

(Texte de `docs/legal/frequentation-confidentialite.md`, inchangé sur le fond, valable quand le compteur iCloud est branché.) Pour éviter que trop de pêcheurs se retrouvent au même endroit, FishMe compte combien de pêcheurs différents ont pêché sur un même tronçon de rivière ces 7 derniers jours. Au début d'une session, l'app enregistre dans la base publique iCloud d'Apple trois informations : le tronçon (désigné par la station de relevés OFB la plus proche, un point public), le jour, et un code tiré au hasard qui change chaque jour. Ni ta position exacte, ni ton nom, ni ton surnom, ni tes prises ne sont envoyés avec elles. Rien ne s'affiche tant que moins de 5 pêcheurs différents sont passés, et l'app n'affiche jamais un nombre, seulement « calme », « normal » ou « chargé ». Tu peux arrêter de participer dans Réglages, « Compteur de fréquentation » ; tu continues alors de voir les niveaux.

## 9. L'âge

Un profil public, publier, commenter et écrire à d'autres utilisateurs sont réservés aux personnes de 15 ans ou plus. L'app te demande de déclarer « J'ai 15 ans ou plus » et de cocher une case pour accepter les conditions d'utilisation, quand tu crées ton profil. Elle ne demande ni ne conserve de date de naissance. Si tu as moins de 15 ans, ces fonctions te restent fermées. FishMe n'est pas faite pour les enfants.

## 10. Combien de temps nous gardons tes données

- Ton profil, tes publications, tes commentaires, tes likes et tes messages de club : jusqu'à ce que tu les supprimes, ou que tu supprimes ton profil.
- Ta sauvegarde iCloud et tes cartes partagées : jusqu'à la suppression de ton compte dans l'app.
- Les signalements, avec le texte du message joint s'il y en a un : [durée à fixer par MWM].
- Les données de mesure d'usage : [durée à donner par MWM].
- Les messages que tu as envoyés à un ami peuvent rester chez lui après la suppression de ton compte.

## 11. Tes droits

Tu peux supprimer ton profil et tout ce que tu as publié dans les Réglages de l'app, sans nous écrire. Pour accéder à tes données, les faire corriger ou effacer, ou pour t'opposer à un traitement, écris à fishme.app@gmail.com. Tu peux aussi saisir l'autorité de protection des données de ton pays (en France, la CNIL). ⚠ Droits et délais à faire détailler par le juriste de MWM.

FishMe ne fait aucun profilage et ne montre aucune publicité.

## 12. Changements

Si cette politique change, l'app te le dit. La date de version est en haut de la page publiée. Version du brouillon : 19 octobre 2026.
