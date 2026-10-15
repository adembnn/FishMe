import time, torch, sys, glob
from PIL import Image
from transformers import Owlv2Processor, Owlv2ForObjectDetection
torch.set_num_threads(4)
m="google/owlv2-base-patch16-ensemble"
p=Owlv2Processor.from_pretrained(m); mod=Owlv2ForObjectDetection.from_pretrained(m).eval()
for f in sorted(glob.glob(sys.argv[1]+"/*.jpg")):
    im=Image.open(f).convert("RGB"); t=time.time()
    inp=p(text=[["a photo of a fish"]],images=im,return_tensors="pt")
    with torch.no_grad(): out=mod(**inp)
    W,H=im.size; s=max(W,H)
    r=p.post_process_grounded_object_detection(out,threshold=0.1,target_sizes=torch.tensor([[s,s]]))[0]
    print(f, im.size, round(time.time()-t,2), [ (round(x.item(),2), [int(v) for v in b]) for x,b in zip(r['scores'][:3],r['boxes'][:3])])
