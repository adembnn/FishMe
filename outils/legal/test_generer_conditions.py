import unittest
from generer_conditions import echapper, lire, swift

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


if __name__ == "__main__":
    unittest.main()
