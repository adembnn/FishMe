"""Tests hors réseau des normaliseurs MA, RI, CT (fixture : quelques objets réels lus le 2026-11-07, champs libres retirés)."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import normaliser as nz  # noqa: E402
import verifier_geo as vg  # noqa: E402

with open(os.path.join(ICI, "fixtures", "nesud.json"), encoding="utf-8") as f:
    FIX = json.load(f)


class TestNordEstSud(unittest.TestCase):
    def test_enregistres(self):
        for nom in ("acces_ma_ofba", "acces_ri_dem", "acces_ct_deep"):
            self.assertIn(nom, nz.NORMALISEURS)

    def test_ma_types(self):
        t = [nz.NORMALISEURS["acces_ma_ofba"](f)["properties"] for f in FIX["ma"]]
        self.assertEqual([p["type"] for p in t], ["rampe", "acces_portage", "peche_rive", "peche_rive"])
        self.assertEqual([p["coin"] for p in t], ["acces", "acces", "peche", "peche"])
        self.assertTrue(all(p["id"].startswith("ma-ofba:") for p in t))
        for p in t:
            self.assertNotIn("COMMENTS", p)
            self.assertNotIn("GOOGLE_MAP", p)

    def test_ri_types(self):
        t = [nz.NORMALISEURS["acces_ri_dem"](f)["properties"] for f in FIX["ri"]]
        self.assertEqual([p["type"] for p in t], ["rampe", "acces_portage", "peche_rive"])
        self.assertTrue(all(p["id"].startswith("ri-dem:") for p in t))
        self.assertEqual(t[0]["milieu"], "salee")

    def test_ct_types_et_lien(self):
        t = [nz.NORMALISEURS["acces_ct_deep"](f)["properties"] for f in FIX["ct"]]
        self.assertEqual([p["type"] for p in t], ["rampe", "acces_portage"])
        self.assertTrue(all(p["id"].startswith("ct-deep:") for p in t))
        self.assertTrue(all(p["lien"].startswith("http") for p in t if "lien" in p))

    def test_sans_donnee_personnelle(self):
        for nom, cle in (("acces_ma_ofba", "ma"), ("acces_ri_dem", "ri"), ("acces_ct_deep", "ct")):
            for f in FIX[cle]:
                p = nz.NORMALISEURS[nom](f)["properties"]
                self.assertFalse(any(vg.RE_TEL.search(str(v)) for v in p.values()), p)

    def test_objet_sans_identifiant_ignore(self):
        self.assertIsNone(nz.NORMALISEURS["acces_ma_ofba"]({"properties": {"FACNAME": "x"}, "geometry": None}))
        self.assertIsNone(nz.NORMALISEURS["acces_ri_dem"]({"properties": {"NAME": "x"}, "geometry": None}))
        self.assertIsNone(nz.NORMALISEURS["acces_ct_deep"]({"properties": {"LAUNCHNAME": "x"}, "geometry": None}))


if __name__ == "__main__":
    unittest.main()
