SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

-- \restrict ewpOklJ0v8u9KQ2WRowsU1qjxoZbY78CJA9KNhuhdWuhnh8veJn1E5aik09wb6w

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
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."audit_log_entries" ("instance_id", "id", "payload", "created_at", "ip_address") VALUES
	('00000000-0000-0000-0000-000000000000', '3a9d47d8-3ea9-4508-9557-3a3659d3b211', '{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"provider":"email","user_email":"jpfilho@axia.com.br","user_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","user_phone":""}}', '2026-04-15 12:09:40.487301+00', ''),
	('00000000-0000-0000-0000-000000000000', 'c1ad4cae-b618-4fac-9feb-f93ec3e91df1', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 12:18:58.307875+00', ''),
	('00000000-0000-0000-0000-000000000000', 'f55a9259-e10b-4c95-894b-309e4bfba949', '{"action":"user_updated_password","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"user"}', '2026-04-15 12:19:16.909809+00', ''),
	('00000000-0000-0000-0000-000000000000', '5dfb9816-e3a7-45fa-aa3f-342f607b5c36', '{"action":"user_modified","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"user"}', '2026-04-15 12:19:16.91066+00', ''),
	('00000000-0000-0000-0000-000000000000', '3273a062-6a92-4424-8ed6-f1ca4152a9ad', '{"action":"logout","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account"}', '2026-04-15 12:19:23.39108+00', ''),
	('00000000-0000-0000-0000-000000000000', 'ecd074c1-dc43-403c-b2ac-3c879b9d4d42', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 12:19:31.847398+00', ''),
	('00000000-0000-0000-0000-000000000000', 'cdde6128-bddb-46af-9880-3c61622683f1', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 12:31:07.391748+00', ''),
	('00000000-0000-0000-0000-000000000000', '8fb009f7-edcd-45b1-804f-db32cb061593', '{"action":"logout","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account"}', '2026-04-15 12:32:10.553472+00', ''),
	('00000000-0000-0000-0000-000000000000', '2c5cebdb-037e-4fd1-bb82-0df5ea65b839', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 12:32:19.81328+00', ''),
	('00000000-0000-0000-0000-000000000000', '31c5b9d1-e49b-40e8-94b4-badfa890dd22', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 12:51:35.396363+00', ''),
	('00000000-0000-0000-0000-000000000000', '2de622e3-a607-41db-85db-6f6539895abc', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 13:20:16.092642+00', ''),
	('00000000-0000-0000-0000-000000000000', '5aea0580-afaa-4836-a513-ef971273fadc', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 13:25:13.293631+00', ''),
	('00000000-0000-0000-0000-000000000000', '7303217e-99ee-4858-8230-916296a71a20', '{"action":"logout","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account"}', '2026-04-15 13:26:41.35365+00', ''),
	('00000000-0000-0000-0000-000000000000', '9fd63a2e-8510-40f6-9dd4-66109856cc68', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 13:26:48.289608+00', ''),
	('00000000-0000-0000-0000-000000000000', 'aff5b0eb-5497-45ef-ac19-90faed30d387', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 14:45:32.567662+00', ''),
	('00000000-0000-0000-0000-000000000000', '797006c1-b2a2-4a57-b9ad-619b0c091910', '{"action":"user_modified","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"user"}', '2026-04-15 14:45:39.727106+00', ''),
	('00000000-0000-0000-0000-000000000000', 'cae6cc3b-5cde-42e9-8728-25d769d053c1', '{"action":"token_refreshed","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-15 15:44:57.314629+00', ''),
	('00000000-0000-0000-0000-000000000000', 'f3c32940-bac7-4f9a-a166-c57309740ac3', '{"action":"token_revoked","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-15 15:44:57.318503+00', ''),
	('00000000-0000-0000-0000-000000000000', '57f1391b-aef7-4097-a74e-ab75903f696a', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 16:34:27.65959+00', ''),
	('00000000-0000-0000-0000-000000000000', 'a8a672da-9911-43c7-baf0-999a32ce06fd', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 16:37:49.585458+00', ''),
	('00000000-0000-0000-0000-000000000000', '674513c2-2607-4b65-8814-e7176ee4a147', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 16:56:12.147213+00', ''),
	('00000000-0000-0000-0000-000000000000', 'f36320e9-300b-4c67-8b54-bf311a271fff', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 17:00:45.751812+00', ''),
	('00000000-0000-0000-0000-000000000000', '0bc7e25a-7e47-4703-b263-c47d0e061c67', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 17:09:11.66594+00', ''),
	('00000000-0000-0000-0000-000000000000', '325b3194-76c8-4f4e-983f-9f559e6bb184', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 17:55:34.562109+00', ''),
	('00000000-0000-0000-0000-000000000000', 'ffb86f3a-1357-41e2-a10a-50842addb704', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 17:59:11.687866+00', ''),
	('00000000-0000-0000-0000-000000000000', '8c57e6bc-a63a-49cc-ad40-1971fd4cc68c', '{"action":"token_refreshed","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-15 18:58:40.020015+00', ''),
	('00000000-0000-0000-0000-000000000000', '647406f2-324d-46bc-a1de-f88d148abbc1', '{"action":"token_revoked","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-15 18:58:40.026816+00', ''),
	('00000000-0000-0000-0000-000000000000', 'f98bbccf-dbc1-4337-85e0-a4ac7765ce2f', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 19:09:06.482783+00', ''),
	('00000000-0000-0000-0000-000000000000', 'b123fc60-9222-4357-890f-9f1685e0f977', '{"action":"token_refreshed","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-15 20:08:31.675629+00', ''),
	('00000000-0000-0000-0000-000000000000', 'e2fdf333-6912-4c87-8b92-9df6b5a29f5b', '{"action":"token_revoked","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-15 20:08:31.680162+00', ''),
	('00000000-0000-0000-0000-000000000000', '910291dc-7772-43f5-bf8b-c0d55779d120', '{"action":"logout","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account"}', '2026-04-15 20:29:18.261053+00', ''),
	('00000000-0000-0000-0000-000000000000', 'e3c0ecb4-f2f0-49e0-8c90-969ac70d3ec3', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-15 20:34:19.588719+00', ''),
	('00000000-0000-0000-0000-000000000000', '0f376691-36f8-43e9-88bc-12a0b01ae128', '{"action":"token_refreshed","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 12:26:48.391569+00', ''),
	('00000000-0000-0000-0000-000000000000', '865523f4-2bef-4c90-8453-663b8c23ef77', '{"action":"token_revoked","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 12:26:48.417435+00', ''),
	('00000000-0000-0000-0000-000000000000', 'e0f1c1a0-9cf7-4c53-ac28-398ee240529c', '{"action":"token_refreshed","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 13:26:17.471299+00', ''),
	('00000000-0000-0000-0000-000000000000', '67bcea82-df53-411e-ad7a-d4a7e234d85d', '{"action":"token_revoked","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 13:26:17.48266+00', ''),
	('00000000-0000-0000-0000-000000000000', '762d1310-de5c-4844-84f1-7942e60c4ef2', '{"action":"token_refreshed","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 14:25:46.370203+00', ''),
	('00000000-0000-0000-0000-000000000000', '8462649c-9907-4164-8be9-eee50f549f73', '{"action":"token_revoked","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 14:25:46.374325+00', ''),
	('00000000-0000-0000-0000-000000000000', 'e41998c7-cd2f-4c41-806e-c167f24fd9a3', '{"action":"login","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-04-16 14:31:12.5301+00', ''),
	('00000000-0000-0000-0000-000000000000', '13c3e3c9-064c-456b-9187-9a1f3df730b6', '{"action":"token_refreshed","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 15:30:36.79086+00', ''),
	('00000000-0000-0000-0000-000000000000', 'b89217c2-5080-4d8d-b746-d8caa5ace3ea', '{"action":"token_revoked","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 15:30:36.799434+00', ''),
	('00000000-0000-0000-0000-000000000000', 'a626aef1-0d86-43e6-847c-f22ecbbaf10c', '{"action":"token_refreshed","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 16:29:57.053376+00', ''),
	('00000000-0000-0000-0000-000000000000', '548946cf-5af0-4bc5-a8e9-fa032087d689', '{"action":"token_revoked","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 16:29:57.059495+00', ''),
	('00000000-0000-0000-0000-000000000000', '4ff292b9-00b0-4eac-ac39-7e936f7e7bf6', '{"action":"token_refreshed","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 17:29:18.313293+00', ''),
	('00000000-0000-0000-0000-000000000000', '274d74eb-c81c-49c0-b895-57f943931197', '{"action":"token_revoked","actor_id":"c1ca7980-1a8d-44e2-9ba3-493d35a2ced8","actor_username":"jpfilho@axia.com.br","actor_via_sso":false,"log_type":"token"}', '2026-04-16 17:29:18.321884+00', '');


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."users" ("instance_id", "id", "aud", "role", "email", "encrypted_password", "email_confirmed_at", "invited_at", "confirmation_token", "confirmation_sent_at", "recovery_token", "recovery_sent_at", "email_change_token_new", "email_change", "email_change_sent_at", "last_sign_in_at", "raw_app_meta_data", "raw_user_meta_data", "is_super_admin", "created_at", "updated_at", "phone", "phone_confirmed_at", "phone_change", "phone_change_token", "phone_change_sent_at", "email_change_token_current", "email_change_confirm_status", "banned_until", "reauthentication_token", "reauthentication_sent_at", "is_sso_user", "deleted_at", "is_anonymous") VALUES
	('00000000-0000-0000-0000-000000000000', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'authenticated', 'authenticated', 'jpfilho@axia.com.br', '$2a$10$1jJJMq78DCBvybVqT.tZj.TR0oIhR6iNLCAq/5ZaHkNClCZD.oUhS', '2026-04-15 12:09:40.488878+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-04-16 14:31:12.539832+00', '{"provider": "email", "providers": ["email"]}', '{"email_verified": true, "onboarding_done": true}', NULL, '2026-04-15 12:09:40.476173+00', '2026-04-16 17:29:18.332853+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."identities" ("provider_id", "user_id", "identity_data", "provider", "last_sign_in_at", "created_at", "updated_at", "id") VALUES
	('c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '{"sub": "c1ca7980-1a8d-44e2-9ba3-493d35a2ced8", "email": "jpfilho@axia.com.br", "email_verified": false, "phone_verified": false}', 'email', '2026-04-15 12:09:40.485906+00', '2026-04-15 12:09:40.485941+00', '2026-04-15 12:09:40.485941+00', '96a7e429-ae27-4c52-8bbf-b02128d3ecf7');


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."sessions" ("id", "user_id", "created_at", "updated_at", "factor_id", "aal", "not_after", "refreshed_at", "user_agent", "ip", "tag", "oauth_client_id", "refresh_token_hmac_key", "refresh_token_counter", "scopes") VALUES
	('b7300ad3-bb95-48be-b066-aaf7dc998ff9', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 12:19:31.848694+00', '2026-04-15 12:19:31.848694+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('1e690fb4-4a5e-4ce3-bb35-2d563fc46c6e', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 12:32:19.815535+00', '2026-04-15 12:32:19.815535+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('3fad1406-e1ce-4bf9-a6ce-5c7e5181e739', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 12:51:35.408385+00', '2026-04-15 12:51:35.408385+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('d9f193b9-7de8-487b-abd2-a94d2f46541a', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 13:20:16.106167+00', '2026-04-15 13:20:16.106167+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('bfb6a523-181f-441e-9cba-c4bd915378d3', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 13:26:48.291692+00', '2026-04-15 13:26:48.291692+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('068fcbb1-d741-40c4-9248-2506e68d2751', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 14:45:32.589485+00', '2026-04-15 15:44:57.329331+00', NULL, 'aal1', NULL, '2026-04-15 15:44:57.329277', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('d243ca53-ad7f-402f-b1fb-f0deeac29574', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 16:34:27.674287+00', '2026-04-15 16:34:27.674287+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('03374d20-75e4-4b97-8f47-15f907f5039d', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 16:37:49.597897+00', '2026-04-15 16:37:49.597897+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('4a846bf8-c4b9-4eba-af2b-8e256d863aaf', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 16:56:12.155226+00', '2026-04-15 16:56:12.155226+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('e4077667-8ec1-441f-96da-350865628f40', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 17:00:45.765898+00', '2026-04-15 17:00:45.765898+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('8fd3da2a-ab60-4983-8797-0172bdaaea2a', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 17:09:11.677181+00', '2026-04-15 17:09:11.677181+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('1df6da12-3680-4d8c-a498-0358271e0a72', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 17:55:34.57841+00', '2026-04-15 17:55:34.57841+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('079cf460-346b-4661-ba99-6259ac4ec927', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 17:59:11.693044+00', '2026-04-15 18:58:40.04901+00', NULL, 'aal1', NULL, '2026-04-15 18:58:40.048913', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('3e7816c4-2475-415c-8135-d2fb8e301ed2', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-15 20:34:19.594394+00', '2026-04-16 14:25:46.383988+00', NULL, 'aal1', NULL, '2026-04-16 14:25:46.383921', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL),
	('de910d88-400a-4fb1-9b69-fa6d475a6b56', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', '2026-04-16 14:31:12.541179+00', '2026-04-16 17:29:18.33638+00', NULL, 'aal1', NULL, '2026-04-16 17:29:18.335984', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '172.18.0.1', NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."mfa_amr_claims" ("session_id", "created_at", "updated_at", "authentication_method", "id") VALUES
	('b7300ad3-bb95-48be-b066-aaf7dc998ff9', '2026-04-15 12:19:31.855611+00', '2026-04-15 12:19:31.855611+00', 'password', '212a9166-8f7e-42c1-836e-a66df4b70695'),
	('1e690fb4-4a5e-4ce3-bb35-2d563fc46c6e', '2026-04-15 12:32:19.820057+00', '2026-04-15 12:32:19.820057+00', 'password', '8176f17d-4a69-495c-a56d-26bca2278fe7'),
	('3fad1406-e1ce-4bf9-a6ce-5c7e5181e739', '2026-04-15 12:51:35.436326+00', '2026-04-15 12:51:35.436326+00', 'password', '54a3c514-7155-4778-88c9-3ba05b6950f2'),
	('d9f193b9-7de8-487b-abd2-a94d2f46541a', '2026-04-15 13:20:16.1347+00', '2026-04-15 13:20:16.1347+00', 'password', '081bc3e5-5bbc-4f32-a287-f88ac229ec10'),
	('bfb6a523-181f-441e-9cba-c4bd915378d3', '2026-04-15 13:26:48.298572+00', '2026-04-15 13:26:48.298572+00', 'password', 'c1f27e2c-2634-4941-9c8a-85aaac433f0d'),
	('068fcbb1-d741-40c4-9248-2506e68d2751', '2026-04-15 14:45:32.637848+00', '2026-04-15 14:45:32.637848+00', 'password', '0bb70656-f547-46cb-8a07-532fd691b849'),
	('d243ca53-ad7f-402f-b1fb-f0deeac29574', '2026-04-15 16:34:27.699082+00', '2026-04-15 16:34:27.699082+00', 'password', '6777a6a4-546c-400d-900f-5ce873081fac'),
	('03374d20-75e4-4b97-8f47-15f907f5039d', '2026-04-15 16:37:49.628032+00', '2026-04-15 16:37:49.628032+00', 'password', 'ab1a64e3-abc7-4130-907f-5b72ee92465a'),
	('4a846bf8-c4b9-4eba-af2b-8e256d863aaf', '2026-04-15 16:56:12.174965+00', '2026-04-15 16:56:12.174965+00', 'password', 'aeb15881-d20a-4a86-9b25-1dc8a4d32e37'),
	('e4077667-8ec1-441f-96da-350865628f40', '2026-04-15 17:00:45.788555+00', '2026-04-15 17:00:45.788555+00', 'password', '04900aa5-74df-4df6-bfdf-a9df2ea03e19'),
	('8fd3da2a-ab60-4983-8797-0172bdaaea2a', '2026-04-15 17:09:11.699406+00', '2026-04-15 17:09:11.699406+00', 'password', 'f7b3cbec-b009-4c06-9cb8-aa8f77749e79'),
	('1df6da12-3680-4d8c-a498-0358271e0a72', '2026-04-15 17:55:34.610137+00', '2026-04-15 17:55:34.610137+00', 'password', '52e25905-dead-4727-87eb-b19ca5297a4e'),
	('079cf460-346b-4661-ba99-6259ac4ec927', '2026-04-15 17:59:11.703751+00', '2026-04-15 17:59:11.703751+00', 'password', '77dffec7-4b47-49b9-9dc9-a8e3cbdc9a76'),
	('3e7816c4-2475-415c-8135-d2fb8e301ed2', '2026-04-15 20:34:19.614925+00', '2026-04-15 20:34:19.614925+00', 'password', '8f52c354-2410-4d5c-8cc7-482cb6a6dba2'),
	('de910d88-400a-4fb1-9b69-fa6d475a6b56', '2026-04-16 14:31:12.561559+00', '2026-04-16 14:31:12.561559+00', 'password', '970033aa-64b7-44ef-aeac-563b61a7c95f');


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."refresh_tokens" ("instance_id", "id", "token", "user_id", "revoked", "created_at", "updated_at", "parent", "session_id") VALUES
	('00000000-0000-0000-0000-000000000000', 2, 'zded5oktvixk', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 12:19:31.851645+00', '2026-04-15 12:19:31.851645+00', NULL, 'b7300ad3-bb95-48be-b066-aaf7dc998ff9'),
	('00000000-0000-0000-0000-000000000000', 4, 'q57x73ywmd7m', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 12:32:19.817683+00', '2026-04-15 12:32:19.817683+00', NULL, '1e690fb4-4a5e-4ce3-bb35-2d563fc46c6e'),
	('00000000-0000-0000-0000-000000000000', 5, 'mjvmu3ng327j', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 12:51:35.423331+00', '2026-04-15 12:51:35.423331+00', NULL, '3fad1406-e1ce-4bf9-a6ce-5c7e5181e739'),
	('00000000-0000-0000-0000-000000000000', 6, '3ql4mkcid4l3', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 13:20:16.120574+00', '2026-04-15 13:20:16.120574+00', NULL, 'd9f193b9-7de8-487b-abd2-a94d2f46541a'),
	('00000000-0000-0000-0000-000000000000', 40, '7suvsqs3acjp', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 13:26:48.294792+00', '2026-04-15 13:26:48.294792+00', NULL, 'bfb6a523-181f-441e-9cba-c4bd915378d3'),
	('00000000-0000-0000-0000-000000000000', 41, '4s4sv73ql4l4', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', true, '2026-04-15 14:45:32.616031+00', '2026-04-15 15:44:57.318992+00', NULL, '068fcbb1-d741-40c4-9248-2506e68d2751'),
	('00000000-0000-0000-0000-000000000000', 42, 'ghx7hxezbwtn', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 15:44:57.324608+00', '2026-04-15 15:44:57.324608+00', '4s4sv73ql4l4', '068fcbb1-d741-40c4-9248-2506e68d2751'),
	('00000000-0000-0000-0000-000000000000', 43, 'rcktaqdnydjw', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 16:34:27.686637+00', '2026-04-15 16:34:27.686637+00', NULL, 'd243ca53-ad7f-402f-b1fb-f0deeac29574'),
	('00000000-0000-0000-0000-000000000000', 76, 'juz54mp7bpii', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 16:37:49.614495+00', '2026-04-15 16:37:49.614495+00', NULL, '03374d20-75e4-4b97-8f47-15f907f5039d'),
	('00000000-0000-0000-0000-000000000000', 77, 'ky5uedx2kjv3', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 16:56:12.166231+00', '2026-04-15 16:56:12.166231+00', NULL, '4a846bf8-c4b9-4eba-af2b-8e256d863aaf'),
	('00000000-0000-0000-0000-000000000000', 78, 'l3e3skelayaa', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 17:00:45.777611+00', '2026-04-15 17:00:45.777611+00', NULL, 'e4077667-8ec1-441f-96da-350865628f40'),
	('00000000-0000-0000-0000-000000000000', 79, 'ooxuqkkegfzz', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 17:09:11.692071+00', '2026-04-15 17:09:11.692071+00', NULL, '8fd3da2a-ab60-4983-8797-0172bdaaea2a'),
	('00000000-0000-0000-0000-000000000000', 80, 'q5um7n3ttm5b', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 17:55:34.593735+00', '2026-04-15 17:55:34.593735+00', NULL, '1df6da12-3680-4d8c-a498-0358271e0a72'),
	('00000000-0000-0000-0000-000000000000', 81, 'q5emk2vhm7qk', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', true, '2026-04-15 17:59:11.698218+00', '2026-04-15 18:58:40.028091+00', NULL, '079cf460-346b-4661-ba99-6259ac4ec927'),
	('00000000-0000-0000-0000-000000000000', 82, '5o22hlh6na22', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-15 18:58:40.037652+00', '2026-04-15 18:58:40.037652+00', 'q5emk2vhm7qk', '079cf460-346b-4661-ba99-6259ac4ec927'),
	('00000000-0000-0000-0000-000000000000', 85, 'zrawnc4k5azp', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', true, '2026-04-15 20:34:19.60549+00', '2026-04-16 12:26:48.420126+00', NULL, '3e7816c4-2475-415c-8135-d2fb8e301ed2'),
	('00000000-0000-0000-0000-000000000000', 86, 'bbkjschixgh4', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', true, '2026-04-16 12:26:48.434476+00', '2026-04-16 13:26:17.484029+00', 'zrawnc4k5azp', '3e7816c4-2475-415c-8135-d2fb8e301ed2'),
	('00000000-0000-0000-0000-000000000000', 87, 'rd43zdd2ocnn', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', true, '2026-04-16 13:26:17.490373+00', '2026-04-16 14:25:46.375557+00', 'bbkjschixgh4', '3e7816c4-2475-415c-8135-d2fb8e301ed2'),
	('00000000-0000-0000-0000-000000000000', 88, 'j4fj4ftyw2vj', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-16 14:25:46.379081+00', '2026-04-16 14:25:46.379081+00', 'rd43zdd2ocnn', '3e7816c4-2475-415c-8135-d2fb8e301ed2'),
	('00000000-0000-0000-0000-000000000000', 89, '34co3lmwyjn2', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', true, '2026-04-16 14:31:12.553347+00', '2026-04-16 15:30:36.800007+00', NULL, 'de910d88-400a-4fb1-9b69-fa6d475a6b56'),
	('00000000-0000-0000-0000-000000000000', 90, 'o6fbq3q4ulnn', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', true, '2026-04-16 15:30:36.804635+00', '2026-04-16 16:29:57.060692+00', '34co3lmwyjn2', 'de910d88-400a-4fb1-9b69-fa6d475a6b56'),
	('00000000-0000-0000-0000-000000000000', 91, 'objmbyxgs4xw', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', true, '2026-04-16 16:29:57.064502+00', '2026-04-16 17:29:18.322628+00', 'o6fbq3q4ulnn', 'de910d88-400a-4fb1-9b69-fa6d475a6b56'),
	('00000000-0000-0000-0000-000000000000', 92, '7ryv7smzlien', 'c1ca7980-1a8d-44e2-9ba3-493d35a2ced8', false, '2026-04-16 17:29:18.326577+00', '2026-04-16 17:29:18.326577+00', 'objmbyxgs4xw', 'de910d88-400a-4fb1-9b69-fa6d475a6b56');


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('"auth"."refresh_tokens_id_seq"', 92, true);


--
-- PostgreSQL database dump complete
--

-- \unrestrict ewpOklJ0v8u9KQ2WRowsU1qjxoZbY78CJA9KNhuhdWuhnh8veJn1E5aik09wb6w

RESET ALL;
