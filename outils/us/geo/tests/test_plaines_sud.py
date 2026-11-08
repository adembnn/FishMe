"""Tests hors réseau des normaliseurs KS, OK, AR (groupe plaines-sud, US15)."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, ".."))
import normaliser  # noqa: E402

with open(os.path.join(ICI, "fixtures", "plaines_sud.json"), encoding="utf-8") as _f:
    FIX = json.load(_f)
N = normaliser.NORMALISEURS


class TestPlainesSud(unittest.TestCase):
    def test_ks_riviere_sans_note(self):
        r = N["ks_acces_riviere"](FIX["ks_riviere"])
        self.assertEqual(r["properties"]["id"], "ks-river:1")
        self.assertEqual(r["properties"]["eau"], "Missouri River")
        self.assertNotIn("Notes", json.dumps(r))
        self.assertNotIn("libre", json.dumps(r))

    def test_ks_lac(self):
        p = N["ks_acces_plans_eau"](FIX["ks_lac"])["properties"]
        self.assertEqual((p["id"], p["nom"], p["classe"]), ("ks-lac:1", "Keller Lake", "CFAP"))
        self.assertNotIn("copier", json.dumps(p))

    def test_ks_parcelle_devient_un_point(self):
        r = N["ks_acces_pecheurs_a_pied"](FIX["ks_parcelle"])
        self.assertEqual(r["geometry"]["type"], "Point")
        x, y = r["geometry"]["coordinates"]
        self.assertAlmostEqual(x, -94.79, places=4)
        self.assertAlmostEqual(y, 37.01, places=4)
        self.assertEqual(r["properties"]["nom"], "Walk-in fishing access, Cherokee County")

    def test_ok_types_retenus(self):
        rampe = N["ok_acces_owrb"](FIX["ok_rampe"])["properties"]
        self.assertEqual((rampe["type"], rampe["nom"]), ("rampe", "Eufaula Lake, boat ramp"))
        self.assertEqual(N["ok_acces_owrb"](FIX["ok_ponton"])["properties"]["type"], "peche_rive")
        self.assertIsNone(N["ok_acces_owrb"](FIX["ok_marina"]))

    def test_ar_types_et_commentaires(self):
        b = N["ar_bateau_agfc"](FIX["ar_bateau"])["properties"]
        self.assertEqual(b["type"], "rampe")
        self.assertEqual(b["id"], "ar-boat:c08e1e67-3733-4fb4-8d7d-d8b2ebb26581")
        self.assertNotIn("copier", json.dumps(b))
        self.assertEqual(N["ar_bateau_agfc"](FIX["ar_kayak"])["properties"]["type"], "acces_portage")
        self.assertEqual(N["ar_peche_agfc"](FIX["ar_ponton"])["properties"]["type"], "peche_rive")

    def test_prefixes_uniques(self):
        ids = {N[k](FIX[c])["properties"]["id"].split(":")[0] for k, c in [
            ("ks_acces_riviere", "ks_riviere"), ("ks_acces_plans_eau", "ks_lac"), ("ks_acces_pecheurs_a_pied", "ks_parcelle"),
            ("ok_acces_owrb", "ok_rampe"), ("ar_bateau_agfc", "ar_bateau"), ("ar_peche_agfc", "ar_ponton")]}
        self.assertEqual(len(ids), 6)


if __name__ == "__main__":
    unittest.main()
