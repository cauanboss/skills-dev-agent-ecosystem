---
name: bug-diagnosis
description: Diagnóstico estruturado de bugs — loop de 6 fases com critérios de conclusão explícitos. Use quando "debuggar", "diagnosticar", ou reportar algo quebrado/falhando/lento.
---

# bug-diagnosis

Loop disciplinado para bugs difíceis e regressões de performance. Use ao atuar como bug-hunter. Pule fases apenas com justificativa explícita.

## Regras fundamentais

- NÃO reescreve o sistema. Foco: encontrar e corrigir a causa raiz.
- NÃO propõe refatorações arquiteturais como solução primária (documente como recomendação pós-fix).
- Cada fase tem critério de conclusão — não prossiga sem cumpri-lo.
- Instrumentação temporária SEMPRE com prefixo único (`[DEBUG-xxxx]`) para cleanup garantido.
- Se a causa for arquitetural (sem seam de teste, callers emaranhados), documente e recomende `improve-codebase-architecture` após o fix.

---

## Fase 1 — Construir loop de feedback

**Esta é a skill.** O resto é mecânica. Se você tem um sinal pass/fail **apertado** para o bug — um que fica vermelho para ESTE bug — você vai encontrar a causa. Sem ele, nenhuma quantidade de leitura de código vai salvar.

Gaste esforço desproporcional aqui. **Seja agressivo. Seja criativo. Recuse-se a desistir.**

### Estratégias — tentar nesta ordem

1. **Teste falhando** na seam que alcança o bug — unitário, integração, e2e.
2. **Script HTTP** (curl) contra servidor rodando.
3. **Invocação CLI** com fixture de entrada, fazendo diff contra snapshot conhecido.
4. **Script headless** (Playwright/Puppeteer) se o bug for UI.
5. **Replay de trace** — salvar payload real, reexecutar o code path em isolamento.
6. **Harness descartável** — subconjunto mínimo do sistema que exerce o bug.
7. **Property/fuzz loop** — 1000 inputs aleatórios procurando o modo de falha.
8. **Bisection harness** — automatizar `git bisect run`.
9. **Differential loop** — mesma entrada, versão antiga vs nova, diff de saída.

### Apertar o loop

Uma vez que você tem UM loop, **aperte-o**:

- Posso torná-lo mais rápido? (Cache de setup, pular init irrelevante)
- Posso tornar o sinal mais nítido? (Assert no sintoma específico, não "não crashou")
- Posso torná-lo determinístico? (Fixar time, seed RNG, isolar filesystem)

**Bugs não-determinísticos**: o objetivo não é repro limpo, é **taxa de reprodução mais alta**. Execute 100×, paralelize, adicione stress. 50% de flake é debugável; 1% não é.

### Quando genuinamente não consegue construir um loop

Pare e diga explicitamente. Liste o que tentou. Pergunte ao usuário por:
- Acesso ao ambiente que reproduz o bug
- Artefato capturado (HAR, log dump, core dump, gravação de tela)
- Permissão para adicionar instrumentação temporária em produção

**NÃO** prossiga para hipóteses sem um loop.

### Critério de conclusão

- [ ] Loop **apertado** (segundos, não minutos)
- [ ] Loop **capaz de vermelho** — consegue falhar neste bug específico
- [ ] Loop **determinístico** (ou alta taxa de reprodução)
- [ ] Loop **agent-runnable** — você consegue executar sozinho
- [ ] Você executou pelo menos uma vez e viu vermelho

---

## Fase 2 — Reproduzir + Minimizar

Execute o loop. Veja o vermelho — o bug aparece.

**Confirme**:

- [ ] O loop produz o sintoma que o **usuário** descreveu — não uma falha diferente que está perto
- [ ] O sintoma é reproduzível (ou, para bugs não-determinísticos, em taxa alta o suficiente)

### Minimizar

Reduza o repro ao **menor cenário que ainda fica vermelho**. Corte inputs, callers, config, dados, passos — **um de cada vez**, re-executando o loop após cada corte. Mantenha apenas o que é load-bearing para a falha.

**Por quê**: um repro mínimo reduz o espaço de hipóteses (menos partes móveis para suspeitar) e vira o teste de regressão limpo na Fase 5.

**Critério de conclusão**: todo elemento restante é load-bearing — remover qualquer um faz o loop ficar verde.

---

## Fase 3 — Gerar hipóteses

Gere **3 a 5 hipóteses rankeadas** antes de testar qualquer uma. Geração de hipótese única ancora na primeira ideia plausível.

Cada hipótese deve ser **falsificável**: declare a predição que ela faz.

> Formato: "Se `<X>` é a causa, então `<mudar Y>` fará o bug desaparecer / `<mudar Z>` o tornará pior."

Se você não consegue declarar a predição, a hipótese é um "vibe" — descarte ou refine.

**Mostre a lista ao usuário antes de testar.** Eles frequentemente têm conhecimento de domínio que re-rankeia instantaneamente, ou sabem hipóteses já descartadas. Checkpoint barato, grande economia de tempo. Se o usuário não responder em 1 minuto, prossiga com seu ranking.

**Critério de conclusão**: 3-5 hipóteses falsificáveis, rankeadas, mostradas ao usuário.

---

## Fase 4 — Instrumentar

Cada probe deve mapear para uma predição específica da Fase 3. **Mude uma variável por vez.**

Preferência de ferramentas:

1. **Debugger / inspeção REPL** se o ambiente suportar. Um breakpoint vale 10 logs.
2. **Logs direcionados** nas fronteiras que distinguem hipóteses.
3. Nunca "logar tudo e grep".

**TAG de debug**: prefixe todo log temporário com `[DEBUG-xxxx]` (ex: `[DEBUG-a4f2]`). Cleanup ao final é um único grep. Logs com tag morrem; logs sem tag sobrevivem.

**Branch de performance.** Para regressões de performance, logs são geralmente errados. Em vez disso: estabeleça medição baseline (timing harness, profiler, query plan), depois bisecte. Meça primeiro, corrija depois.

**Critério de conclusão**: hipóteses testadas, causa raiz isolada a uma variável específica.

---

## Fase 5 — Corrigir + teste de regressão

Escreva o teste de regressão **antes do fix** — mas apenas se existir uma **seam correta** para ele.

Uma seam correta é aquela onde o teste exercita o **padrão real do bug** como ele ocorre no call site. Se a única seam disponível é muito rasa (teste unitário que não replica a cadeia que disparou o bug), um teste de regressão ali dá falsa confiança.

**Se não existe seam correta, isso é o achado.** Documente. A arquitetura está impedindo o bug de ser travado. Recomende `improve-codebase-architecture` após o fix.

Se existe seam correta:

1. Transforme o repro minimizado em um teste falhando nessa seam.
2. Veja falhar.
3. Aplique o fix.
4. Veja passar.
5. Re-execute o loop da Fase 1 contra o cenário original (não-minimizado).

**Critério de conclusão**:
- [ ] Fix aplicado
- [ ] Teste de regressão passa (ou ausência de seam documentada)
- [ ] Loop original da Fase 1 está verde

---

## Fase 6 — Cleanup + post-mortem

Obrigatório antes de declarar concluído:

- [ ] Repro original não reproduz mais (re-executar loop da Fase 1)
- [ ] Teste de regressão passa (ou ausência de seam documentada)
- [ ] Toda instrumentação `[DEBUG-xxxx]` removida (`grep` pelo prefixo)
- [ ] Protótipos/harnesses descartáveis deletados (ou movidos para local marcado)
- [ ] A hipótese que se provou correta está declarada na mensagem de commit/PR — para o próximo debugger aprender
- [ ] Recomendação arquitetural documentada (se aplicável): o que teria prevenido este bug?

**Então pergunte: o que teria prevenido este bug?** Se a resposta envolve mudança arquitetural (sem seam de teste, callers emaranhados, acoplamento oculto), recomende `improve-codebase-architecture` com os específicos. Faça a recomendação **depois** do fix — você tem mais informação agora do que quando começou.

---

## Anti-padrões proibidos

- Pular a Fase 1 e ir direto ler código para formular teoria.
- Gerar 1 hipótese e testá-la imediatamente (anchoring).
- "Logar tudo e grep" em vez de instrumentação direcionada.
- Esquecer de remover logs de debug (prefixo `[DEBUG-xxxx]` é obrigatório).
- "Já que estou aqui, vou refatorar esse módulo inteiro" — scope creep.
- Corrigir sem teste de regressão quando existe seam correta.
- Declarar vitória sem re-executar o loop original da Fase 1.
