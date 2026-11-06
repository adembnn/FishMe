"""Télécharge les photos d'un manifeste, réduites à 640 px, réencodées sans EXIF (donc sans GPS).
usage: telecharger.py manifeste.csv dossier_sortie plafond_par_classe"""
import csv, hashlib, io, sys, os, random, urllib.request, concurrent.futures as cf
from PIL import Image, ImageOps
Image.MAX_IMAGE_PIXELS = 200_000_000
man, dest, plafond = sys.argv[1], sys.argv[2], int(sys.argv[3])
rows = list(csv.DictReader(open(man)))
random.seed(0); random.shuffle(rows)
par = {}
for r in rows:
    par.setdefault(r["classe"], [])
    if len(par[r["classe"]]) < plafond: par[r["classe"]].append(r)
todo = [r for v in par.values() for r in v]
UA = {"User-Agent": "FishMe-dataset/0.1 (contact: adembanni@gmail.com)"}
def un(r):
    h = hashlib.sha1(r["url"].encode()).hexdigest()[:16]
    p = os.path.join(dest, r["classe"], h + ".jpg")
    if os.path.exists(p): return r, h, "deja"
    try:
        with urllib.request.urlopen(urllib.request.Request(r["url"], headers=UA), timeout=30) as f:
            data = f.read(30_000_000)
        im = Image.open(io.BytesIO(data)); im = ImageOps.exif_transpose(im).convert("RGB")
        if min(im.size) < 150: return r, h, "petite"
        im.thumbnail((640, 640))
        os.makedirs(os.path.dirname(p), exist_ok=True)
        im.save(p, "JPEG", quality=88)  # pas d'exif passé : aucun GPS
        return r, h, "ok"
    except Exception as e:
        return r, h, "erreur:" + type(e).__name__
out = csv.writer(open(man.replace(".csv", "") + ".telecharge.csv", "a", newline=""))
n = 0
with cf.ThreadPoolExecutor(16) as ex:
    for r, h, st in ex.map(un, todo):
        out.writerow([r["classe"], h, st, r["url"], r["photographe"], r["licence"], r["dataset"]]); n += 1
        if n % 500 == 0: print(n, "/", len(todo), flush=True)
print("fini", n)
