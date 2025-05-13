#!/bin/bash

# Script to start all Go microservices in the /backend folder

echo "Starting all Go microservices..."

# Define service ports using simple variables
LANGUAGE_COOKIE_PORT=8083
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

# Function to check if a port is in use
is_port_in_use() {
  lsof -i ":$1" >/dev/null 2>&1
  return $?
}

# Function to get port for service
get_port_for_service() {
  case "$1" in
    "language_cookie") echo $LANGUAGE_COOKIE_PORT ;;
    "signin") echo $SIGNIN_PORT ;;
    "fetch_dashboard") echo $FETCH_DASHBOARD_PORT ;;
    "reset_password") echo $RESET_PASSWORD_PORT ;;
    "signup") echo $SIGNUP_PORT ;;
    "google_auth") echo $GOOGLE_AUTH_PORT ;;
    "dashboard_data") echo $DASHBOARD_DATA_PORT ;;
    "budget_management") echo $BUDGET_MANAGEMENT_PORT ;;
    "savings_management") echo $SAVINGS_MANAGEMENT_PORT ;;
    "cash_bank_management") echo $CASH_BANK_MANAGEMENT_PORT ;;
    "bills_management") echo $BILLS_MANAGEMENT_PORT ;;
    *) echo "" ;;
  esac
}

# Navigate to the backend directory
cd "$(dirname "$0")/backend"

# Loop through each directory in the backend folder
for service_dir in */; do
  # Remove trailing slash
  service=${service_dir%/}
  
  # Skip if not a directory
  if [ ! -d "$service" ]; then
    continue
  fi
  
  # Check if service has a defined port
  port=$(get_port_for_service "$service")
  if [ -n "$port" ]; then
    # Check if port is already in use
    if is_port_in_use "$port"; then
      echo "ERROR: Port $port for $service is already in use. Skipping service."
      continue
    fi
  fi
  
  echo "Starting $service service..."
  
  # Enter the service directory
  cd "$service"
  
  # Start the Go service in the background and save the PID to a file
  go run . &
  PID=$!
  echo $PID > "${service}.pid"
  
  # Return to the backend directory
  cd ..
  
  echo "$service service started with PID $PID"
  
  # Wait a moment to allow the service to start and bind to its port
  sleep 1
done

echo "All services started successfully!" 