-- Esquema do clone de automação de DMs no Instagram (uso próprio).
-- Postgres no Supabase. Tudo tem owner_id (o usuário do Supabase Auth) e RLS.
-- O webhook da Meta roda no servidor com a service role e ignora a RLS.

create extension if not exists pgcrypto;
create extension if not exists unaccent;

-- Normaliza palavra-chave e texto: minúsculas, sem acento, espaços colapsados.
-- "Inglês!!" e "  INGLES " viram "ingles!!" e "ingles".
create or replace function norm(t text) returns text
language sql immutable as $$
  select btrim(regexp_replace(lower(unaccent(coalesce(t, ''))), '\s+', ' ', 'g'))
$$;

create or replace function touch_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

-- S02: a conta do Instagram conectada
create table ig_accounts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  ig_user_id text not null unique,
  username text not null,
  access_token_encrypted text not null,          -- criptografado na aplicação, nunca em texto puro
  token_expires_at timestamptz not null,         -- token longo dura 60 dias
  status text not null default 'connected'
    check (status in ('connected','expired','revoked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on ig_accounts (owner_id);
create index on ig_accounts (token_expires_at);

-- S03-S08: automações
create table automations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  ig_account_id uuid not null references ig_accounts(id) on delete cascade,
  name text not null,
  trigger_type text not null check (trigger_type in ('comment','story_reply','dm_keyword')),
  active boolean not null default false,
  -- escopo de post/story (comentário e story)
  post_scope text not null default 'all' check (post_scope in ('all','specific','next')),
  media_ids text[] not null default '{}',        -- ids de mídia do Instagram quando post_scope = 'specific'
  -- palavras-chave
  any_text boolean not null default false,       -- dispara com qualquer comentário/resposta
  keywords text[] not null default '{}',         -- guardadas já normalizadas com norm()
  match_mode text not null default 'contains' check (match_mode in ('contains','exact','starts_with')),
  exclude_keywords text[] not null default '{}',
  -- respostas públicas (só comentário); uma é sorteada por vez
  public_replies text[] not null default '{}',
  priority int not null default 100,             -- menor ganha quando duas automações batem
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint keywords_or_any check (any_text or cardinality(keywords) > 0)
);
create index on automations (owner_id);
create index on automations (ig_account_id, trigger_type, active, priority);

-- S09: passos da mensagem, em ordem
create table automation_steps (
  id uuid primary key default gen_random_uuid(),
  automation_id uuid not null references automations(id) on delete cascade,
  position int not null,
  type text not null check (type in ('text','image','button','ask_email','delay')),
  body text,                                     -- texto; aceita {first_name}
  image_url text,
  button_label text,
  button_url text,
  wait_seconds int check (wait_seconds between 0 and 82800),  -- no máximo 23 h, dentro da janela de 24 h
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (automation_id, position),
  constraint button_has_url check (type <> 'button' or (button_label is not null and button_url is not null))
);
create index on automation_steps (automation_id);

-- S11-S12: contatos
create table contacts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  ig_account_id uuid not null references ig_accounts(id) on delete cascade,
  igsid text not null,                           -- id da pessoa no escopo da sua conta
  username text,
  name text,
  email text check (email is null or email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  tags text[] not null default '{}',
  last_inbound_at timestamptz,                   -- abre a janela de 24 h
  bot_paused boolean not null default false,
  source_automation_id uuid references automations(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (ig_account_id, igsid)
);
create index on contacts (owner_id, created_at desc);
create index on contacts using gin (tags);

-- S13: mensagens
create table messages (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  contact_id uuid not null references contacts(id) on delete cascade,
  direction text not null check (direction in ('in','out')),
  sent_by text not null check (sent_by in ('contact','bot','human')),
  body text,
  ig_message_id text unique,                     -- a Meta reenvia webhooks; isso evita duplicar
  created_at timestamptz not null default now()
);
create index on messages (contact_id, created_at);
create index on messages (owner_id, created_at desc);

-- Garantia da regra da Meta: 1 resposta privada por comentário.
-- Inserir aqui ANTES de enviar; se der conflito, outro processo já respondeu.
create table processed_comments (
  comment_id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  automation_id uuid references automations(id) on delete set null,
  contact_id uuid references contacts(id) on delete set null,
  status text not null default 'claimed' check (status in ('claimed','sent','failed','skipped')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on processed_comments (owner_id, created_at desc);

-- Em que passo cada contato está numa automação (F04)
create table runs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  automation_id uuid not null references automations(id) on delete cascade,
  contact_id uuid not null references contacts(id) on delete cascade,
  next_position int not null default 0,
  status text not null default 'waiting_reply'
    check (status in ('waiting_reply','waiting_email','scheduled','done','expired','failed')),
  resume_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on runs (automation_id);
create index on runs (contact_id, status);
create index on runs (status, resume_at);

-- S14: eventos para estatística e diagnóstico
create table events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  automation_id uuid references automations(id) on delete set null,
  contact_id uuid references contacts(id) on delete set null,
  type text not null check (type in ('triggered','public_reply','dm_sent','button_click','email_captured','failed')),
  error_code text,
  detail jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index on events (automation_id, type, created_at);
create index on events (owner_id, created_at desc);

-- Links rastreáveis: /l/:id redireciona e registra button_click
create table links (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  step_id uuid not null references automation_steps(id) on delete cascade,
  contact_id uuid not null references contacts(id) on delete cascade,
  target_url text not null,
  created_at timestamptz not null default now()
);
create index on links (step_id);
create index on links (contact_id);

-- updated_at automático
create trigger t_ig_accounts before update on ig_accounts for each row execute function touch_updated_at();
create trigger t_automations before update on automations for each row execute function touch_updated_at();
create trigger t_steps before update on automation_steps for each row execute function touch_updated_at();
create trigger t_contacts before update on contacts for each row execute function touch_updated_at();
create trigger t_processed before update on processed_comments for each row execute function touch_updated_at();
create trigger t_runs before update on runs for each row execute function touch_updated_at();

-- RLS: cada linha só é visível para quem é dona dela.
alter table ig_accounts enable row level security;
alter table automations enable row level security;
alter table automation_steps enable row level security;
alter table contacts enable row level security;
alter table messages enable row level security;
alter table processed_comments enable row level security;
alter table runs enable row level security;
alter table events enable row level security;
alter table links enable row level security;

create policy own on ig_accounts for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy own on automations for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy own on automation_steps for all
  using (exists (select 1 from automations a where a.id = automation_id and a.owner_id = auth.uid()))
  with check (exists (select 1 from automations a where a.id = automation_id and a.owner_id = auth.uid()));
create policy own on contacts for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy own on messages for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy own on processed_comments for select using (owner_id = auth.uid());
create policy own on runs for select using (owner_id = auth.uid());
create policy own on events for select using (owner_id = auth.uid());
create policy own on links for select using (owner_id = auth.uid());
-- O access_token nunca vai para o navegador: a tela S02 lê de uma view sem essa coluna.
create view ig_accounts_public with (security_invoker = true) as
  select id, owner_id, ig_user_id, username, token_expires_at, status, created_at from ig_accounts;
