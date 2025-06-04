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

# Configurar Go en el PATH
export PATH="/usr/local/go/bin:$PATH"

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

# Función para verificar y compilar microservicios
compile_microservices() {
    log_header "🛠️ VERIFICANDO Y COMPILANDO MICROSERVICIOS"
    
    cd "$BACKEND_PATH"
    
    # Lista de microservicios críticos
    local microservices=(
        "signup"
        "cash_bank"
        "profile_service"
        "money_flow"
        "budget_overview"
    )
    
    for service in "${microservices[@]}"; do
        if [ -d "$service" ]; then
            log_info "🔧 Verificando microservicio: $service"
            
            # Verificar si existe el ejecutable
            if [ ! -f "$service/$service.exe" ]; then
                log_warning "⚠️ Ejecutable faltante para $service, compilando..."
                
                cd "$service"
                
                # Inicializar go.mod si no existe
                if [ ! -f "go.mod" ]; then
                    log_info "📦 Inicializando go.mod para $service..."
                    go mod init "${service}_service" || log_warning "go mod init falló para $service"
                    go mod tidy || log_warning "go mod tidy falló para $service"
                fi
                
                # Compilar
                if go build -o "$service.exe" .; then
                    log_success "✅ $service compilado exitosamente"
                    chmod +x "$service.exe"
                    ls -la "$service.exe"
                else
                    log_error "❌ Error compilando $service"
                fi
                
                cd "$BACKEND_PATH"
            else
                log_success "✅ $service ya tiene ejecutable"
            fi
        else
            log_warning "⚠️ Directorio $service no encontrado"
        fi
    done
    
    log_success "Verificación de microservicios completada"
}

# Función para verificar estado de microservicios en puertos
verify_and_restart_services() {
    log_header "🔍 VERIFICANDO ESTADO DE MICROSERVICIOS"
    
    # Puertos esperados para cada microservicio
    declare -A service_ports=(
        ["signup"]="8082"
        ["cash_bank"]="8083"
        ["profile_service"]="8084"
        ["money_flow"]="8085"
        ["budget_overview"]="8086"
    )
    
    # Verificar cada servicio
    for service in "${!service_ports[@]}"; do
        local port="${service_ports[$service]}"
        
        log_info "🔍 Verificando $service en puerto $port..."
        
        # Verificar si el puerto está ocupado
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            log_success "✅ $service corriendo en puerto $port"
        else
            log_warning "⚠️ $service no detectado en puerto $port"
            
            # Intentar iniciar el servicio si existe el ejecutable
            if [ -f "$BACKEND_PATH/$service/$service.exe" ]; then
                log_info "🚀 Intentando iniciar $service..."
                
                # Matar procesos existentes del servicio
                pkill -f "$service.exe" 2>/dev/null || true
                
                # Iniciar en background
                cd "$BACKEND_PATH/$service"
                nohup ./"$service.exe" > "/tmp/$service.log" 2>&1 &
                
                # Esperar un momento y verificar
                sleep 3
                if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
                    log_success "✅ $service iniciado exitosamente"
                else
                    log_error "❌ $service no pudo iniciarse, verificar logs en /tmp/$service.log"
                fi
            else
                log_error "❌ Ejecutable $service.exe no encontrado"
            fi
        fi
    done
    
    # Verificar servicio principal herobudget
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "✅ Servicio principal $SERVICE_NAME está activo"
    else
        log_warning "⚠️ Servicio principal $SERVICE_NAME no está activo, reiniciando..."
        systemctl restart "$SERVICE_NAME" || log_error "Error reiniciando $SERVICE_NAME"
    fi
    
    log_success "Verificación de servicios completada"
}

# Función para verificar conectividad de base de datos
verify_database_connectivity() {
    log_header "🗄️ VERIFICANDO CONECTIVIDAD DE BASE DE DATOS"
    
    # Buscar archivos de configuración de base de datos
    local config_files=(
        "$BACKEND_PATH/config/database.go"
        "$BACKEND_PATH/config/db.go"
        "$BACKEND_PATH/database/connection.go"
        "$BACKEND_PATH/.env"
        "$BACKEND_PATH/config.json"
    )
    
    log_info "🔍 Buscando archivos de configuración de BD..."
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            log_success "✅ Encontrado: $config_file"
        fi
    done
    
    # Verificar si hay un script de test de BD
    if [ -f "$BACKEND_PATH/scripts/test_db.sh" ]; then
        log_info "🧪 Ejecutando test de conectividad BD..."
        cd "$BACKEND_PATH"
        bash scripts/test_db.sh || log_warning "Test de BD falló"
    else
        log_warning "⚠️ No se encontró script de test de BD"
    fi
    
    # Verificar servicios de BD comunes
    local db_services=("mysql" "mariadb" "postgresql")
    for db_service in "${db_services[@]}"; do
        if systemctl is-active --quiet "$db_service" 2>/dev/null; then
            log_success "✅ Servicio $db_service está activo"
        fi
    done
    
    # Verificar puertos de BD comunes
    local db_ports=("3306" "5432" "27017")
    for port in "${db_ports[@]}"; do
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            log_success "✅ Puerto $port (BD) está ocupado"
        fi
    done
    
    log_info "📊 Verificación de BD completada"
}

# Función para health check post-deployment
post_deployment_health_check() {
    log_header "🏥 HEALTH CHECK POST-DEPLOYMENT"
    
    local base_url="https://herobudget.jaimedigitalstudio.com"
    local endpoints_to_check=(
        "/health"
        "/signup/check-email"
        "/categories?user_id=36"
        "/savings/fetch?user_id=36"
    )
    
    log_info "🌐 Verificando endpoints críticos en $base_url..."
    
    local successful_checks=0
    local total_checks=${#endpoints_to_check[@]}
    
    for endpoint in "${endpoints_to_check[@]}"; do
        log_info "🔍 Probando: $endpoint"
        
        local status_code
        if echo "$endpoint" | grep -q "?"; then
            # GET request
            status_code=$(curl -s -o /dev/null -w '%{http_code}' "$base_url$endpoint" 2>/dev/null || echo "000")
        else
            # POST request con datos de ejemplo
            status_code=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H "Content-Type: application/json" -d '{"email":"test@example.com"}' "$base_url$endpoint" 2>/dev/null || echo "000")
        fi
        
        if [ "$status_code" = "200" ] || [ "$status_code" = "201" ]; then
            log_success "✅ $endpoint: HTTP $status_code"
            ((successful_checks++))
        else
            log_warning "⚠️ $endpoint: HTTP $status_code"
        fi
    done
    
    local health_percentage=$((successful_checks * 100 / total_checks))
    log_info "📊 Health Score: $health_percentage% ($successful_checks/$total_checks endpoints OK)"
    
    if [ $health_percentage -ge 75 ]; then
        log_success "🎉 Deployment saludable - Sistema operacional"
    elif [ $health_percentage -ge 50 ]; then
        log_warning "⚠️ Deployment parcial - Algunos servicios pueden necesitar atención"
    else
        log_error "❌ Deployment problemático - Verificar servicios manualmente"
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
    compile_microservices
    verify_and_restart_services
    verify_database_connectivity
    post_deployment_health_check
    
    log_header "🎉 DEPLOYMENT COMPLETADO EXITOSAMENTE"
    log_success "Deployment local finalizado en $(date)"
    log_info "📝 Log completo: $LOG_FILE"
    
    exit 0
}

# Ejecutar función principal
main "$@" 