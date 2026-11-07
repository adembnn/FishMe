import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

DOSSIER = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(DOSSIER))
import verifier  # noqa: E402


def copie(modif):
    """Copie le dossier dans un répertoire temporaire et applique modif(especes)."""
    tmp = Path(tempfile.mkdtemp())
    for n in ("especes-us.json", "groupes-confusion.json", "correspondance-fr.json"):
        (tmp / n).write_text((DOSSIER / n).read_text(encoding="utf-8"), encoding="utf-8")
    es = json.loads((tmp / "especes-us.json").read_text(encoding="utf-8"))
    modif(es)
    (tmp / "especes-us.json").write_text(json.dumps(es), encoding="utf-8")
    return tmp


class TestTable(unittest.TestCase):
    def test_table_reelle_sans_trou(self):
        err, es = verifier.controler(DOSSIER)
        self.assertEqual(err, [])
        self.assertGreaterEqual(len(es), 78)

    def test_doublon_slug(self):
        def m(es): es[1]["slug"] = es[0]["slug"]
        err, _ = verifier.controler(copie(m))
        self.assertTrue(any("slug en double" in x for x in err))

    def test_latin_vide(self):
        def m(es): es[0]["latin"] = " "
        err, _ = verifier.controler(copie(m))
        self.assertTrue(any("latin vide" in x for x in err))

    def test_source_manquante(self):
        def m(es):
            es[0]["source"] = []
            es[0].pop("a_verifier", None)
        err, _ = verifier.controler(copie(m))
        self.assertTrue(any("ni source" in x for x in err))

    def test_statut_inconnu(self):
        def m(es): es[0]["statut"] = "rare"
        err, _ = verifier.controler(copie(m))
        self.assertTrue(any("statut inconnu" in x for x in err))

    def test_champ_manquant(self):
        def m(es): del es[0]["famille"]
        err, _ = verifier.controler(copie(m))
        self.assertTrue(any("famille manquant" in x for x in err))


if __name__ == "__main__":
    unittest.main()
