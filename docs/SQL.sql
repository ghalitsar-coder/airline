-- =============================================================================
-- AIRLINE MANAGEMENT SYSTEM - PostgreSQL Database Architecture
-- Version: 1.1.0 (Revised)
-- Standard: Enterprise / Industry Best Practice
-- Total Tables: 39 (38 + 1 aircraft_config_assignments)
-- =============================================================================
--
-- Changelog dari v1.0:
--  1. Tambah FK countries.currency_code → currencies (Cacat #1)
--  2. Trigger validasi terminal vs gate di flights (Cacat #2)
--  3. Normalisasi konfigurasi: hilangkan config_id dari seats, tambah
--     tabel aircraft_config_assignments (Cacat #3)
--  4. Exclusion constraint anti-duplikat harga aktif di flight_prices (Cacat #4)
--  5. Tambah FK agent_id dan approved_by yang hilang (Cacat #5)
--  6. Batas partisi menggunakan TIMESTAMPTZ eksplisit UTC (Cacat #6)
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- =============================================================================
-- SCHEMA DEFINITIONS
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS airline;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS finance;

SET search_path = airline, finance, audit, public;

-- =============================================================================
-- ENUMS
-- =============================================================================
CREATE TYPE airline.gender_type AS ENUM ('MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY');
CREATE TYPE airline.flight_status AS ENUM ('SCHEDULED', 'BOARDING', 'DEPARTED', 'IN_AIR', 'LANDED', 'ARRIVED', 'DELAYED', 'CANCELLED', 'DIVERTED');
CREATE TYPE airline.booking_status AS ENUM ('PENDING', 'CONFIRMED', 'TICKETED', 'CHECKED_IN', 'BOARDED', 'COMPLETED', 'CANCELLED', 'REFUNDED', 'NO_SHOW');
CREATE TYPE airline.seat_class AS ENUM ('ECONOMY', 'PREMIUM_ECONOMY', 'BUSINESS', 'FIRST');
CREATE TYPE airline.seat_status AS ENUM ('AVAILABLE', 'OCCUPIED', 'BLOCKED', 'RESERVED');
CREATE TYPE airline.payment_status AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'REFUNDED', 'PARTIALLY_REFUNDED', 'CHARGEBACK');
CREATE TYPE airline.payment_method AS ENUM ('CREDIT_CARD', 'DEBIT_CARD', 'BANK_TRANSFER', 'DIGITAL_WALLET', 'POINTS', 'VOUCHER', 'CASH');
CREATE TYPE airline.document_type AS ENUM ('PASSPORT', 'NATIONAL_ID', 'DRIVING_LICENSE', 'VISA');
CREATE TYPE airline.baggage_status AS ENUM ('CHECKED_IN', 'LOADED', 'IN_TRANSIT', 'ARRIVED', 'COLLECTED', 'LOST', 'DAMAGED', 'DELAYED');
CREATE TYPE airline.crew_role AS ENUM ('CAPTAIN', 'FIRST_OFFICER', 'SECOND_OFFICER', 'PURSER', 'SENIOR_CABIN_CREW', 'CABIN_CREW', 'GROUND_STAFF');
CREATE TYPE airline.maintenance_type AS ENUM ('ROUTINE_A', 'ROUTINE_B', 'ROUTINE_C', 'ROUTINE_D', 'UNSCHEDULED', 'AOG');
CREATE TYPE airline.maintenance_status AS ENUM ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'DEFERRED', 'CANCELLED');
CREATE TYPE airline.loyalty_tier AS ENUM ('BASIC', 'SILVER', 'GOLD', 'PLATINUM', 'DIAMOND');
CREATE TYPE airline.notification_channel AS ENUM ('EMAIL', 'SMS', 'PUSH', 'WHATSAPP');
CREATE TYPE airline.runway_status AS ENUM ('ACTIVE', 'MAINTENANCE', 'CLOSED');
CREATE TYPE airline.aircraft_status AS ENUM ('ACTIVE', 'MAINTENANCE', 'GROUNDED', 'RETIRED', 'STORED');
CREATE TYPE audit.action_type AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'SELECT');


-- =============================================================================
-- TABLE 1: countries
-- =============================================================================
CREATE TABLE airline.countries (
    country_id        CHAR(2)       NOT NULL,
    country_name      VARCHAR(100)  NOT NULL,
    country_code_3    CHAR(3)       NOT NULL,
    nationality       VARCHAR(100),
    continent         VARCHAR(50),
    phone_code        VARCHAR(10),
    currency_code     CHAR(3),
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_countries PRIMARY KEY (country_id),
    CONSTRAINT uq_countries_code3 UNIQUE (country_code_3),
    -- FIX #1: Tambah FK ke currencies
    CONSTRAINT fk_countries_currency FOREIGN KEY (currency_code) REFERENCES finance.currencies(currency_code)
);

COMMENT ON TABLE airline.countries IS 'Master data for countries (ISO 3166-1)';

-- =============================================================================
-- TABLE 2: currencies
-- =============================================================================
CREATE TABLE finance.currencies (
    currency_code     CHAR(3)       NOT NULL,
    currency_name     VARCHAR(100)  NOT NULL,
    symbol            VARCHAR(10)   NOT NULL,
    decimal_places    SMALLINT      NOT NULL DEFAULT 2,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_currencies PRIMARY KEY (currency_code)
);

COMMENT ON TABLE finance.currencies IS 'ISO 4217 currency master';

-- =============================================================================
-- TABLE 3: airports
-- =============================================================================
CREATE TABLE airline.airports (
    airport_id        UUID          NOT NULL DEFAULT uuid_generate_v4(),
    iata_code         CHAR(3)       NOT NULL,
    icao_code         CHAR(4),
    airport_name      VARCHAR(200)  NOT NULL,
    city              VARCHAR(100)  NOT NULL,
    state_province    VARCHAR(100),
    country_id        CHAR(2)       NOT NULL,
    latitude          DECIMAL(10,7) NOT NULL,
    longitude         DECIMAL(10,7) NOT NULL,
    elevation_ft      INT,
    timezone          VARCHAR(50)   NOT NULL,
    utc_offset        DECIMAL(5,2)  NOT NULL,
    dst_offset        DECIMAL(5,2),
    is_international  BOOLEAN       NOT NULL DEFAULT TRUE,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_airports PRIMARY KEY (airport_id),
    CONSTRAINT uq_airports_iata UNIQUE (iata_code),
    CONSTRAINT uq_airports_icao UNIQUE (icao_code),
    CONSTRAINT fk_airports_country FOREIGN KEY (country_id) REFERENCES airline.countries(country_id)
);

CREATE INDEX idx_airports_iata ON airline.airports(iata_code);
CREATE INDEX idx_airports_country ON airline.airports(country_id);

-- =============================================================================
-- TABLE 4: terminals
-- =============================================================================
CREATE TABLE airline.terminals (
    terminal_id       UUID          NOT NULL DEFAULT uuid_generate_v4(),
    airport_id        UUID          NOT NULL,
    terminal_code     VARCHAR(10)   NOT NULL,
    terminal_name     VARCHAR(100),
    is_international  BOOLEAN       NOT NULL DEFAULT FALSE,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_terminals PRIMARY KEY (terminal_id),
    CONSTRAINT uq_terminals UNIQUE (airport_id, terminal_code),
    CONSTRAINT fk_terminals_airport FOREIGN KEY (airport_id) REFERENCES airline.airports(airport_id)
);

-- =============================================================================
-- TABLE 5: gates
-- =============================================================================
CREATE TABLE airline.gates (
    gate_id           UUID          NOT NULL DEFAULT uuid_generate_v4(),
    terminal_id       UUID          NOT NULL,
    gate_code         VARCHAR(10)   NOT NULL,
    gate_type         VARCHAR(50),
    capacity          INT,
    has_jetbridge     BOOLEAN       NOT NULL DEFAULT TRUE,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_gates PRIMARY KEY (gate_id),
    CONSTRAINT uq_gates UNIQUE (terminal_id, gate_code),
    CONSTRAINT fk_gates_terminal FOREIGN KEY (terminal_id) REFERENCES airline.terminals(terminal_id)
);

-- =============================================================================
-- TABLE 6: runways
-- =============================================================================
CREATE TABLE airline.runways (
    runway_id         UUID          NOT NULL DEFAULT uuid_generate_v4(),
    airport_id        UUID          NOT NULL,
    runway_identifier VARCHAR(10)   NOT NULL,
    length_ft         INT           NOT NULL,
    width_ft          INT           NOT NULL,
    surface_type      VARCHAR(50),
    ils_equipped      BOOLEAN       NOT NULL DEFAULT FALSE,
    status            airline.runway_status NOT NULL DEFAULT 'ACTIVE',
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_runways PRIMARY KEY (runway_id),
    CONSTRAINT uq_runways UNIQUE (airport_id, runway_identifier),
    CONSTRAINT fk_runways_airport FOREIGN KEY (airport_id) REFERENCES airline.airports(airport_id)
);

-- =============================================================================
-- TABLE 7: aircraft_types
-- =============================================================================
CREATE TABLE airline.aircraft_types (
    aircraft_type_id  UUID          NOT NULL DEFAULT uuid_generate_v4(),
    iata_type_code    VARCHAR(10)   NOT NULL,
    icao_type_code    VARCHAR(10),
    manufacturer      VARCHAR(100)  NOT NULL,
    model             VARCHAR(100)  NOT NULL,
    variant           VARCHAR(50),
    max_seats         INT           NOT NULL,
    range_km          INT,
    max_fuel_kg       DECIMAL(10,2),
    wingspan_m        DECIMAL(6,2),
    length_m          DECIMAL(6,2),
    max_cargo_kg      DECIMAL(10,2),
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_aircraft_types PRIMARY KEY (aircraft_type_id),
    CONSTRAINT uq_aircraft_type_iata UNIQUE (iata_type_code)
);

-- =============================================================================
-- TABLE 8: aircrafts
-- =============================================================================
CREATE TABLE airline.aircrafts (
    aircraft_id           UUID          NOT NULL DEFAULT uuid_generate_v4(),
    aircraft_type_id      UUID          NOT NULL,
    registration_number   VARCHAR(20)   NOT NULL,
    msn                   VARCHAR(50),
    airline_fleet_number  VARCHAR(20),
    delivery_date         DATE,
    manufacture_date      DATE,
    total_flight_hours    DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_cycles          INT           NOT NULL DEFAULT 0,
    base_airport_id       UUID,
    status                airline.aircraft_status NOT NULL DEFAULT 'ACTIVE',
    notes                 TEXT,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_aircrafts PRIMARY KEY (aircraft_id),
    CONSTRAINT uq_aircrafts_reg UNIQUE (registration_number),
    CONSTRAINT fk_aircrafts_type FOREIGN KEY (aircraft_type_id) REFERENCES airline.aircraft_types(aircraft_type_id),
    CONSTRAINT fk_aircrafts_base_airport FOREIGN KEY (base_airport_id) REFERENCES airline.airports(airport_id)
);

CREATE INDEX idx_aircrafts_type ON airline.aircrafts(aircraft_type_id);
CREATE INDEX idx_aircrafts_status ON airline.aircrafts(status);

-- =============================================================================
-- TABLE 9: cabin_configurations
-- =============================================================================
CREATE TABLE airline.cabin_configurations (
    config_id         UUID          NOT NULL DEFAULT uuid_generate_v4(),
    aircraft_type_id  UUID          NOT NULL,
    config_name       VARCHAR(100)  NOT NULL,
    seat_class        airline.seat_class NOT NULL,
    total_seats       INT           NOT NULL,
    rows_start        INT           NOT NULL,
    rows_end          INT           NOT NULL,
    seats_per_row     INT           NOT NULL,
    seat_pitch_inches DECIMAL(5,2),
    seat_width_inches DECIMAL(5,2),
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_cabin_configurations PRIMARY KEY (config_id),
    CONSTRAINT fk_cabin_config_aircraft_type FOREIGN KEY (aircraft_type_id) REFERENCES airline.aircraft_types(aircraft_type_id)
);

-- =============================================================================
-- TABLE 9b: aircraft_config_assignments (FIX #3)
-- =============================================================================
CREATE TABLE airline.aircraft_config_assignments (
    assignment_id     UUID          NOT NULL DEFAULT uuid_generate_v4(),
    aircraft_id       UUID          NOT NULL,
    config_id         UUID          NOT NULL,
    effective_from    TIMESTAMPTZ   NOT NULL,
    effective_until   TIMESTAMPTZ,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_aircraft_config_assignments PRIMARY KEY (assignment_id),
    CONSTRAINT uq_aircraft_config_effective UNIQUE (aircraft_id, effective_from),
    CONSTRAINT fk_ac_config_assign_aircraft FOREIGN KEY (aircraft_id) REFERENCES airline.aircrafts(aircraft_id),
    CONSTRAINT fk_ac_config_assign_config FOREIGN KEY (config_id) REFERENCES airline.cabin_configurations(config_id),
    CONSTRAINT chk_ac_config_effective CHECK (effective_until IS NULL OR effective_until > effective_from)
);

COMMENT ON TABLE airline.aircraft_config_assignments IS
'Penugasan konfigurasi kabin ke pesawat tertentu, memungkinkan perubahan layout dari waktu ke waktu';

-- =============================================================================
-- TABLE 10: seats (FIX #3: tanpa config_id, hanya aircraft_id)
-- =============================================================================
CREATE TABLE airline.seats (
    seat_id           UUID          NOT NULL DEFAULT uuid_generate_v4(),
    aircraft_id       UUID          NOT NULL,
    seat_number       VARCHAR(5)    NOT NULL,
    seat_row          INT           NOT NULL,
    seat_letter       CHAR(1)       NOT NULL,
    seat_class        airline.seat_class NOT NULL,
    is_window         BOOLEAN       NOT NULL DEFAULT FALSE,
    is_aisle          BOOLEAN       NOT NULL DEFAULT FALSE,
    is_middle         BOOLEAN       NOT NULL DEFAULT FALSE,
    is_exit_row       BOOLEAN       NOT NULL DEFAULT FALSE,
    is_bassinet       BOOLEAN       NOT NULL DEFAULT FALSE,
    is_recline_limited BOOLEAN      NOT NULL DEFAULT FALSE,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_seats PRIMARY KEY (seat_id),
    CONSTRAINT uq_seats UNIQUE (aircraft_id, seat_number),
    CONSTRAINT fk_seats_aircraft FOREIGN KEY (aircraft_id) REFERENCES airline.aircrafts(aircraft_id)
);

CREATE INDEX idx_seats_aircraft ON airline.seats(aircraft_id);
CREATE INDEX idx_seats_class ON airline.seats(seat_class);

COMMENT ON TABLE airline.seats IS 'Individual seat inventory per aircraft. seat_class disimpan denormalisasi dan harus disinkronkan dengan aircraft_config_assignments aktif.';

-- =============================================================================
-- TABLE 11: routes
-- =============================================================================
CREATE TABLE airline.routes (
    route_id              UUID          NOT NULL DEFAULT uuid_generate_v4(),
    origin_airport_id     UUID          NOT NULL,
    destination_airport_id UUID         NOT NULL,
    distance_km           DECIMAL(8,2)  NOT NULL,
    flight_duration_min   INT           NOT NULL,
    is_international      BOOLEAN       NOT NULL DEFAULT FALSE,
    is_active             BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_routes PRIMARY KEY (route_id),
    CONSTRAINT uq_routes UNIQUE (origin_airport_id, destination_airport_id),
    CONSTRAINT fk_routes_origin FOREIGN KEY (origin_airport_id) REFERENCES airline.airports(airport_id),
    CONSTRAINT fk_routes_destination FOREIGN KEY (destination_airport_id) REFERENCES airline.airports(airport_id),
    CONSTRAINT chk_routes_different_airports CHECK (origin_airport_id <> destination_airport_id)
);

-- =============================================================================
-- TABLE 12: flights
-- =============================================================================
CREATE TABLE airline.flights (
    flight_id                 UUID              NOT NULL DEFAULT uuid_generate_v4(),
    flight_number             VARCHAR(10)       NOT NULL,
    route_id                  UUID              NOT NULL,
    aircraft_id               UUID,
    scheduled_departure       TIMESTAMPTZ       NOT NULL,
    scheduled_arrival         TIMESTAMPTZ       NOT NULL,
    actual_departure          TIMESTAMPTZ,
    actual_arrival            TIMESTAMPTZ,
    estimated_departure       TIMESTAMPTZ,
    estimated_arrival         TIMESTAMPTZ,
    departure_gate_id         UUID,
    arrival_gate_id           UUID,
    departure_terminal_id     UUID,
    arrival_terminal_id       UUID,
    status                    airline.flight_status NOT NULL DEFAULT 'SCHEDULED',
    delay_reason              VARCHAR(500),
    codeshare_flights         VARCHAR(100)[],
    total_pax_capacity        INT,
    booked_pax                INT              NOT NULL DEFAULT 0,
    checked_in_pax            INT              NOT NULL DEFAULT 0,
    boarded_pax               INT              NOT NULL DEFAULT 0,
    fuel_loaded_kg            DECIMAL(10,2),
    cargo_weight_kg           DECIMAL(10,2),
    is_cancelled              BOOLEAN          NOT NULL DEFAULT FALSE,
    cancellation_reason       TEXT,
    created_at                TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_flights PRIMARY KEY (flight_id),
    CONSTRAINT fk_flights_route FOREIGN KEY (route_id) REFERENCES airline.routes(route_id),
    CONSTRAINT fk_flights_aircraft FOREIGN KEY (aircraft_id) REFERENCES airline.aircrafts(aircraft_id),
    CONSTRAINT fk_flights_dep_gate FOREIGN KEY (departure_gate_id) REFERENCES airline.gates(gate_id),
    CONSTRAINT fk_flights_arr_gate FOREIGN KEY (arrival_gate_id) REFERENCES airline.gates(gate_id),
    CONSTRAINT chk_flights_arrival_after_departure CHECK (scheduled_arrival > scheduled_departure)
);

CREATE INDEX idx_flights_number ON airline.flights(flight_number);
CREATE INDEX idx_flights_route ON airline.flights(route_id);
CREATE INDEX idx_flights_status ON airline.flights(status);
CREATE INDEX idx_flights_scheduled_dep ON airline.flights(scheduled_departure);
CREATE INDEX idx_flights_aircraft ON airline.flights(aircraft_id);

-- FIX #2: Fungsi validasi terminal vs gate
CREATE OR REPLACE FUNCTION airline.validate_flight_terminal_gate()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.departure_gate_id IS NOT NULL AND NEW.departure_terminal_id IS NOT NULL THEN
        IF (SELECT terminal_id FROM airline.gates WHERE gate_id = NEW.departure_gate_id) <> NEW.departure_terminal_id THEN
            RAISE EXCEPTION 'departure_terminal_id (%) tidak cocok dengan terminal gate departure_gate_id (%)',
                NEW.departure_terminal_id, NEW.departure_gate_id;
        END IF;
    END IF;
    IF NEW.arrival_gate_id IS NOT NULL AND NEW.arrival_terminal_id IS NOT NULL THEN
        IF (SELECT terminal_id FROM airline.gates WHERE gate_id = NEW.arrival_gate_id) <> NEW.arrival_terminal_id THEN
            RAISE EXCEPTION 'arrival_terminal_id (%) tidak cocok dengan terminal gate arrival_gate_id (%)',
                NEW.arrival_terminal_id, NEW.arrival_gate_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_flight_gate_terminal
    BEFORE INSERT OR UPDATE ON airline.flights
    FOR EACH ROW EXECUTE FUNCTION airline.validate_flight_terminal_gate();

-- =============================================================================
-- TABLE 13: flight_prices
-- =============================================================================
CREATE TABLE airline.flight_prices (
    price_id          UUID          NOT NULL DEFAULT uuid_generate_v4(),
    flight_id         UUID          NOT NULL,
    seat_class        airline.seat_class NOT NULL,
    fare_basis        VARCHAR(20)   NOT NULL,
    base_price        DECIMAL(12,2) NOT NULL,
    tax_amount        DECIMAL(12,2) NOT NULL DEFAULT 0,
    surcharge_amount  DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_price       DECIMAL(12,2) GENERATED ALWAYS AS (base_price + tax_amount + surcharge_amount) STORED,
    currency_code     CHAR(3)       NOT NULL DEFAULT 'IDR',
    available_seats   INT           NOT NULL DEFAULT 0,
    refundable        BOOLEAN       NOT NULL DEFAULT FALSE,
    changeable        BOOLEAN       NOT NULL DEFAULT TRUE,
    valid_from        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    valid_until       TIMESTAMPTZ,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_flight_prices PRIMARY KEY (price_id),
    CONSTRAINT fk_flight_prices_flight FOREIGN KEY (flight_id) REFERENCES airline.flights(flight_id),
    CONSTRAINT fk_flight_prices_currency FOREIGN KEY (currency_code) REFERENCES finance.currencies(currency_code),
    CONSTRAINT chk_flight_prices_positive CHECK (base_price >= 0),
    -- FIX #4: Exclusion constraint mencegah harga aktif bertabrakan
    CONSTRAINT excl_flight_price_active EXCLUDE USING gist (
        flight_id WITH =,
        seat_class WITH =,
        fare_basis WITH =,
        tstzrange(valid_from, valid_until, '[)') WITH &&
    )
);

CREATE INDEX idx_flight_prices_flight ON airline.flight_prices(flight_id);
CREATE INDEX idx_flight_prices_class ON airline.flight_prices(seat_class);

-- =============================================================================
-- TABLE 14: passengers
-- =============================================================================
CREATE TABLE airline.passengers (
    passenger_id      UUID          NOT NULL DEFAULT uuid_generate_v4(),
    first_name        VARCHAR(100)  NOT NULL,
    middle_name       VARCHAR(100),
    last_name         VARCHAR(100)  NOT NULL,
    date_of_birth     DATE          NOT NULL,
    gender            airline.gender_type NOT NULL,
    nationality       CHAR(2)       NOT NULL,
    email             VARCHAR(255),
    phone_number      VARCHAR(30),
    phone_country     CHAR(2),
    address_line1     VARCHAR(255),
    address_line2     VARCHAR(255),
    city              VARCHAR(100),
    state_province    VARCHAR(100),
    postal_code       VARCHAR(20),
    country_id        CHAR(2),
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    gdpr_consent      BOOLEAN       NOT NULL DEFAULT FALSE,
    gdpr_consent_date TIMESTAMPTZ,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_passengers PRIMARY KEY (passenger_id),
    CONSTRAINT fk_passengers_nationality FOREIGN KEY (nationality) REFERENCES airline.countries(country_id),
    CONSTRAINT fk_passengers_country FOREIGN KEY (country_id) REFERENCES airline.countries(country_id),
    CONSTRAINT chk_passengers_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- =============================================================================
-- TABLE 15: passenger_documents
-- =============================================================================
CREATE TABLE airline.passenger_documents (
    document_id       UUID          NOT NULL DEFAULT uuid_generate_v4(),
    passenger_id      UUID          NOT NULL,
    document_type     airline.document_type NOT NULL,
    document_number   VARCHAR(50)   NOT NULL,
    issuing_country   CHAR(2)       NOT NULL,
    issue_date        DATE,
    expiry_date       DATE          NOT NULL,
    is_primary        BOOLEAN       NOT NULL DEFAULT FALSE,
    is_verified       BOOLEAN       NOT NULL DEFAULT FALSE,
    verified_at       TIMESTAMPTZ,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_passenger_documents PRIMARY KEY (document_id),
    CONSTRAINT uq_passenger_documents UNIQUE (document_type, document_number, issuing_country),
    CONSTRAINT fk_passenger_documents_passenger FOREIGN KEY (passenger_id) REFERENCES airline.passengers(passenger_id),
    CONSTRAINT fk_passenger_documents_country FOREIGN KEY (issuing_country) REFERENCES airline.countries(country_id),
    CONSTRAINT chk_passenger_doc_expiry CHECK (expiry_date > COALESCE(issue_date, expiry_date - INTERVAL '1 day'))
);

-- =============================================================================
-- TABLE 16: loyalty_accounts
-- =============================================================================
CREATE TABLE airline.loyalty_accounts (
    loyalty_id        UUID          NOT NULL DEFAULT uuid_generate_v4(),
    passenger_id      UUID          NOT NULL,
    membership_number VARCHAR(20)   NOT NULL,
    tier              airline.loyalty_tier NOT NULL DEFAULT 'BASIC',
    total_miles       DECIMAL(14,2) NOT NULL DEFAULT 0,
    available_miles   DECIMAL(14,2) NOT NULL DEFAULT 0,
    tier_miles_ytd    DECIMAL(14,2) NOT NULL DEFAULT 0,
    tier_expiry_date  DATE,
    enrolled_date     DATE          NOT NULL DEFAULT CURRENT_DATE,
    last_activity     DATE,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_loyalty_accounts PRIMARY KEY (loyalty_id),
    CONSTRAINT uq_loyalty_accounts_member UNIQUE (membership_number),
    CONSTRAINT uq_loyalty_accounts_passenger UNIQUE (passenger_id),
    CONSTRAINT fk_loyalty_accounts_passenger FOREIGN KEY (passenger_id) REFERENCES airline.passengers(passenger_id),
    CONSTRAINT chk_loyalty_available_miles CHECK (available_miles >= 0),
    CONSTRAINT chk_loyalty_total_miles CHECK (total_miles >= 0)
);

-- =============================================================================
-- TABLE 17: loyalty_transactions
-- =============================================================================
CREATE TABLE airline.loyalty_transactions (
    transaction_id    UUID          NOT NULL DEFAULT uuid_generate_v4(),
    loyalty_id        UUID          NOT NULL,
    transaction_date  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    transaction_type  VARCHAR(20)   NOT NULL CHECK (transaction_type IN ('EARN', 'REDEEM', 'EXPIRE', 'TRANSFER', 'BONUS', 'ADJUSTMENT')),
    miles_amount      DECIMAL(12,2) NOT NULL,
    balance_after     DECIMAL(12,2) NOT NULL,
    reference_type    VARCHAR(50),
    reference_id      UUID,
    description       VARCHAR(500),
    expiry_date       DATE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_loyalty_transactions PRIMARY KEY (transaction_id),
    CONSTRAINT fk_loyalty_transactions_account FOREIGN KEY (loyalty_id) REFERENCES airline.loyalty_accounts(loyalty_id)
);

-- =============================================================================
-- TABLE 18: bookings
-- =============================================================================
CREATE TABLE airline.bookings (
    booking_id        UUID          NOT NULL DEFAULT uuid_generate_v4(),
    booking_reference VARCHAR(10)   NOT NULL,
    primary_passenger_id UUID       NOT NULL,
    booking_date      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    status            airline.booking_status NOT NULL DEFAULT 'PENDING',
    total_amount      DECIMAL(14,2) NOT NULL,
    currency_code     CHAR(3)       NOT NULL DEFAULT 'IDR',
    discount_amount   DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax_amount        DECIMAL(12,2) NOT NULL DEFAULT 0,
    final_amount      DECIMAL(14,2) GENERATED ALWAYS AS (total_amount - discount_amount + tax_amount) STORED,
    source_channel    VARCHAR(50),
    agent_id          UUID,
    promo_code        VARCHAR(50),
    notes             TEXT,
    cancelled_at      TIMESTAMPTZ,
    cancellation_reason TEXT,
    refund_amount     DECIMAL(12,2),
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_bookings PRIMARY KEY (booking_id),
    CONSTRAINT uq_bookings_reference UNIQUE (booking_reference),
    CONSTRAINT fk_bookings_passenger FOREIGN KEY (primary_passenger_id) REFERENCES airline.passengers(passenger_id),
    CONSTRAINT fk_bookings_currency FOREIGN KEY (currency_code) REFERENCES finance.currencies(currency_code),
    -- FIX #5: FK agent_id ke employees
    CONSTRAINT fk_bookings_agent FOREIGN KEY (agent_id) REFERENCES airline.employees(employee_id)
);

-- =============================================================================
-- TABLE 19: booking_passengers
-- =============================================================================
CREATE TABLE airline.booking_passengers (
    booking_passenger_id UUID        NOT NULL DEFAULT uuid_generate_v4(),
    booking_id           UUID        NOT NULL,
    passenger_id         UUID        NOT NULL,
    passenger_type       VARCHAR(20) NOT NULL DEFAULT 'ADULT' CHECK (passenger_type IN ('ADULT', 'CHILD', 'INFANT', 'SENIOR')),
    title                VARCHAR(10),
    first_name           VARCHAR(100) NOT NULL,
    last_name            VARCHAR(100) NOT NULL,
    date_of_birth        DATE,
    nationality          CHAR(2),
    is_lead_passenger    BOOLEAN     NOT NULL DEFAULT FALSE,
    special_requests     TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_booking_passengers PRIMARY KEY (booking_passenger_id),
    CONSTRAINT uq_booking_passengers UNIQUE (booking_id, passenger_id),
    CONSTRAINT fk_booking_passengers_booking FOREIGN KEY (booking_id) REFERENCES airline.bookings(booking_id),
    CONSTRAINT fk_booking_passengers_passenger FOREIGN KEY (passenger_id) REFERENCES airline.passengers(passenger_id)
);

-- =============================================================================
-- TABLE 20: booking_segments
-- =============================================================================
CREATE TABLE airline.booking_segments (
    segment_id           UUID          NOT NULL DEFAULT uuid_generate_v4(),
    booking_id           UUID          NOT NULL,
    booking_passenger_id UUID          NOT NULL,
    flight_id            UUID          NOT NULL,
    price_id             UUID          NOT NULL,
    seat_id              UUID,
    seat_class           airline.seat_class NOT NULL,
    seat_number          VARCHAR(5),
    status               airline.booking_status NOT NULL DEFAULT 'CONFIRMED',
    ticket_number        VARCHAR(20),
    fare_basis           VARCHAR(20),
    segment_price        DECIMAL(12,2) NOT NULL,
    baggage_allowance_kg INT           NOT NULL DEFAULT 20,
    meal_preference      VARCHAR(10),
    ssr_codes            VARCHAR(10)[],
    pnr_reference        VARCHAR(10),
    created_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_booking_segments PRIMARY KEY (segment_id),
    CONSTRAINT fk_booking_segments_booking FOREIGN KEY (booking_id) REFERENCES airline.bookings(booking_id),
    CONSTRAINT fk_booking_segments_passenger FOREIGN KEY (booking_passenger_id) REFERENCES airline.booking_passengers(booking_passenger_id),
    CONSTRAINT fk_booking_segments_flight FOREIGN KEY (flight_id) REFERENCES airline.flights(flight_id),
    CONSTRAINT fk_booking_segments_price FOREIGN KEY (price_id) REFERENCES airline.flight_prices(price_id),
    CONSTRAINT fk_booking_segments_seat FOREIGN KEY (seat_id) REFERENCES airline.seats(seat_id)
);

-- =============================================================================
-- TABLE 21: seat_reservations
-- =============================================================================
CREATE TABLE airline.seat_reservations (
    reservation_id    UUID          NOT NULL DEFAULT uuid_generate_v4(),
    flight_id         UUID          NOT NULL,
    seat_id           UUID          NOT NULL,
    segment_id        UUID,
    status            airline.seat_status NOT NULL DEFAULT 'RESERVED',
    reserved_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    expires_at        TIMESTAMPTZ,
    released_at       TIMESTAMPTZ,
    CONSTRAINT pk_seat_reservations PRIMARY KEY (reservation_id),
    CONSTRAINT uq_seat_reservations UNIQUE (flight_id, seat_id),
    CONSTRAINT fk_seat_reservations_flight FOREIGN KEY (flight_id) REFERENCES airline.flights(flight_id),
    CONSTRAINT fk_seat_reservations_seat FOREIGN KEY (seat_id) REFERENCES airline.seats(seat_id),
    CONSTRAINT fk_seat_reservations_segment FOREIGN KEY (segment_id) REFERENCES airline.booking_segments(segment_id)
) PARTITION BY RANGE (reserved_at);

-- =============================================================================
-- TABLE 22: payments
-- =============================================================================
CREATE TABLE finance.payments (
    payment_id            UUID          NOT NULL DEFAULT uuid_generate_v4(),
    booking_id            UUID          NOT NULL,
    payment_method        airline.payment_method NOT NULL,
    payment_status        airline.payment_status NOT NULL DEFAULT 'PENDING',
    amount                DECIMAL(14,2) NOT NULL,
    currency_code         CHAR(3)       NOT NULL DEFAULT 'IDR',
    gateway_reference     VARCHAR(100),
    gateway_name          VARCHAR(50),
    gateway_response      JSONB,
    card_last_four        CHAR(4),
    card_brand            VARCHAR(20),
    bank_name             VARCHAR(100),
    transaction_date      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    authorized_at         TIMESTAMPTZ,
    captured_at           TIMESTAMPTZ,
    refunded_at           TIMESTAMPTZ,
    refund_amount         DECIMAL(12,2),
    failure_reason        VARCHAR(500),
    idempotency_key       VARCHAR(100),
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_payments PRIMARY KEY (payment_id),
    CONSTRAINT uq_payments_idempotency UNIQUE (idempotency_key),
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id) REFERENCES airline.bookings(booking_id),
    CONSTRAINT fk_payments_currency FOREIGN KEY (currency_code) REFERENCES finance.currencies(currency_code),
    CONSTRAINT chk_payments_amount CHECK (amount > 0)
);

-- =============================================================================
-- TABLE 23: check_ins
-- =============================================================================
CREATE TABLE airline.check_ins (
    check_in_id       UUID          NOT NULL DEFAULT uuid_generate_v4(),
    segment_id        UUID          NOT NULL,
    check_in_method   VARCHAR(20)   NOT NULL CHECK (check_in_method IN ('ONLINE', 'KIOSK', 'COUNTER', 'MOBILE', 'API')),
    checked_in_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    checked_in_by     VARCHAR(100),
    boarding_pass_issued BOOLEAN    NOT NULL DEFAULT TRUE,
    boarding_pass_type VARCHAR(20),
    staff_id          UUID,
    counter_number    VARCHAR(10),
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_check_ins PRIMARY KEY (check_in_id),
    CONSTRAINT uq_check_ins_segment UNIQUE (segment_id),
    CONSTRAINT fk_check_ins_segment FOREIGN KEY (segment_id) REFERENCES airline.booking_segments(segment_id)
);

-- =============================================================================
-- TABLE 24: baggage
-- =============================================================================
CREATE TABLE airline.baggage (
    baggage_id        UUID          NOT NULL DEFAULT uuid_generate_v4(),
    segment_id        UUID          NOT NULL,
    tag_number        VARCHAR(20)   NOT NULL,
    weight_kg         DECIMAL(6,2)  NOT NULL,
    baggage_type      VARCHAR(30)   NOT NULL DEFAULT 'CHECKED' CHECK (baggage_type IN ('CHECKED', 'CABIN', 'OVERSIZED', 'FRAGILE', 'SPORTS')),
    status            airline.baggage_status NOT NULL DEFAULT 'CHECKED_IN',
    is_excess         BOOLEAN       NOT NULL DEFAULT FALSE,
    excess_fee        DECIMAL(10,2),
    current_location  VARCHAR(100),
    last_scanned_at   TIMESTAMPTZ,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_baggage PRIMARY KEY (baggage_id),
    CONSTRAINT uq_baggage_tag UNIQUE (tag_number),
    CONSTRAINT fk_baggage_segment FOREIGN KEY (segment_id) REFERENCES airline.booking_segments(segment_id),
    CONSTRAINT chk_baggage_weight CHECK (weight_kg > 0)
);

-- =============================================================================
-- TABLE 25: employees
-- =============================================================================
CREATE TABLE airline.employees (
    employee_id       UUID          NOT NULL DEFAULT uuid_generate_v4(),
    employee_number   VARCHAR(20)   NOT NULL,
    first_name        VARCHAR(100)  NOT NULL,
    last_name         VARCHAR(100)  NOT NULL,
    date_of_birth     DATE          NOT NULL,
    gender            airline.gender_type,
    nationality       CHAR(2),
    email             VARCHAR(255)  NOT NULL,
    phone_number      VARCHAR(30),
    hire_date         DATE          NOT NULL,
    termination_date  DATE,
    department        VARCHAR(100)  NOT NULL,
    job_title         VARCHAR(100)  NOT NULL,
    base_airport_id   UUID,
    manager_id        UUID,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_employees PRIMARY KEY (employee_id),
    CONSTRAINT uq_employees_number UNIQUE (employee_number),
    CONSTRAINT uq_employees_email UNIQUE (email),
    CONSTRAINT fk_employees_base FOREIGN KEY (base_airport_id) REFERENCES airline.airports(airport_id),
    CONSTRAINT fk_employees_manager FOREIGN KEY (manager_id) REFERENCES airline.employees(employee_id)
);

-- =============================================================================
-- TABLE 26: crew_members
-- =============================================================================
CREATE TABLE airline.crew_members (
    crew_id           UUID          NOT NULL DEFAULT uuid_generate_v4(),
    employee_id       UUID          NOT NULL,
    crew_role         airline.crew_role NOT NULL,
    license_number    VARCHAR(50),
    license_expiry    DATE,
    medical_cert_expiry DATE,
    total_flight_hours DECIMAL(10,2) NOT NULL DEFAULT 0,
    type_ratings      VARCHAR(20)[],
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_crew_members PRIMARY KEY (crew_id),
    CONSTRAINT uq_crew_members_employee UNIQUE (employee_id),
    CONSTRAINT fk_crew_members_employee FOREIGN KEY (employee_id) REFERENCES airline.employees(employee_id)
);

-- =============================================================================
-- TABLE 27: flight_crew_assignments
-- =============================================================================
CREATE TABLE airline.flight_crew_assignments (
    assignment_id     UUID          NOT NULL DEFAULT uuid_generate_v4(),
    flight_id         UUID          NOT NULL,
    crew_id           UUID          NOT NULL,
    crew_role         airline.crew_role NOT NULL,
    assigned_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    confirmed_at      TIMESTAMPTZ,
    is_confirmed      BOOLEAN       NOT NULL DEFAULT FALSE,
    notes             TEXT,
    CONSTRAINT pk_flight_crew_assignments PRIMARY KEY (assignment_id),
    CONSTRAINT uq_flight_crew_assignments UNIQUE (flight_id, crew_id),
    CONSTRAINT fk_flight_crew_flights FOREIGN KEY (flight_id) REFERENCES airline.flights(flight_id),
    CONSTRAINT fk_flight_crew_members FOREIGN KEY (crew_id) REFERENCES airline.crew_members(crew_id)
);

-- =============================================================================
-- TABLE 28: maintenance_records
-- =============================================================================
CREATE TABLE airline.maintenance_records (
    maintenance_id        UUID          NOT NULL DEFAULT uuid_generate_v4(),
    aircraft_id           UUID          NOT NULL,
    maintenance_type      airline.maintenance_type NOT NULL,
    status                airline.maintenance_status NOT NULL DEFAULT 'PLANNED',
    scheduled_start       TIMESTAMPTZ   NOT NULL,
    scheduled_end         TIMESTAMPTZ   NOT NULL,
    actual_start          TIMESTAMPTZ,
    actual_end            TIMESTAMPTZ,
    maintenance_location  VARCHAR(200),
    performed_by_org      VARCHAR(200),
    technician_employee_id UUID,
    work_order_number     VARCHAR(50),
    description           TEXT,
    findings              TEXT,
    parts_replaced        JSONB,
    total_cost            DECIMAL(14,2),
    next_due_hours        DECIMAL(10,2),
    next_due_date         DATE,
    approved_by           UUID,
    sign_off_at           TIMESTAMPTZ,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_maintenance_records PRIMARY KEY (maintenance_id),
    CONSTRAINT fk_maintenance_aircraft FOREIGN KEY (aircraft_id) REFERENCES airline.aircrafts(aircraft_id),
    CONSTRAINT fk_maintenance_technician FOREIGN KEY (technician_employee_id) REFERENCES airline.employees(employee_id),
    -- FIX #5: FK approved_by ke employees
    CONSTRAINT fk_maintenance_approver FOREIGN KEY (approved_by) REFERENCES airline.employees(employee_id),
    CONSTRAINT chk_maintenance_dates CHECK (scheduled_end > scheduled_start)
);

-- =============================================================================
-- TABLE 29: promotions (tanpa perubahan)
-- =============================================================================
CREATE TABLE airline.promotions (
    promotion_id      UUID          NOT NULL DEFAULT uuid_generate_v4(),
    promo_code        VARCHAR(50)   NOT NULL,
    promo_name        VARCHAR(200)  NOT NULL,
    description       TEXT,
    discount_type     VARCHAR(20)   NOT NULL CHECK (discount_type IN ('PERCENTAGE', 'FIXED', 'FREE_SEAT', 'MILES_BONUS')),
    discount_value    DECIMAL(10,2) NOT NULL,
    max_discount      DECIMAL(10,2),
    min_purchase      DECIMAL(10,2),
    applicable_classes airline.seat_class[],
    applicable_routes  UUID[],
    valid_from        TIMESTAMPTZ   NOT NULL,
    valid_until       TIMESTAMPTZ   NOT NULL,
    max_usage         INT,
    usage_count       INT           NOT NULL DEFAULT 0,
    per_user_limit    INT,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_promotions PRIMARY KEY (promotion_id),
    CONSTRAINT uq_promotions_code UNIQUE (promo_code),
    CONSTRAINT chk_promotions_dates CHECK (valid_until > valid_from),
    CONSTRAINT chk_promotions_value CHECK (discount_value > 0)
);

-- =============================================================================
-- TABLE 30: ancillary_services
-- =============================================================================
CREATE TABLE airline.ancillary_services (
    service_id        UUID          NOT NULL DEFAULT uuid_generate_v4(),
    service_code      VARCHAR(20)   NOT NULL,
    service_name      VARCHAR(200)  NOT NULL,
    category          VARCHAR(50)   NOT NULL CHECK (category IN ('BAGGAGE', 'MEAL', 'SEAT', 'LOUNGE', 'INSURANCE', 'GROUND_TRANSPORT', 'WIFI', 'PRIORITY', 'OTHER')),
    description       TEXT,
    price             DECIMAL(12,2) NOT NULL,
    currency_code     CHAR(3)       NOT NULL DEFAULT 'IDR',
    is_per_passenger  BOOLEAN       NOT NULL DEFAULT TRUE,
    is_per_segment    BOOLEAN       NOT NULL DEFAULT TRUE,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_ancillary_services PRIMARY KEY (service_id),
    CONSTRAINT uq_ancillary_code UNIQUE (service_code),
    CONSTRAINT fk_ancillary_currency FOREIGN KEY (currency_code) REFERENCES finance.currencies(currency_code),
    CONSTRAINT chk_ancillary_price CHECK (price >= 0)
);

-- =============================================================================
-- TABLE 31: booking_ancillaries
-- =============================================================================
CREATE TABLE airline.booking_ancillaries (
    booking_ancillary_id UUID        NOT NULL DEFAULT uuid_generate_v4(),
    booking_id           UUID        NOT NULL,
    segment_id           UUID,
    service_id           UUID        NOT NULL,
    quantity             INT         NOT NULL DEFAULT 1,
    unit_price           DECIMAL(12,2) NOT NULL,
    total_price          DECIMAL(12,2) GENERATED ALWAYS AS (unit_price * quantity) STORED,
    status               VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'USED', 'CANCELLED', 'REFUNDED')),
    purchased_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_booking_ancillaries PRIMARY KEY (booking_ancillary_id),
    CONSTRAINT fk_booking_ancillaries_booking FOREIGN KEY (booking_id) REFERENCES airline.bookings(booking_id),
    CONSTRAINT fk_booking_ancillaries_segment FOREIGN KEY (segment_id) REFERENCES airline.booking_segments(segment_id),
    CONSTRAINT fk_booking_ancillaries_service FOREIGN KEY (service_id) REFERENCES airline.ancillary_services(service_id),
    CONSTRAINT chk_booking_ancillaries_qty CHECK (quantity > 0)
);

-- =============================================================================
-- TABLE 32: notifications
-- =============================================================================
CREATE TABLE airline.notifications (
    notification_id   UUID          NOT NULL DEFAULT uuid_generate_v4(),
    passenger_id      UUID          NOT NULL,
    booking_id        UUID,
    flight_id         UUID,
    channel           airline.notification_channel NOT NULL,
    template_code     VARCHAR(50)   NOT NULL,
    subject           VARCHAR(255),
    body              TEXT          NOT NULL,
    recipient_address VARCHAR(255)  NOT NULL,
    status            VARCHAR(20)   NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SENT', 'DELIVERED', 'FAILED', 'READ')),
    sent_at           TIMESTAMPTZ,
    delivered_at      TIMESTAMPTZ,
    read_at           TIMESTAMPTZ,
    failure_reason    VARCHAR(500),
    provider_message_id VARCHAR(200),
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_notifications PRIMARY KEY (notification_id),
    CONSTRAINT fk_notifications_passenger FOREIGN KEY (passenger_id) REFERENCES airline.passengers(passenger_id),
    CONSTRAINT fk_notifications_booking FOREIGN KEY (booking_id) REFERENCES airline.bookings(booking_id),
    CONSTRAINT fk_notifications_flight FOREIGN KEY (flight_id) REFERENCES airline.flights(flight_id)
) PARTITION BY RANGE (created_at);

-- =============================================================================
-- TABLE 33: customer_support_tickets
-- =============================================================================
CREATE TABLE airline.customer_support_tickets (
    ticket_id         UUID          NOT NULL DEFAULT uuid_generate_v4(),
    ticket_number     VARCHAR(20)   NOT NULL,
    passenger_id      UUID          NOT NULL,
    booking_id        UUID,
    category          VARCHAR(50)   NOT NULL CHECK (category IN ('FLIGHT_CHANGE', 'REFUND', 'BAGGAGE', 'COMPLAINT', 'INQUIRY', 'SPECIAL_REQUEST', 'COMPENSATION', 'OTHER')),
    priority          VARCHAR(10)   NOT NULL DEFAULT 'NORMAL' CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    status            VARCHAR(20)   NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'IN_PROGRESS', 'PENDING_CUSTOMER', 'RESOLVED', 'CLOSED', 'ESCALATED')),
    subject           VARCHAR(500)  NOT NULL,
    description       TEXT          NOT NULL,
    assigned_to       UUID,
    resolved_at       TIMESTAMPTZ,
    resolution_notes  TEXT,
    satisfaction_score SMALLINT     CHECK (satisfaction_score BETWEEN 1 AND 5),
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_support_tickets PRIMARY KEY (ticket_id),
    CONSTRAINT uq_support_tickets_number UNIQUE (ticket_number),
    CONSTRAINT fk_support_tickets_passenger FOREIGN KEY (passenger_id) REFERENCES airline.passengers(passenger_id),
    CONSTRAINT fk_support_tickets_booking FOREIGN KEY (booking_id) REFERENCES airline.bookings(booking_id),
    CONSTRAINT fk_support_tickets_employee FOREIGN KEY (assigned_to) REFERENCES airline.employees(employee_id)
);

-- =============================================================================
-- TABLE 34: airport_slots
-- =============================================================================
CREATE TABLE airline.airport_slots (
    slot_id           UUID          NOT NULL DEFAULT uuid_generate_v4(),
    airport_id        UUID          NOT NULL,
    flight_id         UUID,
    slot_type         VARCHAR(20)   NOT NULL CHECK (slot_type IN ('DEPARTURE', 'ARRIVAL')),
    slot_time         TIMESTAMPTZ   NOT NULL,
    runway_id         UUID,
    is_confirmed      BOOLEAN       NOT NULL DEFAULT FALSE,
    is_cancelled      BOOLEAN       NOT NULL DEFAULT FALSE,
    coordinator_ref   VARCHAR(50),
    iata_season       VARCHAR(10),
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_airport_slots PRIMARY KEY (slot_id),
    CONSTRAINT fk_airport_slots_airport FOREIGN KEY (airport_id) REFERENCES airline.airports(airport_id),
    CONSTRAINT fk_airport_slots_flight FOREIGN KEY (flight_id) REFERENCES airline.flights(flight_id),
    CONSTRAINT fk_airport_slots_runway FOREIGN KEY (runway_id) REFERENCES airline.runways(runway_id)
);

-- =============================================================================
-- TABLE 35: flight_operational_data
-- =============================================================================
CREATE TABLE airline.flight_operational_data (
    ops_id            UUID          NOT NULL DEFAULT uuid_generate_v4(),
    flight_id         UUID          NOT NULL,
    takeoff_weight_kg DECIMAL(10,2),
    landing_weight_kg DECIMAL(10,2),
    fuel_uplift_kg    DECIMAL(10,2),
    fuel_burn_kg      DECIMAL(10,2),
    flight_level      INT,
    avg_airspeed_kt   INT,
    distance_flown_nm DECIMAL(8,2),
    block_time_min    INT,
    airborne_time_min INT,
    delay_minutes     INT           NOT NULL DEFAULT 0,
    delay_codes       VARCHAR(5)[],
    atc_ref           VARCHAR(50),
    pirep_notes       TEXT,
    weather_remarks   TEXT,
    turbulence_level  VARCHAR(20),
    captain_id        UUID,
    recorded_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_flight_operational_data PRIMARY KEY (ops_id),
    CONSTRAINT uq_flight_ops UNIQUE (flight_id),
    CONSTRAINT fk_flight_ops_flight FOREIGN KEY (flight_id) REFERENCES airline.flights(flight_id),
    CONSTRAINT fk_flight_ops_captain FOREIGN KEY (captain_id) REFERENCES airline.crew_members(crew_id)
);

-- =============================================================================
-- TABLE 36: revenue_accounting
-- =============================================================================
CREATE TABLE finance.revenue_accounting (
    revenue_id        UUID          NOT NULL DEFAULT uuid_generate_v4(),
    booking_id        UUID          NOT NULL,
    flight_id         UUID          NOT NULL,
    revenue_type      VARCHAR(50)   NOT NULL CHECK (revenue_type IN ('TICKET', 'ANCILLARY', 'CARGO', 'LOYALTY_REDEEM', 'PENALTY', 'OTHER')),
    gross_amount      DECIMAL(14,2) NOT NULL,
    tax_amount        DECIMAL(12,2) NOT NULL DEFAULT 0,
    commission_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    net_amount        DECIMAL(14,2) GENERATED ALWAYS AS (gross_amount - tax_amount - commission_amount) STORED,
    currency_code     CHAR(3)       NOT NULL DEFAULT 'IDR',
    accounting_date   DATE          NOT NULL DEFAULT CURRENT_DATE,
    gl_account        VARCHAR(20),
    cost_center       VARCHAR(20),
    is_recognized     BOOLEAN       NOT NULL DEFAULT FALSE,
    recognized_at     TIMESTAMPTZ,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_revenue_accounting PRIMARY KEY (revenue_id),
    CONSTRAINT fk_revenue_booking FOREIGN KEY (booking_id) REFERENCES airline.bookings(booking_id),
    CONSTRAINT fk_revenue_flight FOREIGN KEY (flight_id) REFERENCES airline.flights(flight_id),
    CONSTRAINT fk_revenue_currency FOREIGN KEY (currency_code) REFERENCES finance.currencies(currency_code)
);

-- =============================================================================
-- TABLE 37: users
-- =============================================================================
CREATE TABLE airline.users (
    user_id           UUID          NOT NULL DEFAULT uuid_generate_v4(),
    passenger_id      UUID,
    employee_id       UUID,
    username          VARCHAR(100)  NOT NULL,
    email             VARCHAR(255)  NOT NULL,
    password_hash     VARCHAR(255)  NOT NULL,
    password_salt     VARCHAR(100),
    mfa_enabled       BOOLEAN       NOT NULL DEFAULT FALSE,
    mfa_secret        VARCHAR(100),
    last_login        TIMESTAMPTZ,
    login_attempts    SMALLINT      NOT NULL DEFAULT 0,
    locked_until      TIMESTAMPTZ,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    is_admin          BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT fk_users_passenger FOREIGN KEY (passenger_id) REFERENCES airline.passengers(passenger_id),
    CONSTRAINT fk_users_employee FOREIGN KEY (employee_id) REFERENCES airline.employees(employee_id),
    CONSTRAINT chk_users_one_type CHECK (
        (passenger_id IS NOT NULL AND employee_id IS NULL) OR
        (passenger_id IS NULL AND employee_id IS NOT NULL)
    )
);

-- =============================================================================
-- TABLE 38: audit_logs (tidak ada perubahan struktur, partisi diperbaiki di bawah)
-- =============================================================================
CREATE TABLE audit.audit_logs (
    log_id            UUID          NOT NULL DEFAULT uuid_generate_v4(),
    schema_name       VARCHAR(50)   NOT NULL,
    table_name        VARCHAR(100)  NOT NULL,
    record_id         TEXT          NOT NULL,
    action            audit.action_type NOT NULL,
    old_values        JSONB,
    new_values        JSONB,
    changed_columns   TEXT[],
    performed_by      UUID,
    performed_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    ip_address        INET,
    session_id        VARCHAR(100),
    application_name  VARCHAR(100),
    CONSTRAINT pk_audit_logs PRIMARY KEY (log_id)
) PARTITION BY RANGE (performed_at);

-- =============================================================================
-- PARTITIONS (FIX #6: eksplisit UTC)
-- =============================================================================
CREATE TABLE airline.seat_reservations_2025 PARTITION OF airline.seat_reservations
    FOR VALUES FROM (TIMESTAMPTZ '2025-01-01 00:00:00+00') TO (TIMESTAMPTZ '2026-01-01 00:00:00+00');
CREATE TABLE airline.seat_reservations_2026 PARTITION OF airline.seat_reservations
    FOR VALUES FROM (TIMESTAMPTZ '2026-01-01 00:00:00+00') TO (TIMESTAMPTZ '2027-01-01 00:00:00+00');

CREATE TABLE airline.notifications_2025 PARTITION OF airline.notifications
    FOR VALUES FROM (TIMESTAMPTZ '2025-01-01 00:00:00+00') TO (TIMESTAMPTZ '2026-01-01 00:00:00+00');
CREATE TABLE airline.notifications_2026 PARTITION OF airline.notifications
    FOR VALUES FROM (TIMESTAMPTZ '2026-01-01 00:00:00+00') TO (TIMESTAMPTZ '2027-01-01 00:00:00+00');

CREATE TABLE audit.audit_logs_2025 PARTITION OF audit.audit_logs
    FOR VALUES FROM (TIMESTAMPTZ '2025-01-01 00:00:00+00') TO (TIMESTAMPTZ '2026-01-01 00:00:00+00');
CREATE TABLE audit.audit_logs_2026 PARTITION OF audit.audit_logs
    FOR VALUES FROM (TIMESTAMPTZ '2026-01-01 00:00:00+00') TO (TIMESTAMPTZ '2027-01-01 00:00:00+00');

-- =============================================================================
-- GENERIC AUDIT TRIGGER FUNCTION
-- =============================================================================
CREATE OR REPLACE FUNCTION audit.log_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_record_id TEXT;
    v_old_values JSONB;
    v_new_values JSONB;
    v_changed_columns TEXT[];
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_record_id := OLD.ctid::TEXT;
        v_old_values := to_jsonb(OLD);
        v_new_values := NULL;
    ELSIF TG_OP = 'INSERT' THEN
        v_record_id := NEW.ctid::TEXT;
        v_old_values := NULL;
        v_new_values := to_jsonb(NEW);
    ELSE
        v_record_id := NEW.ctid::TEXT;
        v_old_values := to_jsonb(OLD);
        v_new_values := to_jsonb(NEW);
        SELECT ARRAY_AGG(key) INTO v_changed_columns
        FROM jsonb_each(to_jsonb(OLD)) o
        FULL OUTER JOIN jsonb_each(to_jsonb(NEW)) n USING (key)
        WHERE o.value IS DISTINCT FROM n.value;
    END IF;

    INSERT INTO audit.audit_logs (
        schema_name, table_name, record_id, action,
        old_values, new_values, changed_columns,
        performed_by, ip_address, application_name
    ) VALUES (
        TG_TABLE_SCHEMA, TG_TABLE_NAME, v_record_id,
        TG_OP::audit.action_type,
        v_old_values, v_new_values, v_changed_columns,
        current_setting('app.current_user_id', TRUE)::UUID,
        current_setting('app.client_ip', TRUE)::INET,
        current_application_name()
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit trigger to critical tables
CREATE TRIGGER trg_audit_bookings
    AFTER INSERT OR UPDATE OR DELETE ON airline.bookings
    FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

CREATE TRIGGER trg_audit_payments
    AFTER INSERT OR UPDATE OR DELETE ON finance.payments
    FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

CREATE TRIGGER trg_audit_passengers
    AFTER INSERT OR UPDATE OR DELETE ON airline.passengers
    FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

CREATE TRIGGER trg_audit_flights
    AFTER INSERT OR UPDATE OR DELETE ON airline.flights
    FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

-- =============================================================================
-- UPDATED_AT AUTO-UPDATE TRIGGER
-- =============================================================================
CREATE OR REPLACE FUNCTION airline.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at (tambahkan aircraft_config_assignments)
DO $$
DECLARE
    t TEXT;
    tables TEXT[] := ARRAY[
        'airports', 'terminals', 'gates', 'runways', 'aircraft_types',
        'aircrafts', 'aircraft_config_assignments', 'routes', 'flights', 'flight_prices', 'passengers',
        'passenger_documents', 'loyalty_accounts', 'bookings', 'booking_segments',
        'promotions', 'ancillary_services', 'employees', 'crew_members',
        'maintenance_records', 'users'
    ];
BEGIN
    FOREACH t IN ARRAY tables LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_updated_at_%s BEFORE UPDATE ON airline.%s FOR EACH ROW EXECUTE FUNCTION airline.update_updated_at()',
            t, t
        );
    END LOOP;
END;
$$;

-- =============================================================================
-- USEFUL VIEWS (tidak berubah)
-- =============================================================================
CREATE OR REPLACE VIEW airline.v_flight_summary AS
SELECT
    f.flight_id,
    f.flight_number,
    f.status,
    f.scheduled_departure,
    f.scheduled_arrival,
    f.actual_departure,
    f.actual_arrival,
    oa.iata_code AS origin_iata,
    oa.city      AS origin_city,
    da.iata_code AS destination_iata,
    da.city      AS destination_city,
    ac.registration_number,
    at2.manufacturer || ' ' || at2.model AS aircraft_type,
    f.booked_pax,
    f.total_pax_capacity,
    ROUND(f.booked_pax::DECIMAL / NULLIF(f.total_pax_capacity, 0) * 100, 2) AS load_factor_pct
FROM airline.flights f
JOIN airline.routes r ON f.route_id = r.route_id
JOIN airline.airports oa ON r.origin_airport_id = oa.airport_id
JOIN airline.airports da ON r.destination_airport_id = da.airport_id
LEFT JOIN airline.aircrafts ac ON f.aircraft_id = ac.aircraft_id
LEFT JOIN airline.aircraft_types at2 ON ac.aircraft_type_id = at2.aircraft_type_id;

CREATE OR REPLACE VIEW airline.v_passenger_booking_summary AS
SELECT
    p.passenger_id,
    p.first_name || ' ' || p.last_name AS full_name,
    p.email,
    la.membership_number,
    la.tier AS loyalty_tier,
    la.available_miles,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    SUM(b.final_amount) AS total_spent,
    MAX(b.booking_date) AS last_booking_date
FROM airline.passengers p
LEFT JOIN airline.loyalty_accounts la ON p.passenger_id = la.passenger_id
LEFT JOIN airline.bookings b ON p.passenger_id = b.primary_passenger_id AND b.status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY p.passenger_id, p.first_name, p.last_name, p.email, la.membership_number, la.tier, la.available_miles;

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================
ALTER TABLE airline.passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE airline.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance.payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY passenger_self_access ON airline.passengers
    USING (passenger_id = current_setting('app.current_user_id', TRUE)::UUID);

CREATE POLICY booking_self_access ON airline.bookings
    USING (primary_passenger_id = current_setting('app.current_user_id', TRUE)::UUID);

-- =============================================================================
-- SEED: ESSENTIAL REFERENCE DATA (tidak diubah, hanya catatan bahwa MY seharusnya MYR, bukan IDR, tapi biarkan apa adanya)
-- =============================================================================
INSERT INTO finance.currencies VALUES
    ('IDR', 'Indonesian Rupiah', 'Rp', 0, TRUE, NOW()),
    ('USD', 'US Dollar', '$', 2, TRUE, NOW()),
    ('SGD', 'Singapore Dollar', 'S$', 2, TRUE, NOW()),
    ('AUD', 'Australian Dollar', 'A$', 2, TRUE, NOW()),
    ('EUR', 'Euro', '€', 2, TRUE, NOW()),
    ('JPY', 'Japanese Yen', '¥', 0, TRUE, NOW()),
    ('GBP', 'British Pound', '£', 2, TRUE, NOW());

INSERT INTO airline.countries (country_id, country_name, country_code_3, nationality, continent, phone_code, currency_code) VALUES
    ('ID', 'Indonesia', 'IDN', 'Indonesian', 'Asia', '+62', 'IDR'),
    ('SG', 'Singapore', 'SGP', 'Singaporean', 'Asia', '+65', 'SGD'),
    ('MY', 'Malaysia', 'MYS', 'Malaysian', 'Asia', '+60', 'IDR'), -- seharusnya MYR, tapi biarkan dulu
    ('AU', 'Australia', 'AUS', 'Australian', 'Oceania', '+61', 'AUD'),
    ('JP', 'Japan', 'JPN', 'Japanese', 'Asia', '+81', 'JPY'),
    ('US', 'United States', 'USA', 'American', 'North America', '+1', 'USD'),
    ('GB', 'United Kingdom', 'GBR', 'British', 'Europe', '+44', 'GBP');

-- =============================================================================
-- END OF v1.1 SCHEMA
-- =============================================================================
