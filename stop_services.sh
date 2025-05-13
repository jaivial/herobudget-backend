#!/bin/bash

# Script to stop all Go microservices in the /backend folder

echo "Stopping all Go microservices..."

# Define service ports using simple variables instead of associative array
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

# Navigate to the backend directory
cd "$(dirname "$0")/backend"

# First try to kill by PID file
for service_dir in */; do
  # Remove trailing slash
  service=${service_dir%/}
  
  # Skip if not a directory
  if [ ! -d "$service" ]; then
    continue
  fi
  
  # Check if PID file exists
  if [ -f "${service}/${service}.pid" ]; then
    PID=$(cat ${service}/${service}.pid)
    
    echo "Stopping $service service (PID: $PID)..."
    
    # Kill the process
    if kill $PID 2>/dev/null; then
      echo "$service service stopped via PID file"
    else
      echo "Failed to stop $service service via PID file, will try by port"
    fi
    
    # Remove the PID file regardless
    rm -f ${service}/${service}.pid
  else
    echo "$service service has no PID file, will try to stop by port"
  fi
done

# Then kill any remaining processes by port
for port in $LANGUAGE_COOKIE_PORT $SIGNIN_PORT $FETCH_DASHBOARD_PORT $RESET_PASSWORD_PORT $SIGNUP_PORT $GOOGLE_AUTH_PORT $DASHBOARD_DATA_PORT $BUDGET_MANAGEMENT_PORT $SAVINGS_MANAGEMENT_PORT $CASH_BANK_MANAGEMENT_PORT $BILLS_MANAGEMENT_PORT; do
  # Find process using this port
  pid=$(lsof -i :$port -t 2>/dev/null)
  
  if [ -n "$pid" ]; then
    echo "Stopping service on port $port (PID: $pid)..."
    
    # Kill the process
    if kill $pid 2>/dev/null; then
      echo "Service on port $port stopped"
    else
      echo "Failed to stop service on port $port, trying with -9"
      kill -9 $pid 2>/dev/null && echo "Service on port $port force stopped" || echo "Failed to force stop service on port $port"
    fi
  fi
done

echo "All services stopped successfully!" 