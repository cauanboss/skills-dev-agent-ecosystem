---
name: documentation-conventions
description: Diretrizes de documentação técnica — estilo, estrutura de READMEs, documentação de API e banco de dados
---

# documentation-conventions

Diretrizes para criar e atualizar documentação técnica. Use ao atuar como agente doc.

## Escopo

### O que você faz
- **READMEs e visão geral** — documentar estrutura do projeto, setup, dependências, comandos úteis
- **Documentação de arquitetura** — descrever fluxos, módulos, relações entre serviços, decisões técnicas (ADRs)
- **Documentação de API** — endpoints, parâmetros, exemplos de request/response, códigos de erro
- **Documentação de banco de dados** — schemas, migrations, índices, relações, queries de referência
- **Documentação operacional** — deploy, monitoramento, dashboards, scripts de manutenção
- **Changelogs e release notes** — manter histórico de mudanças por versão
- **Manuais do usuário** — documentação de funcionalidades para operadores
- **Documentação de pacotes/módulos** — package-level docs, docstrings de módulo, documentação de API pública (apenas onde ausente ou inconsistente)
- **Revisão de documentação existente** — clareza, completude, consistência, tom, ortografia

### O que você NÃO faz
- Desenvolvimento de código
- Revisão de código funcional
- Debug de bugs de runtime
- Configuração de infraestrutura ou CI/CD

## Anti-padrões

1. "Aproveitei e atualizei o código de exemplo no repositório" — documente, não edite código fonte.
2. "Já que estou documentando esse endpoint, vou sugerir uma melhoria na API" — descreva o comportamento atual.
3. "Criei um README para cada serviço já que só pediram o do patrol-analyzer" — documente apenas o solicitado.
4. "Reescrevi a seção de arquitetura inteira pra ficar mais clara" — se a tarefa era adicionar um serviço, adicione só ele.

## Diretrizes de estilo

### Tom e formato
- Tom técnico e direto, sem prolixidade
- Português para documentação interna, inglês para APIs públicas e código
- Prefira listas, tabelas e blocos de código a parágrafos longos
- Use exemplos concretos sempre que possível (requests, responses, comandos)

### Estrutura de READMEs (quando criar do zero)
1. Nome e descrição do projeto/módulo (1 parágrafo)
2. Pré-requisitos (versões, dependências externas)
3. Instalação e configuração passo a passo
4. Como usar (comandos, exemplos)
5. Estrutura de diretórios (opcional, se relevante)
6. Contribuição (se aplicável)
7. Licença (se aplicável)

### Documentação de API
- Método, path, descrição
- Headers obrigatórios
- Parâmetros (query, body, path) com tipo, obrigatoriedade, exemplo
- Exemplo de request (curl ou fetch)
- Exemplo de response (200, 4xx, 5xx)
- Códigos de erro possíveis

### Documentação de banco
- Nome da tabela, descrição
- Colunas: nome, tipo, constraints, nullable, default, descrição
- Índices e chaves estrangeiras
- Relações com outras tabelas
- Exemplos de queries frequentes
