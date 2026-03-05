# Fontes para Linux/macOS

Este diretório contém scripts para instalação de fontes no Linux e macOS.

## Arquivos

- **install-fonts.sh**: Script para instalação automática de fontes
- **README.md**: Este arquivo

## Instalação

```bash
chmod +x install-fonts.sh  # Adiciona permissões de execução
./install-fonts.sh
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

### Terminator (Linux)
Adicione ao `~/.config/terminator/config`:
```ini
[global_config]
  font = Fira Code NF 11
```

### iTerm2 (macOS)
Configuração via Interface:
1. Preferências > Profiles > Text
2. Selecione "Fira Code NF" como fonte

## Solução de Problemas

### Permissões de Execução
Se o script não executar:
```bash
chmod +x install-fonts.sh
```

### Fontes Não Detectadas
Execute para atualizar o cache de fontes:
```bash
fc-cache -fv
```

Reinicie o VS Code ou o terminal.