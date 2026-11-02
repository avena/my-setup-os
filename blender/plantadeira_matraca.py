# Plantadeira Manual de Sementes (matraca / bico fino) - modelo parametrico 1:1
# API nativa bpy (Blender). Unidades: 1 BU = 1 mm.
# Executar dentro do Blender (Text Editor ou via console). Nenhuma dependencia externa.
import bpy, bmesh, math
from mathutils import Vector, Matrix

# ---------------------------------------------------------------- cena / unidades
S = bpy.context.scene
u = S.unit_settings
u.system = 'METRIC'
u.scale_length = 0.001          # 1 BU = 1 mm
u.length_unit = 'MILLIMETERS'
S.frame_start, S.frame_end = 1, 60
S.render.fps = 30
try:
    S.render.engine = 'BLENDER_EEVEE_NEXT'
except Exception:
    S.render.engine = 'BLENDER_EEVEE'

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for c in list(bpy.data.collections):
    bpy.data.collections.remove(c)

COL = bpy.data.collections.new('Plantadeira_Matraca_Manual')
S.collection.children.link(COL)

def link(o):
    COL.objects.link(o)
    return o

def finish(o, mat=None, thick=None, bev=True):
    if mat:
        o.data.materials.append(mat)
    if thick:
        m = o.modifiers.new('Solidify', 'SOLIDIFY')
        m.thickness = thick
        m.offset = 0.0
        m.use_even_offset = True
    if bev:
        m = o.modifiers.new('Bevel', 'BEVEL')
        m.width = 1.0
        m.segments = 2
        m.limit_method = 'ANGLE'
        m.angle_limit = math.radians(35)
        m.use_clamp_overlap = True
    for p in o.data.polygons:
        p.use_smooth = True
    try:
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
    except Exception:
        pass
    return o

def mesh(n, v, f, mat=None, th=None):
    me = bpy.data.meshes.new(n)
    me.from_pydata([tuple(x) for x in v], [], f)
    me.update()
    o = link(bpy.data.objects.new(n, me))
    return finish(o, mat, th)

def seth(o, p):
    """Recoloca a origem (pivo) do objeto no ponto `p` do mundo."""
    p = Vector(p)
    o.data.transform(Matrix.Translation(-p))
    o.location = p

def mat(n, h, rg, mt, b=0.0, sc=0.05):
    m = bpy.data.materials.new(n)
    m.use_nodes = True
    nt = m.node_tree
    bs = next(x for x in nt.nodes if x.type == 'BSDF_PRINCIPLED')
    hs = h.lstrip('#')
    cs = []
    for i in (0, 2, 4):
        c = int(hs[i:i + 2], 16) / 255.0
        cs.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    bs.inputs['Base Color'].default_value = (*cs, 1)
    bs.inputs['Roughness'].default_value = rg
    bs.inputs['Metallic'].default_value = mt
    m.diffuse_color = (*cs, 1)
    if b:
        tc = nt.nodes.new('ShaderNodeTexCoord')
        nz = nt.nodes.new('ShaderNodeTexNoise')
        nz.inputs['Scale'].default_value = sc
        bp = nt.nodes.new('ShaderNodeBump')
        bp.inputs['Strength'].default_value = b
        nt.links.new(tc.outputs['Object'], nz.inputs['Vector'])
        nt.links.new(nz.outputs['Fac'], bp.inputs['Height'])
        nt.links.new(bp.outputs['Normal'], bs.inputs['Normal'])
    return m

# ---------------------------------------------------------------- materiais PBR
gMV = mat('Mat_Verde_Agricola', '#236B2B', 0.35, 0.08, 0.12)     # chapa verde
gMM = mat('Mat_Madeira_Torneada', '#C49A45', 0.55, 0.0, 0.25, 0.35)  # madeira
gMP = mat('Mat_Plastico_Preto_Tecnico', '#1C1C1C', 0.65, 0.0, 0.05)  # tampa
gMA = mat('Mat_Aco_Zincado', '#C0C0C0', 0.22, 1.0)               # aço

CH = 1.8          # espessura chapa
PIV = Vector((0.0, 0.0, 240.0))   # centro do eixo de articulacao (240 mm acima do bico)

# ---------------------------------------------------------------- braços (chapa em U)
L, W, H = 750, 40, 20

def uch(n, length, td, mo):
    pts = [(-W / 2, 0), (W / 2, 0), (W / 2, H), (-W / 2, H)]
    nn = len(pts)
    v = []
    for x, y in pts:
        v.append(Vector((x, y, 0.0)))
    for x, y in pts:
        v.append(Vector((x, y, length)))
    f = []
    for i in range(nn - 1):
        f.append((i, i + 1, nn + i + 1, nn + i))
    f.append(tuple(range(nn - 1, -1, -1)))
    f.append(tuple(range(nn, 2 * nn)))
    o = mesh(n, [tuple(x) for x in v], f, mo, CH)
    zd = Vector((0, 0, 1))
    td = Vector(td).normalized()
    ax = zd.cross(td)
    ag = zd.angle(td)
    if ax.length > 1e-6:
        R = Matrix.Rotation(ag, 4, ax.normalized())
        for p in o.data.vertices:
            p.co = R @ p.co
    o.data.update()
    off = td * 70.0          # pivo a 70 mm da base (perto da ponteira)
    for p in o.data.vertices:
        p.co -= off
    o.data.update()
    o.location = PIV         # pivo no centro do eixo de articulacao
    return o

def dd(s):
    return (s * 180.0, 0.0, 680.0)

OBS = uch('Braco_Estatico_Guia', L, dd(-1), gMV)     # lado reservatorio
OBM = uch('Braco_Movel_Alavanca', L, dd(+1), gMV)    # lado articulado

# ---------------------------------------------------------------- manoplas madeira
def man(n, loc, rot, mo):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=16,
                          depth=115, radius1=15, radius2=15, matrix=Matrix.Identity(4))
    me = bpy.data.meshes.new(n)
    bm.to_mesh(me)
    bm.free()
    o = link(bpy.data.objects.new(n, me))
    finish(o, mo, None, True)
    o.location = loc
    o.rotation_euler = rot
    return o

dirE = Vector(dd(-1)).normalized()
topE = dirE * 680 + PIV
M1 = man('Manopla_Madeira_Esq', topE, (0, 0, 0), gMM)
dirM = Vector(dd(+1)).normalized()
topM = dirM * 680 + PIV
M2 = man('Manopla_Madeira_Dir', topM, (0, math.radians(20), 0), gMM)  # dobra ergonômica

# ---------------------------------------------------------------- reservatorio (tronco-piramidal)
bm = bmesh.new()
bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=16,
                      depth=310, radius1=70, radius2=22.5, matrix=Matrix.Identity(4))
me = bpy.data.meshes.new('Reservatorio_Sementes_Funil')
bm.to_mesh(me)
bm.free()
RES = link(bpy.data.objects.new('Reservatorio_Sementes_Funil', me))
finish(RES, gMV, CH, True)
seth(RES, (0, 0, 0))
dirE = Vector(dd(-1)).normalized()
RES.location = PIV + dirE * 210 + Vector((0, 0, 40))  # 280 mm da extremidade inferior da ponteira

# ---------------------------------------------------------------- tampa
TAM = mesh('Tampa_Reservatorio',
           [(-67.5, -50, 0), (67.5, -50, 0), (67.5, 50, 0), (-67.5, 50, 0)],
           [(0, 1, 2, 3)], gMP, None)
seth(TAM, (0, 0, 0))
TAM.location = RES.location + Vector((0, 0, 310))

# ---------------------------------------------------------------- ponteiras (cunha, origem no eixo)
def ponteira(n, sinal, mo):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=8,
                          depth=210, radius1=30, radius2=7.5, matrix=Matrix.Identity(4))
    me = bpy.data.meshes.new(n)
    bm.to_mesh(me)
    bm.free()
    o = link(bpy.data.objects.new(n, me))
    finish(o, mo, CH, True)
    for p in o.data.vertices:
        p.co.z -= 210          # ponta no extremo inferior local
    o.data.update()
    o.location = PIV + Vector((sinal * 30, 0, 0))      # folga mecanica entre fixa/movel
    return o

PF = ponteira('Ponteira_Bico_Fixo', -1, gMA)
PM = ponteira('Ponteira_Bico_Movel', +1, gMA)

# ---------------------------------------------------------------- parenting das ponteiras nos braços
obEsq = bpy.data.objects['Braco_Estatico_Guia']
obDir = bpy.data.objects['Braco_Movel_Alavanca']
obPF = bpy.data.objects['Ponteira_Bico_Fixo']
obPM = bpy.data.objects['Ponteira_Bico_Movel']

def dd(s):
    return (s * 180.0, 0.0, 680.0)

dirE = Vector(dd(-1)).normalized()
dirM = Vector(dd(+1)).normalized()

obPF.location = PIV - dirE * 70
obPF.rotation_euler = (0, 0, 0)
obPF.data.update()
obPM.location = PIV - dirM * 70
obPM.rotation_euler = (0, 0, 0)
obPM.data.update()

obPF.parent = obEsq
obPM.parent = obDir
obPF.matrix_parent_inverse = obEsq.matrix_world.inverted() @ obPF.matrix_world
obPM.matrix_parent_inverse = obDir.matrix_world.inverted() @ obPM.matrix_world
obPF.update_from_editmode()
obPM.update_from_editmode()

# ---------------------------------------------------------------- flange circular na abertura superior do reservatorio
bm = bmesh.new()
rf_in = 70.0
rf_out = 80.0
esp = 3.0
h_flange = -1.0
seg = 32
vtop_in = []
vtop_out = []
vbot_in = []
vbot_out = []
for i in range(seg):
    a = 2 * math.pi * i / seg
    vtop_in.append(bm.verts.new((rf_in * math.cos(a), rf_in * math.sin(a), 0)))
    vtop_out.append(bm.verts.new((rf_out * math.cos(a), rf_out * math.sin(a), 0)))
    vbot_in.append(bm.verts.new((rf_in * math.cos(a), rf_in * math.sin(a), h_flange)))
    vbot_out.append(bm.verts.new((rf_out * math.cos(a), rf_out * math.sin(a), h_flange)))
for i in range(seg):
    i2 = (i + 1) % seg
    bm.faces.new((vtop_in[i], vtop_in[i2], vbot_in[i2], vbot_in[i]))
    bm.faces.new((vtop_out[i], vtop_out[i2], vbot_out[i2], vbot_out[i]))
    bm.faces.new((vtop_out[i], vtop_out[i2], vtop_in[i2], vtop_in[i]))
    bm.faces.new((vbot_in[i], vbot_in[i2], vbot_out[i2], vbot_out[i]))
me = bpy.data.meshes.new('Flange_Reservatorio')
bm.to_mesh(me)
bm.free()
FL = link(bpy.data.objects.new('Flange_Reservatorio', me))
FL.data.materials.append(gVER)
for p in FL.data.polygons:
    p.use_smooth = True
FL.location = RES.location
FL.rotation_euler = RES.rotation_euler

# ---------------------------------------------------------------- braccadeira metálica em volta do reservatorio
bm = bmesh.new()
R_res = 72.0
R_bracc = 78.0
h_bracc = 6.0
seg = 24
ang_inicial = -math.pi / 2
ang_final = math.pi / 2
vs = []
for i in range(seg + 1):
    a = ang_inicial + (ang_final - ang_inicial) * i / seg
    cx = RES.location.x + R_bracc * math.cos(a)
    cy = RES.location.y + R_bracc * math.sin(a)
    cz = RES.location.z + 155
    sseg = 8
    ring = []
    for j in range(sseg):
        b = 2 * math.pi * j / sseg
        nr = Vector((0, math.cos(a), math.sin(a))).normalized()
        nt = Vector((0, -math.sin(a), math.cos(a))).normalized()
        nx = Vector((1, 0, 0))
        off = nr * math.cos(b) * 2.0 + nt * math.sin(b) * 2.0
        ring.append(bm.verts.new((cx + off.x, cy + off.y, cz + off.z)))
    vs.append(ring)
for i in range(seg):
    for j in range(sseg):
        j2 = (j + 1) % sseg
        bm.faces.new((vs[i][j], vs[i][j2], vs[i + 1][j2], vs[i + 1][j]))
for ring_idx in (0, seg):
    bm.faces.new(vs[ring_idx])
me = bpy.data.meshes.new('Braccadeira_Reservatorio')
bm.to_mesh(me)
bm.free()
BR = link(bpy.data.objects.new('Braccadeira_Reservatorio', me))
BR.data.materials.append(gMA)
for p in BR.data.polygons:
    p.use_smooth = True
BR.location = Vector((0, 0, 0))

# ---------------------------------------------------------------- tubo condutor / calha do fundo do funil ao bico de pato
def tubo_condutor(nome, start, end, raio, mo):
    bm = bmesh.new()
    seg = 16
    direcao = (end - start)
    comprimento = direcao.length
    eixo = direcao.normalized()
    ref = Vector((0.0, 0.0, 1.0)) if abs(eixo.z) < 0.9 else Vector((0.0, 1.0, 0.0))
    u = eixo.cross(ref).normalized()
    v = eixo.cross(u).normalized()
    nseg = 8
    rings = []
    for i in range(nseg + 1):
        t = i / nseg
        centro = start + eixo * (comprimento * t)
        ring = []
        for j in range(seg):
            a = 2 * math.pi * j / seg
            ponto = centro + u * (raio * math.cos(a)) + v * (raio * math.sin(a))
            ring.append(bm.verts.new(ponto))
        rings.append(ring)
    for i in range(nseg):
        for j in range(seg):
            j2 = (j + 1) % seg
            bm.faces.new((rings[i][j], rings[i][j2], rings[i + 1][j2], rings[i + 1][j]))
    bm.faces.new(rings[0])
    bm.faces.new(rings[nseg])
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = link(bpy.data.objects.new(nome, me))
    finish(o, mo, None, True)
    return o

saida = Vector((RES.location.x, RES.location.y, 327.0))
entrada = Vector((0.0, 0.0, 130.0))
tubo = tubo_condutor('Tubo_Condutor_Sementes', saida, entrada, 20.0, gMA)

# ---------------------------------------------------------------- parafuso sextavado M8 x 65 + arruelas + porca autotravante
def parafuso(nome, loc, mo):
    bm = bmesh.new()
    Rcab = 7.0
    hcab = 5.5
    Rhaste = 4.0
    Lhaste = 65.0
    seg = 24
    vt = []
    for i in range(6):
        a = math.pi / 3 * i
        vt.append(bm.verts.new((Rcab * math.cos(a), Rcab * math.sin(a), hcab / 2)))
    bm.faces.new(vt)
    vb = []
    for v in vt:
        vb.append(bm.verts.new((v.co.x, v.co.y, -hcab / 2)))
    bm.faces.new(vb)
    for i in range(6):
        i2 = (i + 1) % 6
        bm.faces.new((vt[i], vt[i2], vb[i2], vb[i]))
    vtop = []
    vbot = []
    for i in range(seg + 1):
        a = 2 * math.pi * i / seg
        vtop.append(bm.verts.new((Rhaste * math.cos(a), Rhaste * math.sin(a), -hcab / 2)))
        vbot.append(bm.verts.new((Rhaste * math.cos(a), Rhaste * math.sin(a), -hcab / 2 - Lhaste)))
    for i in range(seg):
        bm.faces.new((vtop[i], vtop[i + 1], vbot[i + 1], vbot[i]))
    bm.faces.new(vbot)
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = link(bpy.data.objects.new(nome, me))
    finish(o, mo, None, True)
    o.location = loc
    o.rotation_euler = (math.radians(90), 0, 0)
    return o

PARA = parafuso('Eixo_Pivo_Articulacao', PIV, gMA)

def arruela(nome, r1, r2, h, loc, mo):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=24, depth=h, radius1=r1, radius2=r2, matrix=Matrix.Identity(4))
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = link(bpy.data.objects.new(nome, me))
    finish(o, mo, None, True)
    o.location = loc
    o.rotation_euler = (math.radians(90), 0, 0)
    return o

arruela('Arruela_Eixo_A', 4.5, 8.0, 1.6, PIV + Vector((0.0, 33.0, 0.0)), gMA)
arruela('Arruela_Eixo_B', 4.5, 8.0, 1.6, PIV + Vector((0.0, -33.0, 0.0)), gMA)

def porca(nome, loc, mo):
    bm = bmesh.new()
    R = 7.0
    h = 8.0
    vt = []
    for i in range(6):
        a = math.pi / 3 * i
        vt.append(bm.verts.new((R * math.cos(a), R * math.sin(a), h / 2)))
    bm.faces.new(vt)
    vb = []
    for v in vt:
        vb.append(bm.verts.new((v.co.x, v.co.y, -h / 2)))
    bm.faces.new(vb)
    for i in range(6):
        i2 = (i + 1) % 6
        bm.faces.new((vt[i], vt[i2], vb[i2], vb[i]))
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = link(bpy.data.objects.new(nome, me))
    finish(o, mo, None, True)
    o.location = loc
    o.rotation_euler = (math.radians(90), 0, 0)
    return o

PORCA = porca('Porca_Eixo', PIV + Vector((0.0, 45.0, 0.0)), gMA)

# ---------------------------------------------------------------- mola helicoidal tracao
def mola(n, mo):
    bm = bmesh.new()
    N, seg, Lm, R, rf, voltas = 24, 12, 60, 7, 2, 4
    pts = []
    for k in range(N + 1):
        t = k / N
        y = 240 - Lm / 2 + t * Lm
        a = t * voltas * 2 * math.pi
        for s in range(seg):
            sa = 2 * math.pi * s / seg
            pts.append(Vector((R * math.cos(a) + rf * math.cos(sa),
                               y,
                               R * math.sin(a) + rf * math.sin(sa))))
    for k in range(N):
        for s in range(seg):
            i0 = k * seg + s
            i1 = k * seg + (s + 1) % seg
            i2 = (k + 1) * seg + (s + 1) % seg
            i3 = (k + 1) * seg + s
            bm.faces.new((bm.verts.new(pts[i0]), bm.verts.new(pts[i1]),
                          bm.verts.new(pts[i2]), bm.verts.new(pts[i3])))
    me = bpy.data.meshes.new(n)
    bm.to_mesh(me)
    bm.free()
    o = link(bpy.data.objects.new(n, me))
    finish(o, mo, None, True)
    return o

MOL = mola('Mola_Retorno_Helicoidal', gMA)

# ---------------------------------------------------------------- empty de controle
CTRL = bpy.data.objects.new('CTRL_Matraca', None)
COL.objects.link(CTRL)
CTRL.location = PIV

# ---------------------------------------------------------------- vista explodida (60 frames)
anims = {
    'Manopla_Madeira_Esq': (0, 0, 100),        # +100 mm ao longo do eixo de insercao
    'Manopla_Madeira_Dir': (0, 0, 100),
    'Tampa_Reservatorio': (0, 0, 150),         # sobe +150 mm em Z
    'Reservatorio_Sementes_Funil': (-120, 0, 0), # afasta -120 mm em X local
    'Braco_Movel_Alavanca': (140, 0, 0),       # translada +140 mm em X
    'Ponteira_Bico_Movel': (80, 0, -50),       # +80 mm em X, desce -50 mm em Z
    'Eixo_Pivo_Articulacao': (0, 100, 0),      # expande lateralmente em Y
    'Mola_Retorno_Helicoidal': (0, -100, 0),   # expande lateralmente em Y (oposto)
}
for n, d in anims.items():
    if n not in bpy.data.objects:
        continue
    o = bpy.data.objects[n]
    o.animation_data_clear()
    o.delta_location = (0, 0, 0)
    o.keyframe_insert(data_path='delta_location', frame=1)
    o.delta_location = d
    o.keyframe_insert(data_path='delta_location', frame=60)
    # interpolacao BEZIER suave (API 5.2: fcurves estao em strip.channelbags)
    act = o.animation_data.action
    for lay in act.layers:
        for st in lay.strips:
            for cb in st.channelbags.values():
                for fc in cb.fcurves:
                    for kp in fc.keyframe_points:
                        kp.interpolation = 'BEZIER'

# ---------------------------------------------------------------- camera centralizada
cam = bpy.data.objects.get('Camera')
if cam is None:
    me_cam = bpy.data.cameras.new('Camera')
    cam = bpy.data.objects.new('Camera', me_cam)
    bpy.context.scene.collection.objects.link(cam)
cam.location = Vector((1300.0, -1300.0, 950.0))
tgt = Vector((0.0, 0.0, 460.0))
dirc = tgt - cam.location
cam.rotation_euler = dirc.to_track_quat('-Z', 'Y').to_euler()
S.camera = cam
S.frame_set(1)

# ---------------------------------------------------------------- parent das ponteiras nos braços
obEsq=bpy.data.objects['Braco_Estatico_Guia']
obDir=bpy.data.objects['Braco_Movel_Alavanca']
obPF=bpy.data.objects['Ponteira_Bico_Fixo']
obPM=bpy.data.objects['Ponteira_Bico_Movel']
# alinhar nas extremidades inferiores dos braços (70 mm antes do pivô)
L=750
def dd(s):return(s*180.0,0.0,680.0)
dirE=Vector(dd(-1)).normalized()
dirM=Vector(dd(+1)).normalized()
PIV=Vector((0.0,0.0,240.0))
obPF.location=PIV - dirE*70
obPF.rotation_euler=(0,0,0)
obPM.location=PIV - dirM*70
obPM.rotation_euler=(0,0,0)
obPF.data.update(); obPM.data.update()
obPF.parent=obEsq
obPM.parent=obDir
obPF.matrix_parent_inverse=obEsq.matrix_world.inverted()@obPF.matrix_world
obPM.matrix_parent_inverse=obDir.matrix_world.inverted()@obPM.matrix_world
obPF.update_from_editmode(); obPM.update_from_editmode()
bpy.context.view_layer.update()
print('Ponteiras parentizadas e alinhadas nas extremidades dos braços')
print('Plantadeira_Matraca_Manual construída:', [o.name for o in COL.objects])
