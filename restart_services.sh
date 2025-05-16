#!/bin/bash

# Script to restart all Go microservices in the /backend folder

echo "Restarting all Go microservices..."

# Get the absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
PROFILE_MANAGEMENT_PORT=8092
INCOME_MANAGEMENT_PORT=8093
EXPENSE_MANAGEMENT_PORT=8094

# Function to check if a port is in use
is_port_in_use() {
  lsof -i ":$1" >/dev/null 2>&1
  return $?
}

# First stop all services
"$SCRIPT_DIR/stop_services.sh"

# Wait and verify all ports are free
echo "Verifying all ports are free..."
max_attempts=10
attempt=1
all_ports_free=false

while [ $attempt -le $max_attempts ] && [ "$all_ports_free" != "true" ]; do
  all_ports_free=true
  
  for port in $LANGUAGE_COOKIE_PORT $SIGNIN_PORT $FETCH_DASHBOARD_PORT $RESET_PASSWORD_PORT $SIGNUP_PORT $GOOGLE_AUTH_PORT $DASHBOARD_DATA_PORT $BUDGET_MANAGEMENT_PORT $SAVINGS_MANAGEMENT_PORT $CASH_BANK_MANAGEMENT_PORT $BILLS_MANAGEMENT_PORT $PROFILE_MANAGEMENT_PORT $INCOME_MANAGEMENT_PORT $EXPENSE_MANAGEMENT_PORT; do
    if is_port_in_use "$port"; then
      echo "Port $port is still in use. Waiting..."
      all_ports_free=false
      break
    fi
  done
  
  if [ "$all_ports_free" != "true" ]; then
    echo "Waiting for ports to be released (attempt $attempt/$max_attempts)..."
    sleep 2
    attempt=$((attempt+1))
  fi
done

if [ "$all_ports_free" != "true" ]; then
  echo "ERROR: Some ports are still in use after $max_attempts attempts. Forcing kill..."
  for port in $LANGUAGE_COOKIE_PORT $SIGNIN_PORT $FETCH_DASHBOARD_PORT $RESET_PASSWORD_PORT $SIGNUP_PORT $GOOGLE_AUTH_PORT $DASHBOARD_DATA_PORT $BUDGET_MANAGEMENT_PORT $SAVINGS_MANAGEMENT_PORT $CASH_BANK_MANAGEMENT_PORT $BILLS_MANAGEMENT_PORT $PROFILE_MANAGEMENT_PORT $INCOME_MANAGEMENT_PORT $EXPENSE_MANAGEMENT_PORT; do
    if is_port_in_use "$port"; then
      pid=$(lsof -i :$port -t 2>/dev/null)
      if [ -n "$pid" ]; then
        echo "Force killing process on port $port (PID: $pid)..."
        kill -9 $pid 2>/dev/null
      fi
    fi
  done
  sleep 2
fi

# Then start all services
"$SCRIPT_DIR/start_services.sh"

echo "All services have been restarted!" 