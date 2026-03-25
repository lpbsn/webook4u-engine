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
-- Name: enforce_bookings_client_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_bookings_client_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  service_client_id bigint;
  enseigne_client_id bigint;
BEGIN
  SELECT client_id INTO service_client_id
  FROM services
  WHERE id = NEW.service_id;

  IF service_client_id IS NOT NULL AND service_client_id <> NEW.client_id THEN
    RAISE EXCEPTION 'bookings.client_id must match services.client_id'
      USING ERRCODE = '23514';
  END IF;

  SELECT client_id INTO enseigne_client_id
  FROM enseignes
  WHERE id = NEW.enseigne_id;

  IF enseigne_client_id IS NOT NULL AND enseigne_client_id <> NEW.client_id THEN
    RAISE EXCEPTION 'bookings.client_id must match enseignes.client_id'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bookings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookings (
    id bigint NOT NULL,
    client_id bigint NOT NULL,
    service_id bigint NOT NULL,
    customer_email character varying,
    booking_start_time timestamp(6) without time zone NOT NULL,
    booking_end_time timestamp(6) without time zone NOT NULL,
    booking_status character varying NOT NULL,
    booking_expires_at timestamp(6) without time zone,
    stripe_session_id character varying,
    stripe_payment_intent character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    customer_first_name character varying,
    customer_last_name character varying,
    confirmation_token character varying,
    enseigne_id bigint NOT NULL,
    pending_access_token character varying,
    CONSTRAINT bookings_confirmed_requires_confirmation_token CHECK ((((booking_status)::text <> 'confirmed'::text) OR (NULLIF(btrim((confirmation_token)::text), ''::text) IS NOT NULL))),
    CONSTRAINT bookings_confirmed_requires_customer_email CHECK ((((booking_status)::text <> 'confirmed'::text) OR (NULLIF(btrim((customer_email)::text), ''::text) IS NOT NULL))),
    CONSTRAINT bookings_confirmed_requires_customer_first_name CHECK ((((booking_status)::text <> 'confirmed'::text) OR (NULLIF(btrim((customer_first_name)::text), ''::text) IS NOT NULL))),
    CONSTRAINT bookings_confirmed_requires_customer_last_name CHECK ((((booking_status)::text <> 'confirmed'::text) OR (NULLIF(btrim((customer_last_name)::text), ''::text) IS NOT NULL))),
    CONSTRAINT bookings_end_time_after_start_time CHECK ((booking_end_time > booking_start_time)),
    CONSTRAINT bookings_pending_requires_booking_expires_at CHECK ((((booking_status)::text <> 'pending'::text) OR (booking_expires_at IS NOT NULL))),
    CONSTRAINT bookings_pending_requires_pending_access_token CHECK ((((booking_status)::text <> 'pending'::text) OR (NULLIF(btrim((pending_access_token)::text), ''::text) IS NOT NULL))),
    CONSTRAINT bookings_status_allowed_values CHECK (((booking_status)::text = ANY ((ARRAY['pending'::character varying, 'confirmed'::character varying, 'failed'::character varying])::text[])))
);


--
-- Name: bookings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bookings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bookings_id_seq OWNED BY public.bookings.id;


--
-- Name: client_opening_hours; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_opening_hours (
    id bigint NOT NULL,
    client_id bigint NOT NULL,
    day_of_week integer NOT NULL,
    opens_at time without time zone NOT NULL,
    closes_at time without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: client_opening_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_opening_hours_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_opening_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_opening_hours_id_seq OWNED BY public.client_opening_hours.id;


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id bigint NOT NULL,
    name character varying,
    slug character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clients_id_seq OWNED BY public.clients.id;


--
-- Name: enseigne_opening_hours; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enseigne_opening_hours (
    id bigint NOT NULL,
    enseigne_id bigint NOT NULL,
    day_of_week integer NOT NULL,
    opens_at time without time zone NOT NULL,
    closes_at time without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: enseigne_opening_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enseigne_opening_hours_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enseigne_opening_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enseigne_opening_hours_id_seq OWNED BY public.enseigne_opening_hours.id;


--
-- Name: enseignes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enseignes (
    id bigint NOT NULL,
    client_id bigint NOT NULL,
    name character varying NOT NULL,
    full_address character varying,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: enseignes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enseignes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enseignes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enseignes_id_seq OWNED BY public.enseignes.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.services (
    id bigint NOT NULL,
    client_id bigint NOT NULL,
    name character varying NOT NULL,
    duration_minutes integer NOT NULL,
    price_cents integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT services_duration_minutes_positive CHECK ((duration_minutes > 0)),
    CONSTRAINT services_price_cents_non_negative CHECK ((price_cents >= 0))
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- Name: bookings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings ALTER COLUMN id SET DEFAULT nextval('public.bookings_id_seq'::regclass);


--
-- Name: client_opening_hours id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_opening_hours ALTER COLUMN id SET DEFAULT nextval('public.client_opening_hours_id_seq'::regclass);


--
-- Name: clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients ALTER COLUMN id SET DEFAULT nextval('public.clients_id_seq'::regclass);


--
-- Name: enseigne_opening_hours id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enseigne_opening_hours ALTER COLUMN id SET DEFAULT nextval('public.enseigne_opening_hours_id_seq'::regclass);


--
-- Name: enseignes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enseignes ALTER COLUMN id SET DEFAULT nextval('public.enseignes_id_seq'::regclass);


--
-- Name: services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: client_opening_hours client_opening_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_opening_hours
    ADD CONSTRAINT client_opening_hours_pkey PRIMARY KEY (id);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: enseigne_opening_hours enseigne_opening_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enseigne_opening_hours
    ADD CONSTRAINT enseigne_opening_hours_pkey PRIMARY KEY (id);


--
-- Name: enseignes enseignes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enseignes
    ADD CONSTRAINT enseignes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: index_bookings_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookings_on_client_id ON public.bookings USING btree (client_id);


--
-- Name: index_bookings_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bookings_on_confirmation_token ON public.bookings USING btree (confirmation_token);


--
-- Name: index_bookings_on_enseigne_and_start_time_confirmed; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bookings_on_enseigne_and_start_time_confirmed ON public.bookings USING btree (enseigne_id, booking_start_time) WHERE ((booking_status)::text = 'confirmed'::text);


--
-- Name: index_bookings_on_enseigne_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookings_on_enseigne_id ON public.bookings USING btree (enseigne_id);


--
-- Name: index_bookings_on_pending_access_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bookings_on_pending_access_token ON public.bookings USING btree (pending_access_token);


--
-- Name: index_bookings_on_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookings_on_service_id ON public.bookings USING btree (service_id);


--
-- Name: index_client_opening_hours_on_client_and_day; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_opening_hours_on_client_and_day ON public.client_opening_hours USING btree (client_id, day_of_week);


--
-- Name: index_client_opening_hours_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_opening_hours_on_client_id ON public.client_opening_hours USING btree (client_id);


--
-- Name: index_clients_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_clients_on_slug ON public.clients USING btree (slug);


--
-- Name: index_enseigne_opening_hours_on_enseigne_and_day; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enseigne_opening_hours_on_enseigne_and_day ON public.enseigne_opening_hours USING btree (enseigne_id, day_of_week);


--
-- Name: index_enseigne_opening_hours_on_enseigne_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enseigne_opening_hours_on_enseigne_id ON public.enseigne_opening_hours USING btree (enseigne_id);


--
-- Name: index_enseignes_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enseignes_on_client_id ON public.enseignes USING btree (client_id);


--
-- Name: index_services_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_services_on_client_id ON public.services USING btree (client_id);


--
-- Name: bookings bookings_client_consistency_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER bookings_client_consistency_trigger BEFORE INSERT OR UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.enforce_bookings_client_consistency();


--
-- Name: bookings fk_rails_1707d5de0d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT fk_rails_1707d5de0d FOREIGN KEY (service_id) REFERENCES public.services(id);


--
-- Name: services fk_rails_1b9e100e65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT fk_rails_1b9e100e65 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: bookings fk_rails_2c503ea743; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT fk_rails_2c503ea743 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: enseigne_opening_hours fk_rails_5afe3b8c85; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enseigne_opening_hours
    ADD CONSTRAINT fk_rails_5afe3b8c85 FOREIGN KEY (enseigne_id) REFERENCES public.enseignes(id);


--
-- Name: client_opening_hours fk_rails_8e88be3c44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_opening_hours
    ADD CONSTRAINT fk_rails_8e88be3c44 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: enseignes fk_rails_cc63fed4c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enseignes
    ADD CONSTRAINT fk_rails_cc63fed4c0 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: bookings fk_rails_cf615b8bba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT fk_rails_cf615b8bba FOREIGN KEY (enseigne_id) REFERENCES public.enseignes(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260325130000'),
('20260325123000'),
('20260325113000'),
('20260325103000'),
('20260325090000'),
('20260325080000'),
('20260325073349'),
('20260325000003'),
('20260325000002'),
('20260325000001'),
('20260324000002'),
('20260324000001'),
('20260319000002'),
('20260319000001'),
('20260318091500'),
('20260318043805'),
('20260316073931'),
('20260315110003'),
('20260315105010'),
('20260315104615'),
('20260315102949'),
('20260315102534'),
('20260314081835'),
('20260314080003'),
('20260314075954');
