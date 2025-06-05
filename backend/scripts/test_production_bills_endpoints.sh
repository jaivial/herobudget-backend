#!/bin/bash

# =============================================================================
# SCRIPT DE PRUEBAS PARA BILLS MANAGEMENT EN PRODUCCIÓN
# Prueba todos los endpoints de bills management en el VPS
# =============================================================================

# Configuración de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Variables de configuración
DOMAIN="herobudget.jaimedigitalstudio.com"
BASE_URL="https://$DOMAIN"
TEST_USER_ID="test_user_$(date +%s)"

echo -e "${WHITE}"
echo "============================================================================="
echo "   🧪 PRUEBAS DE BILLS MANAGEMENT EN PRODUCCIÓN"
echo "============================================================================="
echo -e "${NC}"

# Función para logging
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Contadores de pruebas
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Función para ejecutar una prueba
run_test() {
    local test_name="$1"
    local curl_cmd="$2"
    local expected_status="$3"
    local description="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_test "$test_name"
    log_info "$description"
    
    # Ejecutar comando curl y capturar respuesta
    response=$(eval $curl_cmd)
    status_code=$(echo "$response" | tail -n1)
    content=$(echo "$response" | sed '$d')
    
    # Verificar código de estado
    if [ "$status_code" = "$expected_status" ]; then
        log_pass "Status: $status_code (esperado: $expected_status)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        
        # Mostrar contenido si es JSON
        if [[ "$content" == *"{"* ]]; then
            echo -e "${CYAN}Response:${NC}"
            echo "$content" | jq . 2>/dev/null || echo "$content"
        fi
    else
        log_fail "Status: $status_code (esperado: $expected_status)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}Response:${NC} $content"
    fi
    
    echo ""
}

# Test 1: Verificar endpoint GET /bills
test_get_bills() {
    run_test "GET /bills" \
        "curl -s -w '\n%{http_code}' '$BASE_URL/bills?user_id=$TEST_USER_ID'" \
        "200" \
        "Obtener lista de facturas para usuario de prueba"
}

# Test 2: Verificar endpoint POST /bills/update con datos válidos
test_update_bill_valid() {
    run_test "POST /bills/update (datos válidos)" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/bills/update' \
        -H 'Content-Type: application/json' \
        -d '{\"user_id\": \"$TEST_USER_ID\", \"bill_id\": 1, \"name\": \"Factura de Prueba\", \"amount\": 150.75}'" \
        "200" \
        "Actualizar factura con datos válidos"
}

# Test 3: Verificar endpoint POST /bills/update sin user_id (error)
test_update_bill_no_user() {
    run_test "POST /bills/update (sin user_id)" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/bills/update' \
        -H 'Content-Type: application/json' \
        -d '{\"bill_id\": 1, \"name\": \"Factura de Prueba\", \"amount\": 150.75}'" \
        "400" \
        "Intentar actualizar sin user_id (debe fallar)"
}

# Test 4: Verificar endpoint POST /bills/update sin bill_id (error)
test_update_bill_no_id() {
    run_test "POST /bills/update (sin bill_id)" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/bills/update' \
        -H 'Content-Type: application/json' \
        -d '{\"user_id\": \"$TEST_USER_ID\", \"name\": \"Factura de Prueba\", \"amount\": 150.75}'" \
        "400" \
        "Intentar actualizar sin bill_id (debe fallar)"
}

# Test 5: Verificar endpoint POST /bills/delete con datos válidos
test_delete_bill_valid() {
    run_test "POST /bills/delete (datos válidos)" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/bills/delete' \
        -H 'Content-Type: application/json' \
        -d '{\"user_id\": \"$TEST_USER_ID\", \"bill_id\": 1}'" \
        "200" \
        "Eliminar factura con datos válidos"
}

# Test 6: Verificar endpoint POST /bills/delete sin user_id (error)
test_delete_bill_no_user() {
    run_test "POST /bills/delete (sin user_id)" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/bills/delete' \
        -H 'Content-Type: application/json' \
        -d '{\"bill_id\": 1}'" \
        "400" \
        "Intentar eliminar sin user_id (debe fallar)"
}

# Test 7: Verificar endpoint POST /bills/delete sin bill_id (error)
test_delete_bill_no_id() {
    run_test "POST /bills/delete (sin bill_id)" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/bills/delete' \
        -H 'Content-Type: application/json' \
        -d '{\"user_id\": \"$TEST_USER_ID\"}'" \
        "400" \
        "Intentar eliminar sin bill_id (debe fallar)"
}

# Test 8: Verificar método no permitido en update
test_update_wrong_method() {
    run_test "GET /bills/update (método incorrecto)" \
        "curl -s -w '\n%{http_code}' '$BASE_URL/bills/update'" \
        "405" \
        "Usar método GET en endpoint POST (debe fallar)"
}

# Test 9: Verificar método no permitido en delete
test_delete_wrong_method() {
    run_test "GET /bills/delete (método incorrecto)" \
        "curl -s -w '\n%{http_code}' '$BASE_URL/bills/delete'" \
        "405" \
        "Usar método GET en endpoint POST (debe fallar)"
}

# Test 10: Verificar JSON malformado
test_malformed_json() {
    run_test "POST /bills/update (JSON malformado)" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/bills/update' \
        -H 'Content-Type: application/json' \
        -d '{\"user_id\": \"$TEST_USER_ID\", \"bill_id\": 1, \"name\": \"Factura malformada\"'" \
        "400" \
        "Enviar JSON malformado (debe fallar)"
}

# Test de conectividad SSL
test_ssl_connectivity() {
    log_test "Verificando conectividad SSL"
    log_info "Comprobando certificado SSL y conectividad HTTPS"
    
    ssl_info=$(curl -s -I "$BASE_URL/bills?user_id=1" | head -1)
    if [[ "$ssl_info" == *"200"* ]]; then
        log_pass "Conectividad SSL correcta: $ssl_info"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_fail "Problema con SSL: $ssl_info"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo ""
}

# Test de rendimiento básico
test_performance() {
    log_test "Test de rendimiento básico"
    log_info "Midiendo tiempo de respuesta para GET /bills"
    
    start_time=$(date +%s)
    response=$(curl -s -w '\n%{http_code}' "$BASE_URL/bills?user_id=$TEST_USER_ID")
    end_time=$(date +%s)
    
    response_time=$((end_time - start_time))
    status_code=$(echo "$response" | tail -n1)
    
    if [ "$status_code" = "200" ] && [ "$response_time" -lt 10 ]; then
        log_pass "Tiempo de respuesta: ${response_time}s (< 10s)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_fail "Tiempo de respuesta: ${response_time}s (demasiado lento o error)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo ""
}

# Ejecutar todas las pruebas
main() {
    log_info "Iniciando pruebas de Bills Management en producción..."
    log_info "Dominio: $DOMAIN"
    log_info "Usuario de prueba: $TEST_USER_ID"
    echo ""
    
    # Verificar que jq esté disponible para formatear JSON
    if ! command -v jq &> /dev/null; then
        log_info "jq no está disponible, las respuestas JSON no se formatearán"
    fi
    
    # Ejecutar pruebas
    test_ssl_connectivity
    test_get_bills
    test_update_bill_valid
    test_update_bill_no_user
    test_update_bill_no_id
    test_delete_bill_valid
    test_delete_bill_no_user
    test_delete_bill_no_id
    test_update_wrong_method
    test_delete_wrong_method
    test_malformed_json
    test_performance
    
    # Mostrar resumen de resultados
    echo -e "${WHITE}"
    echo "============================================================================="
    echo "   📊 RESUMEN DE PRUEBAS"
    echo "============================================================================="
    echo -e "${NC}"
    
    echo -e "${CYAN}Total de pruebas:${NC} $TOTAL_TESTS"
    echo -e "${GREEN}Pruebas exitosas:${NC} $PASSED_TESTS"
    echo -e "${RED}Pruebas fallidas:${NC} $FAILED_TESTS"
    
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${CYAN}Tasa de éxito:${NC} $success_rate%"
    
    echo ""
    
    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "${GREEN}🎉 TODAS LAS PRUEBAS PASARON EXITOSAMENTE${NC}"
        echo -e "${GREEN}✅ Bills Management está funcionando correctamente en producción${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  ALGUNAS PRUEBAS FALLARON${NC}"
        echo -e "${YELLOW}🔍 Revisar logs del VPS para más detalles${NC}"
        exit 1
    fi
}

# Ejecutar función principal
main "$@" 