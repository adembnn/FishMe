import os, sys, unittest
ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, "..", "collecte"))
import commun_esp10 as commun, WA

PAGE_WDFW = """<title>Largemouth bass | Washington Department of Fish &amp; Wildlife</title>
<h1>Largemouth bass </h1><p>Category</p><p>: Fish</p><p>(Micropterus salmoides)</p>
<div class="view-header"><h3>Lakes where this species may be found</h3></div>
<h4>Adams County</h4><ul><li><a href="/fishing/locations/lowland-lakes/cow-lake" hreflang="en">Cow Lake</a></li>
<li><a href="/fishing/locations/lowland-lakes/herman-lake">Herman Lake</a></li></ul>
<div class="accordion-item"><a href="/fishing/locations/lowland-lakes/hors-section">Hors section</a></div>"""


class T(unittest.TestCase):
    def test_lacs_wdfw(self):
        self.assertEqual(commun.lacs_wdfw(PAGE_WDFW), ["Cow Lake", "Herman Lake"])

    def test_parse_espece(self):
        nom, lat, lacs = WA.parse_espece(PAGE_WDFW)
        self.assertEqual((nom, lat, len(lacs)), ("Largemouth bass", "Micropterus salmoides", 2))

    def test_slug(self):
        self.assertEqual(commun.slug_de("Micropterus salmoides"), "largemouth-bass")
        self.assertIsNone(commun.slug_de("Clarias fuscus"))


if __name__ == "__main__":
    unittest.main()
