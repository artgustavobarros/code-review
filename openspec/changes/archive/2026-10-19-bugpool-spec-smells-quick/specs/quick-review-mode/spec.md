## ADDED Requirements

### Requirement: Invocação e execução do modo rápido
O sistema SHALL permitir a execução do bugpool em modo rápido e econômico através da flag `--quick`.

#### Scenario: Ativação via flag
- **WHEN** o usuário invoca o bugpool com a flag `--quick`
- **THEN** o sistema SHALL ativar o fluxo simplificado de dois eixos, ignorando a criação de worktree, repros descartáveis e auto-fix

#### Scenario: Execução dos dois eixos de revisão
- **WHEN** o modo rápido está ativo
- **THEN** o sistema SHALL executar um pré-passe enxuto e disparar dois agentes paralelos: um para o eixo de Corretude & Segurança e outro para o eixo de Padrões & Especificação

### Requirement: Relatório simplificado no terminal
O sistema SHALL apresentar os resultados do modo rápido diretamente no terminal de forma clara, rápida e sem poluição.

#### Scenario: Apresentação dos achados por eixo
- **WHEN** os agentes do modo rápido concluem suas análises
- **THEN** o sistema SHALL exibir um sumário destacando o pior achado encontrado em cada eixo e o total de ocorrências

#### Scenario: Restrição de tempo e custo
- **WHEN** o modo rápido é executado em diffs típicos (< 500 linhas)
- **THEN** a execução SHALL ser concluída em menos de 30 segundos, sem gravação de comentários no GitHub
