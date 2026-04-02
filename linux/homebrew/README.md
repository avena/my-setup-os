# Homebrew para Linux/WSL

Este diretório contém scripts para instalação e gerenciamento do Homebrew no Linux e WSL.

## Arquivos

- **install-homebrew.sh**: Script para instalação automática do Homebrew
- **Brewfile**: Lista declarativa de pacotes para instalação
- **install-brew-packages.sh**: Script para instalar pacotes do Brewfile
- **README.md**: Este arquivo

## Instalação

### 1. Instalar o Homebrew

```bash
chmod +x install-homebrew.sh
./install-homebrew.sh
```

### 2. Instalar os Pacotes

```bash
chmod +x install-brew-packages.sh
./install-brew-packages.sh
```

## Gerenciamento de Pacotes

### Atualizar Todos os Pacotes

```bash
brew update
brew upgrade
```

### Listar Pacotes Instalados

```bash
brew list
```

### Adicionar Novo Pacote ao Brewfile

Edite o `Brewfile` e adicione:

```ruby
brew "nome-do-pacote"
```

Depois execute:

```bash
brew bundle --file=Brewfile
```

### Exportar Pacotes Atuais para Brewfile

```bash
brew bundle dump --file=Brewfile --force
```

## Comandos Úteis

| Comando | Descrição |
|---------|-----------|
| `brew install <pacote>` | Instala um pacote |
| `brew uninstall <pacote>` | Remove um pacote |
| `brew search <termo>` | Busca pacotes |
| `brew info <pacote>` | Informações sobre um pacote |
| `brew doctor` | Verifica problemas na instalação |
| `brew cleanup` | Remove versões antigas |

## Coexistência com apt/dnf

O Homebrew coexiste com apt/dnf sem conflitos. Pacotes instalados via Homebrew ficam em `/home/linuxbrew/.linuxbrew/` e não interferem com pacotes do sistema.

## Solução de Problemas

### Homebrew Não Encontrado

Execute para carregar o PATH:

```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

### Erro de Permissão

Verifique as permissões de execução:

```bash
chmod +x install-homebrew.sh install-brew-packages.sh
```

### Pacotes Não Encontrados

Atualize o Homebrew:

```bash
brew update
```
