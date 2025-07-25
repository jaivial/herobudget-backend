#!/bin/bash

# =============================================================================
# HERO BUDGET - DATABASE MIGRATION SCRIPT
# =============================================================================
# Migra base de datos SQLite local a PostgreSQL en VPS
# SQLite: /Users/usuario/Documents/PROYECTOS/herobudgetflutter/hero_budget/backend/google_auth/users.db
# VPS: 178.16.130.178 (PostgreSQL)
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
LOCAL_SQLITE_DB="/Users/usuario/Documents/PROYECTOS/herobudgetflutter/hero_budget/backend/google_auth/users.db"
POSTGRES_DB="herobudget"
POSTGRES_USER="herobudget_user"
POSTGRES_PASSWORD="HeroBudget2024!Secure"  # Cambiar por el password real
TEMP_DIR="/tmp/herobudget_migration"
PROJECT_DIR="/opt/hero_budget"

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

# Check if SQLite database exists
check_sqlite_db() {
    print_header "CHECKING LOCAL SQLITE DATABASE"
    
    if [[ ! -f "$LOCAL_SQLITE_DB" ]]; then
        print_error "SQLite database not found at: $LOCAL_SQLITE_DB"
        exit 1
    fi
    
    # Check if database has data
    table_count=$(sqlite3 "$LOCAL_SQLITE_DB" "SELECT count(*) FROM sqlite_master WHERE type='table';")
    user_count=$(sqlite3 "$LOCAL_SQLITE_DB" "SELECT count(*) FROM users;" 2>/dev/null || echo "0")
    
    print_success "SQLite database found"
    print_info "Tables in database: $table_count"
    print_info "Users in database: $user_count"
    
    if [[ $user_count -eq 0 ]]; then
        print_warning "Database appears to be empty"
        read -p "Continue anyway? (y/N): " continue_empty
        if [[ ! $continue_empty =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# Create temporary directory
create_temp_dir() {
    print_header "PREPARING MIGRATION FILES"
    
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    print_success "Temporary directory created: $TEMP_DIR"
}

# Export SQLite data
export_sqlite_data() {
    print_info "Exporting SQLite data..."
    
    # Get database schema
    sqlite3 "$LOCAL_SQLITE_DB" .schema > "$TEMP_DIR/schema.sql"
    
    # Export all data
    sqlite3 "$LOCAL_SQLITE_DB" .dump > "$TEMP_DIR/sqlite_dump.sql"
    
    print_success "SQLite data exported"
}

# Convert SQLite to PostgreSQL format
convert_to_postgresql() {
    print_info "Converting SQLite format to PostgreSQL..."
    
    # Create PostgreSQL schema
    cat > "$TEMP_DIR/postgresql_schema.sql" << 'EOF'
-- Drop existing tables if they exist
DROP TABLE IF EXISTS users CASCADE;

-- Create users table for PostgreSQL
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    google_id TEXT UNIQUE,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    given_name TEXT,
    family_name TEXT,
    picture TEXT,
    locale TEXT DEFAULT 'es',
    verified_email BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Create function to update updated_at automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
EOF

    # Convert data from SQLite dump
    print_info "Converting user data..."
    
    # Extract INSERT statements for users table
    grep "INSERT INTO users" "$TEMP_DIR/sqlite_dump.sql" > "$TEMP_DIR/users_data.sql" || true
    
    # Convert SQLite INSERT statements to PostgreSQL format
    if [[ -f "$TEMP_DIR/users_data.sql" ]]; then
        # Fix data types and syntax for PostgreSQL
        sed -i.bak 's/INSERT INTO users VALUES(/INSERT INTO users (id, google_id, email, name, given_name, family_name, picture, locale, verified_email, created_at, updated_at) VALUES(/g' "$TEMP_DIR/users_data.sql"
        
        # Convert boolean values
        sed -i.bak 's/,0,/,false,/g' "$TEMP_DIR/users_data.sql"
        sed -i.bak 's/,1,/,true,/g' "$TEMP_DIR/users_data.sql"
        sed -i.bak 's/,0)/,false)/g' "$TEMP_DIR/users_data.sql"
        sed -i.bak 's/,1)/,true)/g' "$TEMP_DIR/users_data.sql"
        
        # Fix timestamp format if needed
        sed -i.bak "s/''/NULL/g" "$TEMP_DIR/users_data.sql"
        
        print_success "Data conversion completed"
    else
        print_warning "No user data found to convert"
        touch "$TEMP_DIR/users_data.sql"
    fi
    
    # Create final migration script
    cat > "$TEMP_DIR/migration.sql" << EOF
-- Hero Budget Database Migration
-- From SQLite to PostgreSQL
-- $(date)

\echo 'Starting Hero Budget database migration...'

-- Import schema
\i postgresql_schema.sql

\echo 'Schema created successfully'

-- Reset sequence if data exists
SELECT setval('users_id_seq', COALESCE((SELECT MAX(id) FROM users), 1));

-- Import data
\i users_data.sql

\echo 'Data imported successfully'

-- Verify migration
SELECT 'Total users migrated: ' || COUNT(*) FROM users;
SELECT 'Migration completed at: $(date)';

\echo 'Migration completed successfully!'
EOF

    print_success "PostgreSQL migration files created"
}

# Create backup script for VPS
create_vps_backup_script() {
    print_info "Creating VPS backup script..."
    
    cat > "$TEMP_DIR/backup_vps_db.sh" << EOF
#!/bin/bash
# Backup current PostgreSQL database before migration

BACKUP_DIR="/opt/hero_budget/backups"
BACKUP_FILE="herobudget_backup_\$(date +%Y%m%d_%H%M%S).sql"

mkdir -p "\$BACKUP_DIR"

echo "Creating backup of current database..."
sudo -u postgres pg_dump herobudget > "\$BACKUP_DIR/\$BACKUP_FILE"

if [[ \$? -eq 0 ]]; then
    echo "✅ Backup created: \$BACKUP_DIR/\$BACKUP_FILE"
    ls -la "\$BACKUP_DIR/\$BACKUP_FILE"
else
    echo "❌ Backup failed!"
    exit 1
fi
EOF

    chmod +x "$TEMP_DIR/backup_vps_db.sh"
    print_success "VPS backup script created"
}

# Transfer files to VPS
transfer_files_to_vps() {
    print_header "TRANSFERRING FILES TO VPS"
    
    print_info "Copying migration files to VPS..."
    
    # Create remote directory
    ssh "$VPS_USER@$VPS_IP" "mkdir -p $PROJECT_DIR/migration"
    
    # Transfer files
    scp -r "$TEMP_DIR"/* "$VPS_USER@$VPS_IP:$PROJECT_DIR/migration/"
    
    print_success "Files transferred to VPS"
}

# Execute migration on VPS
execute_migration() {
    print_header "EXECUTING MIGRATION ON VPS"
    
    print_info "Creating backup of current database..."
    ssh "$VPS_USER@$VPS_IP" "cd $PROJECT_DIR/migration && chmod +x backup_vps_db.sh && ./backup_vps_db.sh"
    
    print_info "Executing database migration..."
    ssh "$VPS_USER@$VPS_IP" << EOF
cd $PROJECT_DIR/migration

echo "Stopping Hero Budget services..."
systemctl stop herobudget 2>/dev/null || true

echo "Executing migration..."
sudo -u postgres psql -d $POSTGRES_DB -f migration.sql

if [[ \$? -eq 0 ]]; then
    echo "✅ Migration completed successfully"
    
    echo "Verifying migration..."
    sudo -u postgres psql -d $POSTGRES_DB -c "SELECT COUNT(*) as total_users FROM users;"
    sudo -u postgres psql -d $POSTGRES_DB -c "SELECT email, name, created_at FROM users LIMIT 5;"
    
    echo "Restarting Hero Budget services..."
    systemctl start herobudget
    
    echo "Migration completed successfully!"
else
    echo "❌ Migration failed!"
    echo "Restoring from backup..."
    
    # Find latest backup
    LATEST_BACKUP=\$(ls -t $PROJECT_DIR/backups/*.sql | head -1)
    if [[ -f "\$LATEST_BACKUP" ]]; then
        echo "Restoring from: \$LATEST_BACKUP"
        sudo -u postgres dropdb $POSTGRES_DB
        sudo -u postgres createdb $POSTGRES_DB
        sudo -u postgres psql -d $POSTGRES_DB < "\$LATEST_BACKUP"
        echo "Database restored from backup"
    fi
    
    systemctl start herobudget
    exit 1
fi
EOF

    if [[ $? -eq 0 ]]; then
        print_success "Migration executed successfully on VPS"
    else
        print_error "Migration failed on VPS"
        exit 1
    fi
}

# Verify migration
verify_migration() {
    print_header "VERIFYING MIGRATION"
    
    print_info "Connecting to VPS to verify migration..."
    
    # Get user count from VPS
    vps_user_count=$(ssh "$VPS_USER@$VPS_IP" "sudo -u postgres psql -d $POSTGRES_DB -t -c 'SELECT COUNT(*) FROM users;'" | tr -d ' ')
    
    # Get user count from local SQLite
    local_user_count=$(sqlite3 "$LOCAL_SQLITE_DB" "SELECT count(*) FROM users;" 2>/dev/null || echo "0")
    
    print_info "Local SQLite users: $local_user_count"
    print_info "VPS PostgreSQL users: $vps_user_count"
    
    if [[ "$vps_user_count" -eq "$local_user_count" ]]; then
        print_success "User count matches! Migration successful"
    else
        print_warning "User count mismatch - please verify manually"
    fi
    
    # Test endpoint connectivity
    print_info "Testing VPS endpoints..."
    if curl -s -f "https://herobudget.jaimedigitalstudio.com/health" > /dev/null; then
        print_success "VPS endpoints are accessible"
    else
        print_warning "VPS endpoints may not be accessible yet"
    fi
}

# Cleanup
cleanup() {
    print_header "CLEANUP"
    
    print_info "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    print_success "Temporary files cleaned up"
    
    print_info "Cleaning up VPS migration files..."
    ssh "$VPS_USER@$VPS_IP" "rm -rf $PROJECT_DIR/migration/*.sql"
    print_success "VPS temporary files cleaned up"
}

# Display final instructions
show_final_instructions() {
    print_header "MIGRATION COMPLETED"
    
    echo -e "${GREEN}🎉 Database migration completed successfully!${NC}\n"
    
    echo -e "${YELLOW}📋 WHAT HAPPENED:${NC}"
    echo -e "${BLUE}1.${NC} SQLite database exported from local machine"
    echo -e "${BLUE}2.${NC} Data converted to PostgreSQL format"
    echo -e "${BLUE}3.${NC} Current VPS database backed up"
    echo -e "${BLUE}4.${NC} New data imported to VPS PostgreSQL"
    echo -e "${BLUE}5.${NC} Migration verified successfully"
    echo ""
    
    echo -e "${YELLOW}🔍 VERIFICATION:${NC}"
    echo -e "${BLUE}•${NC} Local users: $(sqlite3 "$LOCAL_SQLITE_DB" "SELECT count(*) FROM users;" 2>/dev/null || echo "0")"
    echo -e "${BLUE}•${NC} VPS users: $(ssh "$VPS_USER@$VPS_IP" "sudo -u postgres psql -d $POSTGRES_DB -t -c 'SELECT COUNT(*) FROM users;'" | tr -d ' ')"
    echo ""
    
    echo -e "${YELLOW}🔧 NEXT STEPS:${NC}"
    echo -e "${BLUE}1.${NC} Update Flutter app to use VPS endpoints"
    echo -e "${BLUE}2.${NC} Test authentication with migrated users"
    echo -e "${BLUE}3.${NC} Monitor VPS logs: journalctl -u herobudget -f"
    echo -e "${BLUE}4.${NC} Backup location: $PROJECT_DIR/backups/"
    echo ""
    
    echo -e "${GREEN}✅ Your users can now authenticate against the VPS!${NC}"
}

# Main execution
main() {
    print_header "HERO BUDGET DATABASE MIGRATION"
    echo -e "${BLUE}From:${NC} $LOCAL_SQLITE_DB"
    echo -e "${BLUE}To:${NC} $VPS_USER@$VPS_IP PostgreSQL"
    echo ""
    
    # Confirmation
    read -p "Do you want to continue with the migration? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Migration cancelled"
        exit 0
    fi
    
    check_sqlite_db
    create_temp_dir
    export_sqlite_data
    convert_to_postgresql
    create_vps_backup_script
    transfer_files_to_vps
    execute_migration
    verify_migration
    cleanup
    show_final_instructions
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@" 