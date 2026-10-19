## ADDED Requirements

### Requirement: Auditoria reversa de especificação (Diff-Inversion)
A lente `spec` SHALL executar auditoria bidirecional, inspecionando cada nova rota de API, server action, comando CLI ou export de componente no diff para garantir rastreabilidade a um requisito explícito da especificação.

#### Scenario: Rota ou endpoint público adicionado sem respaldo na especificação
- **WHEN** o diff introduzir uma nova rota HTTP (ex: `GET /api/...`) ou ação pública não solicitada na especificação
- **THEN** a lente SHALL reportar um achado `spec/creep` com severidade **MEDIUM** citando a ausência do requisito na spec e a ausência de chamadores na aplicação

#### Scenario: Entidade de escopo justificada pela especificação
- **WHEN** uma nova rota ou export corresponder a uma funcionalidade descrita nas seções de Why, Capabilities ou Requirements da especificação
- **THEN** a lente SHALL validar o componente e não reportar `spec/creep`

### Requirement: Simulação de ciclo de vida de estado dinâmico na UI
A auditoria de fidelidade de especificação em componentes interativos SHALL simular a consistência de estado visual e derivados após ações do usuário.

#### Scenario: Limpeza de filtros e reset de escopo compartilhado
- **WHEN** o usuário aciona uma ação que redefine filtros (ex: "Ver estante completa", "Limpar busca")
- **THEN** a lente SHALL verificar se textos informativos, banners de recorte ou avisos derivados de props iniciais (`initial`) são devidamente atualizados ou ocultados em vez de permanecerem com texto inconsistente
