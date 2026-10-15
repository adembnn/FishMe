import csv, os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import preparer_jeu as pj
from PIL import Image  # test seulement : fabrique des images factices


def fabriquer(racine, plan):
    """plan : {espece: [(nom, taille, auteur)]} -> jeu factice + licences.csv"""
    lic = []
    for esp, photos in plan.items():
        os.makedirs(racine / esp, exist_ok=True)
        for nom, taille, auteur in photos:
            Image.new("RGB", taille, (10, 20, 30)).save(racine / esp / nom, "JPEG" if nom.endswith("jpg") else "PNG")
            lic.append({"fichier": f"{esp}/{nom}", "espece_id": esp, "source": "test", "observation_ou_url": "", "licence": "cc0", "auteur": auteur})
    with open(racine / "licences.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, ["fichier", "espece_id", "source", "observation_ou_url", "licence", "auteur"])
        w.writeheader()
        w.writerows(lic)


def plan_standard():
    return {
        "brochet": [(f"b{i}.jpg", (320, 300), f"p{i % 10}") for i in range(100)] + [("petit.jpg", (200, 400), "x"), ("p.png", (299, 299), "y")],
        "sandre": [(f"s{i}.jpg", (400, 400), f"q{i}") for i in range(40)],
        "autre": [(f"a{i}.jpg", (300, 300), f"r{i}") for i in range(20)],
        "lotte": [(f"l{i}.jpg", (300, 300), f"t{i}") for i in range(30)],
    }


def test_taille_image(tmp_path):
    fabriquer(tmp_path, {"x": [("a.jpg", (123, 456), "z"), ("b.png", (50, 60), "z")]})
    assert pj.taille_image(str(tmp_path / "x" / "a.jpg")) == (123, 456)
    assert pj.taille_image(str(tmp_path / "x" / "b.png")) == (50, 60)
    (tmp_path / "x" / "c.jpg").write_bytes(b"pas une image")
    assert pj.taille_image(str(tmp_path / "x" / "c.jpg")) is None


def test_decoupe_70_15_15_par_photographe_et_299(tmp_path):
    fabriquer(tmp_path, plan_standard())
    man, rapport = pj.preparer(str(tmp_path), ["brochet", "sandre"], str(tmp_path / "out"), copier=True)
    br = [m for m in man if m["classe"] == "brochet"]
    assert len(br) == 101  # 100 + p.png 299x299 ; petit.jpg 200x400 exclu
    comptes = {l: sum(1 for m in br if m["lot"] == l) for l in ("train", "val", "test")}
    assert comptes["train"] >= 60 and comptes["val"] >= 10 and comptes["test"] >= 10, comptes
    # un photographe ne se retrouve jamais dans deux lots
    lots_par_auteur = {}
    for m in br:
        lots_par_auteur.setdefault(m["auteur"], set()).add(m["lot"])
    assert all(len(v) == 1 for v in lots_par_auteur.values())
    assert "images exclues (< 299x299 ou illisibles) : 1" in rapport
    assert "lotte" in rapport  # dossier hors liste ignoré
    assert os.path.exists(tmp_path / "out" / "test" / "sandre")
    assert os.path.exists(tmp_path / "out" / "manifeste.csv")
    assert not any(m["classe"] == "lotte" for m in man)


def test_sandre_decoupe_proche_70_15_15(tmp_path):
    fabriquer(tmp_path, plan_standard())
    man, _ = pj.preparer(str(tmp_path), ["brochet", "sandre"])
    sa = [m["lot"] for m in man if m["classe"] == "sandre"]
    assert (sa.count("train"), sa.count("val"), sa.count("test")) == (28, 6, 6)


def test_repli_autres_vers_autre_et_deterministe(tmp_path):
    fabriquer(tmp_path, plan_standard())
    m1, r = pj.preparer(str(tmp_path), ["brochet", "sandre"], repli=True)
    assert any(m["classe"] == "autre" and m["dossier"] == "lotte" for m in m1)
    m2, _ = pj.preparer(str(tmp_path), ["brochet", "sandre"], repli=True)
    assert m1 == m2
    assert "déséquilibre" in r


def test_repli_constante():
    assert len(pj.REPLI) == 6 and "black-bass" in pj.REPLI
