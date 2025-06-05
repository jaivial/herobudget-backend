#!/bin/bash

# =============================================================================
# SCRIPT DE TESTING COMPLETO CON NUEVOS ENDPOINTS IMPLEMENTADOS
# =============================================================================

# Configuración de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Contadores
total_tests=0
successful_tests=0
failed_tests=0
expected_failures=0

echo -e "${WHITE}"
echo "============================================================================="
echo "   🧪 TESTING COMPLETO CON NUEVOS ENDPOINTS IMPLEMENTADOS"
echo "============================================================================="
echo -e "${NC}"

# Función para obtener primer ID de categoría válido
get_first_category_id() {
    local response=$(curl -s "http://localhost:8096/categories?user_id=36" 2>/dev/null)
    local category_id=$(echo "$response" | grep -o '"id":[^,}]*' | head -1 | cut -d':' -f2 | tr -d ' "')
    
    if [ ! -z "$category_id" ] && [ "$category_id" != "null" ] && [ "$category_id" -gt 0 ] 2>/dev/null; then
        echo "$category_id"
    else
        echo "1"  # Fallback
    fi
}

# Función para hacer una petición HTTP con análisis inteligente
test_endpoint() {
    local method=$1
    local url=$2
    local data=$3
    local description=$4
    local expected_behavior=${5:-"success"}
    
    total_tests=$((total_tests + 1))
    
    echo -e "${CYAN}Probando: ${description}${NC}"
    
    # Hacer la petición
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$url" 2>/dev/null)
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$url" 2>/dev/null)
    fi
    
    # Extraer código de estado
    status_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d':' -f2)
    body=$(echo "$response" | sed 's/HTTPSTATUS:[0-9]*$//')
    
    # Análisis inteligente basado en comportamiento esperado
    case $expected_behavior in
        "success")
            if [ "$status_code" = "200" ] || [ "$status_code" = "201" ]; then
                echo -e "${GREEN}  ✅ SUCCESS: $status_code${NC}"
                successful_tests=$((successful_tests + 1))
            else
                echo -e "${RED}  ❌ FAILED: $status_code${NC}"
                failed_tests=$((failed_tests + 1))
                echo -e "${YELLOW}     Response: $body${NC}"
            fi
            ;;
        "validation_error")
            if [ "$status_code" = "400" ] || [ "$status_code" = "401" ] || [ "$status_code" = "422" ] || [ "$status_code" = "409" ]; then
                echo -e "${YELLOW}  ⚠️  EXPECTED VALIDATION ERROR: $status_code${NC}"
                expected_failures=$((expected_failures + 1))
            else
                echo -e "${RED}  ❌ UNEXPECTED RESPONSE: $status_code${NC}"
                failed_tests=$((failed_tests + 1))
            fi
            ;;
        "not_implemented")
            if [ "$status_code" = "404" ] || [ "$status_code" = "501" ]; then
                echo -e "${YELLOW}  ⚠️  NOT IMPLEMENTED (EXPECTED): $status_code${NC}"
                expected_failures=$((expected_failures + 1))
            else
                echo -e "${GREEN}  🎉 IMPLEMENTED! (WAS 404, NOW $status_code)${NC}"
                successful_tests=$((successful_tests + 1))
            fi
            ;;
    esac
    
    echo ""
}

echo -e "${BLUE}🔍 Obteniendo ID de categoría válido para testing...${NC}"
CATEGORY_ID=$(get_first_category_id)
echo -e "${GREEN}  ✅ Usando category_id: $CATEGORY_ID${NC}\n"

echo -e "${WHITE}=== TESTING ENDPOINTS PRIORITARIOS (NUEVOS) ===${NC}\n"

# 1. CASH/BANK MANAGEMENT (NUEVOS ENDPOINTS)
echo -e "${CYAN}💰 CASH/BANK MANAGEMENT (Puerto 8090) - NUEVOS ENDPOINTS:${NC}"

test_endpoint "POST" "http://localhost:8090/cash-bank/cash/update" \
'{"user_id":"36","amount":150.00,"date":"2025-06-03"}' \
"Cash Update" "success"

test_endpoint "POST" "http://localhost:8090/cash-bank/bank/update" \
'{"user_id":"36","amount":250.00,"date":"2025-06-03"}' \
"Bank Update" "success"

# 2. PROFILE MANAGEMENT (NUEVO ENDPOINT)
echo -e "${CYAN}👤 PROFILE MANAGEMENT (Puerto 8092) - NUEVO ENDPOINT:${NC}"

test_endpoint "POST" "http://localhost:8092/update/locale" \
'{"user_id":"36","locale":"es"}' \
"Locale Update" "success"

# 3. DASHBOARD/USER MANAGEMENT (NUEVO ENDPOINT)
echo -e "${CYAN}📊 DASHBOARD/USER MANAGEMENT (Puerto 8085) - NUEVO ENDPOINT:${NC}"

test_endpoint "POST" "http://localhost:8085/user/update" \
'{"id":"36","name":"Test User Updated","email":"updated@herobudget.test"}' \
"User Update" "success"

# 4. MONEY FLOW ANALYSIS (NUEVO ENDPOINT)
echo -e "${CYAN}💹 MONEY FLOW ANALYSIS (Puerto 8097) - NUEVO ENDPOINT:${NC}"

test_endpoint "GET" "http://localhost:8097/money-flow/data?user_id=36" \
"" \
"Money Flow Data" "success"

# 5. HEALTH CHECKS (NUEVOS ENDPOINTS)
echo -e "${CYAN}🏥 HEALTH CHECKS - NUEVOS ENDPOINTS:${NC}"

test_endpoint "GET" "http://localhost:8089/health" \
"" \
"Savings Health Check" "success"

test_endpoint "GET" "http://localhost:8085/health" \
"" \
"Dashboard Health Check" "success"

echo -e "${WHITE}=== TESTING ENDPOINTS EXISTENTES (VERIFICACIÓN) ===${NC}\n"

# HEALTH CHECK (EXISTENTE)
echo -e "${CYAN}🏥 HEALTH CHECK EXISTENTE:${NC}"

test_endpoint "GET" "http://localhost:8098/health" \
"" \
"Budget Overview Health" "success"

# AUTENTICACIÓN
echo -e "${CYAN}🔐 AUTENTICACIÓN:${NC}"

# Usar timestamp único para evitar conflictos
timestamp=$(date +%s)

test_endpoint "POST" "http://localhost:8084/signin/check-email" \
'{"email":"test@herobudget.test"}' \
"Signin Check Email" "success"

test_endpoint "POST" "http://localhost:8082/signup/check-email" \
'{"email":"newuser'$timestamp'@herobudget.test"}' \
"Signup Check Email" "success"

test_endpoint "POST" "http://localhost:8082/signup" \
'{"email":"testuser'$timestamp'@herobudget.test","password":"password123","name":"Test User"}' \
"User Signup" "success"

test_endpoint "POST" "http://localhost:8082/signup/check-verification" \
'{"email":"test@herobudget.test","verification_code":"123456"}' \
"Check Verification" "validation_error"

test_endpoint "POST" "http://localhost:8084/signin" \
'{"email":"invalid@test.com","password":"wrongpassword"}' \
"User Signin" "validation_error"

# GESTIÓN DE CATEGORÍAS
echo -e "${CYAN}📂 GESTIÓN DE CATEGORÍAS:${NC}"

test_endpoint "GET" "http://localhost:8096/categories?user_id=36" \
"" \
"Categories Fetch" "success"

test_endpoint "POST" "http://localhost:8096/categories/add" \
'{"user_id":"36","name":"Test Category","type":"expense","icon":"test","color":"#FF0000"}' \
"Categories Add" "success"

test_endpoint "POST" "http://localhost:8096/categories/update" \
'{"category_id":'$CATEGORY_ID',"name":"Updated Category","type":"expense","icon":"updated","color":"#00FF00"}' \
"Categories Update" "success"

test_endpoint "DELETE" "http://localhost:8096/categories/delete" \
'{"category_id":'$CATEGORY_ID'}' \
"Categories Delete" "success"

# OPERACIONES FINANCIERAS
echo -e "${CYAN}💰 OPERACIONES FINANCIERAS:${NC}"

test_endpoint "GET" "http://localhost:8089/savings?user_id=36" \
"" \
"Savings Fetch" "success"

test_endpoint "POST" "http://localhost:8089/savings/update" \
'{"user_id":"36","available":500.00,"goal":1000.00}' \
"Savings Update" "success"

test_endpoint "POST" "http://localhost:8093/incomes/add" \
'{"user_id":"36","amount":1000.00,"category_id":1,"date":"2025-06-03","description":"Test Income"}' \
"Income Add" "success"

test_endpoint "GET" "http://localhost:8093/incomes?user_id=36" \
"" \
"Income Fetch" "success"

test_endpoint "POST" "http://localhost:8094/expenses/add" \
'{"user_id":"36","amount":50.00,"category_id":1,"date":"2025-06-03","description":"Test Expense"}' \
"Expense Add" "success"

test_endpoint "GET" "http://localhost:8094/expenses?user_id=36" \
"" \
"Expense Fetch" "success"

test_endpoint "GET" "http://localhost:8091/bills?user_id=36" \
"" \
"Bills Fetch" "success"

test_endpoint "GET" "http://localhost:8090/cash-bank/distribution?user_id=36" \
"" \
"Cash Bank Distribution" "success"

echo -e "${WHITE}"
echo "============================================================================="
echo "   📊 RESUMEN FINAL DE TESTING CON NUEVOS ENDPOINTS"
echo "============================================================================="
echo -e "${NC}"

echo -e "${GREEN}✅ SUCCESSFUL TESTS: $successful_tests${NC}"
echo -e "${YELLOW}⚠️  EXPECTED BEHAVIORS: $expected_failures${NC}"
echo -e "${RED}❌ REAL FAILURES: $failed_tests${NC}"
echo -e "${WHITE}📊 TOTAL TESTS: $total_tests${NC}"

# Calcular score de salud
working_endpoints=$((successful_tests))
total_functional_tests=$((total_tests - expected_failures))
health_score=$((working_endpoints * 100 / total_tests))

echo -e "\n${WHITE}🏥 HEALTH SCORE: $health_score% ($working_endpoints/$total_tests endpoints working)${NC}"

if [ $failed_tests -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ¡SISTEMA COMPLETAMENTE OPERACIONAL!${NC}"
    echo -e "${GREEN}   - Todos los endpoints críticos funcionando${NC}"
    echo -e "${GREEN}   - Nuevos endpoints implementados exitosamente${NC}"
    echo -e "${GREEN}   - 0 fallos reales detectados${NC}"
    
    echo -e "\n${CYAN}📋 NUEVOS ENDPOINTS QUE AHORA FUNCIONAN:${NC}"
    echo -e "${WHITE}  • /cash-bank/cash/update (Era 404, ahora funciona)${NC}"
    echo -e "${WHITE}  • /cash-bank/bank/update (Era 404, ahora funciona)${NC}"
    echo -e "${WHITE}  • /update/locale (Era 404, ahora funciona)${NC}"
    echo -e "${WHITE}  • /user/update (Era 404, ahora funciona)${NC}"
    echo -e "${WHITE}  • /money-flow/data (Era 404, ahora funciona)${NC}"
    echo -e "${WHITE}  • /health en Savings (Era 404, ahora funciona)${NC}"
    echo -e "${WHITE}  • /health en Dashboard (Era 404, ahora funciona)${NC}"
    
    exit 0
else
    echo -e "\n${YELLOW}⚠️  ALGUNOS ENDPOINTS NECESITAN ATENCIÓN${NC}"
    echo -e "${WHITE}   - $failed_tests endpoint(s) con fallos reales${NC}"
    echo -e "${WHITE}   - Revisar implementación y configuración${NC}"
    exit 1
fi 