# Template de Novo Projeto - Configuração de Skills

Este template contém a configuração padrão de skills para novos projetos, incluindo a skill oficial da Cloudflare `security-audit`.

## Como usar em um novo projeto

### Opção 1: Usando o script automatizado (Recomendado)
No diretório do seu novo projeto, execute:
```bash
bash /home/livre/my-setup-os/shared/instalar-skills-novo-projeto.sh
```
Ou com o alias configurado no shell:
```bash
skills-novo-projeto
```
Para incluir também as skills de engenharia/produtividade Matt Pocock:
```bash
skills-novo-projeto --all
```

### Opção 2: Restaurando a partir do skills-lock.json
Copie os arquivos `skills-lock.json` e `opencode.jsonc` para a raiz do seu novo projeto e execute:
```bash
npx skills experimental_install
```

### Opção 3: Via Skills CLI diretamente
```bash
npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit
```

## Como ativar a skill no seu agente de IA
Com a skill instalada ou com acesso global, use comandos como:
- `security audit this codebase`
- `find security vulnerabilities in ./src`
- `do a security review, output to ~/audits/meu-projeto`
