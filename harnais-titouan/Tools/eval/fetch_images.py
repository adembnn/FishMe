#!/usr/bin/env python3
"""Telecharge des photos iNaturalist conformes (research grade, licence photo CC0 ou CC-BY uniquement).

  python -I fetch_images.py --per-species 5 --species brochet="Esox lucius" perche="Perca fluviatilis"
  python -I fetch_images.py --count-only ...      # ne telecharge rien, compte seulement

- Quota dur : --max-requests (defaut 60) appels a api.inaturalist.org, compteur affiche et ecrit dans le rapport.
- Par espece : 1 requete monde (liste des candidats + total_results) + 1 requete France (total_results seul).
- Conformite d'une photo : licence de CETTE photo dans {cc0, cc-by}, decodable (Pillow), >= 400 px de large,
  pas de doublon (photo_id, empreinte sha256, meme observateur + meme jour + meme taxon).
- Images dans --out (dossier ignore par Git). Manifeste versionnable : --manifest (auteur, licence, URL).
Non verifie automatiquement : le poisson est-il bien visible et occupe-t-il > 30 % du cadre ? (tri manuel).
"""
import argparse, csv, hashlib, io, json, sys, time, urllib.parse, urllib.request
from datetime import datetime, timezone
from pathlib import Path

API = "https://api.inaturalist.org/v1/observations"
UA = {"User-Agent": "bredouille-eval/0.1 (hackathon ESSEC; usage non commercial de test)"}
OK_LICENSES = {"cc0", "cc-by"}
FIELDS = ["slug", "taxon", "obs_id", "photo_id", "license", "author", "attribution", "url_observation",
          "url_photo", "file", "sha256", "width", "height", "observed_on", "downloaded_at"]


class Quota:
    def __init__(self, maxi, sleep):
        self.n, self.maxi, self.sleep = 0, maxi, sleep

    def get_json(self, params):
        if self.n >= self.maxi:
            raise SystemExit(f"Quota atteint ({self.maxi} requetes API) : arret.")
        self.n += 1
        time.sleep(self.sleep)
        url = API + "?" + urllib.parse.urlencode(params)
        with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
            return json.load(r)


def query(taxon, **extra):
    q = {"taxon_name": taxon, "quality_grade": "research", "photos": "true",
         "photo_license": "cc0,cc-by", "order_by": "votes", "per_page": 1}
    q.update(extra)
    return q


def fetch_bytes(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        return r.read()


def check_image(data):
    from PIL import Image
    im = Image.open(io.BytesIO(data))
    im.load()
    return im.width, im.height


def load_manifest(path):
    if not Path(path).exists():
        return []
    with open(path, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f, delimiter=";"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--species", nargs="+", required=True, help='slug="Nom latin"')
    ap.add_argument("--per-species", type=int, default=5)
    ap.add_argument("--out", default=str(Path(__file__).parent / "images"))
    ap.add_argument("--manifest", default=str(Path(__file__).parent / "images_manifest.csv"))
    ap.add_argument("--report", default=str(Path(__file__).parent / "images_report.json"))
    ap.add_argument("--max-requests", type=int, default=60)
    ap.add_argument("--sleep", type=float, default=1.1)
    ap.add_argument("--min-width", type=int, default=400)
    ap.add_argument("--count-only", action="store_true")
    a = ap.parse_args()

    quota = Quota(a.max_requests, a.sleep)
    rows = load_manifest(a.manifest)
    seen_photo = {r["photo_id"] for r in rows}
    seen_hash = {r["sha256"] for r in rows}
    seen_key = set()
    report = {"date": datetime.now(timezone.utc).isoformat(timespec="seconds"), "species": {}}
    new_rows = []
    for spec in a.species:
        slug, taxon = spec.split("=", 1)
        world = quota.get_json(query(taxon, per_page=min(200, max(40, a.per_species * 8))))
        france = quota.get_json(query(taxon, place_id=6753))
        stat = {"taxon": taxon, "total_monde_cc0_ccby": world["total_results"],
                "total_france_cc0_ccby": france["total_results"], "candidats_examines": 0,
                "rejetes": {"licence_photo": 0, "doublon": 0, "image": 0, "trop_petite": 0},
                "telechargees": 0}
        d = Path(a.out) / slug
        for o in world["results"]:
            if stat["telechargees"] >= a.per_species or a.count_only:
                break
            stat["candidats_examines"] += 1
            photos = o.get("photos") or []
            p = next((x for x in photos if (x.get("license_code") or "").lower() in OK_LICENSES), None)
            if not p:
                stat["rejetes"]["licence_photo"] += 1
                continue
            user = (o.get("user") or {}).get("login", "")
            key = (user, o.get("observed_on"), taxon)
            if str(p["id"]) in seen_photo or key in seen_key:
                stat["rejetes"]["doublon"] += 1
                continue
            url = p["url"].replace("square", "large")
            try:
                data = fetch_bytes(url)
                w, h = check_image(data)
            except Exception as e:  # reseau ou fichier illisible
                print("  rejet image", url, type(e).__name__)
                stat["rejetes"]["image"] += 1
                continue
            digest = hashlib.sha256(data).hexdigest()
            if digest in seen_hash:
                stat["rejetes"]["doublon"] += 1
                continue
            if w < a.min_width:
                stat["rejetes"]["trop_petite"] += 1
                continue
            d.mkdir(parents=True, exist_ok=True)
            fn = d / f"{o['id']}_{p['id']}.jpg"
            fn.write_bytes(data)
            seen_photo.add(str(p["id"])); seen_hash.add(digest); seen_key.add(key)
            new_rows.append({"slug": slug, "taxon": taxon, "obs_id": o["id"], "photo_id": p["id"],
                             "license": p["license_code"], "author": user or (p.get("attribution") or ""),
                             "attribution": p.get("attribution", ""),
                             "url_observation": f"https://www.inaturalist.org/observations/{o['id']}",
                             "url_photo": url, "file": f"{slug}/{fn.name}", "sha256": digest,
                             "width": w, "height": h, "observed_on": o.get("observed_on", ""),
                             "downloaded_at": report["date"]})
            stat["telechargees"] += 1
        report["species"][slug] = stat
        print(f"{slug:<14} monde={stat['total_monde_cc0_ccby']:>6} france={stat['total_france_cc0_ccby']:>5} "
              f"telechargees={stat['telechargees']} rejets={stat['rejetes']}")
    report["requetes_api"] = quota.n
    if new_rows:
        write_header = not Path(a.manifest).exists()
        with open(a.manifest, "a", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=FIELDS, delimiter=";", lineterminator="\n")
            if write_header:
                w.writeheader()
            w.writerows(new_rows)
    Path(a.report).write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"requetes API : {quota.n}/{a.max_requests} ; nouvelles images : {len(new_rows)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
