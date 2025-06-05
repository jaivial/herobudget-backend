#!/bin/bash

# =============================================================================
# HERO BUDGET - VERIFICATION & TROUBLESHOOTING SCRIPT
# =============================================================================
# VPS: 178.16.130.178 (root user)
# Domain: herobudget.jaimedigitalstudio.com
# Project Directory: /opt/hero_budget
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="herobudget.jaimedigitalstudio.com"
PROJECT_DIR="/opt/hero_budget"

# Service ports based on start_services.sh
declare -A SERVICES=(
    ["google_auth"]="8081:/auth/google"
    ["signup"]="8082:/signup"
    ["language_cookie"]="8083:/language"
    ["signin"]="8084:/signin"
    ["fetch_dashboard"]="8085:/user"
    ["reset_password"]="8086:/reset-password"
    ["dashboard_data"]="8087:/dashboard-data"
    ["budget_management"]="8088:/budget"
    ["savings_management"]="8089:/savings"
    ["cash_bank_management"]="8090:/cash-bank"
    ["bills_management"]="8091:/bills"
    ["profile_management"]="8092:/profile"
    ["income_management"]="8093:/incomes"
    ["expense_management"]="8094:/expenses"
    ["transaction_delete_service"]="8095:/transaction-delete"
    ["categories_management"]="8096:/categories"
    ["money_flow_sync"]="8097:/money-flow-sync"
    ["budget_overview_fetch"]="8098:/budget-overview"
)

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

# Check system resources
check_system_resources() {
    print_header "SYSTEM RESOURCES CHECK"
    
    # Check CPU usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo -e "${BLUE}CPU Usage:${NC} ${cpu_usage}%"
    
    # Check memory usage
    memory_info=$(free -h | grep "Mem:")
    echo -e "${BLUE}Memory:${NC} $memory_info"
    
    # Check disk usage
    disk_usage=$(df -h / | tail -1 | awk '{print $5}')
    echo -e "${BLUE}Disk Usage:${NC} $disk_usage"
    
    # Check available ports
    print_info "Checking if required ports are available..."
    for service in "${!SERVICES[@]}"; do
        port=$(echo "${SERVICES[$service]}" | cut -d':' -f1)
        if lsof -i :$port > /dev/null 2>&1; then
            print_success "Port $port is in use (service: $service)"
        else
            print_warning "Port $port is free (service: $service not running)"
        fi
    done
    
    echo ""
}

# Check nginx status
check_nginx() {
    print_header "NGINX STATUS CHECK"
    
    # Check if nginx is running
    if systemctl is-active --quiet nginx; then
        print_success "Nginx is running"
    else
        print_error "Nginx is not running"
        print_info "Try: systemctl start nginx"
        return 1
    fi
    
    # Check nginx configuration
    if nginx -t > /dev/null 2>&1; then
        print_success "Nginx configuration is valid"
    else
        print_error "Nginx configuration has errors"
        nginx -t
        return 1
    fi
    
    # Check if Hero Budget site is enabled
    if [[ -L "/etc/nginx/sites-enabled/herobudget" ]]; then
        print_success "Hero Budget site is enabled"
    else
        print_error "Hero Budget site is not enabled"
        print_info "Try: ln -s /etc/nginx/sites-available/herobudget /etc/nginx/sites-enabled/"
    fi
    
    echo ""
}

# Check SSL certificates
check_ssl() {
    print_header "SSL CERTIFICATES CHECK"
    
    # Check if certificates exist
    if [[ -d "/etc/letsencrypt/live/$DOMAIN" ]]; then
        print_success "SSL certificates exist for $DOMAIN"
        
        # Check certificate expiry
        cert_expiry=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$DOMAIN/cert.pem" | cut -d= -f2)
        print_info "Certificate expires: $cert_expiry"
        
        # Check if renewal is needed soon (30 days)
        if openssl x509 -checkend 2592000 -noout -in "/etc/letsencrypt/live/$DOMAIN/cert.pem" > /dev/null; then
            print_success "Certificate is valid for more than 30 days"
        else
            print_warning "Certificate expires within 30 days - consider renewal"
            print_info "Try: certbot renew"
        fi
    else
        print_error "SSL certificates not found for $DOMAIN"
        print_info "Try: certbot --nginx -d $DOMAIN"
    fi
    
    echo ""
}

# Check Hero Budget services
check_services() {
    print_header "HERO BUDGET SERVICES CHECK"
    
    # Check systemd service
    if systemctl is-active --quiet herobudget; then
        print_success "Hero Budget systemd service is running"
    else
        print_warning "Hero Budget systemd service is not running"
        print_info "Try: systemctl start herobudget"
    fi
    
    # Check individual microservices
    print_info "Checking individual microservices..."
    local running_count=0
    local total_count=${#SERVICES[@]}
    
    for service in "${!SERVICES[@]}"; do
        port=$(echo "${SERVICES[$service]}" | cut -d':' -f1)
        if lsof -i :$port > /dev/null 2>&1; then
            print_success "$service (port $port) is running"
            ((running_count++))
        else
            print_error "$service (port $port) is not running"
        fi
    done
    
    echo ""
    print_info "Services running: $running_count/$total_count"
    
    if [[ $running_count -eq $total_count ]]; then
        print_success "All microservices are running!"
    elif [[ $running_count -gt 0 ]]; then
        print_warning "Some microservices are not running"
    else
        print_error "No microservices are running"
        print_info "Try: cd $PROJECT_DIR && ./scripts/start_services.sh"
    fi
    
    echo ""
}

# Test endpoints
test_endpoints() {
    print_header "ENDPOINT CONNECTIVITY TEST"
    
    # Test health endpoint
    print_info "Testing health endpoint..."
    if curl -s -f "https://$DOMAIN/health" > /dev/null; then
        print_success "Health endpoint is accessible"
    else
        print_error "Health endpoint is not accessible"
    fi
    
    # Test critical endpoints
    local critical_endpoints=(
        "/auth/google:Google Authentication"
        "/signup:User Signup"
        "/signin:User Signin"
        "/incomes:Income Management"
        "/expenses:Expense Management"
        "/budget-overview:Budget Overview"
    )
    
    print_info "Testing critical endpoints..."
    for endpoint_info in "${critical_endpoints[@]}"; do
        endpoint=$(echo "$endpoint_info" | cut -d':' -f1)
        description=$(echo "$endpoint_info" | cut -d':' -f2)
        
        # Test with HTTP status code only
        status_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN$endpoint" || echo "000")
        
        if [[ "$status_code" =~ ^[2-4][0-9][0-9]$ ]]; then
            print_success "$description ($endpoint) - Status: $status_code"
        else
            print_error "$description ($endpoint) - Status: $status_code"
        fi
    done
    
    echo ""
}

# Check logs for errors
check_logs() {
    print_header "LOG ANALYSIS"
    
    # Check nginx error logs
    print_info "Checking nginx error logs (last 10 lines)..."
    if [[ -f "/var/log/nginx/herobudget_error.log" ]]; then
        tail -10 /var/log/nginx/herobudget_error.log | while read line; do
            if [[ -n "$line" ]]; then
                print_warning "Nginx Error: $line"
            fi
        done
    else
        print_info "No nginx error log found (this is good!)"
    fi
    
    # Check systemd service logs
    print_info "Checking Hero Budget service logs (last 5 lines)..."
    systemctl status herobudget --lines=5 --no-pager | tail -5 | while read line; do
        if [[ -n "$line" ]]; then
            print_info "Service: $line"
        fi
    done
    
    echo ""
}

# Performance check
check_performance() {
    print_header "PERFORMANCE CHECK"
    
    # Test response times
    print_info "Testing response times..."
    
    local endpoints=("/health" "/auth/google" "/signup")
    
    for endpoint in "${endpoints[@]}"; do
        response_time=$(curl -s -o /dev/null -w "%{time_total}" "https://$DOMAIN$endpoint" 2>/dev/null || echo "timeout")
        
        if [[ "$response_time" != "timeout" ]]; then
            # Convert to milliseconds
            ms_time=$(echo "$response_time * 1000" | bc 2>/dev/null || echo "unknown")
            print_info "$endpoint: ${ms_time}ms"
        else
            print_warning "$endpoint: timeout"
        fi
    done
    
    echo ""
}

# Generate troubleshooting report
generate_troubleshooting_report() {
    print_header "TROUBLESHOOTING SUGGESTIONS"
    
    # Check if any services are down
    local down_services=()
    for service in "${!SERVICES[@]}"; do
        port=$(echo "${SERVICES[$service]}" | cut -d':' -f1)
        if ! lsof -i :$port > /dev/null 2>&1; then
            down_services+=("$service")
        fi
    done
    
    if [[ ${#down_services[@]} -gt 0 ]]; then
        print_warning "Services that are down:"
        for service in "${down_services[@]}"; do
            port=$(echo "${SERVICES[$service]}" | cut -d':' -f1)
            path=$(echo "${SERVICES[$service]}" | cut -d':' -f2)
            echo -e "  ${RED}•${NC} $service (port $port, path $path)"
        done
        
        echo ""
        print_info "To fix service issues:"
        echo -e "  ${BLUE}1.${NC} Check service logs: journalctl -u herobudget -f"
        echo -e "  ${BLUE}2.${NC} Restart services: systemctl restart herobudget"
        echo -e "  ${BLUE}3.${NC} Manual start: cd $PROJECT_DIR && ./scripts/start_services.sh"
        echo -e "  ${BLUE}4.${NC} Check Go build errors in service directories"
    fi
    
    # Check nginx issues
    if ! systemctl is-active --quiet nginx; then
        print_warning "Nginx is not running:"
        echo -e "  ${BLUE}1.${NC} Start nginx: systemctl start nginx"
        echo -e "  ${BLUE}2.${NC} Check configuration: nginx -t"
        echo -e "  ${BLUE}3.${NC} Check logs: journalctl -u nginx -f"
    fi
    
    # Check SSL issues
    if [[ ! -d "/etc/letsencrypt/live/$DOMAIN" ]]; then
        print_warning "SSL certificates missing:"
        echo -e "  ${BLUE}1.${NC} Generate certificates: certbot --nginx -d $DOMAIN"
        echo -e "  ${BLUE}2.${NC} Check DNS settings for $DOMAIN"
        echo -e "  ${BLUE}3.${NC} Ensure domain points to this server ($(curl -s ifconfig.me))"
    fi
    
    echo ""
}

# Main verification function
main() {
    print_header "HERO BUDGET PRODUCTION VERIFICATION"
    echo -e "${BLUE}Domain:${NC} $DOMAIN"
    echo -e "${BLUE}Project Directory:${NC} $PROJECT_DIR"
    echo -e "${BLUE}Timestamp:${NC} $(date)"
    echo ""
    
    check_system_resources
    check_nginx
    check_ssl
    check_services
    test_endpoints
    check_logs
    check_performance
    generate_troubleshooting_report
    
    print_header "VERIFICATION COMPLETE"
    print_info "For detailed monitoring, use:"
    echo -e "  ${BLUE}•${NC} Watch logs: tail -f /var/log/nginx/herobudget_*.log"
    echo -e "  ${BLUE}•${NC} Service status: systemctl status herobudget"
    echo -e "  ${BLUE}•${NC} Real-time monitoring: watch -n 2 'systemctl status herobudget'"
    echo ""
}

# Command line options
case "${1:-}" in
    --services-only)
        check_services
        ;;
    --nginx-only)
        check_nginx
        ;;
    --ssl-only)
        check_ssl
        ;;
    --endpoints-only)
        test_endpoints
        ;;
    --performance-only)
        check_performance
        ;;
    --help)
        echo "Hero Budget Verification Script"
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  --services-only     Check only Hero Budget services"
        echo "  --nginx-only        Check only nginx status"
        echo "  --ssl-only          Check only SSL certificates"
        echo "  --endpoints-only    Test only endpoint connectivity"
        echo "  --performance-only  Check only performance metrics"
        echo "  --help              Show this help message"
        echo ""
        echo "Run without options for complete verification"
        ;;
    *)
        main
        ;;
esac 