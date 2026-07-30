# Roluna Connect

Central de comunicação interna da **Roluna Rolamentos** — app Flutter (Android, iOS, Web) com backend em Supabase/PostgreSQL.

## Backend já provisionado ✅

O projeto Supabase **`roluna-connect`** já foi criado e está no ar:

- Região: `sa-east-1` (São Paulo)
- URL: `https://gvloqylqscbjqwypgpgm.supabase.co`
- Schema completo aplicado (11 tabelas, RLS habilitada em todas, views e triggers)
- Checagem de segurança rodada e corrigida (views não vazam mais dados sem RLS,
  funções com `search_path` fixo, RPCs sensíveis restritas)
- **Setores/ramais ainda não populados** — o app está pronto para cadastro real
  (ver `supabase/seed.sql` se quiser usar os dados de exemplo depois)

As credenciais já estão preenchidas em `lib/core/constants/app_constants.dart`
(`SupabaseConfig`), então basta rodar `flutter pub get` e `flutter run`.

### Falta só um passo manual: criar o primeiro admin

1. Cadastre um usuário normalmente pela tela de login (ou pelo painel do
   Supabase em Authentication → Users → Add user)
2. No SQL Editor do projeto, rode:
   ```sql
   update public.profiles set role = 'admin' where email = 'seu@email.com';
   ```

## Stack

- **Flutter 3.x** (Material 3), organizado em arquitetura por camadas/módulos
- **Supabase**: Auth (e-mail/senha) + Postgres + Row Level Security
- **Riverpod** para estado e injeção de dependência
- **go_router** para navegação declarativa com shell de bottom navigation

## Arquitetura de pastas

```
lib/
  core/            # transversal: tema, cores, rotas, cliente Supabase, widgets compartilhados
    constants/
    router/
    supabase/
    theme/
    utils/
    widgets/
  data/
    models/        # classes imutáveis que espelham as tabelas/JSON do Supabase
  repositories/     # única camada que fala com o Supabase (uma por domínio)
  providers/        # providers Riverpod (repositories + estado de sessão)
  features/         # uma pasta por tela/fluxo, sem dependências cruzadas
    auth/
    home/
    comunicados/
    feed/
    ramais/
    aniversariantes/
    admin/
    shell/
```

Regra de dependência: `features` → `providers` → `repositories` → `core/supabase`.
Nenhuma tela chama o Supabase diretamente — tudo passa pelos repositories, o que
permite trocar a fonte de dados no futuro sem tocar na UI.

## Banco de dados

Todo o schema está em `supabase/schema.sql` (rodar no SQL Editor do Supabase ou via CLI):

- `profiles` — estende `auth.users`, guarda `role` (admin/colaborador), setor, ramal, aniversário
- `comunicados` + `confirmacoes_leitura` + `comunicado_likes` + `comunicado_comentarios`
- `posts` (feed geral) + `post_likes` + `post_comentarios`
- `setores` / `ramais`
- `notificacoes`
- Views `vw_admin_dashboard` e `vw_comunicado_stats` para os números do painel admin
- RLS habilitada em todas as tabelas: leitura liberada para autenticados,
  escrita de comunicados restrita a `role = 'admin'` via função `is_admin()`
- Trigger `handle_new_user` cria o `profile` automaticamente no cadastro

`supabase/seed.sql` tem dados de exemplo de setores/ramais para desenvolvimento.

### Recriando o backend do zero (se precisar)

1. Criar um projeto em [supabase.com](https://supabase.com)
2. Rodar `supabase/schema.sql` no SQL Editor
3. (Opcional) Rodar `supabase/seed.sql` para dados de teste
4. Criar o primeiro usuário admin (ver instruções acima)
5. Preencher `lib/core/constants/app_constants.dart` (`SupabaseConfig`) com a URL e a anon key

## Fluxo de navegação

```
/login  (redireciona para /home se já autenticado)
/home                     ─┐
/comunicados               │  abas do shell (bottom navigation)
/feed                       │  — o item "Admin" só aparece se role = admin
/ramais                     │
/admin                     ─┘
/aniversariantes            (acessível via atalho, fora da bottom nav)
/comunicados/novo           (form de criação — admin)
/comunicados/:id            (detalhe + confirmação de leitura + curtidas/comentários)
/comunicados/:id/confirmacoes  (painel admin: quem confirmou / pendentes)
```

O redirecionamento de autenticação é reativo: qualquer mudança em `authStateProvider`
(login/logout) faz o `go_router` reavaliar a rota atual automaticamente.

## O que já está implementado (MVP)

- Login com e-mail/senha (Supabase Auth)
- Home com comunicados fixados, últimos comunicados, aniversariantes do dia e atalhos
- Lista de comunicados com filtro por categoria
- Detalhe do comunicado com curtidas e **confirmação de leitura obrigatória**
  (botão "Li e estou ciente", com registro de usuário/data/hora)
- Criação de comunicado pelo admin (categoria, prioridade, fixar, agendamento)
- Painel de confirmações: percentual de leitura, lista de quem confirmou e pendentes
- Feed geral estilo rede social interna, com destaque visual para posts de admin
- Ramais internos agrupados por departamento
- Aniversariantes por mês
- Dashboard administrativo com estatísticas gerais

## Próximos passos sugeridos (fora do escopo deste MVP)

- Upload real de anexos (imagem/PDF) via Supabase Storage
- Push notifications para comunicados obrigatórios/urgentes
- Comentários completos na tela de detalhe do comunicado (já modelados no banco)
- Tela de gerenciamento de colaboradores e ramais pelo admin
- Testes automatizados (widget/unit) para repositories e telas críticas

## Rodando o projeto

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=SUA-ANON-KEY
```
