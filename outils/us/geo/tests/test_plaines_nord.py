"""Tests hors réseau des normaliseurs ND, SD, NE (US15, groupe plaines-nord)."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))

import normaliser  # noqa: E402

with open(os.path.join(ICI, "fixtures", "plaines-nord.json"), encoding="utf-8") as f:
    FIX = json.load(f)

INTERDITS = ("OwnershipPhone", "OwnershipContact", "Directions", "Photo", "Comments", "LocationDescription", "Site_Notes",
             "GoogleMapsHyperlink", "701-000", "texte libre", "exemple.test")


def tous(nom, cle):
    fn = normaliser.NORMALISEURS[nom]
    return [r for r in (fn(dict(type="Feature", **f), {}) for f in FIX[cle]) if r]


class TestPlainesNord(unittest.TestCase):
    def test_nd(self):
        r = tous("acces_nd_gnf", "nd")
        self.assertEqual([x["properties"]["id"] for x in r], ["nd-gnf:9150", "nd-gnf:9096"])
        self.assertEqual(r[0]["properties"]["type"], "rampe")
        self.assertEqual(r[0]["properties"]["nom"], "Jamestown Reservoir – Five Mile Corner Landing")
        self.assertEqual(r[1]["properties"]["type"], "peche_rive")
        self.assertEqual(r[1]["properties"]["coin"], "peche")

    def test_sd(self):
        r = tous("acces_sd_gfp", "sd")
        self.assertEqual(len(r), 1)
        self.assertEqual(r[0]["properties"]["id"], "sd-gfp:0e0ae6fe-f96d-4e42-bea3-ca8a9d44bb9b")
        self.assertEqual(r[0]["properties"]["comte"], "Codington")

    def test_ne(self):
        r = tous("acces_ne_ngpc", "ne")
        self.assertEqual(len(r), 1)
        p = r[0]["properties"]
        self.assertEqual(p["id"], "ne-ngpc:4")
        self.assertEqual(p["nom"], "Sandy Channel – Sandy Channel SRA")
        self.assertEqual(p["places_remorque"], 3)

    def test_aucune_donnee_privee_ni_texte_libre(self):
        for nom, cle in (("acces_nd_gnf", "nd"), ("acces_sd_gfp", "sd"), ("acces_ne_ngpc", "ne")):
            texte = json.dumps(tous(nom, cle), ensure_ascii=False)
            for mot in INTERDITS:
                self.assertNotIn(mot, texte, f"{nom} : {mot}")

    def test_configs(self):
        for u in ("ND", "SD", "NE"):
            with open(os.path.join(os.path.dirname(ICI), "etats", f"{u}.json"), encoding="utf-8") as f:
                cfg = json.load(f)
            self.assertEqual(cfg["etat"], u)
            self.assertTrue(cfg["couches"][0]["normaliseur"] in normaliser.NORMALISEURS)


if __name__ == "__main__":
    unittest.main()
