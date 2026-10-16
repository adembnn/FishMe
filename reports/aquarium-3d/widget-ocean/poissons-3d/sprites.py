"""Images du widget rendues en vraie 3D (Cycles) : 3 vues x 8 battements de queue, PNG transparents <= 600 px.
<nom>-nage-0..7 (profil, tête à droite), <nom>-vue-1-0..7 (45° vers le fond), <nom>-vue-2-0..7 (45° vers nous).
blender -b --python sprites.py -- <dossier_textures> <dossier_sortie> <slug:nom> [slug:nom ...]"""
import sys, os, math, bpy
import numpy as np
sys.path.insert(0, "/mnt/project-files/build/aquarium/3d")
import fishkit2 as fk
A = sys.argv[sys.argv.index("--") + 1:]
DOS, SORTIE, PAIRES = A[0], A[1], [a.split(":") if ":" in a else (a, a) for a in A[2:]]
os.makedirs(SORTIE, exist_ok=True)
# Adem 08h35 : « pas de téléportation » quand il tourne -> 9 angles de 22,5° de -90 (vers nous) à +90 (vers le fond),
# l'aperçu et le widget fondent entre deux angles voisins ; à ±90° (vu de face / de dos) le miroir gauche-droite est invisible.
ANGLES = [float(a) for a in os.environ.get("ANGLES", "0,15,30,45,60,75,90,-15,-30,-45,-60,-75,-90").split(",")]
def nom_vue(a):
    # nommage du widget (coordinateur, lot/widget-aquarium) : nage, lacet-15 (vers le fond), lacet-m15 (vers nous)
    if a == 0: return "nage"
    n = ("%g" % abs(a)).replace(".", "_")
    return "lacet-" + ("" if a > 0 else "m") + n
VUES = tuple((nom_vue(a), a) for a in ANGLES)
NB = int(os.environ.get("IMAGES", "16"))          # images par battement (Adem 08h05 : plus fluide)
EP = float(os.environ.get("EPAISSEUR", "1.25"))    # corps plus épais que la planche, pour qu'il ne fasse pas « feuille »
AMP = float(os.environ.get("AMPLITUDE", "0.16"))  # battement de queue bien visible
def dos_lisse(p, slug):
    """Dos et ventre : la planche est vue de profil, donc sur le dessus bombé sa texture s'étire en stries.
    Là où la surface regarde vers le haut (ou le bas), on passe en douceur à la même texture très floutée,
    un peu plus sombre sur le dos et plus claire sous le ventre, comme un vrai poisson."""
    flou = os.path.join(SORTIE, "..", "flou", slug + "-flou.png")   # fait avant par flou.py (pas de PIL dans Blender)
    mat = p.data.materials[0]; nt = mat.node_tree; N = nt.nodes.new; L = nt.links.new
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tc = bsdf.inputs["Base Color"].links[0].from_node
    tf = N("ShaderNodeTexImage"); tf.image = bpy.data.images.load(flou); tf.interpolation = "Cubic"
    L(tc.inputs["Vector"].links[0].from_socket if tc.inputs["Vector"].links else N("ShaderNodeTexCoord").outputs["UV"], tf.inputs["Vector"])
    geo = N("ShaderNodeNewGeometry"); sep = N("ShaderNodeSeparateXYZ"); L(geo.outputs["Normal"], sep.inputs[0])
    def rampe(signe):
        m = N("ShaderNodeMath"); m.operation = "MULTIPLY"; m.inputs[1].default_value = signe; L(sep.outputs["Z"], m.inputs[0])
        r = N("ShaderNodeMapRange"); r.inputs["From Min"].default_value = 0.70; r.inputs["From Max"].default_value = 0.97
        r.interpolation_type = "SMOOTHSTEP"; L(m.outputs[0], r.inputs["Value"]); return r.outputs["Result"]
    def teinte(fac):
        t = N("ShaderNodeMix"); t.data_type = "RGBA"; t.blend_type = "MULTIPLY"; t.inputs["Factor"].default_value = 1.0
        L(tf.outputs["Color"], t.inputs[6]); t.inputs[7].default_value = (fac, fac, fac, 1); return t.outputs[2]
    m1 = N("ShaderNodeMix"); m1.data_type = "RGBA"; L(rampe(1.0), m1.inputs["Factor"])
    L(tc.outputs["Color"], m1.inputs[6]); L(teinte(0.78), m1.inputs[7])
    m2 = N("ShaderNodeMix"); m2.data_type = "RGBA"; L(rampe(-1.0), m2.inputs["Factor"])
    L(m1.outputs[2], m2.inputs[6]); L(teinte(1.08), m2.inputs[7])
    L(m2.outputs[2], bsdf.inputs["Base Color"])

def uv_dos(p, part=float(os.environ.get("PART_DOS", "0.55"))):
    """2e carte UV « UVDos » : chaque point est décalé vers le milieu du corps (dans la planche) en proportion de
    son écart latéral |Y| rapporté à l'épaisseur max de sa tranche. Ainsi le dos lit les écailles du haut du flanc
    sans étirement, et la queue fine reste dans le corps."""
    me = p.data
    co = np.empty(len(me.vertices) * 3, np.float32); me.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    uv0 = me.uv_layers["UVMap"]; n = len(me.loops)
    uv = np.empty(n * 2, np.float32); uv0.data.foreach_get("uv", uv); uv = uv.reshape(-1, 2)
    vi = np.empty(n, np.int64); me.loops.foreach_get("vertex_index", vi)
    X, Y = co[vi, 0], np.abs(co[vi, 1])
    nb = 120; b = np.clip(((X - X.min()) / (X.ptp() + 1e-9) * nb).astype(int), 0, nb - 1)
    ymax = np.zeros(nb); vmin = np.full(nb, 9.0); vmax = np.full(nb, -9.0)
    corps = Y > 0  # points épais = corps (les nageoires ont une épaisseur infime)
    for k in range(nb):
        m = b == k
        if not m.any(): continue
        ymax[k] = Y[m].max()
        mc = m & (Y > 0.35 * Y[m].max())
        if mc.any(): vmin[k], vmax[k] = uv[mc, 1].min(), uv[mc, 1].max()
    ok = vmax > vmin
    idx = np.arange(nb)
    for arr in (vmin, vmax): arr[~ok] = np.interp(idx[~ok], idx[ok], arr[ok])
    vc = (vmin + vmax) / 2; hv = (vmax - vmin) / 2
    f = np.clip(Y / np.maximum(ymax[b], 1e-6), 0, 1)
    v = uv[:, 1]; dirc = np.sign(vc[b] - v)
    nv = v + dirc * hv[b] * (float(os.environ.get("PLANCHER_DOS", "0.06")) + part * f)   # même l arête du dos lit un peu à l intérieur (pas le trait d encre)
    nv = np.where(np.sign(vc[b] - nv) == dirc, nv, vc[b])   # ne jamais dépasser le milieu
    out = uv.copy(); out[:, 1] = nv
    l2 = me.uv_layers.new(name="UVDos"); l2.data.foreach_set("uv", out.ravel())
    me.uv_layers.active_index = 0

def alpha_net(p):
    """Bord net : la bande semi-transparente du contour laissait voir l'intérieur sombre du poisson
    (un trait noir le long du dos quand on le voit de dessus)."""
    nt = p.data.materials[0].node_tree
    for n in list(nt.nodes):
        if n.type == "TEX_IMAGE" and n.outputs["Alpha"].links:
            liens = [l.to_socket for l in n.outputs["Alpha"].links]
            r = nt.nodes.new("ShaderNodeMapRange"); r.inputs["From Min"].default_value = 0.42; r.inputs["From Max"].default_value = 0.58
            nt.links.new(n.outputs["Alpha"], r.inputs["Value"])
            for sock in liens:
                for l in list(sock.links): nt.links.remove(l)
                nt.links.new(r.outputs["Result"], sock)
            # la « jupe » du maillage (2 cases hors silhouette, épaisseur nulle) formait une lame verticale le long
            # du dos, sombre vue de dessus : on la rend invisible là où l'épaisseur au repos est nulle, sauf nageoires
            me = p.data
            co = np.empty(len(me.vertices) * 3, np.float32); me.vertices.foreach_get("co", co); y = np.abs(co.reshape(-1, 3)[:, 1])
            at = me.attributes.new("ep", "FLOAT", "POINT"); at.data.foreach_set("value", (y / max(y.max(), 1e-6)).astype(np.float32))
            att = nt.nodes.new("ShaderNodeAttribute"); att.attribute_name = "ep"
            gt = nt.nodes.new("ShaderNodeMath"); gt.operation = "GREATER_THAN"; gt.inputs[1].default_value = 0.006
            nt.links.new(att.outputs["Fac"], gt.inputs[0])
            tn = next((m for m in nt.nodes if m.type == "TEX_IMAGE" and m.image and "nageoires" in m.image.name), None)
            garde = gt.outputs[0]
            if tn:
                mx = nt.nodes.new("ShaderNodeMath"); mx.operation = "MAXIMUM"
                nt.links.new(gt.outputs[0], mx.inputs[0]); nt.links.new(tn.outputs["Color"], mx.inputs[1]); garde = mx.outputs[0]
            # corps (épaisseur > 0, hors nageoires) : opaque jusqu'au bord, sinon on voit l'intérieur sombre à l'arête du dos
            # nageoires : alpha de la planche (bord net) ; jupe d'épaisseur nulle : invisible
            fin = nt.nodes.new("ShaderNodeMath"); fin.operation = "GREATER_THAN"; fin.inputs[1].default_value = 0.5
            if tn: nt.links.new(tn.outputs["Color"], fin.inputs[0])
            else: fin.inputs[0].default_value = 0.0
            af = nt.nodes.new("ShaderNodeMath"); af.operation = "MULTIPLY"; nt.links.new(r.outputs["Result"], af.inputs[0]); nt.links.new(fin.outputs[0], af.inputs[1])
            mu = nt.nodes.new("ShaderNodeMath"); mu.operation = "MAXIMUM"; nt.links.new(af.outputs[0], mu.inputs[0]); nt.links.new(gt.outputs[0], mu.inputs[1])
            for sock in liens:
                for l in list(sock.links): nt.links.remove(l)
                nt.links.new(mu.outputs[0], sock)
            break

def dos_ecailles(p, slug):
    """Dos et ventre texturés (Adem 08h22 : « il faut la texturer ») : la planche est vue de profil, donc sur le
    dessus bombé elle s'étire. Là où la surface regarde vers le haut (ou le bas), on relit la MÊME planche, mais
    décalée vers l'intérieur du flanc selon la distance latérale |Y| : le dos reçoit les vraies écailles du haut du
    flanc, sans étirement, un peu assombries (dos) ou éclaircies (ventre) comme un vrai poisson."""
    K = float(os.environ.get("K_DOS", "1.1"))
    mat = p.data.materials[0]; nt = mat.node_tree; N = nt.nodes.new; L = nt.links.new
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tc = bsdf.inputs["Base Color"].links[0].from_node
    uvn = N("ShaderNodeUVMap"); uvn.uv_map = "UVMap"
    sepuv = N("ShaderNodeSeparateXYZ"); L(uvn.outputs["UV"], sepuv.inputs[0])
    co = N("ShaderNodeTexCoord"); sepo = N("ShaderNodeSeparateXYZ"); L(co.outputs["Object"], sepo.inputs[0])
    ay = N("ShaderNodeMath"); ay.operation = "ABSOLUTE"; L(sepo.outputs["Y"], ay.inputs[0])
    geo = N("ShaderNodeNewGeometry"); sepn = N("ShaderNodeSeparateXYZ"); L(geo.outputs["Normal"], sepn.inputs[0])
    uvd = N("ShaderNodeUVMap"); uvd.uv_map = "UVDos"
    def lecture(signe, fac):
        t = N("ShaderNodeTexImage"); t.image = tc.image; t.interpolation = "Cubic"; L(uvd.outputs["UV"], t.inputs["Vector"])
        x = N("ShaderNodeMix"); x.data_type = "RGBA"; x.blend_type = "MULTIPLY"; x.inputs["Factor"].default_value = 1.0
        L(t.outputs["Color"], x.inputs[6]); x.inputs[7].default_value = (fac, fac, fac, 1)
        return x.outputs[2]
    def rampe(signe):
        m = N("ShaderNodeMath"); m.operation = "MULTIPLY"; m.inputs[1].default_value = signe; L(sepn.outputs["Z"], m.inputs[0])
        r = N("ShaderNodeMapRange"); r.inputs["From Min"].default_value = 0.35; r.inputs["From Max"].default_value = 0.75
        r.interpolation_type = "SMOOTHSTEP"; L(m.outputs[0], r.inputs["Value"]); return r.outputs["Result"]
    SD = float(os.environ.get("SENS_DOS", "-1"))
    m1 = N("ShaderNodeMix"); m1.data_type = "RGBA"; L(rampe(1.0), m1.inputs["Factor"])
    L(tc.outputs["Color"], m1.inputs[6]); L(lecture(SD, 0.85), m1.inputs[7])
    m2 = N("ShaderNodeMix"); m2.data_type = "RGBA"; L(rampe(-1.0), m2.inputs["Factor"])
    L(m1.outputs[2], m2.inputs[6]); L(lecture(-SD, 1.05), m2.inputs[7])
    L(m2.outputs[2], bsdf.inputs["Base Color"])

for slug, nom in PAIRES:
    fk.scene_vide(); fk._CORNEE = None
    sc = fk.reglages_cycles(echantillons=12, largeur=760, hauteur=486, rebonds=3)
    sc.render.film_transparent = True
    sc.render.use_persistent_data = True          # ne pas tout reconstruire à chaque image
    sc.render.threads_mode = "FIXED"; sc.render.threads = os.cpu_count() or 4
    sc.render.image_settings.color_mode = "RGBA"
    oeil = False  # œil peint de la planche : les cornées ajoutées flottaient au-dessus du corps épaissi
    p = fk.poisson(slug, longueur=1.0, dossier=DOS, largeur_grille=160, lissage=int(os.environ.get("LISSAGE", "1")), debord=int(os.environ.get("DEBORD", "2")), oeil=oeil, epaisseur=fk.EPAISSEUR.get(slug, 0.2) * EP, uv_rentre=float(os.environ.get("UV_RENTRE", "0")))
    if os.environ.get("DOS", "ecailles") == "ecailles": alpha_net(p); uv_dos(p); dos_ecailles(p, slug)
    elif os.environ.get("DOS") == "1": dos_lisse(p, slug)
    fk.nage(p, debut=1, periode=NB, phases=NB, amplitude=AMP, cycles=1)
    # lumière : ciel d'eau clair au-dessus, soleil doux de face-haut, contre-jour léger
    w = bpy.data.worlds.new("eau"); sc.world = w; w.use_nodes = True
    bg = w.node_tree.nodes["Background"]; bg.inputs[0].default_value = (0.62, 0.80, 0.88, 1); bg.inputs[1].default_value = 0.9
    def soleil(rot, force, coul):
        d = bpy.data.lights.new("s", "SUN"); d.energy = force; d.color = coul; d.angle = math.radians(18)
        o = bpy.data.objects.new("s", d); o.rotation_euler = [math.radians(r) for r in rot]; sc.collection.objects.link(o)
    soleil((35, 0, -20), 3.2, (1.0, 0.97, 0.9)); soleil((120, 0, 160), 1.4, (0.7, 0.9, 1.0))
    cam = bpy.data.cameras.new("c"); cam.type = "ORTHO"; cam.ortho_scale = 1.3
    co = bpy.data.objects.new("c", cam); sc.collection.objects.link(co); sc.camera = co
    # caméra un peu au-dessus (20°) : on voit le dos (volume) et le battement latéral de la queue se lit à l'écran
    EL = math.radians(float(os.environ.get("ELEVATION", "20")))
    co.location = (0, -5 * math.cos(EL), 5 * math.sin(EL)); co.rotation_euler = (math.radians(90) - EL, 0, 0)
    for vue, ang in VUES:
        p.rotation_euler = (0, 0, math.radians(ang))
        for k in range(NB):
            sc.frame_set(1 + k)
            f = os.path.join(SORTIE, f"{nom}-{vue}-{k}.png" if vue != "nage" else f"{nom}-nage-{k}.png")
            sc.render.filepath = f; bpy.ops.render.render(write_still=True)
    print("SPRITES", nom)
