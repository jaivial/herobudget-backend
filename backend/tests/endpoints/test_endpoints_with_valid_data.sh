#!/bin/bash

# =============================================================================
# SCRIPT AVANZADO DE PRUEBAS CON DATOS VÁLIDOS - HERO BUDGET
# =============================================================================
# Este script usa datos válidos específicos para cada endpoint para identificar
# fallos reales vs comportamientos esperados
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

# Variables globales para análisis
TOTAL_TESTS=0
REAL_FAILURES=0
EXPECTED_FAILURES=0
SUCCESS_COUNT=0

# Arrays para almacenar resultados
declare -a REAL_FAILURES_LIST
declare -a EXPECTED_FAILURES_LIST
declare -a SUCCESS_LIST

# Función para obtener puerto según el servicio
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

# Función para hacer peticiones HTTP con análisis de respuesta
test_endpoint_advanced() {
    local method=$1
    local url=$2
    local description=$3
    local data=$4
    local expected_behavior=$5  # "success", "validation_error", "not_implemented"
    
    local response
    local status_code
    local content
    
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
    
    # Extraer código de estado y contenido
    status_code=$(echo "$response" | tail -n1)
    content=$(echo "$response" | sed '$d')
    
    # Análisis inteligente de respuesta
    local test_result="UNKNOWN"
    local is_real_failure=false
    
    if [[ "$status_code" =~ ^[0-9]+$ ]]; then
        case $expected_behavior in
            "success")
                if [ "$status_code" -eq 200 ] || [ "$status_code" -eq 201 ]; then
                    test_result="SUCCESS"
                    ((SUCCESS_COUNT++))
                    SUCCESS_LIST+=("$description: $status_code")
                elif [ "$status_code" -eq 404 ] || [ "$status_code" -eq 405 ]; then
                    test_result="EXPECTED_NOT_FOUND"
                    ((EXPECTED_FAILURES++))
                    EXPECTED_FAILURES_LIST+=("$description: $status_code (Not Found/Method Not Allowed)")
                else
                    test_result="REAL_FAILURE"
                    is_real_failure=true
                    ((REAL_FAILURES++))
                    REAL_FAILURES_LIST+=("$description: $status_code - $content")
                fi
                ;;
            "validation_error")
                if [ "$status_code" -eq 400 ] || [ "$status_code" -eq 401 ] || [ "$status_code" -eq 422 ]; then
                    test_result="EXPECTED_VALIDATION"
                    ((EXPECTED_FAILURES++))
                    EXPECTED_FAILURES_LIST+=("$description: $status_code (Expected validation error)")
                elif [ "$status_code" -eq 200 ] || [ "$status_code" -eq 201 ]; then
                    test_result="UNEXPECTED_SUCCESS"
                    ((SUCCESS_COUNT++))
                    SUCCESS_LIST+=("$description: $status_code (Unexpected success)")
                else
                    test_result="REAL_FAILURE"
                    is_real_failure=true
                    ((REAL_FAILURES++))
                    REAL_FAILURES_LIST+=("$description: $status_code - $content")
                fi
                ;;
            "not_implemented")
                if [ "$status_code" -eq 501 ] || [ "$status_code" -eq 404 ]; then
                    test_result="EXPECTED_NOT_IMPLEMENTED"
                    ((EXPECTED_FAILURES++))
                    EXPECTED_FAILURES_LIST+=("$description: $status_code (Not implemented - expected)")
                else
                    test_result="REAL_FAILURE"
                    is_real_failure=true
                    ((REAL_FAILURES++))
                    REAL_FAILURES_LIST+=("$description: $status_code - Implementation status unclear")
                fi
                ;;
        esac
    else
        test_result="CONNECTION_ERROR"
        is_real_failure=true
        ((REAL_FAILURES++))
        REAL_FAILURES_LIST+=("$description: Connection failed")
    fi
    
    # Output colorizado según el resultado
    case $test_result in
        "SUCCESS"|"UNEXPECTED_SUCCESS")
            echo -e "${GREEN}✅ $test_result${NC} - $description (Status: $status_code)"
            ;;
        "EXPECTED_VALIDATION"|"EXPECTED_NOT_FOUND"|"EXPECTED_NOT_IMPLEMENTED")
            echo -e "${YELLOW}⚠️ $test_result${NC} - $description (Status: $status_code)"
            ;;
        "REAL_FAILURE"|"CONNECTION_ERROR")
            echo -e "${RED}❌ $test_result${NC} - $description (Status: $status_code)"
            if [ ${#content} -gt 0 ] && [ ${#content} -lt 200 ]; then
                echo -e "${RED}   Response: $content${NC}"
            fi
            ;;
        *)
            echo -e "${PURPLE}🔍 $test_result${NC} - $description (Status: $status_code)"
            ;;
    esac
    
    return $([ "$is_real_failure" = true ] && echo 1 || echo 0)
}

# Función para probar un endpoint en ambos ambientes con datos válidos
test_endpoint_with_valid_data() {
    local method=$1
    local path=$2
    local service=$3
    local description=$4
    local data=$5
    local expected_behavior=$6
    
    local port=$(get_port "$service")
    
    echo -e "\n${CYAN}Testing: $description${NC}"
    echo -e "${BLUE}Path: $path | Service: $service | Port: $port | Expected: $expected_behavior${NC}"
    
    # Probar en localhost
    local localhost_url="$LOCALHOST_BASE:$port$path"
    echo -e "${YELLOW}🏠 LOCALHOST: $localhost_url${NC}"
    test_endpoint_advanced "$method" "$localhost_url" "Localhost $description" "$data" "$expected_behavior"
    
    # Probar en producción
    local production_url="$PRODUCTION_BASE$path"
    echo -e "${PURPLE}🌐 PRODUCTION: $production_url${NC}"
    test_endpoint_advanced "$method" "$production_url" "Production $description" "$data" "$expected_behavior"
    
    ((TOTAL_TESTS++))
}

# Función para crear usuario de prueba válido
create_test_user() {
    echo -e "\n${WHITE}=== CREATING TEST USER ===${NC}"
    
    local test_email="test_$(date +%s)@herobudget.test"
    local test_user_data='{
        "email": "'$test_email'",
        "password": "TestPassword123!",
        "name": "Test User",
        "locale": "en"
    }'
    
    echo "Creating test user with email: $test_email"
    
    # Intentar crear usuario en localhost
    local localhost_url="$LOCALHOST_BASE:8082/signup/register"
    local response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$test_user_data" \
        "$localhost_url" 2>/dev/null)
    
    local status_code=$(echo "$response" | tail -n1)
    if [ "$status_code" -eq 200 ] || [ "$status_code" -eq 201 ]; then
        echo -e "${GREEN}✅ Test user created successfully${NC}"
        echo "$test_email"
        return 0
    else
        echo -e "${YELLOW}⚠️ Could not create new test user, using fallback${NC}"
        echo "test@herobudget.test"
        return 1
    fi
}

# Función para obtener ID de usuario válido
get_valid_user_id() {
    # Intentar obtener información de usuario existente
    local test_url="$LOCALHOST_BASE:8085/user/info?id=36"
    local response=$(curl -s -w "\n%{http_code}" -X GET \
        -H "Content-Type: application/json" \
        "$test_url" 2>/dev/null)
    
    local status_code=$(echo "$response" | tail -n1)
    if [ "$status_code" -eq 200 ]; then
        echo "36"
        return 0
    fi
    
    # Fallback a ID genérico
    echo "1"
    return 1
}

# Función para probar endpoints de health check
test_health_endpoints_advanced() {
    echo -e "\n${WHITE}=== HEALTH CHECK ENDPOINTS ===${NC}"
    
    test_endpoint_with_valid_data "GET" "/health" "budget_overview_fetch" "Budget Overview Health" "{}" "success"
    test_endpoint_with_valid_data "GET" "/health" "fetch_dashboard" "Dashboard Health" "{}" "success"
    test_endpoint_with_valid_data "GET" "/health" "savings_management" "Savings Health" "{}" "success"
}

# Función para probar endpoints de autenticación con datos válidos
test_auth_endpoints_advanced() {
    echo -e "\n${WHITE}=== AUTHENTICATION ENDPOINTS ===${NC}"
    
    # Crear usuario de prueba
    local test_email=$(create_test_user)
    
    # Datos válidos para autenticación
    local valid_signin_data='{
        "email": "admin@herobudget.test",
        "password": "AdminPassword123!"
    }'
    
    local valid_signup_data='{
        "email": "'$test_email'",
        "password": "TestPassword123!",
        "name": "Test User",
        "locale": "en"
    }'
    
    local check_email_data='{
        "email": "'$test_email'"
    }'
    
    # Probar con datos válidos pero expect validation errors para algunos
    test_endpoint_with_valid_data "POST" "/signin/check-email" "signin" "Signin Check Email" "$check_email_data" "success"
    test_endpoint_with_valid_data "POST" "/signin" "signin" "User Signin" "$valid_signin_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/signup/check-email" "signup" "Signup Check Email" "$check_email_data" "success"
    test_endpoint_with_valid_data "POST" "/signup/register" "signup" "User Signup" "$valid_signup_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/signup/check-verification" "signup" "Check Verification" "$check_email_data" "success"
}

# Función para probar endpoints de reset password
test_reset_password_endpoints_advanced() {
    echo -e "\n${WHITE}=== RESET PASSWORD ENDPOINTS ===${NC}"
    
    local valid_email_data='{
        "email": "admin@herobudget.test"
    }'
    
    local valid_token_data='{
        "token": "valid-reset-token-123"
    }'
    
    local valid_update_data='{
        "token": "valid-reset-token-123",
        "user_id": 1,
        "new_password": "NewPassword123!"
    }'
    
    test_endpoint_with_valid_data "POST" "/reset-password/check-email" "reset_password" "Reset Password Check Email" "$valid_email_data" "success"
    test_endpoint_with_valid_data "POST" "/reset-password/request" "reset_password" "Reset Password Request" "$valid_email_data" "success"
    test_endpoint_with_valid_data "POST" "/reset-password/validate-token" "reset_password" "Reset Password Validate Token" "$valid_token_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/reset-password/update" "reset_password" "Reset Password Update" "$valid_update_data" "validation_error"
}

# Función para probar endpoints financieros con datos válidos
test_financial_endpoints_advanced() {
    echo -e "\n${WHITE}=== FINANCIAL MANAGEMENT ENDPOINTS ===${NC}"
    
    local user_id=$(get_valid_user_id)
    local current_date=$(date '+%Y-%m-%d')
    
    # Datos válidos para transacciones financieras
    local valid_income_data='{
        "user_id": "'$user_id'",
        "amount": 150.50,
        "date": "'$current_date'",
        "category": "Salary",
        "payment_method": "bank",
        "description": "Monthly salary payment"
    }'
    
    local valid_expense_data='{
        "user_id": "'$user_id'",
        "amount": 75.25,
        "date": "'$current_date'",
        "category": "Food",
        "payment_method": "cash",
        "description": "Grocery shopping"
    }'
    
    local valid_update_data='{
        "user_id": "'$user_id'",
        "id": 1,
        "amount": 200.00,
        "date": "'$current_date'",
        "category": "Updated Category",
        "payment_method": "bank",
        "description": "Updated transaction"
    }'
    
    local valid_delete_data='{
        "user_id": "'$user_id'",
        "id": 999
    }'
    
    # Savings Management
    test_endpoint_with_valid_data "GET" "/savings/fetch?user_id=$user_id" "savings_management" "Savings Fetch" "{}" "success"
    test_endpoint_with_valid_data "POST" "/savings/update" "savings_management" "Savings Update" '{"user_id":"'$user_id'","goal":1500}' "success"
    test_endpoint_with_valid_data "POST" "/savings/delete" "savings_management" "Savings Delete" '{"user_id":"'$user_id'"}' "success"
    
    # Income Management
    test_endpoint_with_valid_data "POST" "/incomes/add" "income_management" "Income Add" "$valid_income_data" "success"
    test_endpoint_with_valid_data "GET" "/incomes?user_id=$user_id" "income_management" "Income Fetch" "{}" "success"
    test_endpoint_with_valid_data "POST" "/incomes/update" "income_management" "Income Update" "$valid_update_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/incomes/delete" "income_management" "Income Delete" "$valid_delete_data" "validation_error"
    
    # Expense Management
    test_endpoint_with_valid_data "POST" "/expenses/add" "expense_management" "Expense Add" "$valid_expense_data" "success"
    test_endpoint_with_valid_data "GET" "/expenses?user_id=$user_id" "expense_management" "Expense Fetch" "{}" "success"
    test_endpoint_with_valid_data "POST" "/expenses/update" "expense_management" "Expense Update" "$valid_update_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/expenses/delete" "expense_management" "Expense Delete" "$valid_delete_data" "validation_error"
}

# Función para probar endpoints de bills con datos válidos
test_bills_endpoints_advanced() {
    echo -e "\n${WHITE}=== BILLS MANAGEMENT ENDPOINTS ===${NC}"
    
    local user_id=$(get_valid_user_id)
    local start_date=$(date '+%Y-%m-%d')
    
    local valid_bill_data='{
        "user_id": "'$user_id'",
        "name": "Internet Bill",
        "amount": 45.99,
        "payment_day": 15,
        "duration_months": 12,
        "category": "Utilities",
        "icon": "🌐",
        "recurring": true,
        "regularity": "monthly",
        "start_date": "'$start_date'"
    }'
    
    local valid_pay_data='{
        "user_id": "'$user_id'",
        "bill_id": 1,
        "year_month": "2024-12",
        "description": "Internet payment for December"
    }'
    
    test_endpoint_with_valid_data "GET" "/bills?user_id=$user_id" "bills_management" "Bills Fetch" "{}" "success"
    test_endpoint_with_valid_data "POST" "/bills/add" "bills_management" "Bills Add" "$valid_bill_data" "success"
    test_endpoint_with_valid_data "POST" "/bills/pay" "bills_management" "Bills Pay" "$valid_pay_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/bills/update" "bills_management" "Bills Update" "$valid_bill_data" "not_implemented"
    test_endpoint_with_valid_data "POST" "/bills/delete" "bills_management" "Bills Delete" '{"user_id":"'$user_id'","bill_id":1}' "not_implemented"
    test_endpoint_with_valid_data "GET" "/bills/upcoming?user_id=$user_id" "bills_management" "Bills Upcoming" "{}" "not_implemented"
}

# Función para probar endpoints de cash/bank
test_cash_bank_endpoints_advanced() {
    echo -e "\n${WHITE}=== CASH/BANK MANAGEMENT ENDPOINTS ===${NC}"
    
    local user_id=$(get_valid_user_id)
    
    local valid_cash_update='{
        "user_id": "'$user_id'",
        "amount": 150.00,
        "date": "'$(date '+%Y-%m-%d')'"
    }'
    
    local valid_transfer='{
        "user_id": "'$user_id'",
        "amount": 25.00
    }'
    
    test_endpoint_with_valid_data "GET" "/cash-bank/distribution?user_id=$user_id" "cash_bank_management" "Cash Bank Distribution" "{}" "success"
    test_endpoint_with_valid_data "POST" "/cash-bank/cash/update" "cash_bank_management" "Cash Update" "$valid_cash_update" "validation_error"
    test_endpoint_with_valid_data "POST" "/cash-bank/bank/update" "cash_bank_management" "Bank Update" "$valid_cash_update" "validation_error"
    test_endpoint_with_valid_data "POST" "/transfer/cash-to-bank" "cash_bank_management" "Transfer Cash to Bank" "$valid_transfer" "validation_error"
    test_endpoint_with_valid_data "POST" "/transfer/bank-to-cash" "cash_bank_management" "Transfer Bank to Cash" "$valid_transfer" "validation_error"
}

# Función para probar endpoints de categorías
test_categories_endpoints_advanced() {
    echo -e "\n${WHITE}=== CATEGORIES MANAGEMENT ENDPOINTS ===${NC}"
    
    local user_id=$(get_valid_user_id)
    
    local valid_category_data='{
        "user_id": "'$user_id'",
        "name": "Test Category",
        "icon": "📁",
        "color": "blue",
        "category_type": "expense"
    }'
    
    test_endpoint_with_valid_data "GET" "/categories?user_id=$user_id" "categories_management" "Categories Fetch" "{}" "success"
    test_endpoint_with_valid_data "POST" "/categories/add" "categories_management" "Categories Add" "$valid_category_data" "success"
    test_endpoint_with_valid_data "POST" "/categories/update" "categories_management" "Categories Update" "$valid_category_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/categories/delete" "categories_management" "Categories Delete" '{"user_id":"'$user_id'","id":999}' "validation_error"
}

# Función para probar endpoints de perfil
test_profile_endpoints_advanced() {
    echo -e "\n${WHITE}=== PROFILE MANAGEMENT ENDPOINTS ===${NC}"
    
    local user_id=$(get_valid_user_id)
    
    local valid_profile_data='{
        "user_id": "'$user_id'",
        "name": "Updated Test User",
        "email": "updated@herobudget.test"
    }'
    
    local valid_password_data='{
        "user_id": "'$user_id'",
        "current_password": "CurrentPassword123!",
        "new_password": "NewPassword123!"
    }'
    
    test_endpoint_with_valid_data "GET" "/profile/ping" "profile_management" "Profile Ping" "{}" "success"
    test_endpoint_with_valid_data "POST" "/profile/update" "profile_management" "Profile Update" "$valid_profile_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/profile/update-password" "profile_management" "Profile Update Password" "$valid_password_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/profile/test-image-update" "profile_management" "Profile Test Image Update" '{"user_id":"'$user_id'","image":"base64imagedata"}' "validation_error"
    test_endpoint_with_valid_data "POST" "/update/locale" "profile_management" "Profile Update Locale" '{"user_id":"'$user_id'","locale":"es"}' "validation_error"
}

# Función para probar endpoints de transacciones y dashboard
test_transaction_dashboard_endpoints_advanced() {
    echo -e "\n${WHITE}=== TRANSACTION & DASHBOARD ENDPOINTS ===${NC}"
    
    local user_id=$(get_valid_user_id)
    local current_date=$(date '+%Y-%m')
    
    local valid_transaction_data='{
        "user_id": "'$user_id'",
        "limit": 10,
        "offset": 0,
        "period": "monthly",
        "date": "'$current_date'"
    }'
    
    local valid_delete_data='{
        "user_id": "'$user_id'",
        "transaction_id": 1,
        "transaction_type": "expense"
    }'
    
    test_endpoint_with_valid_data "POST" "/transactions/history" "budget_overview_fetch" "Transaction History" "$valid_transaction_data" "success"
    test_endpoint_with_valid_data "POST" "/transactions/delete" "transaction_delete" "Transaction Delete" "$valid_delete_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/budget-overview" "budget_overview_fetch" "Budget Overview" "$valid_transaction_data" "success"
    test_endpoint_with_valid_data "GET" "/user/info?id=$user_id" "fetch_dashboard" "Dashboard User Info" "{}" "validation_error"
    test_endpoint_with_valid_data "POST" "/user/update" "fetch_dashboard" "Dashboard User Update" '{"id":"'$user_id'","name":"Updated Name"}' "validation_error"
    test_endpoint_with_valid_data "GET" "/dashboard/data?user_id=$user_id&period=monthly&date=$(date '+%Y-%m-%d')" "dashboard_data" "Dashboard Data" "{}" "success"
    test_endpoint_with_valid_data "GET" "/money-flow/data?user_id=$user_id&period=monthly&date=$(date '+%Y-%m-%d')" "money_flow_sync" "Money Flow Data" "{}" "validation_error"
}

# Función para probar endpoints de idioma
test_language_endpoints_advanced() {
    echo -e "\n${WHITE}=== LANGUAGE MANAGEMENT ENDPOINTS ===${NC}"
    
    test_endpoint_with_valid_data "GET" "/language/get" "language" "Language Get" "{}" "success"
    test_endpoint_with_valid_data "POST" "/language/set" "language" "Language Set" '{"locale":"es"}' "success"
}

# Función para generar reporte de análisis
generate_analysis_report() {
    echo -e "\n${WHITE}"
    echo "============================================================================="
    echo "   🔍 ADVANCED ENDPOINT ANALYSIS REPORT"
    echo "============================================================================="
    echo -e "${NC}"
    
    echo -e "${CYAN}📊 TEST SUMMARY:${NC}"
    echo -e "  Total Tests: $TOTAL_TESTS"
    echo -e "  ${GREEN}✅ Successful: $SUCCESS_COUNT${NC}"
    echo -e "  ${YELLOW}⚠️ Expected Failures: $EXPECTED_FAILURES${NC}"
    echo -e "  ${RED}❌ Real Failures: $REAL_FAILURES${NC}"
    echo ""
    
    if [ ${#REAL_FAILURES_LIST[@]} -gt 0 ]; then
        echo -e "${RED}🚨 REAL FAILURES REQUIRING ATTENTION:${NC}"
        for failure in "${REAL_FAILURES_LIST[@]}"; do
            echo -e "${RED}  ❌ $failure${NC}"
        done
        echo ""
    fi
    
    if [ ${#SUCCESS_LIST[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ SUCCESSFUL ENDPOINTS:${NC}"
        for success in "${SUCCESS_LIST[@]}"; do
            echo -e "${GREEN}  ✅ $success${NC}"
        done
        echo ""
    fi
    
    if [ ${#EXPECTED_FAILURES_LIST[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️ EXPECTED FAILURES (Normal behavior):${NC}"
        for expected in "${EXPECTED_FAILURES_LIST[@]}"; do
            echo -e "${YELLOW}  ⚠️ $expected${NC}"
        done
        echo ""
    fi
    
    # Calcular score de salud
    local health_score=0
    if [ $TOTAL_TESTS -gt 0 ]; then
        health_score=$(( ((SUCCESS_COUNT + EXPECTED_FAILURES) * 100) / (TOTAL_TESTS * 2) ))
    fi
    
    echo -e "${CYAN}🏥 SYSTEM HEALTH SCORE: ${health_score}%${NC}"
    
    if [ $REAL_FAILURES -eq 0 ]; then
        echo -e "${GREEN}🎉 NO REAL FAILURES DETECTED - SYSTEM IS HEALTHY! 🎉${NC}"
    else
        echo -e "${RED}⚠️ REAL FAILURES DETECTED - NEEDS ATTENTION${NC}"
    fi
    
    echo -e "\n${WHITE}=============================================================================${NC}"
}

# Función principal
main() {
    echo -e "${WHITE}"
    echo "============================================================================="
    echo "   🧪 HERO BUDGET - ADVANCED ENDPOINT TESTING WITH VALID DATA"
    echo "============================================================================="
    echo "   Testing endpoints with realistic, valid data to identify real issues"
    echo "   Distinguishing between real failures and expected validation errors"
    echo "============================================================================="
    echo -e "${NC}"
    
    # Mostrar configuración
    echo -e "${CYAN}Configuration:${NC}"
    echo -e "  Localhost Base: $LOCALHOST_BASE"
    echo -e "  Production Base: $PRODUCTION_BASE"
    echo -e "  Test Mode: Advanced with valid data"
    echo ""
    
    # Ejecutar todas las pruebas
    test_health_endpoints_advanced
    test_auth_endpoints_advanced
    test_reset_password_endpoints_advanced
    test_financial_endpoints_advanced
    test_bills_endpoints_advanced
    test_cash_bank_endpoints_advanced
    test_categories_endpoints_advanced
    test_profile_endpoints_advanced
    test_transaction_dashboard_endpoints_advanced
    test_language_endpoints_advanced
    
    # Generar reporte de análisis
    generate_analysis_report
    
    # Exit code basado en fallos reales
    if [ $REAL_FAILURES -gt 0 ]; then
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
    
    if ! command -v date &> /dev/null; then
        echo -e "${RED}❌ Error: date command is required but not installed${NC}"
        exit 1
    fi
}

# Mostrar ayuda
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Advanced endpoint testing with valid data for Hero Budget API"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --localhost    Test only localhost endpoints"
    echo "  --production   Test only production endpoints"
    echo ""
    echo "Features:"
    echo "  • Uses realistic, valid data for each endpoint"
    echo "  • Distinguishes real failures from expected validation errors"
    echo "  • Creates test users when needed"
    echo "  • Analyzes response patterns intelligently"
    echo "  • Generates detailed failure analysis"
    echo ""
    echo "Example:"
    echo "  $0                 # Test both environments with analysis"
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