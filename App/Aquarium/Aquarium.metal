#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Fonctions de l'aquarium (lot L14), toutes préfixées aquarium_ : une seule bibliothèque Metal pour toute l'app.

// Ondulation du corps de la tête à la queue. Les illustrations regardent à droite : la tête est à droite (x grand), la queue à gauche.
// La queue bat le plus, la tête presque pas.
[[ stitchable ]] float2 aquarium_ondeNage(float2 position, float temps, float largeur, float amplitude, float vitesse) {
    float t = clamp(position.x / max(largeur, 1.0), 0.0, 1.0);
    float queue = 1.0 - t;
    float decalage = amplitude * queue * queue * sin(temps * vitesse + position.x * 0.05);
    return float2(position.x, position.y + decalage);
}

// Reflet irisé sur les écailles d'un poisson légendaire : une bande de lumière qui glisse et des couleurs qui tournent.
// `couleur` est prémultipliée par l'alpha : le reflet ne sort jamais de la silhouette.
[[ stitchable ]] half4 aquarium_irise(float2 position, half4 couleur, float temps, float2 taille) {
    if (couleur.a < 0.01h) {
        return couleur;
    }
    float2 uv = position / max(taille, float2(1.0));
    float teinte = uv.x * 1.3 + uv.y * 0.7 - temps * 0.18;
    float3 arcEnCiel = 0.5 + 0.5 * cos(6.28318 * (teinte + float3(0.0, 0.33, 0.67)));
    float distanceBande = abs(fract(uv.x * 0.8 - temps * 0.12) - 0.5);
    float bande = 1.0 - smoothstep(0.0, 0.18, distanceBande);
    float force = 0.26 + 0.34 * bande;
    half3 reflet = half3(arcEnCiel) * couleur.a * half(force);
    half3 rgb = min(couleur.rgb + reflet, half3(couleur.a));
    return half4(rgb, couleur.a);
}
