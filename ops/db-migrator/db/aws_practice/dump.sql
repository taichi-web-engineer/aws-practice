--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3 (Debian 15.3-1.pgdg120+1)
-- Dumped by pg_dump version 15.3 (Debian 15.3-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: aws_practice; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE aws_practice WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE aws_practice OWNER TO postgres;

\connect aws_practice

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: aws_test; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.aws_test (
    id integer NOT NULL,
    test_text character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.aws_test OWNER TO postgres;

--
-- Name: aws_test_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.aws_test_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.aws_test_id_seq OWNER TO postgres;

--
-- Name: aws_test_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.aws_test_id_seq OWNED BY public.aws_test.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- Name: aws_test id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aws_test ALTER COLUMN id SET DEFAULT nextval('public.aws_test_id_seq'::regclass);


--
-- Data for Name: aws_test; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.aws_test (id, test_text, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (version, dirty) FROM stdin;
20250118003441	f
\.


--
-- Name: aws_test_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.aws_test_id_seq', 1, false);


--
-- Name: aws_test aws_test_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aws_test
    ADD CONSTRAINT aws_test_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: DATABASE aws_practice; Type: ACL; Schema: -; Owner: postgres
--

GRANT CONNECT ON DATABASE aws_practice TO aws_practice;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO aws_practice;


--
-- Name: TABLE aws_test; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.aws_test TO aws_practice;


--
-- Name: SEQUENCE aws_test_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.aws_test_id_seq TO aws_practice;


--
-- Name: TABLE schema_migrations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.schema_migrations TO aws_practice;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT USAGE ON SEQUENCES  TO aws_practice;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO aws_practice;


--
-- PostgreSQL database dump complete
--

