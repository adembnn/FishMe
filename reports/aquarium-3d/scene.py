"""Aquarium « Voir mon aquarium », v2 (16 oct.) : poissons fishkit2 + décor CC0 (Poly Haven, ambientCG).
blender -b --python scene.py -- --vue 1|2|3 --res 1080x1920 --samples 96 --frame 9 --out vue-1.png"""
import sys, math, os, random
import bpy
sys.path.insert(0, "/mnt/project-files/build/aquarium/3d")
import fishkit2 as fk

A = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def arg(n, d):
    return A[A.index(n) + 1] if n in A else d
VUE = arg("--vue", "1"); RES = arg("--res", "540x960"); SPP = int(arg("--samples", "32"))
FRAME = int(arg("--frame", "9")); OUT = arg("--out", "/tmp/aq.png")
SANS = "--sans-poissons" in A
RW, RH = (int(x) for x in RES.split("x"))
LARGE = RW / RH > 1.2
DEC = "/mnt/project-files/build/aquarium/3d/decor/"
random.seed(7)

sc = fk.scene_vide()
# bac : X 0..±0.45 (largeur 0.9), Y 0 (vitre) .. 0.5 (fond), Z 0..0.62
LX, LY, LZ = 0.9, 0.5, 0.72

def img(p, data=False):
    i = bpy.data.images.load(p, check_existing=True)
    if data: i.colorspace_settings.name = "Non-Color"
    return i

def mat_pbr(nom, dossier, echelle, disp=None):
    m = bpy.data.materials.new(nom); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]; N = nt.nodes.new; L = nt.links.new
    tc = N("ShaderNodeTexCoord"); mp = N("ShaderNodeMapping"); mp.inputs["Scale"].default_value = (echelle,) * 3
    L(tc.outputs["UV"], mp.inputs["Vector"])
    def t(f, data=False):
        x = N("ShaderNodeTexImage"); x.image = img(DEC + dossier + "/" + f, data); L(mp.outputs[0], x.inputs[0]); return x
    c = t("couleur.jpg"); ao = t("ao.jpg", True)
    mul = N("ShaderNodeMix"); mul.data_type = "RGBA"; mul.blend_type = "MULTIPLY"; mul.inputs["Factor"].default_value = 0.8
    L(c.outputs[0], mul.inputs[6]); L(ao.outputs[0], mul.inputs[7]); L(mul.outputs[2], b.inputs["Base Color"])
    L(t("rugosite.jpg", True).outputs[0], b.inputs["Roughness"])
    nm = N("ShaderNodeNormalMap"); L(t("normale.jpg", True).outputs[0], nm.inputs["Color"]); L(nm.outputs[0], b.inputs["Normal"])
    return m

# ---------- sol : galets réels à l'échelle, pente vers le fond
bpy.ops.mesh.primitive_grid_add(x_subdivisions=360, y_subdivisions=200, size=1)
sol = bpy.context.object; sol.name = "sol"; sol.scale = ((2.4 if LARGE else LX + 0.2), LY + 0.4, 1); sol.location = (0, LY / 2 - 0.15, 0)
bpy.ops.object.transform_apply(scale=True)
for v in sol.data.vertices:
    y = max(0.0, (v.co.y + (LY + 0.4) / 2 - 0.3) / (LY + 0.1))
    v.co.z = 0.035 + 0.09 * y ** 1.6 + 0.012 * math.sin(v.co.x * 9 + 1.3) * y
bpy.ops.object.shade_smooth()
sol.data.materials.append(mat_pbr("galets", "sol-galets-riviere", (LX + 0.2) / 2.16 * 3.2))
tx = bpy.data.textures.new("h", "IMAGE"); tx.image = img(DEC + "sol-galets-riviere/hauteur.jpg", True)
dm = sol.modifiers.new("relief", "DISPLACE"); dm.texture = tx; dm.texture_coords = "UV"; dm.strength = 0.006; dm.mid_level = 0.5
sol.data.uv_layers.active.data.foreach_set("uv", [c * ((LX + 0.2) / 2.16 * 3.2) for lp in sol.data.uv_layers.active.data for c in lp.uv])
# l'image du relief doit suivre la même échelle que la couleur : on a mis l'échelle dans les UV, on remet le Mapping à 1
sol.data.materials[0].node_tree.nodes["Mapping"].inputs["Scale"].default_value = (1, 1, 1)

def hauteur_sol(x, y):
    yy = min(max(y / (LY + 0.1), 0), 1)
    return 0.035 + 0.09 * yy ** 1.6

def importe(id_):
    avant = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=f"{DEC}modeles/{id_}/{id_}_2k.gltf")
    neufs = [o for o in bpy.data.objects if o not in avant]
    objs = [o for o in neufs if o.type == "MESH"]
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        mw = o.matrix_world.copy(); o.parent = None; o.matrix_world = mw
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for o in neufs:
        if o.type != "MESH":
            bpy.data.objects.remove(o)
    for o in objs:
        # origine au centre du dessous de l'objet, posé à z = 0
        xs = [v.co.x for v in o.data.vertices]; ys = [v.co.y for v in o.data.vertices]; zs = [v.co.z for v in o.data.vertices]
        cx, cy, z0 = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(zs)
        o.data.transform(__import__("mathutils").Matrix.Translation((-cx, -cy, -z0)))
        o.location = (0, 0, 0)
        o.hide_render = o.hide_viewport = True
    return objs

def pose(src, loc, s, rz=0.0, rx=0.0, enfonce=0.25):
    o = src.copy(); bpy.context.scene.collection.objects.link(o)
    o.hide_render = o.hide_viewport = False
    hz = max(v.co.z for v in src.data.vertices) * s
    loc = (loc[0], loc[1], hauteur_sol(loc[0], loc[1]) - enfonce * hz)
    o.location = loc; o.scale = (s, s, s); o.rotation_euler = (rx, 0, rz)
    return o

roches = importe("rock_moss_set_02") + importe("rock_moss_set_01")
boules = importe("namaqualand_boulders_01")
branche = importe("dead_quiver_branch_01")
souche = importe("tree_stump_01")
herbe = importe("weed_plant_02")
fougere = importe("fern_02")

# composition : massif rocheux à gauche-fond, bois flotté au centre, plantes au fond et à droite
pose(roches[0], (-0.30, 0.38, 0.07), 0.19, 0.6)
pose(roches[3], (-0.13, 0.43, 0.08), 0.15, 2.0)
pose(roches[1], (-0.38, 0.22, 0.05), 0.10, 1.1)
pose(roches[7], (0.27, 0.40, 0.09), 0.13, -0.4)
pose(roches[5], (0.20, 0.26, 0.06), 0.09, 0.9)
for i, (x, y, s) in enumerate([(0.05, 0.12, 0.13), (-0.08, 0.08, 0.10), (0.36, 0.14, 0.12), (-0.25, 0.10, 0.09)]):
    pose(boules[i % len(boules)], (x, y, 0), s * 2.0, random.uniform(0, 6))
b = pose(branche[0], (0.02, 0.33, 0.10), 0.62, 0.5, 0.0)
s = pose(souche[0], (0.40, 0.46, 0.07), 0.16, 2.6)
for x, y, sc_ in [(-0.36, 0.44, 1.4), (-0.05, 0.47, 1.6), (0.14, 0.45, 1.3), (0.33, 0.30, 1.0), (-0.22, 0.30, 1.0), (0.42, 0.20, 0.8)]:
    pose(herbe[random.randrange(len(herbe))], (x, y, 0), sc_ * 1.3, random.uniform(0, 6), enfonce=0.1)
for x, y in [(-0.42, 0.48), (0.24, 0.49), (0.0, 0.49)]:
    pose(fougere[random.randrange(len(fougere))], (x, y, 0), 0.6, random.uniform(0, 6), enfonce=0.05)


# ---------- vallisnéries : rubans fins qui montent du fond (faits ici : aucune plante aquatique CC0)
import bmesh
def herbier(cx, cy, n, h0, h1, rayon):
    bm = bmesh.new()
    for k in range(n):
        x = cx + random.uniform(-rayon, rayon); y = cy + random.uniform(-rayon * 0.5, rayon * 0.5)
        h = random.uniform(h0, h1); lw = random.uniform(0.004, 0.007)
        ang = random.uniform(0, math.pi); dx, dy = math.cos(ang), math.sin(ang)
        pench = random.uniform(-0.25, 0.25); z0 = hauteur_sol(x, y) - 0.01
        prec = None
        for i in range(15):
            t = i / 14
            px = x + pench * h * t * t * 0.6 + 0.01 * math.sin(t * 5 + k)
            py = y + 0.02 * math.sin(t * 3 + k * 0.7)
            pz = z0 + h * t
            w = lw * (1 - 0.65 * t ** 2)
            a = bm.verts.new((px - dx * w, py - dy * w, pz)); b = bm.verts.new((px + dx * w, py + dy * w, pz))
            if prec:
                bm.faces.new((prec[0], prec[1], b, a))
            prec = (a, b)
    me = bpy.data.meshes.new("herbier"); bm.to_mesh(me); bm.free()
    uv = me.uv_layers.new()
    o = bpy.data.objects.new("herbier", me); bpy.context.scene.collection.objects.link(o)
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    o.data.materials.append(mat_herbe)
    return o

mat_herbe = bpy.data.materials.new("herbe"); mat_herbe.use_nodes = True; nt = mat_herbe.node_tree
bh = nt.nodes["Principled BSDF"]; bh.inputs["Roughness"].default_value = 0.45
fk._set(bh, "Subsurface Weight", 0.0)
gc = nt.nodes.new("ShaderNodeNewGeometry"); sz = nt.nodes.new("ShaderNodeSeparateXYZ"); rp = nt.nodes.new("ShaderNodeValToRGB")
nt.links.new(gc.outputs["Position"], sz.inputs[0])
mr = nt.nodes.new("ShaderNodeMapRange"); mr.inputs["From Min"].default_value = 0.05; mr.inputs["From Max"].default_value = 0.5
nt.links.new(sz.outputs["Z"], mr.inputs["Value"]); nt.links.new(mr.outputs[0], rp.inputs[0])
rp.color_ramp.elements[0].color = (0.035, 0.09, 0.03, 1); rp.color_ramp.elements[1].color = (0.32, 0.50, 0.12, 1)
nt.links.new(rp.outputs[0], bh.inputs["Base Color"])
tr = nt.nodes.new("ShaderNodeBsdfTranslucent"); nt.links.new(rp.outputs[0], tr.inputs["Color"])
mx = nt.nodes.new("ShaderNodeMixShader"); mx.inputs[0].default_value = 0.35
out = nt.nodes["Material Output"]
nt.links.new(bh.outputs[0], mx.inputs[1]); nt.links.new(tr.outputs[0], mx.inputs[2]); nt.links.new(mx.outputs[0], out.inputs["Surface"])
mat_herbe.use_backface_culling = False
herbier(-0.38, 0.46, 40, 0.30, 0.52, 0.07)
herbier(0.08, 0.48, 30, 0.25, 0.45, 0.06)
herbier(0.38, 0.36, 25, 0.18, 0.36, 0.05)
herbier(-0.10, 0.46, 18, 0.15, 0.30, 0.04)
if LARGE:
    herbier(-0.75, 0.44, 35, 0.25, 0.50, 0.08); herbier(0.72, 0.42, 30, 0.22, 0.45, 0.07)
    herbier(-0.55, 0.30, 14, 0.12, 0.25, 0.04); herbier(0.58, 0.30, 14, 0.12, 0.26, 0.04)
    pose(roches[2], (-0.62, 0.38, 0), 0.17, 1.4); pose(roches[4], (0.62, 0.40, 0), 0.15, 0.3)


# ---------- surface de l'eau vue de dessous (reflet total, petites rides)
bpy.ops.mesh.primitive_plane_add(size=1, location=(0, LY / 2 - 0.2, LZ))
surf = bpy.context.object; surf.scale = ((3.2 if LARGE else LX + 0.8), LY + 0.6, 1)
ms = bpy.data.materials.new("surface"); ms.use_nodes = True; nt = ms.node_tree; bs = nt.nodes["Principled BSDF"]
bs.inputs["Roughness"].default_value = 0.04; bs.inputs["IOR"].default_value = 1.33; fk._set(bs, "Transmission Weight", 1.0)
bs.inputs["Base Color"].default_value = (0.85, 0.97, 0.95, 1)
nz = nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = 18; nz.inputs["Detail"].default_value = 3
bm_ = nt.nodes.new("ShaderNodeBump"); bm_.inputs["Strength"].default_value = 0.25
nt.links.new(nz.outputs["Fac"], bm_.inputs["Height"]); nt.links.new(bm_.outputs["Normal"], bs.inputs["Normal"])
surf.data.materials.append(ms)

# ---------- fond du bac : dégradé vert d'eau (éclairé par la volumétrie)
bpy.ops.mesh.primitive_plane_add(size=1, location=(0, LY + 0.02, LZ / 2), rotation=(math.radians(90), 0, 0))
fond = bpy.context.object; fond.scale = ((3.2 if LARGE else LX + 0.6), LZ + 0.4, 1)
mf = bpy.data.materials.new("fond"); mf.use_nodes = True; nt = mf.node_tree
for n in list(nt.nodes): nt.nodes.remove(n)
o = nt.nodes.new("ShaderNodeOutputMaterial"); e = nt.nodes.new("ShaderNodeEmission")
tc = nt.nodes.new("ShaderNodeTexCoord"); sep = nt.nodes.new("ShaderNodeSeparateXYZ"); cr = nt.nodes.new("ShaderNodeValToRGB")
nt.links.new(tc.outputs["Generated"], sep.inputs[0]); nt.links.new(sep.outputs["Y"], cr.inputs[0])
cr.color_ramp.elements[0].color = (0.010, 0.040, 0.040, 1); cr.color_ramp.elements[1].color = (0.11, 0.30, 0.27, 1)
nt.links.new(cr.outputs[0], e.inputs[0]); e.inputs[1].default_value = 1.0; nt.links.new(e.outputs[0], o.inputs[0])
fond.data.materials.append(mf)

# ---------- eau : volume léger (profondeur, rayons)
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, LY / 2 - 0.3, LZ / 2))
eau = bpy.context.object; eau.name = "eau"; eau.scale = ((3.2 if LARGE else LX + 0.8), LY + 0.62, LZ)
mv = bpy.data.materials.new("eau"); mv.use_nodes = True; nt = mv.node_tree
for n in list(nt.nodes): nt.nodes.remove(n)
o = nt.nodes.new("ShaderNodeOutputMaterial"); v = nt.nodes.new("ShaderNodeVolumePrincipled")
v.inputs["Color"].default_value = (0.30, 0.62, 0.58, 1); v.inputs["Density"].default_value = 0.18
v.inputs["Anisotropy"].default_value = 0.55; v.inputs["Absorption Color"].default_value = (0.55, 0.85, 0.75, 1)
nt.links.new(v.outputs[0], o.inputs["Volume"]); eau.data.materials.append(mv)

# ---------- surface : ondulations qui projettent des caustiques douces via une lampe à gobo
lum = bpy.data.lights.new("rampe", "SPOT"); lum.energy = 70; lum.spot_size = math.radians(80); lum.spot_blend = 0.6
lum.color = (1.0, 0.96, 0.88); lum.shadow_soft_size = 0.03; lum.use_nodes = True
nt = lum.node_tree; em = nt.nodes["Emission"]
tc = nt.nodes.new("ShaderNodeTexCoord"); vo = nt.nodes.new("ShaderNodeTexVoronoi"); vo.feature = "SMOOTH_F1"
vo.voronoi_dimensions = "4D"; vo.inputs["Scale"].default_value = 14; vo.inputs["W"].default_value = FRAME / 40.0
nt.links.new(tc.outputs["Normal"], vo.inputs["Vector"])
cr = nt.nodes.new("ShaderNodeMapRange"); cr.inputs["From Min"].default_value = 0.0; cr.inputs["From Max"].default_value = 0.35
cr.inputs["To Min"].default_value = 2.0; cr.inputs["To Max"].default_value = 0.55
nt.links.new(vo.outputs["Distance"], cr.inputs["Value"]); nt.links.new(cr.outputs[0], em.inputs["Strength"])
lo = bpy.data.objects.new("rampe", lum); sc.collection.objects.link(lo); lo.location = (0, LY * 0.45, LZ + 0.35)
ar = bpy.data.lights.new("douce", "AREA"); ar.energy = 25; ar.size = 0.9; ar.size_y = 0.5; ar.shape = "RECTANGLE"
ar.color = (0.85, 0.95, 1.0)
ao_ = bpy.data.objects.new("douce", ar); sc.collection.objects.link(ao_); ao_.location = (0, 0.1, LZ + 0.25)
de = bpy.data.lights.new("face", "AREA"); de.energy = 4; de.size = 1.2; de.color = (1, 0.93, 0.84)
do = bpy.data.objects.new("face", de); sc.collection.objects.link(do); do.location = (0.2, -0.9, 0.35)
do.rotation_euler = (math.radians(80), 0, math.radians(10))
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.02, 0.03, 0.035, 1)

# ---------- poissons (tête +X) : (espèce, longueur, x, y, z, cap en degrés, inclinaison)
BANC = [
    ("brochet", 0.30, 0.02, 0.30, 0.50, 180, -2),
    ("truite-fario", 0.20, -0.06, 0.10, 0.36, 6, 2),
    ("carpe-commune", 0.22, 0.07, 0.28, 0.21, 176, 3),
    ("sandre", 0.19, -0.13, 0.36, 0.29, 12, -2),
    ("tanche", 0.15, 0.10, 0.18, 0.12, 192, 8),
    ("perche", 0.12, 0.15, 0.06, 0.26, 200, 0),
    ("perche", 0.10, 0.20, 0.14, 0.31, 194, 3),
    ("gardon", 0.09, -0.16, 0.30, 0.60, 10, 0),
    ("gardon", 0.085, -0.07, 0.24, 0.66, 2, -6),
    ("gardon", 0.09, -0.21, 0.38, 0.57, 14, 2),
    ("rotengle", 0.10, 0.13, 0.40, 0.62, 186, 0),
]
cache = {}
for i, (sp, lg, x, y, z, cap, inc) in enumerate([] if SANS else BANC):
    p = fk.poisson(sp, longueur=lg, nom=f"{sp}-{i}", largeur_grille=220)
    fk.nage(p, debut=1 + (i * 7) % 36, periode=30 + (i * 5) % 14, amplitude=0.07, cycles=6)
    p.location = (x, y, z); p.rotation_euler = (0, math.radians(inc), math.radians(cap))

# ---------- bulles qui montent dans un coin
mb = bpy.data.materials.new("bulle"); mb.use_nodes = True; bb = mb.node_tree.nodes["Principled BSDF"]
bb.inputs["Roughness"].default_value = 0.0; bb.inputs["IOR"].default_value = 1.0 / 1.33
fk._set(bb, "Transmission Weight", 1.0)
for k in range(0 if SANS else 26):
    r = random.uniform(0.0015, 0.004)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, segments=16, ring_count=8,
                                         location=(0.40 + random.uniform(-0.01, 0.01), 0.42 + random.uniform(-0.01, 0.01), 0.12 + k * 0.019 + random.uniform(0, 0.01)))
    bpy.ops.object.shade_smooth(); bpy.context.object.data.materials.append(mb)

# ---------- caméra
cam = bpy.data.cameras.new("cam"); co = bpy.data.objects.new("cam", cam); sc.collection.objects.link(co); sc.camera = co
cam.sensor_fit = "VERTICAL"; cam.dof.use_dof = True; cam.dof.aperture_fstop = 2.8
if VUE == "1":   # vue d'ensemble, portrait, à travers la vitre
    co.location = (0.0, -0.70, 0.37); co.rotation_euler = (math.radians(91), 0, 0); cam.lens = 27
    cam.dof.focus_distance = 1.05
elif VUE == "2":  # gros plan truite et perches
    co.location = (0.06, -0.30, 0.32); co.rotation_euler = (math.radians(89), 0, 0); cam.lens = 22
    cam.dof.focus_distance = 0.40; cam.dof.aperture_fstop = 2.8
elif VUE == "w":  # fond de widget : sol sur le quart bas, surface claire en haut
    co.location = (0.0, -0.75, 0.36); co.rotation_euler = (math.radians(90), 0, 0)
    cam.sensor_fit = "VERTICAL"; cam.lens = 30 if RW / RH < 1.2 else 36; cam.dof.use_dof = False
else:             # contre-plongée depuis le gravier
    co.location = (-0.10, -0.42, 0.09); co.rotation_euler = (math.radians(101), 0, math.radians(-8)); cam.lens = 20
    cam.dof.focus_distance = 0.6

fk.reglages_cycles(sc, echantillons=SPP, largeur=RW, hauteur=RH, rebonds=6)
sc.cycles.volume_step_rate = 4; sc.cycles.volume_max_steps = 256
sc.view_settings.look = "AgX - Medium High Contrast"
sc.frame_set(FRAME)
sc.render.filepath = OUT
if OUT.endswith(".blend"):
    bpy.ops.wm.save_as_mainfile(filepath=OUT)
else:
    bpy.ops.render.render(write_still=True)
