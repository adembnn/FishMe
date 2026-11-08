"""US15, groupe golfe (LA, TX) : normaliseurs, hors réseau. Fixtures = objets réels réduits (lus le 2026-11-07)."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import normaliser as nz  # noqa: E402

with open(os.path.join(ICI, "fixtures", "golfe.json"), encoding="utf-8") as f:
    FIX = json.load(f)


class TestGolfe(unittest.TestCase):
    def test_normaliseurs_enregistres(self):
        for n in ("acces_la_ldwf", "peche_rive_la_ldwf", "acces_tx_rampes", "acces_tx_raca"):
            self.assertIn(n, nz.NORMALISEURS)

    def test_la_garde_le_public_seulement(self):
        fn = nz.NORMALISEURS["acces_la_ldwf"]
        sortie = [fn(f) for f in FIX["la_acces"]]
        gardes = [s for s in sortie if s]
        self.assertEqual([s["properties"]["nom"] for s in gardes], ["Port of Iberia Ramp", "4th Street Boat Launch"])
        self.assertEqual(gardes[0]["properties"]["id"], "la-ldwf:2")

    def test_la_aucune_coordonnee_de_contact(self):
        fn = nz.NORMALISEURS["acces_la_ldwf"]
        p = fn(FIX["la_acces"][1])["properties"]
        for k in ("Phone", "Email", "Website", "Hours", "phone", "email", "tel"):
            self.assertNotIn(k, p)
        self.assertNotIn("364-1065", json.dumps(p))

    def test_la_rive_et_communautaire(self):
        fn = nz.NORMALISEURS["peche_rive_la_ldwf"]
        a = fn(FIX["la_rive"][0])["properties"]
        b = fn(FIX["la_comm"][0])["properties"]
        self.assertEqual((a["id"], a["type"], a["coin"]), ("la-bank:1", "peche_rive", "peche"))
        self.assertEqual(b["id"], "la-comm:1")
        self.assertNotIn("Address", b)

    def test_tx_rampes(self):
        p = nz.NORMALISEURS["acces_tx_rampes"](FIX["tx_rampes"][0])["properties"]
        self.assertEqual((p["id"], p["type"], p["eau"]), ("tx-ramp:anderson001", "rampe", "Trinity River"))

    def test_tx_raca_baux_en_cours_seulement(self):
        fn = nz.NORMALISEURS["acces_tx_raca"]
        sortie = [fn(f) for f in FIX["tx_raca"]]
        self.assertEqual([bool(s) for s in sortie], [True, False])
        p = sortie[0]["properties"]
        self.assertNotIn("Description", p)
        self.assertNotIn("Directions", p)
        self.assertNotIn("262-0925", json.dumps(p))


if __name__ == "__main__":
    unittest.main()
