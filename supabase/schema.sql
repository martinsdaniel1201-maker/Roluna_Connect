-- =========================================================================
-- ROLUNA CONNECT — Schema do banco de dados (Supabase / PostgreSQL)
-- =========================================================================
-- Convenções:
--   * Toda tabela tem id uuid, created_at, updated_at.
--   * auth.users (Supabase Auth) é a fonte da identidade; profiles estende.
--   * RLS habilitado em todas as tabelas de negócio.
-- =========================================================================

create extension if not exists "uuid-ossp";

-- -------------------------------------------------------------------------
-- ENUMS
-- -------------------------------------------------------------------------
create type user_role as enum ('admin', 'colaborador');
create type comunicado_categoria as enum ('rh','comercial','financeiro','logistica','estoque','diretoria','geral');
create type comunicado_prioridade as enum ('normal','importante','urgente','obrigatorio');
create type comunicado_status as enum ('rascunho','agendado','publicado','arquivado');

-- -------------------------------------------------------------------------
-- PROFILES  (estende auth.users)
-- -------------------------------------------------------------------------
create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  nome_completo text not null,
  email         text not null unique,
  cargo         text,
  setor         text,
  ramal         text,
  telefone      text,
  foto_url      text,
  data_nascimento date,
  role          user_role not null default 'colaborador',
  ativo         boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on table public.profiles is 'Dados do colaborador; role define permissões (admin/colaborador).';

-- -------------------------------------------------------------------------
-- SETORES / RAMAIS
-- -------------------------------------------------------------------------
create table public.setores (
  id          uuid primary key default uuid_generate_v4(),
  nome        text not null,
  departamento text, -- ex: "Administrativo", "Comercial"
  ordem       int default 0,
  created_at  timestamptz not null default now()
);

create table public.ramais (
  id          uuid primary key default uuid_generate_v4(),
  setor_id    uuid references public.setores(id) on delete set null,
  nome_local  text not null,          -- ex: "Recepção", "Vendas"
  responsavel text,
  numero      text not null,
  created_at  timestamptz not null default now()
);

-- -------------------------------------------------------------------------
-- COMUNICADOS
-- -------------------------------------------------------------------------
create table public.comunicados (
  id            uuid primary key default uuid_generate_v4(),
  titulo        text not null,
  descricao     text not null,
  autor_id      uuid not null references public.profiles(id),
  categoria     comunicado_categoria not null default 'geral',
  prioridade    comunicado_prioridade not null default 'normal',
  status        comunicado_status not null default 'publicado',
  fixado        boolean not null default false,
  obrigatorio   boolean not null default false, -- redundante c/ prioridade, útil p/ query rápida
  anexo_url     text,
  publicar_em   timestamptz default now(),       -- suporte a agendamento
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index idx_comunicados_publicar_em on public.comunicados (publicar_em desc);
create index idx_comunicados_fixado on public.comunicados (fixado);
create index idx_comunicados_categoria on public.comunicados (categoria);

-- Confirmação de leitura (para comunicados obrigatórios)
create table public.confirmacoes_leitura (
  id            uuid primary key default uuid_generate_v4(),
  comunicado_id uuid not null references public.comunicados(id) on delete cascade,
  usuario_id    uuid not null references public.profiles(id) on delete cascade,
  confirmado_em timestamptz not null default now(),
  unique (comunicado_id, usuario_id)
);

-- Curtidas em comunicados
create table public.comunicado_likes (
  comunicado_id uuid not null references public.comunicados(id) on delete cascade,
  usuario_id    uuid not null references public.profiles(id) on delete cascade,
  created_at    timestamptz not null default now(),
  primary key (comunicado_id, usuario_id)
);

-- Comentários em comunicados
create table public.comunicado_comentarios (
  id            uuid primary key default uuid_generate_v4(),
  comunicado_id uuid not null references public.comunicados(id) on delete cascade,
  autor_id      uuid not null references public.profiles(id),
  texto         text not null,
  created_at    timestamptz not null default now()
);

-- -------------------------------------------------------------------------
-- FEED GERAL (posts de colaboradores e admins)
-- -------------------------------------------------------------------------
create table public.posts (
  id          uuid primary key default uuid_generate_v4(),
  autor_id    uuid not null references public.profiles(id),
  texto       text not null,
  anexo_url   text,
  anexo_tipo  text, -- 'imagem' | 'pdf'
  publicar_em timestamptz default now(), -- agendamento
  status      comunicado_status not null default 'publicado',
  created_at  timestamptz not null default now()
);

create index idx_posts_publicar_em on public.posts (publicar_em desc);

create table public.post_likes (
  post_id    uuid not null references public.posts(id) on delete cascade,
  usuario_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, usuario_id)
);

create table public.post_comentarios (
  id         uuid primary key default uuid_generate_v4(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  autor_id   uuid not null references public.profiles(id),
  texto      text not null,
  created_at timestamptz not null default now()
);

-- -------------------------------------------------------------------------
-- NOTIFICAÇÕES (registro simples; envio via push fica para integração futura)
-- -------------------------------------------------------------------------
create table public.notificacoes (
  id          uuid primary key default uuid_generate_v4(),
  usuario_id  uuid not null references public.profiles(id) on delete cascade,
  titulo      text not null,
  corpo       text,
  referencia_tipo text, -- 'comunicado' | 'post'
  referencia_id   uuid,
  lida        boolean not null default false,
  created_at  timestamptz not null default now()
);

-- =========================================================================
-- FUNÇÃO HELPER: papel do usuário atual
-- =========================================================================
create or replace function public.current_user_role()
returns user_role
language sql stable security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select coalesce((select role = 'admin' from public.profiles where id = auth.uid()), false);
$$;

-- Restringe quem pode chamar estas funções diretamente via RPC:
-- só usuários autenticados (necessário para a RLS avaliar as políticas).
revoke execute on function public.is_admin() from public;
revoke execute on function public.current_user_role() from public;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.current_user_role() to authenticated;

-- =========================================================================
-- ROW LEVEL SECURITY
-- =========================================================================
alter table public.profiles enable row level security;
alter table public.setores enable row level security;
alter table public.ramais enable row level security;
alter table public.comunicados enable row level security;
alter table public.confirmacoes_leitura enable row level security;
alter table public.comunicado_likes enable row level security;
alter table public.comunicado_comentarios enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comentarios enable row level security;
alter table public.notificacoes enable row level security;

-- PROFILES: todos autenticados podem ler; só o próprio usuário ou admin edita.
create policy "profiles_select_all" on public.profiles for select using (auth.role() = 'authenticated');
create policy "profiles_update_own_or_admin" on public.profiles for update
  using (auth.uid() = id or public.is_admin());
create policy "profiles_insert_admin" on public.profiles for insert
  with check (public.is_admin() or auth.uid() = id);

-- SETORES / RAMAIS: leitura geral, escrita só admin.
create policy "setores_select_all" on public.setores for select using (auth.role() = 'authenticated');
create policy "setores_write_admin" on public.setores for all using (public.is_admin()) with check (public.is_admin());

create policy "ramais_select_all" on public.ramais for select using (auth.role() = 'authenticated');
create policy "ramais_write_admin" on public.ramais for all using (public.is_admin()) with check (public.is_admin());

-- COMUNICADOS: leitura geral (publicados); escrita (create/update/delete) só admin.
create policy "comunicados_select_all" on public.comunicados for select
  using (auth.role() = 'authenticated' and (status = 'publicado' or public.is_admin()));
create policy "comunicados_insert_admin" on public.comunicados for insert with check (public.is_admin());
create policy "comunicados_update_admin" on public.comunicados for update using (public.is_admin());
create policy "comunicados_delete_admin" on public.comunicados for delete using (public.is_admin());

-- CONFIRMAÇÕES DE LEITURA: usuário só cria a própria; admin vê todas; usuário vê a própria.
create policy "confirmacoes_select" on public.confirmacoes_leitura for select
  using (usuario_id = auth.uid() or public.is_admin());
create policy "confirmacoes_insert_own" on public.confirmacoes_leitura for insert
  with check (usuario_id = auth.uid());

-- LIKES / COMENTÁRIOS de comunicados: qualquer autenticado interage; exclui o próprio ou admin.
create policy "comunicado_likes_select" on public.comunicado_likes for select using (auth.role() = 'authenticated');
create policy "comunicado_likes_insert_own" on public.comunicado_likes for insert with check (usuario_id = auth.uid());
create policy "comunicado_likes_delete_own" on public.comunicado_likes for delete using (usuario_id = auth.uid());

create policy "comunicado_comentarios_select" on public.comunicado_comentarios for select using (auth.role() = 'authenticated');
create policy "comunicado_comentarios_insert_own" on public.comunicado_comentarios for insert with check (autor_id = auth.uid());
create policy "comunicado_comentarios_delete_own_or_admin" on public.comunicado_comentarios for delete
  using (autor_id = auth.uid() or public.is_admin());

-- POSTS (feed geral): todo colaborador autenticado pode criar; edita/exclui o próprio ou admin.
create policy "posts_select_all" on public.posts for select
  using (auth.role() = 'authenticated' and (status = 'publicado' or autor_id = auth.uid() or public.is_admin()));
create policy "posts_insert_own" on public.posts for insert with check (autor_id = auth.uid());
create policy "posts_update_own_or_admin" on public.posts for update using (autor_id = auth.uid() or public.is_admin());
create policy "posts_delete_own_or_admin" on public.posts for delete using (autor_id = auth.uid() or public.is_admin());

create policy "post_likes_select" on public.post_likes for select using (auth.role() = 'authenticated');
create policy "post_likes_insert_own" on public.post_likes for insert with check (usuario_id = auth.uid());
create policy "post_likes_delete_own" on public.post_likes for delete using (usuario_id = auth.uid());

create policy "post_comentarios_select" on public.post_comentarios for select using (auth.role() = 'authenticated');
create policy "post_comentarios_insert_own" on public.post_comentarios for insert with check (autor_id = auth.uid());
create policy "post_comentarios_delete_own_or_admin" on public.post_comentarios for delete
  using (autor_id = auth.uid() or public.is_admin());

-- NOTIFICAÇÕES: cada usuário só vê as suas.
create policy "notificacoes_select_own" on public.notificacoes for select using (usuario_id = auth.uid());
create policy "notificacoes_update_own" on public.notificacoes for update using (usuario_id = auth.uid());
create policy "notificacoes_insert_admin" on public.notificacoes for insert with check (public.is_admin());

-- =========================================================================
-- VIEWS ÚTEIS (dashboard / estatísticas)
-- =========================================================================
create or replace view public.vw_comunicado_stats as
select
  c.id as comunicado_id,
  c.titulo,
  c.obrigatorio,
  (select count(*) from public.profiles p where p.ativo) as total_colaboradores,
  (select count(*) from public.confirmacoes_leitura cl where cl.comunicado_id = c.id) as total_confirmados
from public.comunicados c;

alter view public.vw_comunicado_stats set (security_invoker = on);

create or replace view public.vw_admin_dashboard as
select
  (select count(*) from public.profiles where ativo) as total_colaboradores,
  (select count(*) from public.comunicados where status = 'publicado') as total_comunicados,
  (select count(*) from public.comunicados where obrigatorio and status = 'publicado') as total_obrigatorios,
  (select count(*) from public.posts where created_at::date = current_date) as posts_hoje;

alter view public.vw_admin_dashboard set (security_invoker = on);

-- =========================================================================
-- TRIGGERS: updated_at automático
-- =========================================================================
create or replace function public.set_updated_at()
returns trigger language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger trg_comunicados_updated before update on public.comunicados
  for each row execute function public.set_updated_at();

-- Cria profile automaticamente quando um usuário se cadastra no Supabase Auth
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nome_completo, email, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome_completo', new.email), new.email, 'colaborador');
  return new;
end;
$$;

-- Ninguém deve chamar isso via RPC: só o próprio trigger de auth.users dispara.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
