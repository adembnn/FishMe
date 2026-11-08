import os, sys, unittest
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "collecte"))
import esp3

NC = "Topics Related to Fish Warmouth Scientific Name: Lepomis gulosus Classification: Game Fish Abundance: x Common throughout NC Hickory Shad Scientific Name: Alosa mediocris Classification: Game Robust Redhorse Scientific Name: Moxostoma robustum Classification: State Endangered"
VA = '<tr><td class="date_stocked">November 6, 2026</td><td class="waterbody_details">Burkes Fork [National Forest Water]</td><td><ul><li>Rainbow Trout</li><li>Tiger Trout</li></ul></td></tr>'


class T(unittest.TestCase):
    def test_nc(self):
        self.assertEqual([x[1] for x in esp3.parse_nc(NC)], ["Lepomis gulosus", "Alosa mediocris", "Moxostoma robustum"])

    def test_va_stock(self):
        self.assertEqual(esp3.parse_va_empoissonnement(VA), [(2026, "Burkes Fork", ["Rainbow Trout", "Tiger Trout"])])

    def test_noms_absents(self):
        self.assertEqual(esp3.noms_presents("Bluegill Lepomis", ["Bluegill", "Walleye"]), ["Bluegill"])

    def test_slug(self):
        t = esp3.charger_table()
        self.assertEqual(esp3.trouver("Hybrid Striped Bass", t)["slug"], "wiper")
        self.assertIsNone(esp3.trouver("Roanoke Bass", t))


if __name__ == "__main__":
    unittest.main()
