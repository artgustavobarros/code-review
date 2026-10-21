# 🎨 Kit Frontend

Conjunto fixo de skills para projetos frontend. As skills ficam copiadas aqui, então todo projeto recebe exatamente as mesmas versões.

## 🚀 Instalar

### Via script (kit completo, com impeccable):
```bash
./frontend/install.sh /caminho/para/seu/projeto
```

### Via `npx skills` + instalador do impeccable:
```bash
npx skills add artgustavobarros/skills/frontend --all
npx impeccable@4.7.0 install -y --project
```

## 📦 Skills

| Skill | Origem | Para quê |
| :--- | :--- | :--- |
| `design-taste-frontend` | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | Direção de arte anti-"cara de IA" para páginas e telas |
| `vercel-composition-patterns` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | Padrões de composição React (compound components, React 19) |
| `vercel-react-best-practices` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | Performance em React/Next.js |
| `web-design-guidelines` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | Revisão de UI contra as Web Interface Guidelines |
| `webapp-testing` | [anthropics/skills](https://github.com/anthropics/skills) | Testar apps locais com Playwright |
| `impeccable` | [impeccable](https://www.npmjs.com/package/impeccable) `4.7.0` | Design, crítica e polimento de UI (instalado pelo CLI oficial) |

O `impeccable` não é copiado: ele gera uma variante por harness (`/impeccable` no Claude, `$impeccable` no Codex), hooks e um binário por plataforma. O `install.sh` chama o instalador oficial com a versão travada.

`skills-lock.json` registra a origem e o hash de cada skill copiada.

## 🔄 Atualizar o kit

1. Num projeto, rode `npx skills update` (ou reinstale da origem).
2. Copie as pastas de `.agents/skills/<skill>` de volta para `frontend/` e o `skills-lock.json`.
3. Para o impeccable, troque `IMPECCABLE_VERSION` no `install.sh`.
