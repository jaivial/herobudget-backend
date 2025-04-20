#!/bin/bash

# Script to restart all Go microservices in the /backend folder

echo "Restarting all Go microservices..."

# Get the absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# First stop all services
"$SCRIPT_DIR/stop_services.sh"

# Wait a moment for processes to properly terminate
sleep 2

# Then start all services
"$SCRIPT_DIR/start_services.sh"

echo "All services have been restarted!" 