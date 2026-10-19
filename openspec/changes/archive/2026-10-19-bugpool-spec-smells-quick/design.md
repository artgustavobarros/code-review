## Context

O `bugpool` é uma skill de revisão de código e triagem de PRs focada em confiabilidade extrema, com pré-passe determinístico, lentes especializadas, validação adversarial com scripts descartáveis de reprodução e auto-fix em worktree isolado.

Atualmente na versão 3.1.0, o `bugpool` tem excelente desempenho em encontrar bugs de concorrência e regressão sem falsos positivos, mas carece de:
1. Auditoria formal de conformidade com a especificação ou ticket original (Spec Fidelity).
2. Vocabulário formal de code smells (Martin Fowler) para avaliação de design e manutenibilidade.
3. Um modo rápido e econômico (`--quick`) para avaliações locais instantâneas.

## Goals / Non-Goals

**Goals:**
- **Detecção e Auditoria de Spec:** Descobrir automaticamente a fonte de requisitos (PR body, commits com `#123`, arquivos locais de spec ou flag `--spec`) e introduzir a lente `spec` (`sonnet`) focada em requisitos ausentes (`spec/missing`), divergências de comportamento (`spec/divergence`) e complexidade não solicitada (`spec/creep`).
- **Catálogo Fowler de Smells:** Enriquecer a lente `architecture` com os 12 code smells de Fowler (*Refactoring*, cap. 3), com teto estrito de severidade (LOW para smells sem defeito/divergência) e prevalência de regras documentadas no repo.
- **Modo Quick / Lean:** Introduzir a flag `--quick` que pula a infraestrutura pesada (worktrees, repros em `$RUN/repro/`, auto-fix e loops extras), executando um pré-passe enxuto e dois eixos paralelos em modelo rápido para entregar um relatório side-by-side em < 30 segundos a < US$ 0,15.
- **Preservação de Confiabilidade:** Manter a taxa zero de falsos positivos no modo completo e compatibilidade reversa com todas as flags do Bugpool 3.1.0.

**Non-Goals:**
- Não transformar o `bugpool` em um linter estilístico (ex: reclamar de espaços ou nomes de variáveis que o linter do projeto aceita).
- Não executar scripts de reprodução no validador para requisitos ausentes (`spec/missing`), já que ausência de código não é testável via execução unitária.
- Não penalizar pontuação (score) nem bloquear aprovação com base em code smells puros de Fowler (permanecem informativos/LOW).

## Decisions

### 1. Descoberta de Spec e Lente `spec.md`
- **Decisão:** A descoberta de spec segue ordem estrita:
  1. Flag `--spec <caminho|url|texto>`
  2. Issues/PR: Em modo PR, `gh pr view` e busca por `#<id>` / `Closes #<id>` nos commits
  3. Arquivos locais em `specs/`, `openspec/`, `docs/specs/` ou `.scratch/`
  4. Se nada for encontrado, a lente `spec` é pulada e reportada como `no spec available`.
- **Alternativas consideradas:**
  - *Perguntar interativamente ao usuário:* Interrompe a automação do PR e scripts CI. Preferimos descoberta automática com fallback gracioso.

### 2. Catálogo Fowler integrado à Lente `architecture`
- **Decisão:** Incorporar o baseline Fowler diretamente em `skills/bugpool/reference/lenses/architecture.md`, em vez de criar uma lente separada de `standards`.
- **Rationale:** A lente `architecture` já avalia acoplamento e manutenibilidade. Adicionar os 12 smells de Fowler fornece uma rubrica estruturada sem inflar o número de agentes paralelos no modo completo.
- **Regra de Severidade:**
  - Smell puro sem quebra ou divergência = severidade LOW (não desconta do score).
  - Smell com divergência concreta existente entre cópias = severidade MEDIUM.
  - Se o repositório tiver `CODING_STANDARDS.md` ou `CONTRIBUTING.md`, o padrão do repositório sempre anula o baseline do Fowler.

### 3. Mecânica do Modo `--quick`
- **Decisão:** O modo `--quick` segue uma ramificação direta no início do `SKILL.md`:
  - Pré-passe rápido (apenas linter e typecheck em arquivos alterados).
  - Spawna 2 agentes paralelos (estilo Matt Pocock):
    - **Eixo 1: Corretude & Segurança** (`correctness-stack` + `security` unificados em `sonnet` ou `haiku`).
    - **Eixo 2: Padrões & Requisitos** (`architecture` com Fowler smells + `spec` audit).
  - Sem etapa de refutação/repro em `$RUN/repro/` e sem auto-fix em worktree.
  - Saída direta no terminal com layout de dois eixos e pior achado destacado.

## Risks / Trade-offs

- **[Alucinações sobre requisitos ausentes na Lente Spec]** → *Mitigação:* A lente `spec` deve obrigatoriamente citar o trecho exato da spec que motivou a alegação. Se não houver citação textual direta, o validador rejeita o achado.
- **[Poluição de relatórios com julgamentos subjetivos de smells]** → *Mitigação:* Cap estrito de no máximo 4 achados de arquitetura por revisão; smells puros classificados como LOW/NIT sem dedução de pontos no score geral.
- **[Divergência entre o modo Quick e o modo Completo]** → *Mitigação:* Ambos compartilham as mesmas regras base de pré-passe e prompts fundamentais de lentes, diferindo apenas na profundidade de validação e na infraestrutura de auto-fix.
