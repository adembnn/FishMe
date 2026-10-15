import gzip
import json
import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import build_departments as bd  # noqa: E402
import rarity  # noqa: E402

B = [0.30, 0.12, 0.04, 0.01]
A = [0.30, 0.10, 0.03, 0.01]


@pytest.mark.parametrize("f,expected", [
    (1.0, 1), (0.30, 1), (0.2999, 2), (0.12, 2), (0.1199, 3), (0.04, 3), (0.0399, 4),
    (0.01, 4), (0.0099, 5), (0.0, 5)])
def test_classify_bornes_incluses_en_bas(f, expected):
    assert rarity.classify(f, B) == expected


def test_classify_profils_differents():
    assert rarity.classify(0.11, B) == 3  # B : en dessous de 12 %
    assert rarity.classify(0.11, A) == 2  # A : au-dessus de 10 %
    assert rarity.classify(0.035, A) == 3 and rarity.classify(0.035, B) == 4


def test_classify_monotone():
    freqs = [i / 1000 for i in range(1000, -1, -1)]
    classes = [rarity.classify(f, B) for f in freqs]
    assert classes == sorted(classes)


def test_plafond_plan_eau():
    assert rarity.apply_ceiling(5, "plan_eau", {"plan_eau": 2}) == (2, True)
    assert rarity.apply_ceiling(1, "plan_eau", {"plan_eau": 2}) == (1, False)
    assert rarity.apply_ceiling(2, "plan_eau", {"plan_eau": 2}) == (2, False)
    assert rarity.apply_ceiling(5, "cours_eau", {"plan_eau": 2}) == (5, False)


@pytest.mark.parametrize("ops,sta,expected", [
    (20, 10, "ok"), (19, 10, "faible"), (20, 9, "faible"), (500, 3, "faible"), (51, 9, "faible"), (0, 0, "faible")])
def test_fiabilite(ops, sta, expected):
    assert rarity.reliability(ops, sta, {"min_stations": 10, "min_operations": 20}) == expected


def test_fusion_codes():
    fusion = {"CCO": ["CCO", "CMI", "CCU"]}
    assert rarity.canonical("CMI", fusion) == "CCO"
    assert rarity.canonical("BRO", fusion) == "BRO"


OPS = [{"code_operation": i, "date_operation": d, "code_station": s} for i, d, s in [
    (1, "2012-05-01T10:00:00Z", "S1"), (2, "2015-05-01T10:00:00Z", "S2"),
    (3, "2020-05-01T10:00:00Z", "S1"), (4, "2005-05-01T10:00:00Z", "S3")]]


def obs(op, sp, sta="S1"):
    return {"code_operation": str(op), "code_alternatif_taxon": sp, "code_station": sta}


def test_aggregate_filtre_depuis_et_types_mixtes():
    rows = [obs(1, "BRO"), obs(1, "BRO"), obs(2, "BRO", "S2"), obs(4, "BRO", "S3"), obs(3, "CMI"), obs(9, "PER")]
    agg = rarity.aggregate(OPS, rows, 2010, {"CCO": ["CCO", "CMI", "CCU"]})
    assert agg["n_ops"] == 3 and agg["n_sta"] == 2  # l'operation 4 (2005) est exclue
    assert agg["especes"]["BRO"] == (2, 2)  # lots doubles comptes une fois, op 4 ignoree
    assert agg["especes"]["CCO"] == (1, 1)  # CMI fusionne dans CCO
    assert "PER" not in agg["especes"]  # operation inconnue
    assert agg["obs_ignorees"] == 2


META = {"BRO": ["Brochet", "mixte", ""], "CCO": ["Carpe", "plan_eau", ""], "SIL": ["Silure", "plan_eau", "exotique"],
        "LPP": ["Lamproie", "cours_eau", "protege"], "VAI": ["Vairon", "cours_eau", ""]}


def test_rank_species_statuts_plafond_et_tri():
    agg = {"n_ops": 100, "n_sta": 30, "obs_ignorees": 0,
           "especes": {"VAI": (60, 20), "BRO": (12, 8), "CCO": (0, 0), "SIL": (2, 2), "LPP": (50, 10), "XXX": (7, 3)}}
    agg["especes"]["CCO"] = (1, 1)
    out, unknown = rarity.rank_species(agg, META, B, {"plan_eau": 2})
    by = {e["c"]: e for e in out}
    assert unknown == {"XXX": 7}
    assert by["VAI"]["k"] == 1 and by["BRO"]["k"] == 2
    assert by["CCO"]["k"] == 2 and by["CCO"]["pl"] == 1  # 1 % -> classe 4, plafonnee a 2
    assert "k" not in by["SIL"] and by["SIL"]["st"] == "exotique"
    assert "k" not in by["LPP"] and by["LPP"]["st"] == "protege"
    assert by["SIL"]["r"] == 1 and by["CCO"]["r"] == 1 and "r" not in by["BRO"]
    assert [e["c"] for e in out] == ["VAI", "LPP", "BRO", "SIL", "CCO"]  # freq decroissante


def test_distribution_ignore_les_especes_a_statut():
    esp = [{"k": 1}, {"k": 1}, {"k": 4}, {"st": "protege"}]
    assert rarity.distribution(esp) == {1: 2, 2: 0, 3: 0, 4: 1, 5: 0}


def _write(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with gzip.open(path, "wt", encoding="utf-8") as f:
        json.dump(payload, f)


def test_build_bout_en_bout_et_cache_incomplet(tmp_path):
    cache = str(tmp_path)
    _write(f"{cache}/operations/99/r.json.gz", {"data": OPS})
    _write(f"{cache}/observations/99/r.json.gz", {"data": [obs(1, "BRO"), obs(2, "BRO", "S2")]})
    _write(f"{cache}/observations/99/count_r.json.gz", {"count": 2})
    cfg = bd.load_config()
    cfg["since"] = 2010
    doc, st = bd.build("99", cfg, {"BRO": ["Brochet", "mixte", ""]}, "B", cache)
    assert st["complet"] and doc["ops"] == 3 and doc["fiab"] == "faible"
    assert doc["especes"] == [{"c": "BRO", "n": "Brochet", "o": 2, "s": 2, "p": 0.6667, "k": 1, "r": 1}]
    assert bd.available_deps(cache) == ["99"]
    _write(f"{cache}/observations/99/count_r.json.gz", {"count": 50})
    assert not bd.build("99", cfg, {}, "B", cache)[1]["complet"]


def test_config_coherente():
    cfg = bd.load_config()
    for nom, bornes in cfg["seuils"]["profils"].items():
        assert len(bornes) == len(cfg["classes"]) - 1 and bornes == sorted(bornes, reverse=True), nom
    assert cfg["seuils"]["profil_actif"] in cfg["seuils"]["profils"]
    meta = bd.load_meta()
    assert all(len(v) == 3 and v[1] in ("cours_eau", "mixte", "plan_eau") for v in meta.values())
