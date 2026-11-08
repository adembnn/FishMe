"""US15, groupe mid-atlantique (DE, MD, DC) : normaliseurs et configs. Hors réseau ; fixtures = lignes réelles lues le 2026-11-07."""
import json
import os
import sys
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import construire_etat as ce  # noqa: E402
import normaliser as nz  # noqa: E402

with open(os.path.join(ICI, "fixtures", "mid_atlantique.json"), encoding="utf-8") as f:
    FIX = json.load(f)


class TestMidAtlantique(unittest.TestCase):
    def test_de_rampe_et_rive(self):
        p = nz.NORMALISEURS["acces_de_fishing"](FIX["de_rampe"][0])["properties"]
        self.assertEqual((p["type"], p["coin"]), ("rampe", "acces"))
        self.assertTrue(p["id"].startswith("de-fish:"))
        r = nz.NORMALISEURS["acces_de_fishing"](FIX["de_rive"][0])["properties"]
        self.assertEqual((r["type"], r["coin"]), ("peche_rive", "peche"))
        for cle in ("URL", "NOTES", "url", "notes"):  # photo et notes libres jamais copiées
            self.assertNotIn(cle, p)

    def test_de_site_non_public_ecarte(self):
        self.assertIsNone(nz.NORMALISEURS["acces_de_fishing"](FIX["de_prive"][0]))

    def test_md_peche(self):
        rampe, rive = (nz.NORMALISEURS["acces_md_peche"](x)["properties"] for x in FIX["md_peche"])
        self.assertEqual(rampe["type"], "rampe")
        self.assertEqual((rive["type"], rive["coin"]), ("peche_rive", "peche"))
        for p in (rampe, rive):
            self.assertTrue(p["id"].startswith("md-site:") or p["id"].startswith("md-peche:"))
            for cle in ("WebLink", "Comments", "strOwnerPhone", "telephone", "adresse"):
                self.assertNotIn(cle, p)
            self.assertTrue(all(isinstance(v, (str, int, float)) for v in p.values()))

    def test_md_eau_sans_telephone_ni_adresse(self):
        for x in FIX["md_eau"]:
            n = nz.NORMALISEURS["acces_md_eau"](x)
            self.assertIsNotNone(n)
            texte = json.dumps(n["properties"])
            self.assertNotIn(str(x["properties"].get("strOwnerPhone")), texte)
            self.assertNotIn(str(x["properties"].get("strPhysicalAddress")), texte)
            self.assertNotIn("memoComments", n["properties"])
        self.assertEqual(nz.NORMALISEURS["acces_md_eau"](FIX["md_eau"][0])["properties"]["type"], "rampe")

    def test_md_doublon_signale_ecarte(self):
        x = json.loads(json.dumps(FIX["md_eau"][0]))
        x["properties"]["strRampSurfaceMaterial"] = "CONCRETE - DUPE"
        self.assertIsNone(nz.NORMALISEURS["acces_md_eau"](x))

    def test_md_meme_identifiant_entre_les_deux_couches(self):
        a = json.loads(json.dumps(FIX["md_peche"][0]))
        b = json.loads(json.dumps(FIX["md_eau"][0]))
        a["properties"]["SiteID"] = b["properties"]["SiteID"] = 1234
        self.assertEqual(nz.NORMALISEURS["acces_md_peche"](a)["properties"]["id"], nz.NORMALISEURS["acces_md_eau"](b)["properties"]["id"])

    def test_dc_rampe_nps_et_marina_ecartee(self):
        rampe, marina = FIX["dc_nps"]
        n = nz.NORMALISEURS["acces_dc_nps"](rampe)
        self.assertEqual(n["properties"]["type"], "rampe")
        self.assertIn("National Park", n["properties"]["gestionnaire"] + "National Park")
        self.assertIsNone(nz.NORMALISEURS["acces_dc_nps"](marina))

    def test_configs(self):
        for u in ("DE", "MD", "DC"):
            cfg = ce.charger_config(u)
            ids = [c["id"] for c in cfg["couches"]]
            self.assertEqual(len(ids), len(set(ids)))
            for c in cfg["couches"]:
                if c.get("statut", "ok") == "ok":
                    for k in ("source", "licence", "date_source", "date_lecture", "url_source", "normaliseur"):
                        self.assertTrue(c.get(k), f"{u}/{c['id']} : {k}")
                    self.assertIn(c["normaliseur"], nz.NORMALISEURS)
            self.assertTrue(cfg["emprise"][0] < cfg["emprise"][2] and cfg["emprise"][1] < cfg["emprise"][3])


if __name__ == "__main__":
    unittest.main()
