# Arquitetura: clone de DM automática no Instagram (recriação das funções principais do ManyChat)

Lê: `replica/recon.md`, `replica/features.csv`. SQL completo: `replica/schema.sql`.
Uso próprio: uma dona, uma conta de Instagram profissional, sem cobrança.

## Stack

| camada | escolha | por quê |
| --- | --- | --- |
| web | Next.js (App Router) + TypeScript | telas e webhooks no mesmo projeto; padrão bem documentado |
| estilo | Tailwind, com os tokens do `/replica-design` | rápido de montar, consistente |
| banco | Postgres no Supabase | gerenciado, plano grátis basta para uso próprio, RLS pronta |
| ORM | Drizzle | SQL explícito, migrações em arquivo |
| login | Supabase Auth, só e-mail com link mágico | uma usuária; cadastro aberto desligado |
| Instagram | API oficial da Meta: Instagram API with Instagram Login (`graph.instagram.com`) | único caminho permitido; sem API privada |
| pagamentos | nenhum | uso próprio (fica para depois se virar produto) |
| e-mail | nenhum no início | o e-mail capturado só é salvo; enviar para ferramenta de e-mail é "could" |
| jobs | Inngest (plano grátis) | o webhook precisa responder rápido à Meta; o envio roda em segundo plano, com retentativa e espera (`delay`) |
| hospedagem | Vercel | HTTPS público, que a Meta exige para o webhook |

Um banco, um app. Nada de microsserviços.

## Esquema

Tabelas: 9 (`ig_accounts`, `automations`, `automation_steps`, `contacts`, `messages`, `processed_comments`, `runs`, `events`, `links`).
Acesso: **RLS do Postgres** (cada linha tem `owner_id = auth.uid()`). O webhook e os jobs usam a service role no servidor. O token da Meta é criptografado na aplicação e nunca vai para o navegador (a tela lê `ig_accounts_public`).

Restrições que resolvem os problemas do recon no banco, não na tela:
- `processed_comments.comment_id` é chave primária: o job grava ali **antes** de mandar a DM. Se a Meta reenviar o mesmo comentário, o segundo insert falha e nada é enviado duas vezes.
- `messages.ig_message_id` único: DM recebida duas vezes não duplica.
- `contacts (ig_account_id, igsid)` único: a mesma pessoa vira um contato só.
- `automation_steps.wait_seconds` até 23 h: impede montar uma espera que cairia fora da janela de 24 h.
- `norm()` (minúsculas + sem acento): "Inglês", "INGLES" e "ingles" batem na mesma palavra.

## API

| método caminho | faz | quem | entrada | saída | fluxo |
| --- | --- | --- | --- | --- | --- |
| GET /api/meta/oauth/start | manda para o login do Instagram | dona logada | — | redirect | F01 |
| GET /api/meta/oauth/callback | troca o código por token longo, salva a conta, assina os webhooks | Meta (redirect) | code, state | redirect para S03 | F01 |
| GET /api/meta/webhook | verificação do webhook (hub.challenge) | Meta | hub.* | challenge | F01 |
| POST /api/meta/webhook | recebe comentários, DMs, respostas a story; confere a assinatura; enfileira | Meta | evento assinado | 200 em menos de 1 s | F03, F05, F06 |
| GET /api/meta/media | lista posts/Reels/stories para o seletor | dona | tipo | miniaturas | F02, F05 |
| action createAutomation / updateAutomation | salva gatilho, palavras, respostas públicas | dona | form | automação | F02, F05, F06 |
| action saveSteps | salva a lista de passos da mensagem | dona | passos | ok / erros | F02 |
| action toggleAutomation | liga ou desliga | dona | id, ativo | ok | F02 |
| action testAutomation | manda o fluxo para a própria conta | dona | id | status | F02 |
| GET /contacts, /contacts/:id | lista e detalhe | dona | busca, tag | contatos | — |
| GET /contacts.csv | exportar | dona | filtro | CSV | could |
| action sendManualReply | resposta manual pela caixa de entrada (só com janela aberta) | dona | contato, texto | mensagem | F07 |
| action setBotPaused | pausa ou retoma o bot para um contato | dona | contato, bool | ok | F07 |
| GET /l/:id | redireciona o link do botão e conta o clique | qualquer pessoa | id | 302 | F04, F08 |
| GET /automations/:id/stats | números de S14 | dona | período | contadores | F08 |

Webhooks que chegam: Meta (`comments`, `live_comments` fica fora, `messages`, `messaging_postbacks`, respostas a story vêm como `messages` com `reply_to.story`).
Webhooks que saem: nenhum no início (enviar contato para planilha é "could").

Jobs (Inngest):
- `handle-comment`: casa a automação, grava `processed_comments`, manda resposta pública e a resposta privada (1 mensagem). Na hora.
- `handle-dm`: atualiza `last_inbound_at`, salva a mensagem, continua um `run` que estava esperando resposta ou e-mail, ou dispara uma automação de palavra-chave na DM. Na hora.
- `continue-run`: manda os próximos passos, respeitando `delay`; antes de cada envio confere se a janela de 24 h ainda está aberta e se o bot não está pausado.
- `refresh-token`: todo dia; renova tokens que vencem em menos de 10 dias; marca `expired` se falhar e mostra aviso em S02.
- `expire-runs`: de hora em hora; marca como `expired` os runs cuja janela fechou.

## As partes que mordem

- **Janelas da Meta:** resposta privada só 1 por comentário e até 7 dias; depois disso, só se a pessoa responder, e por 24 h. Toda função de envio passa por uma checagem central (`canSend(contact)`), nunca espalhada.
- **Idempotência:** a Meta reenvia webhooks. `processed_comments` e `ig_message_id` único resolvem no banco.
- **Corridas:** duas automações batendo no mesmo comentário → só a de menor `priority` roda (o claim em `processed_comments` decide).
- **Limites de taxa:** a API tem limite por hora; o Inngest limita a concorrência por conta e tenta de novo com espera.
- **Webhook rápido:** responder 200 em até 1 s e jogar o trabalho para a fila; a Meta desliga webhooks que falham muito.
- **Assinatura:** conferir `X-Hub-Signature-256` com o app secret em todo POST.
- **Token:** dura 60 dias; se vencer, as automações param em silêncio. Por isso o job diário e o aviso em S02.
- **Fuso:** tudo em `timestamptz` (UTC); a tela mostra no fuso de São Paulo.
- **Aprovação da Meta:** em modo de desenvolvimento, só contas com papel no app funcionam. Para uso próprio, adicionar sua conta do Instagram como testadora basta. Para outras pessoas, é preciso passar pela análise do app (App Review).
- **LGPD:** botão para apagar um contato (cascata em mensagens, runs e links).

## Ordem de construção

1. **Fatia vertical (o loop principal, feio):** S01, S02, S05 mínimo, S09 só com texto + botão. Tabelas `ig_accounts`, `automations`, `automation_steps`, `contacts`, `processed_comments`, `events`. Rotas: OAuth, webhook, job `handle-comment`. Pronto quando: você comenta "INGLES" num Reel de teste e recebe a DM com o link.
2. **Must-haves:** S03 (lista com liga/desliga), palavras sem acento, escolher post (um/todos/o próximo), `{first_name}`, registro de erro, aviso de conta pessoal/token. Job `refresh-token`.
3. **Should-haves:** S06 respostas públicas, S07 story, S08 DM com palavra, `runs` + `continue-run` + pedir e-mail (F04), S11-S13 contatos e caixa de entrada, S14 estatísticas com `/l/:id`, S10 testar.
4. **Could-haves:** excluir palavras, CSV, imagem, atraso, enviar para planilha.
5. **Melhorias do `/replica-entrepreneur`**, depois que ele rodar.

## O que você precisa providenciar antes da fatia 1

- Conta de desenvolvedora na Meta (developers.facebook.com) e um app do tipo **Business** com o produto **Instagram** (API with Instagram Login). Ainda não sabemos se você tem.
- Sua conta do Instagram (já é profissional) adicionada como **testadora** do app.
- Contas grátis no Supabase, na Vercel e no Inngest.
