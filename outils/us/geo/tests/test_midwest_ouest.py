import json, os, sys, unittest
ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, ".."))
import normaliser  # noqa: E402

FIX = json.load(open(os.path.join(ICI, "fixtures", "midwest-ouest.json"), encoding="utf-8"))
N = normaliser.NORMALISEURS


class TestMidwestOuest(unittest.TestCase):
    def test_iowa(self):
        r = [N["acces_ia_dnr"]({"type": "Feature", **f}) for f in FIX["ia"]]
        self.assertEqual([x["properties"]["id"] if x else None for x in r], ["ia-dnr:11", "ia-dnr:12", None, "ia-dnr:14"])
        self.assertEqual(r[0]["properties"]["nom"], "Boat Ramp, Linn County")  # nom générique complété par le comté
        self.assertEqual(r[0]["properties"]["type"], "rampe")
        self.assertEqual(r[3]["properties"]["coin"], "peche")

    def test_missouri(self):
        r = N["acces_mo_rampe"]({"type": "Feature", **FIX["mo"][0]})
        self.assertEqual(r["properties"], {"id": "mo-ramp:1", "nom": "Shelvin Rock Access", "type": "rampe", "coin": "acces"})
        self.assertNotIn("nom", N["acces_mo_quai"]({"type": "Feature", **FIX["mo"][1]})["properties"])  # nom vide : absent
        self.assertEqual(N["acces_mo_jetee"]({"type": "Feature", **FIX["mo"][0]})["properties"]["coin"], "peche")

    def test_kentucky_sans_champs_libres(self):
        r = N["acces_ky_bateau"]({"type": "Feature", **FIX["ky"][0]})
        self.assertEqual(r["properties"]["id"], "ky-boat:51")
        self.assertNotIn("Directions", json.dumps(r))
        self.assertNotIn("copier", json.dumps(r))
        self.assertEqual(N["acces_ky_petit"]({"type": "Feature", **FIX["ky"][1]})["properties"]["type"], "acces_portage")
        self.assertEqual(N["acces_ky_rive"]({"type": "Feature", **FIX["ky"][2]})["properties"]["type"], "peche_rive")
        self.assertIsNone(N["acces_ky_rive"]({"type": "Feature", **FIX["ky"][3]}))  # display = 0


if __name__ == "__main__":
    unittest.main()
