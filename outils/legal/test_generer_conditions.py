import unittest
import re
from generer_conditions import SOURCE, echapper, lire, swift

SRC = """intro ignorée
<!-- version: 1er mars 2027 | numero: 2 -->
## 1. Éditeur
Ligne un
ligne deux avec "guillemets" et \\ antislash.

- puce A
- puce B

## 2. Autre
[lien](https://exemple.fr)
<!-- fin -->
## 3. Ignoré
"""


class TestGenerer(unittest.TestCase):
    def test_lecture(self):
        v, n, arts = lire(SRC)
        self.assertEqual((v, n, len(arts)), ("1er mars 2027", 2, 2))
        self.assertEqual(arts[0][1][0], 'Ligne un ligne deux avec "guillemets" et \\ antislash.')
        self.assertEqual(arts[0][1][1:], ["• puce A", "• puce B"])

    def test_echappement(self):
        self.assertEqual(echapper('a"b\\c'), 'a\\"b\\\\c')

    def test_swift(self):
        self.assertIn("static let numeroVersion = 2", swift(*lire(SRC)))


class TestSourceReelle(unittest.TestCase):
    """Les CGU réelles (docs/legal/conditions-fishme.md) : réseau social, S2 du 19 oct. 2026."""

    @classmethod
    def setUpClass(cls):
        cls.version, cls.numero, cls.articles = lire(SOURCE.read_text(encoding="utf-8"))
        cls.titres = [titre for titre, _ in cls.articles]
        cls.tout = "\n".join(titre + "\n" + "\n".join(ps) for titre, ps in cls.articles)

    def article(self, debut):
        trouves = [(i, ps) for i, (titre, ps) in enumerate(self.articles, start=1) if titre.startswith(debut)]
        self.assertEqual(len(trouves), 1, f"article « {debut} » absent ou en double")
        return trouves[0]

    def test_trois_articles_du_reseau(self):
        for debut in ("Contenu que tu publies", "Ton surnom et ton avatar", "Le lieu de tes publications"):
            self.article(debut)

    def test_retrait_sous_24_heures_et_contact(self):
        _, paragraphes = self.article("Contenu que tu publies")
        texte = " ".join(paragraphes)
        self.assertIn("24 heures", texte)
        self.assertIn("fishme.app@gmail.com", texte)
        self.assertIn("bloquer", texte)
        self.assertIn("signaler", texte)

    def test_age_minimum_et_aucune_date_de_naissance(self):
        _, paragraphes = self.article("Accepter ces conditions")
        texte = " ".join(paragraphes)
        self.assertIn("J'ai 15 ans ou plus", texte)
        self.assertIn("n'en conserve aucune", texte)

    def test_lieu_choisi_et_aucune_coordonnee(self):
        _, paragraphes = self.article("Le lieu de tes publications")
        texte = " ".join(paragraphes)
        for morceau in ("le département seul", "aucun lieu", "position GPS", "n'apparaît pas dans le fil de ta région"):
            self.assertIn(morceau, texte)

    def test_une_seule_adresse_de_contact(self):
        adresses = set(re.findall(r"[\w.+-]+@[\w-]+\.[\w.]+", self.tout))
        self.assertEqual(adresses, {"fishme.app@gmail.com"})

    def test_numero_monte_avec_le_reseau(self):
        self.assertGreaterEqual(self.numero, 2)

    def test_renvois_d_articles(self):
        indice_pro, _ = self.article("FishMe Pro")
        indice_editeur, _ = self.article("Qui édite FishMe")
        for n in map(int, re.findall(r"FishMe Pro \(article (\d+)\)", self.tout)):
            self.assertEqual(n, indice_pro)
        for n in map(int, re.findall(r"chez Apple \(article (\d+)\)", self.tout)):
            self.assertEqual(n, indice_pro)
        for n in map(int, re.findall(r"adresse de l'article (\d+)", self.tout)):
            self.assertEqual(n, indice_editeur)
        for n in map(int, re.findall(r"\barticles? (\d+)\b", self.tout)):
            self.assertLessEqual(n, len(self.articles))

    def test_phrases_interdites(self):
        bas = self.tout.lower()
        for terme in ("poké", "pokemon", "pokédex", "pokedex", "tu peux la garder", "tu peux le garder",
                      "tu peux garder", "jamais en public", "⚠"):
            self.assertNotIn(terme, bas, f"terme interdit : {terme}")
        # pas de promesse de modération continue
        for terme in ("24h/24", "24 h sur 24", "7j/7", "en temps réel"):
            self.assertNotIn(terme, bas)

    def test_la_mesure_se_donne_dans_les_reglages_seulement(self):
        _, paragraphes = self.article("Données personnelles")
        texte = " ".join(paragraphes)
        self.assertIn("seulement dans les Réglages", texte)
        self.assertIn("éteinte", texte)


if __name__ == "__main__":
    unittest.main()
