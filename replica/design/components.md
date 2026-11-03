# Componentes

Fonte: a lista de componentes do `replica/recon.md`. São padrões comuns de ferramentas de automação, não cópia do ManyChat: os textos são novos, os ícones vêm do **Lucide** (MIT), a fonte é a **Inter** (OFL) e o azul é provisório até o `/replica-brand`. Não existem prints do ManyChat em `replica/screens/` (o recon foi feito só com fontes públicas), então as medidas seguem a escala dos tokens, não medições do original.

Base acessível: **shadcn/ui sobre Radix** (Next.js + Tailwind). Todos os tamanhos de toque têm no mínimo 44 px, porque a dona usa o app no tablet.

```
Button
  variants  primary, secondary, ghost, danger
  sizes     sm 32px (só em tabelas no desktop), md 44px, lg 48px
  states    default, hover (accent-hover), active, focus-visible (anel 2px focus, offset 2px), disabled (opacidade 50%, sem hover), loading (spinner + texto mantido)
  tokens    primary: bg accent, text on-accent; secondary: bg bg, borda border-input, text text; ghost: text accent; danger: bg danger, text on-accent; radius md; fonte sm/600
  a11y      <button> de verdade; durante loading, aria-busy="true" e o rótulo continua para leitores de tela
  used on   todas

Toggle (ativo / inativo)
  variants  com rótulo, só o controle (em tabela)
  states    on (bg accent), off (bg border-input), focus-visible, disabled
  tokens    trilho 44x24, bolinha 20, motion fast
  a11y      Radix Switch: role="switch", aria-checked; o rótulo diz o que liga ("Automação ativa")
  used on   S03, S06, S13

Input / Textarea
  variants  texto, e-mail, URL, textarea com contador
  states    default (borda border-input), focus-visible (borda e anel focus), erro (borda danger + mensagem abaixo), disabled
  tokens    altura 44, radius md, fonte base (16px evita zoom no iPhone/iPad)
  a11y      <label> sempre visível; erro ligado por aria-describedby; aria-invalid no erro
  used on   S01, S05-S09, S12, S13, S15

KeywordInput (palavras-chave em chips)
  variants  match: contém / igual / começa com (segmented control ao lado)
  states    vazio (placeholder "ex.: INGLES"), com chips, duplicado (chip pisca + aviso "já existe"), erro (sem palavra e sem "qualquer texto")
  tokens    chip: bg accent-soft, text accent, radius pill; remover com ícone x
  a11y      Enter ou vírgula adiciona; Backspace no campo vazio remove o último; cada chip tem botão "Remover INGLES"; mostra a forma normalizada ("Inglês → ingles")
  used on   S05, S07, S08

MediaPicker (posts, Reels, stories)
  variants  post/Reel (grade 3 colunas), story (faixa horizontal 9:16)
  states    carregando (skeleton), vazio ("Nenhum post encontrado. A conta está conectada?"), selecionado (borda 2px accent + check), erro de API
  tokens    radius md, gap 8
  a11y      cada miniatura é um botão com aria-pressed e a legenda/data como nome
  used on   S05, S07

StepBlock (passo da mensagem)
  variants  text, image, button, ask_email, delay
  states    editando, recolhido, erro de validação (borda danger), arrastando (sombra pop)
  tokens    card: bg surface-raised, borda border, radius lg, sombra card; ícone do tipo à esquerda
  a11y      reordenar também com botões "Subir/Descer" (não só arrastar); erros no topo do bloco
  regra     delay mostra "no máximo 23 h" e bloqueia acima disso (janela de 24 h)
  used on   S09

PhonePreview (pré-visualização da DM)
  variants  retrato
  states    vazio ("Adicione um passo"), com mensagens, botão de link
  tokens    balão recebido: bg bubble-in, text text; balão enviado: bg bubble-out, text on-bubble-out; radius bubble
  a11y      região com aria-label "Pré-visualização da mensagem"; é só visual, o conteúdo real está nos StepBlocks
  used on   S09, S10

Table
  variants  com busca, com filtro por tag, paginada
  states    carregando (skeleton de 5 linhas), vazia (EmptyState), cheia, erro
  tokens    cabeçalho text-muted xs/600; linhas com borda border; hover bg surface
  layout    abaixo de md vira lista de cards (sem rolagem horizontal)
  a11y      <table> real com <th scope>; ordenação com aria-sort
  used on   S03, S11

StatCard
  variants  número, número + variação
  states    sem dados ("—" e "Ainda sem disparos"), com dados, carregando
  tokens    bg surface-raised, radius lg, número xl, rótulo text-muted sm
  used on   S14

ConversationList + ChatPane (caixa de entrada)
  variants  lista (esquerda) + conversa; no tablet em retrato, uma tela por vez
  states    não lida (ponto accent + negrito), lida, bot pausado (badge warning "Bot pausado"), janela fechada (faixa warning-soft: "A janela de 24 h fechou. Você só pode responder quando a pessoa escrever de novo." e campo desativado)
  tokens    balões iguais ao PhonePreview
  a11y      lista com role="listbox"; mensagens novas anunciadas em aria-live="polite"
  used on   S13

Badge
  variants  gatilho (Comentário / Story / DM), status (Ativa / Pausada / Rascunho), aviso
  tokens    radius pill, xs/500; neutro: bg surface, text text-muted; ativa: success-soft/success; aviso: warning-soft/warning; erro: danger-soft/danger
  used on   S03, S12, S13

Toast
  variants  sucesso, erro
  states    entrando, visível 4 s, saindo; erro não some sozinho
  a11y      role="status" (sucesso) / role="alert" (erro)
  used on   todas

Modal de confirmação
  variants  apagar, desconectar
  states    aberto, confirmando (botão loading)
  a11y      Radix Dialog: foco preso, Esc fecha, o foco volta para quem abriu; botão perigoso não é o foco inicial
  used on   S03, S12, S15

EmptyState
  variants  primeira vez (com botão de ação), filtro sem resultado
  tokens    ícone Lucide 32px text-muted, título lg, texto text-muted
  used on   S03, S11, S13, S14

Banner de conexão (S02 e topo do app)
  variants  conectado (success), conta pessoal (warning: "Mude para conta profissional no Instagram"), token vencendo em menos de 10 dias (warning), token vencido (danger: "As automações estão paradas. Conecte de novo.")
  a11y      role="alert" só para danger
  used on   S02, layout geral
```

Layout: barra lateral de 240 px a partir de `lg`; abaixo disso, barra inferior com 4 itens (Automações, Contatos, Caixa de entrada, Configurações). Cabeçalho de 56 px. Conteúdo com no máximo 1120 px.
