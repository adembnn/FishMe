# L11 Règles à jour : ce que le Mac doit faire (lot/veille, 4f15ec7, app non compilée ; Core vert 172 tests)
1. RootView.swift, ParcoursApp.init : `let core = MoteurCore(donnees: .embarque(reglesTelechargees: ReglesAJour.dossierCopies))`
2. RootView.swift, fin de `func demarrer() async` après `await marque.rafraichir()` : `Task.detached(priority: .utility) { await ReglesAJour.lancer() }`
3. Clé Info `ReglesBaseURL` (texte), vide tant qu'Adem n'a pas choisi l'hébergement (défaut : dépôt public + GitHub Pages). Vide = règles embarquées.
4. Copier outils/veille/veille.yml.exemple vers .github/workflows/veille.yml et `gh label create veille` ; si les préfectures sont injoignables depuis Actions, faire tourner outils/veille/veille-local.sh sur un ordinateur d'Adem.
Limite : une mise à jour téléchargée sert au lancement suivant.
