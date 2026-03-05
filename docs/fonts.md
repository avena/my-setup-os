# Fontes para Desenvolvimento

Este documento descreve como instalar e configurar fontes para editores de código e terminais no ambiente cross-platform.

## Fontes Instaladas

Os scripts instalam as seguintes fontes:

### Fontes Originais (clean versions)
- **Fira Code**: Fonte monoespaçada com suporte a ligaduras de código
- **JetBrains Mono**: Fonte otimizada para desenvolvimento em JetBrains IDEs
- **Cascadia Code**: Fonte oficial da Microsoft para desenvolvimento

### Nerd Fonts (com ícones para terminais)
- **Fira Code NF**: Fira Code com patches do Nerd Fonts (ícones para terminais)
- **JetBrains Mono NF**: JetBrains Mono com patches do Nerd Fonts
- **Cascadia Code NF**: Cascadia Code com patches do Nerd Fonts

## Instalação

### Windows

**Requisito**: Scoop (https://scoop.sh/)

```powershell
# Instalação automática
cd windows/fonts/
.\install-fonts.ps1
```

**Detalhes**:
- O script instala fontes via Scoop
- Adiciona o bucket `nerd-fonts` se não existir
- Instala tanto as versões originais quanto as Nerd Fonts
- Fontes são instaladas no `C:\Users\<usuario>\scoop\apps\`

### Linux/macOS

**Suporta**: apt (Debian/Ubuntu), dnf (Fedora), pacman (Arch), Homebrew (macOS)

```bash
# Instalação automática
cd linux/fonts/
./install-fonts.sh
```

**Detalhes**:
- Detecta automaticamente o sistema operacional e gerenciador de pacotes
- No Linux, usa Nerd Fonts installer se não encontrar pacotes oficial
- No macOS, usa Homebrew para instalar fontes
- Fontes são instaladas em `~/.local/share/fonts/` (Linux) ou `~/Library/Fonts/` (macOS)

## Configuração em Editores

### VS Code

As fontes são configuradas no `settings/fragments/10-editor.json`:

```json
{
  "editor.fontFamily": "'Fira Code', 'JetBrains Mono', 'Cascadia Code', 'Consolas', monospace",
  "editor.fontLigatures": true
}
```

### Terminal Windows

Configuração no `settings.json` do Windows Terminal:

```json
{
  "profiles": {
    "defaults": {
      "fontFace": "Fira Code NF"
    }
  }
}
```

### Terminator (Linux)

Configuração no `~/.config/terminator/config`:

```ini
[global_config]
  font = Fira Code NF 11
```

## Verificação

Para verificar se as fontes estão instaladas:

### Windows
```powershell
Get-ChildItem -Path "C:\Users\$env:USERNAME\scoop\apps" -Filter "*FiraCode*"
```

### Linux
```bash
fc-list | grep -i "fira code"
```

### macOS
```bash
fc-list | grep -i "fira code"
```

## Solução de Problemas

### Fontes Não Detectadas pelo VS Code
1. Reinicie o VS Code
2. Verifique se o caminho do Scoop está no PATH
3. Execute `scoop reset` para atualizar o cache

### Fontes Não Detectadas pelo Terminal
1. Reinicie o terminal
2. Verifique se as fontes estão no diretório correto
3. Execute `fc-cache -fv` para atualizar o cache de fontes (Linux/macOS)

### Permissões no Linux
Se o script não executar, adicione permissões de execução:
```bash
chmod +x install-fonts.sh
```