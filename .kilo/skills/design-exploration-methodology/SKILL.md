---
name: design-exploration-methodology
description: Metodologia de exploração de design e arquitetura — análise de trade-offs, geração de alternativas, prototipagem executável e recomendação
---

# design-exploration-methodology

Metodologia para explorar alternativas de design e arquitetura. Use ao atuar como ideas-agent.

## Regras fundamentais

- Invocado opcionalmente pelo `lead-dev-agent` quando há ambiguidade arquitetural.
- NÃO implementa código final, NÃO revisa código, NÃO decompõe tarefas, NÃO valida escopo.
- Foco: design/arquitetura em nível de código e módulos (não infraestrutura).
- **Prototipagem**: quando a pergunta de design for sobre state model, lógica ou UI, construir protótipo executável descartável.

## Metodologia

### 1. Entendimento
Reformula problema, restrições, requisitos não funcionais, contexto.

### 2. Geração
2 a 4 alternativas com: nome, abordagem, estrutura, tecnologias, trade-offs.

### 3. Prototipagem (opcional, quando aplicável)

Se a pergunta de design envolver **risco de implementação** ou **incerteza sobre viabilidade**, construa um protótipo descartável ANTES da análise final. O protótipo NÃO é código de produção — é um experimento para responder uma pergunta específica.

#### Quando prototipar

| Situação | Tipo de protótipo |
|---|---|
| **State model / lógica incerta** | App de terminal executável que exercita o state model com inputs variados |
| **UI / UX ambígua** | Variações toggleáveis em uma rota (switch/case por query param) para comparar abordagens |
| **Performance incerta** | Benchmark isolado com a operação crítica, medindo latência/throughput |
| **Integração nova** | Script standalone que testa a integração sem o resto do sistema |
| **API design** | Servidor mínimo com a interface proposta, testável com curl |

#### Regras do protótipo

- **Descartável**: marcado com comentário `// PROTOTYPE — descartar após decisão`. NUNCA vai para produção.
- **Mínimo**: implementa APENAS o necessário para responder a pergunta. Sem tratamento de erro, sem logging, sem testes.
- **Rápido**: idealmente minutos, não horas. Se está demorando, o escopo do protótipo está grande demais.
- **Pergunta explícita**: antes de começar, declare "Este protótipo responde: {pergunta específica}".
- **Resultado documentado**: após executar, documente o que aprendeu: "O protótipo mostrou que {conclusão}. Portanto, {decisão}."

#### Anti-padrões de prototipagem

- Prototipar quando a resposta já é conhecida (só prototipe incertezas reais).
- Transformar o protótipo em código de produção ("já que está pronto...").
- Prototipar 3 alternativas quando 1 já responderia a pergunta.
- Protótipo sem pergunta explícita — "vou construir algo e ver no que dá".

### 4. Análise
Tabela com critérios (simplicidade, performance, manutenibilidade, escalabilidade, alinhamento, risco). Se houve prototipagem, incluir os aprendizados do protótipo na análise.

### 5. Recomendação
Qual alternativa é mais adequada, em que condições outra seria preferível, riscos residuais, próximos passos.

## Anti-padrões proibidos

- "Essa é a melhor, implementa assim" (você recomenda, não decide).
- "Vou gerar 8 alternativas" (qualidade sobre quantidade, 2-4).
- "Use a tecnologia X que é a melhor do mercado" (avalie adequação, não popularidade).
- "Vou propor uma reescrita completa" (respeite arquitetura existente).
- "Pulei a análise porque a escolha é óbvia" (trade-offs explícitos sempre).
- "O protótipo funcionou, vou deixar ele como código final" (protótipo é descartável).
