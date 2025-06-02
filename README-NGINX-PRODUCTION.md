# 🚀 Hero Budget - Nginx Production Deployment Guide

## 📋 Overview

Esta guía te permitirá configurar Hero Budget en producción usando nginx como reverse proxy para todos los microservicios Go.

**Configuración del servidor:**
- **VPS IP**: 178.16.130.178
- **Usuario**: root
- **Dominio**: herobudget.jaimedigitalstudio.com
- **Protocolo**: HTTPS con SSL (Let's Encrypt)
- **Directorio del proyecto**: /opt/hero_budget

## 📁 Archivos Incluidos

| Archivo | Descripción |
|---------|-------------|
| `nginx-herobudget-config.conf` | Configuración principal de nginx |
| `install-nginx-config.sh` | Script de instalación automatizada |
| `verify-herobudget-setup.sh` | Script de verificación y troubleshooting |
| `start_services.sh` | Script para iniciar microservicios |
| `stop_services.sh` | Script para detener microservicios |

## 🛠 Instalación Rápida

### 1. Preparar los Archivos

```bash
# En tu máquina local, sube los archivos al VPS
scp nginx-herobudget-config.conf root@178.16.130.178:/root/
scp install-nginx-config.sh root@178.16.130.178:/root/
scp verify-herobudget-setup.sh root@178.16.130.178:/root/
scp start_services.sh root@178.16.130.178:/root/
scp stop_services.sh root@178.16.130.178:/root/
```

### 2. Conectar al VPS y Ejecutar Instalación

```bash
# Conectar al VPS
ssh root@178.16.130.178

# Hacer ejecutables los scripts
chmod +x install-nginx-config.sh
chmod +x verify-herobudget-setup.sh
chmod +x start_services.sh
chmod +x stop_services.sh

# Ejecutar instalación automatizada
./install-nginx-config.sh
```

### 3. Subir y Configurar Microservicios

```bash
# Crear estructura de microservicios
cd /opt/hero_budget
mkdir -p backend

# Subir tus microservicios Go a /opt/hero_budget/backend/
# (puedes usar scp, git clone, etc.)

# Iniciar los servicios
systemctl start herobudget

# Verificar que todo funciona
./verify-herobudget-setup.sh
```

## 🔧 Instalación Manual (Paso a Paso)

Si prefieres hacer la instalación manualmente:

### 1. Actualizar Sistema

```bash
apt update && apt upgrade -y
```

### 2. Instalar Paquetes Necesarios

```bash
apt install nginx certbot python3-certbot-nginx curl -y
```

### 3. Configurar Nginx

```bash
# Copiar configuración
cp nginx-herobudget-config.conf /etc/nginx/sites-available/herobudget

# Desactivar sitio por defecto
rm -f /etc/nginx/sites-enabled/default

# Activar sitio de Hero Budget
ln -s /etc/nginx/sites-available/herobudget /etc/nginx/sites-enabled/

# Verificar configuración
nginx -t
```

### 4. Configurar SSL con Let's Encrypt

```bash
# Obtener certificado SSL
certbot --nginx -d herobudget.jaimedigitalstudio.com --email admin@jaimedigitalstudio.com --agree-tos --non-interactive

# Configurar renovación automática
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
```

### 5. Crear Directorio del Proyecto

```bash
mkdir -p /opt/hero_budget/{backend,scripts,logs}
```

### 6. Configurar Servicio Systemd

```bash
# Crear archivo de servicio
cat > /etc/systemd/system/herobudget.service << 'EOF'
[Unit]
Description=Hero Budget Microservices
After=network.target

[Service]
Type=forking
User=root
WorkingDirectory=/opt/hero_budget
ExecStart=/opt/hero_budget/scripts/start_services.sh
ExecStop=/opt/hero_budget/scripts/stop_services.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Habilitar servicio
systemctl daemon-reload
systemctl enable herobudget
systemctl enable nginx
```

## 🔍 Microservicios y Endpoints

La configuración nginx mapea los siguientes endpoints:

### 🔐 Servicios de Autenticación
| Endpoint | Puerto | Servicio |
|----------|--------|----------|
| `/auth/google` | 8081 | google_auth |
| `/signup` | 8082 | signup |
| `/signin` | 8084 | signin |
| `/reset-password` | 8086 | reset_password |

### 💰 Servicios Financieros
| Endpoint | Puerto | Servicio |
|----------|--------|----------|
| `/incomes` | 8093 | income_management |
| `/expenses` | 8094 | expense_management |
| `/budget` | 8088 | budget_management |
| `/savings` | 8089 | savings_management |
| `/cash-bank` | 8090 | cash_bank_management |
| `/transfer` | 8090 | cash_bank_management |
| `/bills` | 8091 | bills_management |

### 📊 Servicios de Datos
| Endpoint | Puerto | Servicio |
|----------|--------|----------|
| `/budget-overview` | 8098 | budget_overview_fetch |
| `/transactions` | 8098 | budget_overview_fetch |
| `/money-flow-sync` | 8097 | money_flow_sync |
| `/categories` | 8096 | categories_management |

### 🛠 Servicios de Soporte
| Endpoint | Puerto | Servicio |
|----------|--------|----------|
| `/language` | 8083 | language_cookie |
| `/user` | 8085 | fetch_dashboard |
| `/dashboard-data` | 8087 | dashboard_data |
| `/profile` | 8092 | profile_management |
| `/transaction-delete` | 8095 | transaction_delete_service |

### 🩺 Servicios de Utilidad
| Endpoint | Descripción |
|----------|-------------|
| `/health` | Health check endpoint |

## ⚙️ Comandos de Gestión

### Servicios Hero Budget

```bash
# Iniciar todos los servicios
systemctl start herobudget

# Detener todos los servicios
systemctl stop herobudget

# Reiniciar todos los servicios
systemctl restart herobudget

# Ver estado de los servicios
systemctl status herobudget

# Ver logs en tiempo real
journalctl -u herobudget -f
```

### Servicios Nginx

```bash
# Reiniciar nginx
systemctl restart nginx

# Recargar configuración (sin downtime)
systemctl reload nginx

# Verificar configuración
nginx -t

# Ver logs de nginx
tail -f /var/log/nginx/herobudget_*.log
```

### Scripts Manuales

```bash
# Iniciar servicios manualmente
cd /opt/hero_budget && ./scripts/start_services.sh

# Detener servicios manualmente
cd /opt/hero_budget && ./scripts/stop_services.sh

# Verificar configuración completa
./verify-herobudget-setup.sh

# Verificaciones específicas
./verify-herobudget-setup.sh --services-only
./verify-herobudget-setup.sh --nginx-only
./verify-herobudget-setup.sh --ssl-only
./verify-herobudget-setup.sh --endpoints-only
```

## 🧪 Testing de Endpoints

### Health Check

```bash
curl https://herobudget.jaimedigitalstudio.com/health
```

**Respuesta esperada:**
```json
{"status":"OK","timestamp":"2025-01-15T10:30:45Z"}
```

### Endpoints Críticos

```bash
# Google Authentication
curl -X POST https://herobudget.jaimedigitalstudio.com/auth/google

# User Signup
curl -X POST https://herobudget.jaimedigitalstudio.com/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Income Management
curl -X POST https://herobudget.jaimedigitalstudio.com/incomes/add \
  -H "Content-Type: application/json" \
  -d '{"user_id":"1","amount":1000,"category":"Salary"}'

# Expense Management
curl -X POST https://herobudget.jaimedigitalstudio.com/expenses/add \
  -H "Content-Type: application/json" \
  -d '{"user_id":"1","amount":50,"category":"Food"}'

# Budget Overview
curl -X POST https://herobudget.jaimedigitalstudio.com/budget-overview \
  -H "Content-Type: application/json" \
  -d '{"user_id":"1"}'
```

## 📊 Monitoreo

### Logs Importantes

```bash
# Logs de nginx (acceso)
tail -f /var/log/nginx/herobudget_access.log

# Logs de nginx (errores)
tail -f /var/log/nginx/herobudget_error.log

# Logs del servicio Hero Budget
journalctl -u herobudget -f

# Logs del sistema
journalctl -f
```

### Monitoreo en Tiempo Real

```bash
# Estado de servicios cada 2 segundos
watch -n 2 'systemctl status herobudget'

# Uso de puertos
watch -n 5 'netstat -tulpn | grep :80'

# Uso de recursos
htop
```

## 🚨 Troubleshooting

### Problemas Comunes

#### 1. Servicios No Inician

**Síntoma:** Error 502 Bad Gateway
```bash
# Verificar servicios
./verify-herobudget-setup.sh --services-only

# Ver logs específicos
journalctl -u herobudget -f

# Iniciar manualmente para debug
cd /opt/hero_budget/backend/google_auth
go build -o google_auth.exe .
./google_auth.exe
```

#### 2. Errores de SSL

**Síntoma:** Error de certificado SSL
```bash
# Verificar certificados
./verify-herobudget-setup.sh --ssl-only

# Renovar certificados
certbot renew --nginx

# Debug SSL
openssl s_client -connect herobudget.jaimedigitalstudio.com:443 -servername herobudget.jaimedigitalstudio.com
```

#### 3. Errores de Nginx

**Síntoma:** Error 404 o 500
```bash
# Verificar configuración
nginx -t

# Ver logs de error
tail -f /var/log/nginx/herobudget_error.log

# Verificar permisos
ls -la /etc/nginx/sites-enabled/herobudget
```

#### 4. Problemas de DNS

**Síntoma:** Domain no resuelve
```bash
# Verificar DNS
nslookup herobudget.jaimedigitalstudio.com

# Verificar IP pública
curl ifconfig.me

# Test desde externo
curl -I https://herobudget.jaimedigitalstudio.com/health
```

### Comandos de Diagnóstico

```bash
# Verificación completa
./verify-herobudget-setup.sh

# Estado de todos los puertos
netstat -tulpn | grep :80

# Verificar procesos Go
ps aux | grep -E "(\.exe|go)"

# Verificar conexiones activas
ss -tulpn

# Test de conectividad interna
curl -I localhost:8081
curl -I localhost:8093
curl -I localhost:8094
```

## 🔒 Seguridad

### Configuración Incluida

La configuración nginx incluye:

- ✅ Redirección HTTP → HTTPS automática
- ✅ Headers de seguridad (HSTS, XSS Protection, etc.)
- ✅ Rate limiting para APIs
- ✅ CORS configurado para Flutter app
- ✅ SSL con TLS 1.2/1.3
- ✅ Logs detallados para auditoría

### Rate Limiting

- **Autenticación**: 20 requests/minuto
- **APIs generales**: 100 requests/minuto
- **Transferencias**: 10 requests/minuto

## 📈 Performance

### Optimizaciones Incluidas

- ✅ HTTP/2 habilitado
- ✅ Keep-alive connections
- ✅ Upstream connection pooling
- ✅ Gzip compression
- ✅ Timeouts optimizados (30s)

### Métricas Esperadas

- **Response time**: < 200ms
- **SSL handshake**: < 100ms
- **Throughput**: 1000+ req/s
- **Uptime**: 99.9%

## 🔄 Backup y Mantenimiento

### Configuración de Backup

```bash
# Backup de configuración nginx
cp /etc/nginx/sites-available/herobudget /opt/hero_budget/backup/

# Backup de certificados SSL
cp -r /etc/letsencrypt/live/herobudget.jaimedigitalstudio.com/ /opt/hero_budget/backup/ssl/

# Backup de scripts
tar -czf /opt/hero_budget/backup/scripts-$(date +%Y%m%d).tar.gz /opt/hero_budget/scripts/
```

### Tareas de Mantenimiento

```bash
# Actualizar sistema (mensual)
apt update && apt upgrade -y

# Limpiar logs (semanal)
find /var/log/nginx/ -name "*.log" -mtime +30 -delete

# Verificar certificados SSL (diario)
./verify-herobudget-setup.sh --ssl-only

# Health check completo (diario)
./verify-herobudget-setup.sh
```

## 🎉 ¡Listo para Producción!

Una vez completada la instalación, tu Hero Budget estará disponible en:

**🌐 https://herobudget.jaimedigitalstudio.com**

### URLs de Test Rápido

```bash
curl https://herobudget.jaimedigitalstudio.com/health
curl https://herobudget.jaimedigitalstudio.com/auth/google
curl https://herobudget.jaimedigitalstudio.com/incomes
curl https://herobudget.jaimedigitalstudio.com/expenses
```

### Próximos Pasos

1. **Configurar Flutter App** para usar dominio de producción
2. **Configurar Base de Datos** de producción
3. **Implementar Monitoring** (Grafana, Prometheus)
4. **Configurar Backups** automáticos
5. **Configurar CI/CD** para deployments

---

**📞 Soporte:** Si encuentras algún problema, ejecuta `./verify-herobudget-setup.sh` y revisa los logs en `/var/log/nginx/herobudget_*.log` 

## 🚀 Deployment Automatizado (Recomendado)

**Ejecuta un solo comando para deployment completo:**

```bash
./deploy-microservices-to-vps.sh
```

Este script automatiza todo el proceso:
- ✅ Instala Go 1.21.5 en el VPS
- ✅ Transfiere todos los microservicios con rsync
- ✅ Configura PostgreSQL para cada servicio
- ✅ Compila microservicios optimizados para producción
- ✅ Crea scripts de gestión automática
- ✅ Prueba conectividad de todos los endpoints

**📖 Para guía detallada ver:** [README-MICROSERVICES-DEPLOYMENT.md](README-MICROSERVICES-DEPLOYMENT.md)

## 📁 Estructura de Microservicios

El script espera encontrar estos 18 microservicios en tu directorio local:
```
/backend/
├── google_auth/        → Puerto 8081
├── signup/            → Puerto 8082  
├── language_cookie/   → Puerto 8083
├── signin/            → Puerto 8084
├── fetch_dashboard/   → Puerto 8085
├── reset_password/    → Puerto 8086
├── dashboard_data/    → Puerto 8087
├── budget_management/ → Puerto 8088
├── savings_management/→ Puerto 8089
├── cash_bank_management/→ Puerto 8090
├── bills_management/  → Puerto 8091
├── profile_management/→ Puerto 8092
├── income_management/ → Puerto 8093
├── expense_management/→ Puerto 8094
├── transaction_delete_service/→ Puerto 8095
├── categories_management/→ Puerto 8096
├── money_flow_sync/   → Puerto 8097
└── budget_overview_fetch/→ Puerto 8098
```

## 🔄 Método Manual (Alternativo)

Si prefieres hacer el deployment manualmente:

### 1. Preparar VPS con Go
```bash
ssh root@178.16.130.178

# Instalar Go
cd /tmp
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Crear estructura de directorios
mkdir -p /opt/hero_budget/{backend,logs,config,scripts}
```

### 2. Transferir Código
```bash
# Desde tu máquina local
rsync -avz --exclude='.git' --exclude='*.log' --exclude='*.db' \
      backend/ root@178.16.130.178:/opt/hero_budget/backend/
```

### 3. Compilar Servicios
```bash
ssh root@178.16.130.178
export PATH=$PATH:/usr/local/go/bin
cd /opt/hero_budget/backend

# Compilar cada servicio
for service in */; do
    if [[ -d "$service" ]]; then
        cd "$service"
        service_name=${service%/}
        echo "Compilando $service_name..."
        
        # Inicializar módulo Go si no existe
        [[ ! -f "go.mod" ]] && go mod init herobudget/$service_name
        
        # Agregar dependencia PostgreSQL
        go get github.com/lib/pq
        go mod tidy
        
        # Compilar
        go build -ldflags="-s -w" -o "${service_name}.exe" main.go
        chmod +x "${service_name}.exe"
        
        cd ..
    fi
done
```

## ✅ Verificación

Una vez completado el deployment (automático o manual):

```bash
# Verificar que todos los servicios estén disponibles
./verify-herobudget-setup.sh --services-only

# O verificación manual
ssh root@178.16.130.178
cd /opt/hero_budget/backend
find . -name "*.exe" -type f  # Ver ejecutables compilados
```

## 🔧 Gestión Post-Deployment

```bash
# Iniciar servicios
systemctl start herobudget

# Ver logs
tail -f /opt/hero_budget/logs/*.log

# Probar endpoints
curl https://herobudget.jaimedigitalstudio.com/health
curl https://herobudget.jaimedigitalstudio.com/auth/google
```

---

**🎯 Próximo paso:** Una vez que los microservicios estén desplegados, procede con la [migración de base de datos](README-DATABASE-MIGRATION.md) 