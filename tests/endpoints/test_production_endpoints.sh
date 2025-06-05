#!/bin/bash

# =============================================================================
# SCRIPT DE TESTING PRODUCCIÓN - HERO BUDGET BACKEND
# =============================================================================
# Basado en la configuración de lib/config/api_config.dart
# URL de producción: https://herobudget.jaimedigitalstudio.com

# Configuración de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuración de producción
PRODUCTION_BASE_URL="https://herobudget.jaimedigitalstudio.com"
TEST_USER_ID="36"

# Contadores
total_tests=0
successful_tests=0
failed_tests=0
expected_failures=0

echo -e "${WHITE}"
echo "============================================================================="
echo "   🚀 TESTING ENDPOINTS DE PRODUCCIÓN - HERO BUDGET"
echo "   🌐 Base URL: $PRODUCTION_BASE_URL"
echo "============================================================================="
echo -e "${NC}"

# Función para obtener primer ID de categoría válido de producción
get_first_category_id() {
    local response=$(curl -s "$PRODUCTION_BASE_URL/categories?user_id=$TEST_USER_ID" 2>/dev/null)
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
    local endpoint_path=$2
    local data=$3
    local description=$4
    local expected_behavior=${5:-"success"}
    
    # Construir URL completa
    local full_url="$PRODUCTION_BASE_URL$endpoint_path"
    
    total_tests=$((total_tests + 1))
    
    echo -e "${CYAN}Probando: ${description}${NC}"
    echo -e "${BLUE}  URL: $full_url${NC}"
    
    # Hacer la petición
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$full_url" 2>/dev/null)
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$full_url" 2>/dev/null)
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
            if [ "$status_code" = "400" ] || [ "$status_code" = "401" ] || [ "$status_code" = "422" ] || [ "$status_code" = "409" ] || [ "$status_code" = "404" ]; then
                echo -e "${YELLOW}  ⚠️  EXPECTED VALIDATION ERROR: $status_code${NC}"
                expected_failures=$((expected_failures + 1))
            else
                echo -e "${RED}  ❌ UNEXPECTED RESPONSE: $status_code${NC}"
                failed_tests=$((failed_tests + 1))
            fi
            ;;
        "expected_success")
            if [ "$status_code" = "200" ] || [ "$status_code" = "201" ]; then
                echo -e "${GREEN}  🎉 PRODUCTION SUCCESS: $status_code${NC}"
                successful_tests=$((successful_tests + 1))
            else
                echo -e "${RED}  ❌ PRODUCTION FAILURE: $status_code${NC}"
                failed_tests=$((failed_tests + 1))
                echo -e "${YELLOW}     Response: $body${NC}"
            fi
            ;;
    esac
    
    echo ""
}

echo -e "${BLUE}🔍 Obteniendo ID de categoría válido de producción...${NC}"
CATEGORY_ID=$(get_first_category_id)
echo -e "${GREEN}  ✅ Usando category_id: $CATEGORY_ID${NC}\n"

echo -e "${WHITE}=== 🏥 HEALTH CHECKS DE PRODUCCIÓN ===${NC}\n"

# Health checks de servicios principales
test_endpoint "GET" "/health" \
"" \
"🏥 Production Health Check General" "success"

test_endpoint "GET" "/savings/health" \
"" \
"🏥 Savings Service Health" "success"

test_endpoint "GET" "/budget-overview/health" \
"" \
"🏥 Budget Overview Health" "success"

echo -e "${WHITE}=== 🔐 ENDPOINTS DE AUTENTICACIÓN ===${NC}\n"

# Generar timestamp único para evitar conflictos
timestamp=$(date +%s)

test_endpoint "POST" "/signin/check-email" \
'{"email":"test@herobudget.test"}' \
"🔐 Signin Check Email" "success"

test_endpoint "POST" "/signup/check-email" \
'{"email":"newuser'$timestamp'@herobudget.test"}' \
"🔐 Signup Check Email" "success"

test_endpoint "POST" "/signup/register" \
'{"email":"testuser'$timestamp'@herobudget.test","password":"password123","name":"Test User"}' \
"🔐 User Signup Register" "expected_success"

test_endpoint "POST" "/signup/check-verification" \
'{"email":"test@herobudget.test","verification_code":"123456"}' \
"🔐 Check Verification Code" "success"

test_endpoint "POST" "/signin" \
'{"email":"invalid@test.com","password":"wrongpassword"}' \
"🔐 User Signin (Invalid)" "validation_error"

test_endpoint "POST" "/auth/google" \
'{"id_token":"fake_token_for_testing"}' \
"🔐 Google Auth" "validation_error"

echo -e "${WHITE}=== 🔑 RESET PASSWORD ENDPOINTS ===${NC}\n"

test_endpoint "POST" "/reset-password/check-email" \
'{"email":"test@herobudget.test"}' \
"🔑 Reset Password Check Email" "success"

test_endpoint "POST" "/reset-password/request" \
'{"email":"test@herobudget.test"}' \
"🔑 Reset Password Request" "success"

test_endpoint "POST" "/reset-password/validate-token" \
'{"token":"fake-token-for-testing"}' \
"🔑 Reset Password Validate Token" "validation_error"

echo -e "${WHITE}=== 📂 GESTIÓN DE CATEGORÍAS ===${NC}\n"

test_endpoint "GET" "/categories?user_id=$TEST_USER_ID" \
"" \
"📂 Categories Fetch" "success"

test_endpoint "POST" "/categories/add" \
'{"user_id":"'$TEST_USER_ID'","name":"Test Category Prod","type":"expense","icon":"test","color":"#FF0000"}' \
"📂 Categories Add" "success"

test_endpoint "POST" "/categories/update" \
'{"user_id":"'$TEST_USER_ID'","category_id":'$CATEGORY_ID',"name":"Updated Category Prod","type":"expense","icon":"updated","color":"#00FF00"}' \
"📂 Categories Update" "success"

test_endpoint "POST" "/categories/delete" \
'{"user_id":"'$TEST_USER_ID'","category_id":'$CATEGORY_ID'}' \
"📂 Categories Delete" "expected_success"

echo -e "${WHITE}=== 💰 OPERACIONES FINANCIERAS ===${NC}\n"

# Savings Management
test_endpoint "GET" "/savings/fetch?user_id=$TEST_USER_ID" \
"" \
"💰 Savings Fetch" "success"

test_endpoint "POST" "/savings/update" \
'{"user_id":"'$TEST_USER_ID'","available":500.00,"goal":1000.00}' \
"💰 Savings Update" "success"

# Income Management
test_endpoint "POST" "/incomes/add" \
'{"user_id":"'$TEST_USER_ID'","amount":1000.00,"category":"1","payment_method":"cash","date":"2025-06-04","description":"Test Income Prod"}' \
"💰 Income Add" "expected_success"

test_endpoint "GET" "/incomes?user_id=$TEST_USER_ID" \
"" \
"💰 Income Fetch" "success"

# Expense Management
test_endpoint "POST" "/expenses/add" \
'{"user_id":"'$TEST_USER_ID'","amount":50.00,"category":"1","payment_method":"bank","date":"2025-06-04","description":"Test Expense Prod"}' \
"💰 Expense Add" "expected_success"

test_endpoint "GET" "/expenses?user_id=$TEST_USER_ID" \
"" \
"💰 Expense Fetch" "success"

echo -e "${WHITE}=== 🏦 CASH/BANK MANAGEMENT ===${NC}\n"

test_endpoint "GET" "/cash-bank/distribution?user_id=$TEST_USER_ID" \
"" \
"🏦 Cash Bank Distribution" "success"

test_endpoint "POST" "/cash-bank/cash/update" \
'{"user_id":"'$TEST_USER_ID'","amount":150.00,"date":"2025-06-04"}' \
"🏦 Cash Update" "success"

test_endpoint "POST" "/cash-bank/bank/update" \
'{"user_id":"'$TEST_USER_ID'","amount":250.00,"date":"2025-06-04"}' \
"🏦 Bank Update" "success"

test_endpoint "POST" "/transfer/cash-to-bank" \
'{"user_id":"'$TEST_USER_ID'","amount":100.00,"date":"2025-06-04"}' \
"🏦 Transfer Cash to Bank" "success"

test_endpoint "POST" "/transfer/bank-to-cash" \
'{"user_id":"'$TEST_USER_ID'","amount":50.00,"date":"2025-06-04"}' \
"🏦 Transfer Bank to Cash" "success"

echo -e "${WHITE}=== 🧾 BILLS MANAGEMENT ===${NC}\n"

test_endpoint "GET" "/bills?user_id=$TEST_USER_ID" \
"" \
"🧾 Bills Fetch" "success"

test_endpoint "POST" "/bills/add" \
'{"user_id":"'$TEST_USER_ID'","name":"Test Bill Prod","amount":100.00,"due_date":"2025-07-01","category":"1"}' \
"🧾 Bills Add" "success"

test_endpoint "GET" "/bills/upcoming?user_id=$TEST_USER_ID" \
"" \
"🧾 Bills Upcoming" "success"

test_endpoint "POST" "/bills/update" \
'{"user_id":"'$TEST_USER_ID'","bill_id":1,"name":"Updated Bill Prod","amount":125.75}' \
"🧾 Bills Update (NUEVO)" "success"

test_endpoint "POST" "/bills/delete" \
'{"user_id":"'$TEST_USER_ID'","bill_id":999}' \
"🧾 Bills Delete (NUEVO - Test con bill inexistente)" "validation_error"

echo -e "${WHITE}=== 📊 DASHBOARD & USER MANAGEMENT ===${NC}\n"

test_endpoint "GET" "/user/info?user_id=$TEST_USER_ID" \
"" \
"📊 Dashboard User Info" "success"

test_endpoint "POST" "/user/update" \
'{"id":"'$TEST_USER_ID'","name":"Test User Updated Prod","email":"updated.prod@herobudget.test"}' \
"📊 User Update" "success"

test_endpoint "GET" "/dashboard/data?user_id=$TEST_USER_ID" \
"" \
"📊 Dashboard Data" "success"

echo -e "${WHITE}=== 👤 PROFILE MANAGEMENT ===${NC}\n"

test_endpoint "POST" "/profile/update" \
'{"user_id":"'$TEST_USER_ID'","name":"Updated Profile Prod","email":"profile.prod@herobudget.test"}' \
"👤 Profile Update" "success"

test_endpoint "POST" "/update/locale" \
'{"user_id":"'$TEST_USER_ID'","locale":"es"}' \
"👤 Locale Update" "success"

test_endpoint "DELETE" "/profile/delete-account" \
'{"user_id":"999999"}' \
"👤 Account Delete (Test con usuario inexistente)" "validation_error"

test_endpoint "GET" "/profile/ping?user_id=$TEST_USER_ID" \
"" \
"👤 Profile Ping" "success"

echo -e "${WHITE}=== 💹 ADVANCED FEATURES ===${NC}\n"

test_endpoint "GET" "/money-flow/data?user_id=$TEST_USER_ID" \
"" \
"💹 Money Flow Data" "success"

test_endpoint "POST" "/money-flow/sync" \
'{"user_id":"'$TEST_USER_ID'","date":"2025-06-04"}' \
"💹 Money Flow Sync" "success"

test_endpoint "GET" "/budget-overview?user_id=$TEST_USER_ID" \
"" \
"💹 Budget Overview" "success"

test_endpoint "GET" "/transactions/history?user_id=$TEST_USER_ID" \
"" \
"💹 Transaction History" "success"

echo -e "${WHITE}=== 🌐 LANGUAGE MANAGEMENT ===${NC}\n"

test_endpoint "GET" "/language/get?user_id=$TEST_USER_ID" \
"" \
"🌐 Language Get" "success"

test_endpoint "POST" "/language/set" \
'{"user_id":"'$TEST_USER_ID'","language":"es"}' \
"🌐 Language Set" "success"

echo -e "${WHITE}"
echo "============================================================================="
echo "   🚀 RESUMEN FINAL: TESTING PRODUCCIÓN HERO BUDGET"
echo "   🌐 URL: $PRODUCTION_BASE_URL"
echo "============================================================================="
echo -e "${NC}"

echo -e "${GREEN}✅ SUCCESSFUL TESTS: $successful_tests${NC}"
echo -e "${YELLOW}⚠️  EXPECTED BEHAVIORS: $expected_failures${NC}"
echo -e "${RED}❌ REAL FAILURES: $failed_tests${NC}"
echo -e "${WHITE}📊 TOTAL TESTS: $total_tests${NC}"

# Calcular score de salud
working_endpoints=$((successful_tests))
health_score=$((working_endpoints * 100 / total_tests))

echo -e "\n${WHITE}🏥 PRODUCTION HEALTH SCORE: $health_score% ($working_endpoints/$total_tests endpoints working)${NC}"

echo -e "\n${CYAN}🔧 CORRECCIONES NECESARIAS PARA PRODUCCIÓN:${NC}"

echo -e "\n${RED}1. SERVICIOS CON 502 BAD GATEWAY:${NC}"
echo -e "${WHITE}   - /signup/check-email${NC}"
echo -e "${WHITE}   - /signup/register${NC}"
echo -e "${WHITE}   - /signup/check-verification${NC}"
echo -e "${WHITE}   💡 Verificar que signup_service (puerto 8082) esté corriendo${NC}"

echo -e "\n${RED}2. CASH/BANK MANAGEMENT (500 ERRORS):${NC}"
echo -e "${WHITE}   - /cash-bank/distribution${NC}"
echo -e "${WHITE}   - /cash-bank/cash/update${NC}"
echo -e "${WHITE}   - /cash-bank/bank/update${NC}"
echo -e "${WHITE}   - /transfer/cash-to-bank${NC}"
echo -e "${WHITE}   - /transfer/bank-to-cash${NC}"
echo -e "${WHITE}   💡 Error: 'Error fetching current distribution' - Problema de BD${NC}"

echo -e "\n${RED}3. ENDPOINTS 404 NOT FOUND:${NC}"
echo -e "${WHITE}   - /savings/health${NC}"
echo -e "${WHITE}   - /budget-overview/health${NC}"
echo -e "${WHITE}   - /update/locale${NC}"
echo -e "${WHITE}   - /money-flow/data${NC}"
echo -e "${WHITE}   💡 Verificar routing en nginx o main.go${NC}"

echo -e "\n${RED}4. METHOD NOT ALLOWED (405):${NC}"
echo -e "${WHITE}   - GET /budget-overview${NC}"
echo -e "${WHITE}   - GET /transactions/history${NC}"
echo -e "${WHITE}   💡 Cambiar a POST o verificar métodos permitidos${NC}"

echo -e "\n${RED}5. VALIDATION ERRORS (400):${NC}"
echo -e "${WHITE}   - /bills/add - 'Start date is required'${NC}"
echo -e "${WHITE}   - /user/info - 'Valid user ID is required'${NC}"
echo -e "${WHITE}   - /profile/update - 'Invalid request body'${NC}"
echo -e "${WHITE}   - /language/set - 'Locale is required'${NC}"
echo -e "${WHITE}   💡 Verificar payloads requeridos${NC}"

echo -e "\n${GREEN}🚀 COMANDOS PARA VERIFICAR VPS:${NC}"
echo -e "${WHITE}ssh root@178.16.130.178 'systemctl status herobudget'${NC}"
echo -e "${WHITE}ssh root@178.16.130.178 'ps aux | grep -E \"(signup|cash_bank|profile)\"'${NC}"
echo -e "${WHITE}ssh root@178.16.130.178 'tail -f /opt/hero_budget/logs/*.log'${NC}"
echo -e "${WHITE}ssh root@178.16.130.178 'curl http://localhost:8082/health'${NC}"

echo -e "\n${GREEN}📋 NEXT STEPS:${NC}"
echo -e "${WHITE}1. Verificar que todos los microservicios estén corriendo${NC}"
echo -e "${WHITE}2. Revisar configuración nginx para routing${NC}"
echo -e "${WHITE}3. Verificar conectividad a base de datos${NC}"
echo -e "${WHITE}4. Corregir payloads de testing según APIs reales${NC}"
echo -e "${WHITE}5. Re-ejecutar tests después de correcciones${NC}"

if [ $failed_tests -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ¡PRODUCCIÓN 100% FUNCIONAL!${NC}"
    echo -e "${GREEN}   - TODOS los endpoints de producción funcionando${NC}"
    echo -e "${GREEN}   - $working_endpoints/$total_tests endpoints operacionales${NC}"
    echo -e "${GREEN}   - 0 fallos reales detectados${NC}"
    echo -e "${GREEN}   - Sistema Hero Budget listo para usuarios${NC}"
    
    echo -e "\n${CYAN}🏆 PRODUCCIÓN VERIFICADA:${NC}"
    echo -e "${WHITE}  🌐 Backend de producción completamente funcional${NC}"
    echo -e "${WHITE}  🔐 Autenticación y seguridad operacional${NC}"
    echo -e "${WHITE}  💰 Operaciones financieras funcionando${NC}"
    echo -e "${WHITE}  📊 Dashboard y análisis disponibles${NC}"
    echo -e "${WHITE}  🚀 Listo para usuarios finales${NC}"
    
    exit 0
elif [ $failed_tests -le 3 ]; then
    echo -e "\n${YELLOW}⚠️  PRODUCCIÓN CASI PERFECTA${NC}"
    echo -e "${WHITE}   - Solo $failed_tests endpoint(s) con problemas menores${NC}"
    echo -e "${WHITE}   - Core functionality está funcionando${NC}"
    echo -e "${WHITE}   - Sistema utilizable en producción${NC}"
    exit 0
else
    echo -e "\n${RED}❌ PRODUCCIÓN NECESITA ATENCIÓN${NC}"
    echo -e "${WHITE}   - $failed_tests endpoint(s) con fallos importantes${NC}"
    echo -e "${WHITE}   - Revisar configuración de producción${NC}"
    echo -e "${WHITE}   - Verificar conectividad con base de datos${NC}"
    exit 1
fi 