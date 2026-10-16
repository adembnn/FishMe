import torch,numpy as np,pickle,cv2,json,os,sys
import coremltools as ct
from PIL import Image
from transformers import AutoModel
torch.set_num_threads(2)
coef,b,cl,xe,P,photos=pickle.load(open("m.pkl","rb"))
dino=AutoModel.from_pretrained("facebook/dinov2-small",attn_implementation="eager").eval()
with torch.no_grad():
    pe=dino.embeddings.interpolate_pos_encoding(torch.zeros(1,257,384),224,224).clone()
dino.embeddings.interpolate_pos_encoding=lambda emb,h,w:pe
class M(torch.nn.Module):
    def __init__(s):
        super().__init__();s.d=dino
        s.register_buffer("mean",torch.tensor([0.485,0.456,0.406]).view(1,3,1,1)*255)
        s.register_buffer("std",torch.tensor([0.229,0.224,0.225]).view(1,3,1,1)*255)
        s.lin=torch.nn.Linear(768,len(cl));s.lin.weight.data=torch.tensor(coef,dtype=torch.float32);s.lin.bias.data=torch.tensor(b,dtype=torch.float32)
    def feat(s,x):
        o=s.d(pixel_values=(x-s.mean)/s.std)
        v=torch.cat([o.pooler_output,o.last_hidden_state[:,1:].mean(1)],1)
        return v/v.norm(dim=1,keepdim=True)
    def forward(s,x): return torch.softmax(s.lin(s.feat(x)),1)
m=M().eval()
# check
DM=np.array([0.485,0.456,0.406]);DS=np.array([0.229,0.224,0.225])
def prep(crop):
    h,w=crop.shape[:2];s=max(h,w);sq=np.full((s,s,3),(124,116,104),np.uint8);sq[(s-h)//2:(s-h)//2+h,(s-w)//2:(s-w)//2+w]=crop
    return cv2.resize(sq,(224,224),interpolation=cv2.INTER_AREA)
X=np.fromfile("d.f32",dtype=np.float32).reshape(-1,768);fs=[json.loads(l)["f"] for l in open("j.jsonl")]
idx={f:i for i,f in enumerate(fs[:len(X)])}
rng=np.random.RandomState(0);sel=rng.choice(len(photos),20,replace=False)
cos=[];agree=0;mp=[]
for i in sel:
    f=photos[i];p="/root/fishdata/traite_carres/"+f.replace("/","__")
    a=prep(np.array(Image.open(p).convert("RGB")))
    x=torch.from_numpy(a.transpose(2,0,1).astype(np.float32))[None]
    with torch.no_grad(): v=m.feat(x)[0].numpy();pr=m(x)[0].numpy()
    ref=X[idx[f]];ref=ref/np.linalg.norm(ref);cos.append(float(v@ref))
    agree+=int(pr.argmax()==P[i].argmax());mp.append(float(np.abs(pr-P[i]).max()))
print("cos min/mean",min(cos),np.mean(cos),"argmax agree",agree,"/20 max|dp|",max(mp))
ex=torch.rand(1,3,224,224)*255
with torch.no_grad(): tr=torch.jit.trace(m,ex,check_trace=False)
with torch.no_grad(): print("trace diff",float((tr(x)-m(x)).abs().max()))
ml=ct.convert(tr,inputs=[ct.ImageType(name="image",shape=(1,3,224,224),color_layout=ct.colorlayout.RGB,scale=1.0)],
  classifier_config=ct.ClassifierConfig(cl),convert_to="mlprogram",minimum_deployment_target=ct.target.iOS17,compute_precision=ct.precision.FLOAT16)
out="/mnt/project-files/build/reconnaissance/coreml/v2";os.makedirs(out,exist_ok=True)
ml.short_description="Classifieur d'especes de poissons d'eau douce (DINOv2-small + regression logistique)"
ml.save(out+"/PoissonsDino.mlpackage")
import coremltools.optimize.coreml as cto
q=cto.linear_quantize_weights(ml,cto.OptimizationConfig(global_config=cto.OpLinearQuantizerConfig(mode="linear_symmetric",dtype="int8")))
q.save(out+"/PoissonsDino-int8.mlpackage")
open(out+"/labels.txt","w").write("\n".join(cl)+"\n")
