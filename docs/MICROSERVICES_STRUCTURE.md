# Estructura de Microservicios - Hero Budget Backend

Este documento detalla la estructura completa de microservicios desplegados en el VPS y su configuración de nginx.

## Información del Servidor

- **VPS IP**: 178.16.130.178
- **Usuario**: root
- **Dominio**: herobudget.jaimedigitalstudio.com
- **Protocolo**: HTTPS con SSL (Let's Encrypt)
- **Directorio del proyecto**: /opt/hero_budget

## Microservicios Configurados

### Lista de Microservicios y Puertos

| Servicio | Puerto | Función | Ruta Nginx |
|----------|--------|---------|------------|
| google_auth | 8081 | Autenticación con Google OAuth | /auth/google |
| google_auth | 8081 | Actualización de idioma | /update/locale |
| signup | 8082 | Registro de usuarios | /signup |
| language_cookie | 8083 | Gestión de cookies de idioma | /language |
| signin | 8084 | Inicio de sesión | /signin |
| fetch_dashboard | 8085 | Obtener datos del dashboard | /fetch-dashboard |
| reset_password | 8086 | Restablecimiento de contraseña | /reset-password |
| dashboard_data | 8087 | Datos del dashboard | /dashboard-data |
| budget_management | 8088 | Gestión de presupuestos | /budget |
| savings_management | 8089 | Gestión de ahorros | /savings |
| cash_bank_management | 8090 | Gestión de efectivo y bancos | /cash-bank |
| bills_management | 8091 | Gestión de facturas | /bills |
| profile_management | 8092 | Gestión de perfil de usuario | /profile |
| income_management | 8093 | Gestión de ingresos | /income |
| expense_management | 8094 | Gestión de gastos | /expense |
| categories_management | 8095 | Gestión de categorías | /categories |
| money_flow_sync | 8096 | Sincronización de flujo de dinero | /money-flow-sync |
| budget_overview_fetch | 8097 | Vista general del presupuesto | /budget-overview |

## Estructura de Directorios

```
/opt/hero_budget/
├── backend/
│   ├── google_auth/
│   │   ├── google_auth (ejecutable)
│   │   ├── users.db (base de datos SQLite)
│   │   └── google_auth.pid
│   ├── signup/
│   │   ├── signup (ejecutable)
│   │   └── signup.pid
│   ├── language_cookie/
│   │   ├── language_cookie (ejecutable)
│   │   └── language_cookie.pid
│   ├── signin/
│   │   ├── signin (ejecutable)
│   │   └── signin.pid
│   ├── fetch_dashboard/
│   │   ├── fetch_dashboard (ejecutable)
│   │   └── fetch_dashboard.pid
│   ├── reset_password/
│   │   ├── reset_password (ejecutable)
│   │   └── reset_password.pid
│   ├── dashboard_data/
│   │   ├── dashboard_data (ejecutable)
│   │   └── dashboard_data.pid
│   ├── budget_management/
│   │   ├── budget_management (ejecutable)
│   │   └── budget_management.pid
│   ├── savings_management/
│   │   ├── savings_management (ejecutable)
│   │   └── savings_management.pid
│   ├── cash_bank_management/
│   │   ├── cash_bank_management (ejecutable)
│   │   └── cash_bank_management.pid
│   ├── bills_management/
│   │   ├── bills_management (ejecutable)
│   │   └── bills_management.pid
│   ├── profile_management/
│   │   ├── profile_management (ejecutable)
│   │   └── profile_management.pid
│   ├── income_management/
│   │   ├── income_management (ejecutable)
│   │   └── income_management.pid
│   ├── expense_management/
│   │   ├── expense_management (ejecutable)
│   │   └── expense_management.pid
│   ├── categories_management/
│   │   ├── categories_management (ejecutable)
│   │   └── categories_management.pid
│   ├── money_flow_sync/
│   │   ├── money_flow_sync (ejecutable)
│   │   └── money_flow_sync.pid
│   └── budget_overview_fetch/
│       ├── budget_overview_fetch (ejecutable)
│       └── budget_overview_fetch.pid
├── backups/
│   └── users_db_backup_*.db
├── start_production_services.sh
├── stop_services.sh
└── restart_services.sh
```

## Configuración de Nginx

### Archivo de configuración principal
**Ubicación**: `/etc/nginx/sites-available/herobudget`

### Configuración de servidor

```nginx
server {
    listen 80;
    server_name herobudget.jaimedigitalstudio.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name herobudget.jaimedigitalstudio.com;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/herobudget.jaimedigitalstudio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/herobudget.jaimedigitalstudio.com/privkey.pem;
}
```

### Configuración de Proxy para Microservicios

```nginx
# Autenticación Google y Locale
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

# Registro de usuarios
location /signup {
    proxy_pass http://localhost:8082;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Gestión de idioma
location /language {
    proxy_pass http://localhost:8083;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Inicio de sesión
location /signin {
    proxy_pass http://localhost:8084;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Dashboard
location /fetch-dashboard {
    proxy_pass http://localhost:8085;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Restablecimiento de contraseña
location /reset-password {
    proxy_pass http://localhost:8086;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Datos del dashboard
location /dashboard-data {
    proxy_pass http://localhost:8087;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Gestión de presupuestos
location /budget {
    proxy_pass http://localhost:8088;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Gestión de ahorros
location /savings {
    proxy_pass http://localhost:8089;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Gestión de efectivo y bancos
location /cash-bank {
    proxy_pass http://localhost:8090;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Gestión de facturas
location /bills {
    proxy_pass http://localhost:8091;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Gestión de perfil
location /profile {
    proxy_pass http://localhost:8092;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Gestión de ingresos
location /income {
    proxy_pass http://localhost:8093;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Gestión de gastos
location /expense {
    proxy_pass http://localhost:8094;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Gestión de categorías
location /categories {
    proxy_pass http://localhost:8095;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Sincronización de flujo de dinero
location /money-flow-sync {
    proxy_pass http://localhost:8096;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Vista general del presupuesto
location /budget-overview {
    proxy_pass http://localhost:8097;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## Configuración CORS

```nginx
# Configuración CORS global
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
```

## Servicio Systemd

### Configuración del servicio principal
**Archivo**: `/etc/systemd/system/hero-budget.service`

```ini
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
```

## Scripts de Gestión

### Script de inicio de servicios
**Archivo**: `/opt/hero_budget/start_production_services.sh`

Inicia todos los microservicios de manera secuencial, verificando que los puertos estén disponibles y guardando los PIDs correspondientes.

### Script de parada de servicios
**Archivo**: `/opt/hero_budget/stop_services.sh`

Detiene todos los servicios usando los PIDs guardados.

### Script de reinicio de servicios
**Archivo**: `/opt/hero_budget/restart_services.sh`

Ejecuta secuencialmente la parada y el inicio de todos los servicios.

## Logs y Monitoreo

### Ubicación de logs
- **Logs de servicios**: `/var/log/hero_budget_[servicio].log`
- **Logs de nginx**: `/var/log/nginx/herobudget_access.log` y `/var/log/nginx/herobudget_error.log`
- **Logs de systemd**: `journalctl -u hero-budget`

### Rotación de logs
Configurada con logrotate para mantener 52 días de histórico con compresión automática.

## Base de Datos

### SQLite Database
- **Ubicación**: `/opt/hero_budget/backend/google_auth/users.db`
- **Backup automático**: Diario a las 2:00 AM
- **Retención**: 7 días
- **Ubicación de backups**: `/opt/hero_budget/backups/`

## Comandos de Gestión

```bash
# Ver estado general
systemctl status hero-budget

# Reiniciar todos los servicios
systemctl restart hero-budget

# Ver logs en tiempo real
tail -f /var/log/hero_budget_*.log

# Verificar puertos activos
netstat -tlnp | grep :80

# Backup manual de base de datos
/opt/hero_budget/backup_db.sh
```

## URLs de Acceso

Todos los endpoints están disponibles bajo HTTPS:
- **Base URL**: `https://herobudget.jaimedigitalstudio.com`
- **Ejemplo**: `https://herobudget.jaimedigitalstudio.com/auth/google`

---

## ✅ VERIFICACIÓN REAL DEL VPS (Análisis realizado el 29/05/2025)

### Estado Actual de Servicios

**✅ Servicio Principal**: `hero-budget.service` está **ACTIVO** y funcionando correctamente
- **Estado**: `active (running)` desde las 12:04:33 UTC
- **Tiempo activo**: 2h 27min (al momento del análisis)
- **Memoria utilizada**: 28.3M (pico: 28.8M)
- **CPU utilizada**: 1.249s

### Mapeo Real de Microservicios

| Servicio | Puerto | PID | Estado | Memoria aprox. |
|----------|--------|-----|--------|---------------|
| google_auth | 8081 | 897195 | ✅ ACTIVO | ~18MB |
| signup | 8082 | 897202 | ✅ ACTIVO | ~9MB |
| language_cookie | 8083 | 897209 | ✅ ACTIVO | ~5MB |
| signin | 8084 | 897216 | ✅ ACTIVO | ~8MB |
| fetch_dashboard | 8085 | 897230 | ✅ ACTIVO | ~8MB |
| reset_password | 8086 | 897223 | ✅ ACTIVO | ~8MB |
| dashboard_data | 8087 | 897237 | ✅ ACTIVO | ~8MB |
| budget_management | 8088 | 897244 | ✅ ACTIVO | ~7MB |
| savings_management | 8089 | 897251 | ✅ ACTIVO | ~9MB |
| cash_bank_management | 8090 | 897258 | ✅ ACTIVO | ~7MB |
| bills_management | 8091 | 897265 | ✅ ACTIVO | ~10MB |
| profile_management | 8092 | 897272 | ✅ ACTIVO | ~9MB |
| income_management | 8093 | 897279 | ✅ ACTIVO | ~9MB |
| expense_management | 8094 | 897286 | ✅ ACTIVO | ~9MB |
| categories_management | 8095 | 897293 | ✅ ACTIVO | ~8MB |
| money_flow_sync | 8096 | 897179 | ✅ ACTIVO | ~7MB |
| budget_overview_fetch | 8097 | 897186 | ✅ ACTIVO | ~12MB |

### Estructura Real Verificada

**✅ Directorio Principal**: `/opt/hero_budget/` confirmado con:
- 24 directorios de microservicios en `/opt/hero_budget/backend/`
- Scripts de gestión presentes y ejecutables
- Directorio de backups configurado
- Logs activos en `/var/log/hero_budget_*.log`

**✅ Nginx**: Configuración confirmada en `/etc/nginx/sites-available/herobudget`
- Proxy reverso funcionando correctamente
- Headers CORS configurados
- SSL/HTTPS activo
- Redirectión HTTP a HTTPS operativa

**✅ Archivos de Configuración**:
- Systemd service: `/etc/systemd/system/hero-budget.service` ✅
- Nginx config: `/etc/nginx/sites-available/herobudget` ✅
- Scripts de gestión: múltiples scripts .sh presentes ✅

### Observaciones Importantes

1. **Todos los 17 microservicios están ACTIVOS** y respondiendo en sus puertos respectivos
2. **El servicio systemd funciona correctamente** con auto-restart configurado
3. **Los logs están siendo generados** y almacenados apropiadamente
4. **La configuración de nginx incluye CORS** apropiado para la aplicación Flutter
5. **El sistema de backups está configurado** con rotación automática

### Tamaños de Ejecutables (Muestran que están compilados)

- Ejecutables van desde ~6MB (language_cookie) hasta ~24MB (savings_management)
- Todos los ejecutables son binarios de Go compilados y funcionales
- Cada servicio mantiene su propio archivo .pid para gestión de procesos

**✅ CONCLUSIÓN**: La infraestructura de microservicios está **100% operativa** y lista para atender requests de la aplicación Flutter.

---

Este documento refleja la estructura actual desplegada en el VPS y puede servir como referencia para futuras modificaciones o expansiones del sistema. 