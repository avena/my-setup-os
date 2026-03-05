# Fontes para Windows

Este diretório contém scripts para instalação de fontes no Windows.

## Arquivos

- **install-fonts.ps1**: Script para instalação automática de fontes via Scoop
- **README.md**: Este arquivo

## Instalação

**Requisito**: Scoop (https://scoop.sh/)

```powershell
.\install-fonts.ps1
```

## Fontes Instaladas

### Fontes Originais (clean versions)
- Fira Code
- JetBrains Mono
- Cascadia Code

### Nerd Fonts (com ícones para terminais)
- Fira Code NF
- JetBrains Mono NF
- Cascadia Code NF

## Configuração

### VS Code
As fontes são configuradas automaticamente via `settings/fragments/10-editor.json`.

### Windows Terminal
Adicione ao `settings.json`:
```json
{
  "profiles": {
    "defaults": {
      "fontFace": "Fira Code NF"
    }
  }
}
```

## Solução de Problemas

### Scoop Não Encontrado
Execute para instalar o Scoop:
```powershell
irm get.scoop.sh | iex
```

### Fontes Não Detectadas
Reinicie o VS Code ou o terminal para detectar as novas fontes.