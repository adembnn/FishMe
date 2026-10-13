import copy
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import score  # noqa: E402

ALT = {"carnassiers": "brochet", "cyprinides_argentes": "gardon", "carpes": "carpe-commune",
       "salmonides": "truite-fario"}
OTHER = {"carnassiers": "sandre", "cyprinides_argentes": "rotengle", "carpes": "carassin-argente",
         "salmonides": "truite-arc-en-ciel"}


def make_manifest(per_group=10):
    rows = []
    for g, t in ALT.items():
        for i in range(per_group):
            rows.append({"image_id": f"{t}_{i}", "espece_verite": t, "groupe": g,
                         "condition": "main" if i == 0 else "propre"})
    return rows


def make_journal(manifest, top1_ok=0.8, top3_ok=1.0, latency=2000):
    res = []
    for g in ALT:
        rows = [m for m in manifest if m["groupe"] == g]
        for i, m in enumerate(rows):
            t, o = m["espece_verite"], OTHER[g]
            if i < int(len(rows) * top1_ok):
                props = [t, o, "perche"]
            elif i < int(len(rows) * top3_ok):
                props = [o, "perche", t]
            else:
                props = [o, "perche", "silure"]
            res.append({"image_id": m["image_id"], "proposals": props, "latency_ms": latency + i * 100,
                        "error": None})
    return {"schema_version": 1, "results": res}


def test_percentile():
    assert score.percentile([1, 2, 3, 4, 5], 0.5) == 3
    assert score.percentile([10], 0.95) == 10
    assert score.percentile([], 0.5) is None
    assert abs(score.percentile([0, 100], 0.95) - 95) < 1e-9


def test_perfect_go():
    m = make_manifest()
    o = score.score(m, make_journal(m, 1.0, 1.0))
    assert o["top1"] == 1.0 and o["top3"] == 1.0
    assert o["verdict"] == "GO" and o["criteres_echoues"] == []


def test_top1_top3_and_confusion():
    m = make_manifest()
    o = score.score(m, make_journal(m, top1_ok=0.8, top3_ok=0.9))
    assert o["n"] == 40
    assert abs(o["top1"] - 0.8) < 1e-9 and abs(o["top3"] - 0.9) < 1e-9
    row = o["confusion"]["carnassiers"]["brochet"]
    assert row == {"brochet": 8, "sandre": 2}
    assert o["verdict"] == "GO"


def test_confusion_hors_groupe_et_aucune():
    m = make_manifest(2)
    j = make_journal(m)
    j["results"][0]["proposals"] = ["gardon", "brochet", "perche"]
    j["results"][1]["proposals"] = []
    o = score.score(m, j)
    row = o["confusion"]["carnassiers"]["brochet"]
    assert row.get("hors_groupe") == 1 and row.get("aucune") == 1


def test_nogo_under_70():
    m = make_manifest()
    o = score.score(m, make_journal(m, top1_ok=0.3, top3_ok=0.6))
    assert o["top3"] < 0.70
    assert o["verdict"] == "NO-GO"


def test_zone_grise_confirmation_obligatoire():
    m = make_manifest()
    o = score.score(m, make_journal(m, top1_ok=0.7, top3_ok=0.8))
    assert o["verdict"] == "GO_AVEC_CONFIRMATION_OBLIGATOIRE"
    assert any("top-3 global" in c for c in o["criteres_echoues"])


def test_groupe_faible_empeche_go():
    m = make_manifest()
    j = make_journal(m, 1.0, 1.0)
    for r in j["results"]:
        if r["image_id"].startswith("gardon_") and int(r["image_id"].split("_")[1]) < 4:
            r["proposals"] = ["rotengle", "perche", "silure"]
    o = score.score(m, j)
    assert o["groupes"]["cyprinides_argentes"]["top3"] == 0.6
    assert o["top3"] >= 0.85 and o["verdict"] == "GO_AVEC_CONFIRMATION_OBLIGATOIRE"


def test_latence_trop_haute():
    m = make_manifest()
    o = score.score(m, make_journal(m, 1.0, 1.0, latency=4500))
    assert o["latence_ms"]["p50"] > 4000
    assert o["verdict"] == "GO_AVEC_CONFIRMATION_OBLIGATOIRE"


def test_erreurs_et_manquants_comptent_comme_echecs():
    m = make_manifest()
    j = make_journal(m, 1.0, 1.0)
    j["results"][0]["error"] = "guardrailViolation"
    del j["results"][1:5]
    j2 = copy.deepcopy(j)
    j2["results"].append({"image_id": "inconnu_1", "proposals": ["brochet"], "latency_ms": 1})
    o = score.score(m, j2)
    assert o["erreurs"] == 1 and o["non_repondu"] == 4
    assert abs(o["top3"] - 35 / 40) < 1e-9
    assert o["ids_inconnus"] == ["inconnu_1"]


def test_manifeste_reel_40_photos():
    rows = score.load_manifest(Path(__file__).resolve().parent.parent / "eval_manifest.csv")
    assert len(rows) == 40
    assert len({r["espece_verite"] for r in rows}) == 10
    assert all(sum(1 for r in rows if r["espece_verite"] == s) == 4 for s in {r["espece_verite"] for r in rows})
    assert sum(1 for r in rows if r["condition"] == "main") >= 4
    assert {r["groupe"] for r in rows} == set(score.GROUPS)
