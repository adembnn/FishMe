"""Pour chaque photo : masque Fishial -> recadrage -> vecteurs Fishial (768) et DINOv2-S (384) + top-5 Fishial.
usage: traiter.py dossier_photos sortie_prefixe   (reprend là où il s'est arrêté)"""
import sys, os, glob, json, numpy as np, torch, cv2
from PIL import Image
sys.path.insert(0, "/tmp/claude-0/reco/scripts")
import fishial as FI
from transformers import AutoModel
torch.set_num_threads(int(os.environ.get("NT","4")))
dino = AutoModel.from_pretrained("facebook/dinov2-small").eval()
DM = np.array([0.485, 0.456, 0.406]); DS = np.array([0.229, 0.224, 0.225])
def dino_vec(crop):
    h, w = crop.shape[:2]; s = max(h, w)  # carré avec bord neutre, comme dans l'app
    sq = np.full((s, s, 3), (124, 116, 104), np.uint8); sq[(s-h)//2:(s-h)//2+h, (s-w)//2:(s-w)//2+w] = crop
    x = torch.from_numpy(((cv2.resize(sq, (224, 224), interpolation=cv2.INTER_AREA) / 255 - DM) / DS).transpose(2, 0, 1)).float()[None]
    with torch.no_grad(): o = dino(pixel_values=x)
    return torch.cat([o.pooler_output, o.last_hidden_state[:, 1:].mean(1)], 1)[0].numpy()
src, pre = sys.argv[1], sys.argv[2]
files = [l.strip() for l in open(sys.argv[3])] if len(sys.argv) > 3 else sorted(glob.glob(src + "/*/*.jpg"))
files = [f if f.startswith("/") else os.path.join(src, f) for f in files]
done = set()
if os.path.exists(pre + ".jsonl"):
    done = {json.loads(l)["f"] for l in open(pre + ".jsonl")}
fo = open(pre + ".jsonl", "a"); vf = open(pre + ".fishial.f32", "ab"); vd = open(pre + ".dino.f32", "ab")
os.makedirs(pre + "_carres", exist_ok=True)
for i, f in enumerate(files):
    rel = os.path.relpath(f, src)
    if rel in done: continue
    try:
        img = np.array(Image.open(f).convert("RGB"))
        m, s = FI.masque(img); crop, b = FI.recadre(img, m)
        poisson = crop is not None and b[4] > 0.005
        if not poisson: crop = img; b = (0, 0, img.shape[1], img.shape[0], 0.0)
        with torch.no_grad(): out = FI.cls(FI.norm(cv2.resize(crop, (434, 154)))[None])
        emb, logits = out[0], out[-1]
        pr = logits.softmax(-1)[0]; v, k = pr.topk(5)
        top = [[FI.MAP[int(j)]["label"], round(float(x), 4)] for x, j in zip(v, k)]
        dv = dino_vec(crop)
        e = torch.nn.functional.normalize(emb, dim=1)[0].numpy()
        vf.write(e.astype(np.float32).tobytes()); vd.write(dv.astype(np.float32).tobytes())
        c = Image.fromarray(crop); c.thumbnail((448, 448)); cp = os.path.join(pre + "_carres", rel.replace("/", "__"))
        c.save(cp, quality=85)
        fo.write(json.dumps({"f": rel, "classe": rel.split("/")[0], "poisson": bool(poisson), "masque": round(s, 3),
                             "frac": round(float(b[4]), 4), "boite": [int(x) for x in b[:4]], "fishial": top}) + "\n")
    except Exception as ex:
        print("erreur", rel, ex, flush=True)
    if i % 200 == 0:
        fo.flush(); vf.flush(); vd.flush(); print(i, len(files), flush=True)
fo.close(); vf.close(); vd.close(); print("fini")
