import zipfile, io, os, urllib.request
from PIL import Image, ImageOps
M = {'Cyprinus carpio':'carpe-commune','Aspius aspius':'aspe','Barbus barbus':'barbeau','Leuciscus idus':'ide','Rutilus rutilus':'gardon','Tinca tinca':'tanche','Esox lucius':'brochet','Scardinius erythrophthalmus':'rotengle','Sander lucioperca':'sandre','Acipenseridae':'esturgeon','Ctenopharyngodon idella':'carpe-amour','Leuciscus cephalus':'chevesne','Silurus glanis':'silure','Abramis brama':'breme-commune','Salmo trutta subsp. fario':'truite-commune','Anguilla anguilla':'anguille','Carassius gibelio':'carassin-argente','Lepomis gibbosus':'perche-soleil','Perca fluviatilis':'perche','Blicca bjoerkna':'breme-bordeliere','Neogobius melanostomus':'gobie-invasif','Carassius carassius':'carassin-commun','Gymnocephalus cernuus':'gremille','Gobio gobio':'goujon','Neogobius fluviatilis':'gobie-invasif','Neogobius kessleri':'gobie-invasif','Vimba vimba':'autre-poisson','Leuciscus leuciscus':'vandoise','Gasterosteus aculeatus':'epinoche','Rhodeus amarus':'bouviere'}
d="/home/user/r1/affine.zip"
if not os.path.exists(d): urllib.request.urlretrieve("https://www.kaggle.com/api/v1/datasets/download/jorritvenema/affine", d)
za=zipfile.ZipFile(d); n=0
for f in za.namelist():
    if not f.endswith(".jpg"): continue
    sp,fn=f.split("/")[1:3]; u=fn[:36]
    c=M.get(sp)
    if not c: continue
    p=f"/home/user/r1/photos/{c}/aff-{u}.jpg"
    if os.path.exists(p): continue
    os.makedirs(os.path.dirname(p),exist_ok=True)
    im=ImageOps.exif_transpose(Image.open(io.BytesIO(za.read(f)))).convert("RGB"); im.thumbnail((640,640)); im.save(p,"JPEG",quality=88); n+=1
print("affine",n)
