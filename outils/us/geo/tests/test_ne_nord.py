"""Tests hors réseau des normaliseurs ME, NH, VT (US15, groupe ne-nord). Fixture : un objet réel par type, 2026-11-07."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import normaliser as nz  # noqa: E402

with open(os.path.join(ICI, "fixtures", "ne_nord.json"), encoding="utf-8") as f:
    FIX = json.load(f)

INTERDITS = ("phone", "tel", "email", "contact", "directions", "additional", "mapurl", "comment")


class TestNeNord(unittest.TestCase):
    def normaliser(self, nom, etat):
        out = [nz.NORMALISEURS[nom](f) for f in FIX[etat]]
        self.assertTrue(all(out))
        return [o["properties"] for o in out]

    def test_me_types(self):
        p = self.normaliser("acces_me_bateau", "ME")
        self.assertEqual([x["type"] for x in p], ["rampe", "acces_portage", "acces"])
        self.assertTrue(all(x["id"].startswith("me-bateau:") and x["coin"] == "acces" for x in p))

    def test_nh_types(self):
        p = self.normaliser("acces_nh_fg", "NH")
        self.assertEqual([x["type"] for x in p], ["rampe", "peche_rive", "acces_portage"])
        self.assertEqual(p[1]["coin"], "peche")
        self.assertTrue(all(x["id"].startswith("nh-fg:") for x in p))

    def test_vt_types(self):
        p = self.normaliser("acces_vt_fw", "VT")
        self.assertEqual([x["type"] for x in p], ["peche_rive", "rampe"])
        self.assertTrue(all(x["id"].startswith("vt-fw:") for x in p))

    def test_aucun_champ_prive_ni_libre(self):
        for nom, etat in (("acces_me_bateau", "ME"), ("acces_nh_fg", "NH"), ("acces_vt_fw", "VT")):
            for p in self.normaliser(nom, etat):
                for k, v in p.items():
                    self.assertFalse(any(m in k.lower() for m in INTERDITS), k)
                    self.assertTrue(isinstance(v, (str, int, float)))

    def test_objet_sans_identifiant_ignore(self):
        self.assertIsNone(nz.NORMALISEURS["acces_nh_fg"]({"properties": {"PUBACC_ID": " "}, "geometry": None}))
        self.assertIsNone(nz.NORMALISEURS["acces_me_bateau"]({"properties": {}, "geometry": None}))


if __name__ == "__main__":
    unittest.main()
