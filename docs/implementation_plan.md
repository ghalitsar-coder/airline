# Airline Management System — Backend Services Implementation Plan

## Overview

Membangun 10 microservice backend sesuai PRD Rev 1.1. Terbagi menjadi:
- **4 Go services** (Chi router): Passenger, Inventory, Flight Ops, Notification
- **6 Quarkus services** (Quarkus 3.x): Booking, Pricing, Payment, Loyalty, Crew, Maintenance

Setiap service mengikuti struktur yang konsisten, menerapkan endpoint utama dari PRD, dan terhubung ke database masing-masing.

---

## User Review Required

> [!IMPORTANT]
> **Scope Dikurangi untuk MVP:** Implementasi akan fokus pada **struktur, endpoint, business logic inti, dan konektivitas** setiap service. Fitur enterprise-level (OptaPlanner, Drools/Kogito, Camunda BPM, Hibernate Envers, Narayana TM) **tidak** diimplementasi pada tahap ini karena memerlukan lisensi/setup tambahan yang kompleks. Sebagai gantinya, logika tersebut akan diimplementasi dengan pendekatan sederhana yang dapat di-extend.

> [!IMPORTANT]
> **Database `init-all.sql`:** File ini masih mengandung 3 cross-database query yang akan menyebabkan error. Akan diperbaiki bersamaan dengan pembuatan service.

---

## Open Questions

> [!NOTE]
> Tidak ada pertanyaan terbuka — semua detail teknis sudah tercantum di PRD Rev 1.1.

---

## Proposed Changes

### Fix 1: `infrastructure/postgres/init-all.sql`

#### [MODIFY] [init-all.sql](file:///home/archlinux/My%20Works/airline/infrastructure/postgres/init-all.sql)
- Ganti `CREATE TABLE currencies ( LIKE passenger_db.currencies INCLUDING ALL )` → hardcode DDL di `flight_db`, `pricing_db`, `payment_db`
- Ganti `INSERT INTO currencies SELECT * FROM passenger_db.currencies` → hardcode VALUES
- Ganti `CREATE TABLE employees ( LIKE crew_db.employees INCLUDING ALL )` di `maintenance_db` → hardcode DDL
- Ganti `INSERT INTO loyalty_accounts ... FROM passenger_db.passengers` → hardcode 30 baris VALUES

#### [MODIFY] [docker-compose.yml](file:///home/archlinux/My%20Works/airline/docker-compose.yml)
- Update `inventory-service` depends_on `booking-service` → `service_healthy` (sudah punya healthcheck)

---

### Go Services (4 services)

#### Structure per Go Service:
```
services/{service-name}/
├── Dockerfile
├── go.mod
├── go.sum (generated)
├── cmd/
│   └── main.go          # entry point, setup server
├── internal/
│   ├── config/
│   │   └── config.go    # env config
│   ├── db/
│   │   └── db.go        # postgres connection
│   ├── handler/
│   │   └── *.go         # HTTP handlers
│   ├── model/
│   │   └── *.go         # structs/models
│   ├── repository/
│   │   └── *.go         # DB queries
│   └── middleware/
│       └── *.go         # auth, logging
└── pkg/
    └── response/
        └── response.go  # standard response format
```

---

### Service 1: Passenger Service (Go, Port 8001)

#### [NEW] `services/passenger-service/go.mod`
#### [NEW] `services/passenger-service/cmd/main.go`
#### [NEW] `services/passenger-service/internal/config/config.go`
#### [NEW] `services/passenger-service/internal/db/db.go`
#### [NEW] `services/passenger-service/internal/model/model.go`
#### [NEW] `services/passenger-service/internal/repository/passenger_repo.go`
#### [NEW] `services/passenger-service/internal/handler/auth_handler.go`
#### [NEW] `services/passenger-service/internal/handler/passenger_handler.go`
#### [NEW] `services/passenger-service/internal/middleware/jwt.go`
#### [NEW] `services/passenger-service/pkg/response/response.go`

**Endpoints:** POST /auth/register, POST /auth/login, POST /auth/refresh, GET/PUT /passengers/{id}, POST/GET/DELETE /passengers/{id}/documents, GET /health

---

### Service 2: Inventory Service (Go, Port 8002)

#### [NEW] `services/inventory-service/go.mod`
#### [NEW] `services/inventory-service/cmd/main.go`
#### [NEW] `services/inventory-service/internal/...`

**Endpoints:** GET /aircraft-types, GET /aircrafts/{id}/seat-map, POST/DELETE/GET /seat-reservations, GET /flights/{flightId}/available-seats, GET /health

**Key:** Redis seat locking dengan SETNX atomic

---

### Service 3: Flight Ops Service (Go, Port 8003)

#### [NEW] `services/flight-ops-service/go.mod`
#### [NEW] `services/flight-ops-service/cmd/main.go`
#### [NEW] `services/flight-ops-service/internal/...`

**Endpoints:** GET /flights, GET /flights/{id}, PUT /flights/{id}/status, GET /flights/{id}/operational, GET /routes, GET /airports/{code}/gates, POST /airport-slots, GET /health

**Key:** Publish FlightStatusChanged event ke RabbitMQ

---

### Service 4: Notification Service (Go, Port 8004)

#### [NEW] `services/notification-service/go.mod`
#### [NEW] `services/notification-service/cmd/main.go`
#### [NEW] `services/notification-service/internal/...`

**Key:** Worker pool consume RabbitMQ queues, kirim email via SMTP/Resend, simpan in-app notification ke DB

---

### Quarkus Services (6 services)

#### Structure per Quarkus Service:
```
services/{service-name}/
├── Dockerfile
├── pom.xml
└── src/
    └── main/
        ├── java/
        │   └── com/airline/{service}/
        │       ├── entity/       # JPA entities
        │       ├── repository/   # Panache repositories
        │       ├── service/      # Business logic
        │       ├── resource/     # REST endpoints (JAX-RS)
        │       ├── dto/          # Request/Response DTOs
        │       ├── event/        # RabbitMQ events
        │       └── exception/    # Custom exceptions
        └── resources/
            └── application.properties
```

---

### Service 5: Booking Service (Quarkus, Port 8005)

**Endpoints:** POST /bookings, GET /bookings/{pnr}, PUT /bookings/{pnr}/confirm|cancel|change, POST /bookings/{pnr}/check-in|baggage, GET /bookings/{pnr}/boarding-pass

**Key:** Saga orchestration logic, PNR generation, state machine booking status

---

### Service 6: Pricing Service (Quarkus, Port 8006)

**Endpoints:** GET /prices/search, GET /prices/{flightId}, POST /prices/calculate, GET/POST /promotions, GET /prices/calendar

**Key:** Fare calculation engine (base × multiplier + tax + ancillary - discount)

---

### Service 7: Payment Service (Quarkus, Port 8007)

**Endpoints:** POST /payments, GET /payments/{id}, POST /payments/webhook, POST /payments/{id}/refund, GET /revenue

**Key:** Xendit integration (mock), idempotency key di Redis, webhook signature verification

---

### Service 8: Loyalty Service (Quarkus, Port 8008)

**Endpoints:** GET /loyalty/{passengerId}, GET /loyalty/{passengerId}/transactions, POST /loyalty/{passengerId}/redeem|reverse-miles, GET /loyalty/tiers

**Key:** Miles earn rules berdasarkan seat class & distance, tier calculation

---

### Service 9: Crew Service (Quarkus, Port 8009)

**Endpoints:** GET /crew, GET /crew/{id}, POST /crew/assignments, GET /crew/{id}/schedule, GET /flights/{id}/crew, PUT /crew/assignments/{id}

**Key:** Flight hours compliance validation (max 8 jam DGCA)

---

### Service 10: Maintenance Service (Quarkus, Port 8010)

**Endpoints:** GET/POST /maintenance, GET /maintenance/{id}, PUT /maintenance/{id}/status, POST /maintenance/{id}/approve, GET /aircrafts/{id}/maintenance-history

**Key:** Status workflow state machine, approval logging

---

## Implementation Order

1. **Fix `init-all.sql`** — supaya DB bisa dijalankan dulu
2. **Passenger Service** — foundational, service lain bergantung padanya
3. **Inventory Service** — dibutuhkan oleh Booking
4. **Flight Ops Service** — dibutuhkan oleh Booking & Pricing
5. **Pricing Service** — dibutuhkan oleh Booking
6. **Booking Service** — core business service
7. **Payment Service** — dibutuhkan oleh Booking Saga
8. **Notification Service** — async consumer
9. **Loyalty Service** — async consumer
10. **Crew Service** — independent
11. **Maintenance Service** — independent

## Verification Plan

### Automated Tests
- `docker compose up postgres redis rabbitmq` → pastikan DB ready
- Jalankan `docker compose up --build` untuk setiap service secara bertahap
- Test endpoint health: `curl http://localhost:{port}/health`

### Manual Verification
- Test Passenger: register + login → dapat JWT
- Test Inventory: GET seat-map → dapat daftar kursi
- Test Flight Ops: GET /flights → dapat daftar penerbangan
- Test Pricing: GET /prices/search → dapat harga tiket
- Test Booking: POST /bookings → inisiasi booking flow
