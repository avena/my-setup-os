# Guia de Edição - Plantadeira Matraca Manual no Blender 5.2

## Visão Geral

Projeto de modelagem 3D de uma plantadeira manual de sementes (matraca) desenvolvido em 24 etapas sequenciais no Blender 5.2 LTS.

**Arquivo final:** `/home/livre/blender/plantadeira_matraca_v24.blend` (também em `C:/Users/randomacesso/AppData/Local/Temp/plantadeira_matraca_v24.blend`)

**Especificações:**
- Unidades métricas: 1 BU = 1 mm (unit scale 0.001)
- Coleção principal: `Plantadeira_Matraca_Manual`
- 5 materiais finais: `Mat_Aco_Zincado`, `Mat_Chao`, `Mat_Madeira_Torneada`, `Mat_Plastico_Preto_Tecnico`, `Mat_Verde_Agricola`
- 31 objetos na cena final
- Render engine: EEVEE (BLENDER_EEVEE)

---

## Como Executar Scripts no Blender 5.2 (Windows)

O Blender roda no Windows. Caminhos Linux **não** são acessíveis diretamente pelo Blender.

### Comando base

```bash
/mnt/c/Program\ Files/Blender\ Foundation/Blender\ 5.2/blender.exe --background --python "C:/Users/randomacesso/AppData/Local/Temp/script.py"
```

### Fluxo de trabalho recomendado

1. Escrever o script Python em `/tmp/opencode/etapaN_exec.py`
2. Copiar para o Windows Temp:
   ```bash
   cp /tmp/opencode/etapaN_exec.py "/mnt/c/Users/randomacesso/AppData/Local/Temp/etapaN_exec.py"
   ```
3. Executar:
   ```bash
   "/mnt/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --python "C:/Users/randomacesso/AppData/Local/Temp/etapaN_exec.py"
   ```
4. Copiar o .blend de volta para o Linux:
   ```bash
   cp "/mnt/c/Users/randomacesso/AppData/Local/Temp/plantadeira_matraca_vNN.blend" /home/livre/blender/
   ```

---

## Regras Críticas (Blender 5.2)

| Problema | Solução |
|----------|---------|
| Caminhos Linux não funcionam no Blender | Usar sempre caminhos Windows `C:/Users/...` |
| Aspas duplas quebram JSON | Usar apenas aspas simples `'` nos scripts Python enviados via MCP |
| `matrix_parent_inverse` manual não funciona | Usar `bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)` |
| `BLENDER_EEVEE_NEXT` não existe no Blender 5.2 | Usar `BLENDER_EEVEE` |
| `drivers.clear()` não existe | Iterar e remover: `for drv in list(obj.animation_data.drivers): obj.animation_data.drivers.remove(drv)` |
| Referência `S = bpy.context.scene` se invalida após salvar | Chamar `bpy.context.scene` diretamente ou usar uma função `def S(): return bpy.context.scene` |
| Imagens não exibem via `look()` | Incompatibilidade filesystem Linux/Windows |

---

## Estrutura de Hierarquia (Etapa 2)

```
RAIZ:
  ├─ Camera
  ├─ Chao
  ├─ CTRL_Matraca (raiz da plantadeira, em 0,0,0)
  │   ├─ Arruela_Eixo_A
  │   ├─ Arruela_Eixo_B
  │   ├─ Braco_Estatico_Guia
  │   │   ├─ Ponteira_Bico_Fixo
  │   │   ├─ Manopla_Madeira_Esq
  │   │   ├─ Reservatorio_Sementes_Funil
  │   │   ├─ Flange_Reservatorio
  │   │   ├─ Braccadeira_Reservatorio
  │   │   ├─ Tampa_Reservatorio
  │   │   └─ Tubo_Condutor_Sementes
  │   ├─ Braco_Movel_Alavanca
  │   │   ├─ Ponteira_Bico_Movel
  │   │   └─ Manopla_Madeira_Dir
  │   ├─ Eixo_Pivo_Articulacao
  │   ├─ Porca_Eixo
  │   └─ Mola_Retorno_Helicoidal
  ├─ Fundo_Estudio
  ├─ Luz_Key
  ├─ Luz_Fill
  └─ Luz_Rim
```

---

## Especificações por Etapa

| Etapa | Conteúdo | Valores-chave |
|-------|----------|---------------|
| 1 | Unificar materiais duplicados | 5 materiais finais, 10 duplicados removidos |
| 2 | Hierarquia com Keep Transform | CTRL_Matraca raiz; braços filhos do CTRL; peças filhas dos braços |
| 3 | Assentar no chão | CTRL_Matraca desce 853.523 mm; ponteiras em Z=0 |
| 4 | Mola entre braços | Eixo X horizontal, z=320, comprimento 75.36 mm, entre faces internas dos braços |
| 5 | Tampa no reservatório | z=508.3–512.3, Solidify 4 mm, face inferior em z=508.3 |
| 6 | Flange | z≈505, Solidify 3 mm, Ø163 mm |
| 7 | Braçadeira | Anel completo Ø143 mm, z=468.3, concêntrica com reservatório, folga 0.6 mm/lado |
| 8 | Tubo condutor | Ø40 mm, conecta reservatório (z=196.7) à ponteira fixa (z=0), sem frestas |
| 9 | Manopla Madeira Esq/Dir | Cilindro madeira, nas pontas dos braços |
| 10 | Etiqueta | Placa no reservatório, material verde |
| 11 | Furos | 4 furos na braçadeira, Ø6 mm |
| 12 | Alças D | Torus achatado em aço |
| 13 | Botão | Cilindro plástico preto no braço móvel |
| 14 | Ponteira invertida | Rotacionada 180° em X |
| 15 | Materiais aplicados | 24 objetos com seus materiais finais |
| 16 | Fundo estúdio | Chão + painel infinito |
| 17 | Câmera retrato | 1080×1920, lente 50mm |
| 18 | Luz 3 pontos | Key (SUN), Fill (AREA), Rim (AREA) |
| 19 | Driver de articulação | Ponteira movel ↔ braço móvel (rotação Z e loc Y) |
| 20 | Ajustes finais materiais | Confirmação de 5 materiais em todos os objetos |
| 21 | Cena final | EEVEE, 128 amostras, câmera retrato |
| 22 | Render final HQ | Retrato + frontal alta qualidade |
| 23 | Múltiplos ângulos | 8 renders (frontal, laterais, 3/4, traseira, topo, baixo) |
| 24 | Versão final | v24.blend salvo + relatório |

---

## Scripts Úteis

### Inspecionar um arquivo .blend

```python
import bpy
from mathutils import Vector

print("=== OBJETOS ===")
for o in bpy.data.objects:
    parent = o.parent.name if o.parent else "RAIZ"
    print(f"  {o.name:35s} | tipo={o.type:10s} | parent={parent}")

print("\n=== MATERIAIS ===")
for m in bpy.data.materials:
    print(f"  {m.name}")

print("\n=== LIMITES DAS PEÇAS ===")
for nome in ["Ponteira_Bico_Fixo", "Ponteira_Bico_Movel", "Reservatorio_Sementes_Funil",
             "Tubo_Condutor_Sementes", "Mola_Retorno_Helicoidal"]:
    o = bpy.data.objects.get(nome)
    if o:
        bb = o.bound_box
        wc = [o.matrix_world @ Vector(c) for c in bb]
        minv = Vector((min(c.x for c in wc), min(c.y for c in wc), min(c.z for c in wc)))
        maxv = Vector((max(c.x for c in wc), max(c.y for c in wc), max(c.z for c in wc)))
        print(f"  {nome:30s} Z: {minv.z:.1f}-{maxv.z:.1f} X: {minv.x:.1f}-{maxv.x:.1f} Y: {minv.y:.1f}-{maxv.y:.1f}")
```

### Carregar v08 e executar etapas 9-24 em sequência

```python
import bpy, os
from mathutils import Vector, Matrix

TMP = r"C:/Users/randomacesso/AppData/Local/Temp/"
bpy.ops.wm.open_mainfile(filepath=TMP + "plantadeira_matraca_v08.blend")

for etapa in range(9, 25):
    script = TMP + f"etapa{etapa:02d}_exec.py"
    if os.path.exists(script):
        print(f"=== Etapa {etapa} ===")
        exec(open(script).read())
```

### Render 3 vistas (frontal/lateral/3/4)

```python
import bpy
from mathutils import Vector

S = bpy.context.scene
cam = bpy.data.objects["Camera"]

def mirar(target=Vector((0.0, 0.0, 400.0))):
    dirc = target - cam.location
    cam.rotation_euler = dirc.to_track_quat('-Z', 'Y').to_euler()

def render(path):
    S.render.filepath = path
    bpy.ops.render.render(write_still=True)

TMP = r"C:/Users/randomacesso/AppData/Local/Temp/"
cam.location = Vector((0.0, -2200.0, 700.0)); mirar(); render(TMP + "frontal.png")
cam.location = Vector((2200.0, 0.0, 700.0)); mirar(); render(TMP + "lateral.png")
cam.location = Vector((1600.0, -1600.0, 1000.0)); mirar(); render(TMP + "34.png")
```

### Parent com Keep Transform (forma correta no Blender 5.2)

```python
import bpy

def parent_keep(filho, pai):
    for o in bpy.data.objects:
        o.select_set(False)
    pai.select_set(True); filho.select_set(True)
    bpy.context.view_layer.objects.active = pai
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    bpy.context.view_layer.update()

# Uso
parent_keep(bpy.data.objects["ObjetoFilho"], bpy.data.objects["ObjetoPai"])
```

---

## Arquivos Gerados

**Blends (por etapa):**
- `plantadeira_matraca_v01.blend` … `v24.blend` — um por etapa

**Renders (por etapa, 3 vistas):**
- `etapaN_frontal.png`, `etapaN_lateral.png`, `etapaN_34.png`

**Renders adicionais:**
- `etapa17_retrato.png` — câmera retrato
- `etapa22_retrato_final.png`, `etapa22_frontal_hq.png` — alta qualidade
- `etapa23_*.png` — 8 ângulos diferentes

Todos salvos em `C:/Users/randomacesso/AppData/Local/Temp/` e copiados para `/home/livre/blender/`.

---

## Solução de Problemas Comuns

**"StructRNA of type Scene has been removed"**
- Causa: referência `S = bpy.context.scene` capturada antes de `wm.save_as_mainfile` ou `wm.open_mainfile`.
- Solução: usar `bpy.context.scene` diretamente após operações de arquivo, ou envolver em função `def S(): return bpy.context.scene`.

**"enum not found in ('BLENDER_EEVEE', 'BLENDER_WORKBENCH', 'CYCLES')**
- Causa: `BLENDER_EEVEE_NEXT` não existe no Blender 5.2.
- Solução: usar `S.render.engine = 'BLENDER_EEVEE'`.

**"AttributeError: 'SceneEEVEE' object has no attribute 'use_ssr'"**
- Causa: propriedades do EEVEE mudaram no Blender 5.2.
- Solução: envolver em `try/except` ou remover propriedades não suportadas.

**"bpy_prop_collection: attribute 'clear' not found"**
- Causa: `drivers.clear()` não existe.
- Solução: `for drv in list(obj.animation_data.drivers): obj.animation_data.drivers.remove(drv)`.

---

## Notas

- O usuário solicitou execução em sequência sem perguntar entre etapas.
- Commit entre cada etapa (salvar .blend a cada etapa).
- 3 renders de conferência após cada etapa (frontal, lateral, 3/4).
- Blender 5.2.3 LTS (hash e13b728c6880, built 2026-10-22).