# FishMe en mouvement (16 oct. 2026)

Variations d'animations de chargement et de sons, à choisir par Adem avant tout code dans l'app.
Page publiée : https://claude.ai/artifact/7n5bnagqXqoKZemwvbT7Z3 (même contenu que `fishme-en-mouvement.html`).

- Lancement (3) : Le bond, Ronds dans l'eau, Marée. Départ exact de l'écran fixe P44 B (lune ronde, halo, « FishMe » sur #0D4A85).
- Arrivée d'une carte (3, chacune en 4 raretés) : La remontée, Le dos de la carte, Bulle. Carte d'après P24 A et P43 C.
- Petites attentes (4) : Bouchon, Poisson qui tourne, Bulles, Moulinet.
- Carte qui charge (3) : Sonar, La rivière se dessine, Squelette d'eau.
- Reconnaissance (1) : Lecture de la photo.
- Sons : 33 sons synthétisés en Web Audio (13 moments, 2 ou 3 variations), aucun son repris d'un jeu. Export WAV possible par `FMSons.versWav(await FMSons.rendre(id))`, puis `afconvert -f caff -d LEI16`.

Chaque variation dit comment la faire en SwiftUI (champ `swiftui`). Rien n'est branché dans l'app tant qu'Adem n'a pas choisi.
Rebâtir la page : `sources/assembler.sh` (concatène coque + assets + sons + animations + page.js).
