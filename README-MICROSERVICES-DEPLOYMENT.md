# 🚀 Deployment de Microservicios - Hero Budget

## 📋 Descripción

Esta guía detalla cómo subir y configurar los 18 microservicios Go de Hero Budget al VPS de producción.

**¿Qué hace este proceso?**
- ✅ **Instala Go** en el VPS de producción
- ✅ **Transfiere código** de manera eficiente con rsync
- ✅ **Configura base de datos** PostgreSQL para cada servicio
- ✅ **Compila microservicios** optimizados para producción
- ✅ **Crea scripts** de gestión automática
- ✅ **Prueba conectividad** de todos los endpoints

## 📁 Archivos Relacionados

| Archivo | Descripción |
|---------|-------------|
| `deploy-microservices-to-vps.sh` | Script principal de deployment |
| `README-MICROSERVICES-DEPLOYMENT.md` | Esta guía |

## 🏗 Arquitectura de Microservicios

### Origen (Local)
```
Directorio: /Users/usuario/Documents/PROYECTOS/herobudgetflutter/hero_budget/backend/
Estructura:
├── google_auth/
├── signup/
├── signin/
├── language_cookie/
├── fetch_dashboard/
├── reset_password/
├── dashboard_data/
├── budget_management/
├── savings_management/
├── cash_bank_management/
├── bills_management/
├── profile_management/
├── income_management/
├── expense_management/
├── transaction_delete_service/
├── categories_management/
├── money_flow_sync/
└── budget_overview_fetch/
```

### Destino (VPS)
```
Directorio: /opt/hero_budget/backend/
Configuración: /opt/hero_budget/config/
Logs: /opt/hero_budget/logs/
Scripts: /opt/hero_budget/scripts/
```

## 🚀 Proceso de Deployment (1 Comando)

```bash
# Ejecutar deployment completo
./deploy-microservices-to-vps.sh
```

### ¿Qué hace el script paso a paso?

#### 1. **Verificación Local** 🔍
- ✅ Verifica que el directorio backend existe
- ✅ Cuenta microservicios disponibles (18 esperados)
- ✅ Lista servicios faltantes (si los hay)
- ✅ Permite continuar con servicios parciales

#### 2. **Preparación del VPS** 📦
- ✅ Actualiza paquetes del sistema
- ✅ Instala Go 1.21.5 si no está presente
- ✅ Instala herramientas adicionales (git, curl, build-essential)
- ✅ Crea estructura de directorios

#### 3. **Configuración de Base de Datos** 🗄️
- ✅ Crea archivo de configuración PostgreSQL
- ✅ Genera helper de conexión en Go
- ✅ Configura pool de conexiones optimizado
- ✅ Sube configuración al VPS

#### 4. **Transferencia de Código** 📡
- ✅ Detiene servicios existentes
- ✅ Crea backup del backend actual
- ✅ Transfiere cada microservicio con rsync
- ✅ Excluye archivos innecesarios (.git, .log, .db)

#### 5. **Configuración de Microservicios** ⚙️
- ✅ Inicializa módulos Go (go.mod)
- ✅ Agrega driver PostgreSQL (github.com/lib/pq)
- ✅ Descarga dependencias (go mod tidy)
- ✅ Copia configuración de base de datos

#### 6. **Compilación Optimizada** 🔨
- ✅ Compila con optimizaciones (-ldflags="-s -w")
- ✅ Detecta archivo main automáticamente
- ✅ Genera ejecutables .exe
- ✅ Reporta estado de compilación

#### 7. **Scripts de Gestión** 📜
- ✅ Crea start_services.sh actualizado
- ✅ Crea stop_services.sh mejorado
- ✅ Gestión de PIDs y logs
- ✅ Carga automática de variables de entorno

#### 8. **Pruebas de Conectividad** 🧪
- ✅ Inicia todos los servicios
- ✅ Verifica conectividad en cada puerto
- ✅ Reporta servicios funcionando/fallando
- ✅ Proporciona estadísticas de éxito

## 🔧 Mapeo de Microservicios

| Servicio | Puerto | Archivo Principal | Endpoint |
|----------|--------|-------------------|----------|
| `google_auth` | 8081 | main.go | `/auth/google` |
| `signup` | 8082 | main.go | `/signup` |
| `language_cookie` | 8083 | main.go | `/language` |
| `signin` | 8084 | main.go | `/signin` |
| `fetch_dashboard` | 8085 | main.go | `/user` |
| `reset_password` | 8086 | main.go | `/reset-password` |
| `dashboard_data` | 8087 | main.go | `/dashboard-data` |
| `budget_management` | 8088 | main.go | `/budget` |
| `savings_management` | 8089 | main.go | `/savings` |
| `cash_bank_management` | 8090 | main.go | `/cash-bank` |
| `bills_management` | 8091 | main.go | `/bills` |
| `profile_management` | 8092 | main.go | `/profile` |
| `income_management` | 8093 | main.go | `/incomes` |
| `expense_management` | 8094 | main.go | `/expenses` |
| `transaction_delete_service` | 8095 | main.go | `/transaction-delete` |
| `categories_management` | 8096 | main.go | `/categories` |
| `money_flow_sync` | 8097 | main.go | `/money-flow-sync` |
| `budget_overview_fetch` | 8098 | main.go | `/budget-overview` |

## 🗄️ Configuración de Base de Datos

### Archivo: `/opt/hero_budget/config/database.env`
```bash
# Database Configuration for Hero Budget Production
DB_TYPE=postgresql
DB_HOST=localhost
DB_PORT=5432
DB_NAME=herobudget
DB_USER=herobudget_user
DB_PASSWORD=HeroBudget2024!Secure
DB_SSLMODE=disable

# Connection Pool Settings
DB_MAX_OPEN_CONNS=25
DB_MAX_IDLE_CONNS=5
DB_CONN_MAX_LIFETIME=300s

# Server Settings
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=production

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
```

### Helper de Conexión Go
El script crea automáticamente un helper `database.go` que:
- ✅ Lee configuración desde variables de entorno
- ✅ Establece pool de conexiones optimizado
- ✅ Maneja errores de conexión
- ✅ Proporciona función `ConnectDatabase()`

## 📊 Estructura del VPS Post-Deployment

```
/opt/hero_budget/
├── backend/                    # Microservicios compilados
│   ├── google_auth/
│   │   ├── main.go
│   │   ├── database.go
│   │   ├── .env
│   │   ├── go.mod
│   │   ├── go.sum
│   │   └── google_auth.exe     # Ejecutable compilado
│   ├── signup/
│   │   └── signup.exe
│   └── ... (16 servicios más)
├── config/                     # Configuración global
│   ├── database.env
│   └── database.go
├── logs/                       # Logs de servicios
│   ├── google_auth.log
│   ├── google_auth.pid
│   └── ... (logs por servicio)
├── scripts/                    # Scripts de gestión
│   ├── start_services.sh
│   └── stop_services.sh
└── backups/                    # Backups de base de datos
    └── ... (archivos .sql)
```

## 🔧 Gestión de Servicios

### Comandos Systemd
```bash
# Iniciar todos los servicios
systemctl start herobudget

# Detener todos los servicios
systemctl stop herobudget

# Reiniciar todos los servicios
systemctl restart herobudget

# Ver estado de servicios
systemctl status herobudget

# Ver logs en tiempo real
journalctl -u herobudget -f
```

### Scripts Manuales
```bash
# En el VPS
ssh root@178.16.130.178

# Iniciar servicios manualmente
cd /opt/hero_budget && ./scripts/start_services.sh

# Detener servicios manualmente
cd /opt/hero_budget && ./scripts/stop_services.sh

# Ver logs específicos
tail -f /opt/hero_budget/logs/google_auth.log
tail -f /opt/hero_budget/logs/income_management.log
```

## 🧪 Testing Post-Deployment

### Verificación Básica
```bash
# Health check general
curl https://herobudget.jaimedigitalstudio.com/health

# Verificar servicios específicos
curl -I https://herobudget.jaimedigitalstudio.com/auth/google
curl -I https://herobudget.jaimedigitalstudio.com/incomes
curl -I https://herobudget.jaimedigitalstudio.com/expenses
```

### Verificación Interna (en VPS)
```bash
# Conectar al VPS
ssh root@178.16.130.178

# Verificar que todos los puertos estén activos
netstat -tulpn | grep :80

# Probar conectividad interna
curl localhost:8081  # Google Auth
curl localhost:8093  # Income Management
curl localhost:8094  # Expense Management
```

### Script de Verificación Completa
```bash
# Usar script de verificación automática
./verify-herobudget-setup.sh

# O verificación específica de servicios
./verify-herobudget-setup.sh --services-only
```

## 🔄 Redeployment y Actualizaciones

### Para actualizar código existente:
```bash
# El script automáticamente:
# 1. Crea backup del backend actual
# 2. Transfiere nueva versión
# 3. Recompila todos los servicios
# 4. Reinicia servicios
./deploy-microservices-to-vps.sh
```

### Rollback en caso de problemas:
```bash
# En el VPS, restaurar backup anterior
ssh root@178.16.130.178
cd /opt/hero_budget
ls backend_backup_*  # Ver backups disponibles
rm -rf backend
mv backend_backup_YYYYMMDD_HHMMSS backend
systemctl restart herobudget
```

## 🚨 Troubleshooting

### Error: "Go not found"
**Síntoma:** Error al compilar microservicios
```bash
# Verificar instalación de Go en VPS
ssh root@178.16.130.178
/usr/local/go/bin/go version
echo $PATH
```

### Error: "Service failed to compile"
**Síntoma:** Algunos microservicios no compilan
```bash
# En el VPS, compilar manualmente para ver errores
ssh root@178.16.130.178
cd /opt/hero_budget/backend/[service_name]
/usr/local/go/bin/go build -v main.go
```

### Error: "Service not responding"
**Síntoma:** Microservicio no responde en puerto
```bash
# Verificar logs del servicio específico
ssh root@178.16.130.178
tail -f /opt/hero_budget/logs/[service_name].log

# Verificar conectividad de base de datos
sudo -u postgres psql -d herobudget -c "SELECT version();"
```

### Error: "Database connection failed"
**Síntoma:** Servicios no pueden conectar a PostgreSQL
```bash
# Verificar configuración de base de datos
ssh root@178.16.130.178
cat /opt/hero_budget/config/database.env

# Probar conexión manualmente
sudo -u postgres psql -d herobudget
```

## 📈 Optimizaciones Incluidas

### Compilación
- ✅ **Optimizaciones de tamaño**: `-ldflags="-s -w"`
- ✅ **Compilación estática**: `CGO_ENABLED=0`
- ✅ **Target específico**: `GOOS=linux`

### Transferencia
- ✅ **Rsync eficiente**: Solo transfiere cambios
- ✅ **Exclusiones inteligentes**: Ignora .git, logs, etc.
- ✅ **Backup automático**: Preserva versión anterior

### Base de Datos
- ✅ **Pool de conexiones**: Configurado para producción
- ✅ **Timeouts optimizados**: 300s de vida máxima
- ✅ **Conexiones limitadas**: Max 25 abiertas, 5 idle

### Logs
- ✅ **Logs separados**: Un archivo por servicio
- ✅ **Gestión de PIDs**: Control preciso de procesos
- ✅ **Rotación automática**: Previene crecimiento excesivo

## 🎯 Próximos Pasos

Una vez completado el deployment de microservicios:

### 1. Migrar Base de Datos
```bash
./setup-vps-postgresql.sh      # Si no se ha hecho
./migrate-database-to-vps.sh   # Migrar datos SQLite
```

### 2. Verificar Setup Completo
```bash
./verify-herobudget-setup.sh   # Verificación integral
```

### 3. Configurar Monitoreo
- **Logs centralizados**: Configurar agregación de logs
- **Métricas**: Implementar Prometheus/Grafana
- **Alertas**: Configurar notificaciones por fallas

### 4. Actualizar Flutter App
- **Base URL**: Cambiar a `https://herobudget.jaimedigitalstudio.com`
- **Endpoints**: Verificar que coincidan con nginx
- **Testing**: Probar autenticación y funcionalidades

---

## 🎉 ¡Deployment Completado!

Una vez ejecutado exitosamente:

✅ **18 microservicios Go** desplegados y compilados  
✅ **PostgreSQL** configurado para cada servicio  
✅ **Scripts de gestión** automatizados  
✅ **Logs y monitoreo** configurados  
✅ **Nginx reverse proxy** mapeando endpoints  
✅ **SSL/HTTPS** funcionando en producción  

### URLs de Producción Disponibles

**Base:** `https://herobudget.jaimedigitalstudio.com`

**Endpoints críticos:**
- `/health` - Health check
- `/auth/google` - Autenticación Google
- `/incomes` - Gestión de ingresos
- `/expenses` - Gestión de gastos
- `/budget-overview` - Resumen de presupuesto

---

**📞 Soporte:** Si encuentras problemas, revisa logs en `/opt/hero_budget/logs/` y usa el script de verificación automática 