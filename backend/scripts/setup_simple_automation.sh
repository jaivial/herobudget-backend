#!/bin/bash

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
VPS_IP="178.16.130.178"
REPO_PATH="/opt/hero_budget"
LOG_DIR="/opt/hero_budget/logs"
SERVICE_NAME="hero-budget-webhook"

echo -e "${BLUE}🚀 CONFIGURACIÓN SIMPLE DE AUTOMATIZACIÓN${NC}"
echo "=================================================="

# Función para logging
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si estamos en el VPS
if [[ $(hostname -I | grep $VPS_IP) ]]; then
    IS_VPS=true
    log "Ejecutando en VPS"
else
    IS_VPS=false
    log "Ejecutando localmente - Copiando archivos al VPS..."
fi

if [ "$IS_VPS" = false ]; then
    # Ejecutar desde local - copiar archivos al VPS
    log "Copiando archivos al VPS..."
    
    # Crear directorio en VPS
    ssh root@$VPS_IP "mkdir -p $REPO_PATH/scripts $LOG_DIR"
    
    # Copiar scripts necesarios
    scp scripts/simple_webhook_server.py root@$VPS_IP:$REPO_PATH/scripts/
    scp scripts/webhook_deploy.sh root@$VPS_IP:$REPO_PATH/scripts/
    scp scripts/verify_deployment.sh root@$VPS_IP:$REPO_PATH/scripts/
    scp scripts/manage_services.sh root@$VPS_IP:$REPO_PATH/scripts/
    
    # Ejecutar instalación en VPS
    ssh root@$VPS_IP "cd $REPO_PATH && bash scripts/setup_simple_automation.sh"
    
    log "✅ Configuración completada desde local"
    exit 0
fi

# Resto del script se ejecuta en VPS
log "Configurando sistema de automatización en VPS..."

# 1. Crear directorios necesarios
log "📁 Creando directorios..."
mkdir -p $REPO_PATH/{scripts,logs,backups}
mkdir -p /etc/systemd/system

# 2. Dar permisos de ejecución a scripts
log "🔧 Configurando permisos..."
chmod +x $REPO_PATH/scripts/*.sh
chmod +x $REPO_PATH/scripts/*.py

# 3. Crear archivo de servicio systemd
log "⚙️ Creando servicio systemd..."
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Hero Budget Webhook Server
After=network.target
Wants=network.target

[Service]
Type=exec
User=root
WorkingDirectory=$REPO_PATH
ExecStart=/usr/bin/python3 $REPO_PATH/scripts/simple_webhook_server.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

# Variables de entorno
Environment=PYTHONPATH=$REPO_PATH
Environment=WEBHOOK_SECRET=

[Install]
WantedBy=multi-user.target
EOF

# 4. Configurar firewall
log "🔥 Configurando firewall..."
ufw allow 8080/tcp || warn "No se pudo configurar UFW"

# 5. Habilitar e iniciar servicio
log "🚀 Iniciando servicio webhook..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

# 6. Verificar estado del servicio
sleep 3
if systemctl is-active --quiet $SERVICE_NAME; then
    log "✅ Servicio webhook iniciado correctamente"
else
    error "❌ Error al iniciar servicio webhook"
    systemctl status $SERVICE_NAME
fi

# 7. Crear script de monitoreo
log "📊 Creando script de monitoreo..."
cat > $REPO_PATH/scripts/monitor_webhook.sh << 'EOF'
#!/bin/bash

SERVICE_NAME="hero-budget-webhook"
LOG_FILE="/opt/hero_budget/logs/webhook.log"

echo "🔍 Estado del Webhook Server"
echo "=========================="

# Estado del servicio
echo "📋 Servicio: $(systemctl is-active $SERVICE_NAME)"
echo "🔄 Uptime: $(systemctl show $SERVICE_NAME --property=ActiveEnterTimestamp | cut -d= -f2)"

# Verificar puerto
echo "🌐 Puerto 8080: $(ss -tlnp | grep :8080 | wc -l) conexión(es)"

# Últimas líneas del log
if [[ -f "$LOG_FILE" ]]; then
    echo ""
    echo "📝 Últimos logs:"
    tail -5 "$LOG_FILE"
fi

# Test de conectividad
echo ""
echo "🧪 Test de conectividad:"
curl -s http://localhost:8080/ && echo " ✅" || echo " ❌"
EOF

chmod +x $REPO_PATH/scripts/monitor_webhook.sh

# 8. Crear script de restart
log "🔄 Creando script de restart..."
cat > $REPO_PATH/scripts/restart_webhook.sh << EOF
#!/bin/bash
echo "🔄 Reiniciando webhook server..."
systemctl restart $SERVICE_NAME
sleep 2
systemctl status $SERVICE_NAME
EOF

chmod +x $REPO_PATH/scripts/restart_webhook.sh

# 9. Verificar instalación
log "🧪 Verificando instalación..."
sleep 2

# Test de conectividad
if curl -s http://localhost:8080/ > /dev/null; then
    log "✅ Webhook server responde correctamente"
else
    warn "⚠️ Webhook server no responde, verificando logs..."
    journalctl -u $SERVICE_NAME --no-pager -n 5
fi

# Mostrar información final
echo ""
echo -e "${GREEN}🎉 CONFIGURACIÓN COMPLETADA${NC}"
echo "================================"
echo ""
echo -e "${BLUE}📊 Información del Sistema:${NC}"
echo "• Webhook URL: http://$VPS_IP:8080/"
echo "• Servicio: $SERVICE_NAME"
echo "• Logs: $LOG_DIR/webhook.log"
echo "• Scripts: $REPO_PATH/scripts/"
echo ""
echo -e "${BLUE}🛠️ Comandos Útiles:${NC}"
echo "• Estado: systemctl status $SERVICE_NAME"
echo "• Logs: journalctl -u $SERVICE_NAME -f"
echo "• Restart: $REPO_PATH/scripts/restart_webhook.sh"
echo "• Monitor: $REPO_PATH/scripts/monitor_webhook.sh"
echo ""
echo -e "${BLUE}🔗 Configuración GitHub Webhook:${NC}"
echo "• URL: http://$VPS_IP:8080/"
echo "• Content-Type: application/json"
echo "• Events: Just the push event"
echo ""
echo -e "${GREEN}✅ Sistema listo para recibir webhooks de GitHub!${NC}" 