#!/bin/bash

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define service ports
AUTH_SERVICE_PORT=8081
SIGNUP_SERVICE_PORT=8082
LANGUAGE_SERVICE_PORT=8083
SIGNIN_SERVICE_PORT=8084
FETCH_DASHBOARD_PORT=8085
RESET_PASSWORD_PORT=8086
DASHBOARD_DATA_PORT=8087
BUDGET_MANAGEMENT_PORT=8088
SAVINGS_MANAGEMENT_PORT=8089
CASH_BANK_MANAGEMENT_PORT=8090
BILLS_MANAGEMENT_PORT=8091
PROFILE_MANAGEMENT_PORT=8092
INCOME_MANAGEMENT_PORT=8093
EXPENSE_MANAGEMENT_PORT=8094
CATEGORIES_MANAGEMENT_PORT=8095
MONEY_FLOW_SYNC_PORT=8096
MONEY_FLOW_CALCULATION_PORT=8097

# Service directories
services=(
    "google_auth"
    "signup"
    "language_cookie"
    "signin"
    "fetch_dashboard"
    "reset_password"
    "dashboard_data"
    "budget_management"
    "savings_management"
    "cash_bank_management"
    "bills_management"
    "profile_management"
    "income_management"
    "expense_management"
    "categories_management"
    "money_flow_sync"
    "money_flow_calculation"
)

# Output header
echo -e "${GREEN}Stopping Hero Budget backend services...${NC}"
echo

# Kill processes by port (more reliable)
for port in $AUTH_SERVICE_PORT $SIGNUP_SERVICE_PORT $LANGUAGE_SERVICE_PORT $SIGNIN_SERVICE_PORT $FETCH_DASHBOARD_PORT $RESET_PASSWORD_PORT $DASHBOARD_DATA_PORT $BUDGET_MANAGEMENT_PORT $SAVINGS_MANAGEMENT_PORT $CASH_BANK_MANAGEMENT_PORT $BILLS_MANAGEMENT_PORT $PROFILE_MANAGEMENT_PORT $INCOME_MANAGEMENT_PORT $EXPENSE_MANAGEMENT_PORT $CATEGORIES_MANAGEMENT_PORT $MONEY_FLOW_SYNC_PORT $MONEY_FLOW_CALCULATION_PORT; do
    # Find and kill process using this port
    PID=$(lsof -i :$port -t 2>/dev/null)
    if [ -n "$PID" ]; then
        echo -e "${YELLOW}Stopping service on port $port (PID: $PID)...${NC}"
        kill -9 $PID 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Service on port $port stopped successfully.${NC}"
        else
            echo -e "${RED}Failed to stop service on port $port.${NC}"
        fi
    fi
done

# Stop by PID files as backup method
cd backend
for service in "${services[@]}"; do
    if [ -d "$service" ] && [ -f "$service/$service.pid" ]; then
        PID=$(cat "$service/$service.pid" 2>/dev/null)
        if [ -n "$PID" ]; then
            echo -e "${YELLOW}Stopping $service service (PID: $PID)...${NC}"
            kill -9 $PID 2>/dev/null
            rm -f "$service/$service.pid"
            echo -e "${GREEN}$service service stopped.${NC}"
        fi
    fi
done
cd ..

# Clean up executables
cd backend
for service in "${services[@]}"; do
    if [ -d "$service" ] && [ -f "$service/$service.exe" ]; then
        rm -f "$service/$service.exe"
    fi
done
cd ..

echo
echo -e "${GREEN}All services stopped.${NC}" 