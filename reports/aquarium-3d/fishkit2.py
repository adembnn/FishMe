"""fishkit2 : poissons en volume, version soignée (16 oct.).

Différences avec fishkit (v1) :
- textures nettoyées par outils/nettoyer_planche.py (bord net, plus de liseré papier ni de trait gravé,
  couleurs corrigées, trame adoucie) : textures/propres/<slug>-couleur.png, -epaisseur.png, -relief.png ;
- la silhouette vient de la transparence de la texture (bord lisse au pixel), plus des cases du maillage :
  fini les bords en dents de scie ;
- profil en lentille (corps bombé, nageoires presque plates) au lieu d'un poisson « gonflé » ;
- vraie peau : relief des écailles, reflet mouillé, nageoires un peu translucides ;
- un œil : petite cornée brillante posée sur l'œil peint, de chaque côté ;
- nage : clés de forme en boucle (comme v1).

Usage :
    import sys; sys.path.insert(0, "/mnt/project-files/build/aquarium/3d")
    import fishkit2 as fk
    p = fk.poisson("brochet", longueur=0.75)          # textures propres par défaut
    fk.nage(p, periode=36, amplitude=0.06)
"""

import math
import os

import bpy
import numpy as np

ICI = os.path.dirname(os.path.abspath(__file__))
PROPRES = os.path.join(ICI, "textures", "propres")

# Position de l'œil sur la planche : (u depuis la gauche, v depuis le HAUT, rayon en fraction de la largeur)
YEUX = {
    "brochet": (0.868, 0.36, 0.011),
    "sandre": (0.910, 0.47, 0.011),
    "perche": (0.904, 0.49, 0.013),
    "carpe-commune": (0.893, 0.49, 0.011),
    "gardon": (0.921, 0.53, 0.013),
    "truite-fario": (0.900, 0.42, 0.011),
    "tanche": (0.895, 0.57, 0.012),
}

# Demi-épaisseur maximale du corps, en fraction de la hauteur du poisson (réalité anatomique, arrondie)
EPAISSEUR = {
    "brochet": 0.30, "sandre": 0.24, "perche": 0.20, "carpe-commune": 0.22, "gardon": 0.17,
    "truite-fario": 0.24, "tanche": 0.24, "chevesne": 0.22, "breme-commune": 0.12, "black-bass": 0.22,
    "silure": 0.30, "ablette": 0.15, "rotengle": 0.16,
}


def _pixels(img):
    w, h = img.size
    px = np.empty(w * h * img.channels, dtype=np.float32)
    img.pixels.foreach_get(px)
    return px.reshape(h, w, img.channels)  # ligne 0 = bas


def _image(chemin, donnees=False):
    img = bpy.data.images.load(chemin, check_existing=True)
    if donnees:
        img.colorspace_settings.name = "Non-Color"
    return img


def poisson(slug, longueur=0.4, dossier=PROPRES, largeur_grille=300, lissage=1, nom=None,
            epaisseur=None, oeil=True):
    """Crée un poisson en volume (tête vers +X, dos vers +Z, flancs selon ±Y). longueur en mètres."""
    nom = nom or slug
    img_c = _image(os.path.join(dossier, slug + "-couleur.png"))
    img_e = _image(os.path.join(dossier, slug + "-epaisseur.png"), donnees=True)
    W, H = img_c.size
    alpha = _pixels(img_c)[:, :, 3]
    ep = _pixels(img_e)[:, :, 0]

    pas = max(1, W // largeur_grille)
    gh, gw = H // pas, W // pas
    a = alpha[: gh * pas, : gw * pas].reshape(gh, pas, gw, pas).max(axis=(1, 3))
    e = ep[: gh * pas, : gw * pas].reshape(gh, pas, gw, pas).mean(axis=(1, 3))
    plein = a > 0.02
    # le maillage déborde de 2 cases : c'est la transparence qui dessine le bord, au pixel près
    m = plein.copy()
    for _ in range(2):
        g = m.copy()
        g[1:, :] |= m[:-1, :]; g[:-1, :] |= m[1:, :]; g[:, 1:] |= m[:, :-1]; g[:, :-1] |= m[:, 1:]
        m = g

    ys, xs = np.where(plein)
    echelle = longueur / float((xs.max() + 1 - xs.min()) * pas)
    hauteur_m = (ys.max() + 1 - ys.min()) * pas * echelle
    demi = (epaisseur if epaisseur is not None else EPAISSEUR.get(slug, 0.2)) * hauteur_m
    cx = (xs.min() + xs.max() + 1) * pas / 2.0
    cy = (ys.min() + ys.max() + 1) * pas / 2.0

    coin = np.zeros((gh + 1, gw + 1), dtype=bool)
    for dy, dx in ((0, 0), (1, 0), (0, 1), (1, 1)):
        coin[dy:dy + gh, dx:dx + gw] |= m
    zc = np.zeros((gh + 1, gw + 1), dtype=np.float32)
    nb = np.zeros((gh + 1, gw + 1), dtype=np.float32)
    cnt = np.zeros((gh + 1, gw + 1), dtype=np.int32)
    for dy, dx in ((0, 0), (1, 0), (0, 1), (1, 1)):
        zc[dy:dy + gh, dx:dx + gw] += e * m
        nb[dy:dy + gh, dx:dx + gw] += m
        cnt[dy:dy + gh, dx:dx + gw] += m
    zc /= np.maximum(nb, 1)
    bord = coin & (cnt < 4)
    zc[bord] = 0.0

    ia = -np.ones((gh + 1, gw + 1), dtype=np.int64)
    ib = -np.ones((gh + 1, gw + 1), dtype=np.int64)
    verts, uvv = [], []
    jj, ii = np.where(coin)
    for j, i in zip(jj, ii):
        X = (i * pas - cx) * echelle
        Z = (j * pas - cy) * echelle
        u, v = min(i * pas / W, 1.0), min(j * pas / H, 1.0)
        ia[j, i] = len(verts); verts.append((X, -zc[j, i] * demi, Z)); uvv.append((u, v))
        if bord[j, i]:
            ib[j, i] = ia[j, i]
        else:
            ib[j, i] = len(verts); verts.append((X, zc[j, i] * demi, Z)); uvv.append((u, v))
    faces = []
    fj, fi = np.where(m)
    for j, i in zip(fj, fi):
        q = ((j, i), (j, i + 1), (j + 1, i + 1), (j + 1, i))
        faces.append([ia[p] for p in q])
        faces.append([ib[p] for p in reversed(q)])

    me = bpy.data.meshes.new(nom)
    me.from_pydata(verts, [], faces)
    me.validate()
    uv = me.uv_layers.new(name="UVMap")
    vi = np.empty(len(me.loops), dtype=np.int64)
    me.loops.foreach_get("vertex_index", vi)
    uv.data.foreach_set("uv", np.asarray(uvv, dtype=np.float32)[vi].ravel())
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    obj = bpy.data.objects.new(nom, me)
    bpy.context.scene.collection.objects.link(obj)
    if lissage:
        sd = obj.modifiers.new("Lissage", "SUBSURF")
        sd.levels = sd.render_levels = lissage
    obj.data.materials.append(materiau_peau(slug, img_c, dossier))
    obj["longueur"] = longueur
    obj["hauteur"] = hauteur_m

    if oeil and slug in YEUX:
        u, vt, r = YEUX[slug]
        X = (u * W - cx) * echelle
        Z = ((1 - vt) * H - cy) * echelle
        R = r * W * echelle
        j = int(np.clip((1 - vt) * H / pas, 0, gh)); i = int(np.clip(u * W / pas, 0, gw))
        y = float(zc[j, i]) * demi
        for cote in (-1, 1):
            bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=R,
                                                 location=(X, cote * (y + R * 0.05), Z))
            c = bpy.context.object
            c.name = f"{nom}-cornee{'G' if cote < 0 else 'D'}"
            c.scale = (1.0, 0.45, 1.0)
            bpy.ops.object.shade_smooth()
            c.data.materials.append(materiau_cornee())
            c.parent = obj
    return obj


def materiau_peau(slug, img_c, dossier):
    mat = bpy.data.materials.new("peau-" + slug)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    N = nt.nodes.new
    out = N("ShaderNodeOutputMaterial")
    bsdf = N("ShaderNodeBsdfPrincipled")
    tc = N("ShaderNodeTexImage"); tc.image = img_c; tc.interpolation = "Cubic"
    tr = N("ShaderNodeTexImage"); tr.image = _image(os.path.join(dossier, slug + "-relief.png"), True)
    tn = N("ShaderNodeTexImage"); tn.image = _image(os.path.join(dossier, slug + "-nageoires.png"), True)
    bump = N("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.35
    bump.inputs["Distance"].default_value = 0.0015
    L = nt.links.new
    L(tc.outputs["Color"], bsdf.inputs["Base Color"])
    L(tc.outputs["Alpha"], bsdf.inputs["Alpha"])
    L(tr.outputs["Color"], bump.inputs["Height"])
    L(bump.outputs["Normal"], bsdf.inputs["Normal"])
    # rugosité : corps luisant 0.38, nageoires mates 0.6
    rug = N("ShaderNodeMapRange")
    rug.inputs["To Min"].default_value = 0.38; rug.inputs["To Max"].default_value = 0.72
    L(tn.outputs["Color"], rug.inputs["Value"])
    L(rug.outputs["Result"], bsdf.inputs["Roughness"])
    _set(bsdf, "Coat Weight", 0.18); _set(bsdf, "Coat Roughness", 0.12)
    _set(bsdf, "Subsurface Weight", 0.06); _set(bsdf, "Subsurface Scale", 0.004)
    _set(bsdf, "Sheen Weight", 0.08)
    # nageoires : un peu de lumière les traverse
    trans = N("ShaderNodeBsdfTranslucent")
    sombre = N("ShaderNodeMix"); sombre.data_type = "RGBA"; sombre.blend_type = "MULTIPLY"
    sombre.inputs["Factor"].default_value = 1.0; sombre.inputs[7].default_value = (0.55, 0.55, 0.55, 1)
    L(tc.outputs["Color"], sombre.inputs[6]); L(sombre.outputs[2], trans.inputs["Color"])
    poids = N("ShaderNodeMath"); poids.operation = "MULTIPLY"; poids.inputs[1].default_value = 0.12
    L(tn.outputs["Color"], poids.inputs[0])
    mix = N("ShaderNodeMixShader")
    L(poids.outputs[0], mix.inputs[0])
    L(bsdf.outputs["BSDF"], mix.inputs[1])
    L(trans.outputs["BSDF"], mix.inputs[2])
    # la transparence (bord) s'applique au mélange
    tsp = N("ShaderNodeBsdfTransparent")
    mix2 = N("ShaderNodeMixShader")
    L(tc.outputs["Alpha"], mix2.inputs[0])
    L(tsp.outputs["BSDF"], mix2.inputs[1])
    L(mix.outputs["Shader"], mix2.inputs[2])
    L(mix2.outputs["Shader"], out.inputs["Surface"])
    return mat


_CORNEE = None


def materiau_cornee():
    global _CORNEE
    if _CORNEE:
        return _CORNEE
    m = bpy.data.materials.new("cornee")
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.02, 0.02, 0.02, 1)
    b.inputs["Roughness"].default_value = 0.03
    _set(b, "Transmission Weight", 1.0)
    b.inputs["IOR"].default_value = 1.376
    _set(b, "Coat Weight", 1.0); _set(b, "Coat Roughness", 0.02)
    _CORNEE = m
    return m


def _set(noeud, nom, val):
    if nom in noeud.inputs:
        noeud.inputs[nom].default_value = val


def nage(obj, debut=1, periode=36, amplitude=0.06, phases=12, longueur_onde=1.05, cycles=40):
    """Onde latérale (Y) de la tête (+X) vers la queue, en boucle (clés de forme)."""
    me = obj.data
    if me.shape_keys is None:
        obj.shape_key_add(name="Repos", from_mix=False)
    co0 = np.empty(len(me.vertices) * 3, dtype=np.float32)
    me.vertices.foreach_get("co", co0)
    co0 = co0.reshape(-1, 3)
    xs = co0[:, 0]
    tete, queue = xs.max(), xs.min()
    Lg = max(tete - queue, 1e-6)
    t = (tete - xs) / Lg
    env = 0.03 + 0.97 * t ** 2.2
    A = amplitude * Lg
    cles = []
    for k in range(phases):
        ph = 2 * math.pi * k / phases
        sk = obj.shape_key_add(name="Nage%02d" % k, from_mix=False)
        co = co0.copy()
        dy = A * env * np.sin(ph - 2 * math.pi * t / longueur_onde) - A * 0.12 * np.sin(ph) * (1 - t)
        co[:, 1] += dy
        sk.data.foreach_set("co", co.ravel())
        cles.append(sk)
    pasf = periode / phases
    for k, sk in enumerate(cles):
        for c in range(cycles):
            f0 = debut + c * periode + k * pasf
            for f, val in ((f0 - pasf, 0.0), (f0, 1.0), (f0 + pasf, 0.0)):
                sk.value = val
                sk.keyframe_insert("value", frame=f)
    ad = me.shape_keys.animation_data
    if ad and ad.action:
        for fc in _fcurves(ad.action):
            for kp in fc.keyframe_points:
                kp.interpolation = "LINEAR"
    # les cornées suivent la tête (elle bouge à peine) : rien à faire
    return obj


def _fcurves(action):
    if hasattr(action, "fcurves") and len(action.fcurves):
        return list(action.fcurves)
    out = []
    for layer in getattr(action, "layers", []):
        for strip in layer.strips:
            for bag in getattr(strip, "channelbags", []):
                out.extend(bag.fcurves)
    return out


def reglages_cycles(scene=None, echantillons=128, largeur=1080, hauteur=1920, rebonds=8):
    scene = scene or bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = echantillons
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.use_denoising = True
    scene.cycles.denoiser = "OPENIMAGEDENOISE"
    scene.cycles.max_bounces = rebonds
    scene.cycles.transparent_max_bounces = 24
    scene.render.resolution_x, scene.render.resolution_y = largeur, hauteur
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Base Contrast"
    scene.render.image_settings.file_format = "PNG"
    return scene


def scene_vide():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    return bpy.context.scene
