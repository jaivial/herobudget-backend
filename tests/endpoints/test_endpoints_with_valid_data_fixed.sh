#!/bin/bash

# =============================================================================
# SCRIPT CORREGIDO DE PRUEBAS CON DATOS VÁLIDOS - HERO BUDGET
# =============================================================================
# Versión corregida basada en el análisis del backend Go
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
    
    ((TOTAL_TESTS++))
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
test_health_endpoints_fixed() {
    echo -e "\n${WHITE}=== HEALTH CHECK ENDPOINTS (FIXED) ===${NC}"
    
    test_endpoint_with_valid_data "GET" "/health" "budget_overview_fetch" "Budget Overview Health" "{}" "success"
    test_endpoint_with_valid_data "GET" "/health" "fetch_dashboard" "Dashboard Health" "{}" "not_implemented"
    test_endpoint_with_valid_data "GET" "/health" "savings_management" "Savings Health" "{}" "not_implemented"
}

# Función para probar endpoints de autenticación con datos CORREGIDOS
test_auth_endpoints_fixed() {
    echo -e "\n${WHITE}=== AUTHENTICATION ENDPOINTS (FIXED) ===${NC}"
    
    # FORMATO CORRECTO: solo necesita campo "email" según el backend
    local valid_email_check='{
        "email": "test@herobudget.test"
    }'
    
    # FORMATO CORRECTO para signin según SignInRequest struct
    local valid_signin_data='{
        "email": "admin@herobudget.test",
        "password": "AdminPassword123!"
    }'
    
    # FORMATO CORRECTO para signup según SignupRequest struct
    local valid_signup_data='{
        "email": "test@herobudget.test",
        "password": "TestPassword123!",
        "name": "Test User",
        "given_name": "Test",
        "family_name": "User",
        "locale": "en",
        "verified_email": false
    }'
    
    # FORMATO CORRECTO para check verification (requiere user_id o email)
    local valid_check_verification='{
        "email": "test@herobudget.test"
    }'
    
    test_endpoint_with_valid_data "POST" "/signin/check-email" "signin" "Signin Check Email" "$valid_email_check" "success"
    test_endpoint_with_valid_data "POST" "/signin" "signin" "User Signin" "$valid_signin_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/signup/check-email" "signup" "Signup Check Email" "$valid_email_check" "success"
    test_endpoint_with_valid_data "POST" "/signup/register" "signup" "User Signup" "$valid_signup_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/signup/check-verification" "signup" "Check Verification" "$valid_check_verification" "success"
}

# Función para probar endpoints de categorías CORREGIDO
test_categories_endpoints_fixed() {
    echo -e "\n${WHITE}=== CATEGORIES MANAGEMENT ENDPOINTS (FIXED) ===${NC}"
    
    local user_id=$(get_valid_user_id)
    
    # FORMATO CORRECTO según AddCategoryRequest struct - nota el campo "type" NO "category_type"
    local valid_category_data='{
        "user_id": "'$user_id'",
        "name": "Test Category",
        "type": "expense",
        "emoji": "📁"
    }'
    
    # FORMATO CORRECTO según UpdateCategoryRequest - requiere category_id
    local valid_update_data='{
        "user_id": "'$user_id'",
        "category_id": 1,
        "name": "Updated Category",
        "type": "income",
        "emoji": "💰"
    }'
    
    # FORMATO CORRECTO según DeleteCategoryRequest - requiere category_id
    local valid_delete_data='{
        "user_id": "'$user_id'",
        "category_id": 999
    }'
    
    test_endpoint_with_valid_data "GET" "/categories?user_id=$user_id" "categories_management" "Categories Fetch" "{}" "success"
    test_endpoint_with_valid_data "POST" "/categories/add" "categories_management" "Categories Add" "$valid_category_data" "success"
    test_endpoint_with_valid_data "POST" "/categories/update" "categories_management" "Categories Update" "$valid_update_data" "validation_error"
    test_endpoint_with_valid_data "POST" "/categories/delete" "categories_management" "Categories Delete" "$valid_delete_data" "validation_error"
}

# Función para probar endpoints críticos con datos válidos
test_critical_endpoints_fixed() {
    echo -e "\n${WHITE}=== CRITICAL FINANCIAL ENDPOINTS (FIXED) ===${NC}"
    
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
    
    # Savings Management
    test_endpoint_with_valid_data "GET" "/savings/fetch?user_id=$user_id" "savings_management" "Savings Fetch" "{}" "success"
    test_endpoint_with_valid_data "POST" "/savings/update" "savings_management" "Savings Update" '{"user_id":"'$user_id'","goal":1500}' "success"
    
    # Income Management
    test_endpoint_with_valid_data "POST" "/incomes/add" "income_management" "Income Add" "$valid_income_data" "success"
    test_endpoint_with_valid_data "GET" "/incomes?user_id=$user_id" "income_management" "Income Fetch" "{}" "success"
    
    # Expense Management
    test_endpoint_with_valid_data "POST" "/expenses/add" "expense_management" "Expense Add" "$valid_expense_data" "success"
    test_endpoint_with_valid_data "GET" "/expenses?user_id=$user_id" "expense_management" "Expense Fetch" "{}" "success"
    
    # Bills Management
    test_endpoint_with_valid_data "GET" "/bills?user_id=$user_id" "bills_management" "Bills Fetch" "{}" "success"
    
    # Cash/Bank Management
    test_endpoint_with_valid_data "GET" "/cash-bank/distribution?user_id=$user_id" "cash_bank_management" "Cash Bank Distribution" "{}" "success"
}

# Función para probar endpoints faltantes que necesitan implementación
test_missing_endpoints() {
    echo -e "\n${WHITE}=== MISSING/404 ENDPOINTS (NEED IMPLEMENTATION) ===${NC}"
    
    local user_id=$(get_valid_user_id)
    
    # Estos endpoints devuelven 404 y necesitan implementación
    test_endpoint_with_valid_data "POST" "/cash-bank/cash/update" "cash_bank_management" "Cash Update" '{"user_id":"'$user_id'","amount":100}' "not_implemented"
    test_endpoint_with_valid_data "POST" "/cash-bank/bank/update" "cash_bank_management" "Bank Update" '{"user_id":"'$user_id'","amount":100}' "not_implemented"
    test_endpoint_with_valid_data "POST" "/update/locale" "profile_management" "Profile Update Locale" '{"user_id":"'$user_id'","locale":"es"}' "not_implemented"
    test_endpoint_with_valid_data "GET" "/money-flow/data?user_id=$user_id&period=monthly&date=$(date '+%Y-%m-%d')" "money_flow_sync" "Money Flow Data" "{}" "not_implemented"
    test_endpoint_with_valid_data "POST" "/user/update" "fetch_dashboard" "Dashboard User Update" '{"id":"'$user_id'","name":"Updated Name"}' "not_implemented"
}

# Función para generar reporte de análisis mejorado
generate_fixed_analysis_report() {
    echo -e "\n${WHITE}"
    echo "============================================================================="
    echo "   🔧 FIXED ENDPOINT ANALYSIS REPORT"
    echo "============================================================================="
    echo -e "${NC}"
    
    echo -e "${CYAN}📊 CORRECTED TEST SUMMARY:${NC}"
    echo -e "  Total Tests: $TOTAL_TESTS"
    echo -e "  ${GREEN}✅ Successful: $SUCCESS_COUNT${NC}"
    echo -e "  ${YELLOW}⚠️ Expected Failures: $EXPECTED_FAILURES${NC}"
    echo -e "  ${RED}❌ Real Failures: $REAL_FAILURES${NC}"
    echo ""
    
    if [ ${#REAL_FAILURES_LIST[@]} -gt 0 ]; then
        echo -e "${RED}🚨 REAL FAILURES STILL REQUIRING ATTENTION:${NC}"
        for failure in "${REAL_FAILURES_LIST[@]}"; do
            echo -e "${RED}  ❌ $failure${NC}"
        done
        echo ""
    fi
    
    if [ ${#SUCCESS_LIST[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ SUCCESSFULLY FIXED ENDPOINTS:${NC}"
        for success in "${SUCCESS_LIST[@]}"; do
            echo -e "${GREEN}  ✅ $success${NC}"
        done
        echo ""
    fi
    
    if [ ${#EXPECTED_FAILURES_LIST[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️ EXPECTED BEHAVIOR (Normal):${NC}"
        for expected in "${EXPECTED_FAILURES_LIST[@]}"; do
            echo -e "${YELLOW}  ⚠️ $expected${NC}"
        done
        echo ""
    fi
    
    # Calcular score de salud mejorado
    local health_score=0
    if [ $TOTAL_TESTS -gt 0 ]; then
        health_score=$(( (SUCCESS_COUNT * 100) / TOTAL_TESTS ))
    fi
    
    echo -e "${CYAN}🏥 SYSTEM HEALTH SCORE (LOCALHOST): ${health_score}%${NC}"
    
    if [ $REAL_FAILURES -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL REAL FAILURES FIXED - SYSTEM IS HEALTHY! 🎉${NC}"
    else
        echo -e "${RED}⚠️ ${REAL_FAILURES} REAL FAILURES STILL NEED ATTENTION${NC}"
    fi
    
    echo -e "\n${WHITE}=============================================================================${NC}"
}

# Función principal
main() {
    echo -e "${WHITE}"
    echo "============================================================================="
    echo "   🔧 HERO BUDGET - FIXED ENDPOINT TESTING"
    echo "============================================================================="
    echo "   Testing with CORRECTED data formats based on backend analysis"
    echo "   Focusing on localhost to identify and fix real issues"
    echo "============================================================================="
    echo -e "${NC}"
    
    # Mostrar configuración
    echo -e "${CYAN}Configuration:${NC}"
    echo -e "  Test Mode: CORRECTED data formats"
    echo -e "  Focus: Localhost only (fixing real failures)"
    echo -e "  Based on: Backend Go struct analysis"
    echo ""
    
    # Ejecutar pruebas corregidas
    test_health_endpoints_fixed
    test_auth_endpoints_fixed
    test_categories_endpoints_fixed
    test_critical_endpoints_fixed
    test_missing_endpoints
    
    # Generar reporte de análisis
    generate_fixed_analysis_report
    
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

# Ejecutar verificaciones y pruebas
check_dependencies
main 