## Why

O `bugpool` (v3.1.0) é uma ferramenta excelente de alta precisão e verificação adversarial (zero falsos positivos em evals), mas possui dois pontos cegos marcantes quando comparado a ferramentas de revisão como a do Matt Pocock (`/code-review`):
1. **Falta de verificação de alinhamento com requisitos (Spec Fidelity)**: Ele caça bugs de runtime e de segurança, mas não audita se o código entregou o que a issue/PR pediu ou se introduziu escopo não solicitado.
2. **Ausência de taxonomia formal de smells de código**: A análise arquitetural atual avalia tamanho e duplicação direta, mas não guia o modelo com um vocabulário padronizado de design (ex: catálogo de Fowler).
3. **Custo e latência elevados para checagens rápidas**: O fluxo completo do bugpool roda múltiplos agentes com validação Opus e repros descartáveis (~$1,50 e vários minutos), inviabilizando sanity checks rápidos durante o ciclo de desenvolvimento local.

Implementar essas melhorias posicionará o `bugpool` como uma solução completa: ágil no dia a dia local e implacável na validação pré-merge.

## What Changes

- **Nova Lente e Descoberta de Spec (`spec.md`)**:
  - Descoberta automática da fonte de especificação (PR body via `gh pr view`, issues referenciadas `#123`, arquivos em `specs/` ou flag `--spec`).
  - Nova lente `spec` (`sonnet`) focada em `spec/missing`, `spec/divergence` e `spec/creep`.
  - Integração da spec no Router e no validador.
- **Catálogo Fowler de Smells na Lente `architecture.md`**:
  - Inclusão do baseline de 12 smells do Fowler (*Refactoring*, ch. 3): Primitive Obsession, Feature Envy, Speculative Generality, Data Clumps, Shotgun Surgery, etc.
  - Regra de teto de severidade: smells sem quebra funcional concreta permanecem no máximo LOW, respeitando padrões documentados do repositório (`CONTRIBUTING.md`).
- **Modo Rápido / Lean (`--quick`)**:
  - Nova flag `--quick` na invocação do `/bugpool`.
  - Execução enxuta de dois eixos em modelos rápidos (Haiku/Sonnet direto), sem worktree, sem validação via script de repro e sem auto-fix.
  - Saída side-by-side no terminal em < 30 segundos e custo < US$ 0,15.
- **Atualização de Documentação e CLI**:
  - Bump de versão do `bugpool` para `3.2.0` no `SKILL.md` e `README.md`.

## Capabilities

### New Capabilities
- `spec-fidelity-lens`: Descoberta de fontes de especificação e auditoria de conformidade de requisitos no diff.
- `fowler-smell-catalog`: Formalização do catálogo de code smells do Fowler na lente arquitetural com prioridade para padrões documentados.
- `quick-review-mode`: Modo de execução rápida e baixo custo com relatório de dois eixos.

### Modified Capabilities
<!-- Nenhuma capability existente em openspec/specs/ -->

## Impact

- `skills/bugpool/SKILL.md`: Atualização do fluxo, flags (`--quick`, `--spec`) e checklist.
- `skills/bugpool/reference/lenses/spec.md`: Criação da nova lente de especificação.
- `skills/bugpool/reference/lenses/architecture.md`: Expansão com catálogo de Fowler.
- `skills/bugpool/reference/lenses/router.md`: Adição da seleção da lente `spec`.
- `skills/bugpool/reference/report-templates.md`: Modelos de relatório para modo `--quick` e achados de spec.
- `README.md`: Documentação das novas opções e versão 3.2.0.
