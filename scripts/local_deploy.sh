#!/bin/bash
# Script de deployment local para VPS
# Se ejecuta directamente en el VPS sin SSH

set -e

# Configuración
BACKEND_PATH="/opt/hero_budget/backend"
BACKUP_PATH="/opt/hero_budget/backups"
LOG_PATH="/opt/hero_budget/logs"
SERVICE_NAME="herobudget"
REPO_URL="https://github.com/jaivial/herobudget-backend.git"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Variables
BRANCH="${1:-main}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_PATH}/local_deploy_${TIMESTAMP}.log"

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
mkdir -p "$LOG_PATH" "$BACKUP_PATH"

# Función para realizar backup
create_backup() {
    log_header "💾 CREANDO BACKUP PRE-DEPLOY"
    
    local backup_file="local_backup_${TIMESTAMP}.tar.gz"
    
    if [ -d "$BACKEND_PATH" ] && [ ! -z "$(ls -A $BACKEND_PATH 2>/dev/null)" ]; then
        cd /opt/hero_budget
        tar -czf "$BACKUP_PATH/$backup_file" backend/ 2>/dev/null || true
        log_success "Backup creado: $backup_file"
        ls -lh "$BACKUP_PATH/$backup_file" 2>/dev/null || true
    else
        log_info "No hay backend previo para backup"
    fi
}

# Función para realizar git pull rebase
git_pull_rebase() {
    log_header "📥 EJECUTANDO GIT PULL REBASE"
    
    # Crear directorio si no existe
    mkdir -p "$BACKEND_PATH"
    cd "$BACKEND_PATH"
    
    # Si no existe el repositorio, clonarlo
    if [ ! -d ".git" ]; then
        log_info "🔄 Repositorio no existe, clonando..."
        rm -rf ./*
        git clone "$REPO_URL" .
        git checkout "$BRANCH"
    else
        log_info "📥 Repositorio existe, actualizando..."
        
        # Guardar cambios locales si existen
        if ! git diff --quiet || ! git diff --cached --quiet; then
            log_warning "⚠️ Hay cambios locales, guardando..."
            
            # Agregar archivos no trackeados importantes
            git add -A 2>/dev/null || true
            
            # Hacer stash forzado
            git stash push -m "Auto-stash before local deploy $TIMESTAMP" --include-untracked 2>/dev/null || true
        fi
        
        # Reset hard para limpiar cualquier estado inconsistente
        log_info "🧹 Limpiando estado del repositorio..."
        git reset --hard HEAD 2>/dev/null || true
        git clean -fd 2>/dev/null || true
        
        # Fetch latest changes
        log_info "🔍 Obteniendo últimos cambios..."
        git fetch origin
        
        # Switch to target branch y hacer reset hard
        log_info "🔀 Cambiando a branch $BRANCH..."
        git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH" "origin/$BRANCH"
        git reset --hard "origin/$BRANCH"
        
        log_success "✅ Repositorio actualizado exitosamente"
    fi
    
    # Mostrar estado final
    log_info "📊 Estado final del repositorio:"
    git log --oneline -5
    echo ""
    log_info "📂 Branch actual: $(git branch --show-current)"
    log_info "📌 Último commit: $(git rev-parse --short HEAD)"
    
    log_success "Git pull rebase completado exitosamente"
}

# Función para compilar aplicación
compile_application() {
    log_header "🔨 COMPILANDO APLICACIÓN"
    
    cd "$BACKEND_PATH"
    
    # Verificar archivos Go
    if [ -f "go.mod" ]; then
        log_info "📦 go.mod encontrado, compilando..."
        
        # Limpiar builds anteriores
        rm -f main herobudget
        
        # Compilar aplicación principal
        if go build -o main .; then
            log_success "✅ Compilación exitosa"
            chmod +x main
            ls -la main
        else
            log_error "❌ Error en compilación"
            exit 1
        fi
    else
        log_warning "⚠️ go.mod no encontrado, verificando estructura..."
        find . -name "*.go" -type f | head -5
    fi
    
    log_success "Compilación completada"
}

# Función para gestionar servicios
manage_services() {
    log_header "🔄 GESTIONANDO SERVICIOS"
    
    # Detener servicios si existen
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        log_info "🛑 Deteniendo servicio $SERVICE_NAME..."
        systemctl stop "$SERVICE_NAME" || true
    fi
    
    # Iniciar servicios
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        log_info "🚀 Iniciando servicio $SERVICE_NAME..."
        systemctl start "$SERVICE_NAME" || true
        sleep 2
        
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            log_success "✅ Servicio $SERVICE_NAME iniciado correctamente"
        else
            log_warning "⚠️ Servicio $SERVICE_NAME no se pudo iniciar"
        fi
    else
        log_info "ℹ️ Servicio $SERVICE_NAME no está configurado"
    fi
}

# Función principal
main() {
    log_header "🚀 INICIANDO DEPLOYMENT LOCAL"
    log_info "Branch: $BRANCH"
    log_info "Timestamp: $TIMESTAMP"
    log_info "Log file: $LOG_FILE"
    
    # Ejecutar pasos del deployment
    create_backup
    git_pull_rebase
    compile_application
    manage_services
    
    log_header "🎉 DEPLOYMENT COMPLETADO EXITOSAMENTE"
    log_success "Deployment local finalizado en $(date)"
    log_info "📝 Log completo: $LOG_FILE"
    
    exit 0
}

# Ejecutar función principal
main "$@" 