#!/bin/bash

# =============================================================================
# SCRIPT PARA REINICIAR TODOS LOS SERVICIOS GO EN VPS
# Version adaptada para /opt/hero_budget/backend/
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
echo "   🔄 REINICIANDO TODOS LOS MICROSERVICIOS GO EN VPS"
echo "   📁 Ruta base: /opt/hero_budget/backend/"
echo "============================================================================="
echo -e "${NC}"

# Configuración de rutas para VPS
BASE_DIR="/opt/hero_budget/backend"
GO_PATH="/usr/local/go/bin/go"

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

# Function to kill process by port
kill_process_on_port() {
    local port=$1
    local pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo -e "${YELLOW}  Deteniendo servicio en puerto $port (PID: $pid)${NC}"
        kill -9 $pid 2>/dev/null
        sleep 1
    fi
}

# Función para detener procesos existentes
stop_existing_services() {
    echo -e "${YELLOW}🛑 Deteniendo servicios existentes...${NC}"
    
    # Array de puertos
    ports=($LANGUAGE_SERVICE_PORT $SIGNIN_PORT $FETCH_DASHBOARD_PORT $RESET_PASSWORD_PORT $SIGNUP_PORT $GOOGLE_AUTH_PORT $DASHBOARD_DATA_PORT $BUDGET_MANAGEMENT_PORT $SAVINGS_MANAGEMENT_PORT $CASH_BANK_MANAGEMENT_PORT $BILLS_MANAGEMENT_PORT $PROFILE_MANAGEMENT_PORT $INCOME_MANAGEMENT_PORT $EXPENSE_MANAGEMENT_PORT $TRANSACTION_DELETE_PORT $CATEGORIES_MANAGEMENT_PORT $MONEY_FLOW_SYNC_PORT $BUDGET_OVERVIEW_FETCH_PORT)
    
    for port in "${ports[@]}"; do
        kill_process_on_port $port
    done
    
    echo -e "${GREEN}✅ Servicios existentes detenidos${NC}"
}

# Función para compilar un servicio
compile_service() {
    local service_name=$1
    local service_dir="$BASE_DIR/$service_name"
    
    if [ -d "$service_dir" ]; then
        echo -e "${BLUE}🔨 Compilando $service_name...${NC}"
        cd "$service_dir"
        
        # Verificar si Go está disponible
        if [ ! -x "$GO_PATH" ]; then
            echo -e "${RED}  ❌ Go no encontrado en $GO_PATH${NC}"
            return 1
        fi
        
        # Compilar el servicio
        $GO_PATH build -o "${service_name}" main.go 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✅ $service_name compilado exitosamente${NC}"
            return 0
        else
            echo -e "${RED}  ❌ Error compilando $service_name${NC}"
            return 1
        fi
    else
        echo -e "${RED}  ❌ Directorio $service_dir no encontrado${NC}"
        return 1
    fi
}

# Función para iniciar un servicio en background
start_service_background() {
    local service_name=$1
    local port=$2
    local service_dir="$BASE_DIR/$service_name"
    
    echo -e "${CYAN}🚀 Iniciando $service_name en puerto $port...${NC}"
    
    if [ -d "$service_dir" ]; then
        cd "$service_dir"
        
        # Verificar si el ejecutable existe
        if [ -x "./${service_name}" ]; then
            nohup "./${service_name}" > "${service_name}.log" 2>&1 &
            local pid=$!
            echo -e "${GREEN}  ✅ $service_name iniciado (PID: $pid)${NC}"
            sleep 1
            
            # Verificar que el proceso siga corriendo
            if kill -0 $pid 2>/dev/null; then
                echo -e "${GREEN}  🟢 $service_name está corriendo correctamente${NC}"
            else
                echo -e "${RED}  ❌ $service_name se detuvo inesperadamente${NC}"
                echo -e "${YELLOW}  📋 Últimas líneas del log:${NC}"
                tail -5 "${service_name}.log" 2>/dev/null | sed 's/^/    /'
            fi
        else
            echo -e "${RED}  ❌ Ejecutable ./${service_name} no encontrado${NC}"
        fi
    else
        echo -e "${RED}  ❌ Directorio $service_dir no encontrado${NC}"
    fi
}

# Función para verificar que un servicio esté respondiendo
verify_service() {
    local service_name=$1
    local port=$2
    local endpoint=$3
    
    echo -e "${BLUE}🔍 Verificando $service_name...${NC}"
    
    # Verificar que el puerto esté escuchando
    if ! is_port_in_use "$port"; then
        echo -e "${RED}  ❌ $service_name no está escuchando en puerto $port${NC}"
        return 1
    fi
    
    # Intentar conectar al endpoint
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:$port$endpoint" 2>/dev/null)
    
    if [ "$response" = "200" ] || [ "$response" = "404" ]; then
        echo -e "${GREEN}  ✅ $service_name está respondiendo (Status: $response)${NC}"
        return 0
    else
        echo -e "${RED}  ❌ $service_name no está respondiendo correctamente (Status: $response)${NC}"
        return 1
    fi
}

# Función para verificar endpoints específicos de Bills Management
verify_bills_endpoints() {
    echo -e "\n${CYAN}🔍 VERIFICANDO ENDPOINTS ESPECÍFICOS DE BILLS MANAGEMENT:${NC}"
    
    # Verificar endpoint principal
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:$BILLS_MANAGEMENT_PORT/bills?user_id=1" 2>/dev/null)
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}  ✅ Endpoint GET /bills está funcionando${NC}"
    else
        echo -e "${RED}  ❌ Endpoint GET /bills no responde (Status: $response)${NC}"
    fi
    
    # Verificar que el servicio tenga los nuevos endpoints configurados
    echo -e "${BLUE}  🔍 Verificando configuración de nuevos endpoints...${NC}"
    local delete_response=$(curl -s "http://localhost:$BILLS_MANAGEMENT_PORT/bills/delete" 2>/dev/null)
    if echo "$delete_response" | grep -q "Method not allowed\|Invalid request\|user_id.*required"; then
        echo -e "${GREEN}  ✅ Endpoint POST /bills/delete está configurado${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Endpoint POST /bills/delete: $delete_response${NC}"
    fi
}

# Detener servicios existentes
stop_existing_services

echo -e "\n${WHITE}=== COMPILANDO SERVICIOS ===${NC}"

# Lista de servicios a compilar y iniciar
services=(
    "bills_management:$BILLS_MANAGEMENT_PORT"
    "categories_management:$CATEGORIES_MANAGEMENT_PORT"
    "cash_bank_management:$CASH_BANK_MANAGEMENT_PORT"
    "dashboard_data:$DASHBOARD_DATA_PORT"
    "expense_management:$EXPENSE_MANAGEMENT_PORT"
    "fetch_dashboard:$FETCH_DASHBOARD_PORT"
    "google_auth:$GOOGLE_AUTH_PORT"
    "income_management:$INCOME_MANAGEMENT_PORT"
    "language_cookie:$LANGUAGE_SERVICE_PORT"
    "money_flow_sync:$MONEY_FLOW_SYNC_PORT"
    "profile_management:$PROFILE_MANAGEMENT_PORT"
    "reset_password:$RESET_PASSWORD_PORT"
    "savings_management:$SAVINGS_MANAGEMENT_PORT"
    "signin:$SIGNIN_PORT"
    "signup:$SIGNUP_PORT"
    "budget_management:$BUDGET_MANAGEMENT_PORT"
    "budget_overview_fetch:$BUDGET_OVERVIEW_FETCH_PORT"
    "transaction_delete_service:$TRANSACTION_DELETE_PORT"
)

# Compilar todos los servicios
compiled_services=()
for service_info in "${services[@]}"; do
    service_name=$(echo $service_info | cut -d':' -f1)
    if compile_service "$service_name"; then
        compiled_services+=("$service_info")
    fi
done

echo -e "\n${WHITE}=== INICIANDO SERVICIOS ===${NC}"

# Iniciar servicios críticos primero
echo -e "\n${CYAN}📋 SERVICIOS CRÍTICOS:${NC}"
critical_services=(
    "google_auth:$GOOGLE_AUTH_PORT"
    "bills_management:$BILLS_MANAGEMENT_PORT"
    "categories_management:$CATEGORIES_MANAGEMENT_PORT"
    "cash_bank_management:$CASH_BANK_MANAGEMENT_PORT"
)

for service_info in "${critical_services[@]}"; do
    if [[ " ${compiled_services[@]} " =~ " ${service_info} " ]]; then
        service_name=$(echo $service_info | cut -d':' -f1)
        port=$(echo $service_info | cut -d':' -f2)
        start_service_background "$service_name" "$port"
    fi
done

# Iniciar resto de servicios
echo -e "\n${CYAN}📋 RESTO DE SERVICIOS:${NC}"
for service_info in "${compiled_services[@]}"; do
    service_name=$(echo $service_info | cut -d':' -f1)
    port=$(echo $service_info | cut -d':' -f2)
    
    # Skip if already started in critical services
    if [[ ! " ${critical_services[@]} " =~ " ${service_info} " ]]; then
        start_service_background "$service_name" "$port"
    fi
done

echo -e "\n${WHITE}=== VERIFICANDO SERVICIOS ===${NC}"

# Esperar a que todos los servicios se inicialicen
echo -e "${YELLOW}⏳ Esperando 8 segundos para que los servicios se inicialicen...${NC}"
sleep 8

# Verificar servicios críticos
echo -e "\n${CYAN}🔍 VERIFICANDO SERVICIOS CRÍTICOS:${NC}"
verify_service "Google Auth" $GOOGLE_AUTH_PORT "/health"
verify_service "Bills Management" $BILLS_MANAGEMENT_PORT "/bills?user_id=1"
verify_service "Categories Management" $CATEGORIES_MANAGEMENT_PORT "/categories?user_id=1"
verify_service "Cash Bank Management" $CASH_BANK_MANAGEMENT_PORT "/cash-bank/distribution?user_id=1"

# Verificación específica de bills management con nuevos endpoints
verify_bills_endpoints

# Contar servicios activos
active_services=0
total_services=${#compiled_services[@]}

for service_info in "${compiled_services[@]}"; do
    service_name=$(echo $service_info | cut -d':' -f1)
    port=$(echo $service_info | cut -d':' -f2)
    
    if is_port_in_use "$port"; then
        ((active_services++))
    fi
done

echo -e "\n${WHITE}"
echo "============================================================================="
echo "   ✅ REINICIO COMPLETADO"
echo "   📊 Servicios activos: $active_services/$total_services"
echo "============================================================================="
echo -e "${NC}"

if [ $active_services -eq $total_services ]; then
    echo -e "${GREEN}🎉 TODOS LOS SERVICIOS ESTÁN FUNCIONANDO CORRECTAMENTE${NC}"
    exit 0
elif [ $active_services -gt $((total_services * 2 / 3)) ]; then
    echo -e "${YELLOW}⚠️  LA MAYORÍA DE SERVICIOS ESTÁN FUNCIONANDO ($active_services/$total_services)${NC}"
    exit 0
else
    echo -e "${RED}❌ MUCHOS SERVICIOS NO ESTÁN FUNCIONANDO ($active_services/$total_services)${NC}"
    echo -e "${YELLOW}💡 Revisar logs individuales en cada directorio de servicio${NC}"
    exit 1
fi 