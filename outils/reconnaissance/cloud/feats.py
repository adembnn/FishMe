import sys, os, csv, numpy as np, torch, time
from PIL import Image
from transformers import AutoModel
torch.set_num_threads(int(os.environ.get("NT","4")))
dino = AutoModel.from_pretrained("facebook/dinov2-small").eval()
M = torch.tensor([0.485,0.456,0.406]).view(1,3,1,1); S = torch.tensor([0.229,0.224,0.225]).view(1,3,1,1)
mode = sys.argv[1]  # fill | crop
lst = [l.strip() for l in open(sys.argv[2])]; out = sys.argv[3]
def load(p):
    im = Image.open(p).convert("RGB")
    if mode == "fill": im = im.resize((224,224), Image.BILINEAR)
    else:
        w,h = im.size; s=min(w,h); im = im.crop(((w-s)//2,(h-s)//2,(w-s)//2+s,(h-s)//2+s)).resize((224,224), Image.BILINEAR)
    return torch.from_numpy(np.asarray(im).copy()).permute(2,0,1).float()/255
done = 0; F = np.zeros((len(lst),768), np.float32); ok = np.zeros(len(lst), bool)
if os.path.exists(out+".part.npz"):
    z = np.load(out+".part.npz"); F, ok = z["F"], z["ok"]
t=time.time(); B=32
for i in range(0, len(lst), B):
    if ok[i:i+B].all(): continue
    xs=[]; idx=[]
    for j in range(i, min(i+B,len(lst))):
        try: xs.append(load(lst[j])); idx.append(j)
        except Exception as e: print("err", lst[j], e)
    x = (torch.stack(xs)-M)/S
    with torch.no_grad(): o = dino(pixel_values=x)
    f = torch.cat([o.pooler_output, o.last_hidden_state[:,1:].mean(1)], 1).numpy()
    F[idx]=f; ok[idx]=True
    if (i//B)%20==0:
        np.savez(out+".part.npz", F=F, ok=ok); print(i, len(lst), round(time.time()-t), flush=True)
np.savez(out, F=F, ok=ok); print("fini")
