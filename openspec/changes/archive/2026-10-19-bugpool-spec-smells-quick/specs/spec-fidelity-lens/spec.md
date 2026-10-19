## ADDED Requirements

### Requirement: Descoberta automática da fonte de especificação
O sistema SHALL descobrir a fonte de especificação relevante para o diff a ser revisado com base em parâmetros fornecidos ou metadados do repositório e git.

#### Scenario: Fonte especificada explicitamente via flag
- **WHEN** o usuário invoca o bugpool com `--spec <caminho|url|texto>`
- **THEN** o sistema SHALL utilizar a especificação apontada pela flag como fonte prioritária de requisitos

#### Scenario: Descoberta via PR do GitHub
- **WHEN** o bugpool roda em PR mode sem flag `--spec` explícita
- **THEN** o sistema SHALL inspecionar o corpo do PR via `gh pr view` e os commits em busca de referências a issues para extrair os critérios de aceite

#### Scenario: Fallback para arquivos locais ou ausência de spec
- **WHEN** nenhuma flag ou PR com issue for detectado, mas existir arquivo correspondente em `specs/` ou `docs/specs/`
- **THEN** o sistema SHALL utilizar esse arquivo como spec; caso nenhum arquivo exista, a lente de spec SHALL ser ignorada com nota de "no spec available"

### Requirement: Lente especializada de fidelidade à especificação
O sistema SHALL disponibilizar a lente `spec` (`reference/lenses/spec.md`) para auditar o diff contra os requisitos da especificação descoberta.

#### Scenario: Detecção de requisitos não implementados
- **WHEN** um requisito explícito da especificação não tiver implementação correspondente no diff
- **THEN** a lente SHALL reportar um achado com categoria `spec/missing` citando o trecho exato da especificação

#### Scenario: Detecção de divergência de regra de negócio
- **WHEN** o diff implementar uma lógica que contradiz explicitamente a regra de negócio exigida na especificação
- **THEN** a lente SHALL reportar um achado com categoria `spec/divergence` com evidência no diff e citação da especificação

#### Scenario: Detecção de escopo não solicitado (scope creep)
- **WHEN** o diff introduzir complexidade ou funcionalidades extras substanciais não mencionadas na especificação
- **THEN** a lente SHALL reportar um achado com categoria `spec/creep` detalhando o excesso de escopo

### Requirement: Validação de achados de especificação
O validador SHALL verificar a legitimidade dos achados de especificação sem exigir scripts de execução quando se tratar de omissão.

#### Scenario: Validação de requisito ausente
- **WHEN** o validador processa um achado da categoria `spec/missing`
- **THEN** o validador SHALL confirmar o achado se a citação da spec for exata e a funcionalidade realmente não constar no diff ou repo, marcando `repro: n/a (omission)`
