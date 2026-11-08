"""US16 esp-10 : USGS NAS (poissons non indigènes) pour AZ CA OR WA AK HI. Usage : python3 -I NAS.py [USPS ...]"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun

ETATS = {"AZ": "Arizona", "CA": "California", "OR": "Oregon", "WA": "Washington", "AK": "Alaska", "HI": "Hawaii"}

if __name__ == "__main__":
    for u in (sys.argv[1:] or ETATS):
        a = commun.nas_fishes(u)
        if a is None:
            print(u, "NAS inaccessible")
            continue
        print(u, commun.fichier_nas(u, a, ETATS[u]))
