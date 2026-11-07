"""Tests hors réseau des normaliseurs VA, WV, NC (fixture : quelques objets réels lus le 2026-11-07)."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import normaliser as nz  # noqa: E402

with open(os.path.join(ICI, "fixtures", "se-nord.json"), encoding="utf-8") as f:
    FIX = json.load(f)

INTERDITS = {"LOCATION", "Comments", "Phone", "Street", "comments", "telephone", "directions"}


class TestSENord(unittest.TestCase):
    def normaliser(self, nom, cle):
        n = nz.NORMALISEURS[nom]
        return [n(f) for f in FIX[cle]]

    def test_va_rampe_portage_retires(self):
        r = self.normaliser("acces_va_dwr", "va")
        self.assertEqual(r[0]["properties"]["type"], "rampe")
        self.assertEqual(r[0]["properties"]["coin"], "acces")
        self.assertTrue(r[0]["properties"]["id"].startswith("va-dwr:"))
        self.assertEqual(r[1]["properties"]["type"], "acces_portage")
        self.assertIsNone(r[2])  # On_List = N
        self.assertNotIn("gestionnaire", r[3]["properties"])  # « No File » n'est pas un gestionnaire

    def test_va_ponton(self):
        r = self.normaliser("ponton_va_dwr", "va_pontons")[0]
        self.assertEqual(r["properties"]["type"], "peche_rive")
        self.assertEqual(r["properties"]["coin"], "peche")

    def test_wv_types_et_prive(self):
        r = self.normaliser("acces_wv_dnr", "wv")
        self.assertEqual(r[0]["properties"]["type"], "rampe")
        self.assertEqual(r[1]["properties"]["type"], "acces_portage")
        self.assertEqual(r[2]["properties"]["type"], "peche_rive")
        self.assertEqual(r[2]["properties"]["coin"], "peche")
        self.assertIsNone(r[3])  # propriétaire privé

    def test_nc_ouvert_seulement(self):
        r = self.normaliser("acces_nc_wrc", "nc")
        self.assertEqual(r[0]["properties"]["type"], "rampe")
        self.assertEqual(r[1]["properties"]["type"], "acces_portage")
        self.assertIsNone(r[2])  # fermé temporairement
        self.assertEqual(r[0]["properties"]["nom"], r[0]["properties"]["nom"].title())

    def test_aucun_champ_prive(self):
        for nom, cle in (("acces_va_dwr", "va"), ("ponton_va_dwr", "va_pontons"), ("acces_wv_dnr", "wv"), ("acces_nc_wrc", "nc")):
            for n in self.normaliser(nom, cle):
                if n:
                    self.assertFalse(INTERDITS & set(n["properties"]), n["properties"])


if __name__ == "__main__":
    unittest.main()
