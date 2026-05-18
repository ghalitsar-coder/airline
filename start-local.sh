#!/bin/bash

# Pastikan berada di root direktori project
cd "$(dirname "$0")"

if [ -f .env ]; then
  echo "Memuat environment variables dari .env..."
  set -a
  source .env
  set +a
fi

echo "Menghentikan service Docker agar port tidak bentrok..."
docker compose stop passenger-service inventory-service flight-ops-service notification-service booking-service pricing-service payment-service loyalty-service crew-service maintenance-service

# Trap SIGINT (Ctrl+C) untuk mematikan semua background jobs
trap 'echo -e "\nMematikan semua services..."; kill $(jobs -p) 2>/dev/null; exit' SIGINT SIGTERM EXIT

# Common Environment Variables
export DB_HOST=localhost
export DB_USER=airline
export DB_PASSWORD=postgres
export REDIS_URL=redis://localhost:6379
export RABBITMQ_URL=amqp://guest:guest@localhost:5672
export MINIO_ENDPOINT=localhost:9000
export MINIO_ACCESS_KEY=minioadmin
export MINIO_SECRET_KEY=minioadmin
export JWT_SECRET=${JWT_SECRET:-airline-jwt-secret-dev}
export SERVICE_API_KEY=${SERVICE_API_KEY:-airline-internal-dev-key}

# Service Specific Endpoints (for inter-service comms)
export PASSENGER_SERVICE_URL=http://localhost:8001
export PASSENGER_SERVICE_API_KEY=$SERVICE_API_KEY
export INVENTORY_SERVICE_URL=http://localhost:8002
export PRICING_SERVICE_URL=http://localhost:8006
export PAYMENT_SERVICE_URL=http://localhost:8007

# Nonaktifkan interactive console Quarkus agar tidak bentrok di terminal yang sama
export QUARKUS_CONSOLE_ENABLED=false

echo "Memulai Go Services..."
(cd services/passenger-service && export DB_NAME=passenger_db PORT=8001 && go run ./cmd/main.go) 2>&1 | sed 's/^/[PASSENGER] /' &
(cd services/inventory-service && export DB_NAME=inventory_db PORT=8002 && go run ./cmd/main.go) 2>&1 | sed 's/^/[INVENTORY] /' &
(cd services/flight-ops-service && export DB_NAME=flight_db PORT=8003 && go run ./cmd/main.go) 2>&1 | sed 's/^/[FLIGHT] /' &
(cd services/notification-service && export DB_NAME=notif_db PORT=8004 SMTP_HOST=localhost SMTP_PORT=2525 && go run ./cmd/main.go) 2>&1 | sed 's/^/[NOTIF] /' &

echo "Memulai Quarkus Services..."
(cd services/booking-service && export DB_NAME=booking_db PORT=8005 && mvn compile quarkus:dev -Dquarkus.http.port=$PORT) 2>&1 | sed 's/^/[BOOKING] /' &
(cd services/pricing-service && export DB_NAME=pricing_db PORT=8006 && mvn compile quarkus:dev -Dquarkus.http.port=$PORT) 2>&1 | sed 's/^/[PRICING] /' &
(cd services/payment-service && export DB_NAME=payment_db PORT=8007 && mvn compile quarkus:dev -Dquarkus.http.port=$PORT) 2>&1 | sed 's/^/[PAYMENT] /' &
(cd services/loyalty-service && export DB_NAME=loyalty_db PORT=8008 && mvn compile quarkus:dev -Dquarkus.http.port=$PORT) 2>&1 | sed 's/^/[LOYALTY] /' &
(cd services/crew-service && export DB_NAME=crew_db PORT=8009 && mvn compile quarkus:dev -Dquarkus.http.port=$PORT) 2>&1 | sed 's/^/[CREW] /' &
(cd services/maintenance-service && export DB_NAME=maintenance_db PORT=8010 && mvn compile quarkus:dev -Dquarkus.http.port=$PORT) 2>&1 | sed 's/^/[MAINTENANCE] /' &

echo "Semua service sedang berjalan! Tekan Ctrl+C untuk menghentikan semua."
wait
