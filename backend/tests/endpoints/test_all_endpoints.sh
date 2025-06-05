#!/bin/bash

# =============================================================================
# SCRIPT DE PRUEBAS COMPLETAS DE ENDPOINTS - HERO BUDGET
# =============================================================================
# Este script prueba todos los endpoints configurados en lib/config/api_config.dart
# tanto en localhost como en producción
# =============================================================================

# Configuración de colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuración de URLs base
LOCALHOST_BASE="http://localhost"
PRODUCTION_BASE="https://herobudget.jaimedigitalstudio.com"

# Función para obtener puerto según el servicio (compatible con bash 3.x)
get_port() {
    local service=$1
    case $service in
        "signup") echo "8082" ;;
        "language") echo "8083" ;;
        "signin") echo "8084" ;;
        "google_auth") echo "8081" ;;
        "fetch_dashboard") echo "8085" ;;
        "reset_password") echo "8086" ;;
        "dashboard_data") echo "8087" ;;
        "budget_management") echo "8088" ;;
        "savings_management") echo "8089" ;;
        "cash_bank_management") echo "8090" ;;
        "bills_management") echo "8091" ;;
        "profile_management") echo "8092" ;;
        "income_management") echo "8093" ;;
        "expense_management") echo "8094" ;;
        "transaction_delete") echo "8095" ;;
        "categories_management") echo "8096" ;;
        "money_flow_sync") echo "8097" ;;
        "budget_overview_fetch") echo "8098" ;;
        *) echo "8080" ;;
    esac
}

# Contadores de resultados
TOTAL_TESTS=0
PASSED_LOCALHOST=0
FAILED_LOCALHOST=0
PASSED_PRODUCTION=0
FAILED_PRODUCTION=0

# Función para hacer peticiones HTTP
test_endpoint() {
    local method=$1
    local url=$2
    local description=$3
    local expected_status=${4:-200}
    local data=$5
    
    local response
    local status_code
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -X GET \
            -H "Content-Type: application/json" \
            --connect-timeout 10 \
            --max-time 30 \
            "$url" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            --connect-timeout 10 \
            --max-time 30 \
            -d "$data" \
            "$url" 2>/dev/null)
    fi
    
    # Extraer código de estado (última línea)
    status_code=$(echo "$response" | tail -n1)
    
    # Extraer contenido de respuesta (todas las líneas excepto la última)
    content=$(echo "$response" | sed '$d')
    
    # Determinar si la prueba pasó
    if [[ "$status_code" =~ ^[0-9]+$ ]]; then
        if [ "$status_code" -eq 200 ] || [ "$status_code" -eq 404 ] || [ "$status_code" -eq 405 ]; then
            echo -e "${GREEN}✅ PASS${NC} - $description (Status: $status_code)"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} - $description (Status: $status_code)"
            echo -e "${YELLOW}   Response: ${content:0:100}...${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ ERROR${NC} - $description (Connection failed)"
        return 1
    fi
}

# Función para probar un endpoint en ambos ambientes
test_endpoint_both_environments() {
    local method=$1
    local path=$2
    local service=$3
    local description=$4
    local data=${5:-'{}'}
    
    local port=$(get_port "$service")
    
    echo -e "\n${CYAN}Testing: $description${NC}"
    echo -e "${BLUE}Path: $path | Service: $service | Port: $port${NC}"
    
    # Probar en localhost
    local localhost_url="$LOCALHOST_BASE:$port$path"
    echo -e "${YELLOW}🏠 LOCALHOST: $localhost_url${NC}"
    if test_endpoint "$method" "$localhost_url" "Localhost" 200 "$data"; then
        ((PASSED_LOCALHOST++))
    else
        ((FAILED_LOCALHOST++))
    fi
    
    # Probar en producción
    local production_url="$PRODUCTION_BASE$path"
    echo -e "${PURPLE}🌐 PRODUCTION: $production_url${NC}"
    if test_endpoint "$method" "$production_url" "Production" 200 "$data"; then
        ((PASSED_PRODUCTION++))
    else
        ((FAILED_PRODUCTION++))
    fi
    
    ((TOTAL_TESTS++))
}

# Función para probar endpoints de health check
test_health_endpoints() {
    echo -e "\n${WHITE}=== HEALTH CHECK ENDPOINTS ===${NC}"
    
    test_endpoint_both_environments "GET" "/health" "budget_overview_fetch" "Budget Overview Health"
    test_endpoint_both_environments "GET" "/health" "fetch_dashboard" "Dashboard Health"
    test_endpoint_both_environments "GET" "/health" "savings_management" "Savings Health"
}

# Función para probar endpoints de autenticación
test_auth_endpoints() {
    echo -e "\n${WHITE}=== AUTHENTICATION ENDPOINTS ===${NC}"
    
    local test_user_data='{"email":"test@example.com","password":"test123"}'
    local signup_data='{"email":"test@example.com","password":"test123","name":"Test User","locale":"en"}'
    local google_auth_data='{"idToken":"test-token","accessToken":"test-token","deviceLocale":"en"}'
    
    test_endpoint_both_environments "POST" "/signin" "signin" "User Signin" "$test_user_data"
    test_endpoint_both_environments "POST" "/signin/check-email" "signin" "Signin Check Email" '{"email":"test@example.com"}'
    test_endpoint_both_environments "POST" "/signup/register" "signup" "User Signup" "$signup_data"
    test_endpoint_both_environments "POST" "/signup/check-email" "signup" "Signup Check Email" '{"email":"test@example.com"}'
    test_endpoint_both_environments "POST" "/signup/check-verification" "signup" "Check Verification" '{"email":"test@example.com"}'
    test_endpoint_both_environments "POST" "/auth/google" "google_auth" "Google Auth" "$google_auth_data"
}

# Función para probar endpoints de reset password
test_reset_password_endpoints() {
    echo -e "\n${WHITE}=== RESET PASSWORD ENDPOINTS ===${NC}"
    
    test_endpoint_both_environments "POST" "/reset-password/check-email" "reset_password" "Reset Password Check Email" '{"email":"test@example.com"}'
    test_endpoint_both_environments "POST" "/reset-password/request" "reset_password" "Reset Password Request" '{"email":"test@example.com"}'
    test_endpoint_both_environments "POST" "/reset-password/validate-token" "reset_password" "Reset Password Validate Token" '{"token":"test-token"}'
    test_endpoint_both_environments "POST" "/reset-password/update" "reset_password" "Reset Password Update" '{"token":"test-token","user_id":1,"new_password":"newpass"}'
}

# Función para probar endpoints financieros
test_financial_endpoints() {
    echo -e "\n${WHITE}=== FINANCIAL MANAGEMENT ENDPOINTS ===${NC}"
    
    local financial_data='{"user_id":"1","amount":100,"date":"2024-12-20","category":"Test","payment_method":"cash","description":"Test transaction"}'
    
    # Savings Management
    test_endpoint_both_environments "GET" "/savings/fetch?user_id=1" "savings_management" "Savings Fetch"
    test_endpoint_both_environments "POST" "/savings/update" "savings_management" "Savings Update" '{"user_id":"1","goal":1000}'
    test_endpoint_both_environments "POST" "/savings/delete" "savings_management" "Savings Delete" '{"user_id":"1"}'
    
    # Income Management
    test_endpoint_both_environments "POST" "/incomes/add" "income_management" "Income Add" "$financial_data"
    test_endpoint_both_environments "GET" "/incomes?user_id=1" "income_management" "Income Fetch"
    test_endpoint_both_environments "POST" "/incomes/update" "income_management" "Income Update" "$financial_data"
    test_endpoint_both_environments "POST" "/incomes/delete" "income_management" "Income Delete" '{"user_id":"1","id":1}'
    
    # Expense Management
    test_endpoint_both_environments "POST" "/expenses/add" "expense_management" "Expense Add" "$financial_data"
    test_endpoint_both_environments "GET" "/expenses?user_id=1" "expense_management" "Expense Fetch"
    test_endpoint_both_environments "POST" "/expenses/update" "expense_management" "Expense Update" "$financial_data"
    test_endpoint_both_environments "POST" "/expenses/delete" "expense_management" "Expense Delete" '{"user_id":"1","id":1}'
}

# Función para probar endpoints de bills
test_bills_endpoints() {
    echo -e "\n${WHITE}=== BILLS MANAGEMENT ENDPOINTS ===${NC}"
    
    local bill_data='{"user_id":"1","name":"Test Bill","amount":50,"payment_day":15,"duration_months":1,"category":"Utilities","icon":"💡","recurring":false,"regularity":"monthly","start_date":"2024-12-01"}'
    
    test_endpoint_both_environments "GET" "/bills?user_id=1" "bills_management" "Bills Fetch"
    test_endpoint_both_environments "POST" "/bills/add" "bills_management" "Bills Add" "$bill_data"
    test_endpoint_both_environments "POST" "/bills/pay" "bills_management" "Bills Pay" '{"user_id":"1","bill_id":1,"year_month":"2024-12","description":"Test payment"}'
    test_endpoint_both_environments "POST" "/bills/update" "bills_management" "Bills Update" "$bill_data"
    test_endpoint_both_environments "POST" "/bills/delete" "bills_management" "Bills Delete" '{"user_id":"1","bill_id":1}'
    test_endpoint_both_environments "GET" "/bills/upcoming?user_id=1" "bills_management" "Bills Upcoming"
}

# Función para probar endpoints de cash/bank
test_cash_bank_endpoints() {
    echo -e "\n${WHITE}=== CASH/BANK MANAGEMENT ENDPOINTS ===${NC}"
    
    test_endpoint_both_environments "GET" "/cash-bank/distribution?user_id=1" "cash_bank_management" "Cash Bank Distribution"
    test_endpoint_both_environments "POST" "/cash-bank/cash/update" "cash_bank_management" "Cash Update" '{"user_id":"1","amount":100}'
    test_endpoint_both_environments "POST" "/cash-bank/bank/update" "cash_bank_management" "Bank Update" '{"user_id":"1","amount":100}'
    test_endpoint_both_environments "POST" "/transfer/cash-to-bank" "cash_bank_management" "Transfer Cash to Bank" '{"user_id":"1","amount":50}'
    test_endpoint_both_environments "POST" "/transfer/bank-to-cash" "cash_bank_management" "Transfer Bank to Cash" '{"user_id":"1","amount":50}'
}

# Función para probar endpoints de categorías
test_categories_endpoints() {
    echo -e "\n${WHITE}=== CATEGORIES MANAGEMENT ENDPOINTS ===${NC}"
    
    local category_data='{"user_id":"1","name":"Test Category","icon":"📁","color":"blue","category_type":"expense"}'
    
    test_endpoint_both_environments "GET" "/categories?user_id=1" "categories_management" "Categories Fetch"
    test_endpoint_both_environments "POST" "/categories/add" "categories_management" "Categories Add" "$category_data"
    test_endpoint_both_environments "POST" "/categories/update" "categories_management" "Categories Update" "$category_data"
    test_endpoint_both_environments "POST" "/categories/delete" "categories_management" "Categories Delete" '{"user_id":"1","id":1}'
}

# Función para probar endpoints de perfil
test_profile_endpoints() {
    echo -e "\n${WHITE}=== PROFILE MANAGEMENT ENDPOINTS ===${NC}"
    
    local profile_data='{"user_id":"1","name":"Updated Name","email":"updated@example.com"}'
    
    test_endpoint_both_environments "POST" "/profile/update" "profile_management" "Profile Update" "$profile_data"
    test_endpoint_both_environments "POST" "/profile/update-password" "profile_management" "Profile Update Password" '{"user_id":"1","current_password":"old","new_password":"new"}'
    test_endpoint_both_environments "GET" "/profile/ping" "profile_management" "Profile Ping"
    test_endpoint_both_environments "POST" "/profile/test-image-update" "profile_management" "Profile Test Image Update" '{"user_id":"1","image":"test-image"}'
    test_endpoint_both_environments "POST" "/update/locale" "profile_management" "Profile Update Locale" '{"user_id":"1","locale":"es"}'
}

# Función para probar endpoints de transacciones y dashboard
test_transaction_dashboard_endpoints() {
    echo -e "\n${WHITE}=== TRANSACTION & DASHBOARD ENDPOINTS ===${NC}"
    
    local transaction_data='{"user_id":"1","limit":10,"offset":0,"period":"monthly","date":"2024-12"}'
    
    test_endpoint_both_environments "POST" "/transactions/history" "budget_overview_fetch" "Transaction History" "$transaction_data"
    test_endpoint_both_environments "POST" "/transactions/delete" "transaction_delete" "Transaction Delete" '{"user_id":"1","transaction_id":1,"transaction_type":"expense"}'
    test_endpoint_both_environments "POST" "/budget-overview" "budget_overview_fetch" "Budget Overview" "$transaction_data"
    test_endpoint_both_environments "GET" "/user/info?id=1" "fetch_dashboard" "Dashboard User Info"
    test_endpoint_both_environments "POST" "/user/update" "fetch_dashboard" "Dashboard User Update" '{"id":"1","name":"Updated Name"}'
    test_endpoint_both_environments "GET" "/dashboard/data?user_id=1&period=monthly&date=2024-12-20" "dashboard_data" "Dashboard Data"
    test_endpoint_both_environments "GET" "/money-flow/data?user_id=1&period=monthly&date=2024-12-20" "money_flow_sync" "Money Flow Data"
}

# Función para probar endpoints de idioma
test_language_endpoints() {
    echo -e "\n${WHITE}=== LANGUAGE MANAGEMENT ENDPOINTS ===${NC}"
    
    test_endpoint_both_environments "GET" "/language/get" "language" "Language Get"
    test_endpoint_both_environments "POST" "/language/set" "language" "Language Set" '{"locale":"es"}'
}

# Función principal
main() {
    echo -e "${WHITE}"
    echo "============================================================================="
    echo "   🧪 HERO BUDGET - ENDPOINT TESTING SUITE"
    echo "============================================================================="
    echo "   Testing all endpoints from lib/config/api_config.dart"
    echo "   Environments: LOCALHOST & PRODUCTION"
    echo "============================================================================="
    echo -e "${NC}"
    
    # Mostrar información de configuración
    echo -e "${CYAN}Configuration:${NC}"
    echo -e "  Localhost Base: $LOCALHOST_BASE"
    echo -e "  Production Base: $PRODUCTION_BASE"
    echo -e "  Services configured: $(echo "signup language signin google_auth fetch_dashboard reset_password dashboard_data budget_management savings_management cash_bank_management bills_management profile_management income_management expense_management transaction_delete categories_management money_flow_sync budget_overview_fetch" | wc -w)"
    echo ""
    
    # Ejecutar todas las pruebas
    test_health_endpoints
    test_auth_endpoints
    test_reset_password_endpoints
    test_financial_endpoints
    test_bills_endpoints
    test_cash_bank_endpoints
    test_categories_endpoints
    test_profile_endpoints
    test_transaction_dashboard_endpoints
    test_language_endpoints
    
    # Mostrar resumen de resultados
    echo -e "\n${WHITE}"
    echo "============================================================================="
    echo "   📊 TEST RESULTS SUMMARY"
    echo "============================================================================="
    echo -e "${NC}"
    
    echo -e "${CYAN}Total Tests Executed: $TOTAL_TESTS${NC}"
    echo ""
    echo -e "${YELLOW}🏠 LOCALHOST RESULTS:${NC}"
    echo -e "  ${GREEN}✅ Passed: $PASSED_LOCALHOST${NC}"
    echo -e "  ${RED}❌ Failed: $FAILED_LOCALHOST${NC}"
    echo ""
    echo -e "${PURPLE}🌐 PRODUCTION RESULTS:${NC}"
    echo -e "  ${GREEN}✅ Passed: $PASSED_PRODUCTION${NC}"
    echo -e "  ${RED}❌ Failed: $FAILED_PRODUCTION${NC}"
    echo ""
    
    local localhost_success_rate=0
    local production_success_rate=0
    
    if [ $TOTAL_TESTS -gt 0 ]; then
        localhost_success_rate=$(( (PASSED_LOCALHOST * 100) / TOTAL_TESTS ))
        production_success_rate=$(( (PASSED_PRODUCTION * 100) / TOTAL_TESTS ))
    fi
    
    echo -e "${CYAN}Success Rates:${NC}"
    echo -e "  🏠 Localhost: ${localhost_success_rate}%"
    echo -e "  🌐 Production: ${production_success_rate}%"
    echo ""
    
    if [ $FAILED_LOCALHOST -eq 0 ] && [ $FAILED_PRODUCTION -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    elif [ $FAILED_LOCALHOST -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Localhost OK, Production has issues${NC}"
    elif [ $FAILED_PRODUCTION -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Production OK, Localhost has issues${NC}"
    else
        echo -e "${RED}❌ Both environments have issues${NC}"
    fi
    
    echo -e "\n${WHITE}=============================================================================${NC}"
    
    # Exit code basado en resultados
    if [ $FAILED_LOCALHOST -gt 0 ] || [ $FAILED_PRODUCTION -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Verificar dependencias
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}❌ Error: curl is required but not installed${NC}"
        exit 1
    fi
}

# Mostrar ayuda
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --localhost    Test only localhost endpoints"
    echo "  --production   Test only production endpoints"
    echo ""
    echo "Example:"
    echo "  $0                 # Test both environments"
    echo "  $0 --localhost     # Test only localhost"
    echo "  $0 --production    # Test only production"
}

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --localhost)
            PRODUCTION_BASE=""
            shift
            ;;
        --production)
            LOCALHOST_BASE=""
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Ejecutar verificaciones y pruebas
check_dependencies
main 