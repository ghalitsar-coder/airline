-- =============================================================================
-- AIRLINE MANAGEMENT SYSTEM - SEED DATA FOR DEVELOPMENT
-- =============================================================================
-- Target: PostgreSQL 16 container with multiple databases
-- Prerequisite: Run after init-multiple-dbs.sh creates all databases
-- Instructions:
--   1. Copy this file to /docker-entrypoint-initdb.d/02_seed.sql inside the container
--   2. It will be executed automatically after database creation.
-- =============================================================================

-- Enable extensions for each database we'll use
\c passenger_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
\c inventory_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
\c flight_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
\c notif_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
\c booking_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
\c pricing_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
\c payment_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
\c loyalty_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
\c crew_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
\c maintenance_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- PASSENGER SERVICE DATABASE (passenger_db)
-- =============================================================================
\c passenger_db

-- DDL for reference tables (duplicated for development convenience)
CREATE TABLE IF NOT EXISTS currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    decimal_places SMALLINT NOT NULL DEFAULT 2,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS countries (
    country_id CHAR(2) PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    country_code_3 CHAR(3) NOT NULL UNIQUE,
    nationality VARCHAR(100),
    continent VARCHAR(50),
    phone_code VARCHAR(10),
    currency_code CHAR(3) REFERENCES currencies(currency_code),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Seed currencies
INSERT INTO currencies (currency_code, currency_name, symbol, decimal_places) VALUES
('IDR', 'Indonesian Rupiah', 'Rp', 0),
('USD', 'US Dollar', '$', 2),
('SGD', 'Singapore Dollar', 'S$', 2),
('AUD', 'Australian Dollar', 'A$', 2),
('EUR', 'Euro', '€', 2),
('JPY', 'Japanese Yen', '¥', 0),
('GBP', 'British Pound', '£', 2);

-- Seed countries
INSERT INTO countries (country_id, country_name, country_code_3, nationality, continent, phone_code, currency_code) VALUES
('ID', 'Indonesia', 'IDN', 'Indonesian', 'Asia', '+62', 'IDR'),
('SG', 'Singapore', 'SGP', 'Singaporean', 'Asia', '+65', 'SGD'),
('MY', 'Malaysia', 'MYS', 'Malaysian', 'Asia', '+60', 'IDR'),
('AU', 'Australia', 'AUS', 'Australian', 'Oceania', '+61', 'AUD'),
('JP', 'Japan', 'JPN', 'Japanese', 'Asia', '+81', 'JPY'),
('US', 'United States', 'USA', 'American', 'North America', '+1', 'USD'),
('GB', 'United Kingdom', 'GBR', 'British', 'Europe', '+44', 'GBP'),
('KR', 'South Korea', 'KOR', 'Korean', 'Asia', '+82', 'USD'),
('TH', 'Thailand', 'THA', 'Thai', 'Asia', '+66', 'USD'),
('SA', 'Saudi Arabia', 'SAU', 'Saudi', 'Middle East', '+966', 'USD');

-- DDL for application tables (simplified from original schema)
CREATE TABLE IF NOT EXISTS passengers (
    passenger_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20) NOT NULL DEFAULT 'PREFER_NOT_TO_SAY',
    nationality CHAR(2) REFERENCES countries(country_id),
    email VARCHAR(255),
    phone_number VARCHAR(30),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS passenger_documents (
    document_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID REFERENCES passengers(passenger_id),
    document_type VARCHAR(30) NOT NULL CHECK (document_type IN ('PASSPORT','NATIONAL_ID','DRIVING_LICENSE','VISA')),
    document_number VARCHAR(50) NOT NULL,
    issuing_country CHAR(2) REFERENCES countries(country_id),
    expiry_date DATE NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID REFERENCES passengers(passenger_id),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Insert 55 passengers with Indonesian names, various nationalities
INSERT INTO passengers (passenger_id, first_name, last_name, date_of_birth, gender, nationality, email, phone_number) VALUES
('b0000000-0000-0000-0000-000000000001', 'Ahmad', 'Santoso', '1985-03-15', 'MALE', 'ID', 'ahmad.s@email.com', '+62812345601'),
('b0000000-0000-0000-0000-000000000002', 'Dewi', 'Kartika', '1990-07-22', 'FEMALE', 'ID', 'dewi.k@email.com', '+62812345602'),
('b0000000-0000-0000-0000-000000000003', 'Budi', 'Hermawan', '1978-11-08', 'MALE', 'ID', 'budi.h@email.com', '+62812345603'),
('b0000000-0000-0000-0000-000000000004', 'Siti', 'Nurhaliza', '1992-01-12', 'FEMALE', 'MY', 'siti.n@email.com', '+60123456701'),
('b0000000-0000-0000-0000-000000000005', 'John', 'Doe', '1980-05-20', 'MALE', 'US', 'john.d@email.com', '+1234567890'),
('b0000000-0000-0000-0000-000000000006', 'Yuki', 'Tanaka', '1995-09-30', 'FEMALE', 'JP', 'yuki.t@email.com', '+81901234567'),
('b0000000-0000-0000-0000-000000000007', 'Rudi', 'Prakoso', '1988-06-17', 'MALE', 'ID', 'rudi.p@email.com', '+62812345604'),
('b0000000-0000-0000-0000-000000000008', 'Lina', 'Wijaya', '1993-12-05', 'FEMALE', 'ID', 'lina.w@email.com', '+62812345605'),
('b0000000-0000-0000-0000-000000000009', 'Agus', 'Saputra', '1982-08-25', 'MALE', 'ID', 'agus.s@email.com', '+62812345606'),
('b0000000-0000-0000-0000-000000000010', 'Mega', 'Putri', '1991-04-18', 'FEMALE', 'ID', 'mega.p@email.com', '+62812345607'),
('b0000000-0000-0000-0000-000000000011', 'Rina', 'Wati', '1989-10-01', 'FEMALE', 'ID', 'rina.w@email.com', '+62812345608'),
('b0000000-0000-0000-0000-000000000012', 'Adi', 'Nugroho', '1975-02-28', 'MALE', 'ID', 'adi.n@email.com', '+62812345609'),
('b0000000-0000-0000-0000-000000000013', 'Sri', 'Wahyuni', '1986-07-14', 'FEMALE', 'ID', 'sri.w@email.com', '+62812345610'),
('b0000000-0000-0000-0000-000000000014', 'Ferry', 'Irawan', '1994-11-19', 'MALE', 'ID', 'ferry.i@email.com', '+62812345611'),
('b0000000-0000-0000-0000-000000000015', 'Dian', 'Pertiwi', '1983-06-23', 'FEMALE', 'ID', 'dian.p@email.com', '+62812345612'),
('b0000000-0000-0000-0000-000000000016', 'Rendy', 'Kurniawan', '1990-09-09', 'MALE', 'ID', 'rendy.k@email.com', '+62812345613'),
('b0000000-0000-0000-0000-000000000017', 'Anita', 'Susanti', '1987-01-30', 'FEMALE', 'ID', 'anita.s@email.com', '+62812345614'),
('b0000000-0000-0000-0000-000000000018', 'David', 'Liem', '1976-12-12', 'MALE', 'SG', 'david.l@email.com', '+6587654321'),
('b0000000-0000-0000-0000-000000000019', 'Melisa', 'Tan', '1996-03-07', 'FEMALE', 'SG', 'melisa.t@email.com', '+6587654322'),
('b0000000-0000-0000-0000-000000000020', 'Hadi', 'Soesilo', '1981-08-17', 'MALE', 'ID', 'hadi.s@email.com', '+62812345615'),
('b0000000-0000-0000-0000-000000000021', 'Lutfi', 'Hakim', '1992-04-02', 'MALE', 'ID', 'lutfi.h@email.com', '+62812345616'),
('b0000000-0000-0000-0000-000000000022', 'Rizka', 'Amalia', '1984-10-10', 'FEMALE', 'ID', 'rizka.a@email.com', '+62812345617'),
('b0000000-0000-0000-0000-000000000023', 'Bima', 'Putra', '1998-05-25', 'MALE', 'ID', 'bima.p@email.com', '+62812345618'),
('b0000000-0000-0000-0000-000000000024', 'Nadia', 'Karim', '1980-02-14', 'FEMALE', 'MY', 'nadia.k@email.com', '+60123456702'),
('b0000000-0000-0000-0000-000000000025', 'Raden', 'Mas', '1973-11-11', 'MALE', 'ID', 'raden.m@email.com', '+62812345619'),
('b0000000-0000-0000-0000-000000000026', 'Ayu', 'Lestari', '1995-07-03', 'FEMALE', 'ID', 'ayu.l@email.com', '+62812345620'),
('b0000000-0000-0000-0000-000000000027', 'Gunawan', 'Wirawan', '1988-12-20', 'MALE', 'ID', 'gunawan.w@email.com', '+62812345621'),
('b0000000-0000-0000-0000-000000000028', 'Lisa', 'Kusuma', '1991-06-08', 'FEMALE', 'ID', 'lisa.k@email.com', '+62812345622'),
('b0000000-0000-0000-0000-000000000029', 'Ricky', 'Subagja', '1986-09-13', 'MALE', 'ID', 'ricky.s@email.com', '+62812345623'),
('b0000000-0000-0000-0000-000000000030', 'Eva', 'Rahmawati', '1993-01-29', 'FEMALE', 'ID', 'eva.r@email.com', '+62812345624'),
('b0000000-0000-0000-0000-000000000031', 'Toni', 'Setiawan', '1979-10-05', 'MALE', 'ID', 'toni.s@email.com', '+62812345625'),
('b0000000-0000-0000-0000-000000000032', 'Wulan', 'Guritno', '1997-03-18', 'FEMALE', 'ID', 'wulan.g@email.com', '+62812345626'),
('b0000000-0000-0000-0000-000000000033', 'Benny', 'Hartono', '1982-08-22', 'MALE', 'ID', 'benny.h@email.com', '+62812345627'),
('b0000000-0000-0000-0000-000000000034', 'Cindy', 'Lie', '1990-04-11', 'FEMALE', 'ID', 'cindy.l@email.com', '+62812345628'),
('b0000000-0000-0000-0000-000000000035', 'Oscar', 'Lopez', '1977-07-07', 'MALE', 'AU', 'oscar.l@email.com', '+61412345678'),
('b0000000-0000-0000-0000-000000000036', 'Karin', 'Svensson', '1994-12-24', 'FEMALE', 'US', 'karin.s@email.com', '+1234567891'),
('b0000000-0000-0000-0000-000000000037', 'Fajar', 'Utomo', '1989-05-16', 'MALE', 'ID', 'fajar.u@email.com', '+62812345629'),
('b0000000-0000-0000-0000-000000000038', 'Retno', 'Handayani', '1996-02-28', 'FEMALE', 'ID', 'retno.h@email.com', '+62812345630'),
('b0000000-0000-0000-0000-000000000039', 'Irfan', 'Bachdim', '1987-09-19', 'MALE', 'ID', 'irfan.b@email.com', '+62812345631'),
('b0000000-0000-0000-0000-000000000040', 'Mia', 'Puspita', '1991-11-30', 'FEMALE', 'ID', 'mia.p@email.com', '+62812345632'),
('b0000000-0000-0000-0000-000000000041', 'Hendra', 'Lesmana', '1984-01-05', 'MALE', 'ID', 'hendra.l@email.com', '+62812345633'),
('b0000000-0000-0000-0000-000000000042', 'Putri', 'Anggraini', '1998-06-22', 'FEMALE', 'ID', 'putri.a@email.com', '+62812345634'),
('b0000000-0000-0000-0000-000000000043', 'Dino', 'Pratiwi', '1983-03-14', 'MALE', 'ID', 'dino.p@email.com', '+62812345635'),
('b0000000-0000-0000-0000-000000000044', 'Sari', 'Dewi', '1992-08-27', 'FEMALE', 'ID', 'sari.d@email.com', '+62812345636'),
('b0000000-0000-0000-0000-000000000045', 'Kevin', 'Hansen', '1980-12-08', 'MALE', 'SG', 'kevin.h@email.com', '+6587654323'),
('b0000000-0000-0000-0000-000000000046', 'Lanny', 'Sugianto', '1995-04-03', 'FEMALE', 'ID', 'lanny.s@email.com', '+62812345637'),
('b0000000-0000-0000-0000-000000000047', 'Indra', 'Gunawan', '1981-07-25', 'MALE', 'ID', 'indra.g@email.com', '+62812345638'),
('b0000000-0000-0000-0000-000000000048', 'Tina', 'Melinda', '1990-10-31', 'FEMALE', 'ID', 'tina.m@email.com', '+62812345639'),
('b0000000-0000-0000-0000-000000000049', 'Bayu', 'Saputra', '1988-02-15', 'MALE', 'ID', 'bayu.s@email.com', '+62812345640'),
('b0000000-0000-0000-0000-000000000050', 'Rosa', 'Liana', '1993-09-10', 'FEMALE', 'ID', 'rosa.l@email.com', '+62812345641');

-- Add some passenger documents (passport for international flights)
INSERT INTO passenger_documents (passenger_id, document_type, document_number, issuing_country, expiry_date, is_primary, is_verified)
SELECT p.passenger_id, 'PASSPORT', CONCAT('P', SUBSTRING(p.passenger_id::text, 1, 8)), p.nationality, '2027-12-31', true, true
FROM passengers p WHERE p.nationality IN ('ID', 'SG', 'MY', 'US', 'JP', 'AU');

-- Create users for some passengers (password_hash dummy)
INSERT INTO users (passenger_id, username, email, password_hash)
SELECT passenger_id, email, email, '$2a$10$dummyhashfortestingpurposesonly'
FROM passengers WHERE email LIKE '%@email.com' LIMIT 20;

-- =============================================================================
-- INVENTORY SERVICE DATABASE (inventory_db)
-- =============================================================================
\c inventory_db

CREATE TABLE IF NOT EXISTS aircraft_types (
    aircraft_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    iata_type_code VARCHAR(10) UNIQUE NOT NULL,
    manufacturer VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    max_seats INT NOT NULL
);

CREATE TABLE IF NOT EXISTS aircrafts (
    aircraft_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aircraft_type_id UUID REFERENCES aircraft_types(aircraft_type_id),
    registration_number VARCHAR(20) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
);

CREATE TABLE IF NOT EXISTS cabin_configurations (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aircraft_type_id UUID REFERENCES aircraft_types(aircraft_type_id),
    seat_class VARCHAR(20) NOT NULL,
    total_seats INT NOT NULL,
    rows_start INT NOT NULL,
    rows_end INT NOT NULL,
    seats_per_row INT NOT NULL
);

CREATE TABLE IF NOT EXISTS aircraft_config_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aircraft_id UUID REFERENCES aircrafts(aircraft_id),
    config_id UUID REFERENCES cabin_configurations(config_id),
    effective_from TIMESTAMPTZ NOT NULL,
    effective_until TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS seats (
    seat_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aircraft_id UUID REFERENCES aircrafts(aircraft_id),
    seat_number VARCHAR(5) NOT NULL,
    seat_row INT NOT NULL,
    seat_letter CHAR(1) NOT NULL,
    seat_class VARCHAR(20) NOT NULL,
    is_window BOOLEAN NOT NULL DEFAULT FALSE,
    is_aisle BOOLEAN NOT NULL DEFAULT FALSE,
    is_exit_row BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (aircraft_id, seat_number)
);

CREATE TABLE IF NOT EXISTS seat_reservations (
    reservation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flight_id UUID, -- will be referenced from flight_db but dummy for dev
    seat_id UUID REFERENCES seats(seat_id),
    status VARCHAR(20) NOT NULL DEFAULT 'RESERVED',
    reserved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- Aircraft types
INSERT INTO aircraft_types (aircraft_type_id, iata_type_code, manufacturer, model, max_seats) VALUES
('a1000000-0000-0000-0000-000000000001', '738', 'Boeing', '737-800', 162),
('a1000000-0000-0000-0000-000000000002', '320', 'Airbus', 'A320-200', 156),
('a1000000-0000-0000-0000-000000000003', '333', 'Airbus', 'A330-300', 296);

-- Aircrafts fleet
INSERT INTO aircrafts (aircraft_id, aircraft_type_id, registration_number, status) VALUES
('a2000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'PK-NAA', 'ACTIVE'),
('a2000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'PK-NAB', 'ACTIVE'),
('a2000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'PK-NAC', 'ACTIVE'),
('a2000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 'PK-NAD', 'MAINTENANCE'),
('a2000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000003', 'PK-NAE', 'ACTIVE');

-- Cabin configurations (simplified)
INSERT INTO cabin_configurations (config_id, aircraft_type_id, seat_class, total_seats, rows_start, rows_end, seats_per_row) VALUES
-- 737-800 Economy
('c1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'ECONOMY', 144, 1, 24, 6),
-- 737-800 Business
('c1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'BUSINESS', 18, 1, 3, 4),
-- A320 Economy
('c1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'ECONOMY', 138, 1, 23, 6),
-- A320 Business
('c1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 'BUSINESS', 12, 1, 2, 4),
-- A330 Economy
('c1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000003', 'ECONOMY', 260, 10, 49, 8),
-- A330 Business
('c1000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000003', 'BUSINESS', 36, 1, 9, 4);

-- Assign configs to aircraft (simplified: each aircraft gets all its type configs)
INSERT INTO aircraft_config_assignments (aircraft_id, config_id, effective_from)
SELECT ac.aircraft_id, cc.config_id, NOW()
FROM aircrafts ac JOIN cabin_configurations cc ON ac.aircraft_type_id = cc.aircraft_type_id;

-- Generate seats for each aircraft based on config (using plpgsql)
DO $$
DECLARE
    rec RECORD;
    r INT;
    c CHAR;
    seat_class TEXT;
BEGIN
    FOR rec IN
        SELECT s.aircraft_id, cfg.rows_start, cfg.rows_end, cfg.seats_per_row, cfg.seat_class
        FROM aircrafts s
        JOIN aircraft_config_assignments aca ON s.aircraft_id = aca.aircraft_id
        JOIN cabin_configurations cfg ON aca.config_id = cfg.config_id
    LOOP
        FOR r IN rec.rows_start..rec.rows_end LOOP
            FOR c IN SELECT chr(ascii('A') + i) FROM generate_series(0, rec.seats_per_row-1) AS i LOOP
                -- Determine window/aisle/middle
                INSERT INTO seats (aircraft_id, seat_number, seat_row, seat_letter, seat_class, is_window, is_aisle)
                VALUES (
                    rec.aircraft_id,
                    r || c,
                    r,
                    c,
                    rec.seat_class,
                    c = 'A' OR c = chr(ascii('A') + rec.seats_per_row - 1),
                    c = 'C' OR c = 'D'
                );
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- Add some seat reservations (dummy, will reference flights later)
INSERT INTO seat_reservations (flight_id, seat_id, status, reserved_at, expires_at)
SELECT 'f0000000-0000-0000-0000-000000000001'::UUID, seat_id, 'RESERVED', NOW(), NOW() + INTERVAL '10 minutes'
FROM seats WHERE seat_row = 12 AND seat_letter = 'A' AND aircraft_id = 'a2000000-0000-0000-0000-000000000001';

-- =============================================================================
-- FLIGHT OPS SERVICE DATABASE (flight_db)
-- =============================================================================
\c flight_db

CREATE TABLE IF NOT EXISTS currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL
);
INSERT INTO currencies VALUES ('IDR','Indonesian Rupiah','Rp'),('USD','US Dollar','$'),('SGD','Singapore Dollar','S$');

CREATE TABLE IF NOT EXISTS countries (
    country_id CHAR(2) PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    currency_code CHAR(3) REFERENCES currencies(currency_code)
);
INSERT INTO countries VALUES ('ID','Indonesia','IDR'),('SG','Singapore','SGD'),('MY','Malaysia','IDR'),('JP','Japan','USD'),('AU','Australia','AUD'),('US','USA','USD');

CREATE TABLE IF NOT EXISTS airports (
    airport_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    iata_code CHAR(3) UNIQUE NOT NULL,
    airport_name VARCHAR(200) NOT NULL,
    city VARCHAR(100),
    country_id CHAR(2) REFERENCES countries(country_id),
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,
    timezone VARCHAR(50)
);

INSERT INTO airports (airport_id, iata_code, airport_name, city, country_id, latitude, longitude, timezone) VALUES
('ap000001-0000-0000-0000-000000000001', 'CGK', 'Soekarno-Hatta International', 'Jakarta', 'ID', -6.1256, 106.6559, 'Asia/Jakarta'),
('ap000001-0000-0000-0000-000000000002', 'DPS', 'Ngurah Rai International', 'Denpasar', 'ID', -8.7482, 115.1675, 'Asia/Makassar'),
('ap000001-0000-0000-0000-000000000003', 'SUB', 'Juanda International', 'Surabaya', 'ID', -7.3798, 112.7866, 'Asia/Jakarta'),
('ap000001-0000-0000-0000-000000000004', 'SIN', 'Changi Airport', 'Singapore', 'SG', 1.3644, 103.9915, 'Asia/Singapore'),
('ap000001-0000-0000-0000-000000000005', 'KUL', 'Kuala Lumpur International', 'Kuala Lumpur', 'MY', 2.7557, 101.7047, 'Asia/Kuala_Lumpur'),
('ap000001-0000-0000-0000-000000000006', 'NRT', 'Narita International', 'Tokyo', 'JP', 35.7720, 140.3929, 'Asia/Tokyo'),
('ap000001-0000-0000-0000-000000000007', 'SYD', 'Sydney Airport', 'Sydney', 'AU', -33.9399, 151.1753, 'Australia/Sydney'),
('ap000001-0000-0000-0000-000000000008', 'LAX', 'Los Angeles International', 'Los Angeles', 'US', 33.9416, -118.4085, 'America/Los_Angeles');

CREATE TABLE IF NOT EXISTS terminals (
    terminal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    airport_id UUID REFERENCES airports(airport_id),
    terminal_code VARCHAR(10) NOT NULL,
    UNIQUE(airport_id, terminal_code)
);
INSERT INTO terminals (airport_id, terminal_code) VALUES
('ap000001-0000-0000-0000-000000000001','1A'),('ap000001-0000-0000-0000-000000000001','1B'),
('ap000001-0000-0000-0000-000000000002','D'),('ap000001-0000-0000-0000-000000000004','T1');

CREATE TABLE IF NOT EXISTS gates (
    gate_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    terminal_id UUID REFERENCES terminals(terminal_id),
    gate_code VARCHAR(10) NOT NULL,
    UNIQUE(terminal_id, gate_code)
);
-- Add some gates
INSERT INTO gates (terminal_id, gate_code) SELECT terminal_id, 'G1' FROM terminals UNION ALL SELECT terminal_id, 'G2' FROM terminals;

CREATE TABLE IF NOT EXISTS routes (
    route_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    origin_airport_id UUID REFERENCES airports(airport_id),
    destination_airport_id UUID REFERENCES airports(airport_id),
    distance_km DECIMAL(8,2),
    flight_duration_min INT,
    UNIQUE(origin_airport_id, destination_airport_id)
);
INSERT INTO routes (route_id, origin_airport_id, destination_airport_id, distance_km, flight_duration_min) VALUES
('r1000000-0000-0000-0000-000000000001', 'ap000001-0000-0000-0000-000000000001', 'ap000001-0000-0000-0000-000000000002', 980, 115),
('r1000000-0000-0000-0000-000000000002', 'ap000001-0000-0000-0000-000000000001', 'ap000001-0000-0000-0000-000000000003', 690, 90),
('r1000000-0000-0000-0000-000000000003', 'ap000001-0000-0000-0000-000000000001', 'ap000001-0000-0000-0000-000000000004', 900, 105),
('r1000000-0000-0000-0000-000000000004', 'ap000001-0000-0000-0000-000000000001', 'ap000001-0000-0000-0000-000000000005', 1180, 135),
('r1000000-0000-0000-0000-000000000005', 'ap000001-0000-0000-0000-000000000001', 'ap000001-0000-0000-0000-000000000006', 5500, 420);

CREATE TABLE IF NOT EXISTS flights (
    flight_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flight_number VARCHAR(10) NOT NULL,
    route_id UUID REFERENCES routes(route_id),
    aircraft_id UUID, -- from inventory_db but no FK
    scheduled_departure TIMESTAMPTZ NOT NULL,
    scheduled_arrival TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED'
);

-- Insert flights for the next few days
INSERT INTO flights (flight_id, flight_number, route_id, aircraft_id, scheduled_departure, scheduled_arrival, status) VALUES
('f0000000-0000-0000-0000-000000000001', 'NA101', 'r1000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', '2025-05-01 06:00:00+07', '2025-05-01 08:00:00+08', 'SCHEDULED'),
('f0000000-0000-0000-0000-000000000002', 'NA102', 'r1000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000002', '2025-05-01 07:00:00+07', '2025-05-01 08:30:00+07', 'SCHEDULED'),
('f0000000-0000-0000-0000-000000000003', 'NA103', 'r1000000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000003', '2025-05-01 09:00:00+07', '2025-05-01 11:45:00+08', 'BOARDING'),
('f0000000-0000-0000-0000-000000000004', 'NA104', 'r1000000-0000-0000-0000-000000000004', 'a2000000-0000-0000-0000-000000000005', '2025-05-02 14:00:00+07', '2025-05-02 16:15:00+08', 'SCHEDULED'),
('f0000000-0000-0000-0000-000000000005', 'NA105', 'r1000000-0000-0000-0000-000000000005', 'a2000000-0000-0000-0000-000000000005', '2025-05-03 22:00:00+07', '2025-05-04 07:00:00+09', 'SCHEDULED');

-- =============================================================================
-- PRICING SERVICE DATABASE (pricing_db)
-- =============================================================================
\c pricing_db

CREATE TABLE IF NOT EXISTS currencies ( LIKE passenger_db.currencies INCLUDING ALL );
INSERT INTO currencies SELECT * FROM passenger_db.currencies;

CREATE TABLE IF NOT EXISTS flight_prices (
    price_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flight_id UUID NOT NULL, -- reference to flight_db
    seat_class VARCHAR(20) NOT NULL,
    fare_basis VARCHAR(20) NOT NULL,
    base_price DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency_code CHAR(3) REFERENCES currencies(currency_code) DEFAULT 'IDR',
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS promotions (
    promotion_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promo_code VARCHAR(50) UNIQUE NOT NULL,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('PERCENTAGE','FIXED')),
    discount_value DECIMAL(10,2) NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL,
    valid_until TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS tax_configurations (
    tax_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tax_name VARCHAR(100) NOT NULL,
    tax_percentage DECIMAL(5,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- Insert some prices
INSERT INTO flight_prices (flight_id, seat_class, fare_basis, base_price, tax_amount, valid_until) VALUES
('f0000000-0000-0000-0000-000000000001', 'ECONOMY', 'Y', 850000, 93500, '2025-04-30 23:59:59+07'),
('f0000000-0000-0000-0000-000000000001', 'ECONOMY', 'B', 1200000, 132000, '2025-04-30 23:59:59+07'),
('f0000000-0000-0000-0000-000000000001', 'BUSINESS', 'C', 2500000, 275000, '2025-04-30 23:59:59+07'),
('f0000000-0000-0000-0000-000000000003', 'ECONOMY', 'Y', 950000, 104500, '2025-04-30 23:59:59+07'),
('f0000000-0000-0000-0000-000000000005', 'BUSINESS', 'C', 4500000, 495000, '2025-05-03 23:59:59+07');

-- Insert promotions
INSERT INTO promotions (promo_code, discount_type, discount_value, valid_from, valid_until) VALUES
('EARLYBIRD10', 'PERCENTAGE', 10, '2025-01-01', '2025-06-30'),
('FLASH50', 'FIXED', 50000, '2025-04-01', '2025-04-30');

-- Tax config
INSERT INTO tax_configurations (tax_name, tax_percentage) VALUES ('PPN', 11), ('PJKP2U', 5);

-- =============================================================================
-- BOOKING SERVICE DATABASE (booking_db)
-- =============================================================================
\c booking_db

CREATE TABLE IF NOT EXISTS bookings (
    booking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_reference VARCHAR(10) UNIQUE NOT NULL,
    primary_passenger_id UUID NOT NULL, -- passenger_db reference
    booking_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total_amount DECIMAL(14,2),
    currency_code CHAR(3) DEFAULT 'IDR'
);

CREATE TABLE IF NOT EXISTS booking_passengers (
    booking_passenger_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(booking_id),
    passenger_id UUID NOT NULL,
    passenger_type VARCHAR(20) NOT NULL DEFAULT 'ADULT',
    first_name VARCHAR(100),
    last_name VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS booking_segments (
    segment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(booking_id),
    booking_passenger_id UUID REFERENCES booking_passengers(booking_passenger_id),
    flight_id UUID NOT NULL,
    price_id UUID, -- pricing_db reference
    seat_id UUID, -- inventory_db reference
    seat_class VARCHAR(20),
    status VARCHAR(20) DEFAULT 'CONFIRMED'
);

-- Insert sample bookings (correlate with passengers and flights)
-- Booking 1: Ahmad Santoso, flight NA101
INSERT INTO bookings (booking_reference, primary_passenger_id, status, total_amount) VALUES
('NA1234', 'b0000000-0000-0000-0000-000000000001', 'CONFIRMED', 943500);

INSERT INTO booking_passengers (booking_id, passenger_id, passenger_type, first_name, last_name)
SELECT b.booking_id, p.passenger_id, 'ADULT', p.first_name, p.last_name
FROM bookings b, passenger_db.passengers p
WHERE b.booking_reference = 'NA1234' AND p.passenger_id = 'b0000000-0000-0000-0000-000000000001';

INSERT INTO booking_segments (booking_id, booking_passenger_id, flight_id, price_id, seat_id, seat_class, status)
SELECT b.booking_id, bp.booking_passenger_id, 'f0000000-0000-0000-0000-000000000001',
       (SELECT price_id FROM pricing_db.flight_prices WHERE flight_id = 'f0000000-0000-0000-0000-000000000001' AND fare_basis = 'Y'),
       (SELECT seat_id FROM inventory_db.seats WHERE aircraft_id = 'a2000000-0000-0000-0000-000000000001' AND seat_number = '12A'),
       'ECONOMY', 'CONFIRMED'
FROM bookings b JOIN booking_passengers bp ON b.booking_id = bp.booking_id
WHERE b.booking_reference = 'NA1234';

-- More bookings can be added similarly. For brevity, only one full example.

-- =============================================================================
-- PAYMENT SERVICE DATABASE (payment_db)
-- =============================================================================
\c payment_db
CREATE TABLE IF NOT EXISTS payments (
    payment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL,
    payment_method VARCHAR(30),
    payment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    amount DECIMAL(14,2),
    currency_code CHAR(3)
);
INSERT INTO payments (booking_id, payment_method, payment_status, amount, currency_code)
SELECT b.booking_id, 'CREDIT_CARD', 'COMPLETED', b.total_amount, 'IDR'
FROM booking_db.bookings b WHERE b.booking_reference = 'NA1234';

-- =============================================================================
-- LOYALTY SERVICE DATABASE (loyalty_db)
-- =============================================================================
\c loyalty_db
CREATE TABLE IF NOT EXISTS loyalty_accounts (
    loyalty_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID NOT NULL,
    membership_number VARCHAR(20) UNIQUE NOT NULL,
    tier VARCHAR(20) NOT NULL DEFAULT 'BASIC',
    available_miles DECIMAL(14,2) DEFAULT 0
);
INSERT INTO loyalty_accounts (passenger_id, membership_number, tier, available_miles)
SELECT passenger_id, CONCAT('NA-', SUBSTRING(passenger_id::text, 1, 8)), 'BLUE', 5000
FROM passenger_db.passengers WHERE email LIKE '%@email.com' LIMIT 30;

-- =============================================================================
-- CREW SERVICE DATABASE (crew_db)
-- =============================================================================
\c crew_db
CREATE TABLE IF NOT EXISTS employees (
    employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255)
);
INSERT INTO employees (employee_id, first_name, last_name, email) VALUES
('e0000000-0000-0000-0000-000000000001', 'Capt. Andi', 'Wirawan', 'andi.w@airline.com'),
('e0000000-0000-0000-0000-000000000002', 'FO Budi', 'Santoso', 'budi.s@airline.com'),
('e0000000-0000-0000-0000-000000000003', 'Purser Rina', 'Marlina', 'rina.m@airline.com');

-- =============================================================================
-- MAINTENANCE SERVICE DATABASE (maintenance_db)
-- =============================================================================
\c maintenance_db
CREATE TABLE IF NOT EXISTS maintenance_records (
    maintenance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aircraft_id UUID NOT NULL,
    status VARCHAR(30) DEFAULT 'PLANNED'
);
INSERT INTO maintenance_records (aircraft_id, status) VALUES
('a2000000-0000-0000-0000-000000000004', 'IN_PROGRESS');

-- =============================================================================
-- NOTIFICATION SERVICE DATABASE (notif_db)
-- =============================================================================
\c notif_db
CREATE TABLE IF NOT EXISTS notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID,
    channel VARCHAR(20),
    template_code VARCHAR(50),
    body TEXT,
    status VARCHAR(20) DEFAULT 'PENDING'
);
INSERT INTO notifications (passenger_id, channel, template_code, body, status)
SELECT passenger_id, 'EMAIL', 'booking-confirmation', 'Your booking NA1234 is confirmed.', 'SENT'
FROM passenger_db.passengers WHERE email = 'ahmad.s@email.com';