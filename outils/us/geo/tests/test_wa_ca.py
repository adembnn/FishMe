"""Tests hors réseau des normaliseurs de Washington et de Californie (fixture réduite)."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, ".."))
import normaliser  # noqa: E402

with open(os.path.join(ICI, "fixtures", "wa_ca.json"), encoding="utf-8") as f:
    FIX = json.load(f)

INTERDITS = ("Phone", "EMail", "Notes", "Comments", "à ne pas copier", "555-0100", "example.org")


class TestWA(unittest.TestCase):
    def test_wdfw(self):
        fn = normaliser.NORMALISEURS["acces_wa_wdfw"]
        a, b, c = (fn(x) for x in FIX["wa_wdfw"])
        self.assertEqual(a["properties"]["id"], "wa-wdfw:101")
        self.assertEqual(a["properties"]["type"], "rampe")
        self.assertEqual(a["properties"]["coin"], "acces")
        self.assertEqual(b["properties"]["type"], "peche_rive")
        self.assertEqual(b["properties"]["coin"], "peche")
        self.assertEqual(b["properties"]["fermeture"], "Seasonal Limited Access")
        self.assertIsNone(c)
        self.assertNotIn("rampes", b["properties"])
        for n in (a, b):
            texte = json.dumps(n, ensure_ascii=False)
            for mot in INTERDITS:
                self.assertNotIn(mot, texte)

    def test_parcs(self):
        fn = normaliser.NORMALISEURS["acces_wa_parcs"]
        res = [fn(x) for x in FIX["wa_parcs"]]
        self.assertEqual(res[0]["properties"]["id"], "wa-parc:5")
        self.assertEqual(res[0]["properties"]["nom"], "Battle Ground Lake")
        self.assertIsNone(res[1])  # masqué par l'agence
        self.assertIsNone(res[2])  # non officiel

    def test_usbr(self):
        fn = normaliser.NORMALISEURS["acces_wa_usbr"]
        a, b = (fn(x) for x in FIX["usbr"])
        self.assertEqual(a["properties"]["type"], "rampe")
        self.assertEqual(a["properties"]["eau"], "Columbia Basin")
        self.assertEqual(b["properties"]["type"], "acces_portage")


class TestCA(unittest.TestCase):
    def test_cdfw(self):
        fn = normaliser.NORMALISEURS["acces_ca_cdfw"]
        a, b, c = (fn(x) for x in FIX["ca_cdfw"])
        self.assertEqual(a["properties"]["id"], "ca-cdfw:2")
        self.assertEqual(a["properties"]["voies"], 2)
        self.assertEqual(a["properties"]["eau"], "Lakes Earl & Talawa")
        self.assertIsNone(b)  # propriétaire privé exclu
        self.assertNotIn("voies", c["properties"])  # chaîne vide : pas de nombre inventé
        texte = json.dumps(a, ensure_ascii=False)
        for mot in INTERDITS:
            self.assertNotIn(mot, texte)

    def test_usbr(self):
        fn = normaliser.NORMALISEURS["acces_ca_usbr"]
        a, b = (fn(x) for x in FIX["usbr"])
        self.assertEqual(a["properties"]["id"], "usbr:abc-1")
        self.assertEqual(b["properties"]["type"], "acces_portage")


if __name__ == "__main__":
    unittest.main()
