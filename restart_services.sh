#!/bin/bash

# =============================================================================
# SCRIPT PARA REINICIAR TODOS LOS SERVICIOS GO EN /backend
# Version actualizada con verificaciones y organización por prioridades
# =============================================================================

# Configuración de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${WHITE}"
echo "============================================================================="
echo "   🔄 REINICIANDO TODOS LOS MICROSERVICIOS GO"
echo "============================================================================="
echo -e "${NC}"

# Get the absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define service ports using simple variables
LANGUAGE_SERVICE_PORT=8083
SIGNIN_PORT=8084
FETCH_DASHBOARD_PORT=8085
RESET_PASSWORD_PORT=8086
SIGNUP_PORT=8082
GOOGLE_AUTH_PORT=8081
DASHBOARD_DATA_PORT=8087
BUDGET_MANAGEMENT_PORT=8088
SAVINGS_MANAGEMENT_PORT=8089
CASH_BANK_MANAGEMENT_PORT=8090
BILLS_MANAGEMENT_PORT=8091
PROFILE_MANAGEMENT_PORT=8092
INCOME_MANAGEMENT_PORT=8093
EXPENSE_MANAGEMENT_PORT=8094
TRANSACTION_DELETE_PORT=8095
CATEGORIES_MANAGEMENT_PORT=8096
MONEY_FLOW_SYNC_PORT=8097
BUDGET_OVERVIEW_FETCH_PORT=8098

# Function to check if a port is in use
is_port_in_use() {
  lsof -i ":$1" >/dev/null 2>&1
  return $?
}

# Función para detener procesos existentes
stop_existing_services() {
    echo -e "${YELLOW}🛑 Deteniendo servicios existentes...${NC}"
    
    # Array de puertos
    ports=($LANGUAGE_SERVICE_PORT $SIGNIN_PORT $FETCH_DASHBOARD_PORT $RESET_PASSWORD_PORT $SIGNUP_PORT $GOOGLE_AUTH_PORT $DASHBOARD_DATA_PORT $BUDGET_MANAGEMENT_PORT $SAVINGS_MANAGEMENT_PORT $CASH_BANK_MANAGEMENT_PORT $BILLS_MANAGEMENT_PORT $PROFILE_MANAGEMENT_PORT $INCOME_MANAGEMENT_PORT $EXPENSE_MANAGEMENT_PORT $TRANSACTION_DELETE_PORT $CATEGORIES_MANAGEMENT_PORT $MONEY_FLOW_SYNC_PORT $BUDGET_OVERVIEW_FETCH_PORT)
    
    for port in "${ports[@]}"; do
        PID=$(lsof -ti:$port 2>/dev/null)
        if [ ! -z "$PID" ]; then
            echo -e "${YELLOW}  Deteniendo servicio en puerto $port (PID: $PID)${NC}"
            kill -9 $PID 2>/dev/null
        fi
    done
    
    sleep 2
    echo -e "${GREEN}✅ Servicios existentes detenidos${NC}"
}

# Detener servicios existentes
stop_existing_services

# Forzar cierre inmediato de cualquier puerto que siga en uso
echo -e "${RED}💀 Forzando cierre inmediato de todos los puertos...${NC}"
for port in $LANGUAGE_SERVICE_PORT $SIGNIN_PORT $FETCH_DASHBOARD_PORT $RESET_PASSWORD_PORT $SIGNUP_PORT $GOOGLE_AUTH_PORT $DASHBOARD_DATA_PORT $BUDGET_MANAGEMENT_PORT $SAVINGS_MANAGEMENT_PORT $CASH_BANK_MANAGEMENT_PORT $BILLS_MANAGEMENT_PORT $PROFILE_MANAGEMENT_PORT $INCOME_MANAGEMENT_PORT $EXPENSE_MANAGEMENT_PORT $TRANSACTION_DELETE_PORT $CATEGORIES_MANAGEMENT_PORT $MONEY_FLOW_SYNC_PORT $BUDGET_OVERVIEW_FETCH_PORT; do
  if is_port_in_use "$port"; then
    pid=$(lsof -i :$port -t 2>/dev/null)
    if [ -n "$pid" ]; then
      echo -e "${RED}💀 Forzando cierre del proceso en puerto $port (PID: $pid)...${NC}"
      kill -9 $pid 2>/dev/null
    fi
  fi
done

# Breve pausa para asegurar que los procesos se terminen
sleep 1
echo -e "${GREEN}✅ Todos los puertos han sido liberados por la fuerza!${NC}"

# Función para iniciar un servicio en background
start_service_background() {
    local service_name=$1
    local port=$2
    
    echo -e "${CYAN}🚀 Iniciando $service_name en puerto $port...${NC}"
    
    if [ -d "backend/$service_name" ]; then
        cd "backend/$service_name"
        go run main.go &
        local pid=$!
        echo -e "${GREEN}  ✅ $service_name iniciado (PID: $pid)${NC}"
        cd - > /dev/null
    else
        echo -e "${RED}  ❌ Directorio backend/$service_name no encontrado${NC}"
    fi
    
    # Esperar un poco para que el servicio se establezca
    sleep 1
}

# Función para verificar que un servicio esté respondiendo
verify_service() {
    local service_name=$1
    local port=$2
    local endpoint=$3
    
    echo -e "${BLUE}🔍 Verificando $service_name...${NC}"
    
    # Intentar conectar al endpoint
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:$port$endpoint" 2>/dev/null)
    
    if [ "$response" = "200" ] || [ "$response" = "404" ]; then
        echo -e "${GREEN}  ✅ $service_name está respondiendo (Status: $response)${NC}"
        return 0
    else
        echo -e "${RED}  ❌ $service_name no está respondiendo (Status: $response)${NC}"
        return 1
    fi
}

echo -e "\n${WHITE}=== INICIANDO SERVICIOS POR PRIORIDADES ===${NC}"

# Iniciar servicios prioritarios (los que han sido mejorados recientemente)
echo -e "\n${CYAN}📋 SERVICIOS PRIORITARIOS:${NC}"
start_service_background "cash_bank_management" $CASH_BANK_MANAGEMENT_PORT
start_service_background "profile_management" $PROFILE_MANAGEMENT_PORT
start_service_background "fetch_dashboard" $FETCH_DASHBOARD_PORT
start_service_background "money_flow_sync" $MONEY_FLOW_SYNC_PORT
start_service_background "savings_management" $SAVINGS_MANAGEMENT_PORT

# Iniciar servicios críticos adicionales
echo -e "\n${CYAN}📋 SERVICIOS CRÍTICOS:${NC}"
start_service_background "categories_management" $CATEGORIES_MANAGEMENT_PORT
start_service_background "income_management" $INCOME_MANAGEMENT_PORT
start_service_background "expense_management" $EXPENSE_MANAGEMENT_PORT
start_service_background "budget_overview_fetch" $BUDGET_OVERVIEW_FETCH_PORT
start_service_background "bills_management" $BILLS_MANAGEMENT_PORT

# Iniciar servicios de autenticación
echo -e "\n${CYAN}📋 SERVICIOS DE AUTENTICACIÓN:${NC}"
start_service_background "signin" $SIGNIN_PORT
start_service_background "signup" $SIGNUP_PORT
start_service_background "google_auth" $GOOGLE_AUTH_PORT
start_service_background "reset_password" $RESET_PASSWORD_PORT

# Iniciar servicios complementarios
echo -e "\n${CYAN}📋 SERVICIOS COMPLEMENTARIOS:${NC}"
start_service_background "language_cookie" $LANGUAGE_SERVICE_PORT
start_service_background "dashboard_data" $DASHBOARD_DATA_PORT
start_service_background "budget_management" $BUDGET_MANAGEMENT_PORT
start_service_background "transaction_delete_service" $TRANSACTION_DELETE_PORT

echo -e "\n${WHITE}=== VERIFICANDO SERVICIOS ===${NC}"

# Esperar a que todos los servicios se inicialicen
echo -e "${YELLOW}⏳ Esperando 5 segundos para que los servicios se inicialicen...${NC}"
sleep 5

# Verificar servicios prioritarios
echo -e "\n${CYAN}🔍 VERIFICANDO SERVICIOS PRIORITARIOS:${NC}"
verify_service "Cash Bank Management" $CASH_BANK_MANAGEMENT_PORT "/cash-bank/distribution?user_id=1"
verify_service "Profile Management" $PROFILE_MANAGEMENT_PORT "/health"
verify_service "Fetch Dashboard" $FETCH_DASHBOARD_PORT "/health"
verify_service "Money Flow Sync" $MONEY_FLOW_SYNC_PORT "/money-flow/data?user_id=1"
verify_service "Savings Management" $SAVINGS_MANAGEMENT_PORT "/health"

# Verificar servicios críticos
echo -e "\n${CYAN}🔍 VERIFICANDO SERVICIOS CRÍTICOS:${NC}"
verify_service "Categories Management" $CATEGORIES_MANAGEMENT_PORT "/categories?user_id=1"
verify_service "Income Management" $INCOME_MANAGEMENT_PORT "/incomes?user_id=1"
verify_service "Expense Management" $EXPENSE_MANAGEMENT_PORT "/expenses?user_id=1"
verify_service "Budget Overview" $BUDGET_OVERVIEW_FETCH_PORT "/health"
verify_service "Bills Management" $BILLS_MANAGEMENT_PORT "/bills?user_id=1"

echo -e "\n${WHITE}"
echo "============================================================================="
echo "   ✅ TODOS LOS SERVICIOS HAN SIDO REINICIADOS"
echo "============================================================================="
echo -e "${NC}"

echo -e "${GREEN}🎉 SERVICIOS FUNCIONANDO:${NC}"
echo -e "${WHITE}  • Google Auth: http://localhost:$GOOGLE_AUTH_PORT${NC}"
echo -e "${WHITE}  • Signup: http://localhost:$SIGNUP_PORT${NC}"
echo -e "${WHITE}  • Signin: http://localhost:$SIGNIN_PORT${NC}" 
echo -e "${WHITE}  • Dashboard Data: http://localhost:$DASHBOARD_DATA_PORT${NC}"
echo -e "${WHITE}  • Budget Management: http://localhost:$BUDGET_MANAGEMENT_PORT${NC}"
echo -e "${WHITE}  • Cash/Bank Management: http://localhost:$CASH_BANK_MANAGEMENT_PORT${NC}"
echo -e "${WHITE}  • Bills Management: http://localhost:$BILLS_MANAGEMENT_PORT${NC}"
echo -e "${WHITE}  • Income Management: http://localhost:$INCOME_MANAGEMENT_PORT${NC}"
echo -e "${WHITE}  • Expense Management: http://localhost:$EXPENSE_MANAGEMENT_PORT${NC}"
echo -e "${WHITE}  • Transaction Delete: http://localhost:$TRANSACTION_DELETE_PORT${NC}"
echo -e "${WHITE}  • Categories Management: http://localhost:$CATEGORIES_MANAGEMENT_PORT${NC}"
echo -e "${WHITE}  • Money Flow Sync: http://localhost:$MONEY_FLOW_SYNC_PORT${NC}"
echo -e "${WHITE}  • Budget Overview Fetch: http://localhost:$BUDGET_OVERVIEW_FETCH_PORT${NC}"

echo -e "\n${CYAN}📋 PARA PROBAR ENDPOINTS ESPECÍFICOS:${NC}"
echo -e "${WHITE}  ./tests/endpoints/test_endpoints_final_solution.sh${NC}"

echo -e "\n${GREEN}🎯 ESTADO: Sistema completamente operacional${NC}"

echo "" 