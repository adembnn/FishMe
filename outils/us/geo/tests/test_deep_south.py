"""US15, groupe deep-south : normaliseurs AL, MS, TN (fixtures réduites de vraies réponses, hors réseau)."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import normaliser as nz  # noqa: E402

with open(os.path.join(ICI, "fixtures", "deep_south.json"), encoding="utf-8") as f:
    FIX = json.load(f)


class TestDeepSouth(unittest.TestCase):
    def test_enregistres(self):
        for nom in ("acces_al_cotier", "acces_ms_rampes", "acces_tn_rampes", "peche_tn_rive"):
            self.assertIn(nom, nz.NORMALISEURS)

    def test_al_garde_les_sites_publics_seulement(self):
        n = nz.NORMALISEURS["acces_al_cotier"]
        a = n(FIX["al"][0])
        self.assertEqual(a["properties"]["id"], "al-acces:1")
        self.assertEqual(a["properties"]["comte"], "Baldwin")
        self.assertNotIn("Address", a["properties"])
        self.assertIsNone(n(FIX["al"][1]))

    def test_ms_rampe_sans_directions(self):
        n = nz.NORMALISEURS["acces_ms_rampes"]
        a = n(FIX["ms"][0])
        self.assertEqual(a["properties"]["type"], "rampe")
        self.assertEqual(a["properties"]["nom"], "HORSESHOE LANDING")
        self.assertNotIn("DIRECTIONS", json.dumps(a))
        self.assertEqual(n(FIX["ms"][1])["properties"]["nom"], "BIG RIVER")  # repli sur le plan d'eau

    def test_tn_exclut_les_proprietaires_prives(self):
        n = nz.NORMALISEURS["acces_tn_rampes"]
        a = n(FIX["tn_rampes"][0])
        self.assertEqual(a["properties"]["id"], "tn-rampe:3")
        self.assertEqual(a["properties"]["rampes"], 2)
        self.assertNotIn("Comments", json.dumps(a))
        self.assertIsNone(n(FIX["tn_rampes"][1]))

    def test_tn_peche_rive(self):
        a = nz.NORMALISEURS["peche_tn_rive"](FIX["tn_peche"][0])
        self.assertEqual(a["properties"]["coin"], "peche")
        self.assertEqual(a["properties"]["type"], "peche_rive")


if __name__ == "__main__":
    unittest.main()
