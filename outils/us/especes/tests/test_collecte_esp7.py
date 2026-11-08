"""Tests des collectes du groupe esp-7 (ND, SD, NE, KS, OK) sur petites fixtures, sans reseau."""
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, "..", "collecte"))
sys.path.insert(0, os.path.join(ICI, ".."))

import _commun  # noqa: E402
import ND  # noqa: E402
import NAS  # noqa: E402
import OK  # noqa: E402
import SD  # noqa: E402
import verifier_zones  # noqa: E402


class TestCollecteEsp7(unittest.TestCase):
    def test_nd_liste_etat(self):
        page = "<h2>SUNFISH</h2>\nBluegill (Native)<br>\nLargemouth Bass (Nonnative)\nBack to Top"
        self.assertEqual(ND.parser_liste_etat(page), ["Bluegill", "Largemouth Bass"])

    def test_nd_lac(self):
        page = ('<span id="ctl00_lblLakeName" class="Name">Devils Lake</span>'
                '<span id="ctl00_lblFishSpecies">Northern Pike, Walleye, Yellow Perch</span>')
        self.assertEqual(ND.parser_lac(page), ("Devils Lake", ["Northern Pike", "Walleye", "Yellow Perch"]))

    def test_nd_codes_sans_coordonnees(self):
        page = 'Name:  "Devils Lake", LocationName: "x", LakeCode: "275" , ManagedBy: "y"'
        self.assertEqual(ND.codes_lacs(page), {"275": "Devils Lake"})

    def test_ok_lac(self):
        page = ("<a>Home</a><a>Fishing</a><a>Where To Fish</a><h1>Broken Bow Lake</h1>"
                "<h3>Fish Species of Interest</h3><li>Largemouth Bass</li><li>Walleye</li><h3>Upload Your Catch</h3>"
                "<p>Colton C</p>")
        nom, esp = OK.parser_lac(page)
        self.assertEqual(nom, "Broken Bow Lake")
        self.assertEqual(esp, ["Largemouth Bass", "Walleye"])  # aucun nom de pecheur

    def test_sd_tableau(self):
        texte = "Native SD Status\nWalleye Sander vitreus Yes\nCommon Carp Cyprinus carpio No EX, AIS\nSPECIES\n"
        self.assertEqual(SD.parser_tableau(texte), [("Walleye", "Sander vitreus", "Yes"), ("Common Carp", "Cyprinus carpio", "No")])

    def test_resoudre(self):
        self.assertEqual(_commun.resoudre("Bluegill Sunfish")[0], "bluegill")
        self.assertEqual(_commun.resoudre("Zander")[1], "Sander lucioperca")
        self.assertIsNone(_commun.resoudre("Fathead Minnow")[1])

    def test_nas_agregation_sans_coordonnees(self):
        res = [{"scientificName": "Cyprinus carpio", "commonName": "Common Carp", "year": 1990, "huc8": "10160001",
                "freshMarineIntro": "Freshwater", "decimalLatitude": 1.0, "decimalLongitude": 2.0},
               {"scientificName": "Cyprinus carpio", "commonName": "Common Carp", "year": 2001, "huc8": "10160001",
                "freshMarineIntro": "Freshwater"}]
        sources, entrees = NAS.construire("SD", res)
        self.assertEqual(len(entrees), 2)  # Etat + HUC8
        self.assertEqual([e["n"] for e in entrees], [2, 2])
        self.assertEqual(entrees[0]["annee_max"], 2001)
        self.assertFalse(any("decimalLatitude" in e or "lat" in e for e in entrees))
        d = {"format": "fishme-especes-us/1", "etat": "SD", "producteur": "nas", "date": "2026-11-08",
             "sources": sources, "entrees": entrees}
        self.assertEqual(verifier_zones.verifier_fichier("SD-nas.json", d), [])


if __name__ == "__main__":
    unittest.main()
