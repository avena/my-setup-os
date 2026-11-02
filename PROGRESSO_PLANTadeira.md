# Status do Projeto — Plantadeira Matraca Manual (Blender 5.2)

## Estado Atual

**Último arquivo salvo:** `plantadeira_matraca_v09.blend` (etapa 9 concluída)

**Caminho:** `C:/Users/randomacesso/blender/plantadeira_matraca_v09.blend`

**Estado do v09:**
- 20 objetos, 5 materiais
- Hierarquia correta (CTRL_Matraca raiz → braços → peças)
- CTRL_Matraca em (0, 0, -441.2) — assentado no chão
- Mola entre braços em Z=-121.2, eixo X, 75.3 mm
- Tampa no topo do reservatório em Z=440.7, Solidify 4 mm
- Flange na boca do reservatório em Z=440.7-441.7, Solidify 3 mm
- Abraçadeira: anel Ø143.8 mm, X=-107.5, Y=0, Z=400.7, Solidify 2 mm
- Tubo condutor: conecta reservatório (Z=129.0, X=-107.5) à ponteira fixa (Z=5.0, X=23.7), gap 0 mm
- Manopla_Madeira_Esq: ponta do braço estático (X=-193.3, Z=93.8)
- Manopla_Madeira_Dir: ponta do braço móvel (X=194.2, Z=93.5)

## Materiais (5 finais)
Mat_Aco_Zincado, Mat_Chao, Mat_Madeira_Torneada, Mat_Plastico_Preto_Tecnico, Mat_Verde_Agricola

## Etapas Concluídas

| Etapa | Conteúdo | Status | Arquivo |
|-------|----------|--------|---------|
| 1 | Unificar materiais duplicados | ✅ | v01.blend |
| 2 | Hierarquia com Keep Transform | ✅ | v02.blend |
| 3 | Assentar no chão | ✅ | v03.blend |
| 4 | Mola entre braços | ✅ | v04.blend |
| 5 | Tampa no topo do reservatório | ✅ | v05.blend |
| 6 | Flange na borda | ✅ | v06.blend |
| 7 | Abraçadeira abraçando de verdade | ✅ | v07.blend |
| 8 | Encaixe do tubo condutor | ✅ | v08.blend |
| 9 | Manopla Madeira Esq/Dir nas pontas dos braços | ✅ | v09.blend |

## Etapas Pendentes (10-24)

Conforme GUIA_BLENDER_PLANTadeira.md (valores DESATUALIZADOS vs estado real):

| Etapa | Conteúdo | Status |
|-------|----------|--------|
| 10 | Etiqueta no reservatório (material verde) | ⏳ |
| 11 | 4 Furos na braçadeira (Ø6 mm) | ⏳ |
| 12 | Alças D (torus achatado em aço) | ⏳ |
| 13 | Botão (cilindro plástico preto no braço móvel) | ⏳ |
| 14 | Ponteira invertida (rotacionada 180° em X) | ⏳ |
| 15 | Materiais aplicados (confirmação) | ⏳ |
| 16 | Fundo estúdio (chão + painel infinito) | ⏳ |
| 17 | Câmera retrato (1080×1920, lente 50mm) | ⏳ |
| 18 | Luz 3 pontos (Key SUN, Fill AREA, Rim AREA) | ⏳ |
| 19 | Driver de articulação (ponteira móvel ↔ braço móvel) | ⏳ |
| 20 | Ajustes finais materiais | ⏳ |
| 21 | Cena final (EEVEE, 128 amostras, câmera retrato) | ⏳ |
| 22 | Render final HQ | ⏳ |
| 23 | Múltiplos ângulos (8 renders) | ⏳ |
| 24 | Versão final (v24.blend + relatório) | ⏳ |

**Nota:** O arquivo `plantadeira_matraca_v24.blend` já existe no disco (31 objetos, estado diferente do v09) — provavelmente de uma sessão anterior com roteiro antigo. Não é confiável como base para continuar.

## Observações Técnicas

- Blender: `/mnt/c/Program Files/Blender Foundation/Blender 5.2/blender.exe` (5.2.3 LTS)
- Scripts Python em: `/mnt/c/Users/randomacesso/AppData/Local/Temp/etapaN_exec.py`
- Blends salvos em: `C:/Users/randomacesso/blender/plantadeira_matraca_vNN.blend`
- Caminhos Linux (`/home/livre/...`) NÃO funcionam no Blender Windows
- Usar apenas aspas simples em scripts Python (evita quebra de JSON)
- Para reparentar mantendo posição mundial: salvar `matrix_world` antes de desparentar, restaurar após, depois `matrix_parent_inverse = pai.matrix_world.inverted() @ world_pos @ matrix_local.inverted()`
- `bpy.ops.object.parent_set` não funciona em modo background; usar método direto com `matrix_parent_inverse`
- `origin_set(type='ORIGIN_GEOMETRY')` para recentar origem antes de reposicionar objetos deslocados
