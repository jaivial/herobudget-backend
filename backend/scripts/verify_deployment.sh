#!/bin/bash
# Script de verificación post-deployment
# Versión: 1.0
# Uso: ./verify_deployment.sh [--timeout SECONDS] [--detailed]

set -e

# Configuración
VPS_HOST="178.16.130.178"
VPS_USER="root"
SERVICE_NAME="herobudget"
TIMEOUT="${2:-300}"  # 5 minutos por defecto
DETAILED_CHECK="${1:-}"

# URLs a verificar
MAIN_URL="https://herobudget.jaimedigitalstudio.com"
ENDPOINTS=(
    "${MAIN_URL}/"
    "${MAIN_URL}/auth/google"
    "${MAIN_URL}/api/health"
    "${MAIN_URL}/dashboard"
)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Variables de estado
VERIFICATION_RESULTS=()
FAILED_CHECKS=0
TOTAL_CHECKS=0

# Funciones de logging
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

log_header() {
    echo -e "${PURPLE}${1}${NC}"
    echo "=================================================="
}

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --timeout SECONDS         Timeout para verificaciones (default: 300)"
    echo "  --detailed                Mostrar información detallada"
    echo "  --help                    Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0"
    echo "  $0 --detailed --timeout 600"
}

# Verificar parámetros
if [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Función para agregar resultado de verificación
add_check_result() {
    local check_name="$1"
    local status="$2"
    local details="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ "$status" = "PASS" ]; then
        VERIFICATION_RESULTS+=("✅ $check_name - $details")
    elif [ "$status" = "WARN" ]; then
        VERIFICATION_RESULTS+=("⚠️ $check_name - $details")
    else
        VERIFICATION_RESULTS+=("❌ $check_name - $details")
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# Función para verificar servicios del sistema
check_system_services() {
    log_header "🔍 VERIFICANDO SERVICIOS DEL SISTEMA"
    
    local services=("herobudget" "nginx" "postgresql")
    
    for service in "${services[@]}"; do
        log_info "Verificando servicio: $service"
        
        local status=$(ssh "$VPS_USER@$VPS_HOST" "systemctl is-active $service 2>/dev/null || echo 'inactive'")
        
        if [ "$status" = "active" ]; then
            add_check_result "Servicio $service" "PASS" "Activo y funcionando"
            
            if [ "$DETAILED_CHECK" = "--detailed" ]; then
                local uptime=$(ssh "$VPS_USER@$VPS_HOST" "systemctl show $service --property=ActiveEnterTimestamp --value 2>/dev/null || echo 'N/A'")
                log_info "  Uptime: $uptime"
            fi
        else
            add_check_result "Servicio $service" "FAIL" "Inactivo o con problemas"
        fi
    done
}

# Función para verificar conectividad de red
check_network_connectivity() {
    log_header "🌐 VERIFICANDO CONECTIVIDAD DE RED"
    
    # Verificar conectividad SSH
    log_info "Verificando conectividad SSH..."
    if ssh -o ConnectTimeout=10 "$VPS_USER@$VPS_HOST" "echo 'SSH OK'" >/dev/null 2>&1; then
        add_check_result "Conectividad SSH" "PASS" "Conexión establecida correctamente"
    else
        add_check_result "Conectividad SSH" "FAIL" "No se puede conectar via SSH"
        return 1
    fi
    
    # Verificar puertos abiertos
    log_info "Verificando puertos críticos..."
    local ports=("80:HTTP" "443:HTTPS" "22:SSH")
    
    for port_info in "${ports[@]}"; do
        local port="${port_info%:*}"
        local service="${port_info#*:}"
        
        log_info "Verificando puerto $port ($service)..."
        
        if ssh "$VPS_USER@$VPS_HOST" "netstat -tlnp | grep -q :$port " 2>/dev/null; then
            add_check_result "Puerto $port ($service)" "PASS" "Puerto abierto y escuchando"
        else
            add_check_result "Puerto $port ($service)" "WARN" "Puerto no está escuchando"
        fi
    done
}

# Función para verificar endpoints web
check_web_endpoints() {
    log_header "🌍 VERIFICANDO ENDPOINTS WEB"
    
    local start_time=$(date +%s)
    
    for endpoint in "${ENDPOINTS[@]}"; do
        log_info "Verificando endpoint: $endpoint"
        
        local attempts=0
        local max_attempts=3
        local success=false
        
        while [ $attempts -lt $max_attempts ] && [ "$success" = false ]; do
            attempts=$((attempts + 1))
            
            local http_code=$(curl -s --max-time 15 -o /dev/null -w '%{http_code}' "$endpoint" 2>/dev/null || echo "000")
            local response_time=$(curl -s --max-time 15 -o /dev/null -w '%{time_total}' "$endpoint" 2>/dev/null || echo "999")
            
            if [[ "$http_code" =~ ^[23] ]]; then
                add_check_result "Endpoint $(basename $endpoint)" "PASS" "HTTP $http_code (${response_time}s)"
                success=true
                
                if [ "$DETAILED_CHECK" = "--detailed" ]; then
                    local size=$(curl -s --max-time 15 -o /dev/null -w '%{size_download}' "$endpoint" 2>/dev/null || echo "0")
                    log_info "  Tamaño respuesta: ${size} bytes"
                fi
            else
                if [ $attempts -eq $max_attempts ]; then
                    add_check_result "Endpoint $(basename $endpoint)" "FAIL" "HTTP $http_code después de $attempts intentos"
                else
                    log_info "  Intento $attempts/$max_attempts falló (HTTP $http_code), reintentando..."
                    sleep 5
                fi
            fi
        done
        
        # Verificar timeout general
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $TIMEOUT ]; then
            log_warning "Timeout alcanzado ($TIMEOUT segundos), interrumpiendo verificaciones web"
            break
        fi
    done
}

# Función para verificar logs del sistema
check_system_logs() {
    log_header "📋 VERIFICANDO LOGS DEL SISTEMA"
    
    log_info "Verificando logs del servicio Hero Budget..."
    
    # Verificar si hay errores recientes en los logs
    local error_count=$(ssh "$VPS_USER@$VPS_HOST" "journalctl -u $SERVICE_NAME --since '10 minutes ago' --no-pager | grep -i -c 'error\|failed\|exception' || echo '0'")
    
    if [ "$error_count" -eq 0 ]; then
        add_check_result "Logs del sistema" "PASS" "No se encontraron errores recientes"
    elif [ "$error_count" -lt 5 ]; then
        add_check_result "Logs del sistema" "WARN" "$error_count errores encontrados en últimos 10 minutos"
    else
        add_check_result "Logs del sistema" "FAIL" "$error_count errores encontrados en últimos 10 minutos"
    fi
    
    if [ "$DETAILED_CHECK" = "--detailed" ]; then
        log_info "Últimas 5 líneas del log:"
        ssh "$VPS_USER@$VPS_HOST" "journalctl -u $SERVICE_NAME --no-pager -n 5 | sed 's/^/  /'"
    fi
}

# Función para verificar recursos del sistema
check_system_resources() {
    log_header "💻 VERIFICANDO RECURSOS DEL SISTEMA"
    
    log_info "Verificando uso de recursos..."
    
    # Verificar uso de CPU
    local cpu_usage=$(ssh "$VPS_USER@$VPS_HOST" "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1" 2>/dev/null || echo "0")
    
    if [ "${cpu_usage%.*}" -lt 80 ]; then
        add_check_result "Uso de CPU" "PASS" "${cpu_usage}% utilizado"
    else
        add_check_result "Uso de CPU" "WARN" "${cpu_usage}% utilizado (alto)"
    fi
    
    # Verificar uso de memoria
    local mem_info=$(ssh "$VPS_USER@$VPS_HOST" "free | grep Mem" 2>/dev/null || echo "Mem: 0 0 0")
    local mem_total=$(echo $mem_info | awk '{print $2}')
    local mem_used=$(echo $mem_info | awk '{print $3}')
    
    if [ "$mem_total" -gt 0 ]; then
        local mem_percentage=$((mem_used * 100 / mem_total))
        
        if [ "$mem_percentage" -lt 85 ]; then
            add_check_result "Uso de memoria" "PASS" "${mem_percentage}% utilizada"
        else
            add_check_result "Uso de memoria" "WARN" "${mem_percentage}% utilizada (alto)"
        fi
    else
        add_check_result "Uso de memoria" "WARN" "No se pudo obtener información de memoria"
    fi
    
    # Verificar espacio en disco
    local disk_usage=$(ssh "$VPS_USER@$VPS_HOST" "df -h / | tail -1 | awk '{print \$5}' | cut -d'%' -f1" 2>/dev/null || echo "0")
    
    if [ "$disk_usage" -lt 85 ]; then
        add_check_result "Espacio en disco" "PASS" "${disk_usage}% utilizado"
    else
        add_check_result "Espacio en disco" "WARN" "${disk_usage}% utilizado (alto)"
    fi
}

# Función para verificar base de datos
check_database() {
    log_header "🗄️ VERIFICANDO BASE DE DATOS"
    
    log_info "Verificando conectividad a PostgreSQL..."
    
    local db_status=$(ssh "$VPS_USER@$VPS_HOST" "sudo -u postgres psql -d herobudget -c 'SELECT 1;' 2>/dev/null && echo 'OK' || echo 'FAIL'")
    
    if [ "$db_status" = "OK" ]; then
        add_check_result "Base de datos" "PASS" "PostgreSQL conectando correctamente"
        
        if [ "$DETAILED_CHECK" = "--detailed" ]; then
            local table_count=$(ssh "$VPS_USER@$VPS_HOST" "sudo -u postgres psql -d herobudget -t -c \"SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';\" 2>/dev/null || echo '0'")
            log_info "  Tablas en la base de datos: $table_count"
        fi
    else
        add_check_result "Base de datos" "FAIL" "No se puede conectar a PostgreSQL"
    fi
}

# Función para mostrar resumen de resultados
show_verification_summary() {
    log_header "📊 RESUMEN DE VERIFICACIÓN"
    
    echo ""
    for result in "${VERIFICATION_RESULTS[@]}"; do
        echo "$result"
    done
    
    echo ""
    echo "=================================================="
    
    local success_count=$((TOTAL_CHECKS - FAILED_CHECKS))
    local success_percentage=$((success_count * 100 / TOTAL_CHECKS))
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        log_success "✅ VERIFICACIÓN COMPLETADA - Todos los checks pasaron"
        log_success "📊 Resultado: $success_count/$TOTAL_CHECKS checks exitosos ($success_percentage%)"
        return 0
    elif [ $FAILED_CHECKS -lt 3 ]; then
        log_warning "⚠️ VERIFICACIÓN CON ADVERTENCIAS"
        log_warning "📊 Resultado: $success_count/$TOTAL_CHECKS checks exitosos ($success_percentage%)"
        log_warning "🚨 $FAILED_CHECKS checks fallaron"
        return 1
    else
        log_error "❌ VERIFICACIÓN FALLIDA"
        log_error "📊 Resultado: $success_count/$TOTAL_CHECKS checks exitosos ($success_percentage%)"
        log_error "🚨 $FAILED_CHECKS checks fallaron"
        return 2
    fi
}

# Función principal
main() {
    log_header "🔍 VERIFICACIÓN POST-DEPLOYMENT"
    log_info "Timeout: $TIMEOUT segundos"
    log_info "Modo detallado: ${DETAILED_CHECK:-No}"
    log_info "Timestamp: $(date)"
    
    # Ejecutar todas las verificaciones
    check_system_services
    check_network_connectivity
    check_web_endpoints
    check_system_logs
    check_system_resources
    check_database
    
    # Mostrar resumen y determinar código de salida
    show_verification_summary
}

# Manejo de errores
trap 'log_error "Error en línea $LINENO. Verificación interrumpida."; exit 1' ERR

# Ejecutar función principal
main "$@" 