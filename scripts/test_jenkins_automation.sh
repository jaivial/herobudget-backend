#!/bin/bash
# Script de testing completo para automatización Jenkins
# Versión: 1.0
# Uso: ./test_jenkins_automation.sh [--full] [--no-deploy]

set -e

# Configuración
JENKINS_URL="http://178.16.130.178:8080"
VPS_HOST="178.16.130.178"
VPS_USER="root"
GITHUB_WEBHOOK_URL="${JENKINS_URL}/github-webhook/"
JOB_NAME="herobudget-backend"
TEST_MODE="${1:-}"
SKIP_DEPLOY="${2:-}"

# URLs a probar
MAIN_URL="https://herobudget.jaimedigitalstudio.com"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Variables de testing
TEST_RESULTS=()
FAILED_TESTS=0
TOTAL_TESTS=0
TEST_START_TIME=$(date +%s)

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

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --full                    Ejecutar suite completa de tests"
    echo "  --no-deploy               Omitir tests de deployment"
    echo "  --help                    Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0                        # Tests básicos"
    echo "  $0 --full                 # Suite completa"
    echo "  $0 --no-deploy            # Sin tests de deployment"
}

# Verificar parámetros
if [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Función para agregar resultado de test
add_test_result() {
    local test_name="$1"
    local status="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$status" = "PASS" ]; then
        TEST_RESULTS+=("✅ $test_name - $details")
    else
        TEST_RESULTS+=("❌ $test_name - $details")
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test: Verificar conectividad básica
test_basic_connectivity() {
    log_header "🔍 TEST: CONECTIVIDAD BÁSICA"
    
    # Test SSH
    log_test "Verificando conexión SSH al VPS..."
    if ssh -o ConnectTimeout=10 "$VPS_USER@$VPS_HOST" "echo 'SSH OK'" >/dev/null 2>&1; then
        add_test_result "Conectividad SSH" "PASS" "Conexión establecida"
    else
        add_test_result "Conectividad SSH" "FAIL" "No se puede conectar"
    fi
    
    # Test Jenkins
    log_test "Verificando acceso a Jenkins..."
    if curl -s --max-time 10 "$JENKINS_URL/login" >/dev/null 2>&1; then
        add_test_result "Acceso Jenkins" "PASS" "Jenkins accesible"
    else
        add_test_result "Acceso Jenkins" "FAIL" "Jenkins no accesible"
    fi
    
    # Test sitio principal
    log_test "Verificando sitio principal..."
    local http_code=$(curl -s --max-time 15 -o /dev/null -w '%{http_code}' "$MAIN_URL" 2>/dev/null || echo "000")
    if [[ "$http_code" =~ ^[23] ]]; then
        add_test_result "Sitio principal" "PASS" "HTTP $http_code"
    else
        add_test_result "Sitio principal" "FAIL" "HTTP $http_code"
    fi
}

# Test: Verificar scripts en VPS
test_scripts_availability() {
    log_header "📋 TEST: DISPONIBILIDAD DE SCRIPTS"
    
    local scripts=(
        "webhook_deploy.sh"
        "manage_services.sh" 
        "verify_deployment.sh"
        "jenkins_webhook_setup.sh"
    )
    
    for script in "${scripts[@]}"; do
        log_test "Verificando script: $script"
        
        if ssh "$VPS_USER@$VPS_HOST" "[ -x /opt/hero_budget/scripts/$script ]"; then
            add_test_result "Script $script" "PASS" "Existe y es ejecutable"
        else
            add_test_result "Script $script" "FAIL" "No existe o no es ejecutable"
        fi
    done
}

# Test: Verificar configuración Jenkins
test_jenkins_configuration() {
    log_header "⚙️ TEST: CONFIGURACIÓN JENKINS"
    
    # Test job existe
    log_test "Verificando job Jenkins existe..."
    if curl -s "$JENKINS_URL/job/$JOB_NAME/api/json" >/dev/null 2>&1; then
        add_test_result "Job Jenkins" "PASS" "Job '$JOB_NAME' existe"
    else
        add_test_result "Job Jenkins" "FAIL" "Job '$JOB_NAME' no encontrado"
    fi
    
    # Test webhook endpoint
    log_test "Verificando endpoint webhook..."
    local webhook_status=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GITHUB_WEBHOOK_URL" 2>/dev/null || echo "000")
    if [ "$webhook_status" = "200" ] || [ "$webhook_status" = "302" ]; then
        add_test_result "Webhook endpoint" "PASS" "Endpoint responde (HTTP $webhook_status)"
    else
        add_test_result "Webhook endpoint" "FAIL" "Endpoint no responde (HTTP $webhook_status)"
    fi
}

# Test: Verificar servicios del sistema
test_system_services() {
    log_header "🔧 TEST: SERVICIOS DEL SISTEMA"
    
    local services=("herobudget" "nginx" "postgresql" "jenkins")
    
    for service in "${services[@]}"; do
        log_test "Verificando servicio: $service"
        
        local status=$(ssh "$VPS_USER@$VPS_HOST" "systemctl is-active $service 2>/dev/null || echo 'inactive'")
        
        if [ "$status" = "active" ]; then
            add_test_result "Servicio $service" "PASS" "Activo"
        else
            add_test_result "Servicio $service" "FAIL" "Inactivo"
        fi
    done
}

# Test: Probar gestión de servicios
test_service_management() {
    log_header "🔄 TEST: GESTIÓN DE SERVICIOS"
    
    if [ "$SKIP_DEPLOY" = "--no-deploy" ]; then
        log_warning "Omitiendo tests de gestión de servicios (--no-deploy)"
        return 0
    fi
    
    # Test status
    log_test "Probando comando status..."
    if ssh "$VPS_USER@$VPS_HOST" "/opt/hero_budget/scripts/manage_services.sh status" >/dev/null 2>&1; then
        add_test_result "Comando status" "PASS" "Ejecuta correctamente"
    else
        add_test_result "Comando status" "FAIL" "Error al ejecutar"
    fi
    
    # Test health
    log_test "Probando comando health..."
    if ssh "$VPS_USER@$VPS_HOST" "/opt/hero_budget/scripts/manage_services.sh health" >/dev/null 2>&1; then
        add_test_result "Comando health" "PASS" "Ejecuta correctamente"
    else
        add_test_result "Comando health" "FAIL" "Error al ejecutar"
    fi
}

# Test: Probar verificación de deployment
test_deployment_verification() {
    log_header "✅ TEST: VERIFICACIÓN DE DEPLOYMENT"
    
    if [ "$SKIP_DEPLOY" = "--no-deploy" ]; then
        log_warning "Omitiendo tests de verificación de deployment (--no-deploy)"
        return 0
    fi
    
    log_test "Ejecutando verify_deployment.sh..."
    
    local verify_result=$(ssh "$VPS_USER@$VPS_HOST" "/opt/hero_budget/scripts/verify_deployment.sh --timeout 120" 2>/dev/null && echo "PASS" || echo "FAIL")
    
    if [ "$verify_result" = "PASS" ]; then
        add_test_result "Verificación deployment" "PASS" "Todas las verificaciones pasaron"
    else
        add_test_result "Verificación deployment" "FAIL" "Falló alguna verificación"
    fi
}

# Test: Simular webhook (si está habilitado)
test_webhook_simulation() {
    log_header "🔗 TEST: SIMULACIÓN WEBHOOK"
    
    if [ "$TEST_MODE" != "--full" ]; then
        log_warning "Omitiendo simulación webhook (usar --full para habilitar)"
        return 0
    fi
    
    if [ "$SKIP_DEPLOY" = "--no-deploy" ]; then
        log_warning "Omitiendo simulación webhook (--no-deploy activo)"
        return 0
    fi
    
    log_test "Simulando webhook de GitHub..."
    
    # Crear payload simulado de GitHub
    local webhook_payload='{"ref":"refs/heads/main","repository":{"name":"herobudget-backend"}}'
    
    local webhook_response=$(curl -s -X POST "$GITHUB_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -H "X-GitHub-Event: push" \
        -d "$webhook_payload" \
        -o /dev/null -w '%{http_code}' 2>/dev/null || echo "000")
    
    if [ "$webhook_response" = "200" ] || [ "$webhook_response" = "302" ]; then
        add_test_result "Simulación webhook" "PASS" "Webhook procesado (HTTP $webhook_response)"
        
        # Esperar un momento y verificar que Jenkins ejecutó algo
        log_test "Esperando respuesta de Jenkins..."
        sleep 10
        
        # Verificar último build
        local last_build=$(curl -s "$JENKINS_URL/job/$JOB_NAME/lastBuild/api/json" 2>/dev/null || echo '{}')
        if echo "$last_build" | grep -q '"number"'; then
            add_test_result "Trigger Jenkins" "PASS" "Jenkins ejecutó build"
        else
            add_test_result "Trigger Jenkins" "FAIL" "Jenkins no ejecutó build"
        fi
    else
        add_test_result "Simulación webhook" "FAIL" "Webhook falló (HTTP $webhook_response)"
    fi
}

# Test: Verificar logs y monitoreo
test_logging_monitoring() {
    log_header "📊 TEST: LOGS Y MONITOREO"
    
    # Test logs Jenkins
    log_test "Verificando logs Jenkins..."
    if ssh "$VPS_USER@$VPS_HOST" "journalctl -u jenkins --no-pager -n 1" >/dev/null 2>&1; then
        add_test_result "Logs Jenkins" "PASS" "Logs accesibles"
    else
        add_test_result "Logs Jenkins" "FAIL" "No se pueden acceder logs"
    fi
    
    # Test directorio logs
    log_test "Verificando directorio de logs..."
    if ssh "$VPS_USER@$VPS_HOST" "[ -d /opt/hero_budget/logs ]"; then
        add_test_result "Directorio logs" "PASS" "Directorio existe"
    else
        add_test_result "Directorio logs" "FAIL" "Directorio no existe"
    fi
    
    # Test log de deployments
    log_test "Verificando log de deployments..."
    if ssh "$VPS_USER@$VPS_HOST" "[ -f /opt/hero_budget/logs/jenkins_deployments.log ]"; then
        add_test_result "Log deployments" "PASS" "Archivo de log existe"
    else
        add_test_result "Log deployments" "FAIL" "Archivo de log no existe"
    fi
}

# Test: Verificar estructura de directorios
test_directory_structure() {
    log_header "📁 TEST: ESTRUCTURA DE DIRECTORIOS"
    
    local directories=(
        "/opt/hero_budget"
        "/opt/hero_budget/backend"
        "/opt/hero_budget/scripts"
        "/opt/hero_budget/backups"
        "/opt/hero_budget/logs"
    )
    
    for dir in "${directories[@]}"; do
        log_test "Verificando directorio: $dir"
        
        if ssh "$VPS_USER@$VPS_HOST" "[ -d $dir ]"; then
            add_test_result "Directorio $dir" "PASS" "Existe"
        else
            add_test_result "Directorio $dir" "FAIL" "No existe"
        fi
    done
}

# Test: Verificar permisos y sudoers
test_permissions() {
    log_header "🔒 TEST: PERMISOS Y SUDOERS"
    
    # Test sudoers Jenkins
    log_test "Verificando sudoers Jenkins..."
    if ssh "$VPS_USER@$VPS_HOST" "[ -f /etc/sudoers.d/jenkins ]"; then
        add_test_result "Sudoers Jenkins" "PASS" "Archivo sudoers existe"
    else
        add_test_result "Sudoers Jenkins" "FAIL" "Archivo sudoers no existe"
    fi
    
    # Test permisos scripts
    log_test "Verificando permisos scripts..."
    if ssh "$VPS_USER@$VPS_HOST" "find /opt/hero_budget/scripts -name '*.sh' -not -executable" | grep -q "."; then
        add_test_result "Permisos scripts" "FAIL" "Algunos scripts no son ejecutables"
    else
        add_test_result "Permisos scripts" "PASS" "Todos los scripts son ejecutables"
    fi
}

# Función para mostrar resumen final
show_test_summary() {
    log_header "📊 RESUMEN DE TESTING"
    
    local test_end_time=$(date +%s)
    local test_duration=$((test_end_time - TEST_START_TIME))
    
    echo ""
    echo "Resultados de los tests:"
    echo ""
    
    for result in "${TEST_RESULTS[@]}"; do
        echo "$result"
    done
    
    echo ""
    echo "=================================================="
    
    local success_count=$((TOTAL_TESTS - FAILED_TESTS))
    local success_percentage=$((success_count * 100 / TOTAL_TESTS))
    
    echo "📊 Estadísticas:"
    echo "   Total tests: $TOTAL_TESTS"
    echo "   Exitosos: $success_count"
    echo "   Fallidos: $FAILED_TESTS"
    echo "   Porcentaje éxito: $success_percentage%"
    echo "   Duración: ${test_duration}s"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "✅ TODOS LOS TESTS PASARON"
        log_success "🎉 Sistema de automatización funcionando correctamente"
        return 0
    elif [ $FAILED_TESTS -lt 3 ]; then
        log_warning "⚠️ ALGUNOS TESTS FALLARON"
        log_warning "🔧 Revisar configuración y reejecutar"
        return 1
    else
        log_error "❌ MÚLTIPLES TESTS FALLARON"
        log_error "🚨 Sistema requiere revisión completa"
        return 2
    fi
}

# Función principal
main() {
    log_header "🧪 TESTING COMPLETO - AUTOMATIZACIÓN JENKINS"
    log_info "Modo: ${TEST_MODE:-Básico}"
    log_info "Skip deploy: ${SKIP_DEPLOY:-No}"
    log_info "Timestamp: $(date)"
    
    # Ejecutar tests
    test_basic_connectivity
    test_directory_structure
    test_scripts_availability
    test_permissions
    test_jenkins_configuration
    test_system_services
    test_service_management
    test_deployment_verification
    test_logging_monitoring
    
    # Tests avanzados solo en modo full
    if [ "$TEST_MODE" = "--full" ]; then
        test_webhook_simulation
    fi
    
    # Mostrar resumen y determinar código de salida
    show_test_summary
}

# Manejo de errores
trap 'log_error "Error en línea $LINENO. Testing interrumpido."; exit 1' ERR

# Ejecutar función principal
main "$@" 