#!/bin/bash

# =============================================================================
# HERO BUDGET - NGINX INSTALLATION & CONFIGURATION SCRIPT
# =============================================================================
# VPS: 178.16.130.178 (root user)
# Domain: herobudget.jaimedigitalstudio.com
# Project Directory: /opt/hero_budget
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="herobudget.jaimedigitalstudio.com"
EMAIL="admin@jaimedigitalstudio.com"  # Change this to your email
PROJECT_DIR="/opt/hero_budget"
NGINX_CONFIG_FILE="nginx-herobudget-config.conf"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
CONFIG_NAME="herobudget"

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

# Check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Update system packages
update_system() {
    print_header "UPDATING SYSTEM PACKAGES"
    apt update && apt upgrade -y
    print_success "System packages updated"
}

# Install required packages
install_packages() {
    print_header "INSTALLING REQUIRED PACKAGES"
    
    # Install nginx if not present
    if ! command -v nginx &> /dev/null; then
        print_info "Installing nginx..."
        apt install nginx -y
    else
        print_success "Nginx already installed"
    fi
    
    # Install certbot if not present
    if ! command -v certbot &> /dev/null; then
        print_info "Installing certbot..."
        apt install certbot python3-certbot-nginx -y
    else
        print_success "Certbot already installed"
    fi
    
    # Install curl for testing
    if ! command -v curl &> /dev/null; then
        print_info "Installing curl..."
        apt install curl -y
    else
        print_success "Curl already installed"
    fi
    
    print_success "All required packages installed"
}

# Create project directory
create_directories() {
    print_header "CREATING PROJECT DIRECTORIES"
    
    mkdir -p "$PROJECT_DIR"
    mkdir -p "$PROJECT_DIR/logs"
    mkdir -p "$PROJECT_DIR/scripts"
    mkdir -p "$PROJECT_DIR/backend"
    
    print_success "Project directories created at $PROJECT_DIR"
}

# Install nginx configuration
install_nginx_config() {
    print_header "INSTALLING NGINX CONFIGURATION"
    
    # Check if config file exists
    if [[ ! -f "$NGINX_CONFIG_FILE" ]]; then
        print_error "Configuration file $NGINX_CONFIG_FILE not found!"
        print_info "Please ensure nginx-herobudget-config.conf is in the current directory"
        exit 1
    fi
    
    # Copy configuration to sites-available
    cp "$NGINX_CONFIG_FILE" "$NGINX_SITES_AVAILABLE/$CONFIG_NAME"
    print_success "Configuration copied to $NGINX_SITES_AVAILABLE/$CONFIG_NAME"
    
    # Remove default nginx site if enabled
    if [[ -L "$NGINX_SITES_ENABLED/default" ]]; then
        rm "$NGINX_SITES_ENABLED/default"
        print_success "Default nginx site disabled"
    fi
    
    # Enable Hero Budget site
    if [[ ! -L "$NGINX_SITES_ENABLED/$CONFIG_NAME" ]]; then
        ln -s "$NGINX_SITES_AVAILABLE/$CONFIG_NAME" "$NGINX_SITES_ENABLED/"
        print_success "Hero Budget site enabled"
    else
        print_success "Hero Budget site already enabled"
    fi
    
    # Test nginx configuration
    if nginx -t; then
        print_success "Nginx configuration test passed"
    else
        print_error "Nginx configuration test failed!"
        exit 1
    fi
}

# Configure SSL with Let's Encrypt
configure_ssl() {
    print_header "CONFIGURING SSL WITH LET'S ENCRYPT"
    
    # Check if certificates already exist
    if [[ -d "/etc/letsencrypt/live/$DOMAIN" ]]; then
        print_warning "SSL certificates already exist for $DOMAIN"
        read -p "Do you want to renew them? (y/N): " renew
        if [[ $renew =~ ^[Yy]$ ]]; then
            certbot renew --nginx
            print_success "SSL certificates renewed"
        else
            print_info "Skipping SSL configuration"
            return
        fi
    else
        print_info "Obtaining SSL certificate for $DOMAIN..."
        
        # Temporarily disable SSL in nginx config for initial cert generation
        sed -i 's/listen 443 ssl/listen 443/' "$NGINX_SITES_AVAILABLE/$CONFIG_NAME"
        sed -i 's/ssl_certificate/#ssl_certificate/g' "$NGINX_SITES_AVAILABLE/$CONFIG_NAME"
        
        # Reload nginx
        systemctl reload nginx
        
        # Get certificate
        if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL"; then
            print_success "SSL certificate obtained successfully"
            
            # Restore SSL configuration
            sed -i 's/listen 443/listen 443 ssl/' "$NGINX_SITES_AVAILABLE/$CONFIG_NAME"
            sed -i 's/#ssl_certificate/ssl_certificate/g' "$NGINX_SITES_AVAILABLE/$CONFIG_NAME"
            
        else
            print_error "Failed to obtain SSL certificate"
            exit 1
        fi
    fi
}

# Start and enable services
enable_services() {
    print_header "ENABLING SERVICES"
    
    # Enable and start nginx
    systemctl enable nginx
    systemctl start nginx
    print_success "Nginx service enabled and started"
    
    # Setup automatic certificate renewal
    if ! crontab -l | grep -q "certbot renew"; then
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        print_success "Automatic SSL renewal configured"
    else
        print_success "Automatic SSL renewal already configured"
    fi
}

# Create service management scripts
create_service_scripts() {
    print_header "CREATING SERVICE MANAGEMENT SCRIPTS"
    
    # Copy start/stop scripts to project directory
    if [[ -f "start_services.sh" ]]; then
        cp start_services.sh "$PROJECT_DIR/scripts/"
        chmod +x "$PROJECT_DIR/scripts/start_services.sh"
        print_success "start_services.sh copied to $PROJECT_DIR/scripts/"
    fi
    
    if [[ -f "stop_services.sh" ]]; then
        cp stop_services.sh "$PROJECT_DIR/scripts/"
        chmod +x "$PROJECT_DIR/scripts/stop_services.sh"
        print_success "stop_services.sh copied to $PROJECT_DIR/scripts/"
    fi
    
    # Create systemd service for Hero Budget services
    cat > /etc/systemd/system/herobudget.service << 'EOF'
[Unit]
Description=Hero Budget Microservices
After=network.target

[Service]
Type=forking
User=root
WorkingDirectory=/opt/hero_budget
ExecStart=/opt/hero_budget/scripts/start_services.sh
ExecStop=/opt/hero_budget/scripts/stop_services.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable herobudget
    print_success "Hero Budget systemd service created and enabled"
}

# Test nginx configuration
test_configuration() {
    print_header "TESTING CONFIGURATION"
    
    # Test nginx syntax
    if nginx -t; then
        print_success "Nginx configuration syntax is valid"
    else
        print_error "Nginx configuration syntax error!"
        return 1
    fi
    
    # Reload nginx
    systemctl reload nginx
    print_success "Nginx configuration reloaded"
    
    # Test basic connectivity
    print_info "Testing basic connectivity..."
    
    # Test HTTP redirect
    if curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN/health" | grep -q "301\|200"; then
        print_success "HTTP connectivity test passed"
    else
        print_warning "HTTP connectivity test failed"
    fi
    
    # Test HTTPS
    if curl -s -k -o /dev/null -w "%{http_code}" "https://$DOMAIN/health" | grep -q "200"; then
        print_success "HTTPS connectivity test passed"
    else
        print_warning "HTTPS connectivity test failed (this is normal if services aren't running yet)"
    fi
}

# Display final instructions
show_final_instructions() {
    print_header "INSTALLATION COMPLETE"
    
    echo -e "${GREEN}🎉 Nginx configuration for Hero Budget has been installed successfully!${NC}\n"
    
    echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
    echo -e "${BLUE}1.${NC} Deploy your Go microservices to: $PROJECT_DIR/backend/"
    echo -e "${BLUE}2.${NC} Start Hero Budget services:"
    echo -e "   systemctl start herobudget"
    echo -e "   # OR manually:"
    echo -e "   cd $PROJECT_DIR && ./scripts/start_services.sh"
    echo ""
    echo -e "${BLUE}3.${NC} Test your endpoints:"
    echo -e "   curl https://$DOMAIN/health"
    echo -e "   curl -X POST https://$DOMAIN/auth/google"
    echo ""
    echo -e "${YELLOW}📊 MONITORING:${NC}"
    echo -e "${BLUE}•${NC} Nginx logs: /var/log/nginx/herobudget_*.log"
    echo -e "${BLUE}•${NC} Service status: systemctl status herobudget"
    echo -e "${BLUE}•${NC} Service logs: journalctl -u herobudget -f"
    echo ""
    echo -e "${YELLOW}🔧 MANAGEMENT COMMANDS:${NC}"
    echo -e "${BLUE}•${NC} Start services: systemctl start herobudget"
    echo -e "${BLUE}•${NC} Stop services: systemctl stop herobudget"
    echo -e "${BLUE}•${NC} Restart services: systemctl restart herobudget"
    echo -e "${BLUE}•${NC} Reload nginx: systemctl reload nginx"
    echo ""
    echo -e "${GREEN}✅ Your Hero Budget backend is ready for production!${NC}"
}

# Main execution
main() {
    print_header "HERO BUDGET NGINX INSTALLATION"
    
    check_root
    update_system
    install_packages
    create_directories
    install_nginx_config
    configure_ssl
    enable_services
    create_service_scripts
    test_configuration
    show_final_instructions
}

# Run main function
main "$@" 