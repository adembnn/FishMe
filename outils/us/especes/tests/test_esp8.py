"""Tests du groupe esp-8 (AR, LA, TX, NM, CO) : analyseurs sur de petits extraits, sans réseau."""
import os, sys, unittest
ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, "..", "collecte"))
sys.path.insert(0, os.path.join(ICI, ".."))
import esp8_commun as C, CO, TX, AR, NM, nas_esp8
import verifier_zones as vz

CO_HTML = ('<h4 class="coh-heading x" > Walleye </h4><div class="coh-container toggle-1 coh-style"> '
           '<a href="https://cpw.state.co.us/species/walleye">p</a> not fishable</div>'
           '<h4 class="coh-heading x" > Razorback Sucker </h4><div class="coh-container toggle-0 coh-style"> '
           '<a href="https://cpw.state.co.us/species/razorback-sucker">p</a></div>')
TX_EAU = ("<table><tr><td>Species</td><td>Year</td></tr>"
          "<tr><td> Bass, Striped </td><td>2021</td><td>5</td></tr><tr><td>Bass, Striped</td><td>2018</td><td>5</td></tr>"
          "<tr><td>Shad, Threadfin</td><td>2019</td><td>9</td></tr></table>")


class T(unittest.TestCase):
    def test_co_liste(self):
        self.assertEqual(CO.parser_liste(CO_HTML), [("Walleye", True), ("Razorback Sucker", False)])
        e, ex, _ = CO.construire([CO_HTML])
        self.assertEqual([x["slug"] for x in e], ["walleye"])
        self.assertEqual(ex, ["Razorback Sucker"])

    def test_tx_eau(self):
        r = TX.parser_eau(TX_EAU)
        self.assertEqual(r, {"striped bass": (2, 2021)})  # le poisson fourrage est écarté

    def test_tx_noms(self):
        self.assertEqual(TX.nom_courant("Bass, Florida Largemouth"), "florida largemouth bass")
        self.assertEqual(TX.nom_courant("Catfish, Blue"), "blue catfish")
        self.assertIsNone(TX.nom_courant("Shad, Gizzard"))

    def test_ar_ancre_absente(self):
        pages = ["<p>nothing</p>"] * len(AR.PAGES)
        e, manquants = AR.construire(pages)
        self.assertEqual(e, [])
        self.assertTrue(manquants)

    def test_nm_ancre(self):
        pages = ["<p>Quemado Lake supports a healthy population of tiger muskie</p>", "<p>x</p>"]
        e, _ = NM.construire(pages)
        self.assertTrue(any(x["zone"]["nom"] == "Quemado Lake" and x["slug"] == "tiger-muskie" for x in e))

    def test_nas_agregat(self):
        nas_esp8.INDEX["cyprinus carpio"] = "common-carp"
        res = [{"status": "established", "huc8": "08080101", "scientificName": "Cyprinus carpio", "commonName": "Common Carp", "year": 1989, "huc8Name": "Atchafalaya"},
               {"status": "established", "huc8": "08080101", "scientificName": "Cyprinus carpio", "commonName": "Common Carp", "year": 2001, "huc8Name": "Atchafalaya"},
               {"status": "failed", "huc8": "08080101", "scientificName": "Esox lucius", "commonName": "Northern Pike", "year": 2001}]
        e = nas_esp8.agreger(res, "LA")
        self.assertEqual(len(e), 1)
        self.assertEqual((e[0]["n"], e[0]["annee_max"], e[0]["slug"]), (2, 2001, "common-carp"))

    def test_fichiers_produits_valides(self):
        dossier = vz.DEFAUT
        for f in sorted(os.listdir(dossier)) if os.path.isdir(dossier) else []:
            if f[:2] in ("AR", "LA", "TX", "NM", "CO"):
                import json
                d = json.load(open(os.path.join(dossier, f), encoding="utf-8"))
                self.assertEqual(vz.verifier_fichier(f, d), [], f)


if __name__ == "__main__":
    unittest.main()
