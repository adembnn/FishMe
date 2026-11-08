"""Normaliseurs SC, GA, FL (groupe se-sud) : tri des objets et confidentialité. Hors réseau."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import normaliser as nz  # noqa: E402

with open(os.path.join(ICI, "fixtures", "se-sud.json"), encoding="utf-8") as f:
    FIX = json.load(f)

INTERDITS = {"Directions", "Comments", "SpeciesList", "Phone", "ContactPhone", "OperationalComments", "URL", "telephone", "directions"}


def tout(nom, cle):
    n = nz.NORMALISEURS[nom]
    return [r for r in (n(f, {}) for f in FIX[cle]) if r]


class TestSeSud(unittest.TestCase):
    def test_sc(self):
        r = tout("acces_sc_dnr", "sc")
        self.assertEqual([x["properties"]["id"] for x in r], ["sc-dnr:BR235", "sc-dnr:PI001"])  # eau salée et fermé écartés
        self.assertEqual(r[0]["properties"]["type"], "rampe")
        self.assertEqual((r[1]["properties"]["type"], r[1]["properties"]["coin"]), ("peche_rive", "peche"))
        self.assertEqual(r[0]["properties"]["gestionnaire"], "City of North Augusta")

    def test_ga(self):
        r = tout("acces_ga_wrd", "ga")
        self.assertEqual([x["properties"]["id"] for x in r], ["ga-wrd:4", "ga-wrd:50"])  # côtier et fermé écartés
        self.assertEqual(r[0]["properties"]["type"], "rampe")
        self.assertEqual(r[1]["properties"]["type"], "peche_rive")

    def test_fl(self):
        r = tout("acces_fl_fwc", "fl")
        self.assertEqual([x["properties"]["id"] for x in r], ["fl-fwc:AL00001AA", "fl-fwc:OR00002"])
        self.assertEqual(r[0]["properties"]["type"], "acces_portage")
        self.assertEqual(r[0]["properties"]["comte"], "Alachua")
        self.assertEqual(r[1]["properties"]["voies"], 2)

    def test_aucun_champ_prive(self):
        for nom, cle in (("acces_sc_dnr", "sc"), ("acces_ga_wrd", "ga"), ("acces_fl_fwc", "fl")):
            for x in tout(nom, cle):
                self.assertFalse(INTERDITS & set(x["properties"]), nom)
                for v in x["properties"].values():
                    self.assertNotIn("example.org", str(v))
                    self.assertNotIn("maps.google", str(v))


if __name__ == "__main__":
    unittest.main()
