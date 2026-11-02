import bpy
from mathutils import Vector

print("=== OBJETOS NA CENA ===")
for o in bpy.data.objects:
    parent = o.parent.name if o.parent else "RAIZ"
    print(f"  {o.name:35s} | tipo={o.type:10s} | parent={parent}")

print(f"\nTOTAL: {len(bpy.data.objects)} objetos")

print("\n=== MATERIAIS ===")
for m in bpy.data.materials:
    print(f"  {m.name}")

print(f"\nTOTAL MATERIAIS: {len(bpy.data.materials)}")

print("\n=== LIMITES DAS PEÇAS PRINCIPAIS ===")
for nome in ["Ponteira_Bico_Fixo", "Ponteira_Bico_Movel", "Reservatorio_Sementes_Funil",
             "Tubo_Condutor_Sementes", "Mola_Retorno_Helicoidal", "Braco_Estatico_Guia",
             "Braco_Movel_Alavanca", "Manopla_Madeira_Esq", "Manopla_Madeira_Dir",
             "Botao_Acionamento", "Tampa_Reservatorio", "Flange_Reservatorio",
             "Braccadeira_Reservatorio", "Etiqueta_Reservatorio"]:
    o = bpy.data.objects.get(nome)
    if o:
        bb = o.bound_box
        wc = [o.matrix_world @ Vector(c) for c in bb]
        minv = Vector((min(c.x for c in wc), min(c.y for c in wc), min(c.z for c in wc)))
        maxv = Vector((max(c.x for c in wc), max(c.y for c in wc), max(c.z for c in wc)))
        print(f"  {nome:30s} Z: {minv.z:8.1f}-{maxv.z:8.1f} X: {minv.x:8.1f}-{maxv.x:8.1f} Y: {minv.y:8.1f}-{maxv.y:8.1f}")
    else:
        print(f"  {nome:30s} NAO ENCONTRADO")
