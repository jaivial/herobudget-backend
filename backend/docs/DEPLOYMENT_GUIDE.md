# Guía de Despliegue del Backend - Hero Budget

Esta guía te ayudará a desplegar los microservicios de Go de Hero Budget en tu VPS con el dominio `herobudget.jaimedigitalstudio.com`.

## Variables de Configuración

```bash
VPS_IP="178.16.130.178"
VPS_USER="root"
DOMAIN="herobudget.jaimedigitalstudio.com"
```

## Paso 1: Preparación del VPS

### 1.1 Conectar al VPS
```bash
ssh root@178.16.130.178
```

### 1.2 Actualizar el sistema
```bash
apt update && apt upgrade -y
```

**NOTA**: Si tienes problemas con repositorios, consulta primero `docs/VPS_SETUP_FIX.md`

### 1.3 Instalar dependencias necesarias
```bash
# Instalar Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Instalar Nginx
apt install nginx -y

# Instalar Certbot para SSL
apt install certbot python3-certbot-nginx -y

# Instalar SQLite
apt install sqlite3 -y

# Instalar herramientas adicionales
apt install git curl unzip lsof -y
```

### 1.4 Verificar instalación de Go
```bash
go version
```

## Paso 2: Configuración del Dominio y DNS

### 2.1 Configurar DNS
En tu proveedor de dominio, crea un registro A:
- **Tipo**: A
- **Nombre**: herobudget
- **Valor**: 178.16.130.178
- **TTL**: 300 (o el mínimo permitido)

### 2.2 Verificar propagación DNS
```bash
# Desde tu máquina local
nslookup herobudget.jaimedigitalstudio.com
```

## Paso 3: Subir el Código al VPS

### 3.1 Crear directorio del proyecto (EN EL VPS)
```bash
# Ejecutar en el VPS (ya conectado por SSH)
mkdir -p /opt/hero_budget
cd /opt/hero_budget
```

### 3.2 Subir archivos desde tu máquina local

**IMPORTANTE**: Los siguientes comandos se ejecutan desde tu **MÁQUINA LOCAL**, NO desde el VPS.

```bash
# SALIR del VPS primero
exit

# Desde tu máquina local, navegar al directorio del proyecto
cd /Users/usuario/Documents/PROYECTOS/herobudgetflutter/hero_budget

# Verificar que los archivos existen
ls -la backend/
ls -la *.sh

# Subir archivos al VPS
scp -r backend/ root@178.16.130.178:/opt/hero_budget/
scp start_services.sh stop_services.sh restart_services.sh root@178.16.130.178:/opt/hero_budget/
```

**Método alternativo si no tienes los scripts .sh en la raíz:**

```bash
# Si los scripts están en otro lugar, créalos primero o cópialos desde donde estén
# Por ejemplo, si están en el directorio backend:
scp -r backend/ root@178.16.130.178:/opt/hero_budget/

# Si no tienes los scripts, puedes crearlos después en el VPS
```

### 3.3 Configurar permisos (VOLVER AL VPS)
```bash
# Conectar nuevamente al VPS
ssh root@178.16.130.178

# Configurar permisos
cd /opt/hero_budget
chmod +x *.sh 2>/dev/null || echo "Scripts .sh no encontrados, se crearán más adelante"
chown -R root:root /opt/hero_budget

# Verificar que los archivos se subieron correctamente
ls -la /opt/hero_budget/
ls -la /opt/hero_budget/backend/
```

## Paso 4: Compilar los Microservicios

### 4.1 Compilar todos los servicios
```bash
cd /opt/hero_budget/backend

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

# Compilar cada servicio
for service in "${services[@]}"; do
  echo "Compilando $service..."
  if [ -d "$service" ]; then
    cd $service
    go mod tidy
    go build -o $service .
    cd ..
    echo "✅ $service compilado exitosamente"
  else
    echo "❌ Directorio $service no encontrado"
  fi
done
```

## Paso 5: Configurar Nginx como Reverse Proxy

### 5.1 Crear configuración de Nginx
```bash
cat > /etc/nginx/sites-available/herobudget << 'EOF'
server {
    listen 80;
    server_name herobudget.jaimedigitalstudio.com;

    # Redirigir HTTP a HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name herobudget.jaimedigitalstudio.com;

    # Configuración SSL (se configurará con Certbot)
    ssl_certificate /etc/letsencrypt/live/herobudget.jaimedigitalstudio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/herobudget.jaimedigitalstudio.com/privkey.pem;

    # Configuraciones de seguridad SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Headers de seguridad
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # Configuración CORS
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
    add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";

    # Manejar preflight requests
    if ($request_method = 'OPTIONS') {
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";
        add_header Access-Control-Max-Age 1728000;
        add_header Content-Type 'text/plain; charset=utf-8';
        add_header Content-Length 0;
        return 204;
    }

    # Microservicios - Proxy pass a cada puerto
    location /auth/google {
        proxy_pass http://localhost:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /update/locale {
        proxy_pass http://localhost:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /signup {
        proxy_pass http://localhost:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /language {
        proxy_pass http://localhost:8083;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /signin {
        proxy_pass http://localhost:8084;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /fetch-dashboard {
        proxy_pass http://localhost:8085;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /reset-password {
        proxy_pass http://localhost:8086;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /dashboard-data {
        proxy_pass http://localhost:8087;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /budget {
        proxy_pass http://localhost:8088;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /savings {
        proxy_pass http://localhost:8089;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /cash-bank {
        proxy_pass http://localhost:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /bills {
        proxy_pass http://localhost:8091;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /profile {
        proxy_pass http://localhost:8092;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /income {
        proxy_pass http://localhost:8093;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /expense {
        proxy_pass http://localhost:8094;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /categories {
        proxy_pass http://localhost:8095;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /money-flow-sync {
        proxy_pass http://localhost:8096;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /budget-overview {
        proxy_pass http://localhost:8097;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Logs
    access_log /var/log/nginx/herobudget_access.log;
    error_log /var/log/nginx/herobudget_error.log;
}
EOF
```

### 5.2 Habilitar el sitio
```bash
ln -s /etc/nginx/sites-available/herobudget /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

## Paso 6: Configurar SSL con Let's Encrypt

### 6.1 Obtener certificado SSL
```bash
certbot --nginx -d herobudget.jaimedigitalstudio.com
```

### 6.2 Configurar renovación automática
```bash
crontab -e
# Agregar esta línea:
0 12 * * * /usr/bin/certbot renew --quiet
```

## Paso 7: Crear Servicios Systemd

### 7.1 Crear script de inicio mejorado
```bash
cat > /opt/hero_budget/start_production_services.sh << 'EOF'
#!/bin/bash

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define service ports
declare -A SERVICE_PORTS=(
    ["google_auth"]=8081
    ["signup"]=8082
    ["language_cookie"]=8083
    ["signin"]=8084
    ["fetch_dashboard"]=8085
    ["reset_password"]=8086
    ["dashboard_data"]=8087
    ["budget_management"]=8088
    ["savings_management"]=8089
    ["cash_bank_management"]=8090
    ["bills_management"]=8091
    ["profile_management"]=8092
    ["income_management"]=8093
    ["expense_management"]=8094
    ["categories_management"]=8095
    ["money_flow_sync"]=8096
    ["budget_overview_fetch"]=8097
)

# List of services to start
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

# Output header
echo -e "${GREEN}Starting Hero Budget backend services in production mode...${NC}"
echo

# Navigate to backend directory
cd /opt/hero_budget/backend

# Start each service in the background
for service in "${services[@]}"; do
    echo -e "${YELLOW}Starting $service service...${NC}"
    
    if [ -d "$service" ]; then
        cd $service
        
        # Get port for the service
        PORT=${SERVICE_PORTS[$service]}
        
        # Check if port is already in use
        if lsof -i :$PORT > /dev/null 2>&1; then
            echo -e "${RED}Port $PORT is already in use. Service $service may already be running.${NC}"
            cd ..
            continue
        fi
        
        # Start the service
        if [ -f "$service" ]; then
            nohup ./$service > /var/log/hero_budget_${service}.log 2>&1 &
            echo $! > $service.pid
            echo -e "${GREEN}$service service started successfully on port $PORT. PID: $(cat $service.pid)${NC}"
        else
            echo -e "${RED}Executable '$service' not found in directory.${NC}"
        fi
        
        cd ..
    else
        echo -e "${RED}Service directory '$service' not found.${NC}"
    fi
    
    echo
done

echo -e "${GREEN}All requested services started.${NC}"
EOF

chmod +x /opt/hero_budget/start_production_services.sh
```

### 7.2 Crear servicio systemd principal
```bash
cat > /etc/systemd/system/hero-budget.service << 'EOF'
[Unit]
Description=Hero Budget Backend Services
After=network.target

[Service]
Type=forking
User=root
WorkingDirectory=/opt/hero_budget
ExecStart=/opt/hero_budget/start_production_services.sh
ExecStop=/opt/hero_budget/stop_services.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

### 7.3 Habilitar y iniciar el servicio
```bash
systemctl daemon-reload
systemctl enable hero-budget
systemctl start hero-budget
systemctl status hero-budget
```

## Paso 8: Configurar Firewall

### 8.1 Configurar UFW
```bash
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable
```

## Paso 9: Configurar Logs y Monitoreo

### 9.1 Crear directorio de logs
```bash
mkdir -p /var/log/hero_budget
chown root:root /var/log/hero_budget
```

### 9.2 Configurar logrotate
```bash
cat > /etc/logrotate.d/hero-budget << 'EOF'
/var/log/hero_budget_*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF
```

## Paso 10: Verificación del Despliegue

### 10.1 Verificar servicios
```bash
# Verificar que todos los servicios estén corriendo
systemctl status hero-budget

# Verificar puertos
netstat -tlnp | grep :80

# Verificar logs
tail -f /var/log/hero_budget_google_auth.log
```

### 10.2 Probar endpoints
```bash
# Desde tu máquina local
curl -k https://herobudget.jaimedigitalstudio.com/auth/google
```

## Paso 11: Backup y Mantenimiento

### 11.1 Script de backup de base de datos
```bash
cat > /opt/hero_budget/backup_db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/hero_budget/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup de la base de datos principal
cp /opt/hero_budget/backend/google_auth/users.db $BACKUP_DIR/users_db_backup_$DATE.db

# Mantener solo los últimos 7 backups
find $BACKUP_DIR -name "users_db_backup_*.db" -mtime +7 -delete

echo "Backup completed: users_db_backup_$DATE.db"
EOF

chmod +x /opt/hero_budget/backup_db.sh

# Agregar a crontab para backup diario
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/hero_budget/backup_db.sh") | crontab -
```

## Comandos Útiles de Mantenimiento

```bash
# Reiniciar todos los servicios
systemctl restart hero-budget

# Ver logs en tiempo real
tail -f /var/log/hero_budget_*.log

# Verificar estado de Nginx
systemctl status nginx

# Renovar certificado SSL manualmente
certbot renew

# Verificar configuración de Nginx
nginx -t

# Recargar configuración de Nginx
systemctl reload nginx
```

## Solución de Problemas Comunes

### Problema: Servicios no inician
```bash
# Verificar logs
journalctl -u hero-budget -f

# Verificar permisos
ls -la /opt/hero_budget/backend/*/
```

### Problema: SSL no funciona
```bash
# Verificar certificado
certbot certificates

# Renovar certificado
certbot renew --force-renewal
```

### Problema: Base de datos corrupta
```bash
# Restaurar desde backup
cp /opt/hero_budget/backups/users_db_backup_YYYYMMDD_HHMMSS.db /opt/hero_budget/backend/google_auth/users.db
systemctl restart hero-budget
```

¡Tu backend de Hero Budget ahora está desplegado y funcionando en `https://herobudget.jaimedigitalstudio.com`! 