#!/bin/bash
# Script de deployment automático vía webhook
# Versión: 1.0
# Uso: ./webhook_deploy.sh [branch] [--force]

set -e

# Configuración
VPS_HOST="178.16.130.178"
VPS_USER="root"
BACKEND_PATH="/opt/hero_budget/backend"
BACKUP_PATH="/opt/hero_budget/backups"
LOG_PATH="/opt/hero_budget/logs"
SERVICE_NAME="herobudget"
REPO_URL="https://github.com/usuario/herobudget-backend.git"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Variables
BRANCH="${1:-main}"
FORCE_DEPLOY="${2:-}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_PATH}/webhook_deploy_${TIMESTAMP}.log"

# Funciones de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_header() {
    echo -e "${PURPLE}${1}${NC}" | tee -a "$LOG_FILE"
    echo "==================================================" | tee -a "$LOG_FILE"
}

# Crear directorio de logs si no existe
mkdir -p "$LOG_PATH"

# Función para verificar prerequisitos
check_prerequisites() {
    log_header "🔍 VERIFICANDO PREREQUISITOS"
    
    # Verificar conexión SSH
    log_info "Verificando conexión SSH al VPS..."
    if ! ssh -o ConnectTimeout=10 "$VPS_USER@$VPS_HOST" "echo 'SSH OK'" >/dev/null 2>&1; then
        log_error "No se puede conectar al VPS $VPS_HOST"
        exit 1
    fi
    log_success "Conexión SSH establecida"
    
    # Verificar estructura de directorios en VPS
    log_info "Verificando estructura de directorios en VPS..."
    ssh "$VPS_USER@$VPS_HOST" "
        mkdir -p $BACKEND_PATH $BACKUP_PATH $LOG_PATH
        echo 'Directorios verificados'
    "
    log_success "Estructura de directorios verificada"
}

# Función para realizar backup
create_backup() {
    log_header "💾 CREANDO BACKUP PRE-DEPLOY"
    
    local backup_file="webhook_backup_${TIMESTAMP}.tar.gz"
    
    ssh "$VPS_USER@$VPS_HOST" "
        if [ -d '$BACKEND_PATH' ] && [ ! -z \"\$(ls -A $BACKEND_PATH 2>/dev/null)\" ]; then
            cd /opt/hero_budget
            tar -czf $BACKUP_PATH/$backup_file backend/
            echo 'Backup creado: $backup_file'
            ls -lh $BACKUP_PATH/$backup_file
        else
            echo 'No hay backend previo para backup'
        fi
    "
    
    log_success "Backup completado: $backup_file"
    echo "$backup_file" > "/tmp/last_backup.txt"
}

# Función para realizar git pull rebase
git_pull_rebase() {
    log_header "📥 EJECUTANDO GIT PULL REBASE"
    
    ssh "$VPS_USER@$VPS_HOST" << EOF
        # Navegar al directorio del backend
        cd $BACKEND_PATH
        
        # Si no existe el repositorio, clonarlo
        if [ ! -d ".git" ]; then
            echo "🔄 Repositorio no existe, clonando..."
            rm -rf *
            git clone $REPO_URL .
            git checkout $BRANCH
        else
            echo "📥 Repositorio existe, actualizando..."
            
            # Guardar cambios locales si existen
            if ! git diff --quiet; then
                echo "⚠️ Hay cambios locales, guardando..."
                git stash push -m "Auto-stash before webhook deploy $TIMESTAMP"
            fi
            
            # Fetch latest changes
            echo "🔍 Obteniendo últimos cambios..."
            git fetch origin
            
            # Switch to target branch
            echo "🔀 Cambiando a branch $BRANCH..."
            git checkout $BRANCH
            
            # Perform rebase
            echo "🔄 Ejecutando rebase..."
            if git rebase origin/$BRANCH; then
                echo "✅ Rebase exitoso"
            else
                echo "❌ Conflictos en rebase, abortando..."
                git rebase --abort
                exit 1
            fi
            
            # Apply stashed changes if any
            if git stash list | grep -q "Auto-stash before webhook deploy"; then
                echo "🔄 Aplicando cambios guardados..."
                git stash pop || echo "⚠️ Conflictos al aplicar stash"
            fi
        fi
        
        # Mostrar estado final
        echo "📊 Estado final del repositorio:"
        git log --oneline -5
        echo ""
        echo "📂 Branch actual: \$(git branch --show-current)"
        echo "📌 Último commit: \$(git rev-parse --short HEAD)"
EOF
    
    if [ $? -eq 0 ]; then
        log_success "Git pull rebase completado exitosamente"
    else
        log_error "Error durante git pull rebase"
        exit 1
    fi
}

# Función para compilar aplicación
compile_application() {
    log_header "🔨 COMPILANDO APLICACIÓN"
    
    ssh "$VPS_USER@$VPS_HOST" << 'EOF'
        cd $BACKEND_PATH
        
        # Verificar archivos Go
        if [ -f "go.mod" ]; then
            echo "📦 go.mod encontrado, compilando..."
            
            # Limpiar builds anteriores
            rm -f main herobudget
            
            # Compilar aplicación principal
            if go build -o main .; then
                echo "✅ Compilación exitosa"
                chmod +x main
                ls -la main
            else
                echo "❌ Error en compilación"
                exit 1
            fi
        else
            echo "⚠️ go.mod no encontrado, verificando estructura..."
            find . -name "*.go" -type f | head -5
        fi
EOF
    
    if [ $? -eq 0 ]; then
        log_success "Compilación completada"
    else
        log_error "Error durante compilación"
        exit 1
    fi
}

# Función principal de deployment
main() {
    log_header "🚀 INICIANDO WEBHOOK DEPLOYMENT AUTOMÁTICO"
    log_info "Branch: $BRANCH"
    log_info "Timestamp: $TIMESTAMP"
    log_info "Log file: $LOG_FILE"
    
    # Ejecutar pasos del deployment
    check_prerequisites
    create_backup
    git_pull_rebase
    compile_application
    
    log_success "Deployment automático completado exitosamente"
    log_info "Ahora ejecute el script de reinicio de servicios:"
    log_info "./scripts/manage_services.sh restart"
    
    # Crear marcador de deployment exitoso
    echo "$TIMESTAMP" > "/tmp/last_successful_deploy.txt"
}

# Manejo de errores
trap 'log_error "Error en línea $LINENO. Deployment fallido."; exit 1' ERR

# Ejecutar función principal
main "$@" 