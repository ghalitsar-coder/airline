# Konfigurasi Environment Umum
common_env = {
    'DB_HOST': 'localhost',
    'DB_USER': 'airline',
    'DB_PASSWORD': 'postgres',
    'REDIS_URL': 'redis://localhost:6379',
    'RABBITMQ_URL': 'amqp://guest:guest@localhost:5672',
    'MINIO_ENDPOINT': 'localhost:9000',
    'MINIO_ACCESS_KEY': 'minioadmin',
    'MINIO_SECRET_KEY': 'minioadmin',
    'JWT_SECRET': 'airline-jwt-secret-dev',
    'SERVICE_API_KEY': 'airline-internal-dev-key',
    'PASSENGER_SERVICE_URL': 'http://localhost:8001',
    'PASSENGER_SERVICE_API_KEY': 'airline-internal-dev-key',
    'INVENTORY_SERVICE_URL': 'http://localhost:8002',
    'PRICING_SERVICE_URL': 'http://localhost:8006',
    'PAYMENT_SERVICE_URL': 'http://localhost:8007',
    'QUARKUS_CONSOLE_ENABLED': 'false'
}

# Fungsi untuk mempermudah pendaftaran Go Services
def go_service(name, port, db_name, extra_env={}):
    env = dict(common_env)
    env.update({'PORT': str(port), 'DB_NAME': db_name})
    env.update(extra_env)
    
    local_resource(
        name,
        serve_cmd='cd services/' + name + ' && ~/.local/share/mise/shims/air --build.cmd "go build -o tmp/main ./cmd/main.go" --build.bin "./tmp/main"',
        env=env
    )

# Fungsi untuk mempermudah pendaftaran Quarkus Services
def quarkus_service(name, port, db_name, extra_env={}):
    env = dict(common_env)
    env.update({'PORT': str(port), 'DB_NAME': db_name})
    env.update(extra_env)
    
    local_resource(
        name,
        serve_cmd='cd services/' + name + ' && mvn compile quarkus:dev -Dquarkus.http.port=' + str(port),
        env=env
    )

# Daftarkan semua Go Services
go_service('passenger-service', 8001, 'passenger_db')
go_service('inventory-service', 8002, 'inventory_db')
go_service('flight-ops-service', 8003, 'flight_db')
go_service('notification-service', 8004, 'notif_db', {'SMTP_HOST': 'localhost', 'SMTP_PORT': '2525'})

# Daftarkan semua Quarkus Services
quarkus_service('booking-service', 8005, 'booking_db')
quarkus_service('pricing-service', 8006, 'pricing_db')
# quarkus_service('payment-service', 8007, 'payment_db')
# quarkus_service('loyalty-service', 8008, 'loyalty_db')
# quarkus_service('crew-service', 8009, 'crew_db')
# quarkus_service('maintenance-service', 8010, 'maintenance_db')
