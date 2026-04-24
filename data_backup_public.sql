SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

-- \restrict c2QfEQfcKhmBgWakJwDI9RSZFOTw17XJZDPIoMRm5vS5ut69VaeCZfs7jWZui5L

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
-- SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."profiles" ("id", "name", "avatar_url", "bio", "timezone", "language", "theme", "created_at", "updated_at") VALUES
	('c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'jpfilho', NULL, '', 'America/Sao_Paulo', 'pt-BR', 'system', '2026-04-15 12:09:40.475686+00', '2026-04-15 12:09:40.475686+00');


--
-- Data for Name: workspaces; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."workspaces" ("id", "name", "slug", "description", "logo_url", "owner_id", "created_at", "updated_at") VALUES
	('3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Profissional - AXIA', 'jpfilho-eb9f8e51', NULL, NULL, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 12:09:40.475686+00', '2026-04-15 12:09:40.475686+00');


--
-- Data for Name: activities; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: areas; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."projects" ("id", "workspace_id", "area_id", "name", "description", "status", "priority", "start_date", "end_date", "color", "cover_url", "progress", "owner_id", "created_by", "created_at", "updated_at") VALUES
	('6d0115b1-67d3-4ed4-a435-9e2206005ad9', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', NULL, 'TaskFlow', 'Plataforma de Gestão de Atividades', 'in_progress', 'high', NULL, NULL, '#5B6AF3', NULL, 0, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 12:33:11.46388+00', '2026-04-15 12:33:26.587443+00');


--
-- Data for Name: pages; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."pages" ("id", "workspace_id", "parent_id", "project_id", "title", "icon", "cover_url", "is_favorite", "position", "created_by", "last_edited_by", "created_at", "updated_at") VALUES
	('feca4926-9714-4845-9546-418f3c1bc2bd', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', NULL, NULL, 'Nova Página
', NULL, NULL, false, 0, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 20:36:07.30154+00', '2026-04-15 20:36:21.317634+00');


--
-- Data for Name: blocks; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."blocks" ("id", "page_id", "parent_id", "type", "content", "position", "created_at", "updated_at") VALUES
	('3749480b-395a-4a00-8d6e-6d6b8d143ca4', 'feca4926-9714-4845-9546-418f3c1bc2bd', NULL, 'paragraph', '{"text": ""}', 0, '2026-04-15 20:36:20.704456+00', '2026-04-15 20:36:20.704456+00');


--
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."tasks" ("id", "workspace_id", "project_id", "parent_id", "title", "description", "status", "priority", "due_date", "start_date", "estimated_hours", "actual_hours", "assignee_id", "created_by", "position", "is_recurring", "recurrence", "completed_at", "created_at", "updated_at", "is_someday", "recurrence_type", "recurrence_interval", "recurrence_ends_at") VALUES
	('509f1cb8-8c14-4800-bad1-d050bad50c1b', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', NULL, NULL, 'Verificar Pendencias de NA Ver BI Carlos Sivini', NULL, 'todo', 'medium', NULL, NULL, NULL, NULL, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 0, false, NULL, NULL, '2026-04-15 20:38:51.313615+00', '2026-04-15 20:38:51.313615+00', false, 'none', 1, NULL),
	('126db8e1-6db4-41b3-bf61-2bb0314dcb4b', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', NULL, NULL, 'Preparar reunião da operação para o dia 15/04', NULL, 'done', 'urgent', '2026-04-15 00:00:00+00', NULL, NULL, NULL, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 0, false, NULL, NULL, '2026-04-15 16:57:09.268527+00', '2026-04-15 17:59:30.860235+00', false, 'none', 1, NULL),
	('2ce580f3-04ae-4f6c-a957-58fa3648ce9e', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', NULL, NULL, 'Fazer aprovações das prestações no concur', NULL, 'done', 'low', NULL, NULL, NULL, NULL, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 0, false, NULL, NULL, '2026-04-15 16:58:28.975263+00', '2026-04-15 19:15:09.459537+00', false, 'daily', 1, NULL),
	('d27d007c-50bd-4f02-b27f-75736cfda262', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', NULL, NULL, 'Fazer prestação de contas da viagem para Recife (Treinamento de Segurança)', NULL, 'review', 'medium', '2026-04-16 00:00:00+00', NULL, NULL, NULL, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 0, false, NULL, NULL, '2026-04-15 13:07:11.300093+00', '2026-04-15 19:43:21.065927+00', false, 'none', 1, NULL),
	('53e9124a-c560-4447-9b61-49ea0d12197e', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', NULL, NULL, 'https://training.knowbe4.com/ fazer teste do programaca de conscientização', 'AXIA Energia
            
            
Olá Jose Filho,
             
A cultura de segurança da informação começa com a consciência de cada um de nós. A Pesquisa de Cultura em Segurança da Informação já está disponível. Esta pesquisa será realizada por meio da plataforma KnowBe4, nossa parceira em treinamentos e conscientização de segurança da informação.          

Por que sua participação é importante?
Porque entender como os colaboradores enxergam os riscos digitais é essencial para aprimorar nossas estratégias de proteção e fortalecer a Cultura de Segurança na AXIA Energia.
            
            Sua atividade na plataforma:
            - Avaliação de conhecimento sobre conscientização em segurança(SAPA).
             
            Acesse através do link: training.knowbe4.com
                 

A avaliação estará disponivel até 15/05/2026.

Sua participação é essencial para que possamos evoluir juntos em direção a um ambiente mais seguro, consciente e resiliente.

 

 Atenciosamente,
 

Logo AXIA Energia	
Segurança da Informação
conscientizacao.si@axia.com.br
www.axia.com.br
Eletrobras agora é AXIA Energia.', 'todo', 'low', '2026-05-14 00:00:00+00', NULL, NULL, NULL, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 0, false, NULL, NULL, '2026-04-15 19:51:38.696656+00', '2026-04-15 19:52:44.290174+00', false, 'none', 1, NULL),
	('2fb68034-af07-4e50-8326-daf18effef2b', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', NULL, NULL, 'Operação indevida 32T3-6', 'Prezados,

Conforme NM 11517923 , em 30/01/24,  ocorreu a operação indevida da 32T3-6,  na qual a seccionadora fechou de forma autônoma sem nenhuma ordem de comando associada . Por segurança foram desligados os quicklegs AC e DC .

A Equipe NEPTRFET através da 00005461/26H (25 a 27/03/26)  verificou a conformidade referente dos circuitos de controle/automação, mas detectou a presença de potencial anormal proveniente do armário da 32T3-6. A informação foi compartilhada com a equipe NEPTRFMT presente na ocasião.



Dessa forma, solicitamos à operação que a NM seja direcionada a equipe NEPTRFMT. 

Atenciosamente,', 'todo', 'medium', NULL, NULL, NULL, NULL, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 0, false, NULL, NULL, '2026-04-15 19:53:37.823603+00', '2026-04-15 19:53:46.152089+00', false, 'none', 1, NULL),
	('31b2eb3c-43ab-43d2-9a46-e2d7b74addba', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', NULL, NULL, 'Convocação Regional Fortaleza – Treinamento e Implantação de Planejamento de Risco Operacional', 'De: Emmanuel Moura Reis Santos <emreis@axia.com.br>
Enviada em: quarta-feira, 15 de abril de 2026 15:37
Para: Lincoln Da Silva Barbosa <lincolnb@axia.com.br>; Jose Pereira Da Silva Filho <jpfilho@axia.com.br>; Iuri Margels Dos Santos Araujo <iurimsa@axia.com.br>; Temostenes Nunes Tavares <tnunest@axia.com.br>; Herbert De Azevedo Pereira <hpereira@axia.com.br>; Italo Madeira Portela Veloso <italov@axia.com.br>; Luis Laiglon Pinto Martins <laiglon@axia.com.br>
Cc: Geordan Figueroa Feitosa Soares <geordanf@axia.com.br>; Aldiana Nascimento Gomes Medeiros <aldiann@axia.com.br>; Marcio Azevedo Dos Santos <marcio.d.santos@axia.com.br>; Almir Ribeiro Russiano <aribeiro@axia.com.br>; Rafael Pinheiro Alves <rafaelpa@axia.com.br>; Antonio Aloildo Silva De Sousa <antonio.sousa@axia.com.br>
Assunto: Convocação Regional Fortaleza – Treinamento e Implantação de Planejamento de Risco Operacional

 

Caros @Lincoln Da Silva Barbosa @Jose Pereira Da Silva Filho @Iuri Margels Dos Santos Araujo @Temostenes Nunes Tavares @Herbert De Azevedo Pereira @Italo Madeira Portela Veloso @Luis Laiglon Pinto Martins

 

Solicitamos a gentileza de indicarem 2 (dois) multiplicadores de cada divisão: Manutenção (Subestação e Linhas), Proteção, Operação e Civil para participar do Treinamento de Planejamento de Risco Operacional - PRO. Os multiplicadores irão posteriormente repassar o conhecimento para as equipes de manutenção e operação.

 

O objetivo do treinamento é apresentar o processo integrado de planejamento e gestão de riscos em SST e reforçar os procedimentos de segurança, controles operacionais e boas práticas necessárias para garantir que as medidas de controle em campo estejam ativas, visando manter a integridade física dos profissionais, a conformidade com os requisitos internos e legais. 

 

📌 Informações do Treinamento:

Período: 05 a 08/05
Horário: 08:30h
Local: Auditório Espaço de Convivência em Fortaleza
Público-alvo: Equipes de manutenção, operação e demais áreas envolvidas em intervenções técnicas
 

@Lincoln Da Silva Barbosa

 

Peço que me envie a programação de intervenções do mês de maio, pois precisaremos agendar o acompanhamento de uma intervenção em 06/05 (Subestação) a tarde e outra no dia 07/05 (Linhas de Transmissão) para a implementação em campo da Avaliação de Risco - AR. Para o treinamento será necessário que o(s) PEX das atividades previstas para as intervenções de campo que serão acompanhadas estejam disponíveis.

 

Solicitamos também a reserva do auditório nas datas informadas.

 

A participação dos multiplicadores é fundamental para garantir a segurança nas nossas atividades e a continuidade das operações com excelência.

 

Em caso de dúvidas, estou à disposição.', 'todo', 'urgent', '2026-04-16 00:00:00+00', NULL, NULL, NULL, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 0, false, NULL, NULL, '2026-04-15 20:14:58.544607+00', '2026-04-15 20:15:13.607798+00', false, 'none', 1, NULL),
	('356f5ef6-67ac-4802-892c-aa20f269609f', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', '6d0115b1-67d3-4ed4-a435-9e2206005ad9', NULL, 'Inserir scroll horizontal na tela de atividaes gantt', 'Os usuários náo conseguem rolar a tela horizontalmente. Verificar demais Telas do projeto', 'todo', 'low', NULL, NULL, NULL, NULL, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 0, false, NULL, NULL, '2026-04-16 14:32:12.314516+00', '2026-04-16 14:33:26.272486+00', false, 'none', 1, NULL),
	('d37c7cd7-cdf9-40f1-9d5c-b774b1edf128', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', '6d0115b1-67d3-4ed4-a435-9e2206005ad9', NULL, 'Corrigir o click de Notas/Ordens/ATs/SIs na tabela para abrir o formulário', NULL, 'in_progress', 'urgent', '2026-04-16 00:00:00+00', NULL, NULL, NULL, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 0, false, NULL, NULL, '2026-04-15 12:34:07.223184+00', '2026-04-16 14:34:18.299703+00', false, 'none', 1, NULL),
	('bfcf6576-d8ee-4db9-bd34-958f9645c210', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', NULL, NULL, 'NCT Piripiri nível 2 , 01Y1', '
Adriano Ribeiro Fernandes

​CHF-Equipe Tempo Real COOS;​
Jose Pereira Da Silva Filho;​+3 outros
​
​
​
​CHF-OPI_PRI​
Prezados,
após inspeção feita hoje , observamos que a nct do 01Y1 evoluiu para nível 2 com data de correção de até 72 horas.,
VCO= 188,75A











Eletrobras agora é AXIA Energia



Adriano Fernandes



Man Eletromecânica Teresina T Nordeste



adrianor@axia.com.br 

www.axia.com.br



Eletrobras agora é AXIA Energia.', 'in_progress', 'urgent', '2026-04-16 00:00:00+00', NULL, NULL, NULL, 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 0, false, NULL, NULL, '2026-04-15 20:03:15.962129+00', '2026-04-16 14:34:35.518199+00', false, 'none', 1, NULL);


--
-- Data for Name: calendar_events; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: databases; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: db_columns; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: db_rows; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: gtd_contexts; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: gtd_inbox; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."gtd_inbox" ("id", "user_id", "workspace_id", "content", "is_processed", "processed_at", "task_id", "created_at") VALUES
	('3976efbf-660d-45ba-b668-9870f5c57df8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Fazer prestação de contas da viagem para Recife (Treinamento de Segurança)', true, '2026-04-15 10:07:11.097+00', NULL, '2026-04-15 12:59:41.250691+00'),
	('65537533-d3db-4a7a-8bec-dae7b2585b7e', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Verificar Planilha de Trafos enviada por Italo do Departamento', false, NULL, NULL, '2026-04-15 13:30:07.94058+00'),
	('ae8fdb24-fa82-4ab4-9c52-e3a8b6ed33ce', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Verificar 32L3/32T3 os atalhos de tela (quadrado interno e externo)', false, NULL, NULL, '2026-04-15 14:16:46.231565+00'),
	('8fafb557-0bf7-4639-bb54-c9deb0b7f4d8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Preparar reunião da operação para o dia 15/04', true, '2026-04-15 13:57:09.128+00', NULL, '2026-04-15 16:43:53.058688+00'),
	('4e658194-5d17-4607-8549-8a7b35e9e688', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Fazer aprovações das prestações no concur', true, '2026-04-15 13:58:28.844+00', NULL, '2026-04-15 16:58:25.828925+00'),
	('d11ce182-9673-45cd-b73f-1cda1ec9270a', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Verificar as ações de obras no sgo', false, NULL, NULL, '2026-04-15 18:04:44.793992+00'),
	('6b48907d-fc69-4d5b-845e-8b1253ff1490', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Verificar cronograma das obras da siemens TSA (Seccionadoras e Disjuntores)', false, NULL, NULL, '2026-04-15 18:05:15.68146+00'),
	('3d9c452f-ea6f-4728-ad0c-e74e2193891b', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Verificar se ordens PROJ/AT estão conforme as R&M', false, NULL, NULL, '2026-04-15 18:32:27.21071+00'),
	('316d2c9a-bcba-4c9d-a642-04e37057ee07', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Acomponhar o planejamento dos simulados de PIC e ELM', false, NULL, NULL, '2026-04-15 18:48:20.223337+00'),
	('9cad19e5-772d-4883-a8ef-9bee1221c109', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Corrigir feriados do TaskFlow', false, NULL, NULL, '2026-04-15 19:32:30.431092+00'),
	('a4f5b06e-fdb4-4a48-a4e1-74664356279d', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'https://training.knowbe4.com/ fazer teste do programaca de conscientização', true, '2026-04-15 16:51:38.553+00', NULL, '2026-04-15 19:51:35.573271+00'),
	('edfdb7fd-b943-4049-bbcb-173abaf0759b', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Operação indevida 32T3-6', true, '2026-04-15 16:53:37.699+00', NULL, '2026-04-15 19:53:23.105251+00'),
	('405df3aa-5f04-4742-bf7f-f6f633c17df8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Aprovar Ponto da Equipe', false, NULL, NULL, '2026-04-15 19:54:23.411604+00'),
	('fb66c7f2-3923-4681-b5d8-9a6a3cfe6be4', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'TESTE DE MATERIAL ISOLANTE (ABRIL) - Linhas de Transmissão - SGM', false, NULL, NULL, '2026-04-15 19:56:48.791367+00'),
	('b9150c96-0ef3-4e4f-933e-8b248e708c0f', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'PRAZO: 30/04/2025 - ROL DE SUBSÍDIOS PARA DEFESA - MARCOS PATRICIO MARTINS DA SILVA X CHESF - Processo: 0000521-91.2026.5.22.0002', false, NULL, NULL, '2026-04-15 20:00:10.925991+00'),
	('913f99e3-6807-4c72-bba2-2e1777c2131a', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'NCT Piripiri nível 2 , 01Y1', true, '2026-04-15 17:03:15.81+00', NULL, '2026-04-15 20:03:13.781779+00'),
	('bb2bade2-2805-435b-aa3f-9e3296c7314b', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Verificar Pendencias de NA Ver BI Carlos Sivini', true, '2026-04-15 17:38:51.17+00', NULL, '2026-04-15 20:02:38.75636+00'),
	('587745bd-db2d-45ba-97b1-37e916f5cc0a', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'Inserir scroll horizontal na tela de atividaes gantt', true, '2026-04-16 11:32:12.154+00', NULL, '2026-04-15 21:16:19.971153+00');


--
-- Data for Name: labels; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."labels" ("id", "workspace_id", "name", "color", "created_at") VALUES
	('9cf9462e-a8e3-42d5-a1d6-5dbe5ef6ce77', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'bug', '#EF4444', '2026-04-15 12:34:30.245438+00');


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: project_members; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: task_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: task_comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."task_comments" ("id", "task_id", "author_id", "content", "created_at", "updated_at") VALUES
	('723edcaa-92e5-43a7-93bf-f59fd4011b76', 'd27d007c-50bd-4f02-b27f-75736cfda262', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'Repassado para Illana os comprovantes', '2026-04-15 19:43:11.355599+00', '2026-04-15 19:43:11.355599+00'),
	('a12dbb15-2a89-4f1d-a2b0-59c3a99a0413', '53e9124a-c560-4447-9b61-49ea0d12197e', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'Aguardando o reset de senha', '2026-04-15 19:52:58.646583+00', '2026-04-15 19:52:58.646583+00'),
	('7792fefb-a974-4d40-9f61-3cc131598a2f', '2fb68034-af07-4e50-8326-daf18effef2b', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'Prezado Pereira,
Boa noite.
Encaminho a nota de manutenção nº 11517923 (30/01/2026), referente à chave 32T3-6/TSA. Informo que, na data de hoje, a chave voltou a fechar de forma indevida às 18:42.
Às 20:03, o COOS solicitou a abertura da chave, bem como o desligamento do AC e DC da mesma.
Atenciosamente,






Eletrobras agora é AXIA Energia



Rodrigo Albuquerque



Engenheiro Eletricista - Centro de Operação Reg 1 Chesf



rodrigo.albuquerque@axia.com.br 

www.axia.com.br



Eletrobras agora é AXIA Energia.', '2026-04-15 19:55:37.383564+00', '2026-04-15 19:55:37.383564+00'),
	('1ab712f0-6a86-44ac-9218-d7a0079e38ff', '31b2eb3c-43ab-43d2-9a46-e2d7b74addba', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'Verificar com Gilson e Leonardo', '2026-04-15 20:15:38.221737+00', '2026-04-15 20:15:38.221737+00'),
	('5e1a0f30-b90c-40e9-a520-4e07173abdb3', 'bfcf6576-d8ee-4db9-bd34-958f9645c210', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'Aguardando feedback da Equatorial', '2026-04-15 20:37:11.559296+00', '2026-04-15 20:37:11.559296+00');


--
-- Data for Name: task_labels; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."task_labels" ("task_id", "label_id") VALUES
	('d37c7cd7-cdf9-40f1-9d5c-b774b1edf128', '9cf9462e-a8e3-42d5-a1d6-5dbe5ef6ce77');


--
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: workspace_invites; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: workspace_members; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."workspace_members" ("id", "workspace_id", "user_id", "role", "joined_at") VALUES
	('05c972ee-433f-4639-8006-23e49400583e', '3b61366b-a4cc-4c59-93f1-e42b9d4113d2', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'admin', '2026-04-15 12:09:40.475686+00');


--
-- PostgreSQL database dump complete
--

-- \unrestrict c2QfEQfcKhmBgWakJwDI9RSZFOTw17XJZDPIoMRm5vS5ut69VaeCZfs7jWZui5L

RESET ALL;
