--
-- PostgreSQL database dump
--

\restrict 9mO0dNTTqZFJzO0ndcj8vh32NB9ACS4ulLJZd17SnylqIRezXp0Xh6u5t87dtdo

-- Dumped from database version 17.7
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: cs; Type: SCHEMA; Schema: -; Owner: admin
--

CREATE SCHEMA cs;


ALTER SCHEMA cs OWNER TO admin;

--
-- Name: ctg; Type: SCHEMA; Schema: -; Owner: admin
--

CREATE SCHEMA ctg;


ALTER SCHEMA ctg OWNER TO admin;

--
-- Name: pay; Type: SCHEMA; Schema: -; Owner: admin
--

CREATE SCHEMA pay;


ALTER SCHEMA pay OWNER TO admin;

--
-- Name: ship; Type: SCHEMA; Schema: -; Owner: admin
--

CREATE SCHEMA ship;


ALTER SCHEMA ship OWNER TO admin;

--
-- Name: convert_usd_to_cop(); Type: FUNCTION; Schema: ctg; Owner: admin
--

CREATE FUNCTION ctg.convert_usd_to_cop() RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        rows_affected INT;
    BEGIN
        UPDATE ctg.products
        SET cop_price = (usd_price * 3750);

        GET DIAGNOSTICS rows_affected = ROW_COUNT;

    RETURN 'Rows affected: '||rows_affected;   
END;
$$;


ALTER FUNCTION ctg.convert_usd_to_cop() OWNER TO admin;

--
-- Name: update_category_id(integer, integer); Type: FUNCTION; Schema: ctg; Owner: admin
--

CREATE FUNCTION ctg.update_category_id(product_id integer, cat_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        rows_affected INTEGER;
    BEGIN
        UPDATE ctg.products
        SET category_id = cat_id
        WHERE id = product_id;

        GET DIAGNOSTICS rows_affected = ROW_COUNT;

        RETURN 'Rows affected: '|| rows_affected;
    END;
$$;


ALTER FUNCTION ctg.update_category_id(product_id integer, cat_id integer) OWNER TO admin;

--
-- Name: update_price_cop_af_ins(); Type: FUNCTION; Schema: ctg; Owner: admin
--

CREATE FUNCTION ctg.update_price_cop_af_ins() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN

    UPDATE ctg.products
    SET cop_price = (usd_price * 3750)
    WHERE id = NEW.id;

    RETURN NEW;

END;
$$;


ALTER FUNCTION ctg.update_price_cop_af_ins() OWNER TO admin;

--
-- Name: update_total_orders(); Type: FUNCTION; Schema: pay; Owner: admin
--

CREATE FUNCTION pay.update_total_orders() RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        rows_affected INT;
    BEGIN
        UPDATE pay.orders ord
        SET total = sub.total
        FROM (
            SELECT
                T1.order_id,
                SUM(T2.cop_price * T1.quantity) AS total
            FROM pay.order_items T1
            INNER JOIN ctg.products T2
                ON T1.product_id = T2.id
            GROUP BY 1
        ) sub
        WHERE ord.id = sub.order_id;

        GET DIAGNOSTICS rows_affected = ROW_COUNT;

    RETURN 'Rows affected: '||rows_affected;   
END;
$$;


ALTER FUNCTION pay.update_total_orders() OWNER TO admin;

--
-- Name: trg_set_updated_at(); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.trg_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_set_updated_at() OWNER TO admin;

--
-- Name: trg_link_shipment_to_order(); Type: FUNCTION; Schema: ship; Owner: admin
--

CREATE FUNCTION ship.trg_link_shipment_to_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validar que la orden existe
    IF NOT EXISTS (
        SELECT 1 FROM pay.orders WHERE id = NEW.order_id
    ) THEN
        RAISE EXCEPTION 'La orden % no existe en pay.orders', NEW.order_id;
    END IF;

    -- Validar que la orden no tenga ya un envio asignado
    IF EXISTS (
        SELECT 1 FROM ship.shipment_orders
        WHERE  order_id = NEW.order_id
        AND    id       != NEW.id
    ) THEN
        RAISE EXCEPTION 'La orden % ya tiene un envio asignado', NEW.order_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION ship.trg_link_shipment_to_order() OWNER TO admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addresses; Type: TABLE; Schema: cs; Owner: admin
--

CREATE TABLE cs.addresses (
    id integer NOT NULL,
    customer_id_number character varying(50) NOT NULL,
    municipality_code character varying(10) NOT NULL,
    street character varying(255) NOT NULL,
    detail character varying(255),
    postal_code character varying(20),
    additional_comments character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE cs.addresses OWNER TO admin;

--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: cs; Owner: admin
--

CREATE SEQUENCE cs.addresses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cs.addresses_id_seq OWNER TO admin;

--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: cs; Owner: admin
--

ALTER SEQUENCE cs.addresses_id_seq OWNED BY cs.addresses.id;


--
-- Name: customers; Type: TABLE; Schema: cs; Owner: admin
--

CREATE TABLE cs.customers (
    id integer NOT NULL,
    id_number character varying(50) NOT NULL,
    birth_date date NOT NULL,
    phone_number character varying(20) NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_birth_date CHECK ((birth_date < CURRENT_DATE))
);


ALTER TABLE cs.customers OWNER TO admin;

--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: cs; Owner: admin
--

CREATE SEQUENCE cs.customers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cs.customers_id_seq OWNER TO admin;

--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: cs; Owner: admin
--

ALTER SEQUENCE cs.customers_id_seq OWNED BY cs.customers.id;


--
-- Name: categories; Type: TABLE; Schema: ctg; Owner: admin
--

CREATE TABLE ctg.categories (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE ctg.categories OWNER TO admin;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: ctg; Owner: admin
--

CREATE SEQUENCE ctg.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE ctg.categories_id_seq OWNER TO admin;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: ctg; Owner: admin
--

ALTER SEQUENCE ctg.categories_id_seq OWNED BY ctg.categories.id;


--
-- Name: departments; Type: TABLE; Schema: ctg; Owner: admin
--

CREATE TABLE ctg.departments (
    code character varying(10) NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE ctg.departments OWNER TO admin;

--
-- Name: municipalities; Type: TABLE; Schema: ctg; Owner: admin
--

CREATE TABLE ctg.municipalities (
    code character varying(10) NOT NULL,
    name character varying(100) NOT NULL,
    department_code character varying(10) NOT NULL
);


ALTER TABLE ctg.municipalities OWNER TO admin;

--
-- Name: payment_methods; Type: TABLE; Schema: ctg; Owner: admin
--

CREATE TABLE ctg.payment_methods (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    create_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE ctg.payment_methods OWNER TO admin;

--
-- Name: payment_methods_id_seq; Type: SEQUENCE; Schema: ctg; Owner: admin
--

CREATE SEQUENCE ctg.payment_methods_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE ctg.payment_methods_id_seq OWNER TO admin;

--
-- Name: payment_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: ctg; Owner: admin
--

ALTER SEQUENCE ctg.payment_methods_id_seq OWNED BY ctg.payment_methods.id;


--
-- Name: products; Type: TABLE; Schema: ctg; Owner: admin
--

CREATE TABLE ctg.products (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    usd_price numeric(10,2) NOT NULL,
    cop_price numeric(10,2),
    category_id integer
);


ALTER TABLE ctg.products OWNER TO admin;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: ctg; Owner: admin
--

CREATE SEQUENCE ctg.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE ctg.products_id_seq OWNER TO admin;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: ctg; Owner: admin
--

ALTER SEQUENCE ctg.products_id_seq OWNED BY ctg.products.id;


--
-- Name: order_items; Type: TABLE; Schema: pay; Owner: admin
--

CREATE TABLE pay.order_items (
    id integer NOT NULL,
    order_id character varying(25) NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    CONSTRAINT chk_quantity CHECK ((quantity > 0))
);


ALTER TABLE pay.order_items OWNER TO admin;

--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: pay; Owner: admin
--

CREATE SEQUENCE pay.order_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pay.order_items_id_seq OWNER TO admin;

--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: pay; Owner: admin
--

ALTER SEQUENCE pay.order_items_id_seq OWNED BY pay.order_items.id;


--
-- Name: orders; Type: TABLE; Schema: pay; Owner: admin
--

CREATE TABLE pay.orders (
    id character varying(25) NOT NULL,
    customer_id_number character varying(50) NOT NULL,
    order_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    total numeric(10,2),
    payment_method_id integer NOT NULL
);


ALTER TABLE pay.orders OWNER TO admin;

--
-- Name: ship_company; Type: TABLE; Schema: ship; Owner: admin
--

CREATE TABLE ship.ship_company (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    nit character varying(20),
    address character varying(100) NOT NULL,
    phone character varying(20),
    email character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE ship.ship_company OWNER TO admin;

--
-- Name: ship_company_id_seq; Type: SEQUENCE; Schema: ship; Owner: admin
--

CREATE SEQUENCE ship.ship_company_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE ship.ship_company_id_seq OWNER TO admin;

--
-- Name: ship_company_id_seq; Type: SEQUENCE OWNED BY; Schema: ship; Owner: admin
--

ALTER SEQUENCE ship.ship_company_id_seq OWNED BY ship.ship_company.id;


--
-- Name: shipment_orders; Type: TABLE; Schema: ship; Owner: admin
--

CREATE TABLE ship.shipment_orders (
    id character varying(25) NOT NULL,
    ship_company_id integer NOT NULL,
    order_id character varying(25) NOT NULL,
    tracking_code character varying(100),
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    shipped_at timestamp without time zone,
    delivered_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_shipment_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'in_transit'::character varying, 'delivered'::character varying])::text[])))
);


ALTER TABLE ship.shipment_orders OWNER TO admin;

--
-- Name: addresses id; Type: DEFAULT; Schema: cs; Owner: admin
--

ALTER TABLE ONLY cs.addresses ALTER COLUMN id SET DEFAULT nextval('cs.addresses_id_seq'::regclass);


--
-- Name: customers id; Type: DEFAULT; Schema: cs; Owner: admin
--

ALTER TABLE ONLY cs.customers ALTER COLUMN id SET DEFAULT nextval('cs.customers_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.categories ALTER COLUMN id SET DEFAULT nextval('ctg.categories_id_seq'::regclass);


--
-- Name: payment_methods id; Type: DEFAULT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.payment_methods ALTER COLUMN id SET DEFAULT nextval('ctg.payment_methods_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.products ALTER COLUMN id SET DEFAULT nextval('ctg.products_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: pay; Owner: admin
--

ALTER TABLE ONLY pay.order_items ALTER COLUMN id SET DEFAULT nextval('pay.order_items_id_seq'::regclass);


--
-- Name: ship_company id; Type: DEFAULT; Schema: ship; Owner: admin
--

ALTER TABLE ONLY ship.ship_company ALTER COLUMN id SET DEFAULT nextval('ship.ship_company_id_seq'::regclass);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: cs; Owner: admin
--

ALTER TABLE ONLY cs.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: customers customers_email_key; Type: CONSTRAINT; Schema: cs; Owner: admin
--

ALTER TABLE ONLY cs.customers
    ADD CONSTRAINT customers_email_key UNIQUE (email);


--
-- Name: customers customers_id_number_key; Type: CONSTRAINT; Schema: cs; Owner: admin
--

ALTER TABLE ONLY cs.customers
    ADD CONSTRAINT customers_id_number_key UNIQUE (id_number);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: cs; Owner: admin
--

ALTER TABLE ONLY cs.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (code);


--
-- Name: municipalities municipalities_pkey; Type: CONSTRAINT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.municipalities
    ADD CONSTRAINT municipalities_pkey PRIMARY KEY (code);


--
-- Name: payment_methods payment_methods_name_key; Type: CONSTRAINT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.payment_methods
    ADD CONSTRAINT payment_methods_name_key UNIQUE (name);


--
-- Name: payment_methods payment_methods_pkey; Type: CONSTRAINT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.payment_methods
    ADD CONSTRAINT payment_methods_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: pay; Owner: admin
--

ALTER TABLE ONLY pay.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: pay; Owner: admin
--

ALTER TABLE ONLY pay.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: ship_company ship_company_name_key; Type: CONSTRAINT; Schema: ship; Owner: admin
--

ALTER TABLE ONLY ship.ship_company
    ADD CONSTRAINT ship_company_name_key UNIQUE (name);


--
-- Name: ship_company ship_company_nit_key; Type: CONSTRAINT; Schema: ship; Owner: admin
--

ALTER TABLE ONLY ship.ship_company
    ADD CONSTRAINT ship_company_nit_key UNIQUE (nit);


--
-- Name: ship_company ship_company_pkey; Type: CONSTRAINT; Schema: ship; Owner: admin
--

ALTER TABLE ONLY ship.ship_company
    ADD CONSTRAINT ship_company_pkey PRIMARY KEY (id);


--
-- Name: shipment_orders shipment_orders_pkey; Type: CONSTRAINT; Schema: ship; Owner: admin
--

ALTER TABLE ONLY ship.shipment_orders
    ADD CONSTRAINT shipment_orders_pkey PRIMARY KEY (id);


--
-- Name: shipment_orders shipment_orders_tracking_code_key; Type: CONSTRAINT; Schema: ship; Owner: admin
--

ALTER TABLE ONLY ship.shipment_orders
    ADD CONSTRAINT shipment_orders_tracking_code_key UNIQUE (tracking_code);


--
-- Name: addresses tg_addresses_updated_at; Type: TRIGGER; Schema: cs; Owner: admin
--

CREATE TRIGGER tg_addresses_updated_at BEFORE UPDATE ON cs.addresses FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: products tgg_update_price_cop_af_ins; Type: TRIGGER; Schema: ctg; Owner: admin
--

CREATE TRIGGER tgg_update_price_cop_af_ins AFTER INSERT ON ctg.products FOR EACH ROW EXECUTE FUNCTION ctg.update_price_cop_af_ins();


--
-- Name: shipment_orders tg_link_shipment_to_order; Type: TRIGGER; Schema: ship; Owner: admin
--

CREATE TRIGGER tg_link_shipment_to_order BEFORE INSERT ON ship.shipment_orders FOR EACH ROW EXECUTE FUNCTION ship.trg_link_shipment_to_order();


--
-- Name: shipment_orders tg_shipment_orders_updated_at; Type: TRIGGER; Schema: ship; Owner: admin
--

CREATE TRIGGER tg_shipment_orders_updated_at BEFORE UPDATE ON ship.shipment_orders FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: addresses fk_addr_customer; Type: FK CONSTRAINT; Schema: cs; Owner: admin
--

ALTER TABLE ONLY cs.addresses
    ADD CONSTRAINT fk_addr_customer FOREIGN KEY (customer_id_number) REFERENCES cs.customers(id_number);


--
-- Name: addresses fk_addr_municipality; Type: FK CONSTRAINT; Schema: cs; Owner: admin
--

ALTER TABLE ONLY cs.addresses
    ADD CONSTRAINT fk_addr_municipality FOREIGN KEY (municipality_code) REFERENCES ctg.municipalities(code);


--
-- Name: products fk_categories_id; Type: FK CONSTRAINT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.products
    ADD CONSTRAINT fk_categories_id FOREIGN KEY (category_id) REFERENCES ctg.categories(id);


--
-- Name: municipalities fk_department_code; Type: FK CONSTRAINT; Schema: ctg; Owner: admin
--

ALTER TABLE ONLY ctg.municipalities
    ADD CONSTRAINT fk_department_code FOREIGN KEY (department_code) REFERENCES ctg.departments(code);


--
-- Name: order_items fk_order_orders; Type: FK CONSTRAINT; Schema: pay; Owner: admin
--

ALTER TABLE ONLY pay.order_items
    ADD CONSTRAINT fk_order_orders FOREIGN KEY (order_id) REFERENCES pay.orders(id);


--
-- Name: order_items fk_order_products; Type: FK CONSTRAINT; Schema: pay; Owner: admin
--

ALTER TABLE ONLY pay.order_items
    ADD CONSTRAINT fk_order_products FOREIGN KEY (product_id) REFERENCES ctg.products(id);


--
-- Name: orders fk_orders_customer; Type: FK CONSTRAINT; Schema: pay; Owner: admin
--

ALTER TABLE ONLY pay.orders
    ADD CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id_number) REFERENCES cs.customers(id_number);


--
-- Name: orders fk_payments_method; Type: FK CONSTRAINT; Schema: pay; Owner: admin
--

ALTER TABLE ONLY pay.orders
    ADD CONSTRAINT fk_payments_method FOREIGN KEY (payment_method_id) REFERENCES ctg.payment_methods(id);


--
-- Name: shipment_orders fk_order_shipments; Type: FK CONSTRAINT; Schema: ship; Owner: admin
--

ALTER TABLE ONLY ship.shipment_orders
    ADD CONSTRAINT fk_order_shipments FOREIGN KEY (order_id) REFERENCES pay.orders(id);


--
-- Name: shipment_orders fk_shipment_company; Type: FK CONSTRAINT; Schema: ship; Owner: admin
--

ALTER TABLE ONLY ship.shipment_orders
    ADD CONSTRAINT fk_shipment_company FOREIGN KEY (ship_company_id) REFERENCES ship.ship_company(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 9mO0dNTTqZFJzO0ndcj8vh32NB9ACS4ulLJZd17SnylqIRezXp0Xh6u5t87dtdo

