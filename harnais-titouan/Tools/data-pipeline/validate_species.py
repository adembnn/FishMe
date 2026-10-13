#!/usr/bin/env python3
"""Genere et valide le catalogue d'especes.

  python -I validate_species.py --build   # species_source.csv -> species.json, puis validation
  python -I validate_species.py           # valide species.json existant
Sortie 0 si tout est conforme, 1 sinon. Aucune dependance externe (mini validateur JSON Schema).
"""
import argparse, csv, json, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CSV_PATH = HERE / "species_source.csv"
SCHEMA_PATH = HERE / "schema" / "species.schema.json"
JSON_PATH = HERE.parent.parent / "PecheCore" / "Sources" / "PecheCore" / "Resources" / "Data" / "species.json"

# wording-ok : cette liste contient volontairement les mots à détecter
FORBIDDEN = ["pokédex", "pokedex", "pokémon", "pokemon", "tu peux la garder", "tu peux le garder",  # wording-ok
             "légal", "illégal", "autorisé", "interdit de pêcher", "probabilité de capture"]  # wording-ok
EMOJI = re.compile("[\U0001F300-\U0001FAFF☀-➿]")


def _types(t):
    m = {"object": dict, "array": list, "string": str, "integer": int, "boolean": bool, "null": type(None)}
    return tuple(m[x] for x in (t if isinstance(t, list) else [t]))


def _resolve(ref, root):
    node = root
    for p in ref.lstrip("#/").split("/"):
        node = node[p]
    return node


def _check(inst, sch, root, path, errs):
    if "$ref" in sch:
        sch = _resolve(sch["$ref"], root)
    if "enum" in sch and inst not in sch["enum"]:
        errs.append(f"{path}: valeur {inst!r} hors enum {sch['enum']}")
        return
    if "type" in sch:
        ok = isinstance(inst, _types(sch["type"]))
        if isinstance(inst, bool) and "boolean" not in (sch["type"] if isinstance(sch["type"], list) else [sch["type"]]):
            ok = False
        if not ok:
            errs.append(f"{path}: type {type(inst).__name__} attendu {sch['type']}")
            return
    if isinstance(inst, str):
        if len(inst) < sch.get("minLength", 0):
            errs.append(f"{path}: trop court ({len(inst)} < {sch['minLength']})")
        if "pattern" in sch and not re.search(sch["pattern"], inst):
            errs.append(f"{path}: {inst!r} ne respecte pas {sch['pattern']}")
    if isinstance(inst, int) and not isinstance(inst, bool):
        if "minimum" in sch and inst < sch["minimum"]:
            errs.append(f"{path}: {inst} < {sch['minimum']}")
        if "maximum" in sch and inst > sch["maximum"]:
            errs.append(f"{path}: {inst} > {sch['maximum']}")
    if isinstance(inst, dict):
        for k in sch.get("required", []):
            if k not in inst:
                errs.append(f"{path}: champ requis manquant '{k}'")
        props = sch.get("properties", {})
        for k, v in inst.items():
            if k in props:
                _check(v, props[k], root, f"{path}.{k}", errs)
            elif sch.get("additionalProperties") is False:
                errs.append(f"{path}: champ inconnu '{k}'")
    if isinstance(inst, list):
        if len(inst) < sch.get("minItems", 0) or len(inst) > sch.get("maxItems", 10**9):
            errs.append(f"{path}: {len(inst)} elements hors [{sch.get('minItems', 0)}, {sch.get('maxItems', '...')}]")
        for i, x in enumerate(inst):
            if "items" in sch:
                _check(x, sch["items"], root, f"{path}[{i}]", errs)


def business_rules(doc):
    errs = []
    sp = doc.get("species", [])
    for field in ("id", "codeAspe", "codeSandre", "nomFr"):
        vals = [s.get(field) for s in sp]
        dup = {v for v in vals if vals.count(v) > 1}
        if field != "nomFr" and dup:
            errs.append(f"doublon {field}: {sorted(map(str, dup))}")
    for s in sp:
        i = s.get("id")
        n = len([x for x in re.split(r"(?<=[.!?])\s+", s.get("description", "").strip()) if x])
        if n != 2:
            errs.append(f"{i}: description = {n} phrases (2 attendues)")
        text = json.dumps(s, ensure_ascii=False).lower()
        for w in FORBIDDEN:
            if w in text:
                errs.append(f"{i}: terme interdit '{w}'")
        if EMOJI.search(text):
            errs.append(f"{i}: emoji present")
        keys = [t.get("key") for t in s.get("traits", [])]
        if len(set(keys)) != len(keys):
            errs.append(f"{i}: cles de traits dupliquees {keys}")
        if s.get("statut") == "envahissante" and s.get("consigne") == "relacher":
            errs.append(f"{i}: une espece envahissante ne doit jamais porter 'relacher' (peche/03 2.2)")
        if s.get("statut") == "envahissante" and s.get("consigne") != "ne_pas_deplacer":
            errs.append(f"{i}: envahissante sans consigne ne_pas_deplacer")
        if s.get("statut") in ("protege", "menace", "envahissante") and not s.get("sources", {}).get("statut"):
            errs.append(f"{i}: statut renseigne sans source")
        if s.get("consigne") and not s.get("sources", {}).get("statut"):
            errs.append(f"{i}: consigne sans source")
        if s.get("frayeres1988") and s.get("statut") == "aucun":
            errs.append(f"{i}: frayeres 1988 mais statut 'aucun'")
    return errs


def build():
    species = []
    with open(CSV_PATH, encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f, delimiter=";"):
            traits = [dict(zip(("key", "value"), t.split("=", 1))) for t in r["traits"].split("|") if t]
            taille = r["taille_commune_cm"].strip()
            species.append({
                "id": r["id"], "codeAspe": r["code_hubeau"], "codeSandre": int(r["code_sandre"]),
                "nomFr": r["nom_fr"], "nomLatin": r["nom_latin"], "famille": r["famille"],
                "categorie": r["categorie"], "milieu": r["milieu"], "origine": r["origine"],
                "frayeres1988": r["frayeres_1988"] == "oui",
                "statut": r["statut_app"] or None, "consigne": r["consigne"] or None,
                "traits": traits, "tailleCommuneCm": int(taille) if taille else None, "tailleMaxCm": None,
                "description": r["description"], "anecdote": None, "imageAsset": None,
                "sources": {"taxonomie": r["source_taxo"], "statut": r["source_statut"] or None,
                            "biologie": r["source_bio"]},
                "aValider": [x.strip() for x in r["a_valider"].split(",") if x.strip()],
            })
    doc = {"version": 1, "source": "Tools/data-pipeline/species_source.csv", "species": species}
    JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    JSON_PATH.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return doc


def validate(doc):
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    errs = []
    _check(doc, schema, schema, "$", errs)
    return errs + business_rules(doc)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--build", action="store_true")
    a = ap.parse_args()
    doc = build() if a.build else json.loads(JSON_PATH.read_text(encoding="utf-8"))
    errs = validate(doc)
    for e in errs:
        print("ERREUR", e)
    sp = doc["species"]
    print(f"{len(sp)} especes, {sum(1 for s in sp if s['statut'] is None)} sans statut, "
          f"{sum(1 for s in sp if s['tailleCommuneCm'] is None)} sans taille, {len(errs)} erreur(s)")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
