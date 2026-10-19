## ADDED Requirements

### Requirement: Integração do catálogo de Fowler smells na lente de arquitetura
A lente `architecture` SHALL incorporar formalmente o catálogo de 12 code smells de Martin Fowler como heurística estruturada de avaliação de manutenibilidade.

#### Scenario: Avaliação de smells clássicos
- **WHEN** a lente `architecture` analisa o diff
- **THEN** ela SHALL avaliar a presença de smells como Primitive Obsession, Feature Envy, Data Clumps, Speculative Generality, Shotgun Surgery e Divergent Change

#### Scenario: Precedência de padrões documentados do repositório
- **WHEN** o repositório possuir um arquivo de padrões como `CODING_STANDARDS.md` ou `CONTRIBUTING.md`
- **THEN** as diretrizes documentadas do repositório SHALL sobrepor qualquer regra do catálogo de Fowler em caso de conflito

### Requirement: Teto de severidade e pontuação para code smells
O sistema SHALL classificar code smells puros de modo a evitar falsos alarmes ou bloqueios injustificados de PRs.

#### Scenario: Smell sem defeito funcional comprovado
- **WHEN** um code smell for identificado sem divergência ou defeito de runtime demonstrado
- **THEN** o achado SHALL ter severidade máxima LOW e não SHALL deduzir pontos no score final do PR

#### Scenario: Smell associado a defeito ou divergência real
- **WHEN** um code smell causar divergência comprovada entre duas cópias de uma mesma regra no repositório
- **THEN** o achado SHALL ser classificado como MEDIUM ou categoria `bug` conforme a consequência direta
