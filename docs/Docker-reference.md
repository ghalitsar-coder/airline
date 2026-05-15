Berikut adalah konfigurasi **Dockerfile** untuk masing-masing service dan **docker-compose.yaml** yang siap digunakan untuk development environment. Semua file mengikuti struktur monorepo yang sudah Anda miliki.

---

## 1. Dockerfile per Service

Kita akan membuat 10 Dockerfile. Karena direktori service masih kosong, ini menjadi template standar yang bisa langsung dipakai begitu kode mulai ditulis.

### 1.1 Go Services (Passenger, Inventory, Flight Ops, Notification)
Semua Go service memiliki struktur yang hampir sama. Bedakan hanya pada `EXPOSE` port.

**`services/passenger-service/Dockerfile`**
```dockerfile
# Stage 1: Build
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/main.go

# Stage 2: Run
FROM alpine:3.19
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/server .
EXPOSE 8001
CMD ["./server"]
```

**`services/inventory-service/Dockerfile`**
```dockerfile
# Sama seperti passenger, hanya port berbeda
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/main.go

FROM alpine:3.19
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/server .
EXPOSE 8002
CMD ["./server"]
```

**`services/flight-ops-service/Dockerfile`** → expose `8003`

**`services/notification-service/Dockerfile`** → expose `8004`

> Pola sama, cukup salin dan ganti port.

### 1.2 Quarkus Services (Booking, Pricing, Payment, Loyalty, Crew, Maintenance)
Semua Quarkus service menggunakan build JVM (untuk dev) dan menjalankan Quarkus runner JAR.

**`services/booking-service/Dockerfile`**
```dockerfile
# Stage 1: Build with Maven
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# Stage 2: Run with JRE
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/quarkus-app/lib/ ./lib/
COPY --from=builder /app/target/quarkus-app/*.jar ./
COPY --from=builder /app/target/quarkus-app/app/ ./app/
COPY --from=builder /app/target/quarkus-app/quarkus/ ./quarkus/
EXPOSE 8005
ENTRYPOINT ["java", "-jar", "quarkus-run.jar"]
```

**`services/pricing-service/Dockerfile`** → expose `8006`  
**`services/payment-service/Dockerfile`** → expose `8007`  
**`services/loyalty-service/Dockerfile`** → expose `8008`  
**`services/crew-service/Dockerfile`** → expose `8009`  
**`services/maintenance-service/Dockerfile`** → expose `8010`  

> Semua Quarkus service persis sama, hanya ganti port.

---

## 2. Inisialisasi Database PostgreSQL

Buat script untuk membuat banyak database sekaligus di container PostgreSQL.

**`infrastructure/postgres/init-multiple-dbs.sh`**
```bash
#!/bin/bash
set -e
set -u

function create_database() {
    local database=$1
    echo "  Creating database '$database'"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        CREATE DATABASE $database;
EOSQL
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
    echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
    for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
        create_database $db
    done
    echo "Multiple databases created"
fi
```
 
---

## 3. Penjelasan dan Cara Pakai

### Struktur Konfigurasi
- Semua service backend akan mengakses database, Redis, RabbitMQ, dan MinIO dengan hostname sesuai nama service di compose (misal `postgres`, `redis`).
- Environment variables sudah disesuaikan dengan kebutuhan tiap service.
- Booking Service bergantung pada Passenger, Inventory, Pricing, Payment Service untuk orkestrasi Saga.
- Xendit API keys disediakan via `${}` dari file `.env` (tidak perlu commit ke Git). Buat file `.env` di root dengan isi:
  ```
  XENDIT_API_KEY=your_key
  XENDIT_CALLBACK_TOKEN=your_token
  ```

### Menjalankan Development
```bash
# Dari root direktori
docker-compose up -d
```
Tunggu semua container sehat. Cek status:
```bash
docker-compose ps
```
Akses service langsung via port yang diexpose, misal:
- Passenger Service: `http://localhost:8001`
- RabbitMQ Management: `http://localhost:15672`
- MinIO Console: `http://localhost:9001`

### Catatan Penting
1. **Database terpisah**: `init-multiple-dbs.sh` sudah membuat 10 database. Setiap service mengakses database sendiri melalui variabel `DB_NAME`.
2. **RabbitMQ**: Exchange/queue akan dibuat otomatis oleh kode aplikasi saat startup. Gunakan management UI untuk cek.
3. **MinIO**: Bucket `passenger-documents` dll perlu dibuat manual via console atau via `mc` client. Bisa ditambahkan script healthcheck nanti.
4. **ELK, Kong, Jenkins, ArgoCD** tidak disertakan di compose ini karena ditujukan untuk development lokal yang ringan. Mereka akan di-deploy terpisah di cluster Kubernetes production.

---

Dengan konfigurasi ini, seluruh tim dapat langsung memulai koding dengan menjalankan `docker-compose up` dan semua infrastruktur serta service sudah terhubung.