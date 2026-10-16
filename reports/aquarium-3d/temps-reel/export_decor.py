"""Exporte le décor de l'aquarium v2 en un .glb léger (16 oct.) : sol, roches, bois, plantes, herbiers.
Sans eau, lumières ni poissons (le temps réel les fait lui-même).
blender -b --python export_decor.py -- <sortie.glb>"""
import sys, os, bpy
SORTIE_GLB = sys.argv[sys.argv.index("--") + 1]
SCENE = "/mnt/project-files/build/aquarium/3d/v2/aquarium/scene.py"
sys.argv = [sys.argv[0], "--", "--vue", "1", "--sans-poissons", "--out", "/tmp/claude-0/decor-tmp.blend"]
exec(compile(open(SCENE).read(), SCENE, "exec"))

for o in list(bpy.data.objects):
    if o.type != "MESH" or o.hide_render or o.name in ("eau",) or o.name.startswith(("Plane", "Sphere")):
        bpy.data.objects.remove(o)

def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)

sol = bpy.data.objects["sol"]
bpy.context.view_layer.objects.active = sol
bpy.ops.object.modifier_apply(modifier="relief")
# sol : matériau simple (couleur + normales), exportable
m = sol.data.materials[0]; nt = m.node_tree; b = nt.nodes["Principled BSDF"]
for n in nt.nodes:
    if n.type == "TEX_IMAGE" and n.image.filepath.endswith("couleur.jpg"):
        nt.links.new(n.outputs["Color"], b.inputs["Base Color"])
    if n.type == "TEX_IMAGE" and ("rugosite" in n.image.filepath or "ao.jpg" in n.image.filepath):
        for l in list(n.outputs[0].links): nt.links.remove(l)
b.inputs["Roughness"].default_value = 0.8

total = 0
for o in [o for o in bpy.data.objects if o.type == "MESH"]:
    if o.data.users > 1:
        o.data = o.data.copy()
    cible = 14000 if o.name == "sol" else (6000 if o.name == "herbier" else 2500)
    t = tris(o)
    if t > cible:
        d = o.modifiers.new("dec", "DECIMATE"); d.ratio = cible / t
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier="dec")
    total += tris(o)
    print("DECOR", o.name, tris(o))
for mt in bpy.data.materials:
    if not mt.use_nodes: continue
    bs = [n for n in mt.node_tree.nodes if n.type == "BSDF_PRINCIPLED"]
    for bb in bs:
        for nom in ("Roughness", "Metallic"):
            for l in list(bb.inputs[nom].links): mt.node_tree.links.remove(l)
        bb.inputs["Roughness"].default_value = 0.8; bb.inputs["Metallic"].default_value = 0.0
for im in bpy.data.images:
    if im.size[0] > 1024:
        im.scale(1024, max(1, im.size[1] * 1024 // im.size[0]))
print("TOTAL", total)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=SORTIE_GLB, export_format="GLB", use_selection=True, export_image_format="WEBP",
                          export_apply=True, export_animations=False, export_morph=False)
