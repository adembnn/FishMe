# Chaînes d'usage (Info.plist) et messages d'amorçage des permissions (v0.1)

Règles Apple visées : 5.1.1(ii) une chaîne précise par ressource, phrase active, avec un exemple d'usage ; 5.1.1(iv) chaque refus laisse une voie alternative. Aucun texte ci-dessous n'affirme autre chose que ce que fait l'app : si le comportement change, le texte change (voir « Conditions de vérité »).

## 1. Chaînes d'usage (à placer dans `InfoPlist.strings` FR et EN, pas seulement dans la langue de développement)

| Clé | Texte français |
|---|---|
| `NSCameraUsageDescription` | Bredouille utilise l'appareil photo pour photographier ta prise et en faire une carte. La photo reste sur ton iPhone. |
| `NSLocationWhenInUseUsageDescription` | Bredouille utilise ta position une seule fois pour trouver ton département et afficher les poissons de ta région. Seul le numéro du département est conservé. |
| `NSPhotoLibraryAddUsageDescription` | Bredouille enregistre dans ta photothèque l'image de la carte que tu choisis de partager, par exemple pour la poster en story. |

Format `fr.lproj/InfoPlist.strings` :
```
"NSCameraUsageDescription" = "Bredouille utilise l'appareil photo pour photographier ta prise et en faire une carte. La photo reste sur ton iPhone.";
"NSLocationWhenInUseUsageDescription" = "Bredouille utilise ta position une seule fois pour trouver ton département et afficher les poissons de ta région. Seul le numéro du département est conservé.";
"NSPhotoLibraryAddUsageDescription" = "Bredouille enregistre dans ta photothèque l'image de la carte que tu choisis de partager, par exemple pour la poster en story.";
```

Variante de la localisation si « Démarrer une sortie » enregistre un lieu flou (à utiliser seulement dans ce cas) :
« Bredouille utilise ta position approximative pour trouver ton département, et pour situer une sortie si tu en démarres une. Elle reste sur ton iPhone. »

À NE PAS ajouter :
- `NSPhotoLibraryUsageDescription` : inutile tant que l'app passe par le sélecteur de photos du système (`PhotosPicker`), qui ne demande aucune permission. Si une API de photothèque complète est ajoutée un jour : « Bredouille lit la photo que tu choisis pour créer la carte de ta prise. Elle reste sur ton iPhone. »
- `NSLocationAlwaysAndWhenInUseUsageDescription` et `NSLocationAlwaysUsageDescription` : jamais de localisation en arrière-plan.
- `NSUserTrackingUsageDescription` : pas de suivi, pas d'ATT.
- `NSMotionUsageDescription` : l'inclinaison de la carte ne demande a priori pas d'invite ⚠ à vérifier dans la documentation Apple avant de livrer.
- Aucune clé pour les notifications (pas de chaîne d'usage : l'invite système utilise un texte fixe).

Conditions de vérité (à vérifier avant chaque envoi) :
1. « La photo reste sur ton iPhone » : vrai tant que l'analyse de la photo et la création de la carte n'envoient rien hors de l'appareil.
2. « Seul le numéro du département est conservé » : vrai tant qu'aucune coordonnée n'est écrite sur disque.
3. « Une seule fois » : vrai si l'app utilise le bouton de localisation du système (autorisation ponctuelle) ⚠ comportement exact à confirmer sur appareil.

## 2. Messages d'amorçage (écrans maison avant l'invite système)

Principe : amorcer seulement quand on a besoin du « oui » (caméra, notifications). Jamais avant le geste qui en a besoin, jamais deux invites d'affilée, jamais de relance après un refus : on propose « Ouvrir Réglages ». L'invite de localisation passe par le bouton du système, donc pas d'écran d'amorçage bloquant, seulement la feuille « Où pêches-tu ? ».

### Caméra (au premier tap sur l'obturateur, dans le viseur)
- Titre : Prends ta prise en photo (`onb.camera.title`)
- Texte : Bredouille a besoin de l'appareil photo pour créer ta carte. La photo reste sur ton iPhone. (`onb.camera.body`)
- Bouton principal : Autoriser l'appareil photo (`onb.camera.allow`), qui déclenche l'invite système
- Bouton secondaire : Choisir une photo (`onb.camera.alt`), et le lien « Essayer avec une photo d'exemple » (`onb.example.link`) reste visible
- Après un refus : « L'appareil photo est désactivé pour Bredouille. Tu peux choisir une photo ou l'activer dans Réglages. » + [Choisir une photo] [Ouvrir Réglages] (`err.camera.denied`, `err.camera.settings`)

### Localisation (feuille « Où pêches-tu ? », ouverte par la pastille « Affiner pour mon département » après la première carte)
- Titre : Où pêches-tu ? (`onb.dept.title`)
- Texte : La rareté dépend de ton département. Choisis-le à la main, ou laisse l'iPhone le trouver une seule fois. Seul le numéro du département est conservé. (`onb.dept.body`)
- Bouton système : bouton de localisation du système (son libellé est fixé par iOS) ; bouton secondaire : Choisir mon département (`onb.dept.pick`) ; lien : Plus tard (`onb.dept.later`)
- Après un refus : le sélecteur de département s'ouvre, texte « Sans position, choisis ton département à la main. Rien d'autre ne change. » (`err.location.denied`)

### Notifications (écran propre, jamais pendant la première session ; au premier de : fin de la première sortie, 2e carte, 2e ouverture)
- Titre : Un rappel au bon moment ? (`notif.prime.title`)
- Texte : Je te préviens quand l'ouverture de la saison approche chez toi. Tu règles tout dans Réglages. (`notif.prime.body`)
- Bouton principal : Activer les rappels (`notif.prime.allow`), qui déclenche l'invite système
- Bouton secondaire : Pas maintenant (`notif.prime.later`)
- Après un refus : rien ne casse ; ligne « Activer dans Réglages » dans Réglages > Rappels (`set.notif.system`)
- Engagement de fréquence (« jamais plus de X par mois ») : non écrit dans l'écran tant que la limite n'est pas codée et testée. (V)

### Photothèque en écriture (au premier « Partager en image » ou « Enregistrer la carte »)
- Aucun écran d'amorçage : la feuille de partage du système n'exige pas la permission. Seul l'enregistrement direct dans la photothèque déclenche l'invite, avec la chaîne ci-dessus.
- Après un refus : « Pour enregistrer l'image, autorise l'ajout à la photothèque dans Réglages. » (`err.photo.add`) et la feuille de partage reste disponible.

### Rappel d'ouverture et de facturation
- `notif.open` : L'ouverture approche chez toi. Vérifie l'arrêté de ta fédération. (date indicative, jamais de verdict)
- `notif.trial` : Ton essai se termine dans 2 jours. Annulable dans Réglages > Abonnements. (à n'envoyer que si programmée à l'achat avec l'accord de l'utilisateur pour les notifications ; sinon afficher la date de fin dans `pay.success` et dans Réglages)

## 3. Ce qui ne s'affiche jamais
Pas de « Autorise pour continuer » ni de compte à rebours, pas de menace de perte de fonction, pas de relance après refus, aucune permission demandée avant le geste qui l'exige, aucune fonction payante conditionnée à l'octroi d'une donnée.
