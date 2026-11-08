"""Tests hors réseau des normaliseurs AK (BLM) et HI (rampes DLNR). Fixture : réponses réelles réduites du 2026-11-07."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import normaliser as nz  # noqa: E402

with open(os.path.join(ICI, "fixtures", "ak_hi.json"), encoding="utf-8") as f:
    FIX = json.load(f)


class TestAlaska(unittest.TestCase):
    def test_rampe_blm(self):
        n = nz.NORMALISEURS["ak_acces_blm"](FIX["ak_launch"][0])
        p = n["properties"]
        self.assertTrue(p["id"].startswith("ak-blm:rampe:"))
        self.assertEqual((p["type"], p["coin"]), ("rampe", "acces"))
        self.assertNotIn("DESCRIPTION", p)
        self.assertNotIn("description", p)

    def test_sortie_et_peche(self):
        t = nz.NORMALISEURS["ak_acces_blm"](FIX["ak_takeout"][0])["properties"]
        self.assertEqual(t["type"], "acces")
        p = nz.NORMALISEURS["ak_acces_blm"](FIX["ak_fishing"][0])["properties"]
        self.assertEqual((p["type"], p["coin"]), ("peche_rive", "peche"))
        self.assertNotIn("(Fishing)", p["nom"])
        self.assertEqual(set(p), {"id", "nom", "type", "coin", "gestionnaire"})  # aucune espèce, aucune note libre


class TestHawaii(unittest.TestCase):
    def test_rampes_non_privees(self):
        sorties = [nz.NORMALISEURS["hi_acces_rampes"](f) for f in FIX["hi_rampes"]]
        gardes = [s for s in sorties if s]
        prives = [f for f in FIX["hi_rampes"] if "Private" in f["properties"]["jurisdiction"]]
        self.assertEqual(len(gardes), len(FIX["hi_rampes"]) - len(prives))
        self.assertTrue(prives)
        for s in gardes:
            self.assertTrue(s["properties"]["id"].startswith("hi-dar:"))
            self.assertEqual(s["properties"]["type"], "rampe")

    def test_autre_installation_refusee(self):
        f = json.loads(json.dumps(FIX["hi_rampes"][0]))
        f["properties"]["facility"] = "Small Boat Harbor"
        self.assertIsNone(nz.NORMALISEURS["hi_acces_rampes"](f))


if __name__ == "__main__":
    unittest.main()
