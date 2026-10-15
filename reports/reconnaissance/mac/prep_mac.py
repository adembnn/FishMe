"""Prépare les photos pour Create ML sur un Mac, avec le MÊME jeu de test que le banc d'essai du cloud.
Usage (dans un dossier vide ; classes.tsv et classes_modele.txt à côté de ce script) :
  python3 -m pip install torch opencv-python-headless pillow
  python3 prep_mac.py
Sortie : createml/train/<classe>/*.jpg et createml/test/<classe>/*.jpg (poisson recadré), sans GPS."""
import csv, hashlib, io, os, sys, zipfile, random, urllib.request, concurrent.futures as cf
import numpy as np, cv2, torch
from PIL import Image, ImageOps
ICI = os.path.dirname(os.path.abspath(__file__)); TRAV = os.path.abspath("travail"); os.makedirs(TRAV, exist_ok=True)
UA = {"User-Agent": "FishMe-dataset/0.1 (contact: adembanni@gmail.com)"}
CLASSES = set(open(os.path.join(ICI, "classes_modele.txt")).read().split())
def get(url, dest):
    if not os.path.exists(dest):
        urllib.request.urlretrieve(url, dest)
    return dest
# 1. segmenteur Fishial (MIT)
z = get("https://storage.googleapis.com/fishial-ml-resources/segmentator_fpn_res18_416_1.zip", f"{TRAV}/seg.zip")
zs = zipfile.ZipFile(z)
for n in zs.namelist():
    if n.endswith("model.ts"): zs.extract(n, TRAV)
mts = [os.path.join(r, f) for r, _, fs in os.walk(TRAV) for f in fs if f == "model.ts"][0]
seg = torch.jit.load(mts, map_location="cpu").eval()
MEAN = np.array([0.485, 0.456, 0.406]); STD = np.array([0.229, 0.224, 0.225])
def recadrer(img):
    x = torch.from_numpy(((cv2.resize(img, (416, 416)) / 255.0 - MEAN) / STD).transpose(2, 0, 1)).float()[None]
    with torch.no_grad(): p = seg(x).sigmoid()[0, 0].numpy()
    m = cv2.resize(p, (img.shape[1], img.shape[0])) > 0.5
    n, lab, st, _ = cv2.connectedComponentsWithStats(m.astype(np.uint8))
    if n <= 1: return img
    i = 1 + int(np.argmax(st[1:, cv2.CC_STAT_AREA])); ys, xs = np.where(lab == i)
    if len(xs) / m.size < 0.005: return img
    (cx, cy), (w, h), ang = cv2.minAreaRect(np.stack([xs, ys], 1).astype(np.float32))
    if w < h: w, h = h, w; ang += 90
    w, h = w * 1.08 + 4, h * 1.15 + 4
    rot = cv2.warpAffine(img, cv2.getRotationMatrix2D((cx, cy), ang, 1.0), (img.shape[1], img.shape[0]), borderValue=(124, 116, 104))
    x0, y0 = int(cx - w / 2), int(cy - h / 2)
    c = rot[max(0, y0):int(y0 + h), max(0, x0):int(x0 + w)]
    return c if c.size else img
def est_test(photographe):  # même règle que le cloud : un photographe sur quatre
    return int(hashlib.sha1(photographe.encode()).hexdigest(), 16) % 4 == 0
def ecrire(img, classe, nom, test):
    if classe not in CLASSES: return
    d = os.path.join("createml", "test" if test else "train", classe); os.makedirs(d, exist_ok=True)
    c = recadrer(np.array(img)); im = Image.fromarray(c); im.thumbnail((448, 448))
    im.save(os.path.join(d, nom + ".jpg"), quality=88)  # réencodé : aucun EXIF, aucun GPS
# 2. AFFiNe (CC BY-NC-SA, Kaggle sans compte)
M = {'Cyprinus carpio':'carpe-commune','Aspius aspius':'aspe','Barbus barbus':'barbeau','Leuciscus idus':'ide','Rutilus rutilus':'gardon','Tinca tinca':'tanche','Esox lucius':'brochet','Scardinius erythrophthalmus':'rotengle','Sander lucioperca':'sandre','Acipenseridae':'esturgeon','Ctenopharyngodon idella':'carpe-amour','Leuciscus cephalus':'chevesne','Silurus glanis':'silure','Abramis brama':'breme-commune','Salmo trutta subsp. fario':'truite-commune','Anguilla anguilla':'anguille','Carassius gibelio':'carassin-argente','Lepomis gibbosus':'perche-soleil','Perca fluviatilis':'perche','Blicca bjoerkna':'breme-bordeliere','Neogobius melanostomus':'gobie-invasif','Carassius carassius':'carassin-commun','Gymnocephalus cernuus':'gremille','Gobio gobio':'goujon','Neogobius fluviatilis':'gobie-invasif','Neogobius kessleri':'gobie-invasif','Vimba vimba':'autre-poisson','Leuciscus leuciscus':'vandoise','Gasterosteus aculeatus':'epinoche','Rhodeus amarus':'bouviere'}
za = zipfile.ZipFile(get("https://www.kaggle.com/api/v1/datasets/download/jorritvenema/affine", f"{TRAV}/affine.zip"))
for n in za.namelist():
    if not n.endswith(".jpg"): continue
    sp, fn = n.split("/")[1:3]; u = fn[:36]
    ecrire(ImageOps.exif_transpose(Image.open(io.BytesIO(za.read(n)))).convert("RGB"), M[sp], "aff-" + u, est_test("affine-" + u))
print("AFFiNe fini", flush=True)
# 3. GBIF hors iNaturalist, Observation.org, ADN et musées : liste refaite ici (même règle de test par photographe)
import json, time, urllib.parse
API = "https://api.gbif.org/v1"
EXCLUS = {"50c9509d-22c7-4a22-a47d-8c48425ef4a7", "8a863029-f435-446a-821e-275f4f641165", "b88e40a8-c39e-4f8f-962a-7f6d93a977a4"}
BASES = ["HUMAN_OBSERVATION", "MACHINE_OBSERVATION", "OCCURRENCE", "MATERIAL_SAMPLE"]
def api(path, **p):
    for e in range(5):
        try: return json.load(urllib.request.urlopen(f"{API}{path}?{urllib.parse.urlencode(p, doseq=True)}", timeout=60))
        except Exception: time.sleep(2 ** e)
    return {}
def lignes():
    for ligne in open(os.path.join(ICI, "classes.tsv")).read().splitlines()[1:]:
        cid, nom, latins, _ = ligne.split("	")
        if cid not in CLASSES: continue
        vus = 0
        for latin in latins.split("|"):
            m = api("/species/match", name=latin, kingdom="Animalia", strict="true"); k = m.get("usageKey")
            if not k: continue
            geo = {"continent": "EUROPE"} if m.get("rank") == "GENUS" else {}
            f = api("/occurrence/search", taxonKey=k, mediaType="StillImage", basisOfRecord=BASES, limit=0, facet="datasetKey", facetLimit=500, **geo)
            for fc in (f.get("facets") or [{"counts": []}])[0]["counts"]:
                if fc["name"] in EXCLUS: continue
                off = 0
                while off < fc["count"] and off < 20000 and vus < 1500:
                    pg = api("/occurrence/search", taxonKey=k, mediaType="StillImage", basisOfRecord=BASES, datasetKey=fc["name"], limit=300, offset=off, **geo)
                    for o in pg.get("results", []):
                        for md in o.get("media", []):
                            if md.get("type") != "StillImage" or not md.get("identifier"): continue
                            ph = (o.get("recordedBy") or md.get("rightsHolder") or md.get("creator") or "").strip().lower() or md["identifier"]
                            vus += 1
                            yield cid, hashlib.sha1(md["identifier"].encode()).hexdigest()[:16], md["identifier"], ph
                    off += 300
                    if pg.get("endOfRecords", True): break
def un(t):
    classe, h, url, phot = t
    try:
        data = urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30).read(30_000_000)
        im = ImageOps.exif_transpose(Image.open(io.BytesIO(data))).convert("RGB"); im.thumbnail((640, 640))
        ecrire(im, classe, h, est_test(phot))
    except Exception as e:
        print("erreur", url[:60], type(e).__name__)
with cf.ThreadPoolExecutor(8) as ex: list(ex.map(un, lignes()))
print("fini : dossier createml/ prêt")
