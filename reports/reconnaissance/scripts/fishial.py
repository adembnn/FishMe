"""Recadrage (segmenteur Fishial) + classifieur Fishial, sur CPU."""
import json, os, sys, glob, time, numpy as np, torch, cv2
from PIL import Image
torch.set_num_threads(int(os.environ.get("NT","4")))
F = "/root/fishdata/fishial/"
seg = torch.jit.load(F + "segmentator_fpn_res18_416_1/model.ts", map_location="cpu").eval()
cls = torch.jit.load(F + "classification_model_v0.10.2/model.pt", map_location="cpu").eval()
MAP = {int(k): v for k, v in json.loads(bytes(cls.class_mapping_json_bytes.cpu().tolist()).decode()).items()}
MEAN = np.array([0.485, 0.456, 0.406]); STD = np.array([0.229, 0.224, 0.225])
def norm(a): return torch.from_numpy(((a / 255.0 - MEAN) / STD).transpose(2, 0, 1)).float()

def masque(img):  # img RGB uint8 HxWx3 -> masque bool, score
    x = norm(cv2.resize(img, (416, 416), interpolation=cv2.INTER_LINEAR))[None]
    with torch.no_grad(): p = seg(x).sigmoid()[0, 0].numpy()
    p = cv2.resize(p, (img.shape[1], img.shape[0]))
    return p > 0.5, float(p.max())

def recadre(img, m):
    """Plus grande composante -> rectangle tourné -> poisson à l'horizontale, 154x434."""
    n, lab, st, _ = cv2.connectedComponentsWithStats(m.astype(np.uint8))
    if n <= 1: return None, None
    i = 1 + int(np.argmax(st[1:, cv2.CC_STAT_AREA]))
    ys, xs = np.where(lab == i)
    frac = len(xs) / m.size
    pts = np.stack([xs, ys], 1).astype(np.float32)
    (cx, cy), (w, h), ang = cv2.minAreaRect(pts)
    if w < h: w, h = h, w; ang += 90
    w, h = w * 1.08 + 4, h * 1.15 + 4
    M = cv2.getRotationMatrix2D((cx, cy), ang, 1.0)
    rot = cv2.warpAffine(img, M, (img.shape[1], img.shape[0]), borderValue=(124, 116, 104))
    x0, y0 = int(cx - w / 2), int(cy - h / 2)
    crop = rot[max(0, y0):int(y0 + h), max(0, x0):int(x0 + w)]
    if crop.size == 0: return None, None
    return crop, (xs.min(), ys.min(), xs.max(), ys.max(), frac)

def classe(crop):
    x = norm(cv2.resize(crop, (434, 154)))[None]
    with torch.no_grad(): out = cls(x)
    return out

if __name__ == "__main__":
    for f in sorted(glob.glob(sys.argv[1] + "/*.jpg")):
        img = np.array(Image.open(f).convert("RGB")); t = time.time()
        m, s = masque(img); crop, b = recadre(img, m)
        if crop is None: print(f, "pas de poisson"); continue
        out = classe(crop)
        if isinstance(out, (tuple, list)): emb, logits = out[0], out[-1]
        else: logits = out; emb = None
        pr = logits.softmax(-1)[0]; v, k = pr.topk(3)
        print(f, round(time.time() - t, 2), "masque", round(s, 2), "frac", round(b[4], 3),
              [(MAP[int(i)]["label"] if isinstance(MAP[int(i)], dict) else MAP[int(i)], round(float(x), 2)) for x, i in zip(v, k)],
              None if emb is None else tuple(emb.shape))
        Image.fromarray(crop).save(f.replace(".jpg", ".crop.png"))
