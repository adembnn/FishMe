# Planche E, Étiquette de muséum
Idée : le brochet est posé seul sur le blanc, comme un spécimen de tiroir ; une étiquette rectangulaire pend à un fil fin tiré depuis sa nageoire. Rien d'autre sur la « carte ».
Police : Familjen Grotesk (400/600), IBM Plex Mono pour les mesures et le n°. Trois tailles : 28 / 15 / 12 px.
Couleurs : papier #FFFFFF, encre #14181B, gris #596168, filet #C9CED2, accent unique vert #1E7F4F (verdict, réglette, bouton principal).
Audace unique : le fil. Il se dessine du poisson jusqu'au trou de l'étiquette (GSAP, fini à 2,3 s), l'étiquette se pose avec un léger balancement. Réduit = fondu.
Lumière : une bande claire dans le poisson seul (palier 2), suit le pointeur ; état figé déjà placé.
Verso : toucher l'étiquette la retourne (phrase départementale, OFB, 4 sur 11). Info « i » : raisons et signalement.
Références réelles : Fish Rules (verdict en un mot + réglette de taille), TCG Pocket (marque de rareté fixe en bas à gauche : forme, pas couleur), CapWords (le sujet devient un objet détouré), HIG Liquid Glass (verre seulement sur la barre d'actions), étiquettes de collections d'histoire naturelle (n° d'inventaire, trou, ficelle).
Non fait / limites : détourage = illustration de Bloch en remplacement de la photo ; la bande de lumière utilise une 2e copie du PNG masquée (le mask-image sur fichier local est bloqué hors serveur).
SwiftUI : Image(détourage VisionKit) en haut, ombre douce ; fil = Path + .trim(from:0,to:t) animé ; étiquette = VStack dans un Rectangle().stroke(lineWidth:1), trou = Circle().stroke ; retournement = rotation3DEffect(.degrees(180), axis:(0,1,0)) avec deux faces ; lumière = LinearGradient masqué par l'image, décalé par CoreMotion (inclinaison) ; barre = GlassEffectContainer / .glassEffect.
Détecteur impeccable : aucune anti-pattern signalée.
