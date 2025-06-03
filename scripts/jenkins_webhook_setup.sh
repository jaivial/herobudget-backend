#!/bin/bash
# Script de configuración automática de Jenkins para webhooks
# Versión: 1.0
# Uso: ./jenkins_webhook_setup.sh [--force] [--github-repo URL]

set -e

# Configuración
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD=""
GITHUB_REPO_URL="${2:-https://github.com/usuario/herobudget-backend.git}"
JOB_NAME="herobudget-backend"
FORCE_SETUP="${1:-}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Funciones de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}${1}${NC}"
    echo "=================================================="
}

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --force                   Forzar recreación del job si existe"
    echo "  --github-repo URL         URL del repositorio GitHub"
    echo "  --help                    Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0"
    echo "  $0 --force --github-repo https://github.com/mi-usuario/mi-repo.git"
}

# Verificar parámetros
if [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Función para obtener la contraseña inicial de Jenkins
get_jenkins_password() {
    log_info "Obteniendo contraseña inicial de Jenkins..."
    
    if [ -f "/var/lib/jenkins/secrets/initialAdminPassword" ]; then
        JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
        log_success "Contraseña inicial obtenida"
    elif [ -f "/var/jenkins_home/secrets/initialAdminPassword" ]; then
        JENKINS_PASSWORD=$(cat /var/jenkins_home/secrets/initialAdminPassword)
        log_success "Contraseña inicial obtenida (Docker)"
    else
        log_warning "Archivo de contraseña inicial no encontrado"
        read -s -p "Ingrese la contraseña de Jenkins admin: " JENKINS_PASSWORD
        echo ""
    fi
}

# Función para esperar que Jenkins esté disponible
wait_for_jenkins() {
    log_info "Esperando que Jenkins esté disponible..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s --max-time 5 "$JENKINS_URL/login" >/dev/null 2>&1; then
            log_success "Jenkins está disponible"
            return 0
        fi
        
        log_info "Intento $attempt/$max_attempts - Esperando Jenkins..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    log_error "Jenkins no está disponible después de $max_attempts intentos"
    return 1
}

# Función para instalar plugins necesarios
install_jenkins_plugins() {
    log_header "📦 INSTALANDO PLUGINS DE JENKINS"
    
    local plugins=(
        "git"
        "github"
        "pipeline-stage-view"
        "build-timeout"
        "timestamper"
        "workflow-aggregator"
        "github-branch-source"
    )
    
    log_info "Instalando plugins esenciales..."
    
    for plugin in "${plugins[@]}"; do
        log_info "Instalando plugin: $plugin"
        
        curl -s -X POST "$JENKINS_URL/pluginManager/installNecessaryPlugins" \
            --user "$JENKINS_USER:$JENKINS_PASSWORD" \
            -d "plugin.${plugin}.default=on" \
            -d "json={\"plugin\":{\"${plugin}\":{\"default\":true}}}" \
            -H "Content-Type: application/x-www-form-urlencoded" >/dev/null || true
    done
    
    log_success "Plugins instalados - reiniciando Jenkins..."
    
    # Reiniciar Jenkins
    curl -s -X POST "$JENKINS_URL/restart" \
        --user "$JENKINS_USER:$JENKINS_PASSWORD" >/dev/null || true
    
    sleep 30
    wait_for_jenkins
}

# Función para crear el job de pipeline
create_pipeline_job() {
    log_header "🔨 CREANDO JOB DE PIPELINE"
    
    # Verificar si el job ya existe
    if curl -s --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/job/$JOB_NAME/config.xml" >/dev/null 2>&1; then
        
        if [ "$FORCE_SETUP" = "--force" ]; then
            log_warning "Job existente encontrado, eliminando debido a --force..."
            curl -s -X POST "$JENKINS_URL/job/$JOB_NAME/doDelete" \
                --user "$JENKINS_USER:$JENKINS_PASSWORD" >/dev/null
        else
            log_warning "Job '$JOB_NAME' ya existe. Use --force para recrear."
            return 0
        fi
    fi
    
    # Crear archivo XML de configuración del job
    log_info "Creando configuración del job..."
    
    cat > "/tmp/jenkins_job_config.xml" << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>Pipeline automático para Hero Budget Backend - Deployment via Webhook</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty plugin="github@1.34.1">
      <projectUrl>$GITHUB_REPO_URL</projectUrl>
      <displayName></displayName>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.92">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>$GITHUB_REPO_URL</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>scripts/Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
    
    # Crear el job en Jenkins
    log_info "Creando job en Jenkins..."
    
    if curl -s -X POST "$JENKINS_URL/createItem?name=$JOB_NAME" \
        --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        -H "Content-Type: application/xml" \
        --data "@/tmp/jenkins_job_config.xml" >/dev/null; then
        
        log_success "Job '$JOB_NAME' creado exitosamente"
    else
        log_error "Error creando el job"
        return 1
    fi
    
    # Limpiar archivo temporal
    rm -f "/tmp/jenkins_job_config.xml"
}

# Función para configurar seguridad y permisos
configure_jenkins_security() {
    log_header "🔒 CONFIGURANDO SEGURIDAD"
    
    # Habilitar webhooks de GitHub
    log_info "Configurando webhooks de GitHub..."
    
    # Crear script Groovy para configuración
    cat > "/tmp/jenkins_security_config.groovy" << 'EOF'
import jenkins.model.*
import hudson.security.*
import org.jenkinsci.plugins.github.config.GitHubPluginConfig
import com.cloudbees.jenkins.GitHubWebHook

def instance = Jenkins.getInstance()

// Configurar GitHub Plugin
def gitHubConfig = GitHubPluginConfig.get()
gitHubConfig.setHookSecretConfig(false)
gitHubConfig.save()

// Habilitar webhook automático
GitHubWebHook.get().setOverrideHookURL(false)

// Configurar CSRF protection
def crumbIssuer = new DefaultCrumbIssuer(true)
instance.setCrumbIssuer(crumbIssuer)

instance.save()
println "Configuración de seguridad aplicada"
EOF
    
    # Ejecutar script de configuración
    if curl -s -X POST "$JENKINS_URL/scriptText" \
        --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        --data-urlencode "script@/tmp/jenkins_security_config.groovy" >/dev/null; then
        
        log_success "Configuración de seguridad aplicada"
    else
        log_warning "Error aplicando configuración de seguridad"
    fi
    
    rm -f "/tmp/jenkins_security_config.groovy"
}

# Función para configurar sudoers para Jenkins
configure_sudoers() {
    log_header "⚙️ CONFIGURANDO SUDOERS PARA JENKINS"
    
    log_info "Configurando permisos sudo para usuario jenkins..."
    
    # Crear archivo sudoers para Jenkins
    cat > "/tmp/jenkins_sudoers" << 'EOF'
# Permisos para usuario jenkins
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl start herobudget
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl stop herobudget
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl restart herobudget
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl reload nginx
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl status herobudget
jenkins ALL=(ALL) NOPASSWD: /usr/bin/systemctl start herobudget
jenkins ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop herobudget
jenkins ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart herobudget
jenkins ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx
jenkins ALL=(ALL) NOPASSWD: /usr/bin/systemctl status herobudget
jenkins ALL=(ALL) NOPASSWD: /usr/bin/killall -TERM herobudget
EOF
    
    # Instalar archivo sudoers
    if sudo cp "/tmp/jenkins_sudoers" "/etc/sudoers.d/jenkins" && \
       sudo chmod 440 "/etc/sudoers.d/jenkins"; then
        
        log_success "Configuración sudoers aplicada"
    else
        log_error "Error configurando sudoers"
        return 1
    fi
    
    rm -f "/tmp/jenkins_sudoers"
}

# Función para verificar la configuración
verify_setup() {
    log_header "✅ VERIFICANDO CONFIGURACIÓN"
    
    # Verificar que Jenkins está funcionando
    if curl -s --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/api/json" >/dev/null; then
        log_success "Jenkins API accesible"
    else
        log_error "Error accediendo a Jenkins API"
        return 1
    fi
    
    # Verificar que el job existe
    if curl -s --user "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/job/$JOB_NAME/api/json" >/dev/null; then
        log_success "Job '$JOB_NAME' configurado correctamente"
    else
        log_error "Job '$JOB_NAME' no encontrado"
        return 1
    fi
    
    # Mostrar información de webhook
    log_info "Configuración de webhook GitHub:"
    log_info "  URL: $JENKINS_URL/github-webhook/"
    log_info "  Content-Type: application/json"
    log_info "  Events: Push events"
    
    log_success "✅ Configuración completada exitosamente"
}

# Función principal
main() {
    log_header "🚀 CONFIGURACIÓN AUTOMÁTICA DE JENKINS WEBHOOK"
    
    log_info "Repositorio GitHub: $GITHUB_REPO_URL"
    log_info "Job Jenkins: $JOB_NAME"
    log_info "Jenkins URL: $JENKINS_URL"
    
    # Verificar que Jenkins está disponible
    wait_for_jenkins
    
    # Obtener contraseña de Jenkins
    get_jenkins_password
    
    # Ejecutar configuración
    install_jenkins_plugins
    configure_sudoers
    create_pipeline_job
    configure_jenkins_security
    verify_setup
    
    log_header "🎉 CONFIGURACIÓN JENKINS COMPLETADA"
    log_success "Jenkins está configurado para deployment automático"
    log_info "Próximos pasos:"
    log_info "1. Configurar webhook en GitHub: $JENKINS_URL/github-webhook/"
    log_info "2. Hacer push al repositorio para probar"
    log_info "3. Verificar logs: $JENKINS_URL/job/$JOB_NAME/"
}

# Manejo de errores
trap 'log_error "Error en línea $LINENO. Configuración fallida."; exit 1' ERR

# Ejecutar función principal
main "$@" 