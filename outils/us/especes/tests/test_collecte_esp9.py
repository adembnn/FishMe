"""Tests hors réseau de la collecte esp-9 (WY, UT, NAS) : fixtures minuscules."""
import os, sys, unittest
ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, "..", "collecte"))
sys.path.insert(0, os.path.join(ICI, ".."))
import commun_esp9 as C
import UT, WY
import NAS_esp9 as NAS
import verifier_zones as vz

WY_HTML = """<table><tr><th>x</th></tr></table><div>Scientific Name</div>
<div>Burbot</div><div>Game</div><div>Lota lota</div>
<div>Fathead minnow</div><div>Nongame</div><div>Pimephales promelas</div>
<div>Largemouth bass</div><div>Game</div><div>Micropterus nigricans</div>"""

UT_RECORDS = "<p>Species Date Weight BASS, Largemouth 1974 10 lbs. TROUT, Lake 2008 32 lbs. CHUB, Utah* 2005 1 lb. WALLEYE 2024 13 lbs.</p>"
UT_AJAX = ('<td class="watername" onclick="x">ADAMS RESERVOIR</td> <td class="county">DAVIS</td> <td class="species">RAINBOW</td>'
           '<td class="watername">ADAMS RESERVOIR</td> <td class="county">DAVIS</td> <td class="species">RAINBOW</td>'
           '<td class="watername">AMBER\'S MUDDY HOLE</td> <td class="county">SANPETE</td> <td class="species">BROOK TROUT</td>')


class T(unittest.TestCase):
    def test_wy_etat_game_seulement(self):
        self.assertEqual([r[0] for r in WY.especes_etat(WY_HTML)], ["Burbot", "Largemouth bass"])

    def test_latin_corrige_wy(self):
        self.assertEqual(C.trouver("Largemouth bass")[2], "Micropterus salmoides")

    def test_ut_records(self):
        noms = [UT.nom_record(n) for n in UT.especes_records(UT_RECORDS)]
        self.assertIn("largemouth bass", noms)
        self.assertIn("lake trout", noms)
        self.assertIn("walleye", noms)

    def test_ut_agregation(self):
        l = UT.lignes_empoissonnement(UT_AJAX, 2026)
        e = C.agreger_empoissonnement(l, C.trouver, "UT", 1)
        par = {x["zone"]["nom"]: x for x in e}
        self.assertEqual(par["Adams Reservoir"]["n"], 2)
        self.assertEqual(par["Amber's Muddy Hole"]["slug"], "brook-trout")
        self.assertEqual(par["Adams Reservoir"]["annee_max"], 2026)

    def test_nas_sans_coordonnees(self):
        r = [{"scientificName": "Esox lucius", "commonName": "Northern Pike", "huc8": "14040106", "huc8Name": "Upper Green", "year": 1990,
              "freshMarineIntro": "Freshwater", "decimalLatitude": 41.0, "decimalLongitude": -109.0}]
        huc, etat = NAS.agreger(r, NAS.especes_us())
        e = C.entree(*[(a[0]) for a in huc.values()], "huc8", "14040106", "Upper Green", "nas", 0, n=1)
        self.assertNotIn("decimalLatitude", e)
        self.assertEqual(list(etat)[0], "Esox lucius")

    def test_sortie_valide(self):
        src = [{"nom": "x", "url": "https://wildlife.utah.gov/fishing/records", "licence": "non précisée", "date": C.DATE}]
        d = {"format": "fishme-especes-us/1", "etat": "UT", "producteur": "agence", "date": C.DATE, "sources": src,
             "entrees": [C.entree(C.trouver("walleye"), "etat", "UT", "Utah", "liste_agence", 0)]}
        self.assertEqual(vz.verifier_fichier("UT-agence.json", d), [])


if __name__ == "__main__":
    unittest.main()
