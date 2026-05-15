-- =============================================================================
-- AIRLINE MANAGEMENT SYSTEM - Microservice Database Initialization
-- =============================================================================
-- File ini membuat tabel dan mengisi seed data untuk setiap service database.
-- Dijalankan setelah init-multiple-dbs.sh.
-- =============================================================================

-- =============================================================================
-- PASSENGER SERVICE (passenger_db)
-- =============================================================================
\c passenger_db

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE gender_type AS ENUM ('MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY');
CREATE TYPE document_type AS ENUM ('PASSPORT', 'NATIONAL_ID', 'DRIVING_LICENSE', 'VISA');

CREATE TABLE currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    decimal_places SMALLINT NOT NULL DEFAULT 2
);

CREATE TABLE countries (
    country_id CHAR(2) PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    country_code_3 CHAR(3) UNIQUE NOT NULL,
    nationality VARCHAR(100),
    continent VARCHAR(50),
    phone_code VARCHAR(10),
    currency_code CHAR(3) REFERENCES currencies(currency_code)
);

CREATE TABLE passengers (
    passenger_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender gender_type NOT NULL,
    nationality CHAR(2) REFERENCES countries(country_id),
    email VARCHAR(255),
    phone_number VARCHAR(30),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE passenger_documents (
    document_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID REFERENCES passengers(passenger_id),
    document_type document_type NOT NULL,
    document_number VARCHAR(50) NOT NULL,
    issuing_country CHAR(2) REFERENCES countries(country_id),
    expiry_date DATE NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID REFERENCES passengers(passenger_id),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Seed data
INSERT INTO currencies VALUES
('IDR', 'Indonesian Rupiah', 'Rp', 0),
('USD', 'US Dollar', '$', 2),
('SGD', 'Singapore Dollar', 'S$', 2),
('AUD', 'Australian Dollar', 'A$', 2),
('JPY', 'Japanese Yen', '¥', 0),
('GBP', 'British Pound', '£', 2);

INSERT INTO countries VALUES
('ID', 'Indonesia', 'IDN', 'Indonesian', 'Asia', '+62', 'IDR'),
('SG', 'Singapore', 'SGP', 'Singaporean', 'Asia', '+65', 'SGD'),
('MY', 'Malaysia', 'MYS', 'Malaysian', 'Asia', '+60', 'IDR'),
('AU', 'Australia', 'AUS', 'Australian', 'Oceania', '+61', 'AUD'),
('JP', 'Japan', 'JPN', 'Japanese', 'Asia', '+81', 'JPY'),
('US', 'United States', 'USA', 'American', 'North America', '+1', 'USD'),
('GB', 'United Kingdom', 'GBR', 'British', 'Europe', '+44', 'GBP');

-- 50 passengers
INSERT INTO passengers (passenger_id, first_name, last_name, date_of_birth, gender, nationality, email) VALUES
('b0000000-0000-0000-0000-000000000001', 'Ahmad', 'Santoso', '1985-03-15', 'MALE', 'ID', 'ahmad.s@email.com'),
('b0000000-0000-0000-0000-000000000002', 'Dewi', 'Kartika', '1990-07-22', 'FEMALE', 'ID', 'dewi.k@email.com'),
('b0000000-0000-0000-0000-000000000003', 'Budi', 'Hermawan', '1978-11-08', 'MALE', 'ID', 'budi.h@email.com'),
('b0000000-0000-0000-0000-000000000004', 'Siti', 'Nurhaliza', '1992-01-12', 'FEMALE', 'MY', 'siti.n@email.com'),
('b0000000-0000-0000-0000-000000000005', 'John', 'Doe', '1980-05-20', 'MALE', 'US', 'john.d@email.com'),
('b0000000-0000-0000-0000-000000000006', 'Yuki', 'Tanaka', '1995-09-30', 'FEMALE', 'JP', 'yuki.t@email.com'),
('b0000000-0000-0000-0000-000000000007', 'Rudi', 'Prakoso', '1988-06-17', 'MALE', 'ID', 'rudi.p@email.com'),
('b0000000-0000-0000-0000-000000000008', 'Lina', 'Wijaya', '1993-12-05', 'FEMALE', 'ID', 'lina.w@email.com'),
('b0000000-0000-0000-0000-000000000009', 'Agus', 'Saputra', '1982-08-25', 'MALE', 'ID', 'agus.s@email.com'),
('b0000000-0000-0000-0000-000000000010', 'Mega', 'Putri', '1991-04-18', 'FEMALE', 'ID', 'mega.p@email.com'),
('b0000000-0000-0000-0000-000000000011', 'Rina', 'Wati', '1989-10-01', 'FEMALE', 'ID', 'rina.w@email.com'),
('b0000000-0000-0000-0000-000000000012', 'Adi', 'Nugroho', '1975-02-28', 'MALE', 'ID', 'adi.n@email.com'),
('b0000000-0000-0000-0000-000000000013', 'Sri', 'Wahyuni', '1986-07-14', 'FEMALE', 'ID', 'sri.w@email.com'),
('b0000000-0000-0000-0000-000000000014', 'Ferry', 'Irawan', '1994-11-19', 'MALE', 'ID', 'ferry.i@email.com'),
('b0000000-0000-0000-0000-000000000015', 'Dian', 'Pertiwi', '1983-06-23', 'FEMALE', 'ID', 'dian.p@email.com'),
('b0000000-0000-0000-0000-000000000016', 'Rendy', 'Kurniawan', '1990-09-09', 'MALE', 'ID', 'rendy.k@email.com'),
('b0000000-0000-0000-0000-000000000017', 'Anita', 'Susanti', '1987-01-30', 'FEMALE', 'ID', 'anita.s@email.com'),
('b0000000-0000-0000-0000-000000000018', 'David', 'Liem', '1976-12-12', 'MALE', 'SG', 'david.l@email.com'),
('b0000000-0000-0000-0000-000000000019', 'Melisa', 'Tan', '1996-03-07', 'FEMALE', 'SG', 'melisa.t@email.com'),
('b0000000-0000-0000-0000-000000000020', 'Hadi', 'Soesilo', '1981-08-17', 'MALE', 'ID', 'hadi.s@email.com'),
('b0000000-0000-0000-0000-000000000021', 'Lutfi', 'Hakim', '1992-04-02', 'MALE', 'ID', 'lutfi.h@email.com'),
('b0000000-0000-0000-0000-000000000022', 'Rizka', 'Amalia', '1984-10-10', 'FEMALE', 'ID', 'rizka.a@email.com'),
('b0000000-0000-0000-0000-000000000023', 'Bima', 'Putra', '1998-05-25', 'MALE', 'ID', 'bima.p@email.com'),
('b0000000-0000-0000-0000-000000000024', 'Nadia', 'Karim', '1980-02-14', 'FEMALE', 'MY', 'nadia.k@email.com'),
('b0000000-0000-0000-0000-000000000025', 'Raden', 'Mas', '1973-11-11', 'MALE', 'ID', 'raden.m@email.com'),
('b0000000-0000-0000-0000-000000000026', 'Ayu', 'Lestari', '1995-07-03', 'FEMALE', 'ID', 'ayu.l@email.com'),
('b0000000-0000-0000-0000-000000000027', 'Gunawan', 'Wirawan', '1988-12-20', 'MALE', 'ID', 'gunawan.w@email.com'),
('b0000000-0000-0000-0000-000000000028', 'Lisa', 'Kusuma', '1991-06-08', 'FEMALE', 'ID', 'lisa.k@email.com'),
('b0000000-0000-0000-0000-000000000029', 'Ricky', 'Subagja', '1986-09-13', 'MALE', 'ID', 'ricky.s@email.com'),
('b0000000-0000-0000-0000-000000000030', 'Eva', 'Rahmawati', '1993-01-29', 'FEMALE', 'ID', 'eva.r@email.com'),
('b0000000-0000-0000-0000-000000000031', 'Toni', 'Setiawan', '1979-10-05', 'MALE', 'ID', 'toni.s@email.com'),
('b0000000-0000-0000-0000-000000000032', 'Wulan', 'Guritno', '1997-03-18', 'FEMALE', 'ID', 'wulan.g@email.com'),
('b0000000-0000-0000-0000-000000000033', 'Benny', 'Hartono', '1982-08-22', 'MALE', 'ID', 'benny.h@email.com'),
('b0000000-0000-0000-0000-000000000034', 'Cindy', 'Lie', '1990-04-11', 'FEMALE', 'ID', 'cindy.l@email.com'),
('b0000000-0000-0000-0000-000000000035', 'Oscar', 'Lopez', '1977-07-07', 'MALE', 'AU', 'oscar.l@email.com'),
('b0000000-0000-0000-0000-000000000036', 'Karin', 'Svensson', '1994-12-24', 'FEMALE', 'US', 'karin.s@email.com'),
('b0000000-0000-0000-0000-000000000037', 'Fajar', 'Utomo', '1989-05-16', 'MALE', 'ID', 'fajar.u@email.com'),
('b0000000-0000-0000-0000-000000000038', 'Retno', 'Handayani', '1996-02-28', 'FEMALE', 'ID', 'retno.h@email.com'),
('b0000000-0000-0000-0000-000000000039', 'Irfan', 'Bachdim', '1987-09-19', 'MALE', 'ID', 'irfan.b@email.com'),
('b0000000-0000-0000-0000-000000000040', 'Mia', 'Puspita', '1991-11-30', 'FEMALE', 'ID', 'mia.p@email.com'),
('b0000000-0000-0000-0000-000000000041', 'Hendra', 'Lesmana', '1984-01-05', 'MALE', 'ID', 'hendra.l@email.com'),
('b0000000-0000-0000-0000-000000000042', 'Putri', 'Anggraini', '1998-06-22', 'FEMALE', 'ID', 'putri.a@email.com'),
('b0000000-0000-0000-0000-000000000043', 'Dino', 'Pratiwi', '1983-03-14', 'MALE', 'ID', 'dino.p@email.com'),
('b0000000-0000-0000-0000-000000000044', 'Sari', 'Dewi', '1992-08-27', 'FEMALE', 'ID', 'sari.d@email.com'),
('b0000000-0000-0000-0000-000000000045', 'Kevin', 'Hansen', '1980-12-08', 'MALE', 'SG', 'kevin.h@email.com'),
('b0000000-0000-0000-0000-000000000046', 'Lanny', 'Sugianto', '1995-04-03', 'FEMALE', 'ID', 'lanny.s@email.com'),
('b0000000-0000-0000-0000-000000000047', 'Indra', 'Gunawan', '1981-07-25', 'MALE', 'ID', 'indra.g@email.com'),
('b0000000-0000-0000-0000-000000000048', 'Tina', 'Melinda', '1990-10-31', 'FEMALE', 'ID', 'tina.m@email.com'),
('b0000000-0000-0000-0000-000000000049', 'Bayu', 'Saputra', '1988-02-15', 'MALE', 'ID', 'bayu.s@email.com'),
('b0000000-0000-0000-0000-000000000050', 'Rosa', 'Liana', '1993-09-10', 'FEMALE', 'ID', 'rosa.l@email.com');

-- 50 passport documents
INSERT INTO passenger_documents (passenger_id, document_type, document_number, issuing_country, expiry_date, is_primary)
SELECT passenger_id, 'PASSPORT', CONCAT('PP', SUBSTRING(passenger_id::text, 1, 8)), nationality, '2027-12-31', true
FROM passengers;

-- 20 users
INSERT INTO users (passenger_id, username, email, password_hash)
SELECT passenger_id, email, email, '$2a$10$dummy'
FROM passengers LIMIT 20;

-- =============================================================================
-- INVENTORY SERVICE (inventory_db)
-- =============================================================================
\c inventory_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE aircraft_types (
    aircraft_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    iata_type_code VARCHAR(10) UNIQUE NOT NULL,
    manufacturer VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    max_seats INT NOT NULL
);

CREATE TABLE aircrafts (
    aircraft_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aircraft_type_id UUID REFERENCES aircraft_types(aircraft_type_id),
    registration_number VARCHAR(20) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
);

CREATE TABLE cabin_configurations (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aircraft_type_id UUID REFERENCES aircraft_types(aircraft_type_id),
    seat_class VARCHAR(20) NOT NULL,
    total_seats INT NOT NULL,
    rows_start INT NOT NULL,
    rows_end INT NOT NULL,
    seats_per_row INT NOT NULL
);

CREATE TABLE aircraft_config_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aircraft_id UUID REFERENCES aircrafts(aircraft_id),
    config_id UUID REFERENCES cabin_configurations(config_id),
    effective_from TIMESTAMPTZ NOT NULL,
    effective_until TIMESTAMPTZ
);

CREATE TABLE seats (
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

CREATE TABLE seat_reservations (
    reservation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flight_id UUID, -- without FK
    seat_id UUID REFERENCES seats(seat_id),
    status VARCHAR(20) NOT NULL DEFAULT 'RESERVED',
    reserved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- Aircraft types
INSERT INTO aircraft_types VALUES
('a1000000-0000-0000-0000-000000000001', '738', 'Boeing', '737-800', 162),
('a1000000-0000-0000-0000-000000000002', '320', 'Airbus', 'A320-200', 156),
('a1000000-0000-0000-0000-000000000003', '333', 'Airbus', 'A330-300', 296);

-- Aircrafts
INSERT INTO aircrafts VALUES
('a2000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'PK-NAA', 'ACTIVE'),
('a2000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'PK-NAB', 'ACTIVE'),
('a2000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'PK-NAC', 'ACTIVE'),
('a2000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 'PK-NAD', 'MAINTENANCE'),
('a2000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000003', 'PK-NAE', 'ACTIVE');

-- Cabin configs
INSERT INTO cabin_configurations VALUES
('c1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'ECONOMY', 144, 1, 24, 6),
('c1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'BUSINESS', 18, 1, 3, 4),
('c1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'ECONOMY', 138, 1, 23, 6),
('c1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 'BUSINESS', 12, 1, 2, 4),
('c1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000003', 'ECONOMY', 260, 10, 49, 8),
('c1000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000003', 'BUSINESS', 36, 1, 9, 4);

-- Assign configs to aircrafts
INSERT INTO aircraft_config_assignments (aircraft_id, config_id, effective_from)
SELECT ac.aircraft_id, cc.config_id, NOW()
FROM aircrafts ac JOIN cabin_configurations cc ON ac.aircraft_type_id = cc.aircraft_type_id;

-- Generate seats (simplified, representative)
DO $$
DECLARE
    rec RECORD;
    r INT;
    c CHAR;
BEGIN
    FOR rec IN
        -- Gunakan DISTINCT untuk mencegah duplikasi sumber data loop
        SELECT DISTINCT ac.aircraft_id, cfg.rows_start, cfg.rows_end, cfg.seats_per_row, cfg.seat_class
        FROM aircrafts ac
        JOIN aircraft_config_assignments aca ON ac.aircraft_id = aca.aircraft_id
        JOIN cabin_configurations cfg ON aca.config_id = cfg.config_id
    LOOP
        FOR r IN rec.rows_start..rec.rows_end LOOP
            FOR c IN SELECT chr(ascii('A') + i) FROM generate_series(0, rec.seats_per_row-1) AS i LOOP
                -- Tambahkan pengaman ekstra
                INSERT INTO seats (aircraft_id, seat_number, seat_row, seat_letter, seat_class, is_window, is_aisle)
                VALUES (
                    rec.aircraft_id,
                    r || c,
                    r,
                    c,
                    rec.seat_class,
                    c = 'A' OR c = chr(ascii('A') + rec.seats_per_row - 1),
                    c = 'C' OR c = 'D'
                ) ON CONFLICT ON CONSTRAINT seats_aircraft_id_seat_number_key DO NOTHING; 
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- 5 dummy seat reservations
INSERT INTO seat_reservations (flight_id, seat_id, status, reserved_at, expires_at)
SELECT 'f0000000-0000-0000-0000-000000000001', seat_id, 'RESERVED', NOW(), NOW() + INTERVAL '10 minutes'
FROM seats WHERE seat_row = 12 AND seat_letter IN ('A','B') AND aircraft_id = 'a2000000-0000-0000-0000-000000000001';

-- =============================================================================
-- FLIGHT OPS SERVICE (flight_db)
-- =============================================================================
\c flight_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    decimal_places SMALLINT NOT NULL DEFAULT 2
);
INSERT INTO currencies VALUES
('IDR', 'Indonesian Rupiah', 'Rp', 0),
('USD', 'US Dollar', '$', 2),
('SGD', 'Singapore Dollar', 'S$', 2),
('AUD', 'Australian Dollar', 'A$', 2),
('JPY', 'Japanese Yen', '¥', 0),
('GBP', 'British Pound', '£', 2);

CREATE TABLE countries (
    country_id CHAR(2) PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    country_code_3 CHAR(3) UNIQUE NOT NULL,
    nationality VARCHAR(100),
    continent VARCHAR(50),
    phone_code VARCHAR(10),
    currency_code CHAR(3) REFERENCES currencies(currency_code)
);
INSERT INTO countries VALUES
('ID', 'Indonesia', 'IDN', 'Indonesian', 'Asia', '+62', 'IDR'),
('SG', 'Singapore', 'SGP', 'Singaporean', 'Asia', '+65', 'SGD'),
('MY', 'Malaysia', 'MYS', 'Malaysian', 'Asia', '+60', 'IDR'),
('AU', 'Australia', 'AUS', 'Australian', 'Oceania', '+61', 'AUD'),
('JP', 'Japan', 'JPN', 'Japanese', 'Asia', '+81', 'JPY'),
('US', 'United States', 'USA', 'American', 'North America', '+1', 'USD'),
('GB', 'United Kingdom', 'GBR', 'British', 'Europe', '+44', 'GBP');

CREATE TABLE airports (
    airport_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    iata_code CHAR(3) UNIQUE NOT NULL,
    airport_name VARCHAR(200) NOT NULL,
    city VARCHAR(100),
    country_id CHAR(2) REFERENCES countries(country_id),
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,
    timezone VARCHAR(50)
);

INSERT INTO airports VALUES
('af000001-0000-0000-0000-000000000001', 'CGK', 'Soekarno-Hatta International', 'Jakarta', 'ID', -6.1256, 106.6559, 'Asia/Jakarta'),
('af000001-0000-0000-0000-000000000002', 'DPS', 'Ngurah Rai International', 'Denpasar', 'ID', -8.7482, 115.1675, 'Asia/Makassar'),
('af000001-0000-0000-0000-000000000003', 'SUB', 'Juanda International', 'Surabaya', 'ID', -7.3798, 112.7866, 'Asia/Jakarta'),
('af000001-0000-0000-0000-000000000004', 'SIN', 'Changi Airport', 'Singapore', 'SG', 1.3644, 103.9915, 'Asia/Singapore'),
('af000001-0000-0000-0000-000000000005', 'KUL', 'Kuala Lumpur International', 'Kuala Lumpur', 'MY', 2.7557, 101.7047, 'Asia/Kuala_Lumpur'),
('af000001-0000-0000-0000-000000000006', 'NRT', 'Narita International', 'Tokyo', 'JP', 35.7720, 140.3929, 'Asia/Tokyo'),
('af000001-0000-0000-0000-000000000007', 'SYD', 'Sydney Airport', 'Sydney', 'AU', -33.9399, 151.1753, 'Australia/Sydney'),
('af000001-0000-0000-0000-000000000008', 'LAX', 'Los Angeles International', 'Los Angeles', 'US', 33.9416, -118.4085, 'America/Los_Angeles');

CREATE TABLE terminals ( terminal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), airport_id UUID REFERENCES airports(airport_id), terminal_code VARCHAR(10) NOT NULL, UNIQUE(airport_id, terminal_code) );
INSERT INTO terminals (airport_id, terminal_code) VALUES
('af000001-0000-0000-0000-000000000001','1A'),('af000001-0000-0000-0000-000000000001','1B'),
('af000001-0000-0000-0000-000000000002','D'),('af000001-0000-0000-0000-000000000004','T1');

CREATE TABLE gates ( gate_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), terminal_id UUID REFERENCES terminals(terminal_id), gate_code VARCHAR(10) NOT NULL, UNIQUE(terminal_id, gate_code) );
INSERT INTO gates (terminal_id, gate_code) SELECT terminal_id, 'G' || generate_series(1,4) FROM terminals;

CREATE TABLE routes (
    route_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    origin_airport_id UUID REFERENCES airports(airport_id),
    destination_airport_id UUID REFERENCES airports(airport_id),
    distance_km DECIMAL(8,2),
    flight_duration_min INT,
    UNIQUE(origin_airport_id, destination_airport_id)
);
INSERT INTO routes VALUES
('r1000000-0000-0000-0000-000000000001', 'af000001-0000-0000-0000-000000000001', 'af000001-0000-0000-0000-000000000002', 980, 115),
('r1000000-0000-0000-0000-000000000002', 'af000001-0000-0000-0000-000000000001', 'af000001-0000-0000-0000-000000000003', 690, 90),
('r1000000-0000-0000-0000-000000000003', 'af000001-0000-0000-0000-000000000001', 'af000001-0000-0000-0000-000000000004', 900, 105),
('r1000000-0000-0000-0000-000000000004', 'af000001-0000-0000-0000-000000000001', 'af000001-0000-0000-0000-000000000005', 1180, 135),
('r1000000-0000-0000-0000-000000000005', 'af000001-0000-0000-0000-000000000001', 'af000001-0000-0000-0000-000000000006', 5500, 420);

CREATE TABLE flights (
    flight_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flight_number VARCHAR(10) NOT NULL,
    route_id UUID REFERENCES routes(route_id),
    aircraft_id UUID,
    scheduled_departure TIMESTAMPTZ NOT NULL,
    scheduled_arrival TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED'
);
INSERT INTO flights VALUES
('f0000000-0000-0000-0000-000000000001', 'NA101', 'r1000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', '2025-05-01 06:00:00+07', '2025-05-01 08:00:00+08', 'SCHEDULED'),
('f0000000-0000-0000-0000-000000000002', 'NA102', 'r1000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000002', '2025-05-01 07:00:00+07', '2025-05-01 08:30:00+07', 'SCHEDULED'),
('f0000000-0000-0000-0000-000000000003', 'NA103', 'r1000000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000003', '2025-05-01 09:00:00+07', '2025-05-01 11:45:00+08', 'BOARDING'),
('f0000000-0000-0000-0000-000000000004', 'NA104', 'r1000000-0000-0000-0000-000000000004', 'a2000000-0000-0000-0000-000000000005', '2025-05-02 14:00:00+07', '2025-05-02 16:15:00+08', 'SCHEDULED'),
('f0000000-0000-0000-0000-000000000005', 'NA105', 'r1000000-0000-0000-0000-000000000005', 'a2000000-0000-0000-0000-000000000005', '2025-05-03 22:00:00+07', '2025-05-04 07:00:00+09', 'SCHEDULED');

-- =============================================================================
-- PRICING SERVICE (pricing_db)
-- =============================================================================
\c pricing_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    decimal_places SMALLINT NOT NULL DEFAULT 2
);
INSERT INTO currencies VALUES
('IDR', 'Indonesian Rupiah', 'Rp', 0),
('USD', 'US Dollar', '$', 2),
('SGD', 'Singapore Dollar', 'S$', 2),
('AUD', 'Australian Dollar', 'A$', 2),
('JPY', 'Japanese Yen', '¥', 0),
('GBP', 'British Pound', '£', 2);

CREATE TABLE flight_prices (
    price_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flight_id UUID NOT NULL,
    seat_class VARCHAR(20) NOT NULL,
    fare_basis VARCHAR(20) NOT NULL,
    base_price DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency_code CHAR(3) REFERENCES currencies(currency_code) DEFAULT 'IDR',
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ
);
INSERT INTO flight_prices (flight_id, seat_class, fare_basis, base_price, tax_amount, valid_until) VALUES
('f0000000-0000-0000-0000-000000000001', 'ECONOMY', 'Y', 850000, 93500, '2025-04-30 23:59:59+07'),
('f0000000-0000-0000-0000-000000000001', 'ECONOMY', 'B', 1200000, 132000, '2025-04-30 23:59:59+07'),
('f0000000-0000-0000-0000-000000000001', 'BUSINESS', 'C', 2500000, 275000, '2025-04-30 23:59:59+07'),
('f0000000-0000-0000-0000-000000000003', 'ECONOMY', 'Y', 950000, 104500, '2025-04-30 23:59:59+07'),
('f0000000-0000-0000-0000-000000000005', 'BUSINESS', 'C', 4500000, 495000, '2025-05-03 23:59:59+07');

CREATE TABLE promotions (
    promotion_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promo_code VARCHAR(50) UNIQUE NOT NULL,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('PERCENTAGE','FIXED')),
    discount_value DECIMAL(10,2) NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL,
    valid_until TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);
INSERT INTO promotions VALUES
('p1000000-0000-0000-0000-000000000001', 'EARLYBIRD10', 'PERCENTAGE', 10, '2025-01-01', '2025-06-30', true),
('p1000000-0000-0000-0000-000000000002', 'FLASH50', 'FIXED', 50000, '2025-04-01', '2025-04-30', true);

CREATE TABLE tax_configurations (
    tax_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tax_name VARCHAR(100) NOT NULL,
    tax_percentage DECIMAL(5,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);
INSERT INTO tax_configurations VALUES
('t1000000-0000-0000-0000-000000000001', 'PPN', 11, true),
('t1000000-0000-0000-0000-000000000002', 'PJKP2U', 5, true);

-- =============================================================================
-- BOOKING SERVICE (booking_db)
-- =============================================================================
\c booking_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE bookings (
    booking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_reference VARCHAR(10) UNIQUE NOT NULL,
    primary_passenger_id UUID NOT NULL,
    booking_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total_amount DECIMAL(14,2),
    currency_code CHAR(3) DEFAULT 'IDR'
);
INSERT INTO bookings VALUES
('bk000001-0000-0000-0000-000000000001', 'NA1234', 'b0000000-0000-0000-0000-000000000001', NOW(), 'CONFIRMED', 943500, 'IDR'),
('bk000001-0000-0000-0000-000000000002', 'NA1235', 'b0000000-0000-0000-0000-000000000002', NOW(), 'CONFIRMED', 943500, 'IDR');

CREATE TABLE booking_passengers (
    booking_passenger_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(booking_id),
    passenger_id UUID NOT NULL,
    passenger_type VARCHAR(20) NOT NULL DEFAULT 'ADULT',
    first_name VARCHAR(100),
    last_name VARCHAR(100)
);
INSERT INTO booking_passengers VALUES
('bp000001-0000-0000-0000-000000000001', 'bk000001-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'ADULT', 'Ahmad', 'Santoso'),
('bp000001-0000-0000-0000-000000000002', 'bk000001-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 'ADULT', 'Dewi', 'Kartika');

CREATE TABLE booking_segments (
    segment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(booking_id),
    booking_passenger_id UUID REFERENCES booking_passengers(booking_passenger_id),
    flight_id UUID NOT NULL,
    price_id UUID,
    seat_id UUID,
    seat_class VARCHAR(20),
    status VARCHAR(20) DEFAULT 'CONFIRMED'
);
INSERT INTO booking_segments VALUES
('sg000001-0000-0000-0000-000000000001', 'bk000001-0000-0000-0000-000000000001', 'bp000001-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000001', NULL, NULL, 'ECONOMY', 'CONFIRMED'),
('sg000001-0000-0000-0000-000000000002', 'bk000001-0000-0000-0000-000000000002', 'bp000001-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000001', NULL, NULL, 'ECONOMY', 'CONFIRMED');

CREATE TABLE check_ins (
    check_in_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_id UUID REFERENCES booking_segments(segment_id) UNIQUE,
    check_in_method VARCHAR(20) NOT NULL,
    checked_in_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    boarding_pass_issued BOOLEAN NOT NULL DEFAULT TRUE
);
INSERT INTO check_ins (segment_id, check_in_method) VALUES
('sg000001-0000-0000-0000-000000000001', 'ONLINE');

CREATE TABLE baggage (
    baggage_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_id UUID REFERENCES booking_segments(segment_id),
    tag_number VARCHAR(20) UNIQUE NOT NULL,
    weight_kg DECIMAL(6,2) NOT NULL,
    baggage_type VARCHAR(30) NOT NULL DEFAULT 'CHECKED',
    status VARCHAR(30) NOT NULL DEFAULT 'CHECKED_IN'
);
INSERT INTO baggage (segment_id, tag_number, weight_kg, baggage_type) VALUES
('sg000001-0000-0000-0000-000000000001', 'BAG001', 15.0, 'CHECKED');

-- =============================================================================
-- PAYMENT SERVICE (payment_db)
-- =============================================================================
\c payment_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    decimal_places SMALLINT NOT NULL DEFAULT 2
);
INSERT INTO currencies VALUES
('IDR', 'Indonesian Rupiah', 'Rp', 0),
('USD', 'US Dollar', '$', 2),
('SGD', 'Singapore Dollar', 'S$', 2),
('AUD', 'Australian Dollar', 'A$', 2),
('JPY', 'Japanese Yen', '¥', 0),
('GBP', 'British Pound', '£', 2);

CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL,
    payment_method VARCHAR(30),
    payment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    amount DECIMAL(14,2),
    currency_code CHAR(3) REFERENCES currencies(currency_code)
);
INSERT INTO payments (booking_id, payment_method, payment_status, amount) VALUES
('bk000001-0000-0000-0000-000000000001', 'CREDIT_CARD', 'COMPLETED', 943500);

CREATE TABLE revenue_accounting (
    revenue_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL,
    flight_id UUID NOT NULL,
    revenue_type VARCHAR(50) NOT NULL,
    gross_amount DECIMAL(14,2) NOT NULL,
    tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency_code CHAR(3) REFERENCES currencies(currency_code)
);
INSERT INTO revenue_accounting (booking_id, flight_id, revenue_type, gross_amount, tax_amount) VALUES
('bk000001-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000001', 'TICKET', 850000, 93500);

-- =============================================================================
-- LOYALTY SERVICE (loyalty_db)
-- =============================================================================
\c loyalty_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE loyalty_accounts (
    loyalty_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID NOT NULL,
    membership_number VARCHAR(20) UNIQUE NOT NULL,
    tier VARCHAR(20) NOT NULL DEFAULT 'BASIC',
    available_miles DECIMAL(14,2) DEFAULT 0
);
INSERT INTO loyalty_accounts (loyalty_id, passenger_id, membership_number, tier, available_miles) VALUES
('la000001-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'FF-b0000000', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 'FF-b0000001', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000003', 'FF-b0000002', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000004', 'FF-b0000003', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000005', 'FF-b0000004', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000006', 'FF-b0000005', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000007', 'b0000000-0000-0000-0000-000000000007', 'FF-b0000006', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000008', 'b0000000-0000-0000-0000-000000000008', 'FF-b0000007', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000009', 'b0000000-0000-0000-0000-000000000009', 'FF-b0000008', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000010', 'b0000000-0000-0000-0000-000000000010', 'FF-b0000009', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000011', 'b0000000-0000-0000-0000-000000000011', 'FF-b0000010', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000012', 'b0000000-0000-0000-0000-000000000012', 'FF-b0000011', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000013', 'b0000000-0000-0000-0000-000000000013', 'FF-b0000012', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000014', 'b0000000-0000-0000-0000-000000000014', 'FF-b0000013', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000015', 'b0000000-0000-0000-0000-000000000015', 'FF-b0000014', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000016', 'b0000000-0000-0000-0000-000000000016', 'FF-b0000015', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000017', 'b0000000-0000-0000-0000-000000000017', 'FF-b0000016', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000018', 'b0000000-0000-0000-0000-000000000018', 'FF-b0000017', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000019', 'b0000000-0000-0000-0000-000000000019', 'FF-b0000018', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000020', 'b0000000-0000-0000-0000-000000000020', 'FF-b0000019', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000021', 'b0000000-0000-0000-0000-000000000021', 'FF-b0000020', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000022', 'b0000000-0000-0000-0000-000000000022', 'FF-b0000021', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000023', 'b0000000-0000-0000-0000-000000000023', 'FF-b0000022', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000024', 'b0000000-0000-0000-0000-000000000024', 'FF-b0000023', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000025', 'b0000000-0000-0000-0000-000000000025', 'FF-b0000024', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000026', 'b0000000-0000-0000-0000-000000000026', 'FF-b0000025', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000027', 'b0000000-0000-0000-0000-000000000027', 'FF-b0000026', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000028', 'b0000000-0000-0000-0000-000000000028', 'FF-b0000027', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000029', 'b0000000-0000-0000-0000-000000000029', 'FF-b0000028', 'BASIC', 5000),
('la000001-0000-0000-0000-000000000030', 'b0000000-0000-0000-0000-000000000030', 'FF-b0000029', 'BASIC', 5000);

CREATE TABLE loyalty_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    loyalty_id UUID REFERENCES loyalty_accounts(loyalty_id),
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    transaction_type VARCHAR(20) NOT NULL,
    miles_amount DECIMAL(12,2) NOT NULL
);
INSERT INTO loyalty_transactions (loyalty_id, transaction_type, miles_amount)
SELECT loyalty_id, 'EARN', 1000 FROM loyalty_accounts LIMIT 10;

-- =============================================================================
-- CREW SERVICE (crew_db)
-- =============================================================================
\c crew_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE employees (
    employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255) UNIQUE NOT NULL
);
INSERT INTO employees VALUES
('e0000000-0000-0000-0000-000000000001', 'CAPT001', 'Capt. Andi', 'Wirawan', 'andi.w@airline.com'),
('e0000000-0000-0000-0000-000000000002', 'FO001', 'FO Budi', 'Santoso', 'budi.s@airline.com'),
('e0000000-0000-0000-0000-000000000003', 'PURSER01', 'Purser Rina', 'Marlina', 'rina.m@airline.com');

CREATE TABLE crew_members (
    crew_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID REFERENCES employees(employee_id) UNIQUE,
    crew_role VARCHAR(30) NOT NULL,
    license_number VARCHAR(50)
);
INSERT INTO crew_members VALUES
('cr000001-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'CAPTAIN', 'ATP-001'),
('cr000001-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000002', 'FIRST_OFFICER', 'CPL-001'),
('cr000001-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000003', 'PURSER', NULL);

CREATE TABLE flight_crew_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flight_id UUID NOT NULL,
    crew_id UUID REFERENCES crew_members(crew_id),
    crew_role VARCHAR(30) NOT NULL,
    is_confirmed BOOLEAN NOT NULL DEFAULT FALSE
);
INSERT INTO flight_crew_assignments (flight_id, crew_id, crew_role, is_confirmed) VALUES
('f0000000-0000-0000-0000-000000000001', 'cr000001-0000-0000-0000-000000000001', 'CAPTAIN', true),
('f0000000-0000-0000-0000-000000000001', 'cr000001-0000-0000-0000-000000000002', 'FIRST_OFFICER', true);

-- =============================================================================
-- MAINTENANCE SERVICE (maintenance_db)
-- =============================================================================
\c maintenance_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE employees (
    employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255) UNIQUE NOT NULL
);
INSERT INTO employees VALUES
('e0000000-0000-0000-0000-000000000001', 'CAPT001', 'Capt. Andi', 'Wirawan', 'andi.w@airline.com'),
('e0000000-0000-0000-0000-000000000002', 'FO001', 'FO Budi', 'Santoso', 'budi.s@airline.com'),
('e0000000-0000-0000-0000-000000000003', 'PURSER01', 'Purser Rina', 'Marlina', 'rina.m@airline.com');

CREATE TABLE maintenance_records (
    maintenance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aircraft_id UUID NOT NULL,
    maintenance_type VARCHAR(30),
    status VARCHAR(30) DEFAULT 'PLANNED'
);
INSERT INTO maintenance_records VALUES
('m1000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000004', 'ROUTINE_A', 'IN_PROGRESS');

-- =============================================================================
-- NOTIFICATION SERVICE (notif_db)
-- =============================================================================
\c notif_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID,
    channel VARCHAR(20),
    template_code VARCHAR(50),
    body TEXT,
    status VARCHAR(20) DEFAULT 'PENDING'
);
INSERT INTO notifications (passenger_id, channel, template_code, body, status) VALUES
('b0000000-0000-0000-0000-000000000001', 'EMAIL', 'booking-confirmation', 'Your booking NA1234 is confirmed.', 'SENT');