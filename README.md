# 🌟 Public Agent Skills (Acervo Público de Skills)

Repositório público com habilidades especializadas para agentes de codificação de IA (**Claude Code**, **Antigravity**, **Cursor**, etc.), construídas com rigor metodológico e **zero ruído corporativo**.

Compatível nativamente com o padrão aberto do **[skills.sh](https://skills.sh/)** e o CLI `npx skills`.

## 🗂️ Estrutura

| Pasta | Conteúdo | Instalar |
| :--- | :--- | :--- |
| [`code-review/`](./code-review/SKILL.md) | Skill autoral de revisão de PR | `npx skills add artgustavobarros/skills --skill code-review` |
| [`frontend/`](./frontend/README.md) | Kit fixo de skills de terceiros para frontend | `./frontend/install.sh /caminho/do/projeto` |
| [`backend/`](./backend/README.md) | Kit fixo de skills de terceiros para backend | `./backend/install.sh /caminho/do/projeto` |

---

## 🚀 Como Instalar com `npx skills` (Padrão Oficial)

Você pode instalar qualquer skill diretamente em qualquer projeto com um único comando:

### Instalar no projeto atual:
```bash
npx skills add artgustavobarros/skills --skill code-review
```
*(Ou pelo link completo: `npx skills add https://github.com/artgustavobarros/skills --skill code-review`)*

### Instalar globalmente na sua máquina (disponível em todos os projetos):
```bash
npx skills add artgustavobarros/skills --skill code-review -g
```

### Listar todas as skills disponíveis neste repositório:
```bash
npx skills add artgustavobarros/skills --list
```

---

## 📦 Skills Disponíveis

### 1. [`code-review`](./code-review/SKILL.md) — Revisão de PR multi-lente com triagem segura
> **Comando:** `/code-review [pr-number|pr-url] [--local] [--base <ref>] [--dry-run] [--push] [--no-ignore] [--quick] [--spec <ref>]` | **Versão:** `3.4.0`

Revisa um Pull Request (ou a sua branch antes de abrir o PR), valida cada achado antes de reportar, tria threads de bots sem nunca tocar em conversas humanas e, opcionalmente, corrige o que é claro num worktree isolado.

* **Pré-passe determinístico:** lint (só check, nunca `--fix`), typecheck e testes relacionados aos arquivos alterados, em segundos. Timeout de setup é reexecutado uma vez e vira `flaky`/`inconclusive`, não evidência falsa de regressão. Lockfiles, snapshots de migração e pastas de docs ficam fora do diff (`--no-ignore` desliga).
* **Lentes core sempre ligadas:** `correctness-stack` e `security` rodam em todo review (`sonnet`). O router (`haiku`) adiciona `spec`, `qa` e `architecture` conforme necessidade.
* **Lente de fidelidade à especificação (`spec`):** audita se os requisitos da issue, PR ou documento de requisitos foram atendidos (`spec/missing`, `spec/divergence`, `spec/creep`) com citação textual obrigatória da spec. Descoberta automática via `--spec`, PR description/issues ou arquivos locais.
* **Catálogo Fowler na arquitetura:** avalia 12 code smells de Martin Fowler (*Refactoring*, cap. 3). Documentação do repositório (`CONTRIBUTING.md`) sempre sobrepõe; smells puros ficam no máximo LOW (não descontam pontuação).
* **Modo Rápido (`--quick`):** sanity check em dois eixos (Corretude & Segurança vs Padrões & Spec) em < 30 segundos e < US$ 0,15, sem worktrees, repros ou auto-fix.
* **Validação que tenta refutar:** achados MEDIUM+ e LOW de categoria `bug` são deduplicados e checados por um validador (`sonnet`; `opus` para segurança CRITICAL/HIGH), que pode reproduzir o bug com um teste descartável fora do repo. O que não tem prova em `arquivo:linha` é descartado.
* **Cobertura declarada:** cada lente diz o que leu e o que pulou, então "sem achados" não se confunde com "não olhei".
* **Modos:** PR, `--local` (sem PR, revisa branch + working tree), `--dry-run` (sem escrita no GitHub, sem commit) e `--quick` (rápido de dois eixos).
* **Auto-fix seguro:** recusa working tree sujo, corrige num git worktree isolado, gate = typecheck + lint check + testes relacionados, um commit único e push só com `--push`. Nunca roda `git checkout --`/`reset` na sua árvore.
* **Imunidade humana:** thread com qualquer comentário humano nunca é corrigida, respondida nem resolvida. O cabeçalho do bot só conta se estiver no início do comentário.
* **Resumo sticky único** com veredito e score (`100 − Σ deduções`), postado por script (quebras de linha reais).
* **Loop limitado:** até 2 rodadas extras após fixes, parando quando não surge achado novo MEDIUM+.
* **Avaliação embutida:** `evals/` traz o harness (bugs semeados, bugs reais de um intervalo, flake e comparação com o `/code-review` do Claude Code em modo headless) usado para medir o skill.

Comparado ao `/code-review` padrão do Claude Code, nos mesmos cenários (uma execução cada; custo = estimativa de API do CLI):

| Cenário | `/code-review` | bugpool 3.1.0 |
| :--- | :--- | :--- |
| dev (5 seeds) | 3/5 · US$0,10 | 5/5 · US$1,17 |
| held-out (5 seeds) | 5/5 · US$0,15 | 5/5 · US$1,33 |
| intervalo real (3 bugs) | 1/3 · US$0,20 | 2/3 · US$1,45 |
| composição (2 seeds) | 2/2 · US$0,11 | 1/2 · US$0,75 |
| limpo (falsos positivos) | 2 | 0 |

Acha mais (13/15 contra 11/15) e erra menos, a ~8,5x o custo e ~6x o tempo (no modo completo). Use `--quick` para custo e tempo equivalentes ao `/code-review`.

#### 3.3.0
- **Diff-Inversion (Auditoria Reversa de Spec)**: Inspeciona novas rotas HTTP, server actions e exports públicos sem requisito na especificação, reportando `spec/creep` com severidade MEDIUM.
- **Simulação Dinâmica de Ciclo de Vida de UI**: Simula interações de reset/clear/dismiss em componentes interativos para flagrar avisos ou contadores que retêm estado ou props iniciais desatualizados.
- **Métricas Objetivas de Arquitetura**: Heurísticas numéricas para *Divergent Change* (>300 LOC e $\ge 5$ responsabilidades de domínio) e *Feature Envy* em JSX.
- **Prioridade de Deduplicação**: Preservação de achados `spec/divergence`, `spec/creep` e `architecture` antes de descarte no limite de LOWs.
- **Relatório com Seção Consultiva**: Separação clara entre achados que deduzem score (Corretude e Segurança) e notas consultivas de especificação e arquitetura.

#### 3.2.0
- **Lente Spec**: Descoberta automática de especificações (`--spec`, issues de PR, arquivos locais) e auditoria de requisitos ausentes (`spec/missing`), divergências (`spec/divergence`) e escopo extra (`spec/creep`).
- **Catálogo Fowler**: 12 code smells de Martin Fowler integrados na lente `architecture`; prevalência para normas do repo e teto LOW para smells puros.
- **Modo Quick (`--quick`)**: Execução de dois eixos em < 30s (< $0,15) sem worktree nem scripts de repro, para feedback ágil no fluxo de dev local.
- **Validador**: Suporte a verificação de requisitos ausentes de especificação com `repro: n/a (omission)`.

#### 3.1.0
- Pré-passe: retry único só para timeout de setup/hook (`flaky`/`inconclusive`), contagem de testes, filtro de ruído no diff (`BUGPOOL_IGNORE`, `BUGPOOL_IGNORE_DIRS`, `--no-ignore`) e `scripts/diff.sh`.
- Lentes: bug demonstrado vira categoria `bug` no arquivo de código com severidade pela consequência (sem teto por lente); lacuna de teste ou duplicação sem defeito fica no máximo LOW; checagem de composição (duas operações seguidas) na `correctness-stack`; bloco `COVERAGE` e saída em `$RUN/lens-<lente>.md`.
- Router: scope drift "não aplicável" em intervalos com vários commits; formato de saída checado.
- Validador: repro descartável em `$RUN/repro/` (nunca no repo, obrigatório em MEDIUM+ `bug` quando o perigo é HIGH+) e veredito `CONFIRMED (partly pre-existing)`.
- Relatório: LOW não validado não desconta; o veredito nomeia cada MEDIUM+ aberto e marca os reproduzidos; mostra cobertura, ignorados, LOW descartados e o que não foi verificado.
- Orquestração: diretório de execução único por rodada; as lentes nunca são puladas por diff pequeno; `git status` comparado antes e depois.

#### 3.0.1
- Gate do auto-fix e pré-passe tratam checks indisponíveis na stack (exit 127) como `skipped`, não como falha. Se nenhum check rodou, o gate passa como `PASS (unverified)` e o fix leva `unverified` na nota.

#### ⚠️ Breaking changes na 3.0.0
- O próprio skill expõe `/code-review`.
- Auto-fix não roda mais com working tree sujo e não dá push sem `--push`.
- Achados novos aparecem no resumo sticky e no terminal; só threads existentes recebem respostas.

---

## 🎨 Kit Frontend

Conjunto fixo de skills de terceiros para projetos frontend (design, React, testes de UI), na pasta [`frontend/`](./frontend/README.md):

```bash
./frontend/install.sh /caminho/para/seu/projeto
```

---

## 🛠️ Métodos Alternativos de Instalação

### Via script instalador local:
```bash
./install.sh /caminho/para/seu/projeto
```

### Cópia manual:
```bash
cp -r code-review /caminho/para/projeto/.agents/skills/
ln -s ../../.agents/skills/code-review /caminho/para/projeto/.claude/skills/code-review
```

---

## 🙏 Créditos

O `code-review` é derivado e adaptado de:
- [`qa-swarm`](https://github.com/pauldambra/dotfiles/tree/main/ai/skills/qa-swarm) e [`review-triage`](https://github.com/pauldambra/dotfiles/tree/main/ai/skills/review-triage), de Paul D'Ambra: router com lentes, achados estruturados, resumo sticky, imunidade humana.
- [`yooh-digital/ai-workflow`](https://github.com/yooh-digital/ai-workflow): revisão em duas passadas, fricção construtiva, scope drift, rubrica SIZE.

---

## 🛡️ Filosofia deste Acervo
1. **Sem Amarras de Ferramentas:** Nada de acoplamentos com MCPs específicos (Plane, context-mode, Jira, etc.). Tudo usa ferramentas padrão (`git`, `gh`).
2. **Respeito ao Humano:** A IA auxilia e limpa o trabalho repetitivo, mas decisões de arquitetura e conversas com humanos são sempre preservadas.
3. **Custo Consciente:** Os modelos mais caros só são chamados quando estritamente necessários.
