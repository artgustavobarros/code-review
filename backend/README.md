# ⚙️ Kit Backend

Conjunto fixo de skills para projetos backend (Node.js, APIs, Postgres, testes). As skills ficam copiadas aqui, então todo projeto recebe exatamente as mesmas versões.

## 🚀 Instalar

### Via script:
```bash
./backend/install.sh /caminho/para/seu/projeto
```

### Via `npx skills`:
```bash
npx skills add artgustavobarros/skills/backend --all
```

## 📦 Skills

| Skill | Origem | Para quê |
| :--- | :--- | :--- |
| `node` | [mcollina/skills](https://github.com/mcollina/skills) | Boas práticas de Node.js com TypeScript nativo (type stripping, async, erros, streams) |
| `nodejs-backend-patterns` | [wshobson/agents](https://github.com/wshobson/agents) | Serviços Express/Fastify: middleware, erros, auth, banco |
| `api-design-principles` | [wshobson/agents](https://github.com/wshobson/agents) | Design de APIs REST e GraphQL |
| `supabase-postgres-best-practices` | [supabase/agent-skills](https://github.com/supabase/agent-skills) | Schema, migrations, RLS, índices e performance em Postgres |
| `vitest` | [antfu/skills](https://github.com/antfu/skills) | Testes com Vitest: mocks, coverage, fixtures |
| `test-driven-development` | [obra/superpowers](https://github.com/obra/superpowers) | Fluxo TDD antes de escrever código de produção |

`skills-lock.json` registra a origem e o hash de cada skill copiada.

## 🔄 Atualizar o kit

1. Num projeto, rode `npx skills update` (ou reinstale da origem).
2. Copie as pastas de `.agents/skills/<skill>` de volta para `backend/` e atualize o `skills-lock.json`.
