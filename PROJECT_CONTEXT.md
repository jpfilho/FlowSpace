# FlowSpace — Project Context & Documentation

Este documento serve como fonte de verdade para a arquitetura, estrutura e padrões de desenvolvimento do FlowSpace. Qualquer agente ou desenvolvedor que trabalhe neste repositório deve ler e seguir as diretrizes documentadas aqui.

---

## 1. Visão Geral do Projeto

**FlowSpace** é uma plataforma premium de produtividade e gestão, integrando conceitos de GTD (Getting Things Done), projetos, calendários e documentos interativos do tipo Notion (páginas compostas por blocos editáveis).

### Stack de Tecnologia
- **Frontend**: Flutter Multiplataforma (Web/Desktop/Mobile)
  - SDK Dart: `sdk: '>=3.3.0 <4.0.0'`
  - Gerenciamento de Estado: `flutter_riverpod` (Riverpod 2.x com Notifiers assíncronos)
  - Roteamento: `go_router` (Navegação declarativa com `ShellRoute` para a interface principal)
  - Animações: `flutter_animate` (Transições suaves, micro-interações)
  - Tipografia: `google_fonts` (Família de fontes *Inter*)
  - Gráficos: `fl_chart`
- **Backend / Infraestrutura**: Supabase
  - Banco de Dados: PostgreSQL com Row Level Security (RLS) e Triggers
  - Realtime: Inscrições via Postgres Changes e Canais de Presence (rastreamento de usuários ativos)
  - Armazenamento de Arquivos: Supabase Storage para anexos e capas

---

## 2. Estrutura do Código (`lib/`)

O projeto segue uma arquitetura limpa orientada a funcionalidades (*features*):

```
lib/
├── core/
│   ├── config/       # Configuração do Supabase (URL e chaves)
│   ├── errors/       # Exceções e gerenciamento de erros do app
│   ├── providers/    # Provedores globais simples (ex: tema)
│   ├── routing/      # Definições de rotas do GoRouter e transições
│   ├── services/     # Serviços globais (RealtimeService)
│   └── theme/        # Tokens do Design System (cores, espaçamento, tipografia, responsividade)
├── features/         # Módulos funcionais encapsulados
│   ├── auth/         # Autenticação (Login, Signup, forgot password)
│   ├── calendar/     # Visualização de calendário e eventos
│   ├── dashboard/    # Painel inicial, estatísticas e visão geral
│   ├── databases/    # Banco de dados visuais do tipo Notion
│   ├── focus/        # Fluxo de foco diário (Focus Gateway)
│   ├── gtd/          # Inbox de captura e fluxos de esclarecimento
│   ├── invite/       # Convite para workspaces
│   ├── members/      # Gerenciamento de membros
│   ├── notifications/# Notificações em tempo real
│   ├── pages/        # Notas baseadas em blocos (estilo Notion)
│   ├── projects/     # Gerenciamento de projetos
│   ├── reports/      # Relatórios e estatísticas
│   ├── search/       # Busca global e busca em texto completo
│   ├── settings/     # Configurações de preferência do usuário
│   └── tasks/        # Tarefas, subtarefas, comentários e anexos
└── shared/           # Widgets, helpers e componentes compartilhados
    └── widgets/      # Sidebar, Shell, Command Palette
```

---

## 3. Banco de Dados & Supabase Schema

O banco de dados utiliza PostgreSQL no Supabase. O arquivo [all_migrations_flowspace.sql](file:///c:/aplicativos/gtd/all_migrations_flowspace.sql) e os arquivos em [supabase/migrations/](file:///c:/aplicativos/gtd/supabase/migrations) contêm a estrutura completa:

### Principais Tabelas:
1. **profiles**: Informações de perfil dos usuários.
   - `id` (UUID referenciando `auth.users`), `name`, `avatar_url`, `timezone`, `language`, `theme`.
   - Um trigger automático (`on_auth_user_created`) cria o perfil imediatamente após o cadastro de um usuário.
2. **workspaces**: Áreas de trabalho compartilhadas ou individuais.
   - `id`, `name`, `slug`, `owner_id`.
3. **workspace_members**: Associação de usuários a workspaces.
   - `role` (admin | manager | collaborator | viewer).
4. **areas**: Agrupamentos lógicos (pastas) dentro do workspace.
   - `color`, `icon`, `position`.
5. **projects**: Projetos vinculados a workspaces e/ou áreas.
   - `status` (active | on_hold | completed | cancelled), `priority`, `progress` (0-100), `owner_id`.
6. **tasks**: As tarefas do sistema.
   - `parent_id` (auto-referenciamento para subtarefas), `status` (todo | in_progress | review | done | cancelled), `priority` (urgent | high | medium | low), `due_date`, `actual_hours`, `estimated_hours`, `is_recurring`, `recurrence` (JSONB).
7. **pages** e **blocks**: Documentos Notion-like.
   - `pages` representam os documentos com título, ícone, capa.
   - `blocks` representam os parágrafos, cabeçalhos, checklists, imagens, tabelas e códigos de uma página, estruturados em árvore ou lista ordenada (`parent_id`, `type`, `content` como JSONB, `position`).
8. **calendar_events**: Eventos de calendário vinculados ou não a tarefas.
9. **gtd_inbox** e **gtd_contexts**: Caixa de entrada inicial e contextos (ex: `@casa`, `@computador`) para a metodologia GTD.

### Triggers do Banco:
- `handle_updated_at()`: Atualiza automaticamente a coluna `updated_at` de tabelas importantes.
- `handle_new_user()`: Sincroniza usuários criados em `auth.users` com `public.profiles`.

---

## 4. Gerenciamento de Estado (Riverpod)

O arquivo central que gerencia os estados é o [data_providers.dart](file:///c:/aplicativos/gtd/lib/features/auth/domain/data_providers.dart). Os principais padrões de estado aplicados são:

### Provedores de Acesso & Fluxos Assíncronos:
- **`supabaseProvider`**: Expõe a instância do cliente Supabase.
- **`currentWorkspaceProvider`**: Provedor que expõe o workspace atualmente selecionado.
- **`tasksProvider`**: Provedor assíncrono que carrega e gerencia a lista de tarefas do workspace selecionado utilizando `TasksNotifier`.
- **`projectsProvider`**, **`pagesProvider`**, **`gtdInboxProvider`**, etc.: Seguem a mesma abordagem, estendendo `AsyncNotifier` para lidar com carregamento e mutações de dados no Supabase.

### Sincronização em Tempo Real (Realtime):
O aplicativo atualiza os dados em tempo real automaticamente. Isso é feito pelo [RealtimeService](file:///c:/aplicativos/gtd/lib/core/services/realtime_service.dart), que:
- Escuta canais Postgres do Supabase (`tasks`, `projects`, `pages`, `notifications`).
- Quando ocorre uma alteração no banco de dados, o serviço invalida (`ref.invalidate()`) os respectivos provedores Riverpod, forçando o recarregamento automático dos dados nos widgets.
- Utiliza **Presence** do Supabase para monitorar quais membros do workspace estão online no momento, exibindo pequenos avatares na barra superior (`onlineUsersProvider`).

---

## 5. Roteamento & Gateway de Foco

O roteamento é centralizado no GoRouter ([app_router.dart](file:///c:/aplicativos/gtd/lib/core/routing/app_router.dart)).
- **Proteção de Rota (Redirect)**: Redireciona o usuário para a tela de Login `/auth/login` caso não esteja autenticado.
- **AppShell**: O layout principal do app é fornecido por [AppShell](file:///c:/aplicativos/gtd/lib/shared/widgets/sidebar/app_shell.dart), que inclui a barra lateral (`FlowSidebar`), barra superior (`_FlowTopBar`) e trata da responsividade.
- **Gateway de Foco (`_FocusGatewayPage`)**:
  - Quando o usuário tenta acessar o dashboard (`/`), o gateway verifica se ele já concluiu o foco diário hoje.
  - Se houver tarefas críticas atrasadas ou para hoje, o usuário é redirecionado para `/focus`, onde passa por um fluxo guiado (`FocusStartPage` -> `FocusFlowPage` -> `FocusCompletionPage`) para focar no que importa antes de acessar o resto do painel.

---

## 6. Design System (Aesthetics & Tokens)

A interface do FlowSpace foi desenhada com foco em excelência visual e interações premium. Ela utiliza os tokens localizados em `lib/core/theme`:

- **Cores (`AppColors`)**:
  - Paletas harmoniosas e sem cores puras e genéricas.
  - Tons como `primary` (`#5B6AF3`), `accent` (`#06B6D4`), e fundos dedicados para tema claro (`#F7F8FA`) e escuro (`#0D1117`).
  - Suporta troca dinâmica de tema (`themeModeProvider`), persistido com `SharedPreferences`.
- **Espaçamento e Bordas (`AppSpacing` & `AppRadius`)**:
  - Grid de espaçamento baseado em 4px (ex: `sp16` = 16.0).
  - Cantos arredondados generosos para uma estética moderna (`AppRadius.lg` = 12.0, `AppRadius.xl` = 16.0).
- **Tipografia (`AppTypography`)**:
  - Utiliza `GoogleFonts.inter` para toda a interface.
  - Altura de linha padrão (`height: 1.5`) para excelente legibilidade.
- **Responsividade (`Responsive`)**:
  - Breakpoints definidos em 640px (mobile) e 1024px (tablet).
  - O widget `Responsive` ajuda a renderizar layouts diferentes:
    ```dart
    Responsive.value(context, mobile: mobileWidget, tablet: tabletWidget, desktop: desktopWidget);
    ```
- **Extensões de Contexto (`ThemeExtensions` em `index.dart`)**:
  - Sempre utilize a extensão em vez de chamar tokens estáticos diretamente se precisar se adaptar ao tema escuro:
    - `context.theme`, `context.colors`, `context.isDark`
    - `context.cPrimary`, `context.cSurface`, `context.cBackground`, `context.cBorder`
    - `context.bodyMd`, `context.bodySm`, `context.headingMd`

---

## 7. Diretrizes de Codificação & Extensão

Ao criar novas funcionalidades ou modificar as existentes, siga estas regras rígidas:

1. **Clean Architecture / Separação de Conceitos**:
   - Mantenha a lógica de banco e consultas no repositório/Notifier (geralmente em `data_providers.dart` ou no domínio da feature).
   - Não misture lógica de consulta SQL ou chamadas Supabase diretas dentro dos arquivos de Presentation (Widgets).
2. **Padrão de State Notifiers**:
   - Ao criar uma nova feature que exija dados do Supabase, crie uma classe de dados e um `AsyncNotifier` correspondente.
   - Use `AsyncValue.guard` ao executar mutações para capturar e expor erros de forma limpa.
3. **Estilo de Layout & UI**:
   - Use as extensões do `BuildContext` para cores e textos. Não instancie cores hardcoded como `Colors.blue` ou `Colors.black`.
   - Adicione micro-animações onde aplicável usando `flutter_animate` (ex: `.animate().fade().slideY()`) para garantir o apelo premium.
   - Respeite a responsividade e teste em visualizações Web/Desktop (com barra lateral expansível) e Mobile (com barra de navegação inferior).
4. **Modificações de Banco**:
   - Ao alterar o banco de dados, crie uma nova migration numerada em `supabase/migrations/` e execute-a no Supabase local.
   - Atualize o arquivo consolidado `all_migrations_flowspace.sql` na raiz se necessário.
5. **Realtime Sync**:
   - Ao criar uma nova tabela que precise sincronizar dados em tempo real no app, registre-a no `RealtimeService` (`lib/core/services/realtime_service.dart`) para invalidar o provedor de dados correspondente sempre que ocorrerem mudanças Postgres (`INSERT`, `UPDATE`, `DELETE`).
