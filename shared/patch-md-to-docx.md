# Patch local — md-to-docx

Correções aplicadas em `~/.agents/skills/md-to-docx/scripts/md_to_docx.py`
em **2026-11-16**. Reaplicar após qualquer `evercli skill install` /
`evercli skill update` do `openclaw/skills/md-to-docx`.

## Por que existe

O script original tinha dois defeitos que aparecem em qualquer relatório
com texto formatado. Ambos foram reproduzidos e corrigidos.

## Correção 1 — texto formatado saía duplicado

**Sintoma.** `**Pendência:** outorga vencida` virava
`Pendência:Pendência: outorga vencida` no `.docx`.

**Causa.** `parse_inline()` usava `re.split()` com um padrão de **6 grupos
de captura**. `re.split` devolve o match inteiro *e* o conteúdo de cada
grupo, então cada trecho formatado entrava na lista duas vezes:

```python
re.split(r'(\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|...)', '**Pendencia:** x')
# ['', '**Pendencia:**', None, 'Pendencia:', None, None, None, ' x']
#       ^ match completo   ^ grupos vazios     ^ conteúdo real
```

O laço então processava tanto `'**Pendencia:**'` quanto `'Pendencia:'`,
gerando dois runs.

**Correção.** Troca de `re.split` por `re.finditer` com **grupos nomeados**,
acompanhando `pos` manualmente para emitir os trechos sem formatação entre
matches. Elimina a ambiguidade na origem em vez de filtrar duplicatas depois.

## Correção 2 — títulos não tinham nível de tópico

**Sintoma.** Os títulos tinham fonte/tamanho/negrito corretos, mas eram
parágrafos `Normal`. Consequências: não apareciam no painel de navegação do
Word, não entravam em sumário automático, e não eram reconhecidos como
estrutura por leitores de tela ou por `pandoc`.

**Causa.** O script aplicava formatação visual direta e nunca gravava
`w:outlineLvl` no `pPr`.

**Correção.** Em `add_paragraph()`, para níveis de título, grava
`<w:outlineLvl>` direto no XML (o `python-docx` não expõe
`paragraph_format.outline_level`) e marca `keep_with_next`:

```python
outline_map = {'chapter_title': 0, 'section_title': 1,
               'subsection_title': 2, 'heading4': 3}
```

## Como reaplicar

```bash
bash ~/my-setup-os/shared/instalar-skills-documentos.sh   # reinstala a skill
# depois reaplique este patch (as duas edições acima)
```

Se o `evercli` passar a entregar uma versão já corrigida, o patch vira
no-op — verifique com:

```bash
cd /tmp && printf '**teste**\n' > t.md
python3 ~/.agents/skills/md-to-docx/scripts/md_to_docx.py t.md -o t.docx
pandoc -t plain t.docx   # deve imprimir "teste", não "teste:teste"
```

## Limitações conhecidas (não corrigidas)

| Limitação | Impacto | Alternativa |
|---|---|---|
| Listas usam `• ` como texto, sem `w:numPr` | Não são listas reais do Word; contadores e recuo automático não funcionam | Skill `docx` com config `numbering` |
| Títulos sem `w:pStyle` `Heading*` | Sumário automático do Word não os coleta (mas navegação funciona via `outlineLvl`) | Skill `docx` com `styles.default.heading1..n` |
| Sem suporte a imagens, links e notas de rodapé | URLs e imagens ficam como texto | Skill `docx` |
| Mermaid exige `mmdc` + Chrome | Sem eles, o diagrama cai para bloco de código | Instalar `@mermaid-js/mermaid-cli` |
| Nested lists achatadas em 1 nível | Sublistas perdem hierarquia | Skill `docx` |

Regra prática: **`md-to-docx` para converter rascunho rápido; `docx` quando o
documento precisa de sumário, listas reais ou layout fino.**

---

*Aplicado por sessão de agente em 2026-11-16*
