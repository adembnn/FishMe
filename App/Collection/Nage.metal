#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Une onde de la tête à la queue. Les illustrations regardent à droite : la tête est à droite, la queue à gauche.
[[ stitchable ]] float2 ondeNage(float2 position, float temps, float largeur, float amplitude) {
    float t = clamp(position.x / largeur, 0.0, 1.0);
    float queue = 1.0 - t;
    float decalage = amplitude * queue * queue * sin(temps * 3.2 + position.x * 0.045);
    return float2(position.x, position.y + decalage);
}
