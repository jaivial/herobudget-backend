#!/bin/bash

# Script to stop all Go microservices in the /backend folder

echo "Stopping all Go microservices..."

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
  
  # Check if PID file exists
  if [ -f "${service}/${service}.pid" ]; then
    PID=$(cat ${service}/${service}.pid)
    
    echo "Stopping $service service (PID: $PID)..."
    
    # Kill the process
    if kill $PID 2>/dev/null; then
      echo "$service service stopped"
    else
      echo "Failed to stop $service service, process may not be running"
    fi
    
    # Remove the PID file
    rm -f ${service}/${service}.pid
  else
    echo "$service service is not running (no PID file found)"
  fi
done

echo "All services stopped successfully!" 