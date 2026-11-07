"""Tests du lot D7 : consensus et conversion de TX, FL, NC, NY, MI vers regles-us/ (python3 -I -m unittest discover -s . -p 'test_*.py')."""
import hashlib
import importlib.util
import json
import os
import re
import unittest

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.abspath(os.path.join(ICI, "..", "..", ".."))
SORTIE = os.path.join(RACINE, "Packages", "Core", "Sources", "Core", "Resources", "regles-us")
ETATS = ["TX", "FL", "NC", "NY", "MI"]  # lectures et consensus
CHARGES = ["TX", "FL", "NC", "NY"]  # MI : aucune règle confirmée sans réserve, donc aucun fichier regles-us/MI.json
INTERDITS = re.compile(r"autoris|\ballowed?\b|\blegal(ly)?\b|\bpermitt?ed\b|\bauthori[sz]ed\b|tu peux (la )?garder|you can keep|ok to keep", re.I)


def charger(nom, fichier):
    spec = importlib.util.spec_from_file_location(nom, os.path.join(ICI, fichier))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


conv = charger("convertir_niveau2", "convertir_niveau2.py")
cons = charger("consensus_us", "consensus_us.py")


def lire(chemin):
    with open(chemin, encoding="utf-8") as f:
        return json.load(f)


class TestDoubleLecture(unittest.TestCase):
    def test_deux_lectures_distinctes_par_etat(self):
        for e in ETATS:
            a = lire(os.path.join(ICI, "donnees", e, "lecture-a.json"))
            b = lire(os.path.join(ICI, "donnees", e, "lecture-b.json"))
            self.assertEqual((a["lecteur"], b["lecteur"]), ("A", "B"), e)
            self.assertEqual((a["etat"], b["etat"]), (e, e))

    def test_consensus_reproductible(self):
        """Le consensus.json versionné est exactement ce que consensus_us.py recalcule depuis les deux lectures."""
        for e in ETATS:
            d = os.path.join(ICI, "donnees", e)
            a, b = lire(os.path.join(d, "lecture-a.json")), lire(os.path.join(d, "lecture-b.json"))
            gardees, seules_a, seules_b = cons.comparer(a["regles"], b["regles"])
            c = lire(os.path.join(d, "consensus.json"))
            self.assertEqual(len(c["regles"]), sum(1 for r in gardees if r["statut"] == "brouillon"), e)
            self.assertEqual(len(c["incertaines"]), sum(1 for r in gardees if r["statut"] != "brouillon"), e)
            self.assertEqual((len(c["a_verifier"]["seulement_a"]), len(c["a_verifier"]["seulement_b"])), (len(seules_a), len(seules_b)), e)

    def test_a_verifier_garde_les_deux_lectures(self):
        for e in ETATS:
            c = lire(os.path.join(ICI, "donnees", e, "consensus.json"))
            for cle in ("seulement_a", "seulement_b"):
                for r in c["a_verifier"][cle]:
                    self.assertTrue(r.get("citation"), (e, r.get("id")))
                    self.assertTrue((r.get("source") or dict()).get("url"), (e, r.get("id")))


class TestChargement(unittest.TestCase):
    def test_fichiers_a_jour_avec_le_consensus(self):
        """Reconvertir donne les mêmes règles que les fichiers embarqués (rien n'a été modifié à la main) et la somme de l'index est juste."""
        index = lire(os.path.join(SORTIE, "index.json"))
        self.assertNotIn("MI", index["etats"])
        self.assertFalse(os.path.exists(os.path.join(SORTIE, "MI.json")))
        for e in CHARGES:
            donnees, _ = conv.convertir(e, "2026-11-07")
            fichier = lire(os.path.join(SORTIE, e + ".json"))
            self.assertEqual(donnees["regles"], fichier["regles"], e)
            self.assertEqual(index["etats"][e]["regles"], len(fichier["regles"]), e)
            with open(os.path.join(SORTIE, e + ".json"), "rb") as f:
                self.assertEqual(index["etats"][e]["sha256"], hashlib.sha256(f.read()).hexdigest(), e)

    def test_aucune_regle_sans_source_date_lien(self):
        for e in CHARGES:
            f = lire(os.path.join(SORTIE, e + ".json"))
            self.assertTrue(f["lien_agence"].startswith("https://"), e)
            for r in f["regles"]:
                s = r["source"]
                self.assertTrue(s["url"].startswith("https://"), r["id"])
                self.assertRegex(s["date"], r"^\d{4}-\d{2}-\d{2}$")
                self.assertTrue(3 <= len(s["citation"]) <= 200, r["id"])
                self.assertEqual(r["statut"], "double_lecture_confirmee")

    def test_aucun_mot_interdit(self):
        for e in CHARGES:
            with open(os.path.join(SORTIE, e + ".json"), encoding="utf-8") as f:
                texte = f.read()
            self.assertIsNone(INTERDITS.search(texte), e)

    def test_nc_source_tierce_marquee(self):
        f = lire(os.path.join(SORTIE, "NC.json"))
        self.assertTrue(f["regles"])
        for r in f["regles"]:
            self.assertIs(r["source"].get("tiers"), True, r["id"])
            self.assertIn("eregulations.com", r["source"]["url"])
        for e in ("TX", "FL", "NY"):
            for r in lire(os.path.join(SORTIE, e + ".json"))["regles"]:
                self.assertNotIn("tiers", r["source"], (e, r["id"]))

    def test_pas_de_confusion_d_espece_ni_regle_datee_sans_dates(self):
        ny = lire(os.path.join(SORTIE, "NY.json"))["regles"]
        nc = lire(os.path.join(SORTIE, "NC.json"))["regles"]
        self.assertFalse([r for r in nc if r.get("espece") == "bull-trout"])
        self.assertFalse([r for r in ny if r.get("espece") == "sockeye-salmon"])
        self.assertFalse([r for r in ny if r.get("engins")])

    def test_nombre_de_regles_par_etat(self):
        attendu = dict(TX=22, FL=6, NC=15, NY=33)
        for e, n in attendu.items():
            self.assertEqual(len(lire(os.path.join(SORTIE, e + ".json"))["regles"]), n, e)


if __name__ == "__main__":
    unittest.main()
