#!/bin/bash

# Script to start all Go microservices in the /backend folder

echo "Starting all Go microservices..."

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
  
  echo "Starting $service service..."
  
  # Enter the service directory
  cd "$service"
  
  # Start the Go service in the background and save the PID to a file
  go run . &
  echo $! > "${service}.pid"
  
  # Return to the backend directory
  cd ..
  
  echo "$service service started with PID $(cat ${service}/${service}.pid)"
done

echo "All services started successfully!" 