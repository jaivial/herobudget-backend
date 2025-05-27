# Guía de Despliegue para TestFlight - Hero Budget

## Índice
1. [Introducción y Decisiones Arquitectónicas](#introducción-y-decisiones-arquitectónicas)
2. [Preparación del VPS](#preparación-del-vps)
3. [Migración de Base de Datos](#migración-de-base-de-datos)
4. [Configuración de Microservicios](#configuración-de-microservicios)
5. [Configuración de Dominio y HTTPS](#configuración-de-dominio-y-https)
6. [Cambios en la App Flutter](#cambios-en-la-app-flutter)
7. [Configuración de TestFlight](#configuración-de-testflight)
8. [Scripts de Automatización](#scripts-de-automatización)
9. [Monitoreo y Mantenimiento](#monitoreo-y-mantenimiento)

## Introducción y Decisiones Arquitectónicas

### ¿Por qué no ejecutar microservicios en el móvil?

**Los microservicios de Go NO pueden ejecutarse en el móvil iOS** por las siguientes razones:

1. **Restricciones de iOS**: Apple no permite que las apps ejecuten servidores HTTP en producción
2. **Sandboxing**: Las apps están aisladas y no pueden abrir puertos de red
3. **Recursos limitados**: Los microservicios consumirían batería y memoria excesivamente
4. **Seguridad**: Exponer servicios desde el móvil sería un riesgo de seguridad
5. **App Store Guidelines**: Violaría las políticas de Apple

### Arquitectura Recomendada: VPS

**La mejor opción es desplegar en tu VPS** porque:

✅ **Ventajas del VPS:**
- Control total sobre el entorno
- Recursos dedicados y escalables
- Posibilidad de usar HTTPS con certificados SSL
- Base de datos centralizada y persistente
- Backup y recuperación más fáciles
- Mejor rendimiento y disponibilidad
- Cumple con las mejores prácticas de arquitectura móvil

## Preparación del VPS

### 1. Requisitos del Servidor

```bash
# Especificaciones mínimas recomendadas
CPU: 2 vCPUs
RAM: 4GB
Almacenamiento: 40GB SSD
OS: Ubuntu 20.04 LTS o superior
```

### 2. Instalación de Dependencias

```bash
# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Instalar Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Instalar PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# Instalar Nginx
sudo apt install nginx -y

# Instalar Certbot para SSL
sudo apt install certbot python3-certbot-nginx -y

# Instalar herramientas adicionales
sudo apt install git htop curl wget unzip -y
```

### 3. Configuración de PostgreSQL

```bash
# Cambiar a usuario postgres
sudo -u postgres psql

# Crear base de datos y usuario
CREATE DATABASE herobudget;
CREATE USER herobudget_user WITH ENCRYPTED PASSWORD 'tu_password_seguro';
GRANT ALL PRIVILEGES ON DATABASE herobudget TO herobudget_user;
\q

# Configurar PostgreSQL para conexiones remotas
sudo nano /etc/postgresql/14/main/postgresql.conf
# Cambiar: listen_addresses = 'localhost' por listen_addresses = '*'

sudo nano /etc/postgresql/14/main/pg_hba.conf
# Agregar: host herobudget herobudget_user 0.0.0.0/0 md5

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

## Migración de Base de Datos

### 1. Exportar Datos de SQLite

```bash
# En tu máquina local, navegar al directorio del proyecto
cd /Users/usuario/Documents/PROYECTOS/herobudgetflutter/hero_budget

# Exportar datos de SQLite a SQL
sqlite3 backend/google_auth/users.db .dump > users_export.sql

# Crear script de migración
cat > migrate_to_postgresql.sql << 'EOF'
-- Crear tabla users en PostgreSQL
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    google_id TEXT UNIQUE,
    email TEXT UNIQUE,
    name TEXT,
    given_name TEXT,
    family_name TEXT,
    picture TEXT,
    locale TEXT,
    verified_email BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
EOF

# Limpiar el export de SQLite para PostgreSQL
sed 's/INTEGER PRIMARY KEY AUTOINCREMENT/SERIAL PRIMARY KEY/g' users_export.sql > users_postgresql.sql
sed -i 's/DATETIME DEFAULT CURRENT_TIMESTAMP/TIMESTAMP DEFAULT CURRENT_TIMESTAMP/g' users_postgresql.sql
```

### 2. Importar a PostgreSQL en VPS

```bash
# Copiar archivos al VPS
scp migrate_to_postgresql.sql users_postgresql.sql root@178.16.130.178:/root/

# En el VPS, importar datos
sudo -u postgres psql -d herobudget -f /root/migrate_to_postgresql.sql
sudo -u postgres psql -d herobudget -f /root/users_postgresql.sql
```

### 3. Verificar Migración

```bash
# Conectar a PostgreSQL y verificar
sudo -u postgres psql -d herobudget

# Verificar tablas y datos
\dt
SELECT COUNT(*) FROM users;
SELECT * FROM users LIMIT 5;
\q
```

## Configuración de Microservicios

### 1. Crear Estructura de Directorios en VPS

```bash
# En el VPS
mkdir -p /opt/herobudget/{backend,logs,scripts}
cd /opt/herobudget
```

### 2. Modificar Código para PostgreSQL

Crear archivo de configuración de base de datos:

```bash
# En el VPS
cat > /opt/herobudget/backend/db_config.go << 'EOF'
package main

import (
    "database/sql"
    "fmt"
    "log"
    "os"
    
    _ "github.com/lib/pq"
)

var db *sql.DB

func initDB() {
    dbHost := getEnv("DB_HOST", "localhost")
    dbPort := getEnv("DB_PORT", "5432")
    dbUser := getEnv("DB_USER", "herobudget_user")
    dbPassword := getEnv("DB_PASSWORD", "tu_password_seguro")
    dbName := getEnv("DB_NAME", "herobudget")
    
    psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
        dbHost, dbPort, dbUser, dbPassword, dbName)
    
    var err error
    db, err = sql.Open("postgres", psqlInfo)
    if err != nil {
        log.Fatal("Error connecting to database:", err)
    }
    
    if err = db.Ping(); err != nil {
        log.Fatal("Error pinging database:", err)
    }
    
    log.Println("Successfully connected to PostgreSQL database")
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
EOF
```

### 3. Crear Variables de Entorno

```bash
# En el VPS
cat > /opt/herobudget/.env << 'EOF'
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=herobudget_user
DB_PASSWORD=tu_password_seguro
DB_NAME=herobudget

# Server Configuration
SERVER_HOST=0.0.0.0
DOMAIN=herobudget.jaimedigitalstudio.com

# Google OAuth (actualizar con tus credenciales)
GOOGLE_CLIENT_ID=204913639838-lt4jcl1cc0b9qjq4lh8ef6u19trudech.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
GOOGLE_REDIRECT_URL=https://herobudget.jaimedigitalstudio.com/auth/google/callback
EOF
```

### 4. Copiar y Modificar Microservicios

```bash
# En tu máquina local, crear script de despliegue
cat > deploy_to_vps.sh << 'EOF'
#!/bin/bash

VPS_IP="178.16.130.178"
VPS_USER="root"
DOMAIN="herobudget.jaimedigitalstudio.com"

# Lista de servicios
services=(
    "google_auth"
    "signup"
    "language_cookie"
    "signin"
    "reset_password"
    "fetch_dashboard"
    "dashboard_data"
    "budget_management"
    "savings_management"
    "cash_bank_management"
    "bills_management"
    "profile_management"
    "income_management"
    "expense_management"
    "categories_management"
    "money_flow_sync"
    "budget_overview_fetch"
)

echo "Deploying Hero Budget microservices to VPS..."

# Copiar archivos comunes
scp -r backend/ $VPS_USER@$VPS_IP:/opt/herobudget/
scp .env $VPS_USER@$VPS_IP:/opt/herobudget/

# Para cada servicio, modificar URLs y desplegar
for service in "${services[@]}"; do
    echo "Processing $service..."
    
    # Crear versión modificada para producción
    cp -r backend/$service backend/${service}_prod
    
    # Reemplazar localhost por dominio
    find backend/${service}_prod -name "*.go" -exec sed -i.bak "s/localhost:80[0-9][0-9]/$DOMAIN/g" {} \;
    find backend/${service}_prod -name "*.go" -exec sed -i.bak "s/http:/https:/g" {} \;
    
    # Copiar al VPS
    scp -r backend/${service}_prod/ $VPS_USER@$VPS_IP:/opt/herobudget/backend/$service/
    
    # Limpiar archivos temporales
    rm -rf backend/${service}_prod
done

echo "Deployment completed!"
EOF

chmod +x deploy_to_vps.sh
```

### 5. Crear Systemd Services

```bash
# En el VPS, primero crear usuario para los servicios (recomendado para seguridad)
useradd -r -s /bin/false herobudget
chown -R herobudget:herobudget /opt/herobudget

# Crear template de servicio
cat > /opt/herobudget/scripts/create_services.sh << 'EOF'
#!/bin/bash

services=(
    "google_auth:8081"
    "signup:8082"
    "language_cookie:8083"
    "signin:8084"
    "fetch_dashboard:8085"
    "reset_password:8086"
    "dashboard_data:8087"
    "budget_management:8088"
    "savings_management:8089"
    "cash_bank_management:8090"
    "bills_management:8091"
    "profile_management:8092"
    "income_management:8093"
    "expense_management:8094"
    "categories_management:8095"
    "money_flow_sync:8096"
    "budget_overview_fetch:8097"
)

for service_port in "${services[@]}"; do
    IFS=':' read -r service port <<< "$service_port"
    
    cat > /etc/systemd/system/herobudget-$service.service << EOL
[Unit]
Description=Hero Budget $service Service
After=network.target postgresql.service

[Service]
Type=simple
User=herobudget
Group=herobudget
WorkingDirectory=/opt/herobudget/backend/$service
ExecStart=/opt/herobudget/backend/$service/$service
EnvironmentFile=/opt/herobudget/.env
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOL

    systemctl enable herobudget-$service
done

echo "All systemd services created and enabled!"
EOF

chmod +x /opt/herobudget/scripts/create_services.sh
/opt/herobudget/scripts/create_services.sh
```

## Configuración de Dominio y HTTPS

### 1. Configurar DNS

En tu proveedor de dominio (jaimedigitalstudio.com), crear el siguiente registro DNS:

```
A    herobudget.jaimedigitalstudio.com    178.16.130.178
```

**Configuración DNS específica:**
- **Tipo de registro**: A
- **Nombre/Host**: herobudget
- **Valor/Destino**: 178.16.130.178
- **TTL**: 3600 (1 hora) o el valor por defecto de tu proveedor

**Nota**: No necesitas crear `api.herobudget.jaimedigitalstudio.com` ya que todos los servicios estarán bajo el mismo dominio con diferentes rutas.

### 2. Configurar Nginx

**Opción A: Archivo separado (recomendado)**

```bash
# En el VPS - Como ya tienes nginx configurado, agrega este bloque a tu configuración existente
cat > /etc/nginx/sites-available/herobudget << 'EOF'
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name herobudget.jaimedigitalstudio.com;
    return 301 https://$server_name$request_uri;
}

# Main HTTPS server
server {
    listen 443 ssl http2;
    server_name herobudget.jaimedigitalstudio.com;

    # SSL Configuration (will be added by Certbot)
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Microservices proxy
    location /auth/ {
        proxy_pass http://localhost:8081/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /signup/ {
        proxy_pass http://localhost:8082/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /language/ {
        proxy_pass http://localhost:8083/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /signin/ {
        proxy_pass http://localhost:8084/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /dashboard/ {
        proxy_pass http://localhost:8085/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /reset-password/ {
        proxy_pass http://localhost:8086/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /dashboard-data/ {
        proxy_pass http://localhost:8087/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /budget/ {
        proxy_pass http://localhost:8088/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /savings/ {
        proxy_pass http://localhost:8089/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /cash-bank/ {
        proxy_pass http://localhost:8090/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /bills/ {
        proxy_pass http://localhost:8091/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /profile/ {
        proxy_pass http://localhost:8092/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /income/ {
        proxy_pass http://localhost:8093/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /expenses/ {
        proxy_pass http://localhost:8094/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /categories/ {
        proxy_pass http://localhost:8095/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /money-flow/ {
        proxy_pass http://localhost:8096/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /budget-overview/ {
        proxy_pass http://localhost:8097/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Habilitar el sitio (solo si no tienes configuración existente)
ln -s /etc/nginx/sites-available/herobudget /etc/nginx/sites-enabled/

# Si ya tienes nginx configurado, puedes agregar el bloque server directamente 
# a tu archivo de configuración existente en lugar de crear uno nuevo

# Verificar configuración y recargar
nginx -t
systemctl reload nginx
```

**Opción B: Integrar en configuración existente**

Si prefieres agregar el subdominio a tu configuración existente de `jaimedigitalstudio.com`, puedes agregar este bloque server a tu archivo de configuración actual:

```bash
# Agregar al archivo existente de nginx (probablemente en /etc/nginx/sites-available/jaimedigitalstudio.com)
# Agrega estos bloques server al final del archivo:

# Hero Budget - Redirect HTTP to HTTPS
server {
    listen 80;
    server_name herobudget.jaimedigitalstudio.com;
    return 301 https://$server_name$request_uri;
}

# Hero Budget - Main HTTPS server
server {
    listen 443 ssl http2;
    server_name herobudget.jaimedigitalstudio.com;

    # Usar los mismos certificados SSL que tu dominio principal
    ssl_certificate /etc/letsencrypt/live/jaimedigitalstudio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/jaimedigitalstudio.com/privkey.pem;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Microservices proxy (mismas configuraciones que en la Opción A)
    location /auth/ {
        proxy_pass http://localhost:8081/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # ... (resto de las configuraciones de location como en la Opción A)
}
```

Después de agregar la configuración, verifica y recarga:

```bash
nginx -t
systemctl reload nginx
```

### 3. Obtener Certificado SSL

**Opción A: Certificado separado para el subdominio**

```bash
# En el VPS
sudo certbot --nginx -d herobudget.jaimedigitalstudio.com

# Configurar renovación automática (si no la tienes ya configurada)
sudo crontab -e
# Agregar: 0 12 * * * /usr/bin/certbot renew --quiet
```

**Opción B: Agregar subdominio al certificado existente (recomendado)**

Si ya tienes un certificado wildcard o quieres agregar el subdominio al certificado existente:

```bash
# Expandir certificado existente para incluir el subdominio
sudo certbot --nginx -d jaimedigitalstudio.com -d www.jaimedigitalstudio.com -d herobudget.jaimedigitalstudio.com

# O si tienes otros subdominios, agrégalos todos:
# sudo certbot --nginx -d jaimedigitalstudio.com -d www.jaimedigitalstudio.com -d herobudget.jaimedigitalstudio.com -d otrosubdominio.jaimedigitalstudio.com
```

**Verificar certificado:**

```bash
# Verificar que el certificado incluye el subdominio
sudo certbot certificates

# Probar el certificado
curl -I https://herobudget.jaimedigitalstudio.com/health
```

## Cambios en la App Flutter

### 1. Crear Configuración de Entorno

```dart
// lib/config/environment.dart
class Environment {
  static const String _baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://herobudget.jaimedigitalstudio.com',
  );
  
  static const bool _isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
  
  static String get baseUrl => _baseUrl;
  static bool get isProduction => _isProduction;
  
  // URLs de servicios
  static String get authUrl => '$baseUrl/auth';
  static String get signupUrl => '$baseUrl/signup';
  static String get languageUrl => '$baseUrl/language';
  static String get signinUrl => '$baseUrl/signin';
  static String get dashboardUrl => '$baseUrl/dashboard';
  static String get resetPasswordUrl => '$baseUrl/reset-password';
  static String get dashboardDataUrl => '$baseUrl/dashboard-data';
  static String get budgetUrl => '$baseUrl/budget';
  static String get savingsUrl => '$baseUrl/savings';
  static String get cashBankUrl => '$baseUrl/cash-bank';
  static String get billsUrl => '$baseUrl/bills';
  static String get profileUrl => '$baseUrl/profile';
  static String get incomeUrl => '$baseUrl/income';
  static String get expensesUrl => '$baseUrl/expenses';
  static String get categoriesUrl => '$baseUrl/categories';
  static String get moneyFlowUrl => '$baseUrl/money-flow';
  static String get budgetOverviewUrl => '$baseUrl/budget-overview';
}
```

### 2. Actualizar Servicios

Ejemplo para `lib/services/auth_service.dart`:

```dart
import '../config/environment.dart';

class AuthService {
  static const String baseUrl = Environment.authUrl;
  
  // Resto del código...
}
```

### 3. Actualizar Todos los Servicios

```bash
# Script para actualizar URLs en servicios
cat > update_service_urls.sh << 'EOF'
#!/bin/bash

services=(
    "auth_service.dart"
    "savings_service.dart"
    "profile_service.dart"
    "signin_service.dart"
    "dashboard_service.dart"
    "language_service.dart"
    # Agregar todos los servicios
)

for service in "${services[@]}"; do
    if [ -f "lib/services/$service" ]; then
        echo "Updating $service..."
        
        # Reemplazar URLs localhost por Environment
        sed -i.bak "s|http://localhost:8081|Environment.authUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8082|Environment.signupUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8083|Environment.languageUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8084|Environment.signinUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8085|Environment.dashboardUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8086|Environment.resetPasswordUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8087|Environment.dashboardDataUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8088|Environment.budgetUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8089|Environment.savingsUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8090|Environment.cashBankUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8091|Environment.billsUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8092|Environment.profileUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8093|Environment.incomeUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8094|Environment.expensesUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8095|Environment.categoriesUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8096|Environment.moneyFlowUrl|g" "lib/services/$service"
        sed -i.bak "s|http://localhost:8097|Environment.budgetOverviewUrl|g" "lib/services/$service"
        
        # Agregar import si no existe
        if ! grep -q "import.*environment.dart" "lib/services/$service"; then
            sed -i.bak "1i\\
import '../config/environment.dart';" "lib/services/$service"
        fi
        
        rm "lib/services/$service.bak"
    fi
done

echo "All services updated!"
EOF

chmod +x update_service_urls.sh
./update_service_urls.sh
```

## Configuración de TestFlight

### 1. Configurar Build para Producción

```bash
# Crear script de build para producción
cat > build_for_testflight.sh << 'EOF'
#!/bin/bash

echo "Building Hero Budget for TestFlight..."

# Limpiar build anterior
flutter clean
flutter pub get

# Build para iOS con configuración de producción
flutter build ios \
  --release \
  --dart-define=BASE_URL=https://herobudget.jaimedigitalstudio.com \
  --dart-define=PRODUCTION=true \
  --build-name=1.0.0 \
  --build-number=1

echo "Build completed! Ready for Xcode archive."
EOF

chmod +x build_for_testflight.sh
```

### 2. Configurar Info.plist

Actualizar `ios/Runner/Info.plist`:

```xml
<!-- Agregar configuración de red -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>herobudget.jaimedigitalstudio.com</key>
        <dict>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>

<!-- Configuración de Google OAuth -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>google</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.204913639838-lt4jcl1cc0b9qjq4lh8ef6u19trudech</string>
        </array>
    </dict>
</array>
```

### 3. Pasos en Xcode

1. **Abrir proyecto en Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configurar Team y Bundle ID:**
   - Seleccionar tu Apple Developer Team
   - Configurar Bundle Identifier único
   - Habilitar capabilities necesarias

3. **Archive y Upload:**
   - Product → Archive
   - Distribute App → App Store Connect
   - Upload to App Store Connect

4. **Configurar en App Store Connect:**
   - Crear nueva app
   - Configurar TestFlight
   - Agregar testers internos/externos

## Scripts de Automatización

### 1. Script de Despliegue Completo

```bash
# deploy_complete.sh
cat > deploy_complete.sh << 'EOF'
#!/bin/bash

set -e

VPS_IP="178.16.130.178"
VPS_USER="root"
DOMAIN="herobudget.jaimedigitalstudio.com"

echo "🚀 Starting complete deployment to VPS..."

# 1. Build microservices
echo "📦 Building microservices..."
cd backend
for service in */; do
    if [ -d "$service" ] && [ -f "$service/main.go" ]; then
        echo "Building $service..."
        cd "$service"
        GOOS=linux GOARCH=amd64 go build -o "${service%/}" .
        cd ..
    fi
done
cd ..

# 2. Deploy to VPS
echo "🌐 Deploying to VPS..."
rsync -avz --exclude='*.db' --exclude='*.log' backend/ $VPS_USER@$VPS_IP:/opt/herobudget/backend/

# 3. Restart services on VPS
echo "🔄 Restarting services..."
ssh $VPS_USER@$VPS_IP << 'ENDSSH'
sudo systemctl daemon-reload
for service in /etc/systemd/system/herobudget-*.service; do
    service_name=$(basename "$service" .service)
    sudo systemctl restart "$service_name"
    sudo systemctl status "$service_name" --no-pager -l
done
ENDSSH

# 4. Test deployment
echo "🧪 Testing deployment..."
curl -f https://$DOMAIN/health || echo "❌ Health check failed"

echo "✅ Deployment completed!"
EOF

chmod +x deploy_complete.sh
```

### 2. Script de Monitoreo

```bash
# En el VPS
cat > /opt/herobudget/scripts/monitor.sh << 'EOF'
#!/bin/bash

services=(
    "herobudget-google_auth"
    "herobudget-signup"
    "herobudget-language_cookie"
    "herobudget-signin"
    "herobudget-reset_password"
    "herobudget-fetch_dashboard"
    "herobudget-dashboard_data"
    "herobudget-budget_management"
    "herobudget-savings_management"
    "herobudget-cash_bank_management"
    "herobudget-bills_management"
    "herobudget-profile_management"
    "herobudget-income_management"
    "herobudget-expense_management"
    "herobudget-categories_management"
    "herobudget-money_flow_sync"
    "herobudget-budget_overview_fetch"
)

echo "🔍 Hero Budget Services Status"
echo "================================"

for service in "${services[@]}"; do
    status=$(systemctl is-active $service)
    if [ "$status" = "active" ]; then
        echo "✅ $service: $status"
    else
        echo "❌ $service: $status"
        # Intentar reiniciar servicio fallido
        sudo systemctl restart $service
    fi
done

echo ""
echo "📊 System Resources:"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"

echo ""
echo "🌐 Network Test:"
curl -s -o /dev/null -w "HTTPS Response: %{http_code} (Time: %{time_total}s)\n" https://herobudget.jaimedigitalstudio.com/health
EOF

chmod +x /opt/herobudget/scripts/monitor.sh

# Agregar a crontab para monitoreo automático
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/herobudget/scripts/monitor.sh >> /opt/herobudget/logs/monitor.log 2>&1") | crontab -
```

## Monitoreo y Mantenimiento

### 1. Logs Centralizados

```bash
# En el VPS
mkdir -p /opt/herobudget/logs

# Configurar logrotate
cat > /etc/logrotate.d/herobudget << 'EOF'
/opt/herobudget/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 herobudget herobudget
    postrotate
        systemctl reload nginx
    endscript
}
EOF
```

### 2. Backup Automático

```bash
# Script de backup
cat > /opt/herobudget/scripts/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/herobudget/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup de base de datos
sudo -u postgres pg_dump herobudget > $BACKUP_DIR/db_backup_$DATE.sql

# Backup de configuración
tar -czf $BACKUP_DIR/config_backup_$DATE.tar.gz /opt/herobudget/.env /etc/nginx/sites-available/herobudget

# Limpiar backups antiguos (mantener 7 días)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/herobudget/scripts/backup.sh

# Programar backup diario
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/herobudget/scripts/backup.sh") | crontab -
```

### 3. Alertas por Email

```bash
# Instalar mailutils
sudo apt install mailutils -y

# Script de alertas
cat > /opt/herobudget/scripts/alerts.sh << 'EOF'
#!/bin/bash

ADMIN_EMAIL="tu-email@ejemplo.com"
DOMAIN="herobudget.jaimedigitalstudio.com"

# Verificar servicios críticos
failed_services=()
for service in herobudget-*; do
    if ! systemctl is-active --quiet $service; then
        failed_services+=($service)
    fi
done

# Enviar alerta si hay servicios fallidos
if [ ${#failed_services[@]} -gt 0 ]; then
    {
        echo "⚠️ ALERTA: Servicios fallidos en $DOMAIN"
        echo ""
        echo "Servicios afectados:"
        for service in "${failed_services[@]}"; do
            echo "- $service"
        done
        echo ""
        echo "Fecha: $(date)"
        echo "Servidor: $(hostname)"
    } | mail -s "🚨 Hero Budget - Servicios Fallidos" $ADMIN_EMAIL
fi

# Verificar espacio en disco
disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $disk_usage -gt 80 ]; then
    echo "⚠️ ALERTA: Espacio en disco bajo ($disk_usage%)" | mail -s "🚨 Hero Budget - Espacio en Disco" $ADMIN_EMAIL
fi
EOF

chmod +x /opt/herobudget/scripts/alerts.sh

# Ejecutar cada 15 minutos
(crontab -l 2>/dev/null; echo "*/15 * * * * /opt/herobudget/scripts/alerts.sh") | crontab -
```

## Configuración Específica para tu VPS

### Resumen de tu configuración:
- **VPS IP**: 178.16.130.178
- **Usuario VPS**: root
- **Dominio**: herobudget.jaimedigitalstudio.com
- **Dominio principal**: jaimedigitalstudio.com (ya configurado)

### Pasos específicos para tu setup:

**⚠️ Nota sobre usuario root:**
Como usas el usuario `root`, algunos comandos se simplifican (no necesitas `sudo`), pero ten en cuenta:
- Los archivos se guardarán en `/root/` en lugar de `/home/usuario/`
- Algunos comandos de systemd y nginx no necesitarán `sudo`
- Es recomendable crear un usuario específico para los servicios (`herobudget`) por seguridad

1. **DNS**: Agregar registro A en tu proveedor de dominio:
   ```
   Tipo: A
   Nombre: herobudget
   Valor: 178.16.130.178
   TTL: 3600
   ```

2. **Nginx**: Como ya tienes nginx configurado, puedes:
   - **Opción recomendada**: Agregar el bloque server del subdominio a tu configuración existente
   - **Opción alternativa**: Crear archivo separado `/etc/nginx/sites-available/herobudget`

3. **SSL**: Expandir tu certificado existente:
   ```bash
   sudo certbot --nginx -d jaimedigitalstudio.com -d www.jaimedigitalstudio.com -d herobudget.jaimedigitalstudio.com
   ```

4. **Variables de entorno**: Usar `herobudget.jaimedigitalstudio.com` en todos los archivos de configuración

5. **Google OAuth**: Actualizar redirect URL a `https://herobudget.jaimedigitalstudio.com/auth/google/callback`

### Comandos simplificados para usuario root:

Como usas `root`, estos comandos se simplifican:

```bash
# Crear directorios (sin sudo)
mkdir -p /opt/herobudget/{backend,logs,scripts}

# Editar archivos de configuración (sin sudo)
nano /etc/nginx/sites-available/herobudget
nano /etc/systemd/system/herobudget-*.service

# Gestión de servicios (sin sudo)
systemctl enable herobudget-google_auth
systemctl start herobudget-google_auth
systemctl status herobudget-google_auth

# Certificados SSL (sin sudo)
certbot --nginx -d herobudget.jaimedigitalstudio.com

# Logs del sistema (sin sudo)
journalctl -u herobudget-google_auth -f
```

## Checklist Final

### ✅ Antes del Despliegue

- [ ] VPS configurado con todas las dependencias
- [ ] PostgreSQL instalado y configurado
- [ ] Dominio apuntando al VPS
- [ ] Certificado SSL configurado
- [ ] Base de datos migrada de SQLite
- [ ] Microservicios compilados para Linux
- [ ] Variables de entorno configuradas
- [ ] Nginx configurado con proxy reverso
- [ ] Servicios systemd creados

### ✅ Configuración de la App

- [ ] Environment.dart creado
- [ ] URLs de servicios actualizadas
- [ ] Info.plist configurado para producción
- [ ] Google OAuth URLs actualizadas
- [ ] Build de producción funcionando

### ✅ TestFlight

- [ ] Apple Developer Account activo
- [ ] App creada en App Store Connect
- [ ] Bundle ID configurado
- [ ] Archive subido exitosamente
- [ ] Testers agregados a TestFlight

### ✅ Post-Despliegue

- [ ] Todos los servicios funcionando
- [ ] Health checks pasando
- [ ] Logs configurados
- [ ] Backups programados
- [ ] Monitoreo activo
- [ ] Alertas configuradas

## Solución de Problemas Comunes

### 1. Servicios No Inician

```bash
# Verificar logs (sin sudo como root)
journalctl -u herobudget-google_auth -f

# Verificar permisos (sin sudo como root)
chown -R herobudget:herobudget /opt/herobudget

# Verificar conectividad de base de datos
sudo -u postgres psql -d herobudget -c "SELECT 1;"
```

### 2. Problemas de SSL

```bash
# Renovar certificado (sin sudo como root)
certbot renew --force-renewal

# Verificar configuración (sin sudo como root)
nginx -t
systemctl reload nginx
```

### 3. Problemas de Conectividad

```bash
# Verificar puertos abiertos (sin sudo como root)
netstat -tlnp | grep :80

# Verificar firewall (sin sudo como root)
ufw status
ufw allow 80
ufw allow 443
```

---

**¡Felicidades!** 🎉 Tu app Hero Budget ahora está lista para TestFlight con una arquitectura robusta y escalable en tu VPS.

Para soporte adicional, revisa los logs en `/opt/herobudget/logs/` y utiliza los scripts de monitoreo incluidos. 