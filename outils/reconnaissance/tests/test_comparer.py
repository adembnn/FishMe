import csv, os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import comparer


def ecrire(chemin, lignes, cols):
    with open(chemin, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, cols)
        w.writeheader()
        w.writerows(lignes)


def manifeste(tmp_path):
    rows = [{"classe": c, "lot": "test", "dossier": c, "fichier": f"{i}.jpg"} for c in ("brochet", "sandre", "autre") for i in range(10)]
    rows.append({"classe": "brochet", "lot": "train", "dossier": "brochet", "fichier": "t.jpg"})
    p = tmp_path / "m.csv"
    ecrire(p, rows, ["classe", "lot", "dossier", "fichier"])
    return str(p)


def test_choisir_20_stratifie_et_deterministe(tmp_path):
    m = manifeste(tmp_path)
    a = comparer.choisir(m, 20)
    assert len(a) == 20 and len(set(a)) == 20 and a == comparer.choisir(m, 20)
    assert not any("t.jpg" in k for k in a)  # jamais le lot train
    assert sum(k.startswith("brochet/") for k in a) == 7 and sum(k.startswith("autre/") for k in a) == 6


def test_comparer_resume():
    cols = ("fichier", "vraie", "p1", "p2", "p3")
    a = {"x/1": dict(zip(cols, ("x/1", "brochet", "brochet", "sandre", "-"))), "x/2": dict(zip(cols, ("x/2", "sandre", "brochet", "sandre", "-")))}
    b = {"x/1": dict(zip(cols, ("x/1", "brochet", "sandre", "-", "-"))), "x/2": dict(zip(cols, ("x/2", "sandre", "sandre", "-", "-")))}
    lignes, s = comparer.comparer(a, b, ["x/1", "x/2", "x/3"])
    assert (s["n"], s["a1"], s["a3"], s["b1"], s["b3"], s["accord"]) == (2, 1, 2, 1, 1, 0)
    assert "absente" in lignes[2][1]


def test_main_compare(tmp_path, capsys):
    cols = ["fichier", "vraie", "p1", "p2", "p3"]
    ecrire(tmp_path / "a.csv", [{"fichier": "x/1", "vraie": "brochet", "p1": "brochet", "p2": "-", "p3": "-"}], cols)
    ecrire(tmp_path / "b.csv", [{"fichier": "x/1", "vraie": "brochet", "p1": "sandre", "p2": "brochet", "p3": "-"}], cols)
    (tmp_path / "l.csv").write_text("fichier\nx/1\n", encoding="utf-8")
    assert comparer.main(["compare", "--createml", str(tmp_path / "a.csv"), "--apple", str(tmp_path / "b.csv"), "--liste", str(tmp_path / "l.csv")]) == 0
    assert "Create ML top-1 1/1 top-3 1/1 ; IA d'Apple top-1 0/1 top-3 1/1" in capsys.readouterr().out
