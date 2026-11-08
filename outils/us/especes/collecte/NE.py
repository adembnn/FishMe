"""NE : Nebraska Game and Parks Commission. PARTIEL.

Les pages de liste d'especes de l'agence (outdoornebraska.gov, magazine.outdoornebraska.gov) repondent 403 (anti-bot) :
jamais contournees. Seule source officielle lisible : l'article de l'agence « Know your fish before you head to lake »
(Nebraskaland Magazine, 31 aout 2020), qui nomme les especes de peche courantes. On n'en tire que des noms (faits).
Liste noms -> entrees : verifiee a la main sur l'article ; test = presence de chaque nom dans la fixture de l'article.

Usage : python3 -I NE.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _commun import DATE, ecrire, entree  # noqa: E402

URL = "https://digital.outdoornebraska.gov/nebraskaland-magazine/know-your-fish-before-you-head-to-lake"
SOURCES = [{"nom": "Nebraska Game and Parks, article « Know your fish before you head to lake » (Nebraskaland Magazine, 2020)",
            "url": URL, "licence": "non précisée", "date": DATE}]
# Noms cites par l'article (sunfish, panfish, catfish, trout, walleye, bass, carp, drum)
NOMS = ["Bluegill", "Green sunfish", "Redear sunfish", "Black crappie", "White crappie", "Rock bass", "Yellow perch",
        "Black bullhead", "Yellow bullhead", "Brown bullhead", "Channel catfish", "Blue catfish", "Flathead catfish",
        "Rainbow trout", "Brook trout", "Brown trout", "Cutthroat trout", "Walleye", "Largemouth bass",
        "Smallmouth bass", "Common carp", "Freshwater drum"]


def main():
    z = {"type": "etat", "id": "NE", "nom": "Nebraska"}
    entrees = [e for e in (entree(n, z, "liste_agence", 0) for n in NOMS) if e]
    p, t = ecrire("NE", "agence", SOURCES, entrees)
    print(p, t, "octets ; entrees etat:", len(entrees), "sur", len(NOMS))


if __name__ == "__main__":
    main()
