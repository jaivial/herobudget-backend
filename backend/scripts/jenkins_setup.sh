#!/bin/bash
# Script de Instalación y Configuración Jenkins - Hero Budget
# Versión: 2.0
# Uso: ./jenkins_setup.sh [--install|--configure|--full]

set -e

# Configuración
VPS_HOST="178.16.130.178"
VPS_USER="root"
JENKINS_PORT="8080"
JENKINS_HOME="/var/lib/jenkins"
REPO_URL="https://github.com/TU_USUARIO/herobudget-backend.git"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}${1}${NC}"
    echo "=================================================================="
}

# Función de ayuda
show_help() {
    cat << EOF
🔧 Script de Configuración Jenkins - Hero Budget

Uso: $0 [opción]

Opciones:
  --install     Solo instalar Jenkins
  --configure   Solo configurar (requiere Jenkins instalado)
  --full        Instalación y configuración completa
  --help        Mostrar esta ayuda

Sin argumentos ejecuta instalación completa.

EOF
}

# Verificar conexión SSH
check_ssh() {
    log_info "Verificando conexión SSH al VPS..."
    if ssh -o ConnectTimeout=10 $VPS_USER@$VPS_HOST "echo 'SSH OK'" >/dev/null 2>&1; then
        log_success "Conexión SSH establecida"
        return 0
    else
        log_error "No se puede conectar al VPS"
        return 1
    fi
}

# Instalar Jenkins
install_jenkins() {
    log_header "📦 INSTALANDO JENKINS"
    
    log_info "Instalando Jenkins en el VPS..."
    
    ssh $VPS_USER@$VPS_HOST << 'EOF'
        echo "🔄 Actualizando sistema..."
        apt update && apt upgrade -y
        
        echo "☕ Instalando Java (requerido para Jenkins)..."
        apt install -y openjdk-11-jdk
        
        echo "📥 Agregando repositorio Jenkins..."
        wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -
        echo "deb https://pkg.jenkins.io/debian binary/" > /etc/apt/sources.list.d/jenkins.list
        
        echo "📦 Instalando Jenkins..."
        apt update
        apt install -y jenkins
        
        echo "🚀 Iniciando y habilitando Jenkins..."
        systemctl start jenkins
        systemctl enable jenkins
        
        echo "🔥 Configurando firewall para Jenkins..."
        ufw allow 8080/tcp || echo "UFW no disponible o ya configurado"
        
        echo "⏱️ Esperando que Jenkins se inicie completamente..."
        sleep 30
        
        echo "🔑 Obteniendo password inicial de Jenkins..."
        if [ -f "/var/lib/jenkins/secrets/initialAdminPassword" ]; then
            echo "=================================================="
            echo "🔐 PASSWORD INICIAL DE JENKINS:"
            cat /var/lib/jenkins/secrets/initialAdminPassword
            echo "=================================================="
        else
            echo "⚠️ No se pudo obtener password inicial"
        fi
        
        echo "✅ Jenkins instalado correctamente"
        echo "🌐 Accede a: http://$(curl -s ifconfig.me):8080"
EOF
    
    if [ $? -eq 0 ]; then
        log_success "Jenkins instalado exitosamente"
        return 0
    else
        log_error "Error instalando Jenkins"
        return 1
    fi
}

# Configurar Jenkins para Hero Budget
configure_jenkins() {
    log_header "⚙️ CONFIGURANDO JENKINS PARA HERO BUDGET"
    
    log_info "Configurando Jenkins..."
    
    ssh $VPS_USER@$VPS_HOST << 'EOF'
        echo "🔧 Creando directorio de trabajos..."
        mkdir -p /var/lib/jenkins/jobs/herobudget-backend
        
        echo "📋 Creando configuración del proyecto..."
        cat > /var/lib/jenkins/jobs/herobudget-backend/config.xml << 'XMLEOF'
<?xml version='1.1' encoding='UTF-8'?>
<project>
  <actions/>
  <description>Despliegue automático del backend Hero Budget</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty plugin="github@1.34.1">
      <projectUrl>https://github.com/TU_USUARIO/herobudget-backend/</projectUrl>
      <displayName/>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
  </properties>
  <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3">
    <configVersion>2</configVersion>
    <userRemoteConfigs>
      <hudson.plugins.git.UserRemoteConfig>
        <url>https://github.com/TU_USUARIO/herobudget-backend.git</url>
      </hudson.plugins.git.UserRemoteConfig>
    </userRemoteConfigs>
    <branches>
      <hudson.plugins.git.BranchSpec>
        <name>*/main</name>
      </hudson.plugins.git.BranchSpec>
    </branches>
    <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
    <submoduleCfg class="empty-list"/>
    <extensions/>
  </scm>
  <triggers>
    <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.1">
      <spec></spec>
    </com.cloudbees.jenkins.GitHubPushTrigger>
  </triggers>
  <concurrentBuild>false</concurrentBuild>
  <builders>
    <hudson.tasks.Shell>
      <command>#!/bin/bash
echo "🚀 Iniciando despliegue automático Hero Budget Backend"

# Configuración
BACKEND_PATH="/opt/hero_budget/backend"
BACKUP_PATH="/opt/hero_budget/backups"
SERVICE_NAME="herobudget"

# Crear backup
echo "📦 Creando backup..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_PATH
if [ -d "$BACKEND_PATH" ]; then
    cd /opt/hero_budget
    tar -czf $BACKUP_PATH/jenkins_backup_${TIMESTAMP}.tar.gz backend/
fi

# Parar servicios
echo "⏹️ Parando servicios..."
systemctl stop $SERVICE_NAME || true

# Actualizar código
echo "🔄 Actualizando código..."
cd $BACKEND_PATH
git fetch origin
git reset --hard origin/main

# Instalar dependencias y compilar
echo "🔨 Compilando aplicación..."
if [ -f "go.mod" ]; then
    go mod download
    go mod tidy
    
    # Compilar aplicación principal
    if [ -f "main.go" ]; then
        go build -o main .
    fi
    
    # Compilar microservicios
    find . -name "main.go" -not -path "./main.go" | while read main_file; do
        dir=$(dirname "$main_file")
        service_name=$(basename "$dir")
        echo "Compilando $service_name..."
        cd "$dir"
        go build -o "$service_name" .
        cd - > /dev/null
    done
fi

# Aplicar migraciones si existen
echo "🗄️ Aplicando migraciones..."
if [ -f "schema.sql" ]; then
    sudo -u postgres psql -d herobudget -f schema.sql >/dev/null 2>&1 || echo "Migraciones ya aplicadas"
fi

# Reiniciar servicios
echo "🚀 Reiniciando servicios..."
systemctl start $SERVICE_NAME
sleep 5

# Verificar
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ Despliegue exitoso"
    systemctl reload nginx
else
    echo "❌ Error en despliegue"
    exit 1
fi

echo "🎉 Despliegue completado automáticamente"
</command>
    </hudson.tasks.Shell>
  </builders>
  <publishers/>
  <buildWrappers/>
</project>
XMLEOF
        
        echo "🔧 Configurando permisos..."
        chown -R jenkins:jenkins /var/lib/jenkins/jobs/herobudget-backend
        
        echo "🔑 Configurando acceso SSH para Jenkins..."
        # Crear usuario jenkins si no existe
        if ! id "jenkins" &>/dev/null; then
            useradd -m -s /bin/bash jenkins
        fi
        
        # Configurar SSH para jenkins
        sudo -u jenkins mkdir -p /var/lib/jenkins/.ssh
        
        # Copiar clave SSH de root a jenkins (si existe)
        if [ -f "/root/.ssh/id_rsa" ]; then
            cp /root/.ssh/id_rsa* /var/lib/jenkins/.ssh/
            chown jenkins:jenkins /var/lib/jenkins/.ssh/id_rsa*
            chmod 600 /var/lib/jenkins/.ssh/id_rsa
        fi
        
        echo "🔧 Agregando jenkins a sudoers para gestión de servicios..."
        cat > /etc/sudoers.d/jenkins << 'SUDEOF'
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl start herobudget
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl stop herobudget
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl restart herobudget
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl reload nginx
jenkins ALL=(ALL) NOPASSWD: /usr/bin/postgresql-*
jenkins ALL=(ALL) NOPASSWD: /usr/bin/psql
SUDEOF
        
        echo "🔄 Reiniciando Jenkins para aplicar cambios..."
        systemctl restart jenkins
        sleep 15
        
        echo "✅ Jenkins configurado para Hero Budget"
EOF
    
    if [ $? -eq 0 ]; then
        log_success "Jenkins configurado exitosamente"
        return 0
    else
        log_error "Error configurando Jenkins"
        return 1
    fi
}

# Configurar webhook en GitHub
setup_github_webhook() {
    log_header "🔗 CONFIGURANDO WEBHOOK GITHUB"
    
    log_info "Para completar la configuración, configura el webhook en GitHub:"
    echo ""
    echo "1. Ve a tu repositorio en GitHub:"
    echo "   https://github.com/TU_USUARIO/herobudget-backend"
    echo ""
    echo "2. Ve a Settings > Webhooks > Add webhook"
    echo ""
    echo "3. Configura:"
    echo "   • Payload URL: http://$(ssh $VPS_USER@$VPS_HOST "curl -s ifconfig.me"):8080/github-webhook/"
    echo "   • Content type: application/json"
    echo "   • Secret: (déjalo vacío por ahora)"
    echo "   • Events: Just the push event"
    echo "   • Active: ✓"
    echo ""
    echo "4. Haz clic en 'Add webhook'"
    echo ""
    log_warning "Nota: Asegúrate de que el puerto 8080 esté abierto en el firewall"
}

# Crear scripts de monitoreo
create_monitoring_scripts() {
    log_header "📊 CREANDO SCRIPTS DE MONITOREO"
    
    ssh $VPS_USER@$VPS_HOST << 'EOF'
        echo "📋 Creando scripts de monitoreo Jenkins..."
        
        # Script para verificar estado Jenkins
        cat > /opt/hero_budget/scripts/check_jenkins.sh << 'CHECKEOF'
#!/bin/bash
# Script de verificación Jenkins

echo "🔍 Verificando estado Jenkins..."

if systemctl is-active --quiet jenkins; then
    echo "✅ Jenkins: ACTIVO"
else
    echo "❌ Jenkins: INACTIVO"
fi

echo "🌐 Puerto Jenkins:"
if netstat -tln | grep -q ":8080 "; then
    echo "✅ Puerto 8080: ABIERTO"
else
    echo "❌ Puerto 8080: CERRADO"
fi

echo "📊 Uso de recursos Jenkins:"
ps aux | grep jenkins | grep -v grep || echo "Proceso Jenkins no encontrado"

echo "📋 Últimos logs Jenkins:"
journalctl -u jenkins --no-pager -n 3
CHECKEOF
        
        chmod +x /opt/hero_budget/scripts/check_jenkins.sh
        
        # Script para restart Jenkins
        cat > /opt/hero_budget/scripts/restart_jenkins.sh << 'RESTARTEOF'
#!/bin/bash
# Script para reiniciar Jenkins

echo "🔄 Reiniciando Jenkins..."
systemctl restart jenkins

echo "⏱️ Esperando que Jenkins se inicie..."
sleep 30

if systemctl is-active --quiet jenkins; then
    echo "✅ Jenkins reiniciado correctamente"
else
    echo "❌ Error reiniciando Jenkins"
    journalctl -u jenkins --no-pager -n 5
fi
RESTARTEOF
        
        chmod +x /opt/hero_budget/scripts/restart_jenkins.sh
        
        echo "✅ Scripts de monitoreo creados"
EOF
    
    log_success "Scripts de monitoreo creados"
}

# Mostrar información post-instalación
show_post_install_info() {
    log_header "🎉 INSTALACIÓN COMPLETADA"
    
    # Obtener IP externa
    EXTERNAL_IP=$(ssh $VPS_USER@$VPS_HOST "curl -s ifconfig.me")
    
    echo "Jenkins instalado y configurado exitosamente!"
    echo ""
    echo "🌐 URL de acceso:"
    echo "   http://$EXTERNAL_IP:8080"
    echo ""
    echo "📋 Información importante:"
    echo "   • Usuario inicial: admin"
    echo "   • Password: (mostrado durante la instalación)"
    echo "   • Proyecto configurado: herobudget-backend"
    echo ""
    echo "📝 Próximos pasos:"
    echo "   1. Accede a Jenkins en tu navegador"
    echo "   2. Completa el wizard de configuración inicial"
    echo "   3. Instala plugins recomendados"
    echo "   4. Configura webhook en GitHub"
    echo "   5. Ejecuta primer build de prueba"
    echo ""
    echo "🔧 Scripts útiles:"
    echo "   • Verificar Jenkins: /opt/hero_budget/scripts/check_jenkins.sh"
    echo "   • Reiniciar Jenkins: /opt/hero_budget/scripts/restart_jenkins.sh"
    echo ""
    echo "🚨 Troubleshooting:"
    echo "   • Logs: journalctl -u jenkins -f"
    echo "   • Estado: systemctl status jenkins"
    echo "   • Puerto: netstat -tlnp | grep 8080"
    echo ""
}

# Función principal
main() {
    local action="$1"
    
    case "$action" in
        --install)
            log_header "🔧 INSTALACIÓN JENKINS"
            check_ssh || exit 1
            install_jenkins
            ;;
        --configure)
            log_header "⚙️ CONFIGURACIÓN JENKINS"
            check_ssh || exit 1
            configure_jenkins
            create_monitoring_scripts
            setup_github_webhook
            ;;
        --full|"")
            log_header "🚀 INSTALACIÓN Y CONFIGURACIÓN COMPLETA JENKINS"
            check_ssh || exit 1
            install_jenkins || exit 1
            configure_jenkins || exit 1
            create_monitoring_scripts
            setup_github_webhook
            show_post_install_info
            ;;
        --help)
            show_help
            ;;
        *)
            log_error "Opción no válida: $action"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@" 