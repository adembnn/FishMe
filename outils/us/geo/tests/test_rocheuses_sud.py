"""US15, groupe rocheuses-sud (CO, UT, NM) : normaliseurs d'accès publics, hors réseau."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, ".."))
import normaliser  # noqa: E402

with open(os.path.join(ICI, "fixtures", "rocheuses_sud.json"), encoding="utf-8") as _f:
    FX = json.load(_f)
N = normaliser.NORMALISEURS


class TestCO(unittest.TestCase):
    def test_cpw_rampe_et_peche_seulement(self):
        r = N["co_cpw_installation"](FX["co_cpw_rampe"])
        self.assertEqual((r["properties"]["id"], r["properties"]["type"], r["properties"]["nom"]),
                         ("co-cpw-fac:11", "rampe", "Pueblo Reservoir SWA"))
        self.assertIsNone(N["co_cpw_installation"](FX["co_cpw_parking"]))
        p = N["co_cpw_installation"](FX["co_cpw_peche"])["properties"]
        self.assertEqual((p["type"], p["coin"], p["nom"]), ("peche_rive", "peche", "Quai ADA"))

    def test_riviere_blm_usbr(self):
        self.assertEqual(N["co_cpw_acces_riviere"](FX["co_riviere"])["properties"]["nom"], "Harmon SWA")
        self.assertEqual(N["co_blm_rampe"](FX["co_blm"])["properties"]["id"], "co-blm-ramp:L60675")
        self.assertEqual(N["co_blm_peche"](FX["co_blm"])["properties"]["type"], "peche_rive")
        self.assertEqual(N["co_usbr_rampe"](FX["usbr"])["properties"]["id"], "co-usbr-ramp:df1655a1")

    def test_rien_de_prive_copie(self):
        for cle, fn in (("co_cpw_rampe", "co_cpw_installation"), ("co_blm", "co_blm_rampe")):
            texte = json.dumps(N[fn](FX[cle]), ensure_ascii=False)
            for mot in ("ne pas copier", "rue privée"):
                self.assertNotIn(mot, texte)


class TestUT(unittest.TestCase):
    def test_pecheries_communautaires(self):
        r = N["ut_dwr_pecheries_communautaires"](FX["ut_comm"])
        self.assertEqual(r["properties"]["id"], "ut-dwr-comm:1")
        texte = json.dumps(r, ensure_ascii=False)
        self.assertNotIn("801-476", texte)
        self.assertNotIn("ne pas copier", texte)

    def test_usbr(self):
        self.assertEqual(N["ut_usbr_rampe"](FX["usbr"])["properties"]["type"], "rampe")


class TestNM(unittest.TestCase):
    def test_types_acces(self):
        self.assertEqual(N["nm_acces_peche"](FX["nm_wade"])["properties"]["type"], "peche_rive")
        self.assertEqual(N["nm_acces_peche"](FX["nm_rampe_pec"])["properties"]["type"], "rampe")
        self.assertEqual(N["nm_acces_peche"](FX["nm_rampe_pec"])["properties"]["nom"], "Lake Carlsbad")

    def test_pas_de_restrictions_copiees(self):
        texte = json.dumps(N["nm_acces_peche"](FX["nm_wade"]), ensure_ascii=False)
        self.assertNotIn("ne pas copier", texte)
        texte = json.dumps(N["nm_rampe"](FX["nm_rampe"]), ensure_ascii=False)
        self.assertNotIn("ne pas copier", texte)
        self.assertNotIn("https://x", texte)

    def test_usbr(self):
        self.assertEqual(N["nm_usbr_rampe"](FX["usbr"])["properties"]["id"], "nm-usbr-ramp:df1655a1")


if __name__ == "__main__":
    unittest.main()
