```markdown
# Product Requirements Document (PRD)
## Airline Management System — Microservice Architecture
**Versi:** 1.0.0  
**Status:** Draft  
**Tanggal:** 2025  
**Author:** Engineering Team  
**Klasifikasi:** Internal — Confidential

---

## Daftar Isi

1. [Ringkasan Eksekutif](#1-ringkasan-eksekutif)
2. [Latar Belakang & Problem Statement](#2-latar-belakang--problem-statement)
3. [Tujuan & Sasaran Produk](#3-tujuan--sasaran-produk)
4. [Scope & Batasan](#4-scope--batasan)
5. [Stakeholder & User Personas](#5-stakeholder--user-personas)
6. [Arsitektur Sistem](#6-arsitektur-sistem)
7. [Stack Teknologi](#7-stack-teknologi)
8. [Dekomposisi Microservice (Revised Final)](#8-dekomposisi-microservice-revised-final)
9. [Spesifikasi Fungsional Per Service](#9-spesifikasi-fungsional-per-service)
10. [Alur Bisnis Kritis (End-to-End Workflows)](#10-alur-bisnis-kritis-end-to-end-workflows)
11. [Infrastruktur & Integrasi](#11-infrastruktur--integrasi)
12. [Non-Functional Requirements (NFR)](#12-non-functional-requirements-nfr)
13. [Observability & Monitoring](#13-observability--monitoring)
14. [CI/CD & GitOps Pipeline](#14-cicd--gitops-pipeline)
15. [Keamanan & Compliance](#15-keamanan--compliance)
16. [Database Schema & Ownership](#16-database-schema--ownership)
17. [API Contract & Communication Patterns](#17-api-contract--communication-patterns)
18. [Milestones & Roadmap](#18-milestones--roadmap)
19. [Risiko & Mitigasi](#19-risiko--mitigasi)
20. [Glossary](#20-glossary)

---

## 1. Ringkasan Eksekutif

Dokumen ini mendefinisikan **Product Requirements** untuk sistem manajemen maskapai penerbangan (*Airline Management System / AMS*) yang dibangun menggunakan **arsitektur microservice**. Sistem ini dirancang untuk menggantikan atau membangun dari awal platform monolitik yang tidak mampu menskalakan beban operasional maskapai modern.

Sistem AMS mencakup 10 microservice yang terspesialisasi, masing-masing memiliki *bounded context* dan database tersendiri. Frontend dibangun dengan **Next.js**, backend terbagi antara **Go** (untuk service berbeban I/O tinggi dan latensi rendah) dan **Quarkus/Java** (untuk service dengan logika bisnis kompleks dan kebutuhan transaksi ACID), didukung oleh **PostgreSQL**, **Redis**, **RabbitMQ**, dan ekosistem observabilitas modern.

---

## 2. Latar Belakang & Problem Statement

### 2.1 Konteks Bisnis

Operasi maskapai penerbangan mencakup proses yang sangat kompleks dan saling terhubung: pemesanan tiket, manajemen penerbangan real-time, pembayaran, loyalitas penumpang, penjadwalan kru, hingga kepatuhan regulasi perawatan pesawat. Sistem yang tidak terdesentralisasi akan mengalami:

- **Bottleneck performa** saat traffic tinggi (promo tiket, peak season)
- **Deployment risk tinggi** — satu perubahan kecil bisa merusak seluruh sistem
- **Skalabilitas terbatas** — komponen tidak bisa di-scale secara independen
- **Coupling database** yang menyulitkan evolusi skema

### 2.2 Problem Statement

> *Bagaimana membangun sistem manajemen maskapai yang mampu menangani ribuan transaksi per detik, dengan ketersediaan tinggi (99.9% uptime), kepatuhan regulasi (PCI-DSS, DGCA), dan kemampuan rilis fitur baru secara independen per domain bisnis?*

### 2.3 Keputusan Arsitektur Utama

Berdasarkan analisis mendalam terhadap 38 tabel skema database dan karakteristik beban kerja masing-masing domain, diputuskan:

- **Database per Service** — setiap service memiliki database PostgreSQL dan schema sendiri
- **Go** untuk service dengan I/O tinggi, latensi kritis, logika sederhana
- **Quarkus** untuk service dengan proses bisnis kompleks, transaksi ACID, dan integrasi enterprise
- **RabbitMQ** sebagai event broker untuk komunikasi asinkron antar service
- **Kong** sebagai API Gateway tunggal untuk seluruh client

---

## 3. Tujuan & Sasaran Produk

### 3.1 Tujuan Bisnis

| ID | Tujuan | Metrik Keberhasilan |
|----|--------|---------------------|
| G1 | Meningkatkan ketersediaan sistem | Uptime ≥ 99.9% per kuartal |
| G2 | Meningkatkan kecepatan rilis fitur | Deployment per service < 15 menit |
| G3 | Menangani lonjakan traffic promo | 10.000 req/detik pada Booking & Inventory |
| G4 | Memastikan kepatuhan pembayaran | Zero PCI-DSS violation audit |
| G5 | Mengurangi Mean Time to Recovery | MTTR < 5 menit per insiden |
| G6 | Efisiensi biaya infrastruktur | Autoscaling mengurangi idle cost 40% |

### 3.2 Tujuan Teknis

- Membangun 10 microservice yang berjalan independen di Kubernetes
- Implementasi Saga Pattern untuk transaksi terdistribusi pada alur booking
- Zero-downtime deployment via ArgoCD blue-green strategy
- Observabilitas penuh: metrics (Prometheus/Grafana) + logging (ELK Stack)
- Automated rollback saat error rate > 5% dalam 2 menit post-deployment

---

## 4. Scope & Batasan

### 4.1 In Scope

- ✅ 10 microservice backend (Go + Quarkus)
- ✅ Frontend web aplikasi (Next.js)
- ✅ API Gateway (Kong) dengan rate limiting, auth, routing
- ✅ Database per service (PostgreSQL + PgBouncer connection pooling)
- ✅ Cache layer (Redis) untuk session, seat lock, dan pricing cache
- ✅ Object storage (MinIO) untuk dokumen penumpang, laporan, boarding pass PDF
- ✅ Event-driven communication (RabbitMQ)
- ✅ Payment integration (Xendit)
- ✅ Email notification (Mailtrap/Resend)
- ✅ CI/CD GitOps pipeline (Jenkins + ArgoCD)
- ✅ Observabilitas lengkap (Prometheus, Grafana, ELK Stack)

### 4.2 Out of Scope (v1.0)

- ❌ Mobile app native (iOS/Android) — dijadwalkan untuk v2.0
- ❌ Integrasi GDS (Amadeus, Sabre, Travelport)
- ❌ Modul cargo/freight management
- ❌ Multi-airline/codeshare management
- ❌ Revenue Management System otomatis (dynamic pricing ML)
- ❌ Employee Service terpisah (data dasar karyawan saat ini diduplikasi di Crew & Maintenance; future extraction)

---

## 5. Stakeholder & User Personas

### 5.1 Internal Stakeholders

| Persona | Peran | Kebutuhan Utama |
|---------|-------|-----------------|
| **Penumpang (Passenger)** | End-user utama | Pencarian, booking, check-in online, notifikasi |
| **Agen Penjualan** | Staff counter/call center | Akses admin untuk booking & modifikasi |
| **Staf Operasional Penerbangan** | Ground ops, gate agent | Status penerbangan real-time, gate assignment |
| **Staf Keuangan** | Finance team | Laporan pembayaran, revenue accounting |
| **Teknisi & Insinyur Pesawat** | MRO team | Pencatatan maintenance, approval workflow |
| **Kru Penerbangan** | Pilot & cabin crew | Jadwal penugasan, notifikasi perubahan |
| **Admin IT** | DevOps/SRE | Monitoring, deployment, incident response |

### 5.2 External Stakeholders

- **Xendit** — payment gateway provider
- **Mailtrap/Resend** — email delivery provider
- **DGCA** — regulator penerbangan (compliance audit)
- **Otoritas Bandara** — slot & gate coordination

---

## 6. Arsitektur Sistem

### 6.1 High-Level Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                                │
│              Next.js Web App   │   Mobile (Future)                  │
└───────────────────┬─────────────────────────────────────────────────┘
                    │ HTTPS
┌───────────────────▼─────────────────────────────────────────────────┐
│                    API GATEWAY — Kong                                │
│    Rate Limiting │ JWT Auth │ Routing │ Load Balancing │ Logging     │
└──┬──────┬───────┬──────┬───────┬──────┬──────┬────────┬────────────┘
   │      │       │      │       │      │      │        │
┌──▼──┐ ┌─▼──┐ ┌──▼─┐ ┌─▼──┐ ┌──▼─┐ ┌─▼──┐ ┌─▼──┐ ┌──▼──────────┐
│ PSS │ │ INV│ │ FLT│ │ BKG│ │ PAY│ │ PRC│ │ LOY│ │NOTIF│CREW│MNT│
│ Go  │ │ Go │ │ Go │ │ QKS│ │ QKS│ │ QKS│ │ QKS│ │ Go  │QKS │QKS│
└──┬──┘ └─┬──┘ └──┬─┘ └─┬──┘ └──┬─┘ └─┬──┘ └─┬──┘ └─────────────┘
   │      │       │      │       │      │      │
   ▼      ▼       ▼      ▼       ▼      ▼      ▼
[PostgreSQL per service] + [Redis Cache] + [MinIO Object Storage]
                    │
        ┌───────────▼──────────┐
        │   RabbitMQ (Broker)  │
        │  Event Bus / Topics  │
        └──────────────────────┘
                    │
        ┌───────────▼──────────┐
        │   Observability      │
        │  Prometheus + Grafana│
        │  ELK Stack (Logging) │
        └──────────────────────┘
```

### 6.2 Communication Patterns

| Pattern | Protokol | Digunakan Untuk |
|---------|----------|-----------------|
| **Synchronous REST** | HTTP/JSON via Kong | Client → Service, Service → Service (query) |
| **Synchronous gRPC** | Protobuf | Inventory ↔ Booking (seat lock, latensi kritis) |
| **Asynchronous Event** | RabbitMQ / AMQP | BookingConfirmed → Payment, FlightStatusChanged → Notif |
| **Saga Orchestration** | RabbitMQ + Booking Service | Transaksi terdistribusi booking flow |

---

## 7. Stack Teknologi

### 7.1 Frontend

| Komponen | Teknologi | Versi | Justifikasi |
|----------|-----------|-------|-------------|
| Web Framework | **Next.js** | 14+ (App Router) | SSR/SSG untuk SEO, RSC untuk performa, file-based routing |
| Styling | Tailwind CSS + shadcn/ui | latest | Rapid UI development, konsistensi desain |
| State Management | Zustand / React Query | latest | Server state via React Query, client state via Zustand |
| Auth Client | NextAuth.js | v5 | OAuth2/JWT session management |
| HTTP Client | Axios + SWR | latest | Data fetching dengan caching |
| Form | React Hook Form + Zod | latest | Validasi type-safe |

### 7.2 Backend

| Service | Teknologi | Framework | Justifikasi |
|---------|-----------|-----------|-------------|
| Passenger, Inventory, Flight Ops, Notification | **Go** | Chi / Fiber | Binary ringan, concurrency tinggi, cold start < 10ms |
| Booking, Pricing, Payment, Loyalty, Crew, Maintenance | **Quarkus** | Quarkus 3.x | Deklaratif @Transactional, JTA, Hibernate Envers, Rule Engine |

### 7.3 Database & Cache

| Komponen | Teknologi | Digunakan Oleh |
|----------|-----------|----------------|
| Primary Database | **PostgreSQL 16** | Semua service (database terpisah per service) |
| Connection Pooling | **PgBouncer** | Semua service (pooling mode transaction) |
| Cache & Session | **Redis 7** | Seat lock, pricing cache, session token, rate limit |
| Object Storage | **MinIO** | Dokumen penumpang, boarding pass PDF, laporan keuangan |

### 7.4 Messaging & Integration

| Komponen | Teknologi | Digunakan Untuk |
|----------|-----------|-----------------|
| Message Broker | **RabbitMQ** | Event-driven async communication, Saga choreography |
| Payment Gateway | **Xendit** | Payment Service — virtual account, QRIS, kartu kredit |
| Email Provider | **Mailtrap** (dev) / **Resend** (prod) | Notification Service — booking confirmation, tiket |

### 7.5 Infrastructure & DevOps

| Komponen | Teknologi | Fungsi |
|----------|-----------|--------|
| Container Orchestration | Kubernetes (K8s) | Hosting semua service |
| API Gateway | **Kong** | Routing, Auth, Rate Limit, Logging |
| CI (Build & Test) | **Jenkins** | Pipeline build, test, image push ke registry |
| CD (Deploy & Sync) | **ArgoCD** | GitOps sync, blue-green deployment, rollback |
| Container Registry | Docker Hub / Harbor | Image storage |
| Metrics | **Prometheus + Grafana** | Service metrics, dashboards, alerting |
| Logging | **ELK Stack** (Elasticsearch, Logstash, Kibana) | Centralized logging, tracing, log-based alerting |

---

## 8. Dekomposisi Microservice (Revised Final)

Berikut adalah alokasi **final yang telah direvisi**, berdasarkan pertimbangan domain DDD, karakteristik beban kerja, dan kebutuhan enterprise:

| # | Service | Runtime | Port | DB Schema | Tabel Utama | Justifikasi Teknologi |
|---|---------|---------|------|-----------|-------------|----------------------|
| 1 | **Passenger Service** | Go | 8001 | `passenger_db` | passengers, passenger_documents, users | CRUD cepat, autentikasi ringan, goroutine untuk concurrent login |
| 2 | **Inventory Service** | Go | 8002 | `inventory_db` | aircrafts, seats, cabin_configurations, **seat_reservations** | Seat locking high-concurrency via Redis atomic ops + Go; 10K lock/unlock/detik |
| 3 | **Flight Ops Service** | Go | 8003 | `flight_db` | flights, routes, airport_slots, gates, terminals, runways, flight_operational_data | Real-time status update, event publisher, memory footprint < 64MB |
| 4 | **Notification Service** | Go | 8004 | `notif_db` | notifications | I/O-bound outbound, goroutine worker pool, Mailtrap/Resend integration |
| 5 | **Booking Service** | Quarkus | 8005 | `booking_db` | bookings, booking_passengers, booking_segments, booking_ancillaries, check_ins, baggage | Saga Orchestrator, @Transactional multi-table, 50+ business rules |
| 6 | **Pricing Service** | Quarkus | 8006 | `pricing_db` | flight_prices, promotions | Fare engine, Strategy/Specification pattern, Infinispan cache |
| 7 | **Payment Service** | Quarkus | 8007 | `payment_db` | payments, revenue_accounting | JTA, Narayana TM, Xendit integration, PCI-DSS compliance |
| 8 | **Loyalty Service** | Quarkus | 8008 | `loyalty_db` | loyalty_accounts, loyalty_transactions | Drools/Kogito rule engine, tier logic, miles multiplier, expiry rules |
| 9 | **Crew Service** | Quarkus | 8009 | `crew_db` | employees (data dasar kru), crew_members, flight_crew_assignments | OptaPlanner constraint solver (future), jam terbang compliance |
| 10 | **Maintenance Service** | Quarkus | 8010 | `maintenance_db` | maintenance_records, employees (data teknisi) | Hibernate Envers audit trail, Camunda BPM approval workflow, DGCA compliance |

> **Catatan Revisi Kunci:**
> - `seat_reservations` dipindahkan dari Booking → **Inventory Service (Go)** untuk menghindari JTA overhead pada skenario hot-row contention saat promo
> - **Loyalty Service** direvisi dari Go → **Quarkus** karena kompleksitas rule bisnis (tier, multiplier, expiry) memerlukan Drools/Kogito
> - **Maintenance Service** direvisi dari Go → **Quarkus** karena kebutuhan audit trail DGCA/FAA via Hibernate Envers dan BPM approval

---

## 9. Spesifikasi Fungsional Per Service

### 9.1 Passenger Service (Go)

**Tanggung Jawab:** Manajemen identitas penumpang, autentikasi, profil, dan dokumen perjalanan.

**Endpoints Utama:**

| Method | Path | Deskripsi |
|--------|------|-----------|
| POST | `/v1/auth/register` | Registrasi akun baru |
| POST | `/v1/auth/login` | Login, return JWT access + refresh token |
| POST | `/v1/auth/refresh` | Refresh access token |
| GET | `/v1/passengers/{id}` | Ambil profil penumpang |
| PUT | `/v1/passengers/{id}` | Update profil (nama, kontak) |
| POST | `/v1/passengers/{id}/documents` | Upload dokumen (paspor, KTP) ke MinIO |
| GET | `/v1/passengers/{id}/documents` | Daftar dokumen aktif |
| DELETE | `/v1/passengers/{id}/documents/{docId}` | Hapus dokumen |

**Business Rules:**
- Password harus minimal 8 karakter, kombinasi huruf besar/kecil, angka, simbol
- Email harus terverifikasi sebelum bisa booking (OTP via Notification Service)
- Dokumen paspor harus valid (tanggal expired > tanggal penerbangan + 6 bulan)
- Maksimum 5 dokumen per penumpang per tipe

**Dependensi:**
- Notification Service (via RabbitMQ): kirim OTP email verifikasi
- MinIO: penyimpanan file dokumen

---

### 9.2 Inventory Service (Go)

**Tanggung Jawab:** Manajemen data master pesawat, konfigurasi kabin, kursi, dan **seat reservation (locking)** dengan konkurensi tinggi.

**Endpoints Utama:**

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | `/v1/aircraft-types` | Daftar tipe pesawat |
| GET | `/v1/aircrafts/{id}/seat-map` | Peta kursi berdasarkan konfigurasi |
| POST | `/v1/seat-reservations` | Lock kursi (TTL Redis 10 menit) |
| DELETE | `/v1/seat-reservations/{lockId}` | Release lock kursi |
| GET | `/v1/seat-reservations/{lockId}` | Cek status lock |
| GET | `/v1/flights/{flightId}/available-seats` | Kursi tersedia real-time |

**Seat Locking Mechanism:**
```
1. Client request lock → Inventory Service
2. Check Redis key: seat:{flightId}:{seatId}
3. Jika EXIST → return 409 Conflict (kursi sudah di-lock)
4. Jika NOT EXIST → SET seat:{flightId}:{seatId} {bookingSessionId} EX 600 (10 menit TTL)
5. Return lockId ke Booking Service
6. Booking Service konfirmasi → lock diperpanjang atau dilepas
```

**Business Rules:**
- Lock seat maksimal 10 menit (TTL Redis). Expired otomatis → kursi kembali tersedia
- Satu sesi booking hanya bisa lock maksimal jumlah penumpang dalam booking tersebut
- Seat dengan status BLOCKED (disabled) tidak bisa di-reserve

---

### 9.3 Flight Operations Service (Go)

**Tanggung Jawab:** Manajemen data penerbangan, rute, status operasional real-time, gate, terminal, slot bandara.

**Endpoints Utama:**

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | `/v1/flights` | Cari penerbangan (origin, dest, tanggal) |
| GET | `/v1/flights/{id}` | Detail penerbangan |
| PUT | `/v1/flights/{id}/status` | Update status (SCHEDULED→BOARDING→DEPARTED) |
| GET | `/v1/flights/{id}/operational` | Data operasional (gate, actual time, delay) |
| GET | `/v1/routes` | Daftar rute aktif |
| GET | `/v1/airports/{code}/gates` | Gate tersedia di bandara |
| POST | `/v1/airport-slots` | Buat slot penerbangan |

**Status Lifecycle:**
```
SCHEDULED → CHECK_IN_OPEN → BOARDING → GATE_CLOSED → DEPARTED → IN_AIR → LANDED → ARRIVED
                                                    ↓
                                               DELAYED / CANCELLED
```

**Event yang Dipublikasikan ke RabbitMQ:**

| Event | Exchange | Routing Key | Consumer |
|-------|----------|-------------|----------|
| `FlightStatusChanged` | `flight.events` | `flight.status` | Notification, Booking |
| `FlightCancelled` | `flight.events` | `flight.cancelled` | Booking, Notification |
| `GateChanged` | `flight.events` | `flight.gate` | Notification |

---

### 9.4 Notification Service (Go)

**Tanggung Jawab:** Pengiriman notifikasi multi-channel (email, in-app) secara asinkron via worker pool.

**Channels:**
- **Email** — via Resend (production) / Mailtrap (development)
- **In-app Notification** — disimpan di `notifications` table, diambil oleh frontend via polling atau WebSocket

**RabbitMQ Consumers:**

| Queue | Event Source | Template | Channel |
|-------|--------------|----------|---------|
| `notif.booking.confirmed` | Booking Service | booking-confirmation.html | Email |
| `notif.payment.success` | Payment Service | payment-receipt.html | Email |
| `notif.flight.status` | Flight Ops Service | flight-update.html | Email + In-app |
| `notif.checkin.reminder` | Booking Service | checkin-reminder.html | Email |
| `notif.otp.email` | Passenger Service | otp-verification.html | Email |
| `notif.loyalty.miles` | Loyalty Service | miles-credited.html | Email + In-app |

**Retry Policy:**
- Max 3 kali retry dengan exponential backoff (1 menit, 5 menit, 15 menit)
- Setelah 3 kali gagal → pindah ke Dead Letter Queue (DLQ) dan alert ke tim ops

---

### 9.5 Booking Service (Quarkus)

**Tanggung Jawab:** Orkestrator utama proses pemesanan tiket menggunakan **Saga Pattern**. Mengkoordinasikan Inventory, Pricing, Payment, Loyalty, dan Notification.

**Endpoints Utama:**

| Method | Path | Deskripsi |
|--------|------|-----------|
| POST | `/v1/bookings` | Inisiasi booking baru (mulai Saga) |
| GET | `/v1/bookings/{pnr}` | Detail booking by PNR |
| PUT | `/v1/bookings/{pnr}/confirm` | Konfirmasi setelah payment |
| PUT | `/v1/bookings/{pnr}/cancel` | Cancel booking + refund trigger |
| PUT | `/v1/bookings/{pnr}/change` | Ubah penerbangan/kursi |
| POST | `/v1/bookings/{pnr}/check-in` | Proses check-in online |
| POST | `/v1/bookings/{pnr}/baggage` | Tambah bagasi |
| GET | `/v1/bookings/{pnr}/boarding-pass` | Generate boarding pass PDF (MinIO) |

**Booking Saga Flow (Orchestration):**
```
1. [Booking Svc]   Terima request, validasi format dan kelengkapan data
2. [Passenger Svc]  Validasi penumpang (exist + dokumen aktif) via REST; gagal → saga berhenti
3. [Inventory Svc]  Lock seat via gRPC (timeout 3 detik)
4. [Pricing Svc]    Hitung total harga (base fare + ancillary)
5. [Payment Svc]    Inisiasi payment request ke Xendit
6. [Payment Svc]    Tunggu webhook callback dari Xendit (async)
7. [Payment Svc]    Payment SUCCESS → publish PaymentCompleted event
8. [Booking Svc]    Confirm booking, generate PNR
9. [Inventory Svc]  Konfirmasi permanent seat assignment (release lock → assign)
10.[Loyalty Svc]    Publish event → credit miles (async)
11.[Notification]   Kirim konfirmasi booking via email (async)
```

**Saga Compensation (Rollback):**
- Step 2 gagal (penumpang invalid) → return error 400, tidak perlu kompensasi
- Step 3 gagal (seat tidak available) → return error 409
- Step 5/6 gagal (payment gagal) → release seat lock di Inventory
- Step 8 gagal → release seat lock, void payment di Payment Service

**Business Rules:**
- PNR (Passenger Name Record) di-generate otomatis: format `[A-Z]{2}[0-9]{4}` (contoh: `GA1234`)
- Penumpang dan dokumennya harus tervalidasi oleh Passenger Service sebelum booking diproses
- Booking harus selesai (payment confirmed) dalam 15 menit dari inisiasi
- Pembatalan > 24 jam sebelum departure: refund 100% (dikurangi fee admin)
- Pembatalan < 24 jam: refund 50%
- No-show (tidak check-in): no refund
- Maximum 9 penumpang per booking

---

### 9.6 Pricing Service (Quarkus)

**Tanggung Jawab:** Kalkulasi harga tiket berdasarkan fare class, tanggal, promosi, dan musim. Bertindak sebagai *fare engine*.

**Endpoints Utama:**

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | `/v1/prices/search` | Cari harga tiket (origin, dest, date, class) |
| GET | `/v1/prices/{flightId}` | Harga per flight per kelas |
| POST | `/v1/prices/calculate` | Kalkulasi total: base + taxes + ancillaries |
| GET | `/v1/promotions` | Daftar promosi aktif |
| POST | `/v1/promotions` | Buat promosi baru (admin) |
| GET | `/v1/prices/calendar` | Harga lowest fare per hari (kalender harga) |

**Pricing Logic:**

```
Total Fare = Base Fare × Multiplier(Class) + Taxes + Ancillaries - Discounts(Promo)

Kelas Multiplier:
  - Economy (Y): 1.0x
  - Economy Flex (B): 1.3x
  - Business (C): 2.5x
  - First (F): 4.0x

Taxes: PPN 11% + PJKP2U (Airport Tax) + Fuel Surcharge
Ancillaries: Bagasi + Meals + Seat Upgrade + Insurance
```

Konfigurasi pajak (PPN, airport tax, fuel surcharge) disimpan dalam tabel `tax_configurations` di `pricing_db` dan dapat diubah melalui endpoint admin `PUT /v1/admin/tax-rules` tanpa deployment ulang.

**Caching Strategy (Redis):**
- Harga dasar per rute per tanggal: TTL 30 menit
- Promosi aktif: TTL 5 menit (refresh sering)
- Lowest fare calendar: TTL 1 jam

---

### 9.7 Payment Service (Quarkus)

**Tanggung Jawab:** Pemrosesan pembayaran via Xendit, manajemen idempotensi, audit trail finansial, dan revenue accounting.

**Endpoints Utama:**

| Method | Path | Deskripsi |
|--------|------|-----------|
| POST | `/v1/payments` | Inisiasi pembayaran, return payment URL/VA |
| GET | `/v1/payments/{id}` | Status pembayaran |
| POST | `/v1/payments/webhook` | Terima webhook dari Xendit |
| POST | `/v1/payments/{id}/refund` | Inisiasi refund |
| GET | `/v1/revenue` | Laporan revenue (admin) |

**Payment Methods via Xendit:**
- Virtual Account (BCA, BNI, BRI, Mandiri, Permata)
- QRIS (semua e-wallet)
- Kartu Kredit/Debit (Visa, Mastercard)
- E-wallet (OVO, GoPay, Dana, ShopeePay)

**Idempotency:**
- Setiap payment request menyertakan `idempotency_key` (UUID dari Booking Service)
- Duplikat request dengan key yang sama return response yang sama tanpa transaksi ulang
- Key disimpan di Redis dengan TTL 24 jam

**Xendit Webhook Flow:**
```
Xendit → POST /v1/payments/webhook
       → Verify signature (X-CALLBACK-TOKEN header)
       → Update payment status di DB
       → Publish PaymentCompleted/PaymentFailed ke RabbitMQ
       → Booking Service mengonsumsi event → update booking status
```

---

### 9.8 Loyalty Service (Quarkus)

**Tanggung Jawab:** Program Frequent Flyer — akumulasi dan penukaran miles, manajemen tier, aturan ekspirasi miles.

**Endpoints Utama:**

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | `/v1/loyalty/{passengerId}` | Saldo miles dan info tier |
| GET | `/v1/loyalty/{passengerId}/transactions` | Riwayat transaksi miles |
| POST | `/v1/loyalty/{passengerId}/redeem` | Tukar miles untuk tiket/upgrade |
| POST | `/v1/loyalty/{passengerId}/reverse-miles` | Reverse miles untuk pembatalan (compensating transaction) |
| GET | `/v1/loyalty/tiers` | Daftar tier dan syarat kualifikasi |

**Tier System:**

| Tier | Miles/Tahun | Multiplier Earn | Benefit |
|------|-------------|-----------------|---------|
| Blue (Basic) | 0 – 24,999 | 1.0x | Standar |
| Silver | 25,000 – 49,999 | 1.25x | Priority check-in |
| Gold | 50,000 – 99,999 | 1.5x | Lounge access |
| Platinum | 100,000+ | 2.0x | Dedicated line, upgrade |

**Miles Earn Rules (Drools Engine):**
- Economy: 1 mile per 1 km
- Economy Flex: 1.3 miles per 1 km
- Business: 1.5 miles per 1 km + 500 bonus miles
- First: 2.0 miles per 1 km + 1000 bonus miles
- Promo rute tertentu: 2x atau 3x miles (dikonfigurasi di rule engine tanpa deploy ulang)

**Miles Expiry:**
- Miles berlaku 24 bulan dari tanggal kredit
- Aktivitas apapun (booking, redeem) mereset expiry ke +24 bulan

---

### 9.9 Crew Service (Quarkus)

**Tanggung Jawab:** Manajemen data kru penerbangan (pilot, cabin crew), penugasan pada penerbangan, dan kepatuhan regulasi jam terbang.

**Endpoints Utama:**

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | `/v1/crew` | Daftar kru aktif |
| GET | `/v1/crew/{id}` | Profil kru + sertifikasi |
| POST | `/v1/crew/assignments` | Tugaskan kru ke penerbangan |
| GET | `/v1/crew/{id}/schedule` | Jadwal terbang kru |
| GET | `/v1/flights/{id}/crew` | Kru yang ditugaskan di penerbangan |
| PUT | `/v1/crew/assignments/{id}` | Update atau ganti penugasan |

**Business Rules:**
- Pilot tidak boleh bertugas lebih dari 8 jam terbang berturut-turut (DGCA regulation)
- Setiap penerbangan memerlukan minimal 1 Captain + 1 First Officer
- Cabin crew ratio: 1 per 50 penumpang (minimal 2 untuk narrow body)
- Kru tidak bisa ditugaskan jika sertifikasi type-rating tidak sesuai pesawat

---

### 9.10 Maintenance Service (Quarkus)

**Tanggung Jawab:** Pencatatan perawatan pesawat dengan audit trail DGCA/FAA, approval workflow, dan manajemen komponen.

**Endpoints Utama:**

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | `/v1/maintenance` | Daftar rekaman perawatan |
| POST | `/v1/maintenance` | Buat rekaman perawatan baru |
| GET | `/v1/maintenance/{id}` | Detail rekaman + audit history |
| PUT | `/v1/maintenance/{id}/status` | Update status (PENDING→IN_PROGRESS→COMPLETED) |
| POST | `/v1/maintenance/{id}/approve` | Approval oleh head of engineering |
| GET | `/v1/aircrafts/{id}/maintenance-history` | Histori perawatan pesawat |

**Maintenance Status Workflow:**
```
REPORTED → ASSESSED → APPROVED → IN_PROGRESS → QA_CHECK → COMPLETED → CERTIFIED
               ↓           ↓
           REJECTED    AOG_HOLD (Aircraft on Ground — eskalasi)
```

**Audit Trail (Hibernate Envers):**
- Setiap perubahan pada `maintenance_records` otomatis dicatat di audit table
- Field yang diaudit: status, approved_by, parts_replaced, completed_at, notes
- Audit log tidak dapat dihapus (append-only policy)

---

## 10. Alur Bisnis Kritis (End-to-End Workflows)

### 10.1 Booking Flow (Happy Path)

```
Penumpang             Next.js            Kong Gateway         Services
    │                    │                    │                   │
    │──[1] Cari tiket───►│                    │                   │
    │                    │──[2] GET /flights──►│──►Flight Ops Svc  │
    │                    │◄──[3] Daftar flight─│◄──────────────────│
    │◄──[4] Tampilkan───►│                    │                   │
    │                    │                    │                   │
    │──[5] Pilih kursi──►│                    │                   │
    │                    │──[6] POST /seat-reservations──────────►Inventory Svc
    │                    │                    │     [Redis Lock]  │
    │                    │◄──[7] lockId────────────────────────────│
    │                    │                    │                   │
    │──[8] Submit form──►│                    │                   │
    │                    │──[9] POST /bookings──────────────────►Booking Svc
    │                    │                    │  [Saga starts]    │
    │                    │                    │──►GET passenger───►Passenger Svc
    │                    │                    │◄──valid─────────────│
    │                    │                    │──►GET price───────►Pricing Svc
    │                    │                    │◄──total fare───────│
    │                    │                    │──►POST payment────►Payment Svc
    │                    │                    │◄──payment URL──────│
    │◄──[10] Payment URL─│                    │                   │
    │                    │                    │                   │
    │──[11] Bayar───────────────────────────────────────────────►Xendit
    │◄──────────────────────────────────────────────────[Webhook]►Payment Svc
    │                    │                    │  PaymentCompleted │
    │                    │                    │──────────────────►Booking Svc
    │                    │                    │  [Confirm booking]│
    │                    │                    │──────────────────►Inventory Svc (assign seat)
    │                    │                    │  [Async events]   │
    │                    │                    │──────────────────►Loyalty Svc (credit miles)
    │                    │                    │──────────────────►Notif Svc (send email)
    │◄──[12] Email konfirmasi + PNR──────────────────────────────│
```

### 10.2 Check-in Online Flow

```
1. Penumpang akses check-in dengan PNR + last name
2. Booking Service validasi: booking CONFIRMED, penerbangan dalam 24 jam, belum check-in
3. Tampilkan seat map (via Inventory Service)
4. Penumpang konfirmasi kursi (atau pilih ulang jika available)
5. Booking Service update status check-in → CHECKED_IN
6. Generate boarding pass PDF → simpan di MinIO
7. Notification Service kirim boarding pass via email
8. Return boarding pass URL ke penumpang
```

### 10.3 Flight Status Update Flow

```
1. Ground ops update status penerbangan via admin panel
2. Flight Ops Service update DB + publish FlightStatusChanged event ke RabbitMQ
3. Notification Service consume event → kirim email/notif ke semua penumpang
4. Booking Service consume event (jika CANCELLED) → trigger kompensasi refund
5. Payment Service process refund ke Xendit
6. Loyalty Service reverse miles jika perlu
```

### 10.4 Pembatalan & Refund Flow

```
1. Penumpang atau agen request cancel via Booking Service
2. Booking Service hitung refund amount berdasarkan cancellation policy
3. Booking Service publish BookingCancelled event
4. Payment Service consume event → POST refund ke Xendit API
5. Seat dirilis kembali ke Inventory Service (seat available)
6. Loyalty Service reverse miles yang sudah dikreditkan
7. Notification Service kirim konfirmasi pembatalan + info refund
```

---

## 11. Infrastruktur & Integrasi

### 11.1 Kong API Gateway Configuration

```yaml
Services dan Routes yang didaftarkan di Kong:

Service: passenger-service
  Route: /v1/auth/*, /v1/passengers/*
  Plugins:
    - jwt (verifikasi token untuk protected routes)
    - rate-limiting (100 req/menit per IP untuk login)
    - request-transformer (tambah X-Request-ID header)
    - prometheus (metrics collection)

Service: booking-service
  Route: /v1/bookings/*
  Plugins:
    - jwt (required)
    - rate-limiting (30 req/menit per user)
    - correlation-id

Service: payment-service
  Route: /v1/payments/*
  Plugins:
    - jwt (required, kecuali /webhook)
    - ip-restriction (whitelist Xendit IP untuk /webhook)
    - request-size-limiting (1MB max)
```

### 11.2 RabbitMQ Exchange & Queue Design

```
Exchanges:
  booking.events    (type: topic, durable: true)
  flight.events     (type: topic, durable: true)
  payment.events    (type: topic, durable: true)
  loyalty.events    (type: topic, durable: true)
  notification.in   (type: direct, durable: true)

Queues & Bindings:
  booking.confirmed     → booking.events (routing: booking.confirmed)
  booking.cancelled     → booking.events (routing: booking.cancelled)
  payment.completed     → payment.events (routing: payment.completed)
  payment.failed        → payment.events (routing: payment.failed)
  flight.status.changed → flight.events  (routing: flight.status.*)
  notif.email.queue     → notification.in (key: email)
  notif.inapp.queue     → notification.in (key: inapp)

Dead Letter Queues (DLQ):
  notif.email.dlq       (TTL: 7 hari, max-length: 10000)
  booking.saga.dlq      (alert ke PagerDuty)
```

### 11.3 MinIO Bucket Structure

```
Buckets:
  passenger-documents/
    ├── {passengerId}/
    │   ├── passport_{docId}.pdf
    │   └── national_id_{docId}.pdf

  boarding-passes/
    ├── {year}/{month}/
    │   └── {pnr}_boarding_pass.pdf

  financial-reports/
    ├── {year}/{month}/
    │   └── revenue_report_{date}.xlsx

  maintenance-docs/
    ├── {aircraftId}/
    │   └── maintenance_{recordId}.pdf
```

### 11.4 Redis Key Naming Convention

```
Seat Locks:
  seat:lock:{flightId}:{seatId}         → {bookingSessionId}  TTL: 600s

Pricing Cache:
  price:{routeId}:{date}:{class}        → {priceJSON}         TTL: 1800s
  promo:active                           → {promoListJSON}     TTL: 300s
  fare:calendar:{routeId}:{month}       → {calendarJSON}      TTL: 3600s

Session:
  session:{userId}                       → {sessionJSON}       TTL: 86400s
  refresh:{userId}                       → {refreshToken}      TTL: 604800s

Rate Limiting (Kong menggunakan Redis):
  rl:{ip}:{endpoint}                     → {count}             TTL: 60s

Idempotency:
  idem:payment:{idempotencyKey}         → {responseJSON}      TTL: 86400s
```

---

## 12. Non-Functional Requirements (NFR)

### 12.1 Performance

| Service | Target Latency (P99) | Target Throughput |
|---------|----------------------|-------------------|
| Passenger Service | < 200 ms | 1,000 req/detik |
| Inventory Service (seat check) | < 50 ms | 10,000 req/detik |
| Inventory Service (seat lock) | < 10 ms | 5,000 ops/detik |
| Flight Ops Service | < 100 ms | 5,000 req/detik |
| Booking Service | < 500 ms | 500 req/detik |
| Pricing Service (cached) | < 30 ms | 3,000 req/detik |
| Pricing Service (uncached) | < 300 ms | 500 req/detik |
| Payment Service | < 2,000 ms | 200 req/detik |
| Notification Service | < 5,000 ms (email delivery) | 1,000 msg/detik |

### 12.2 Availability & Reliability

| Metrik | Target |
|--------|--------|
| System Uptime | ≥ 99.9% (max 8.7 jam downtime/tahun) |
| Core Services (Booking, Payment) | ≥ 99.95% |
| RTO (Recovery Time Objective) | < 5 menit |
| RPO (Recovery Point Objective) | < 1 menit (continuous streaming backup) |
| Mean Time Between Failures (MTBF) | > 720 jam |

### 12.3 Scalability

- Setiap service dapat di-scale secara **horizontal dan independen** via Kubernetes HPA
- Inventory Service: autoscale dari 2 → 20 pod dalam 2 menit saat seat lock rate > 1,000/detik
- Database: PostgreSQL dengan read replica untuk query berat (reporting)
- Redis: Redis Cluster mode untuk high availability

### 12.4 Security

- Semua komunikasi via **TLS 1.3** (internal dan eksternal)
- **JWT RS256** untuk autentikasi (public/private key pair)
- **Network Policy** Kubernetes: service hanya dapat diakses oleh service yang berwenang
- **Secrets management**: HashiCorp Vault atau Kubernetes Secrets (encrypted at rest)
- **PCI-DSS Level 1** compliance untuk Payment Service (no card data stored in-house, delegasi ke Xendit)
- Input validation dan sanitasi di semua service (mencegah SQL injection, XSS)

---

## 13. Observability & Monitoring

### 13.1 Metrics (Prometheus + Grafana)

**Metrics yang dikumpulkan per service:**

```
# Standard HTTP metrics (semua service via middleware)
http_requests_total{service, method, route, status_code}
http_request_duration_seconds{service, method, route, quantile}
http_requests_in_flight{service}

# Business metrics khusus
booking_created_total{status}
payment_processed_total{method, status}
seat_locks_active{flight_id}
seat_lock_duration_seconds
miles_credited_total{tier}
notification_sent_total{channel, template, status}

# Infrastructure metrics
go_goroutines{service}                     # Go services
jvm_memory_used_bytes{area}                # Quarkus services
pg_connections_active{database}            # PgBouncer
redis_connected_clients
rabbitmq_messages_ready{queue}
rabbitmq_messages_unacked{queue}
```

**Grafana Dashboards:**
- Service Health Overview (semua service dalam satu panel)
- Booking Funnel (search → lock → pay → confirm conversion)
- Payment Success Rate & Xendit Latency
- Seat Lock Contention (hot seat detection)
- RabbitMQ Queue Depth
- Infrastructure Resources (CPU, Memory, Network per pod)

**Alerting Rules (Prometheus Alertmanager → Slack/PagerDuty):**

| Alert | Kondisi | Severity |
|-------|---------|----------|
| ServiceDown | `up == 0` selama 1 menit | Critical |
| HighErrorRate | `error_rate > 5%` selama 2 menit | Critical |
| SlowResponse | `P99 latency > 2× target` selama 5 menit | Warning |
| QueueDepthHigh | `rabbitmq_messages_ready > 10000` | Warning |
| DatabaseConnectionExhausted | `pg_connections > 90% max` | Critical |
| PaymentWebhookFailed | DLQ count increasing | Critical |

### 13.2 Logging (ELK Stack)

**Log Format (JSON structured logging):**

```json
{
  "timestamp": "2025-01-15T10:30:00Z",
  "level": "INFO",
  "service": "booking-service",
  "trace_id": "abc123def456",
  "span_id": "xyz789",
  "user_id": "usr_12345",
  "request_id": "req_abcdef",
  "method": "POST",
  "path": "/v1/bookings",
  "status": 201,
  "duration_ms": 342,
  "message": "Booking created successfully",
  "pnr": "GA1234",
  "context": {
    "flight_id": "FL001",
    "passenger_count": 2
  }
}
```

**Log Levels:**
- `ERROR` — exception tidak tertangani, dependency failure
- `WARN` — retry attempt, slow query, approaching limit
- `INFO` — request lifecycle, business event
- `DEBUG` — detail internal (disabled di production)

**Logstash Pipeline:**
```
Service Pods → Filebeat (sidecar) → Logstash (parse + enrich) → Elasticsearch → Kibana
```

**Kibana Dashboards:**
- Error Rate per Service (last 1h/24h/7d)
- Slow Query Analysis
- Booking Journey Trace (correlated by trace_id)
- Security Audit (login attempts, failed auth)
- DLQ Monitoring

> **Catatan untuk Development & Staging:** Gunakan alternatif ringan **Loki + Fluent Bit** yang terintegrasi dengan Grafana untuk menghemat sumber daya. ELK Stack diaktifkan penuh hanya di production cluster.

---

## 14. CI/CD & GitOps Pipeline

### 14.1 Repository Structure

```
airline-management/
├── services/
│   ├── passenger-service/          # Go
│   ├── inventory-service/          # Go
│   ├── flight-ops-service/         # Go
│   ├── notification-service/       # Go
│   ├── booking-service/            # Quarkus
│   ├── pricing-service/            # Quarkus
│   ├── payment-service/            # Quarkus
│   ├── loyalty-service/            # Quarkus
│   ├── crew-service/               # Quarkus
│   └── maintenance-service/        # Quarkus
├── frontend/                       # Next.js
├── infrastructure/
│   ├── k8s/                        # Kubernetes manifests
│   ├── helm/                       # Helm charts per service
│   ├── kong/                       # Kong config
│   └── rabbitmq/                   # RabbitMQ config
└── gitops/                         # ArgoCD Application manifests
    ├── apps/
    │   ├── staging/
    │   └── production/
    └── applicationset.yaml
```

> **Penting:** Direktori `gitops/` hanya boleh diubah oleh Jenkins CI/CD pipeline. Developer tidak diperkenankan mengubah konten folder ini di branch feature. Gunakan `CODEOWNERS` di repository untuk melakukan enforce.

### 14.2 Jenkins CI Pipeline

```groovy
// Jenkinsfile (per service)
pipeline {
  agent { label 'docker' }
  
  stages {
    stage('Checkout') { ... }
    
    stage('Unit Test') {
      parallel {
        stage('Go Test')     { sh 'go test ./... -race -coverprofile=coverage.out' }
        stage('Quarkus Test') { sh './mvnw test' }
      }
    }
    
    stage('Code Quality') {
      sh 'sonar-scanner -Dsonar.projectKey=${SERVICE_NAME}'
      // Quality gate: coverage > 80%, no critical vulnerabilities
    }
    
    stage('Security Scan') {
      sh 'trivy fs . --exit-code 1 --severity HIGH,CRITICAL'
    }
    
    stage('Build Docker Image') {
      sh '''
        docker build -t ${REGISTRY}/${SERVICE_NAME}:${GIT_COMMIT} .
        docker tag ${REGISTRY}/${SERVICE_NAME}:${GIT_COMMIT} \
                   ${REGISTRY}/${SERVICE_NAME}:latest
      '''
    }
    
    stage('Push Image') {
      sh 'docker push ${REGISTRY}/${SERVICE_NAME}:${GIT_COMMIT}'
    }
    
    stage('Update GitOps Manifest') {
      sh '''
        cd gitops/apps/staging
        sed -i "s|image: .*${SERVICE_NAME}.*|image: ${REGISTRY}/${SERVICE_NAME}:${GIT_COMMIT}|" \
               ${SERVICE_NAME}/deployment.yaml
        git commit -am "ci: update ${SERVICE_NAME} to ${GIT_COMMIT}"
        git push
      '''
    }
  }
  
  post {
    failure { 
      slackSend channel: '#deployments', 
                message: "❌ CI FAILED: ${SERVICE_NAME} @ ${GIT_COMMIT}"
    }
  }
}
```

### 14.3 ArgoCD CD Pipeline

```yaml
# gitops/apps/staging/booking-service/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: booking-service-staging
  namespace: argocd
spec:
  project: airline-staging
  source:
    repoURL: https://github.com/org/airline-management
    targetRevision: main
    path: gitops/apps/staging/booking-service
  destination:
    server: https://kubernetes.default.svc
    namespace: airline-staging
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 3
      backoff:
        duration: 30s
        factor: 2
        maxDuration: 5m
```

**Deployment Strategy:**
- **Staging**: Auto-sync setelah Jenkins push manifest update
- **Production**: Manual sync (approval required via ArgoCD UI/CLI)
- **Strategy**: Rolling Update (default) atau Blue-Green untuk critical services (Payment, Booking)
- **Rollback**: `argocd app rollback booking-service-prod` — kembali ke revision sebelumnya dalam < 2 menit

**Environment Flow:**
```
Feature Branch → PR Review → Merge to main
    → Jenkins CI (test + build + push image)
    → Update staging manifest
    → ArgoCD auto-sync ke Staging
    → QA Testing di Staging
    → Manual promote: tag image → update production manifest
    → ArgoCD manual sync ke Production (approval gating)
```

---

## 15. Keamanan & Compliance

### 15.1 Authentication & Authorization

```
Penumpang / Agen → Kong (JWT Validation) → Service (X-User-ID header)

JWT Payload:
{
  "sub": "usr_12345",
  "role": "passenger | agent | admin | ops",
  "iat": 1705000000,
  "exp": 1705086400,
  "jti": "unique-token-id"
}

Role-Based Access Control (RBAC):
  passenger  → Read own data, create booking, check-in
  agent      → Read/write bookings, manage passengers
  ops        → Update flight status, gate assignment
  admin      → Full access kecuali payment audit
  finance    → Read payment data, revenue reports
  engineering → Maintenance records, crew management
```

### 15.2 PCI-DSS Compliance (Payment Service)

- **No card data storage**: data kartu tidak pernah menyentuh server kita; seluruhnya diproses Xendit
- **HTTPS only**: semua endpoint Payment Service hanya via HTTPS
- **Webhook signature verification**: verifikasi `X-CALLBACK-TOKEN` dari Xendit sebelum memproses
- **Audit logging**: setiap aksi payment dicatat dengan timestamp, user, IP, dan amount
- **Access control**: hanya Payment Service pod yang dapat mengakses `payment_db`
- **Encryption at rest**: PostgreSQL menggunakan transparent data encryption

### 15.3 DGCA/FAA Compliance (Maintenance Service)

- **Immutable audit trail**: Hibernate Envers mencatat setiap perubahan dengan timestamp dan user
- **Dual approval**: perbaikan kritikal memerlukan approval dari ≥2 insinyur berlisensi
- **Document retention**: maintenance records disimpan minimum 7 tahun
- **Part traceability**: setiap komponen yang diganti wajib tercatat dengan nomor seri

---

## 16. Database Schema & Ownership

### 16.1 Database per Service Mapping

```
passenger_db    ← Passenger Service (Go)
  tables: users, passengers, passenger_documents

inventory_db    ← Inventory Service (Go)
  tables: aircraft_types, aircrafts, cabin_configurations,
          aircraft_config_assignments, seats, seat_reservations

flight_db       ← Flight Ops Service (Go)
  tables: flights, routes, airport_slots, flight_operational_data,
          gates, terminals, runways

notif_db        ← Notification Service (Go)
  tables: notifications

booking_db      ← Booking Service (Quarkus)
  tables: bookings, booking_passengers, booking_segments,
          booking_ancillaries, check_ins, baggage

pricing_db      ← Pricing Service (Quarkus)
  tables: flight_prices, promotions, tax_configurations

payment_db      ← Payment Service (Quarkus)
  tables: payments, revenue_accounting

loyalty_db      ← Loyalty Service (Quarkus)
  tables: loyalty_accounts, loyalty_transactions

crew_db         ← Crew Service (Quarkus)
  tables: employees (data dasar kru), crew_members, flight_crew_assignments

maintenance_db  ← Maintenance Service (Quarkus)
  tables: maintenance_records, employees (data teknisi),
          maintenance_audit (Envers auto-generated)
```

> **Catatan:** Data dasar karyawan (nama, email, dsb.) saat ini diduplikasi di `crew_db` dan `maintenance_db` untuk kemandirian service. Di v1.0, seeding data karyawan dilakukan via migration script. Kedepannya, akan dibangun **Employee Service** sebagai single source of truth.

### 16.2 Cross-Service Data Access Rules

| Scenario | Solusi | Anti-Pattern yang Dihindari |
|----------|--------|------------------------------|
| Booking butuh info penumpang | Booking Svc call Passenger Svc REST API | Direct DB join lintas schema |
| Booking butuh harga | Booking Svc call Pricing Svc REST API | Shared pricing table |
| Flight Ops butuh aircraft info | Flight Ops Svc call Inventory Svc REST API | Shared aircraft table |
| Loyalty butuh info booking | Subscribe event `BookingCompleted` dari RabbitMQ | Polling booking_db |

### 16.3 Master Data Strategy

Data master lintas service (`countries`, `currencies`, `airports`) diakses melalui synchronous REST API, bukan direct DB join.

- `airports`: dimiliki oleh **Flight Ops Service**, diekspos via `GET /v1/airports` dan `GET /v1/airports/{code}`. Service lain (e.g., Passenger, Inventory) menyimpan cache lokal dengan TTL 1 jam.
- `countries`: dikelola oleh **Passenger Service**, endpoint `GET /v1/countries` untuk validasi nationality.
- `currencies`: dikelola oleh **Pricing Service**, endpoint `GET /v1/currencies` untuk kalkulasi harga.

Service yang membutuhkan data ini wajib memanggil service pemilik data (bukan mengakses langsung database). Untuk efisiensi, caching lokal diperbolehkan dengan TTL 1 jam.

---

## 17. API Contract & Communication Patterns

### 17.1 REST API Standards

```
Base URL: https://api.airline.com/v1

Request Headers:
  Content-Type: application/json
  Authorization: Bearer {jwt_token}
  X-Request-ID: {uuid}         # Untuk correlation/tracing
  X-Idempotency-Key: {uuid}    # Untuk POST yang idempotent (payment, booking)

Response Format (Success):
{
  "success": true,
  "data": { ... },
  "meta": {
    "request_id": "req_xyz",
    "timestamp": "2025-01-15T10:30:00Z"
  }
}

Response Format (Error):
{
  "success": false,
  "error": {
    "code": "SEAT_UNAVAILABLE",
    "message": "Kursi 12A sudah dipesan oleh penumpang lain",
    "details": { "seat_id": "12A", "flight_id": "FL001" }
  },
  "meta": { ... }
}

HTTP Status Codes:
  200 OK           → Sukses GET/PUT
  201 Created      → Sukses POST create
  400 Bad Request  → Validasi gagal
  401 Unauthorized → Token tidak valid/expired
  403 Forbidden    → Tidak punya akses
  404 Not Found    → Resource tidak ditemukan
  409 Conflict     → Duplikat atau state conflict (seat sudah di-lock)
  422 Unprocessable → Business rule violation
  429 Too Many Requests → Rate limit exceeded
  500 Internal Server Error → Error tidak terduga
```

### 17.2 gRPC Contract (Inventory ↔ Booking)

```protobuf
// inventory.proto
service InventoryService {
  rpc LockSeat(LockSeatRequest) returns (LockSeatResponse);
  rpc ReleaseSeat(ReleaseSeatRequest) returns (ReleaseSeatResponse);
  rpc ConfirmSeat(ConfirmSeatRequest) returns (ConfirmSeatResponse);
  rpc GetAvailableSeats(GetAvailableSeatsRequest) returns (GetAvailableSeatsResponse);
}

message LockSeatRequest {
  string flight_id = 1;
  string seat_id = 2;
  string booking_session_id = 3;
  int32 ttl_seconds = 4;  // default: 600
}

message LockSeatResponse {
  bool success = 1;
  string lock_id = 2;
  string error_code = 3;  // SEAT_UNAVAILABLE | SEAT_BLOCKED
  google.protobuf.Timestamp expires_at = 4;
}
```

### 17.3 RabbitMQ Event Schema

```json
// Envelope standar untuk semua event
{
  "event_id": "evt_uuid_v4",
  "event_type": "BookingConfirmed",
  "version": "1.0",
  "source_service": "booking-service",
  "timestamp": "2025-01-15T10:30:00Z",
  "correlation_id": "req_xyz",
  "payload": {
    // payload spesifik per event
  }
}

// Contoh: BookingConfirmed payload
{
  "pnr": "GA1234",
  "passenger_ids": ["usr_001", "usr_002"],
  "flight_id": "FL001",
  "total_amount": 1500000,
  "currency": "IDR",
  "seat_assignments": [
    {"passenger_id": "usr_001", "seat": "12A"},
    {"passenger_id": "usr_002", "seat": "12B"}
  ]
}
```

---

## 18. Milestones & Roadmap

### Phase 1 — Foundation (Bulan 1-2)
- [ ] Setup Kubernetes cluster + namespaces (dev, staging, prod)
- [ ] Setup Kong API Gateway + routing dasar
- [ ] Setup PostgreSQL per service + PgBouncer
- [ ] Setup Redis Cluster + MinIO
- [ ] Setup RabbitMQ dengan exchange & queue dasar
- [ ] Setup Jenkins pipeline (CI)
- [ ] Setup ArgoCD (CD)
- [ ] Implement Passenger Service (Go) — Auth + CRUD
- [ ] Implement Inventory Service (Go) — Aircraft + Seat data
- [ ] Setup ELK Stack (untuk prod) / Loki (untuk dev/staging) + Prometheus/Grafana dasar

### Phase 2 — Core Business (Bulan 3-4)
- [ ] Implement Flight Ops Service (Go) — Status update + events
- [ ] Implement Pricing Service (Quarkus) — Fare engine + caching
- [ ] Implement Booking Service (Quarkus) — Saga + PNR generation
- [ ] Implement seat locking via Redis di Inventory Service
- [ ] Implement Payment Service (Quarkus) — Xendit integration
- [ ] Implement Notification Service (Go) — Email via Resend
- [ ] End-to-end booking flow testing

### Phase 3 — Supporting Services (Bulan 5-6)
- [ ] Implement Loyalty Service (Quarkus) — Miles + Tier + Drools
- [ ] Implement Crew Service (Quarkus) — Assignment + compliance
- [ ] Implement Maintenance Service (Quarkus) — Audit trail + BPM
- [ ] Boarding pass generation (PDF via MinIO)
- [ ] Check-in online flow
- [ ] Cancellation & refund flow
- [ ] Admin dashboard (Next.js)

### Phase 4 — Hardening & Launch (Bulan 7-8)
- [ ] Load testing (k6) — target throughput validation
- [ ] Security penetration testing
- [ ] PCI-DSS audit & remediation
- [ ] Observabilitas penuh (alert rules, Grafana dashboards)
- [ ] Runbook & incident response documentation
- [ ] Blue-green deployment validation
- [ ] Soft launch (limited users)
- [ ] General availability (GA)

---

## 19. Risiko & Mitigasi

| # | Risiko | Probabilitas | Dampak | Mitigasi |
|---|--------|-------------|--------|----------|
| R1 | Xendit API downtime saat peak | Medium | Sangat Tinggi | Circuit breaker (Resilience4j), fallback ke VA manual, retry queue |
| R2 | Race condition seat booking saat promo flash sale | Tinggi | Tinggi | Redis atomic SETNX, Lua script untuk atomicity |
| R3 | Saga tidak konsisten (partial failure) | Medium | Tinggi | Idempotent compensating transactions, DLQ monitoring |
| R4 | PostgreSQL connection exhaustion | Medium | Tinggi | PgBouncer pool sizing, HPA scale-out, connection limit per service |
| R5 | RabbitMQ queue buildup | Medium | Sedang | Consumer autoscaling, DLQ alerting, prefetch limit tuning |
| R6 | JWT token leakage | Rendah | Sangat Tinggi | Short expiry (15 menit), refresh rotation, revocation via Redis |
| R7 | Compliance gap DGCA | Rendah | Sangat Tinggi | Hibernate Envers audit trail, regular compliance audit |
| R8 | Service dependency chain failure | Medium | Tinggi | Timeout + fallback per call, graceful degradation |

---

## 20. Glossary

| Istilah | Definisi |
|---------|----------|
| **PNR** | Passenger Name Record — kode booking unik 6 karakter |
| **Saga Pattern** | Pola manajemen transaksi terdistribusi dengan compensating transactions |
| **Bounded Context** | Domain bisnis yang memiliki model data dan logika sendiri (DDD) |
| **Seat Lock** | Reservasi sementara kursi via Redis sebelum payment dikonfirmasi |
| **DLQ** | Dead Letter Queue — antrean untuk pesan yang gagal diproses |
| **HPA** | Horizontal Pod Autoscaler — Kubernetes autoscaling berdasarkan metrics |
| **GitOps** | Praktik CD di mana Git repository adalah source of truth untuk state infrastruktur |
| **PCI-DSS** | Payment Card Industry Data Security Standard |
| **DGCA** | Direktorat Jenderal Perhubungan Udara — regulator penerbangan Indonesia |
| **Envers** | Hibernate module untuk audit trail otomatis |
| **OptaPlanner** | Library Java untuk constraint-based optimization (penjadwalan kru) |
| **Drools/Kogito** | Rule engine Java untuk business rules management |
| **gRPC** | Protocol untuk synchronous service-to-service communication berbasis Protobuf |
| **Blue-Green** | Deployment strategy dengan dua environment identik untuk zero-downtime rollout |
| **MTTR** | Mean Time to Recovery — rata-rata waktu pemulihan setelah insiden |

---

*Dokumen ini bersifat living document. Setiap perubahan harus melalui review Engineering Lead dan Product Manager, serta didokumentasikan di changelog di bawah ini.*

**Changelog:**

| Versi | Tanggal | Perubahan | Author |
|-------|---------|-----------|--------|
| 1.0.0 | 2025 | Initial PRD — revised architecture with final service allocation | Engineering Team |
| 1.0.1 | 2025 | Minor revision: tambah validasi penumpang di Saga Booking, endpoint reverse-miles, strategi master data, catatan Loki untuk dev/staging, proteksi direktori gitops, konfigurasi pajak di Pricing, catatan duplikasi employee | Engineering Team |
```