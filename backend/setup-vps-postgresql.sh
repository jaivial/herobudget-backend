#!/bin/bash

# =============================================================================
# HERO BUDGET - VPS POSTGRESQL SETUP SCRIPT
# =============================================================================
# Configura PostgreSQL en el VPS para Hero Budget
# VPS: 178.16.130.178
# =============================================================================

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
POSTGRES_DB="herobudget"
POSTGRES_USER="herobudget_user"
POSTGRES_PASSWORD="HeroBudget2024!Secure"  # Password seguro por defecto

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

# Configure PostgreSQL on VPS
configure_postgresql_vps() {
    print_header "CONFIGURING POSTGRESQL ON VPS"
    
    ssh "$VPS_USER@$VPS_IP" << EOF
set -e

echo "🔍 Checking PostgreSQL installation..."

# Install PostgreSQL if not present
if ! command -v psql &> /dev/null; then
    echo "📦 Installing PostgreSQL..."
    apt update
    apt install postgresql postgresql-contrib -y
    systemctl enable postgresql
    systemctl start postgresql
else
    echo "✅ PostgreSQL already installed"
fi

# Check if database exists
DB_EXISTS=\$(sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -w $POSTGRES_DB | wc -l)

if [[ \$DB_EXISTS -eq 0 ]]; then
    echo "🗄️  Creating Hero Budget database and user..."
    
    sudo -u postgres psql << 'EOSQL'
-- Create database
CREATE DATABASE $POSTGRES_DB;

-- Create user
CREATE USER $POSTGRES_USER WITH ENCRYPTED PASSWORD '$POSTGRES_PASSWORD';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;

-- Grant usage on schema
\c $POSTGRES_DB
GRANT USAGE ON SCHEMA public TO $POSTGRES_USER;
GRANT CREATE ON SCHEMA public TO $POSTGRES_USER;

-- Grant all privileges on all tables and sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $POSTGRES_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $POSTGRES_USER;

-- Display confirmation
\echo 'Database and user created successfully'
\q
EOSQL

    echo "✅ Database and user created"
else
    echo "✅ Database $POSTGRES_DB already exists"
fi

# Test connection
echo "🔐 Testing database connection..."
sudo -u postgres psql -d $POSTGRES_DB -c "SELECT version();" > /dev/null

if [[ \$? -eq 0 ]]; then
    echo "✅ Database connection successful"
else
    echo "❌ Database connection failed"
    exit 1
fi

# Create backup directory
mkdir -p /opt/hero_budget/backups
chown postgres:postgres /opt/hero_budget/backups

echo "🎉 PostgreSQL setup completed successfully!"
echo ""
echo "Database Details:"
echo "  Database: $POSTGRES_DB"
echo "  User: $POSTGRES_USER"
echo "  Password: $POSTGRES_PASSWORD"
echo "  Backup Dir: /opt/hero_budget/backups"
EOF

    if [[ $? -eq 0 ]]; then
        print_success "PostgreSQL configured successfully on VPS"
        echo ""
        print_info "Database credentials:"
        echo -e "  ${BLUE}Database:${NC} $POSTGRES_DB"
        echo -e "  ${BLUE}User:${NC} $POSTGRES_USER"
        echo -e "  ${BLUE}Password:${NC} $POSTGRES_PASSWORD"
    else
        print_error "PostgreSQL configuration failed"
        exit 1
    fi
}

# Test database connectivity
test_database_connectivity() {
    print_header "TESTING DATABASE CONNECTIVITY"
    
    print_info "Testing PostgreSQL connection from VPS..."
    
    ssh "$VPS_USER@$VPS_IP" << EOF
# Test basic connection
sudo -u postgres psql -d $POSTGRES_DB -c "SELECT 'Hero Budget DB Connection Test' as message, current_timestamp;"

# Test user permissions
sudo -u postgres psql -d $POSTGRES_DB << 'EOSQL'
-- Test table creation
CREATE TABLE IF NOT EXISTS test_table (
    id SERIAL PRIMARY KEY,
    test_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Test data insertion
INSERT INTO test_table (test_message) VALUES ('PostgreSQL is ready for Hero Budget!');

-- Test data selection
SELECT * FROM test_table;

-- Clean up test table
DROP TABLE test_table;

\echo 'All database tests passed successfully!'
EOSQL
EOF

    if [[ $? -eq 0 ]]; then
        print_success "Database connectivity test passed"
    else
        print_error "Database connectivity test failed"
        exit 1
    fi
}

# Update migration script with correct password
update_migration_script() {
    print_header "UPDATING MIGRATION SCRIPT"
    
    if [[ -f "migrate-database-to-vps.sh" ]]; then
        print_info "Updating migration script with correct password..."
        
        # Update the password in the migration script
        sed -i.bak "s/POSTGRES_PASSWORD=\"tu_password_seguro\"/POSTGRES_PASSWORD=\"$POSTGRES_PASSWORD\"/" migrate-database-to-vps.sh
        
        print_success "Migration script updated with correct database credentials"
    else
        print_warning "Migration script not found - you'll need to update it manually"
        print_info "Use password: $POSTGRES_PASSWORD"
    fi
}

# Main execution
main() {
    print_header "VPS POSTGRESQL SETUP FOR HERO BUDGET"
    echo -e "${BLUE}VPS:${NC} $VPS_USER@$VPS_IP"
    echo -e "${BLUE}Database:${NC} $POSTGRES_DB"
    echo -e "${BLUE}User:${NC} $POSTGRES_USER"
    echo ""
    
    # Confirmation
    read -p "Do you want to setup/verify PostgreSQL on the VPS? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Setup cancelled"
        exit 0
    fi
    
    configure_postgresql_vps
    test_database_connectivity
    update_migration_script
    
    print_header "SETUP COMPLETED"
    echo -e "${GREEN}🎉 PostgreSQL is ready for Hero Budget migration!${NC}\n"
    
    echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
    echo -e "${BLUE}1.${NC} Run the migration script: ./migrate-database-to-vps.sh"
    echo -e "${BLUE}2.${NC} Verify Hero Budget services are working"
    echo -e "${BLUE}3.${NC} Update Flutter app configuration"
    echo ""
    
    echo -e "${YELLOW}🔐 IMPORTANT:${NC}"
    echo -e "${BLUE}•${NC} Database password: $POSTGRES_PASSWORD"
    echo -e "${BLUE}•${NC} Save this password in a secure location"
    echo -e "${BLUE}•${NC} You'll need it for future database operations"
}

# Run main function
main "$@" 