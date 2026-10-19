## 1. Lente de Especificação (Spec Fidelity)

- [x] 1.1 Criar a definição da lente `skills/bugpool/reference/lenses/spec.md` com as categorias `spec/missing`, `spec/divergence` e `spec/creep`
- [x] 1.2 Atualizar `skills/bugpool/reference/lenses/router.md` para suportar a seleção da lente `spec` mediante disponibilidade de fonte de requisitos
- [x] 1.3 Atualizar `skills/bugpool/reference/lenses/validator.md` para validar achados de especificação sem exigir scripts de execução em omissões (`repro: n/a (omission)`)
- [x] 1.4 Implementar a descoberta da spec no Passo 1 (Contexto) de `skills/bugpool/SKILL.md` (priorizando `--spec`, PR body/issues via `gh pr view` e arquivos em `specs/`)

## 2. Catálogo Fowler de Smells na Lente Architecture

- [x] 2.1 Enriquecer `skills/bugpool/reference/lenses/architecture.md` com os 12 code smells de Martin Fowler (*Refactoring*, cap. 3)
- [x] 2.2 Formalizar regra de prevalência de padrões documentados no repositório (`CODING_STANDARDS.md`, `CONTRIBUTING.md`) sobre o catálogo base em `architecture.md`
- [x] 2.3 Estabelecer teto de severidade LOW para code smells puros sem quebra funcional e MEDIUM para divergências concretas em `architecture.md`

## 3. Modo Rápido / Lean (`--quick`)

- [x] 3.1 Adicionar a flag `--quick` na invocação, na tabela de flags e no `argument-hint` de `skills/bugpool/SKILL.md`
- [x] 3.2 Implementar o branch de execução do modo `--quick` em `skills/bugpool/SKILL.md` (pré-passe leve + 2 sub-agentes paralelos nos eixos Corretude e Padrões/Spec)
- [x] 3.3 Criar o template de relatório de dois eixos para o modo rápido em `skills/bugpool/reference/report-templates.md`

## 4. Documentação e Validação

- [x] 4.1 Fazer bump de versão para 3.2.0 em `skills/bugpool/SKILL.md` e atualizar o checklist do workflow
- [x] 4.2 Atualizar `README.md` documentando a versão 3.2.0, as novas flags (`--quick`, `--spec`) e os novos recursos
- [x] 4.3 Rodar suite de avaliação de integridade em `skills/bugpool/evals/` para garantir que as novas lentes e modos não quebrem o comportamento existente
