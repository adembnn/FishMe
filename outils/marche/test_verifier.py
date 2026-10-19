"""Tests de verifier.py sur des fichiers d'essai temporaires (--sans-reseau).
Lancer : python3 outils/marche/test_verifier.py
"""
import tempfile
import unittest
import pathlib

import verifier as v

ENTETE = "# Rapport\nDécision débloquée : x\nRecherche du 20/10/2026\n"

def trous(texte):
    with tempfile.TemporaryDirectory() as d:
        f = pathlib.Path(d) / "essai.md"
        f.write_text(texte, encoding="utf-8")
        return v.verifier_fichier(f, True, {}, pathlib.Path(d) / "cache.json")

class Verifier(unittest.TestCase):
    def test_fichier_qui_passe(self):
        t = ENTETE + "L'app compte 1 200 avis (§ Sources).\n## Recommandation\n- faire X http://exemple.test\n"
        self.assertEqual(trous(t), [])

    def test_plus_de_200_lignes(self):
        t = ENTETE + "\n".join(["ligne"] * 201)
        self.assertTrue(any("> 200" in x for x in trous(t)))

    def test_entete_incomplete(self):
        self.assertTrue(any("en-tête" in x for x in trous("# T\nrien ici\n")))
        self.assertTrue(any("en-tête" in x for x in trous("Décision débloquée : x\nsans date\n")))

    def test_chiffre_sans_source(self):
        t = ENTETE + "Elle pèse 3 400 téléchargements.\n"
        self.assertTrue(any("unité de marché" in x for x in trous(t)))
        t_ok = ENTETE + "Elle pèse 3 400 téléchargements [?].\n"
        self.assertEqual(trous(t_ok), [])

    def test_recommandation_sans_source(self):
        t = ENTETE + "## Recommandation\n- baisser le prix\n"
        self.assertTrue(any("Recommandation" in x for x in trous(t)))
        t_ok = ENTETE + "## Recommandation\n- baisser le prix (§ avis)\n"
        self.assertEqual(trous(t_ok), [])

if __name__ == "__main__":
    unittest.main(verbosity=1)
