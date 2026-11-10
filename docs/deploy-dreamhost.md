# Playbook: Deploy Incremental via SSH + Rsync na DreamHost

## 1. Arquitetura da Hospedagem Compartilhada DreamHost

### Sistema de Arquivos e Raiz Web

Na DreamHost (shared hosting), a hierarquia de diretórios segue o padrão estrito:

```
/home/<SSH_USER>/<DOMINIO_OU_SUBDOMINIO>/
```

- **`<SSH_USER>`**: Usuário SSH/SFTP configurado no painel da DreamHost (*Websites → Manage Websites → Server Details*).
- **`<DOMINIO_OU_SUBDOMINIO>`**: Diretório raiz servido pelo servidor web (Apache/Nginx). Qualquer arquivo estático (`index.html`, assets, bundles) colocado nesta pasta fica imediatamente acessível na web.

### Limitações de Ambientes Compartilhados

- **Sem runners de CI/CD nativos** (nada no estilo Vercel/Netlify).
- **Sem daemons persistentes** escutando portas customizadas.
- **Sem privilégios de root (`sudo`)**: o usuário opera dentro da própria `$HOME`.

### Solução Técnica: Push Local com Rsync sobre SSH

- **Algoritmo delta**: apenas blocos modificados são transferidos.
- **Compressão em trânsito (`-z`)**: menos banda, uploads mais rápidos.
- **Zero overhead no servidor**: usa os binários `rsync` e `sshd` nativos da DreamHost.

---

## 2. Template do Script

Localização: [`shared/templates/deploy/deploy-dreamhost.sh`](../shared/templates/deploy/deploy-dreamhost.sh)

Variáveis parametrizáveis no topo (ou via variáveis de ambiente):

| Variável | Exemplo | Descrição |
|---|---|---|
| `REMOTE_USER` | `meu_usuario_dh` | Usuário SSH no painel DreamHost |
| `REMOTE_HOST` | `meudominio.com` | Servidor/domínio SSH |
| `DOMAIN_FOLDER` | `meudominio.com` | Pasta raiz web na home do usuário |
| `LOCAL_PATH` | `./dist/` | Diretório local do build |

Exclusões embutidas: `.git/`, `.gitignore`, `.env*`, `node_modules/`, `*.log`, `.DS_Store`, `Thumbs.db`, `.htaccess`, `.well-known/`.

### Pré-requisitos

- `rsync` e `openssh-client` instalados no WSL/Linux (`sudo apt install rsync openssh-client`).
- Conta SSH ativa para o usuário no painel DreamHost (usuários novos podem vir apenas com SFTP; habilite *SSH Access* no painel).

---

## 3. Autenticação

Por padrão o `rsync` pede senha a cada deploy. Para autenticar sem senha:

1. **Gerar par de chaves (se não possuir):**
   ```bash
   ssh-keygen -t ed25519 -C "deploy@dreamhost"
   ```
2. **Copiar a chave pública para a DreamHost:**
   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519.pub seu_usuario@meudominio.com
   ```
3. **Testar acesso:**
   ```bash
   ssh seu_usuario@meudominio.com "echo OK"
   ```

---

## 4. Guia Rápido de Uso

1. **Copiar o template para a raiz do seu projeto:**
   ```bash
   cp /home/livre/my-setup-os/shared/templates/deploy/deploy-dreamhost.sh ./deploy.sh
   chmod +x ./deploy.sh
   ```

2. **Editar as variáveis no topo do script ou exportar ao ambiente:**
   ```bash
   export REMOTE_USER="meu_usuario_dh"
   export REMOTE_HOST="meudominio.com"
   export DOMAIN_FOLDER="meudominio.com"
   export LOCAL_PATH="./dist/"
   ```

3. **Simular o deploy com segurança (dry-run):**
   ```bash
   ./deploy.sh --dry-run
   ```

4. **Executar o deploy em produção:**
   ```bash
   ./deploy.sh
   ```
