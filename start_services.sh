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

# Function to get service port by name
get_port() {
  case $1 in
    "google_auth") echo $AUTH_SERVICE_PORT ;;
    "signup") echo $SIGNUP_SERVICE_PORT ;;
    "language_cookie") echo $LANGUAGE_SERVICE_PORT ;;
    "signin") echo $SIGNIN_SERVICE_PORT ;;
    "fetch_dashboard") echo $FETCH_DASHBOARD_PORT ;;
    "reset_password") echo $RESET_PASSWORD_PORT ;;
    "dashboard_data") echo $DASHBOARD_DATA_PORT ;;
    "budget_management") echo $BUDGET_MANAGEMENT_PORT ;;
    "savings_management") echo $SAVINGS_MANAGEMENT_PORT ;;
    "cash_bank_management") echo $CASH_BANK_MANAGEMENT_PORT ;;
    "bills_management") echo $BILLS_MANAGEMENT_PORT ;;
    "profile_management") echo $PROFILE_MANAGEMENT_PORT ;;
    "income_management") echo $INCOME_MANAGEMENT_PORT ;;
    "expense_management") echo $EXPENSE_MANAGEMENT_PORT ;;
    "categories_management") echo $CATEGORIES_MANAGEMENT_PORT ;;
    "money_flow_sync") echo $MONEY_FLOW_SYNC_PORT ;;
    "money_flow_calculation") echo $MONEY_FLOW_CALCULATION_PORT ;;
    *) echo "" ;;
  esac
}

# List of services to start
services=(
  "google_auth"
  "signup"
  "language_cookie"
  "signin"
  "reset_password"
  "fetch_dashboard"
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

# Check for selected services
if [ $# -gt 0 ]; then
  # If specific services are requested, only start those
  services=("$@")
fi

# Output header
echo -e "${GREEN}Starting Hero Budget backend services...${NC}"
echo

# Navigate to backend directory
cd backend

# Start each service in the background
for service in "${services[@]}"; do
  echo -e "${YELLOW}Starting $service service...${NC}"
  
  if [ -d "$service" ]; then
    cd $service
    
    # Get port for the service
    PORT=$(get_port $service)
    
    # Check if port is already in use
    if lsof -i :$PORT > /dev/null; then
      echo -e "${RED}Port $PORT is already in use. Service $service may already be running.${NC}"
      cd ..
      continue
    fi
    
    # Try to build and run the service
    if go build -o $service.exe .; then
      ./$service.exe &
      echo $! > $service.pid
      echo -e "${GREEN}$service service started successfully on port $PORT. PID: $(cat $service.pid)${NC}"
    else
      echo -e "${RED}Failed to build $service service.${NC}"
    fi
    
    cd ..
  else
    echo -e "${RED}Service directory '$service' not found.${NC}"
  fi
  
  echo
done

echo -e "${GREEN}All requested services started.${NC}"
echo -e "${YELLOW}Use ./stop_services.sh to stop all services.${NC}" 