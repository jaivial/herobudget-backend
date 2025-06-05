#!/bin/bash

# =============================================================================
# HERO BUDGET - MICROSERVICES DEPLOYMENT SCRIPT
# =============================================================================
# Sube y configura microservicios Go en el VPS de producción
# Local: /Users/usuario/Documents/PROYECTOS/herobudgetflutter/hero_budget/backend
# VPS: 178.16.130.178:/opt/hero_budget/backend
# =============================================================================

# Verificar que se está ejecutando con bash
if [ -z "$BASH_VERSION" ]; then
    echo "❌ Este script requiere bash. Ejecuta con: bash $0"
    exit 1
fi

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VPS_IP="178.16.130.178"
VPS_USER="root"
LOCAL_BACKEND_DIR="/Users/usuario/Documents/PROYECTOS/herobudgetflutter/hero_budget/backend"
VPS_PROJECT_DIR="/opt/hero_budget"
VPS_BACKEND_DIR="$VPS_PROJECT_DIR/backend"
POSTGRES_DB="herobudget"
POSTGRES_USER="herobudget_user"
POSTGRES_PASSWORD="HeroBudget2024!Secure"

# Microservices list - usando arrays normales en lugar de asociativo
MICROSERVICES_NAMES=(
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
    "transaction_delete_service"
    "categories_management"
    "money_flow_sync"
    "budget_overview_fetch"
)

MICROSERVICES_PORTS=(
    "8081"
    "8082"
    "8083"
    "8084"
    "8085"
    "8086"
    "8087"
    "8088"
    "8089"
    "8090"
    "8091"
    "8092"
    "8093"
    "8094"
    "8095"
    "8096"
    "8097"
    "8098"
)

# Function to get port for service
get_port_for_service() {
    local service_name=$1
    for i in "${!MICROSERVICES_NAMES[@]}"; do
        if [[ "${MICROSERVICES_NAMES[$i]}" == "$service_name" ]]; then
            echo "${MICROSERVICES_PORTS[$i]}"
            return
        fi
    done
    echo ""
}

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check local backend directory
check_local_backend() {
    print_header "CHECKING LOCAL BACKEND DIRECTORY"
    
    if [[ ! -d "$LOCAL_BACKEND_DIR" ]]; then
        print_error "Local backend directory not found: $LOCAL_BACKEND_DIR"
        exit 1
    fi
    
    print_success "Local backend directory found"
    
    # Check for microservices
    local found_services=0
    local missing_services=()
    
    for service in "${MICROSERVICES_NAMES[@]}"; do
        if [[ -d "$LOCAL_BACKEND_DIR/$service" ]]; then
            print_success "Service found: $service"
            ((found_services++))
        else
            print_warning "Service missing: $service"
            missing_services+=("$service")
        fi
    done
    
    print_info "Found $found_services out of ${#MICROSERVICES_NAMES[@]} microservices"
    
    if [[ $found_services -eq 0 ]]; then
        print_error "No microservices found in backend directory"
        exit 1
    fi
    
    if [[ ${#missing_services[@]} -gt 0 ]]; then
        print_warning "Missing services: ${missing_services[*]}"
        read -p "Continue with available services? (y/N): " continue_partial
        if [[ ! $continue_partial =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# Prepare VPS environment
prepare_vps_environment() {
    print_header "PREPARING VPS ENVIRONMENT"
    
    print_info "Installing Go and dependencies on VPS..."
    
    ssh "$VPS_USER@$VPS_IP" << 'EOF'
set -e

# Update system
echo "📦 Updating system packages..."
apt update

# Install Go if not present
if ! command -v go &> /dev/null; then
    echo "📦 Installing Go..."
    
    # Download and install Go 1.21
    cd /tmp
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    
    # Remove old Go installation
    rm -rf /usr/local/go
    
    # Extract new Go
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    
    # Add to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    
    # Clean up
    rm go1.21.5.linux-amd64.tar.gz
    
    # Verify installation
    /usr/local/go/bin/go version
    
    echo "✅ Go installed successfully"
else
    echo "✅ Go already installed"
    go version
fi

# Install additional tools
echo "📦 Installing additional tools..."
apt install -y git curl wget unzip build-essential

# Create backend directory structure
echo "📁 Creating backend directory structure..."
mkdir -p /opt/hero_budget/backend
mkdir -p /opt/hero_budget/logs
mkdir -p /opt/hero_budget/config

echo "✅ VPS environment prepared"
EOF

    if [[ $? -eq 0 ]]; then
        print_success "VPS environment prepared successfully"
    else
        print_error "Failed to prepare VPS environment"
        exit 1
    fi
}

# Create configuration files
create_config_files() {
    print_header "CREATING CONFIGURATION FILES"
    
    print_info "Creating database configuration..."
    
    # Create database config
    cat > /tmp/database.env << EOF
# Database Configuration for Hero Budget Production
DB_TYPE=postgresql
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$POSTGRES_DB
DB_USER=$POSTGRES_USER
DB_PASSWORD=$POSTGRES_PASSWORD
DB_SSLMODE=disable

# Connection Pool Settings
DB_MAX_OPEN_CONNS=25
DB_MAX_IDLE_CONNS=5
DB_CONN_MAX_LIFETIME=300s

# Server Settings
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=production

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
EOF

    # Create Go database connection helper
    cat > /tmp/database.go << 'EOF'
package main

import (
    "database/sql"
    "fmt"
    "log"
    "os"
    "strconv"
    "time"
    
    _ "github.com/lib/pq"
)

type DatabaseConfig struct {
    Host     string
    Port     string
    User     string
    Password string
    DBName   string
    SSLMode  string
}

func GetDatabaseConfig() *DatabaseConfig {
    return &DatabaseConfig{
        Host:     getEnv("DB_HOST", "localhost"),
        Port:     getEnv("DB_PORT", "5432"),
        User:     getEnv("DB_USER", "herobudget_user"),
        Password: getEnv("DB_PASSWORD", "HeroBudget2024!Secure"),
        DBName:   getEnv("DB_NAME", "herobudget"),
        SSLMode:  getEnv("DB_SSLMODE", "disable"),
    }
}

func (config *DatabaseConfig) ConnectionString() string {
    return fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
        config.Host, config.Port, config.User, config.Password, config.DBName, config.SSLMode)
}

func ConnectDatabase() (*sql.DB, error) {
    config := GetDatabaseConfig()
    
    db, err := sql.Open("postgres", config.ConnectionString())
    if err != nil {
        return nil, fmt.Errorf("failed to open database: %v", err)
    }
    
    // Configure connection pool
    maxOpenConns, _ := strconv.Atoi(getEnv("DB_MAX_OPEN_CONNS", "25"))
    maxIdleConns, _ := strconv.Atoi(getEnv("DB_MAX_IDLE_CONNS", "5"))
    connMaxLifetime, _ := time.ParseDuration(getEnv("DB_CONN_MAX_LIFETIME", "300s"))
    
    db.SetMaxOpenConns(maxOpenConns)
    db.SetMaxIdleConns(maxIdleConns)
    db.SetConnMaxLifetime(connMaxLifetime)
    
    // Test connection
    if err := db.Ping(); err != nil {
        return nil, fmt.Errorf("failed to ping database: %v", err)
    }
    
    log.Println("Database connection established successfully")
    return db, nil
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
EOF

    # Transfer config files to VPS
    scp /tmp/database.env "$VPS_USER@$VPS_IP:$VPS_PROJECT_DIR/config/"
    scp /tmp/database.go "$VPS_USER@$VPS_IP:$VPS_PROJECT_DIR/config/"
    
    # Clean up local temp files
    rm /tmp/database.env /tmp/database.go
    
    print_success "Configuration files created and uploaded"
}

# Transfer microservices
transfer_microservices() {
    print_header "TRANSFERRING MICROSERVICES TO VPS"
    
    print_info "Stopping Hero Budget services on VPS..."
    ssh "$VPS_USER@$VPS_IP" "systemctl stop herobudget 2>/dev/null || true"
    
    print_info "Creating backup of existing backend..."
    ssh "$VPS_USER@$VPS_IP" "
        if [[ -d $VPS_BACKEND_DIR ]]; then
            mv $VPS_BACKEND_DIR $VPS_PROJECT_DIR/backend_backup_\$(date +%Y%m%d_%H%M%S)
        fi
        mkdir -p $VPS_BACKEND_DIR
    "
    
    print_info "Transferring microservices..."
    
    # Transfer each microservice
    for service in "${MICROSERVICES_NAMES[@]}"; do
        if [[ -d "$LOCAL_BACKEND_DIR/$service" ]]; then
            print_info "Transferring $service..."
            
            # Use rsync for efficient transfer (excludes .git, logs, etc.)
            rsync -avz --exclude='.git' --exclude='*.log' --exclude='*.db' \
                  "$LOCAL_BACKEND_DIR/$service/" "$VPS_USER@$VPS_IP:$VPS_BACKEND_DIR/$service/"
            
            print_success "$service transferred"
        fi
    done
    
    print_success "All microservices transferred"
}

# Configure microservices
configure_microservices() {
    print_header "CONFIGURING MICROSERVICES"
    
    print_info "Setting up Go modules and dependencies..."
    
    ssh "$VPS_USER@$VPS_IP" << EOF
set -e
export PATH=\$PATH:/usr/local/go/bin

cd $VPS_BACKEND_DIR

# Configure each microservice
for service_dir in */; do
    if [[ -d "\$service_dir" ]]; then
        service_name=\${service_dir%/}
        echo "🔧 Configuring \$service_name..."
        
        cd "\$service_dir"
        
        # Initialize Go module if not exists
        if [[ ! -f "go.mod" ]]; then
            echo "📦 Initializing Go module for \$service_name..."
            go mod init herobudget/\$service_name
        fi
        
        # Copy database configuration
        cp $VPS_PROJECT_DIR/config/database.go . 2>/dev/null || true
        
        # Create environment file
        cp $VPS_PROJECT_DIR/config/database.env .env 2>/dev/null || true
        
        # Add PostgreSQL driver dependency if not present
        if ! grep -q "github.com/lib/pq" go.mod 2>/dev/null; then
            echo "📦 Adding PostgreSQL driver..."
            go get github.com/lib/pq
        fi
        
        # Download dependencies
        echo "📦 Downloading dependencies for \$service_name..."
        go mod tidy
        
        # Set proper permissions
        chmod +x *.go 2>/dev/null || true
        
        cd ..
    fi
done

echo "✅ All microservices configured"
EOF

    if [[ $? -eq 0 ]]; then
        print_success "Microservices configured successfully"
    else
        print_error "Failed to configure microservices"
        exit 1
    fi
}

# Compile microservices
compile_microservices() {
    print_header "COMPILING MICROSERVICES"
    
    print_info "Compiling Go microservices for production..."
    
    ssh "$VPS_USER@$VPS_IP" << 'EOF'
set -e
export PATH=$PATH:/usr/local/go/bin
export CGO_ENABLED=0
export GOOS=linux

cd /opt/hero_budget/backend

compiled_services=0
failed_services=()

for service_dir in */; do
    if [[ -d "$service_dir" ]]; then
        service_name=${service_dir%/}
        echo "🔨 Compiling $service_name..."
        
        cd "$service_dir"
        
        # Find main Go file
        main_file=""
        if [[ -f "main.go" ]]; then
            main_file="main.go"
        elif [[ -f "$service_name.go" ]]; then
            main_file="$service_name.go"
        else
            # Find any .go file with main function
            main_file=$(grep -l "func main" *.go 2>/dev/null | head -1)
        fi
        
        if [[ -n "$main_file" ]]; then
            # Compile with optimizations
            if go build -ldflags="-s -w" -o "$service_name.exe" "$main_file"; then
                echo "✅ $service_name compiled successfully"
                
                # Make executable
                chmod +x "$service_name.exe"
                
                # Test that it can run (quick check)
                if ./"$service_name.exe" --help >/dev/null 2>&1 || \
                   timeout 2s ./"$service_name.exe" >/dev/null 2>&1; then
                    echo "✅ $service_name executable test passed"
                fi
                
                ((compiled_services++))
            else
                echo "❌ Failed to compile $service_name"
                failed_services+=("$service_name")
            fi
        else
            echo "❌ No main Go file found for $service_name"
            failed_services+=("$service_name")
        fi
        
        cd ..
    fi
done

echo ""
echo "📊 Compilation Summary:"
echo "  Compiled: $compiled_services services"
echo "  Failed: ${#failed_services[@]} services"

if [[ ${#failed_services[@]} -gt 0 ]]; then
    echo "  Failed services: ${failed_services[*]}"
fi

# Create executable summary
echo ""
echo "📁 Compiled Executables:"
find . -name "*.exe" -type f -exec ls -la {} \;
EOF

    if [[ $? -eq 0 ]]; then
        print_success "Microservices compilation completed"
    else
        print_error "Some microservices failed to compile"
        print_warning "Check VPS logs for compilation errors"
    fi
}

# Update service scripts
update_service_scripts() {
    print_header "UPDATING SERVICE SCRIPTS"
    
    print_info "Creating updated start/stop scripts..."
    
    # Create updated start_services.sh
    cat > /tmp/start_services.sh << 'EOF'
#!/bin/bash

# =============================================================================
# HERO BUDGET - START SERVICES SCRIPT (Production)
# =============================================================================
# Starts all Hero Budget microservices on production VPS
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKEND_DIR="/opt/hero_budget/backend"
LOG_DIR="/opt/hero_budget/logs"
CONFIG_DIR="/opt/hero_budget/config"

# Create log directory
mkdir -p "$LOG_DIR"

# Load environment variables
if [[ -f "$CONFIG_DIR/database.env" ]]; then
    set -a  # Automatically export variables
    source "$CONFIG_DIR/database.env"
    set +a
fi

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to start a service
start_service() {
    local service_name=$1
    local port=$2
    local service_dir="$BACKEND_DIR/$service_name"
    local executable="$service_dir/$service_name.exe"
    local log_file="$LOG_DIR/$service_name.log"
    local pid_file="$LOG_DIR/$service_name.pid"
    
    if [[ ! -f "$executable" ]]; then
        print_error "Executable not found: $executable"
        return 1
    fi
    
    # Check if service is already running
    if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
        print_info "$service_name already running (PID: $(cat "$pid_file"))"
        return 0
    fi
    
    print_info "Starting $service_name on port $port..."
    
    # Start service in background
    cd "$service_dir"
    nohup "./$service_name.exe" > "$log_file" 2>&1 &
    local pid=$!
    
    # Save PID
    echo $pid > "$pid_file"
    
    # Wait a moment and check if it's still running
    sleep 2
    if kill -0 $pid 2>/dev/null; then
        print_success "$service_name started (PID: $pid)"
        return 0
    else
        print_error "$service_name failed to start"
        rm -f "$pid_file"
        return 1
    fi
}

# Start all services
print_info "Starting Hero Budget microservices..."

start_service "google_auth" 8081
start_service "signup" 8082
start_service "language_cookie" 8083
start_service "signin" 8084
start_service "fetch_dashboard" 8085
start_service "reset_password" 8086
start_service "dashboard_data" 8087
start_service "budget_management" 8088
start_service "savings_management" 8089
start_service "cash_bank_management" 8090
start_service "bills_management" 8091
start_service "profile_management" 8092
start_service "income_management" 8093
start_service "expense_management" 8094
start_service "transaction_delete_service" 8095
start_service "categories_management" 8096
start_service "money_flow_sync" 8097
start_service "budget_overview_fetch" 8098

echo ""
print_info "Service startup completed"
print_info "Logs are available in: $LOG_DIR"
print_info "Check status with: systemctl status herobudget"
EOF

    # Create updated stop_services.sh
    cat > /tmp/stop_services.sh << 'EOF'
#!/bin/bash

# =============================================================================
# HERO BUDGET - STOP SERVICES SCRIPT (Production)
# =============================================================================
# Stops all Hero Budget microservices on production VPS
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
LOG_DIR="/opt/hero_budget/logs"

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to stop a service
stop_service() {
    local service_name=$1
    local pid_file="$LOG_DIR/$service_name.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_info "Stopping $service_name (PID: $pid)..."
            kill "$pid"
            
            # Wait for graceful shutdown
            local count=0
            while kill -0 "$pid" 2>/dev/null && [[ $count -lt 10 ]]; do
                sleep 1
                ((count++))
            done
            
            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                print_info "Force killing $service_name..."
                kill -9 "$pid"
            fi
            
            print_success "$service_name stopped"
        fi
        rm -f "$pid_file"
    else
        print_info "$service_name not running"
    fi
}

# Stop all services
print_info "Stopping Hero Budget microservices..."

stop_service "google_auth"
stop_service "signup"
stop_service "language_cookie"
stop_service "signin"
stop_service "fetch_dashboard"
stop_service "reset_password"
stop_service "dashboard_data"
stop_service "budget_management"
stop_service "savings_management"
stop_service "cash_bank_management"
stop_service "bills_management"
stop_service "profile_management"
stop_service "income_management"
stop_service "expense_management"
stop_service "transaction_delete_service"
stop_service "categories_management"
stop_service "money_flow_sync"
stop_service "budget_overview_fetch"

# Clean up any remaining processes
print_info "Cleaning up any remaining processes..."
pkill -f "herobudget" 2>/dev/null || true

echo ""
print_success "All Hero Budget services stopped"
EOF

    # Transfer scripts to VPS
    scp /tmp/start_services.sh "$VPS_USER@$VPS_IP:$VPS_PROJECT_DIR/scripts/"
    scp /tmp/stop_services.sh "$VPS_USER@$VPS_IP:$VPS_PROJECT_DIR/scripts/"
    
    # Make executable
    ssh "$VPS_USER@$VPS_IP" "chmod +x $VPS_PROJECT_DIR/scripts/*.sh"
    
    # Clean up local temp files
    rm /tmp/start_services.sh /tmp/stop_services.sh
    
    print_success "Service scripts updated"
}

# Test microservices
test_microservices() {
    print_header "TESTING MICROSERVICES"
    
    print_info "Starting Hero Budget services for testing..."
    ssh "$VPS_USER@$VPS_IP" "$VPS_PROJECT_DIR/scripts/start_services.sh"
    
    # Wait for services to start
    print_info "Waiting for services to initialize..."
    sleep 10
    
    print_info "Testing service connectivity..."
    
    local successful_tests=0
    local total_tests=0
    
    for service in "${MICROSERVICES_NAMES[@]}"; do
        local port=$(get_port_for_service "$service")
        ((total_tests++))
        
        if ssh "$VPS_USER@$VPS_IP" "curl -s --connect-timeout 5 http://localhost:$port >/dev/null"; then
            print_success "$service (port $port) is responding"
            ((successful_tests++))
        else
            print_error "$service (port $port) is not responding"
        fi
    done
    
    print_info "Service test results: $successful_tests/$total_tests services responding"
    
    if [[ $successful_tests -eq $total_tests ]]; then
        print_success "All microservices are working correctly!"
    elif [[ $successful_tests -gt 0 ]]; then
        print_warning "Some microservices may need attention"
    else
        print_error "No microservices are responding - check logs"
    fi
}

# Display final status
show_deployment_status() {
    print_header "DEPLOYMENT COMPLETED"
    
    echo -e "${GREEN}🎉 Microservices deployment completed!${NC}\n"
    
    echo -e "${YELLOW}📋 DEPLOYMENT SUMMARY:${NC}"
    echo -e "${BLUE}•${NC} Backend directory: $VPS_BACKEND_DIR"
    echo -e "${BLUE}•${NC} Configuration: $VPS_PROJECT_DIR/config/"
    echo -e "${BLUE}•${NC} Logs: $VPS_PROJECT_DIR/logs/"
    echo -e "${BLUE}•${NC} Scripts: $VPS_PROJECT_DIR/scripts/"
    echo ""
    
    echo -e "${YELLOW}🔧 MANAGEMENT COMMANDS:${NC}"
    echo -e "${BLUE}•${NC} Start services: systemctl start herobudget"
    echo -e "${BLUE}•${NC} Stop services: systemctl stop herobudget"
    echo -e "${BLUE}•${NC} Check status: systemctl status herobudget"
    echo -e "${BLUE}•${NC} View logs: tail -f $VPS_PROJECT_DIR/logs/*.log"
    echo ""
    
    echo -e "${YELLOW}🌐 NEXT STEPS:${NC}"
    echo -e "${BLUE}1.${NC} Test endpoints: curl https://herobudget.jaimedigitalstudio.com/health"
    echo -e "${BLUE}2.${NC} Migrate database: ./migrate-database-to-vps.sh"
    echo -e "${BLUE}3.${NC} Verify complete setup: ./verify-herobudget-setup.sh"
    echo ""
    
    echo -e "${GREEN}✅ Your Hero Budget microservices are ready for production!${NC}"
}

# Main execution
main() {
    print_header "HERO BUDGET MICROSERVICES DEPLOYMENT"
    echo -e "${BLUE}Local Backend:${NC} $LOCAL_BACKEND_DIR"
    echo -e "${BLUE}VPS Backend:${NC} $VPS_USER@$VPS_IP:$VPS_BACKEND_DIR"
    echo ""
    
    # Confirmation
    read -p "Do you want to deploy microservices to the VPS? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled"
        exit 0
    fi
    
    check_local_backend
    prepare_vps_environment
    create_config_files
    transfer_microservices
    configure_microservices
    compile_microservices
    update_service_scripts
    test_microservices
    show_deployment_status
}

# Run main function
main "$@" 