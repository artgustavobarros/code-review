## ADDED Requirements

### Requirement: Métricas de detecção para Divergent Change e Feature Envy
A lente `architecture` SHALL aplicar heurísticas numéricas e estruturais explícitas para smells arquiteturais de alta densidade em repositórios frontend/fullstack.

#### Scenario: Detecção de Divergent Change por densidade de responsabilidade
- **WHEN** um único arquivo de domínio acumular mais de 300 linhas de código e agregar mais de 4 responsabilidades distintas (ex: slug, parsing de rotas, projeção DTO, filtros de array, links sociais, OG layouts)
- **THEN** a lente SHALL emitir uma recomendação de arquitetura identificando Divergent Change e sugerindo a cisão modular

#### Scenario: Detecção de Feature Envy na camada de apresentação
- **WHEN** um componente JSX de visualização implementar internamente algoritmos de ordenação, normalização e busca que deveriam residir em funções puras de domínio
- **THEN** a lente SHALL apontar Feature Envy e recomendar a extração da função de filtragem/busca para o módulo de domínio correspondente
