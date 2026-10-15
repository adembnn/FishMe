"""Construit le modèle Core ML : image 224x224 -> DINOv2-S (CLS + moyenne des patchs) -> L2 -> tête linéaire -> softmax.
usage: convert.py tete.npz sortie.mlpackage [quant8]"""
import sys, numpy as np, torch, coremltools as ct
from transformers import AutoModel
class Net(torch.nn.Module):
    def __init__(s, W1, b1, W2, b2, T):
        super().__init__()
        s.d = AutoModel.from_pretrained("facebook/dinov2-small", attn_implementation="eager").eval()
        s.register_buffer("m", torch.tensor([0.485,0.456,0.406]).view(1,3,1,1)); s.register_buffer("s", torch.tensor([0.229,0.224,0.225]).view(1,3,1,1))
        s.fc1 = torch.nn.Linear(768, W1.shape[0]); s.fc1.weight.data = torch.tensor(W1); s.fc1.bias.data = torch.tensor(b1)
        s.fc2 = torch.nn.Linear(W1.shape[0], W2.shape[0]); s.fc2.weight.data = torch.tensor(W2); s.fc2.bias.data = torch.tensor(b2); s.T = T
        with torch.no_grad():
            e = s.d.embeddings; p = e.position_embeddings  # (1,1+37*37,384)
            g = p[:, 1:].reshape(1, 37, 37, 384).permute(0, 3, 1, 2)
            g = torch.nn.functional.interpolate(g, size=(16, 16), mode="bicubic", align_corners=False, antialias=False)
            s.register_buffer("pos", torch.cat([p[:, :1], g.permute(0, 2, 3, 1).reshape(1, 256, 384)], 1).clone())
    def forward(s, x):  # x in [0,1]
        e = s.d.embeddings
        h = e.patch_embeddings.projection((x - s.m) / s.s).flatten(2).transpose(1, 2)
        h = torch.cat([e.cls_token.expand(1, -1, -1), h], 1) + s.pos
        for l in s.d.encoder.layer: h = l(h)
        h = s.d.layernorm(h)
        f = torch.cat([h[:, 0], h[:, 1:].mean(1)], 1)
        f = f / f.norm(dim=1, keepdim=True)
        return torch.softmax(s.fc2(torch.nn.functional.gelu(s.fc1(f))) / s.T, dim=1)
if __name__ == "__main__":
    z = np.load(sys.argv[1], allow_pickle=True); net = Net(*[z[k].astype(np.float32) for k in ("W1","b1","W2","b2")], float(z["T"])).eval()
    ex = torch.rand(1, 3, 224, 224)
    tr = torch.jit.trace(net, ex)
    ml = ct.convert(tr, inputs=[ct.ImageType(name="image", shape=(1,3,224,224), scale=1/255.0, color_layout=ct.colorlayout.RGB)],
                    classifier_config=ct.ClassifierConfig([str(c) for c in z["classes"]]), convert_to="mlprogram", minimum_deployment_target=ct.target.iOS17,
                    compute_precision=ct.precision.FLOAT16)
    if len(sys.argv) > 3 and sys.argv[3] == "quant8":
        import coremltools.optimize.coreml as cto
        cfg = cto.OptimizationConfig(global_config=cto.OpLinearQuantizerConfig(mode="linear_symmetric", dtype="int8", granularity="per_channel"))
        ml = cto.linear_quantize_weights(ml, cfg)
    ml.short_description = "FishMe : reconnaissance d'espece (DINOv2-S + tete lineaire). Classes dans classes.txt, dans l'ordre des sorties."
    ml.save(sys.argv[2]); print("ok")
