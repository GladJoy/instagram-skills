# Mapa de recon: ManyChat (web), DM automática no Instagram

Escopo: automação de DMs no Instagram. A pessoa comenta uma palavra-chave num post ou Reel, responde um story ou manda uma palavra-chave na DM e recebe uma resposta automática, que pode ter link, sequência curta de mensagens e captura de e-mail. Fora do escopo: WhatsApp, Messenger, TikTok, e-mail marketing, IA conversacional.
Para: uso próprio de Gladys (English by Gladys / SPEAK NOW), com uma conta de Instagram e sem cobrança. Isso tira cadastro multiusuário, planos e pagamento.
Data: 2026-10-27

Fontes: só páginas públicas (guias, blog do ManyChat via busca, documentação da Meta). Não houve acesso a nenhuma conta do ManyChat. As telas abaixo são **inferidas** desses guias, não vistas. Se você tiver conta no ManyChat, um passeio de 10 minutos por ela, com você clicando, deixa este mapa bem mais preciso.

## Fontes

| # | fonte | URL | o que deu |
| --- | --- | --- | --- |
| 1 | blog ManyChat: guia de automação de comentários | https://manychat.com/blog/the-ultimate-guide-for-instagram-comment-automation/ | gatilho "comenta no post/Reel", escolha do post, palavra-chave, resposta pública, DM |
| 2 | blog ManyChat: gatilho de resposta a story | https://manychat.com/blog/instagram-story-reply-trigger-convert-channels/ | story reply com palavra-chave ou qualquer resposta |
| 3 | blog ManyChat: FAQs no Instagram | https://manychat.com/blog/get-smarter-answering-instagram-faqs-with-manychat/ | palavras-chave na DM para respostas prontas |
| 4 | Kanal: ManyChat para Instagram | https://getkanal.com/blog/manychat-instagram | três tipos de gatilho, regras da Meta, erros comuns |
| 5 | Dealism: passo a passo | https://dealism.ai/blog/manychat-instagram | seções Automation, Flows e Inbox |
| 6 | InstantDM: comentário para DM | https://instantdm.com/blog/how-to-set-up-instagram-comment-to-dm-automation-in-5-minutes | variações de palavra-chave, [[first_name]] |
| 7 | WisdomAI: boas práticas | https://wisdomai.com/insights/JadeBeason/manychat-instagram-automation-engagement-comment-to-dm-f6593fed | link em botão, um pedido por mensagem |
| 8 | Meta: Private Replies | https://developers.facebook.com/docs/instagram-platform/private-replies/ | 1 resposta privada por comentário, até 7 dias |
| 9 | Meta: Private Replies (Messaging) | https://developers.facebook.com/documentation/business-messaging/instagram-messaging/features/private-replies.md | follow-up só depois que a pessoa responder, janela de 24 h |
| 10 | Comunidade n8n: erro de janela | https://community.n8n.io/t/instagram-messaging-api-this-message-is-sent-outside-of-allowed-window/262109 | erro 10 / 2534022 fora da janela |
| 11 | ChatArmin: preços | https://chatarmin.com/en/blog/manychat-pricing | o que é pago: contatos, automações avançadas |

## Loop principal

Alguém comenta "INGLES" num Reel, recebe na hora uma DM com o material prometido, e a conversa (e o contato) fica salva para você continuar.

## Telas

| ID | tela | como chegar | propósito | componentes | estados |
| --- | --- | --- | --- | --- | --- |
| S01 | Login | `/login` | entrar na ferramenta (só você) | form, botão | vazio, erro |
| S02 | Conectar Instagram | primeira vez / Configurações | autorizar a conta Business/Creator pela Meta | botão "Conectar", status da conexão | não conectado, conectado, conta pessoal (inelegível), token expirado |
| S03 | Painel / lista de automações | `/automations` | ver todas as automações, ligar e desligar | tabela, toggle ativo, badges de gatilho, contadores | vazio, cheio, carregando |
| S04 | Escolher modelo de automação | botão "Nova automação" | começar por tipo: comentário, story, DM | cards de modelo | — |
| S05 | Editor: gatilho de comentário | S04 → Comentário | escolher post/Reel (um, todos, o próximo), palavras-chave, excluir palavras | seletor de post com miniaturas, input de tags de palavra-chave, toggle "qualquer comentário" | sem posts (conta não ligada), cheio |
| S06 | Editor: resposta pública | dentro de S05 | respostas públicas variadas embaixo do comentário | lista de textos alternativos, toggle | ligado, desligado |
| S07 | Editor: gatilho de story | S04 → Story | todas as stories ou uma, palavra-chave ou qualquer resposta | seletor de story, input de palavra-chave | sem stories ativas |
| S08 | Editor: gatilho de palavra-chave na DM | S04 → DM | responder quando a DM contém/é igual à palavra | input de palavras, regra "contém / igual / começa com" | — |
| S09 | Editor: mensagens (fluxo) | etapa seguinte de S05/S07/S08 | montar a DM: texto, imagem, botão com link, pergunta de e-mail, atraso | blocos de mensagem em sequência, botão, variável {first_name}, pré-visualização tipo celular | rascunho, publicado, erro de validação |
| S10 | Pré-visualização / teste | botão "Testar" no editor | mandar o fluxo para a própria conta | instruções, status do envio | enviado, falhou |
| S11 | Contatos | `/contacts` | todo mundo que já interagiu, com tags e e-mail | tabela, busca, filtros por tag, exportar CSV | vazio, cheio |
| S12 | Detalhe do contato | clique em S11 | histórico, tags, campos (e-mail), de qual automação veio | perfil, linha do tempo, tags editáveis | — |
| S13 | Caixa de entrada (Inbox) | `/inbox` | ver e responder DMs na mão, pausar a automação daquela pessoa | lista de conversas, chat, campo de resposta, toggle "pausar bot" | vazio, cheio, janela de 24 h fechada |
| S14 | Estatísticas da automação | aba de S03 / S09 | quantos dispararam, enviados, cliques no link, e-mails capturados | cards de número, gráfico simples | sem dados, com dados |
| S15 | Configurações | `/settings` | conta conectada, fuso horário, palavras globais, desconectar | form | — |

## Fluxos

```
F01 Conectar o Instagram (uma vez)
    S01 -> S02 -> (tela da Meta) -> S02 conectado -> S03
    cliques no caminho feliz: 4
    exceção: conta pessoal (precisa virar Business/Creator), conta sem Página do Facebook
             no caminho antigo, permissão negada, token expira em 60 dias

F02 Criar automação "comentou a palavra, recebe DM"  (o loop principal)
    S03 -> S04 -> S05 (post + palavra) -> S06 (resposta pública) -> S09 (DM com botão/link) -> S10 -> publicar
    cliques no caminho feliz: ~10
    exceção: palavra com acento/maiúscula ("Inglês", "INGLES"), emoji no comentário,
             a mesma pessoa comenta 3 vezes, comentário de mais de 7 dias, post apagado

F03 Seguidor comenta e recebe a DM  (o que a pessoa de fora vê)
    comentário no Reel -> resposta pública embaixo do comentário -> DM com o link
    exceção: a pessoa não abre a DM (fica em "pedidos de mensagem"),
             só 1 mensagem permitida até ela responder (regra da Meta)

F04 Sequência depois que a pessoa responde
    DM inicial com botão "Quero receber" -> pessoa toca -> janela de 24 h abre -> pede e-mail -> salva no contato -> manda o link
    exceção: e-mail inválido, pessoa some, resposta depois de 24 h (não dá mais para mandar mensagem automática)

F05 Resposta a story com palavra-chave
    S03 -> S04 -> S07 -> S09 -> publicar ; seguidor responde o story -> recebe DM
    exceção: reação com emoji no lugar de texto, story expirou

F06 Palavra-chave na DM ("PRECO", "AULA")
    S03 -> S04 -> S08 -> S09 -> publicar
    exceção: a mesma DM bate em duas palavras (precisa de prioridade)

F07 Assumir a conversa na mão
    S13 -> abrir conversa -> pausar bot -> responder -> reativar bot
    exceção: janela de 24 h fechada (o campo de resposta deve avisar)

F08 Ver o que funcionou
    S03 -> S14
```

## Componentes

| componente | variantes | estados | usado em |
| --- | --- | --- | --- |
| Botão | primário, secundário, perigo, link | normal, hover, foco, desativado, carregando | todas |
| Toggle ativo/inativo | — | ligado, desligado, desativado | S03, S06, S13 |
| Input de palavras-chave (tags) | contém, igual, começa com | vazio, com tags, erro de duplicado | S05, S07, S08 |
| Seletor de post/story | grade de miniaturas | carregando, vazio, selecionado | S05, S07 |
| Bloco de mensagem | texto, imagem, botão com link, pergunta (e-mail), espera | editando, erro, pré-visualização | S09 |
| Pré-visualização de celular | balões de DM | — | S09 |
| Tabela | com busca, filtro, paginação | vazia, cheia, carregando | S03, S11 |
| Card de número | — | sem dados, com dados | S14 |
| Lista de conversas + chat | — | não lida, lida, bot pausado, janela fechada | S13 |
| Toast | sucesso, erro | — | todas |
| Modal de confirmação | apagar, desconectar | — | S03, S15 |

## Modelo de dados inferido

```
Account      id, ig_user_id, username, access_token (criptografado), token_expires_at, connected_at
             evidência: S02, docs da Meta (Business Login for Instagram)    confiança: alta

Automation   id, name, trigger_type (comment | story_reply | dm_keyword), active, created_at,
             post_scope (all | specific | next), post_ids[], story_ids[],
             keywords[], match_mode (contains | exact | starts_with), exclude_keywords[], any_text (bool),
             public_replies[] (só comentário), priority
             evidência: S05, S07, S08, fontes 1-3    confiança: alta

Step         id, automation_id, position, type (text | image | button | ask_email | delay),
             body, button_label, button_url, wait_seconds
             evidência: S09, fontes 6-7    confiança: média

Contact      id, ig_scoped_id, username, name, email, tags[], first_seen_at, last_inbound_at,
             bot_paused (bool), source_automation_id
             evidência: S11, S12; last_inbound_at é preciso para a janela de 24 h    confiança: alta

Conversation id, contact_id, messages: Message[]
Message      id, contact_id, direction (in | out), body, sent_by (bot | human), ig_message_id, created_at
             evidência: S13    confiança: alta

Event        id, automation_id, contact_id, type (triggered | public_reply | dm_sent | button_click |
             email_captured | failed), error_code, comment_id, created_at
             evidência: S14 (contadores)    confiança: média (palpite sobre o formato)

ProcessedComment  comment_id (único), automation_id, replied_at
             evidência: regra da Meta "1 resposta privada por comentário"; evita mandar duas vezes    confiança: alta
```

Relações: Account 1-n Automation, Automation 1-n Step, Account 1-n Contact, Contact 1-n Message, Automation 1-n Event.

## Lista de funcionalidades

Ver `features.csv`. Must: 14, should: 9, could: 6, skip: 6.

## Fora do escopo (não dá ou não deve ser clonado)

- A marca, os textos, os modelos prontos e o visual do ManyChat (o clone usa nome e visual próprios).
- Os outros canais (WhatsApp, Messenger, TikTok, SMS, e-mail): fora da fatia escolhida.
- O marketplace de modelos e as integrações de parceiros: são a rede deles, não o produto.
- Qualquer coisa que a API da Meta não permita: mandar DM para quem não interagiu, mais de 1 mensagem antes da pessoa responder, mensagem automática depois de 24 h.
- O "status de parceiro oficial" da Meta que o ManyChat tem: o clone usa a API oficial em nome da sua própria conta e precisa passar pela análise do app da Meta (ver abaixo).

## Tamanho

Telas 15, fluxos 8, entidades 8.

Partes difíceis:
1. **Aprovação da Meta.** Responder comentário e mandar DM exige um app da Meta com as permissões `instagram_business_manage_messages` e `instagram_business_manage_comments`. Para usar só na sua própria conta, o modo de desenvolvimento costuma bastar se você for administradora do app. Para outras contas, precisa da análise do app (App Review), que leva semanas e pede vídeo e política de privacidade.
2. **Webhooks confiáveis.** A Meta avisa de cada comentário/DM por webhook. Precisa de servidor público em HTTPS, verificação da assinatura, fila e retentativa, e não pode responder duas vezes o mesmo comentário.
3. **Regras de janela.** 1 resposta privada por comentário em até 7 dias, follow-up só depois que a pessoa responder e só por 24 h. O editor precisa impedir fluxos que a Meta vai recusar.

Tamanho: **M** (algumas semanas) para uso próprio com comentário + story + DM, editor de sequência simples, contatos e inbox. Sem editor visual de arrastar blocos, que deixaria em L.
