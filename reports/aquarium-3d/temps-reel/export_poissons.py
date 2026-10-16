"""Exporte un poisson léger par espèce en .glb pour le temps réel (16 oct.).
Longueur 1 m (on met à l'échelle à l'écran), tête +X, dos +Y, flancs ±Z une fois en glTF.
blender -b --python export_poissons.py -- <dossier_sortie> [grille]"""
import sys, os, bpy
sys.path.insert(0, "/mnt/project-files/build/aquarium/3d")
import fishkit2 as fk
A = sys.argv[sys.argv.index("--") + 1:]
OUT = A[0]; GRILLE = int(A[1]) if len(A) > 1 else 90
os.makedirs(OUT, exist_ok=True)
ESPECES = ["brochet", "carpe-commune", "truite-fario", "sandre", "tanche", "perche", "gardon", "rotengle",
           "chevesne", "black-bass", "breme-commune", "ablette"]

def image_reduite(chemin, largeur, data=False):
    im = bpy.data.images.load(chemin)
    if data: im.colorspace_settings.name = "Non-Color"
    w, h = im.size
    im.scale(largeur, max(1, round(h * largeur / w)))
    return im

for sp in ESPECES:
    fk.scene_vide(); fk._CORNEE = None
    p = fk.poisson(sp, longueur=1.0, largeur_grille=GRILLE, lissage=0)
    m = bpy.data.materials.new("peau-" + sp); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexImage"); tc.image = image_reduite(os.path.join(fk.PROPRES, sp + "-couleur.png"), 1024)
    tn = nt.nodes.new("ShaderNodeTexImage"); tn.image = image_reduite(os.path.join(fk.PROPRES, sp + "-normale.png"), 1024, True)
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(tc.outputs["Color"], b.inputs["Base Color"]); nt.links.new(tc.outputs["Alpha"], b.inputs["Alpha"])
    nt.links.new(tn.outputs["Color"], nm.inputs["Color"]); nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    b.inputs["Roughness"].default_value = 0.42
    m.blend_method = "CLIP" if hasattr(m, "blend_method") else None
    p.data.materials.clear(); p.data.materials.append(m)
    oeil = bpy.data.materials.new("oeil"); oeil.use_nodes = True
    ob = oeil.node_tree.nodes["Principled BSDF"]; ob.inputs["Base Color"].default_value = (0.01, 0.01, 0.01, 1)
    ob.inputs["Roughness"].default_value = 0.05
    for c in p.children:
        c.data.materials.clear(); c.data.materials.append(oeil)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, sp + ".glb"), export_format="GLB", use_selection=True,
                              export_image_format="WEBP", export_apply=True, export_animations=False,
                              export_morph=False)
    tris = sum(len(pl.vertices) - 2 for pl in p.data.polygons)
    print("POISSON", sp, tris, "triangles")
