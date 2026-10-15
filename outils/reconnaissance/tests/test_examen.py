import csv, os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import examen


def jeu(n_ok, n_tot, vraie="brochet", props=("brochet", "sandre", "perche-commune")):
    out = [{"fichier": f"{vraie}{i}", "vraie": vraie, "p1": props[0], "p2": props[1], "p3": props[2]} for i in range(n_ok)]
    out += [{"fichier": f"{vraie}x{i}", "vraie": vraie, "p1": "zz", "p2": "yy", "p3": "autre"} for i in range(n_tot - n_ok)]
    return out


def autres(n, refus):
    return [{"fichier": f"a{i}", "vraie": "autre", "p1": "autre" if i < refus else "brochet", "p2": "-", "p3": "-"} for i in range(n)]


def test_passe():
    r, e = examen.evaluer(jeu(15, 15) + autres(10, 10), taille=12.0)
    assert e == [] and r["top3_moyen"] == 1.0


def test_echec_top3_par_espece_et_taille():
    r, e = examen.evaluer(jeu(15, 15) + jeu(5, 15, vraie="sandre", props=("sandre", "x", "y")) + autres(10, 10), taille=31.0)
    assert r["faibles"] == ["sandre"]
    assert any("30 Mo" in m for m in e)


def test_peu_de_photos_non_evaluable():
    r, e = examen.evaluer(jeu(5, 5) + autres(10, 10), taille=1.0)
    assert r["non_evaluables"] == ["brochet"]
    assert e


def test_refus_autre_insuffisant():
    _, e = examen.evaluer(jeu(12, 12) + autres(10, 5), taille=1.0)
    assert any("refus" in m for m in e)


def test_main_code_sortie(tmp_path):
    j = tmp_path / "j.csv"
    with open(j, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, ["fichier", "vraie", "p1", "p2", "p3"])
        w.writeheader()
        w.writerows(jeu(12, 12) + autres(10, 10))
    m = tmp_path / "m.mlmodel"
    m.write_bytes(b"0" * 1000)
    assert examen.main(["--journal", str(j), "--modele", str(m), "--sortie", str(tmp_path / "s")]) == 0
    assert (tmp_path / "s" / "confusion.csv").exists()
    assert examen.main(["--journal", str(j), "--sortie", str(tmp_path / "s")]) == 1
