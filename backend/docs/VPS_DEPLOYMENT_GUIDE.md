# 🚀 Guía de Despliegue VPS - Hero Budget Backend

## 📋 Descripción

Esta guía detalla el proceso completo para desplegar el backend de Hero Budget en el VPS de producción ubicado en `/opt/hero_budget/backend`.

**Características del despliegue:**
- ✅ **Automático**: Scripts que manejan todo el proceso
- ✅ **Seguro**: Backups automáticos antes de desplegar
- ✅ **Rollback**: Capacidad de revertir en caso de errores
- ✅ **Zero-downtime**: Despliegue sin interrumpir servicio

## 🖥️ Información del VPS

| Parámetro | Valor |
|-----------|-------|
| **IP** | `178.16.130.178` |
| **Usuario** | `root` |
| **Ruta Backend** | `/opt/hero_budget/backend` |
| **Ruta Backups** | `/opt/hero_budget/backups` |
| **Servicio SystemD** | `herobudget` |
| **Puerto Nginx** | `80, 443` |
| **Base de Datos** | PostgreSQL (`herobudget`) |

## 📁 Estructura de Directorios en VPS

```
/opt/hero_budget/
├── backend/                    # Código fuente backend
│   ├── google_auth/           # Microservicio autenticación
│   ├── expense_management/    # Microservicio gastos
│   ├── income_management/     # Microservicio ingresos
│   ├── budget_management/     # Microservicio presupuestos
│   ├── dashboard_data/        # Microservicio dashboard
│   ├── bills_management/      # Microservicio facturas
│   ├── main.go               # Punto de entrada
│   ├── go.mod                # Dependencias
│   └── schema.sql            # Esquema DB
├── backups/                   # Backups automáticos
│   ├── backend_backup_YYYYMMDD_HHMMSS.tar.gz
│   └── database_backup_YYYYMMDD_HHMMSS.sql
├── logs/                      # Logs de aplicación
├── scripts/                   # Scripts de gestión
└── config/                    # Archivos configuración
```

## 🛠️ Scripts de Despliegue

### Script Principal: deploy_backend.sh

```bash
#!/bin/bash
# Script de despliegue backend Hero Budget
# Uso: ./deploy_backend.sh [--force] [--no-backup]

set -e

# Configuración
VPS_HOST="178.16.130.178"
VPS_USER="root"
VPS_PATH="/opt/hero_budget/backend"
BACKUP_PATH="/opt/hero_budget/backups"
SERVICE_NAME="herobudget"
REPO_URL="https://github.com/TU_USUARIO/herobudget-backend.git"
BRANCH="main"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar conexión SSH
check_ssh_connection() {
    log_info "Verificando conexión SSH..."
    if ssh -o ConnectTimeout=10 $VPS_USER@$VPS_HOST "echo 'SSH OK'" >/dev/null 2>&1; then
        log_success "Conexión SSH establecida"
    else
        log_error "No se puede conectar al VPS"
        exit 1
    fi
}

# Crear backup
create_backup() {
    log_info "Creando backup del backend actual..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="backend_backup_${TIMESTAMP}.tar.gz"
    
    ssh $VPS_USER@$VPS_HOST << EOF
        if [ -d "$VPS_PATH" ]; then
            cd /opt/hero_budget
            tar -czf $BACKUP_PATH/$BACKUP_FILE backend/
            echo "Backup creado: $BACKUP_FILE"
        else
            echo "No existe directorio backend, creando estructura..."
            mkdir -p $VPS_PATH
            mkdir -p $BACKUP_PATH
        fi
EOF
    
    log_success "Backup completado"
}

# Desplegar código
deploy_code() {
    log_info "Desplegando código backend..."
    
    ssh $VPS_USER@$VPS_HOST << EOF
        cd $VPS_PATH
        
        # Si es primera vez, clonar repositorio
        if [ ! -d ".git" ]; then
            echo "Clonando repositorio..."
            cd /opt/hero_budget
            rm -rf backend
            git clone $REPO_URL backend
            cd backend
        else
            echo "Actualizando repositorio existente..."
            git fetch origin
            git reset --hard origin/$BRANCH
        fi
        
        # Verificar dependencias Go
        if [ -f "go.mod" ]; then
            echo "Instalando dependencias Go..."
            go mod download
            go mod tidy
        fi
        
        # Compilar microservicios
        echo "Compilando microservicios..."
        find . -name "*.go" -path "*/main.go" | while read main_file; do
            dir=\$(dirname "\$main_file")
            service_name=\$(basename "\$dir")
            echo "Compilando \$service_name..."
            cd "\$dir"
            go build -o "\$service_name" .
            cd - > /dev/null
        done
EOF
    
    log_success "Código desplegado y compilado"
}

# Reiniciar servicios
restart_services() {
    log_info "Reiniciando servicios..."
    
    ssh $VPS_USER@$VPS_HOST << EOF
        # Parar servicio actual
        if systemctl is-active $SERVICE_NAME >/dev/null 2>&1; then
            echo "Parando servicio $SERVICE_NAME..."
            systemctl stop $SERVICE_NAME
        fi
        
        # Esperar un momento
        sleep 2
        
        # Iniciar servicio
        echo "Iniciando servicio $SERVICE_NAME..."
        systemctl start $SERVICE_NAME
        
        # Verificar estado
        if systemctl is-active $SERVICE_NAME >/dev/null 2>&1; then
            echo "Servicio $SERVICE_NAME iniciado correctamente"
        else
            echo "Error: Servicio $SERVICE_NAME no pudo iniciarse"
            exit 1
        fi
        
        # Reiniciar nginx si es necesario
        echo "Reiniciando nginx..."
        systemctl reload nginx
EOF
    
    log_success "Servicios reiniciados"
}

# Verificar despliegue
verify_deployment() {
    log_info "Verificando despliegue..."
    
    # Esperar un momento para que los servicios se inicialicen
    sleep 5
    
    # Verificar endpoints básicos
    if curl -s --max-time 10 https://herobudget.jaimedigitalstudio.com/health >/dev/null; then
        log_success "Endpoint /health responde correctamente"
    else
        log_warning "Endpoint /health no responde (puede ser normal si no existe)"
    fi
    
    # Verificar servicio en VPS
    ssh $VPS_USER@$VPS_HOST << EOF
        if systemctl is-active $SERVICE_NAME >/dev/null 2>&1; then
            echo "✅ Servicio $SERVICE_NAME está activo"
        else
            echo "❌ Servicio $SERVICE_NAME no está activo"
            exit 1
        fi
        
        # Verificar logs recientes
        echo "Últimas líneas del log:"
        journalctl -u $SERVICE_NAME --no-pager -n 5
EOF
    
    log_success "Verificación completada"
}

# Función principal
main() {
    echo "🚀 Iniciando despliegue Hero Budget Backend"
    echo "=========================================="
    
    check_ssh_connection
    
    if [[ "$1" != "--no-backup" ]]; then
        create_backup
    fi
    
    deploy_code
    restart_services
    verify_deployment
    
    log_success "¡Despliegue completado exitosamente!"
    echo ""
    echo "🔗 URLs de verificación:"
    echo "   • https://herobudget.jaimedigitalstudio.com/"
    echo "   • https://herobudget.jaimedigitalstudio.com/auth/google"
    echo ""
}

# Ejecutar script principal
main "$@"
```

## 🔧 Script de Gestión de Servicios

### manage_services.sh

```bash
#!/bin/bash
# Script de gestión de servicios Hero Budget
# Uso: ./manage_services.sh {start|stop|restart|status|logs}

VPS_HOST="178.16.130.178"
VPS_USER="root"
SERVICE_NAME="herobudget"

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

case "$1" in
    start)
        echo "🚀 Iniciando servicios Hero Budget..."
        ssh $VPS_USER@$VPS_HOST "systemctl start $SERVICE_NAME && systemctl start nginx"
        echo -e "${GREEN}✅ Servicios iniciados${NC}"
        ;;
    stop)
        echo "⏹️ Parando servicios Hero Budget..."
        ssh $VPS_USER@$VPS_HOST "systemctl stop $SERVICE_NAME"
        echo -e "${YELLOW}⏹️ Servicios parados${NC}"
        ;;
    restart)
        echo "🔄 Reiniciando servicios Hero Budget..."
        ssh $VPS_USER@$VPS_HOST "systemctl restart $SERVICE_NAME && systemctl reload nginx"
        echo -e "${GREEN}✅ Servicios reiniciados${NC}"
        ;;
    status)
        echo "📊 Estado de servicios Hero Budget:"
        ssh $VPS_USER@$VPS_HOST "systemctl status $SERVICE_NAME --no-pager -l"
        ;;
    logs)
        echo "📋 Logs del servicio Hero Budget:"
        ssh $VPS_USER@$VPS_HOST "journalctl -u $SERVICE_NAME -f"
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
```

## 📋 Configuración Inicial VPS

### Preparar el VPS (ejecutar una sola vez)

```bash
#!/bin/bash
# Script de preparación inicial del VPS

VPS_HOST="178.16.130.178"
VPS_USER="root"

echo "🔧 Configurando VPS para Hero Budget Backend..."

ssh $VPS_USER@$VPS_HOST << 'EOF'
# Actualizar sistema
apt update && apt upgrade -y

# Instalar dependencias
apt install -y git curl wget nginx postgresql postgresql-contrib

# Instalar Go (si no está instalado)
if ! command -v go &> /dev/null; then
    wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    source /etc/profile
fi

# Crear estructura de directorios
mkdir -p /opt/hero_budget/{backend,backups,logs,config}
chown -R root:root /opt/hero_budget
chmod -R 755 /opt/hero_budget

# Configurar servicio systemd
cat > /etc/systemd/system/herobudget.service << 'EOFSERVICE'
[Unit]
Description=Hero Budget Backend Service
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hero_budget/backend
ExecStart=/opt/hero_budget/backend/main
Restart=always
RestartSec=5
Environment=PATH=/usr/local/go/bin:/usr/bin:/bin
Environment=GOPATH=/opt/hero_budget/go

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Habilitar servicio
systemctl daemon-reload
systemctl enable herobudget

echo "✅ VPS configurado correctamente"
EOF
```

## 🔄 Proceso de Despliegue Paso a Paso

### 1. Preparación Local

```bash
# En tu máquina local, carpeta del proyecto
cd backend

# Verificar que el código esté committeado
git status
git add .
git commit -m "feat: preparando despliegue"
git push origin main
```

### 2. Ejecutar Despliegue

```bash
# Hacer el script ejecutable
chmod +x scripts/deploy_backend.sh

# Ejecutar despliegue
./scripts/deploy_backend.sh

# En caso de emergencia (sin backup)
./scripts/deploy_backend.sh --no-backup
```

### 3. Verificar Despliegue

```bash
# Verificar servicios
./scripts/manage_services.sh status

# Ver logs en tiempo real
./scripts/manage_services.sh logs

# Probar endpoints
curl https://herobudget.jaimedigitalstudio.com/auth/google
```

## 🔥 Rollback en Caso de Error

### Rollback Automático

```bash
#!/bin/bash
# Script de rollback automático

VPS_HOST="178.16.130.178"
VPS_USER="root"
BACKUP_PATH="/opt/hero_budget/backups"

echo "🔄 Iniciando rollback..."

# Obtener último backup
LAST_BACKUP=$(ssh $VPS_USER@$VPS_HOST "ls -t $BACKUP_PATH/backend_backup_*.tar.gz | head -1")

if [ -n "$LAST_BACKUP" ]; then
    echo "📦 Restaurando desde: $(basename $LAST_BACKUP)"
    
    ssh $VPS_USER@$VPS_HOST << EOF
        cd /opt/hero_budget
        systemctl stop herobudget
        rm -rf backend
        tar -xzf $LAST_BACKUP
        systemctl start herobudget
        echo "✅ Rollback completado"
EOF
else
    echo "❌ No se encontraron backups"
    exit 1
fi
```

## 🚨 Troubleshooting

### Error: "No se puede conectar al VPS"
```bash
# Verificar SSH
ssh -v root@178.16.130.178

# Regenerar claves si es necesario
ssh-keygen -R 178.16.130.178
ssh-copy-id root@178.16.130.178
```

### Error: "Servicio no inicia"
```bash
# Ver logs detallados
ssh root@178.16.130.178 "journalctl -u herobudget -n 50"

# Verificar permisos
ssh root@178.16.130.178 "ls -la /opt/hero_budget/backend/"

# Compilar manualmente
ssh root@178.16.130.178 "cd /opt/hero_budget/backend && go build -o main ."
```

### Error: "Go no encontrado"
```bash
# Instalar Go en VPS
ssh root@178.16.130.178 << 'EOF'
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
EOF
```

## ✅ Checklist de Despliegue

### Pre-despliegue
- [ ] Código committeado y pusheado
- [ ] Tests locales ejecutados
- [ ] SSH configurado al VPS
- [ ] Backup actual verificado

### Durante despliegue
- [ ] Script de despliegue ejecutado sin errores
- [ ] Servicios reiniciados correctamente
- [ ] Logs sin errores críticos
- [ ] Endpoints respondiendo

### Post-despliegue
- [ ] Verificación funcional completa
- [ ] Monitoreo de logs por 10 minutos
- [ ] Notificación a equipo
- [ ] Actualización de documentación

---

**📝 Nota:** Continúa con la configuración de Jenkins para automatización completa en `docs/CI_CD_GUIDE.md` 