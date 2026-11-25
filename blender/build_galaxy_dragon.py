"""Galaxy Dragon (มังกรกาแลคซี่) - built headless in Blender.

    blender -b --factory-startup --python build_galaxy_dragon.py

Body = ellipsoids + tapered capsules fused by a voxel remesh (sculpt-style "dynamesh"),
then smoothed and displaced with a scale pattern. Crystals, claws, wings, eyes, core and
belly plates are separate objects. Writes galaxy_dragon.blend and galaxy_dragon.glb
(procedural galaxy shaders baked to textures for the GLB) next to this script.

Proportions follow the character sheet: 20 m tall, faces -Y (Blender front view).
Positions are authored in a y-up, z-forward frame (same numbers as galaxy_dragon.html)
and converted with C().
"""
import bpy, bmesh, math, os, sys
import numpy as np
from mathutils import Vector as Vec, Matrix, Euler

HERE = os.path.dirname(os.path.abspath(__file__))
TEX = os.path.join(HERE, 'textures'); os.makedirs(TEX, exist_ok=True)
VOXEL = float(os.environ.get('GD_VOXEL', '0.05'))
BAKE = os.environ.get('GD_BAKE', '1') == '1'
for _o in list(bpy.data.objects): bpy.data.objects.remove(_o)  # drop the startup cube/light/camera

# ---------------------------------------------------------------- frame helpers
CM = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))  # y-up,z-fwd -> blender z-up,-y-fwd
CMi = CM.inverted()
def C(v): return (CM @ Vec((*v, 1)) if len(v) == 3 else CM @ v).to_3d()

class J:
    """A joint: position/rotation (three.js 'XYZ' Euler) relative to its parent."""
    def __init__(s, parent, pos, rot=(0, 0, 0), scale=(1, 1, 1)):
        local = Matrix.Translation(Vec(pos)) @ Euler(rot, 'ZYX').to_matrix().to_4x4() @ Matrix.Diagonal((*scale, 1))
        s.m = parent.m @ local if parent else local
    def p(s, v): return (s.m @ Vec((*v, 1))).to_3d() if not isinstance(v, Vec) else (s.m @ v.to_4d()).to_3d()
    def d(s, v): return s.m.to_3x3() @ Vec(v)

# geometry buckets: name -> bmesh
BM = {}
def bm(name):
    if name not in BM: BM[name] = bmesh.new()
    return BM[name]

def ell(j, pos, scl, rot=(0, 0, 0), group='body', seg=(28, 18)):
    m3 = j.m @ Matrix.Translation(Vec(pos)) @ Euler(rot, 'ZYX').to_matrix().to_4x4() @ Matrix.Diagonal((*scl, 1))
    bmesh.ops.create_uvsphere(bm(group), u_segments=seg[0], v_segments=seg[1], radius=1, matrix=CM @ m3 @ CMi)

def cap(j, a, b, r1, r2, group='body', seg=20, ends=True):
    A, B = C(j.p(a)), C(j.p(b))
    d = B - A; L = d.length
    if L < 1e-5: return
    rot = Vec((0, 0, 1)).rotation_difference(d.normalized()).to_matrix().to_4x4()
    M = Matrix.Translation((A + B) / 2) @ rot
    bmesh.ops.create_cone(bm(group), cap_ends=True, segments=seg, radius1=r1, radius2=r2, depth=L, matrix=M)
    if ends:
        bmesh.ops.create_uvsphere(bm(group), u_segments=seg, v_segments=max(8, seg // 2), radius=r1, matrix=Matrix.Translation(A))
        bmesh.ops.create_uvsphere(bm(group), u_segments=seg, v_segments=max(8, seg // 2), radius=r2, matrix=Matrix.Translation(B))

SHARD_MAT = {'blue': 0, 'violet': 1}
def shard(j, pos, dirv, length, r, mat='blue', sides=5, group=None):
    """Faceted crystal: lathe profile (0,0)->(r,.18L)->(.82r,.6L)->(0,L) around +y, aimed along dirv."""
    group = group or ('claws' if mat == 'claw' else 'crystals')
    b = bm(group)
    base = j.p(pos)
    q = Vec((0, 1, 0)).rotation_difference(j.d(dirv).normalized())
    prof = [(r, .18 * length), (r * .82, .6 * length)]
    tw = (hash((round(base.x, 2), round(base.y, 2))) % 100) / 100 * math.tau  # vary facet orientation
    ring = []
    for rr, h in prof:
        ring.append([b.verts.new(C(base + q @ Vec((math.cos(tw + k / sides * math.tau) * rr, h, math.sin(tw + k / sides * math.tau) * rr)))) for k in range(sides)])
    v0 = b.verts.new(C(base)); v1 = b.verts.new(C(base + q @ Vec((0, length, 0))))
    mi = SHARD_MAT.get(mat, 0)
    faces = []
    for k in range(sides):
        k2 = (k + 1) % sides
        faces.append(b.faces.new((v0, ring[0][k2], ring[0][k])))
        faces.append(b.faces.new((ring[0][k], ring[0][k2], ring[1][k2], ring[1][k])))
        faces.append(b.faces.new((ring[1][k], ring[1][k2], v1)))
    for f in faces: f.material_index = mi; f.smooth = False

def ell_ax(j, c, ax, ay, az, group):
    """Ellipsoid with explicit (joint-local) half-axes."""
    R = j.m.to_3x3(); X, Y, Z = R @ Vec(ax), R @ Vec(ay), R @ Vec(az)
    M = Matrix.Identity(4)
    for i in range(3): M[i][0], M[i][1], M[i][2] = X[i], Y[i], Z[i]
    M.translation = j.p(c)
    bmesh.ops.create_uvsphere(bm(group), u_segments=16, v_segments=10, radius=1, matrix=CM @ M @ CMi)

def plate_row(j, a, b, out, n, r0, r1, w=.32, l=.36, t=.08, group='plates'):
    """A row of overlapping armour scales along a limb, on the side facing `out`."""
    a, b = Vec(a), Vec(b); d = (b - a).normalized()
    out = Vec(out); out = (out - d * out.dot(d)).normalized(); side = d.cross(out)
    for k in range(n):
        f = (k + .5) / n
        ell_ax(j, a.lerp(b, f) + out * (r0 + (r1 - r0) * f), side * w, d * l, out * t, group)

LIMB_VEINS = []
def vein_on(j, c, sc, side, y0, y1, x0, wob, n=12):
    """A glowing vein drawn over the surface of a muscle ellipsoid (joint-local centre c, radii sc)."""
    c, sc = Vec(c), Vec(sc); pts = []
    for k in range(n + 1):
        f = k / n; y = c.y + sc.y * (y0 + (y1 - y0) * f); x = c.x + sc.x * (x0 + wob * math.sin(f * 7 + x0 * 5))
        q = 1 - ((x - c.x) / sc.x) ** 2 - ((y - c.y) / sc.y) ** 2
        if q > .02: pts.append(C(j.p((x, y, c.z + side * (sc.z * math.sqrt(q) + .035)))))
    if len(pts) > 3: LIMB_VEINS.append(pts)

# ---------------------------------------------------------------- skeleton (rest pose)
root = J(None, (0, 0, 0))
hips = J(root, (0, 8.5, 0))
spine = J(hips, (0, 1.5, 0), (.04, 0, 0))
chest = J(spine, (0, 2.0, 0), (.02, 0, 0))
neck = J(chest, (0, 3.5, -.25), (.08, 0, 0))
head = J(neck, (0, 2.1, .75), (-.12, 0, 0))
jaw = J(head, (0, -.05, .35), (.22, 0, 0))
O = (0, 0, 0)
BONES = [  # (name, parent, head, tail) in the y-up frame; becomes the armature
    ('hips', None, hips.p(O), spine.p(O)), ('spine', 'hips', spine.p(O), chest.p(O)),
    ('chest', 'spine', chest.p(O), neck.p(O)), ('neck', 'chest', neck.p(O), head.p(O)),
    ('head', 'neck', head.p(O), head.p((0, .4, 2.4))), ('jaw', 'head', jaw.p(O), jaw.p((0, -.3, 1.85))),
]
ANCHORS = [('fxMouth', 'head', head.p((0, .02, 2.6))), ('fxMouthFwd', 'head', head.p((0, -.35, 5.6)))]

# ---------------------------------------------------------------- torso
ell(hips, (0, 0, -.1), (2.35, 1.55, 1.85))
ell(hips, (0, -.2, -1.25), (1.2, 1.2, 1.2))
ell(spine, (0, .1, 0), (1.75, 1.9, 1.45))
CHc, CHs = Vec((0, .9, 0)), Vec((3.0, 3.4, 2.05))
ell(chest, CHc, CHs)
def on_chest(x, y): return CHs.z * math.sqrt(max(0, 1 - (x / CHs.x) ** 2 - ((y - CHc.y) / CHs.y) ** 2))
for s in (-1, 1):
    ell(chest, (s * 1.4, 2.05, 1.15), (1.3, 1.0, .8), (0, 0, -s * .15))  # pecs, flatter
    ell(chest, (s * .9, 3.6, -.2), (1.0, .8, .9))  # traps into the neck
    ell(chest, (s * 2.55, 2.5, -.1), (.9, .9, 1.0))  # deltoid root
    ell(chest, (s * 1.9, 1.2, -.9), (1.4, 2.2, 1.2))
    ell(chest, (s * 1.6, 3.3, -.3), (1.5, .9, 1.2))
    ell(spine, (s * 1.55, .2, .55), (.55, 1.3, .75))  # obliques
    for k in range(3):  # ribs / serratus under the pecs
        ell(chest, (s * 2.25, .2 - k * .6, .95 - k * .05), (.55, .22, .45), (0, 0, s * .5))
for i in range(3):
    y = -2.1 + i * .9; ell(chest, (0, y, on_chest(0, y) - .12), (1.35 - i * .05, .52, .18), group='belly')
for i in range(3):
    y = -1.0 + i * .75; ell(spine, (0, y, 1.45 * math.sqrt(1 - ((y - .1) / 1.9) ** 2) - .12), (1.25, .48, .18), group='belly')
ell(hips, (0, -.3, 1.55), (1.0, .5, .32), group='belly')

core_y = 1.1; core_z = on_chest(0, core_y)
CORE = (C(chest.p((0, core_y, core_z + .32))), chest.m.to_3x3())
ANCHORS.append(('fxCore', 'chest', chest.p((0, core_y, core_z + .5))))

VEINS = []
for i in range(9):
    x, y, ang = 0.0, core_y, i / 9 * math.tau + .3; L = 2.2 + (i % 3) * .7; pts = []
    for k in range(9):
        pts.append(C(chest.p((x, y, on_chest(x, y) + .035))))
        ang += math.sin(i * 3.1 + k) * .35; x += math.cos(ang) * L / 8; y += math.sin(ang) * L / 8
    VEINS.append(pts)

y = -2.2
while y <= 3.9:
    shard(chest, (0, y, -on_chest(0, y) + .12), (0, .55, -1), 1.0 + .5 * math.sin((y + 2.2) * .5), .3, 'violet')
    if y > -1:
        for s in (-1, 1): shard(chest, (s * .85, y + .3, -on_chest(s * .85, y + .3) + .12), (s * .45, .5, -1), .75, .22)
    y += .68
y = -.9
while y <= 1.0:
    shard(spine, (0, y, -1.45 * math.sqrt(1 - ((y - .1) / 1.9) ** 2) + .12), (0, .5, -1), .9, .27, 'violet'); y += .6

# ---------------------------------------------------------------- neck + head
cap(neck, (0, 0, 0), (0, 2.1, .75), 1.15, .8)
axis, nrm = Vec((0, 2.1, .75)), Vec((0, -.336, .94))
for k in range(4):
    f = .15 + k * .22; r = 1.15 + (.8 - 1.15) * f; p = axis * f
    ell(neck, p + nrm * (r * .82), (.62 - k * .05, .22, .3), group='belly')
    shard(neck, p - nrm * (r * .85), (0, .5, -1), 1.15 - k * .1, .26, 'violet')
# head: angular skull, long flat muzzle, overhanging brows, slanted eyes
ell(head, (0, .42, -.12), (.88, .78, 1.0))
ell(head, (0, .72, -.62), (.55, .5, .7))                        # back of the skull
ell(head, (0, .4, 1.3), (.4, .23, 1.3), (.06, 0, 0))            # flat muzzle top
ell(head, (0, .3, 2.35), (.26, .19, .42))                       # nose tip
for s in (-1, 1):
    ell(head, (s * .27, .12, 1.25), (.22, .25, 1.1), (0, -s * .14, 0))     # upper lip, narrowing to the nose
    ell(head, (s * .44, .74, .72), (.34, .17, .72), (0, -s * .22, s * .32))  # brow, slanting down to the nose
    ell(head, (s * .64, .26, .42), (.38, .3, .62))                         # cheekbone
    ell(head, (s * .72, .02, -.1), (.3, .36, .5))                          # jaw hinge
    ell(head, (s * .15, .4, 2.45), (.08, .06, .16), (0, s * .3, 0))       # nostril ridge
    ell(head, (s * .17, .37, 2.62), (.05, .02, .05), (0, s * .3, s * .5), group='mouth')  # nostril slit
    # eye: slanted almond with a slit pupil and a heavy lower lid
    ell(head, (s * .5, .58, 1.0), (.19, .075, .3), (0, -s * .4, s * .32), group='eyes')
    ell(head, (s * .6, .585, 1.08), (.022, .065, .05), (0, -s * .4, s * .32), group='dark')
    ell(head, (s * .5, .5, 1.02), (.26, .07, .36), (0, -s * .4, s * .32))
    # crystals: brow, crown, cheek frill
    shard(head, (s * .5, .88, .55), (s * .3, .6, -1), 1.1, .2)
    shard(head, (s * .42, .95, -.35), (s * .28, 1, -.55), 2.8, .32, 'blue', 6)
    shard(head, (s * .62, .9, -.12), (s * .5, 1, -.25), 1.7, .22, 'violet')
    shard(head, (s * .28, 1.02, -.05), (s * .15, 1, -.1), 1.3, .18)
    shard(head, (s * .7, .7, -.55), (s * .6, .8, -.6), 2.0, .24)
    shard(head, (s * .25, .85, -.8), (s * .15, .9, -1), 1.9, .22, 'violet')
    for k, (y, L) in enumerate(((.38, 1.4), (.12, 1.15), (-.14, .9), (-.36, .7))):
        shard(head, (s * .86, y, -.25 - k * .05), (s, .2 - k * .12, -.75), L, .2 - k * .03, 'blue' if k % 2 == 0 else 'violet')
    # teeth: fangs at the front, a row behind them
    shard(head, (s * .2, -.02, 2.15), (0, -1, .05), .5, .08, 'claw', 4)
    for k in range(6): shard(head, (s * (.34 - k * .02), -.04, 1.0 + k * .17), (0, -1, .08), .26, .05, 'claw', 4)
for k in range(6):  # ridge scales down the muzzle
    shard(head, (0, .66 - k * .035, .35 + k * .3), (0, 1, -.9), .5 - k * .05, .12, 'violet' if k % 2 else 'blue', 4)
shard(head, (0, 1.15, -.2), (0, 1, -.4), 1.6, .25, 'violet')
shard(head, (0, .95, -.75), (0, .6, -1), 1.3, .2, 'violet')
ell(head, (0, .0, 1.1), (.36, .1, .95), group='mouth')        # roof of the mouth
# lower jaw
cap(jaw, (0, 0, 0), (0, -.3, 1.85), .44, .24)
ell(jaw, (0, -.18, .9), (.46, .22, .85))
ell(jaw, (0, -.34, 1.72), (.24, .14, .26))                     # chin
for s in (-1, 1):
    ell(jaw, (s * .3, -.1, .6), (.22, .2, .55))
    shard(jaw, (s * .22, -.42, 1.25), (s * .25, -1, -.4), .45, .09)
    shard(jaw, (s * .36, -.3, .5), (s * .6, -.6, -.6), .6, .1, 'violet')
    shard(jaw, (s * .2, .02, 1.7), (0, 1, .05), .45, .07, 'claw', 4)
    for k in range(5):
        z = .7 + k * .2; shard(jaw, (s * .27, -.3 * z / 1.85 + .1, z), (0, 1, .08), .26, .05, 'claw', 4)
ell(jaw, (0, .02, 1.0), (.3, .08, .8), group='mouth')          # tongue
MOUTH = C(head.p((0, .02, 2.6)))

# ---------------------------------------------------------------- arms
for s in (1, -1):
    sh = J(chest, (s * 3.15, 1.75, -.1), (-.08, 0, s * .22))
    pad = Vec((s * .25, .25, 0))
    ell(sh, pad, (1.45, 1.3, 1.4))
    for i, (dx, dy, dz, L, r) in enumerate([(.35, 1, .05, 2.3, .36), (.85, .75, .35, 1.8, .3), (.6, .85, -.55, 1.7, .28), (1, .35, -.1, 1.4, .24), (.15, 1, .5, 1.3, .22), (.3, .9, -.9, 1.2, .2)]):
        d = Vec((s * dx, dy, dz)).normalized()
        shard(sh, pad + Vec((d.x * 1.25, d.y * 1.1, d.z * 1.2)), d, L, r, 'violet' if i % 2 else 'blue', 6)
    cap(sh, (0, 0, 0), (s * 1.0, -3.0, .2), .95, .78)
    ell(sh, (s * .55, -1.3, .15), (1.0, 1.5, .95))
    ell(sh, (s * .75, -1.7, -.45), (.7, 1.15, .65))  # triceps
    plate_row(sh, (s * .15, -.6, .1), (s * .85, -2.6, .2), (s, 0, 0), 4, 1.25, .85, .38, .42, .09)
    vein_on(sh, (s * .55, -1.3, .15), (1.0, 1.5, .95), 1, .7, -.75, s * .15, .12)
    el = J(sh, (s * 1.0, -3.0, .2), (-.42, 0, 0))
    tag = 'L' if s > 0 else 'R'
    BONES.append(('shoulder' + tag, 'chest', sh.p(O), el.p(O)))
    ell(el, (0, 0, 0), (.8, .8, .8))
    cap(el, (0, 0, 0), (s * .3, -2.8, .6), .82, .55)
    ell(el, (s * .12, -.9, .2), (.92, 1.35, .88))
    ell(el, (s * .3, -.5, .4), (.55, .95, .5))  # brachioradialis
    plate_row(el, (s * .05, -.4, .05), (s * .28, -2.5, .55), (s, 0, -.35), 5, .95, .6)
    vein_on(el, (s * .12, -.9, .2), (.92, 1.35, .88), 1, .7, -.8, s * .1, .15)
    vein_on(el, (s * .12, -.9, .2), (.92, 1.35, .88), 1, .55, -.85, -s * .3, .1)
    shard(el, (0, 0, -.55), (0, -.25, -1), 1.2, .26)
    for i, k in enumerate((.22, .48, .72)):
        shard(el, Vec((s * .3, -2.8, .6)) * k + Vec((s * .62, 0, -.35)), (s * .8, .45, -.6), 1.25 - .3 * i, .24)
    hand = J(el, (s * .3, -2.8, .6))
    BONES += [('elbow' + tag, 'shoulder' + tag, el.p(O), hand.p(O)), ('hand' + tag, 'elbow' + tag, hand.p(O), hand.p((0, -1.5, .1)))]
    ANCHORS.append(('fxHand' + tag, 'hand' + tag, hand.p((0, -.9, .2))))
    ell(hand, (0, -.35, .08), (.5, .55, .45))
    for z, dy in ((.36, 0), (.13, .04), (-.1, .02), (-.33, -.04)):
        f = J(hand, (s * .05, -.8 + dy, z), (0, 0, -s * .33))
        ell(hand, (s * .08, -.78 + dy, z), (.18, .15, .16))  # knuckle
        cap(f, (0, 0, 0), (0, -.6, 0), .19, .16, seg=12)
        f2 = J(f, (0, -.6, 0), (0, 0, -s * .5))
        cap(f2, (0, 0, 0), (0, -.45, 0), .16, .13, seg=12)
        shard(f2, (0, -.42, 0), (0, -1, 0), .7, .12, 'claw')
    th = J(hand, (-s * .3, -.45, .42))
    cap(th, (0, 0, 0), (-s * .15, -.55, .3), .15, .12, seg=12)
    shard(th, (-s * .15, -.55, .3), (-s * .2, -1, .5), .6, .12, 'claw')

# ---------------------------------------------------------------- legs
for s in (1, -1):
    hp = J(hips, (s * 1.45, -.35, 0))
    cap(hp, (0, 0, 0), (s * .4, -3.2, 1.1), 1.35, .95)
    ell(hp, (s * .3, -1.3, .4), (1.25, 1.9, 1.3))
    ell(hp, (s * .95, -1.2, -.2), (.7, 1.4, .9))  # outer thigh
    vein_on(hp, (s * .3, -1.3, .4), (1.25, 1.9, 1.3), 1, .75, -.8, s * .25, .1)
    vein_on(hp, (s * .3, -1.3, .4), (1.25, 1.9, 1.3), 1, .6, -.7, -s * .2, .12)
    shard(hp, (s * 1.25, -1.2, .1), (s, .3, -.4), 1.3, .3, 'violet')
    kn = J(hp, (s * .4, -3.2, 1.1))
    tag = 'L' if s > 0 else 'R'
    BONES.append(('thigh' + tag, 'hips', hp.p(O), kn.p(O)))
    ell(kn, (0, 0, 0), (.95, .95, .95))
    ell(kn, (0, .05, .55), (.55, .5, .38))  # kneecap
    plate_row(kn, (0, -.4, -.17), (0, -2.7, -1.17), (0, -.397, .917), 5, .85, .52, .36, .38)
    shard(kn, (0, .1, .75), (0, .35, 1), 1.0, .28)
    cap(kn, (0, 0, 0), (0, -3.0, -1.3), .85, .5)
    ell(kn, (0, -1.0, -.55), (.9, 1.55, .95))
    shard(kn, (0, -1.2, -1.25), (0, .2, -1), 1.0, .24, 'violet')
    an = J(kn, (0, -3.0, -1.3))
    BONES.append(('shin' + tag, 'thigh' + tag, kn.p(O), an.p(O)))
    ell(an, (0, 0, 0), (.55, .55, .55))
    cap(an, (0, 0, 0), (0, -1.7, .5), .52, .42)
    ft = J(an, (0, -1.7, .5))
    BONES += [('ankle' + tag, 'shin' + tag, an.p(O), ft.p(O)), ('foot' + tag, 'ankle' + tag, ft.p(O), ft.p((0, -.1, 1.8)))]
    ell(ft, (0, 0, .35), (.8, .38, .95))
    for x in (-.45, 0, .45):
        cap(ft, (x, 0, .7), (x * 1.35, -.12, 1.75), .24, .17, seg=14)
        shard(ft, (x * 1.35, -.12, 1.75), (x * .3, -.4, 1), .8, .16, 'claw')
    shard(ft, (0, 0, -.45), (0, -.3, -1), .7, .16, 'claw')

# ---------------------------------------------------------------- tail (Catmull-Rom through the same points as the page)
TP = [Vec(p) for p in [(0, -.2, -1.3), (0, -2.3, -3.4), (.7, -5.4, -5.6), (2.5, -7.3, -6.6), (5.2, -7.85, -5.4), (7.3, -7.9, -2.7), (8.4, -7.85, .4), (8.8, -7.7, 3.2)]]
def crom(u):
    n = len(TP) - 1; f = min(u * n, n - 1e-6); i = int(f); t = f - i
    p0, p1, p2, p3 = TP[max(i - 1, 0)], TP[i], TP[i + 1], TP[min(i + 2, n)]
    return .5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3)
tail_r = lambda u: .1 + 1.1 * (1 - u) ** 1.2
N_T = 70
tp = [crom(i / N_T) for i in range(N_T + 1)]
for i in range(N_T):
    u0, u1 = i / N_T, (i + 1) / N_T
    cap(hips, tp[i], tp[i + 1], tail_r(u0), tail_r(u1), seg=18, ends=(i % 3 == 0 or i == N_T - 1))
def tail_frame(u):
    P = crom(u); T = (crom(min(1, u + .01)) - crom(max(0, u - .01))).normalized()
    S = T.cross(Vec((0, 1, 0))); S = S.normalized() if S.length > 1e-3 else Vec((1, 0, 0))
    return P, T, S, S.cross(T).normalized()
for k in range(11):
    u = .04 + k * .075; P, T, S, N = tail_frame(u)
    shard(hips, P + N * (tail_r(u) * .8), N - T * .75, .5 + 1.3 * (1 - u), .12 + .28 * (1 - u), 'blue' if k % 2 else 'violet')
for k in range(19):  # belly plates under the tail
    u = .05 + k * .047; P, T, S, N = tail_frame(u); r = tail_r(u)
    ell_ax(hips, P - N * (r * .8), S * (r * .78), T * .34, N * (.12 + .1 * r), 'belly')
for k in range(10):
    BONES.append((f'tail{k}', 'hips' if k == 0 else f'tail{k - 1}', hips.p(crom(k / 10)), hips.p(crom((k + 1) / 10))))
ANCHORS.append(('fxTail', 'tail9', hips.p(crom(1))))
P, T, S, N = tail_frame(1)
for a, L, r in ((0, 2.8, .32), (.4, 2.1, .26), (-.4, 2.1, .26), (.75, 1.4, .2), (-.75, 1.4, .2)):
    shard(hips, P, T * math.cos(a) + N * (math.sin(abs(a)) * .6) + S * (math.sin(a) * .8), L, r, 'blue', 4)

# ---------------------------------------------------------------- wings
# Five curved finger bones; each span between them is a billowed grid with a scalloped
# trailing edge, and the last span runs down to the waist. Bones double as rig bones.
MEMBRANE = []   # quads: [(pos, uv) x4]
WING_EDGES = []
WING_REST = (.1, .55, .12)
def qbez(a, c, b, u): return a * (1 - u) ** 2 + c * (2 * u * (1 - u)) + b * (u * u)
for s in (1, -1):
    tag = 'L' if s > 0 else 'R'
    w = J(chest, (s * 1.15, 2.6, -1.55), (WING_REST[0], s * WING_REST[1], s * WING_REST[2]))
    Mi = lambda v: Vec((s * v[0], v[1], v[2]))          # author the left wing, mirror for the right
    P3 = lambda v: w.p(Mi(v))
    S_, E, W = Vec((0, 0, 0)), Vec((3.0, 2.2, -.9)), Vec((6.2, 4.6, -1.4))
    A = Vec((.9, -6.2, -.2))
    TIPS = [Vec(p) for p in ((10.5, 10.8, -1.9), (14.2, 7.4, -2.2), (15.0, 3.0, -2.0), (13.6, -1.4, -1.6), (10.4, -4.6, -1.0))]
    def finger(t):
        d = t - W; perp = Vec((d.y, -d.x, 0)).normalized()  # bow toward the trailing edge
        c = W.lerp(t, .5) + perp * (d.length * .07)
        return lambda u: qbez(W, c, t, u)
    F = [finger(t) for t in TIPS]
    body_edge = lambda u: S_.lerp(A, u) + Vec((.35 * math.sin(math.pi * u), 0, 0))
    # bones of the wing arm and fingers
    ell(w, Mi(S_), (.8, .8, .8), group='wingbone')
    cap(w, Mi(S_), Mi(E), .55, .4, 'wingbone'); ell(w, Mi(E), (.5, .5, .5), group='wingbone')
    cap(w, Mi(E), Mi(W), .4, .3, 'wingbone'); ell(w, Mi(W), (.45, .45, .45), group='wingbone')
    for f in F:
        for k in range(8):
            u0, u1 = k / 8, (k + 1) / 8
            cap(w, Mi(f(u0)), Mi(f(u1)), .24 - .18 * u0, .24 - .18 * u1, 'wingbone', seg=10, ends=(k in (0, 3, 7)))
        ell(w, Mi(f(.4)), (.15, .15, .15), group='wingbone')
        shard(w, Mi(f(1)), Mi(f(1) - f(.9)), .7, .08, 'claw', 4, group='wingclaw')
    shard(w, Mi(W), Mi(Vec((-.25, 1, .5))), 1.1, .17, 'claw', group='wingclaw')
    shard(w, Mi(W + Vec((.1, -.2, .2))), Mi(Vec((-.1, .6, .9))), .7, .12, 'claw', group='wingclaw')
    for k, a, b in ((.25, S_, E), (.6, S_, E), (.9, S_, E), (.3, E, W), (.65, E, W)):
        shard(w, Mi(a.lerp(b, k) + Vec((0, .35, 0))), Mi(Vec((-.3, 1, -.2))), 1.0 - .1 * k, .2, 'blue' if k < .5 else 'violet', group='wingcry')
    for k in (.2, .4, .6):
        shard(w, Mi(F[0](k) + Vec((-.15, .15, 0))), Mi(Vec((-.6, .6, -.2))), .7, .14, 'blue', group='wingcry')
    # membrane spans
    NU, NV = 16, 8
    spans = [(F[i], F[i + 1], .2) for i in range(4)] + [(F[4], body_edge, .16)]
    edge = []
    for si, (fa, fb, sc) in enumerate(spans):
        grid = []
        for iu in range(NU + 1):
            row = []
            for iv in range(NV + 1):
                u, v = iu / NU, iv / NV
                uu = u * (1 - sc * math.sin(math.pi * v))              # scallop
                q = fa(uu).lerp(fb(uu), v)
                q.z -= .45 * math.sin(math.pi * v) * math.sin(math.pi * uu * .9)  # billow
                row.append(q)
            grid.append(row)
        for iu in range(NU):
            for iv in range(NV):
                quad = [grid[iu][iv], grid[iu + 1][iv], grid[iu + 1][iv + 1], grid[iu][iv + 1]]
                if s < 0: quad = quad[::-1]
                MEMBRANE.append([(C(P3(q)), ((q.x + 1) / 17, (q.y + 7.5) / 19)) for q in quad])
        edge += [grid[NU][iv] for iv in range(NV + 1)][(1 if si else 0):]
    WING_EDGES.append([C(P3(q)) for q in edge])
    BONES += [('wing' + tag, 'chest', P3(S_), P3(E)), ('wingFore' + tag, 'wing' + tag, P3(E), P3(W))]
    BONES += [(f'wingF{i}{tag}', 'wingFore' + tag, P3(W), P3(t)) for i, t in enumerate(TIPS)]

# ---------------------------------------------------------------- textures (numpy)
def save_img(name, arr):
    h, w, _ = arr.shape
    img = bpy.data.images.new(name, w, h, alpha=True)
    img.pixels.foreach_set(np.ascontiguousarray(arr[::-1]).astype(np.float32).ravel())
    img.filepath_raw = os.path.join(TEX, name + '.png'); img.file_format = 'PNG'; img.save()
    img.filepath = img.filepath_raw
    return img

def galaxy(size, cx=.5, cy=.5, R=.42, tilt=.6, rot=.4, bg=True, seed=7):
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:size, 0:size] / size
    def fbm(fr0, n=7):
        acc = np.zeros_like(xx)
        for k in range(n):
            f = fr0 * 1.9 ** k; a = rng.random() * math.tau
            acc += np.sin((np.cos(a) * xx + np.sin(a) * yy) * f * math.tau + rng.random() * 9) / 1.6 ** k
        return acc * .5 + .5
    n1, n2, n3 = fbm(2), fbm(3), fbm(1.5)
    dx, dy = (xx - cx) / R, (yy - cy) / R / tilt
    r = np.sqrt(dx * dx + dy * dy) + 1e-4; th = np.arctan2(dy, dx)
    arm = (np.cos(2 * (th - rot) - 2.8 * np.log(r)) * .5 + .5) ** 2.2
    lane = arm * np.exp(-r * 1.25) * np.clip(1.7 - r, 0, 1) * (.55 + .9 * n1 * n2)
    purple, pink, blue = np.array([.55, .22, 1.]), np.array([1., .4, .9]), np.array([.3, .5, 1.])
    col = lane[..., None] * (purple * (1 - n3[..., None]) + pink * n3[..., None]) * 1.5
    col += (lane * n2)[..., None] * blue * .6
    col += np.exp(-(r / .12) ** 2)[..., None] * np.array([1., .92, 1.]) * 2.2
    col += np.exp(-(r / .38) ** 2)[..., None] * np.array([.65, .4, 1.]) * .9
    alpha = np.clip(col.max(-1), 0, 1)
    if bg:
        neb = np.clip(n1 * n3 * 1.6 - .35, 0, 1)
        col += np.array([.035, .025, .14]) + neb[..., None] * np.array([.25, .08, .45]) * .8
        alpha = np.ones_like(alpha)
        st = np.zeros_like(xx); idx = rng.integers(0, size, (int(size * size * .0016), 2))
        st[idx[:, 0], idx[:, 1]] = rng.random(len(idx)) * .8 + .2
        st = st + .35 * (np.roll(st, 1, 0) + np.roll(st, -1, 0) + np.roll(st, 1, 1) + np.roll(st, -1, 1))
        col += st[..., None] * np.array([.9, .92, 1.])
    return np.concatenate([np.clip(col, 0, 4), alpha[..., None]], -1)

wing_img = save_img('gd_wing_galaxy', galaxy(1024, .55, .52, .42, .6, .4, True, 7))
core_img = save_img('gd_core_swirl', galaxy(512, .5, .5, .48, 1., 0, False, 3))

# ---------------------------------------------------------------- materials
def nodes_of(mat):
    mat.use_nodes = True; nt = mat.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    return nt, nt.nodes, nt.links
def inp(node, *names):
    for n in names:
        if n in node.inputs: return node.inputs[n]
    raise KeyError(names)
def principled(nodes, base, rough=.5, metal=0., emit=None, estr=0.):
    p = nodes.new('ShaderNodeBsdfPrincipled')
    p.inputs['Base Color'].default_value = (*base, 1); p.inputs['Roughness'].default_value = rough; p.inputs['Metallic'].default_value = metal
    if emit: inp(p, 'Emission Color', 'Emission').default_value = (*emit, 1); p.inputs['Emission Strength'].default_value = estr
    return p
def out(nodes, links, shader):
    o = nodes.new('ShaderNodeOutputMaterial'); links.new(shader.outputs[0], o.inputs['Surface']); return o

def galaxy_skin(name, base, neb_gain=1.4, star_gain=3., rim=(.6, .36, 1.), rim_gain=1.2):
    mat = bpy.data.materials.new(name); nt, N, Lk = nodes_of(mat)
    tc = N.new('ShaderNodeTexCoord')
    n1 = N.new('ShaderNodeTexNoise'); n1.inputs['Scale'].default_value = .32; n1.inputs['Detail'].default_value = 6; n1.inputs['Roughness'].default_value = .55
    n2 = N.new('ShaderNodeTexNoise'); n2.inputs['Scale'].default_value = .7; n2.inputs['Detail'].default_value = 4
    Lk.new(tc.outputs['Object'], n1.inputs['Vector']); Lk.new(tc.outputs['Object'], n2.inputs['Vector'])
    lane = N.new('ShaderNodeValToRGB'); lane.color_ramp.elements[0].position = .56; lane.color_ramp.elements[1].position = .8
    Lk.new(n1.outputs['Fac'], lane.inputs['Fac'])
    hue = N.new('ShaderNodeValToRGB'); e = hue.color_ramp.elements
    e[0].position = .35; e[0].color = (.25, .08, .6, 1); e[1].position = .7; e[1].color = (.85, .25, 1., 1)
    b = hue.color_ramp.elements.new(.85); b.color = (.3, .55, 1., 1)
    Lk.new(n2.outputs['Fac'], hue.inputs['Fac'])
    neb = N.new('ShaderNodeMix'); neb.data_type = 'RGBA'; neb.blend_type = 'MULTIPLY'; neb.inputs['Factor'].default_value = 1
    Lk.new(hue.outputs['Color'], neb.inputs[6]); Lk.new(lane.outputs['Color'], neb.inputs[7])
    # stars: voronoi cells, only a few lit
    vo = N.new('ShaderNodeTexVoronoi'); vo.inputs['Scale'].default_value = 3.2; vo.inputs['Randomness'].default_value = .8
    Lk.new(tc.outputs['Object'], vo.inputs['Vector'])
    dist = N.new('ShaderNodeMapRange'); dist.inputs['From Min'].default_value = 0; dist.inputs['From Max'].default_value = .07; dist.inputs['To Min'].default_value = 1; dist.inputs['To Max'].default_value = 0
    Lk.new(vo.outputs['Distance'], dist.inputs['Value'])
    sep = N.new('ShaderNodeSeparateColor'); Lk.new(vo.outputs['Color'], sep.inputs['Color'])
    gt = N.new('ShaderNodeMath'); gt.operation = 'GREATER_THAN'; gt.inputs[1].default_value = .88; Lk.new(sep.outputs[0], gt.inputs[0])
    star = N.new('ShaderNodeMath'); star.operation = 'MULTIPLY'; Lk.new(dist.outputs['Result'], star.inputs[0]); Lk.new(gt.outputs[0], star.inputs[1])
    starg = N.new('ShaderNodeMath'); starg.operation = 'MULTIPLY'; starg.inputs[1].default_value = star_gain; Lk.new(star.outputs[0], starg.inputs[0])
    nebg = N.new('ShaderNodeVectorMath'); nebg.operation = 'SCALE'; inp(nebg, 'Scale').default_value = neb_gain; Lk.new(neb.outputs[2], nebg.inputs[0])
    emis = N.new('ShaderNodeVectorMath'); emis.operation = 'ADD'; Lk.new(nebg.outputs[0], emis.inputs[0]); Lk.new(starg.outputs[0], emis.inputs[1])
    # rim glow
    lw = N.new('ShaderNodeLayerWeight'); lw.inputs['Blend'].default_value = .35
    rimc = N.new('ShaderNodeVectorMath'); rimc.operation = 'SCALE'; rimc.inputs[0].default_value = rim; Lk.new(lw.outputs['Facing'], inp(rimc, 'Scale'))
    rimp = N.new('ShaderNodeMath'); rimp.operation = 'POWER'; rimp.inputs[1].default_value = 2.5
    Lk.new(lw.outputs['Facing'], rimp.inputs[0]); Lk.new(rimp.outputs[0], inp(rimc, 'Scale'))
    rims = N.new('ShaderNodeVectorMath'); rims.operation = 'SCALE'; inp(rims, 'Scale').default_value = rim_gain; Lk.new(rimc.outputs[0], rims.inputs[0])
    emis2 = N.new('ShaderNodeVectorMath'); emis2.operation = 'ADD'; Lk.new(emis.outputs[0], emis2.inputs[0]); Lk.new(rims.outputs[0], emis2.inputs[1])
    # base colour: dark navy lifted a little by the nebula
    basec = N.new('ShaderNodeMix'); basec.data_type = 'RGBA'; basec.blend_type = 'ADD'; basec.inputs['Factor'].default_value = .12
    basec.inputs[6].default_value = (*base, 1); Lk.new(neb.outputs[2], basec.inputs[7])
    p = principled(N, base, .45, .25, (1, 1, 1), 1.)
    Lk.new(basec.outputs[2], p.inputs['Base Color']); Lk.new(emis2.outputs[0], inp(p, 'Emission Color', 'Emission'))
    # small scales as bump
    sv = N.new('ShaderNodeTexVoronoi'); sv.inputs['Scale'].default_value = 5.5; sv.feature = 'DISTANCE_TO_EDGE'
    Lk.new(tc.outputs['Object'], sv.inputs['Vector'])
    bump = N.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = .35; bump.inputs['Distance'].default_value = .04
    Lk.new(sv.outputs['Distance'], bump.inputs['Height']); Lk.new(bump.outputs['Normal'], p.inputs['Normal'])
    out(N, Lk, p)
    mat['emit_node'] = 'emis2'
    return mat

M_SKIN = galaxy_skin('GD_Skin', (.012, .009, .09), 1.2, 3., (.45, .3, 1.), .8)
M_BELLY = galaxy_skin('GD_Belly', (.03, .025, .16), .5, 1.5, (.55, .5, 1.), .6)
M_BONE = galaxy_skin('GD_WingBone', (.01, .008, .07), 1.1, 2.5)

def simple(name, base, rough, metal, emit=None, estr=0., transmission=0.):
    mat = bpy.data.materials.new(name); nt, N, Lk = nodes_of(mat)
    p = principled(N, base, rough, metal, emit, estr)
    if transmission: inp(p, 'Transmission Weight', 'Transmission').default_value = transmission
    out(N, Lk, p); return mat
M_CRY = simple('GD_CrystalBlue', (.3, .42, 1.), .08, .1, (.1, .18, 1.), 2.0, .45)
M_VIO = simple('GD_CrystalViolet', (.5, .3, 1.), .08, .1, (.4, .1, 1.), 2.4, .45)
M_CLAW = simple('GD_Claw', (.8, .84, 1.), .2, .2, (.3, .35, 1.), .8)
M_DARK = simple('GD_Pupil', (.005, .003, .01), .3, 0)
M_MOUTH = simple('GD_MouthGlow', (.05, .01, .08), .5, 0, (.45, .08, .8), 2.5)
M_PLATE = galaxy_skin('GD_ScalePlates', (.02, .015, .12), .9, 2., (.6, .5, 1.), 1.3)
M_EYE = simple('GD_Eye', (.7, 1., 1.), .2, 0, (.5, .95, 1.), 25.)
M_VEIN = simple('GD_Vein', (.8, .4, 1.), .4, 0, (.9, .25, 1.), 2.)
M_EDGE = simple('GD_WingEdge', (.6, .75, 1.), .4, 0, (.45, .6, 1.), 2.5)
M_HUMAN = simple('GD_ScaleHuman', (.02, .02, .025), .8, 0)

M_MEM = bpy.data.materials.new('GD_WingMembrane'); nt, N, Lk = nodes_of(M_MEM)
M_MEM.use_backface_culling = False
ti = N.new('ShaderNodeTexImage'); ti.image = wing_img
p = principled(N, (.1, .1, .3), .7, 0, (1, 1, 1), 1.6)
Lk.new(ti.outputs['Color'], p.inputs['Base Color']); Lk.new(ti.outputs['Color'], inp(p, 'Emission Color', 'Emission'))
out(N, Lk, p)

M_CORE = bpy.data.materials.new('GD_Core'); nt, N, Lk = nodes_of(M_CORE)
ti = N.new('ShaderNodeTexImage'); ti.image = core_img
p = principled(N, (0, 0, 0), .5, 0, (1, 1, 1), 14.)
Lk.new(ti.outputs['Color'], inp(p, 'Emission Color', 'Emission')); Lk.new(ti.outputs['Alpha'], p.inputs['Alpha'])
out(N, Lk, p)
try: M_CORE.surface_render_method = 'BLENDED'
except Exception: pass

# ---------------------------------------------------------------- objects
col = bpy.data.collections.new('GalaxyDragon'); bpy.context.scene.collection.children.link(col)
def obj_from_bm(name, b, mats, smooth=True):
    me = bpy.data.meshes.new(name); b.to_mesh(me); b.free()
    for m in mats: me.materials.append(m)
    if smooth:
        for poly in me.polygons: poly.use_smooth = True
    ob = bpy.data.objects.new(name, me); col.objects.link(ob); return ob
def bake_mods(ob):
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    old = ob.data; nm = old.name; ob.modifiers.clear(); ob.data = me; bpy.data.meshes.remove(old); me.name = nm

print('remeshing body at voxel', VOXEL); sys.stdout.flush()
body = obj_from_bm('GD_Body', BM.pop('body'), [M_SKIN])
r = body.modifiers.new('Remesh', 'REMESH'); r.mode = 'VOXEL'; r.voxel_size = VOXEL; r.adaptivity = 0; r.use_smooth_shade = True
sm = body.modifiers.new('Blend', 'SMOOTH'); sm.factor = .9; sm.iterations = 14   # melt the seams between muscle forms
dec = body.modifiers.new('Decimate', 'DECIMATE'); dec.ratio = float(os.environ.get('GD_DECIMATE', '.24'))
bake_mods(body)
body.data.validate(clean_customdata=False)
for poly in body.data.polygons: poly.use_smooth = True
print('body polys', len(body.data.polygons)); sys.stdout.flush()

belly = obj_from_bm('GD_BellyPlates', BM.pop('belly'), [M_BELLY])
wingbone = obj_from_bm('GD_WingBones', BM.pop('wingbone'), [M_BONE])
crystals = obj_from_bm('GD_Crystals', BM.pop('crystals'), [M_CRY, M_VIO], smooth=False)
claws = obj_from_bm('GD_Claws', BM.pop('claws'), [M_CLAW], smooth=False)
eyes = obj_from_bm('GD_Eyes', BM.pop('eyes'), [M_EYE])
dark = obj_from_bm('GD_PupilsNostrils', BM.pop('dark'), [M_DARK])
mouth = obj_from_bm('GD_Mouth', BM.pop('mouth'), [M_MOUTH])
plates = obj_from_bm('GD_ScalePlates', BM.pop('plates'), [M_PLATE])

b = bmesh.new(); uvl = b.loops.layers.uv.new('UVMap')
for quad in MEMBRANE:
    vs = [b.verts.new(p) for p, _ in quad]; f = b.faces.new(vs)
    for loop, (_, uv) in zip(f.loops, quad): loop[uvl].uv = uv
bmesh.ops.remove_doubles(b, verts=b.verts, dist=.002)
membrane = obj_from_bm('GD_WingMembrane', b, [M_MEM], smooth=True)
sol = membrane.modifiers.new('Thickness', 'SOLIDIFY'); sol.thickness = .035; sol.offset = 0
bake_mods(membrane)
wingcry = obj_from_bm('GD_WingCrystals', BM.pop('wingcry'), [M_CRY, M_VIO], smooth=False)
wingclaw = obj_from_bm('GD_WingClaws', BM.pop('wingclaw'), [M_CLAW], smooth=False)

def curve_obj(name, pts_list, radius, mat):
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = radius; cu.bevel_resolution = 2
    for pts in pts_list:
        sp = cu.splines.new('NURBS'); sp.points.add(len(pts) - 1)
        for p, co in zip(sp.points, pts): p.co = (*co, 1)
        sp.use_endpoint_u = True; sp.order_u = 3
    cu.materials.append(mat)
    ob = bpy.data.objects.new(name, cu); col.objects.link(ob)
    dg = bpy.context.evaluated_depsgraph_get(); me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    col.objects.unlink(ob); bpy.data.objects.remove(ob); bpy.data.curves.remove(cu)
    mo = bpy.data.objects.new(name, me); col.objects.link(mo); return mo
veins = curve_obj('GD_Veins', VEINS + LIMB_VEINS, .035, M_VEIN)
edges = curve_obj('GD_WingEdges', WING_EDGES, .05, M_EDGE)

bpy.ops.mesh.primitive_circle_add(vertices=48, radius=1.45, fill_type='TRIFAN', location=CORE[0])
core = bpy.context.active_object; core.name = 'GD_ChestCore'
nz = C(CORE[1] @ Vec((0, 0, 1))) if False else (CM.to_3x3() @ (CORE[1] @ Vec((0, 0, 1))))
core.rotation_euler = Vec((0, 0, 1)).rotation_difference(nz).to_euler()
for c in core.users_collection: c.objects.unlink(core)
col.objects.link(core); core.data.materials.append(M_CORE)
uvl = core.data.uv_layers.new(name='UVMap')
for loop in core.data.loops:
    v = core.data.vertices[loop.vertex_index].co; uvl.data[loop.index].uv = (v.x / 2.9 + .5, v.y / 2.9 + .5)

rig_root = bpy.data.objects.new('GalaxyDragon', None); col.objects.link(rig_root); rig_root.empty_display_size = 3
PARTS = [body, belly, plates, wingbone, crystals, claws, eyes, dark, mouth, membrane, wingcry, wingclaw, veins, edges, core]

arm_data = bpy.data.armatures.new('GD_Rig'); arm = bpy.data.objects.new('GD_Rig', arm_data)
col.objects.link(arm); arm.parent = rig_root; arm.show_in_front = True
bpy.context.view_layer.objects.active = arm; arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name, parent, h, t in BONES:
    eb = arm_data.edit_bones.new(name); eb.head = C(h); eb.tail = C(t)
    if parent: eb.parent = arm_data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.view_layer.update()

# automatic weights by distance to each bone (less a body radius), smoothed over the 3 nearest
SEG = {n: (np.array(C(h)), np.array(C(t))) for n, _, h, t in BONES}
RAD = {'hips': 1.8, 'spine': 1.5, 'chest': 2.3, 'neck': .9, 'head': .6, 'jaw': .3}
for n in SEG:
    for key, r in (('shoulder', .8), ('elbow', .6), ('hand', .3), ('thigh', 1.0), ('shin', .6), ('ankle', .4), ('foot', .3), ('wingF', .08), ('wingFore', .25), ('wing', .35)):
        if n.startswith(key) and n not in RAD: RAD[n] = r
    if n.startswith('tail'): RAD[n] = tail_r((int(n[4:]) + .5) / 10) * .8
WING_OBJS = {membrane, wingbone, wingcry, wingclaw, edges}
def skin(ob):
    allowed = [n for n in SEG if (n.startswith('wing') or n in ('chest', 'spine')) == (ob in WING_OBJS) or n in ('chest', 'spine')]
    me = ob.data; co = np.empty(len(me.vertices) * 3); me.vertices.foreach_get('co', co)
    mw = np.array(ob.matrix_world); co = co.reshape(-1, 3) @ mw[:3, :3].T + mw[:3, 3]
    D = np.empty((len(co), len(allowed)))
    for k, n in enumerate(allowed):
        a, b = SEG[n]; ab = b - a; t = np.clip(((co - a) @ ab) / ab.dot(ab), 0, 1)
        D[:, k] = np.maximum(np.linalg.norm(co - (a + t[:, None] * ab), axis=1) - .6 * RAD[n], .03)
    Wt = 1 / D ** 4
    top = np.argsort(-Wt, axis=1)[:, :3]
    wv = np.take_along_axis(Wt, top, 1); wv /= wv.sum(1, keepdims=True)
    q = np.round(wv * 20) / 20
    for k, n in enumerate(allowed):
        vg = None
        for lvl in np.unique(q[top == k]):
            if lvl <= 0: continue
            idx = np.nonzero(((top == k) & (q == lvl)).any(1))[0].tolist()
            if vg is None: vg = ob.vertex_groups.new(name=n)
            vg.add(idx, float(lvl), 'REPLACE')
    mw_keep = ob.matrix_world.copy(); ob.parent = arm; ob.matrix_world = mw_keep
    m = ob.modifiers.new('Rig', 'ARMATURE'); m.object = arm
for ob in PARTS: skin(ob)
for name, bone, pos in ANCHORS:  # empties that ride on bones, for effects in the page
    e = bpy.data.objects.new(name, None); col.objects.link(e); e.empty_display_size = .4
    e.parent = arm; e.parent_type = 'BONE'; e.parent_bone = bone
    bpy.context.view_layer.update(); e.matrix_world = Matrix.Translation(C(pos))
print('rigged', len(BONES), 'bones'); sys.stdout.flush()

lamp = bpy.data.lights.new('GD_CoreLight', 'POINT'); lamp.color = (.7, .45, 1.); lamp.energy = 900; lamp.shadow_soft_size = .5
lo = bpy.data.objects.new('GD_CoreLight', lamp); lo.location = CORE[0] + Vec((0, -1.4, 0)); lo.parent = rig_root; col.objects.link(lo)
lamp = bpy.data.lights.new('GD_MouthLight', 'POINT'); lamp.color = (.6, .9, 1.); lamp.energy = 300
lo = bpy.data.objects.new('GD_EyeLight', lamp); lo.location = MOUTH + Vec((0, -1, .8)); lo.parent = rig_root; col.objects.link(lo)

# size reference (not exported)
ref = bpy.data.collections.new('ScaleReference'); bpy.context.scene.collection.children.link(ref)
hb = bmesh.new(); BM['human'] = hb
hum = J(None, (-9.5, 0, 7))
for s in (-1, 1):
    cap(hum, (s * .12, .08, 0), (s * .11, .92, 0), .1, .11, 'human', 10)
    cap(hum, (s * .27, 1.48, 0), (s * .33, .86, 0), .065, .055, 'human', 8)
ell(hum, (0, 1.22, 0), (.24, .36, .14), group='human'); ell(hum, (0, 1.68, 0), (.11, .13, .12), group='human')
hm = bpy.data.meshes.new('ScaleHuman_1.8m'); BM.pop('human').to_mesh(hm); hm.materials.append(M_HUMAN)
ho = bpy.data.objects.new('ScaleHuman_1.8m', hm); ref.objects.link(ho)

# ---------------------------------------------------------------- stage
scene = bpy.context.scene
world = bpy.data.worlds.new('GD_Space'); scene.world = world; nt, N, Lk = nodes_of(world)
tc = N.new('ShaderNodeTexCoord')
vo = N.new('ShaderNodeTexVoronoi'); vo.inputs['Scale'].default_value = 260; Lk.new(tc.outputs['Generated'], vo.inputs['Vector'])
mr = N.new('ShaderNodeMapRange'); mr.inputs['From Max'].default_value = .06; mr.inputs['To Min'].default_value = 1; mr.inputs['To Max'].default_value = 0
Lk.new(vo.outputs['Distance'], mr.inputs['Value'])
sep = N.new('ShaderNodeSeparateColor'); Lk.new(vo.outputs['Color'], sep.inputs['Color'])
gt = N.new('ShaderNodeMath'); gt.operation = 'GREATER_THAN'; gt.inputs[1].default_value = .9; Lk.new(sep.outputs[0], gt.inputs[0])
st = N.new('ShaderNodeMath'); st.operation = 'MULTIPLY'; Lk.new(mr.outputs['Result'], st.inputs[0]); Lk.new(gt.outputs[0], st.inputs[1])
nn = N.new('ShaderNodeTexNoise'); nn.inputs['Scale'].default_value = 2.5; nn.inputs['Detail'].default_value = 8; Lk.new(tc.outputs['Generated'], nn.inputs['Vector'])
cr = N.new('ShaderNodeValToRGB'); e = cr.color_ramp.elements; e[0].position = .45; e[0].color = (.004, .003, .015, 1); e[1].position = .82; e[1].color = (.06, .02, .14, 1)
Lk.new(nn.outputs['Fac'], cr.inputs['Fac'])
mx = N.new('ShaderNodeMix'); mx.data_type = 'RGBA'; mx.blend_type = 'ADD'; mx.inputs['Factor'].default_value = 1
Lk.new(cr.outputs['Color'], mx.inputs[6]); Lk.new(st.outputs[0], mx.inputs[7])
bg = N.new('ShaderNodeBackground'); Lk.new(mx.outputs[2], bg.inputs['Color'])
wo = N.new('ShaderNodeOutputWorld'); Lk.new(bg.outputs[0], wo.inputs['Surface'])

stage = bpy.data.collections.new('Stage'); scene.collection.children.link(stage)
bpy.ops.mesh.primitive_circle_add(vertices=96, radius=150, fill_type='NGON')
ground = bpy.context.active_object; ground.name = 'Ground'
for c in ground.users_collection: c.objects.unlink(ground)
stage.objects.link(ground)
ground.data.materials.append(simple('GD_Ground', (.012, .01, .04), .62, .3))
def light(name, kind, energy, color, loc, rot=None, size=None):
    L = bpy.data.lights.new(name, kind); L.energy = energy; L.color = color
    if size is not None: L.size = size
    o = bpy.data.objects.new(name, L); o.location = loc
    if rot: o.rotation_euler = rot
    stage.objects.link(o); return o
def aim(o, target):
    o.rotation_euler = (Vec(target) - o.location).to_track_quat('-Z', 'Y').to_euler()
k = light('Key', 'SUN', 1.8, (.88, .9, 1.), (0, 0, 0)); k.rotation_euler = Euler((math.radians(50), 0, math.radians(-35)))
for name, e, c, loc in (('RimViolet', 26000, (.7, .36, 1.), (-18, 22, 14)), ('RimCyan', 22000, (.31, .78, 1.), (20, 18, 12)), ('Fill', 5000, (.5, .5, 1.), (10, -30, 8))):
    o = light(name, 'AREA', e, c, loc, size=10); aim(o, (0, 0, 11))

cam = bpy.data.cameras.new('Cam'); cam.lens = 50; cam.clip_end = 3000
co = bpy.data.objects.new('Camera', cam); stage.objects.link(co); scene.camera = co
co.location = (34, -44, 20); aim(co, (0, 0, 10.5))

engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items]
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in engines else 'BLENDER_EEVEE'
scene.view_settings.view_transform = 'AgX' if 'AgX' in [i.identifier for i in scene.view_settings.bl_rna.properties['view_transform'].enum_items] else 'Filmic'
scene.view_settings.look = 'None'
try: scene.eevee.taa_render_samples = 64
except Exception: pass

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, 'galaxy_dragon.blend'))
print('saved blend'); sys.stdout.flush()

# ---------------------------------------------------------------- bake procedural skins -> textures, export GLB
def bake_to(ob, mat, name, size):
    for o in bpy.context.view_layer.objects: o.select_set(False)
    bpy.context.view_layer.objects.active = ob; ob.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=.002)
    bpy.ops.object.mode_set(mode='OBJECT')
    out_imgs = {}
    for kind in ('EMIT', 'DIFFUSE', 'NORMAL'):
        img = bpy.data.images.new(f'{name}_{kind.lower()}', size, size, float_buffer=(kind == 'EMIT'))
        if kind == 'NORMAL': img.colorspace_settings.name = 'Non-Color'
        tn = mat.node_tree.nodes.new('ShaderNodeTexImage'); tn.image = img
        mat.node_tree.nodes.active = tn
        if kind == 'EMIT': bpy.ops.object.bake(type='EMIT', margin=4)
        elif kind == 'NORMAL': bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT', margin=4)
        else: bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, margin=4)
        mat.node_tree.nodes.remove(tn)
        img.filepath_raw = os.path.join(TEX, f'{name}_{kind.lower()}.png'); img.file_format = 'PNG'; img.save()
        out_imgs[kind] = img
        print('baked', name, kind); sys.stdout.flush()
    m = bpy.data.materials.new(mat.name + '_Baked'); nt, N, Lk = nodes_of(m)
    p = principled(N, (0, 0, 0), .45, .25, (1, 1, 1), 1.)
    a = N.new('ShaderNodeTexImage'); a.image = out_imgs['DIFFUSE']; Lk.new(a.outputs['Color'], p.inputs['Base Color'])
    e = N.new('ShaderNodeTexImage'); e.image = out_imgs['EMIT']; Lk.new(e.outputs['Color'], inp(p, 'Emission Color', 'Emission'))
    nm = N.new('ShaderNodeTexImage'); nm.image = out_imgs['NORMAL']; nmap = N.new('ShaderNodeNormalMap')
    Lk.new(nm.outputs['Color'], nmap.inputs['Color']); Lk.new(nmap.outputs['Normal'], p.inputs['Normal'])
    out(N, Lk, p)
    return m

if BAKE:
    scene.render.engine = 'CYCLES'; scene.cycles.samples = 1; scene.cycles.device = 'CPU'
    swaps = [(body, bake_to(body, M_SKIN, 'gd_body', 2048)), (belly, bake_to(belly, M_BELLY, 'gd_belly', 1024)), (wingbone, bake_to(wingbone, M_BONE, 'gd_wingbone', 1024)), (plates, bake_to(plates, M_PLATE, 'gd_plates', 1024))]
    for ob, m in swaps: ob.data.materials[0] = m

for o in bpy.context.view_layer.objects: o.select_set(False)
for ob in PARTS + [rig_root, arm] + [o for o in col.objects if o.name.startswith('fx')]: ob.select_set(True)
opts = dict(filepath=os.path.join(HERE, 'galaxy_dragon.glb'), export_format='GLB', use_selection=True, export_apply=True,
            export_lights=False, export_cameras=False, export_skins=True, export_animations=False,
            export_draco_mesh_compression_enable=True, export_draco_mesh_compression_level=6, export_image_format='WEBP')
try: bpy.ops.export_scene.gltf(**opts)
except TypeError as e:
    print('export option fallback:', e); opts.pop('export_image_format'); bpy.ops.export_scene.gltf(**opts)
print('exported glb'); sys.stdout.flush()
