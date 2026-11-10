---
name: bootstrap-5-overview
description: Diretrizes de configuração, layout responsivo e componentes para projetos web utilizando Bootstrap 5.3. Use ao criar landing pages, painéis administrativos ou estruturar layouts com grid Bootstrap.
---

# Bootstrap 5 Overview Skill

Esta skill fornece diretrizes para criação ágil de interfaces responsivas e produção de layouts modernos com Bootstrap 5.3.

## Quando Usar

- Ao criar ou migrar projetos que utilizam Bootstrap 5.
- Ao estruturar templates responsivos com Mobile-First Grid System.
- Ao configurar componentes com atributos `data-bs-*` ou inicialização programática via JavaScript.
- Ao integrar Bootstrap com bundlers modernos (Vite, Webpack) ou via CDN oficial.

## Configuração Rápida (CDN v5.3)

```html
<!doctype html>
<html lang="pt-BR" data-bs-theme="dark">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Bootstrap 5.3 Starter</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  </head>
  <body>
    <main class="container py-5">
      <h1 class="mb-4">Dashboard</h1>
      <div class="row g-4">
        <div class="col-12 col-md-4">
          <div class="card p-3 shadow-sm">
            <h5>Métrica 1</h5>
            <p class="text-body-secondary">Conteúdo descritivo</p>
          </div>
        </div>
      </div>
    </main>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  </body>
</html>
```

## Regras de Ouro
1. **Grid Flexbox**: Use `container`, `row` e `col-{breakpoint}-{size}` sempre respeitando a hierarquia correta. Nunca use `.row` fora de um `.container` ou `.container-fluid`.
2. **Espaçamentos Nativos**: Prefira classes utilitárias (`m-0` até `m-5`, `p-0` até `p-5`, `gap-3`) em vez de CSS inline.
3. **Temas**: Suporte a Dark Mode nativo via atributo `data-bs-theme="dark"` no elemento `<html>` ou em seções específicas.
4. **Sem jQuery**: Bootstrap 5 usa JavaScript puro. Não importe jQuery.
