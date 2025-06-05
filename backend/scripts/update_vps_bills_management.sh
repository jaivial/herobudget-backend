#!/bin/bash

# =============================================================================
# SCRIPT PARA ACTUALIZAR BILLS MANAGEMENT EN VPS
# Actualiza endpoints /bills/update y /bills/delete en producción
# =============================================================================

# Configuración de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Variables del VPS
VPS_HOST="178.16.130.178"
VPS_USER="root"
VPS_PATH="/opt/hero_budget"
DOMAIN="herobudget.jaimedigitalstudio.com"

echo -e "${WHITE}"
echo "============================================================================="
echo "   🔄 ACTUALIZANDO BILLS MANAGEMENT EN VPS"
echo "============================================================================="
echo -e "${NC}"

# Función para logging
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

# Verificar conectividad SSH
verify_ssh() {
    log_info "Verificando conectividad con VPS..."
    if ssh -o ConnectTimeout=10 $VPS_USER@$VPS_HOST "echo 'SSH OK'" >/dev/null 2>&1; then
        log_success "Conexión SSH establecida"
        return 0
    else
        log_error "No se puede conectar al VPS $VPS_HOST"
        return 1
    fi
}

# Transferir archivos actualizados al VPS
transfer_files() {
    log_info "Transfiriendo archivos actualizados al VPS..."
    
    # Crear backup del main.go actual en VPS
    ssh $VPS_USER@$VPS_HOST "cd $VPS_PATH/backend/bills_management && cp main.go main.go.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Transferir nuevo main.go
    scp backend/bills_management/main.go $VPS_USER@$VPS_HOST:$VPS_PATH/backend/bills_management/
    
    # Transferir scripts de reinicio actualizados
    scp restart_services.sh $VPS_USER@$VPS_HOST:$VPS_PATH/
    chmod +x $VPS_PATH/restart_services.sh
    
    log_success "Archivos transferidos correctamente"
}

# Actualizar configuración de Nginx
update_nginx_config() {
    log_info "Actualizando configuración de Nginx para nuevos endpoints..."
    
    ssh $VPS_USER@$VPS_HOST << 'EOFREMOTE'
# Backup de configuración actual
cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.backup.$(date +%Y%m%d_%H%M%S)

# Verificar si ya existen los endpoints
if grep -q "location /bills/update" /etc/nginx/sites-available/herobudget; then
    echo "⚠️ Endpoints /bills/update y /bills/delete ya están configurados"
else
    echo "📝 Añadiendo configuración para nuevos endpoints de bills..."
    
    # Buscar la línea donde está la configuración de bills
    LINE=$(grep -n "location /bills {" /etc/nginx/sites-available/herobudget | cut -d: -f1)
    
    if [ ! -z "$LINE" ]; then
        # Calcular línea donde termina el bloque bills (generalmente después de 11 líneas)
        ENDLINE=$((LINE + 11))
        
        # Crear configuración temporal para los nuevos endpoints
        cat << 'EOFCONFIG' > /tmp/bills_new_endpoints.txt

    # Bills Management - Update Endpoint
    location /bills/update {
        limit_req zone=api_limit burst=20 nodelay;
        proxy_pass http://bills_service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Bills Management - Delete Endpoint
    location /bills/delete {
        limit_req zone=api_limit burst=20 nodelay;
        proxy_pass http://bills_service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
EOFCONFIG
        
        # Insertar la configuración después del bloque bills
        sed -i "${ENDLINE}r /tmp/bills_new_endpoints.txt" /etc/nginx/sites-available/herobudget
        
        echo "✅ Configuración de endpoints añadida en línea $ENDLINE"
    else
        echo "❌ No se encontró configuración de bills en nginx"
        exit 1
    fi
fi

# Verificar configuración de nginx
echo "🧪 Verificando configuración de nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuración nginx válida - Recargando..."
    systemctl reload nginx
    echo "✅ Nginx recargado exitosamente"
else
    echo "❌ Error en configuración nginx - Restaurando backup..."
    cp /etc/nginx/sites-available/herobudget.backup.$(date +%Y%m%d_%H%M%S) /etc/nginx/sites-available/herobudget
    nginx -t
    exit 1
fi
EOFREMOTE

    log_success "Configuración de Nginx actualizada"
}

# Compilar y reiniciar servicios en VPS
restart_services() {
    log_info "Compilando y reiniciando bills_management en VPS..."
    
    ssh $VPS_USER@$VPS_HOST << EOFREMOTE
cd $VPS_PATH/backend/bills_management

echo "🔨 Compilando bills_management..."
go build . 

if [ \$? -eq 0 ]; then
    echo "✅ Compilación exitosa"
    
    echo "🔄 Reiniciando bills_management..."
    # Detener el proceso actual
    pkill -f "bills_management" 2>/dev/null || true
    sleep 2
    
    # Iniciar nuevo proceso en background
    nohup ./bills_management > /dev/null 2>&1 &
    
    echo "✅ bills_management reiniciado"
    
    # Verificar que esté corriendo
    sleep 3
    if pgrep -f "bills_management" > /dev/null; then
        echo "✅ bills_management está corriendo correctamente"
    else
        echo "❌ Error: bills_management no está corriendo"
        exit 1
    fi
else
    echo "❌ Error en compilación"
    exit 1
fi
EOFREMOTE

    log_success "Servicios reiniciados correctamente"
}

# Verificar endpoints en producción
verify_endpoints() {
    log_info "Verificando nuevos endpoints en producción..."
    
    echo -e "${CYAN}🧪 Probando endpoints via HTTPS...${NC}"
    
    # Test endpoint principal
    log_info "Probando GET /bills..."
    RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "https://$DOMAIN/bills?user_id=1")
    if [ "$RESPONSE" = "200" ]; then
        log_success "✅ GET /bills responde correctamente (Status: $RESPONSE)"
    else
        log_warning "⚠️ GET /bills respuesta: $RESPONSE"
    fi
    
    # Test update endpoint
    log_info "Probando POST /bills/update..."
    UPDATE_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -X POST "https://$DOMAIN/bills/update" \
        -H "Content-Type: application/json" \
        -d '{"user_id": "1", "bill_id": 1, "name": "Test Bill", "amount": 100.50}')
    if [ "$UPDATE_RESPONSE" = "200" ]; then
        log_success "✅ POST /bills/update responde correctamente (Status: $UPDATE_RESPONSE)"
    else
        log_warning "⚠️ POST /bills/update respuesta: $UPDATE_RESPONSE"
    fi
    
    # Test delete endpoint
    log_info "Probando POST /bills/delete..."
    DELETE_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -X POST "https://$DOMAIN/bills/delete" \
        -H "Content-Type: application/json" \
        -d '{"user_id": "1", "bill_id": 1}')
    if [ "$DELETE_RESPONSE" = "200" ]; then
        log_success "✅ POST /bills/delete responde correctamente (Status: $DELETE_RESPONSE)"
    else
        log_warning "⚠️ POST /bills/delete respuesta: $DELETE_RESPONSE"
    fi
}

# Crear script de automatización Python en VPS
setup_automation() {
    log_info "Configurando automatización Python en VPS..."
    
    # Crear script de webhook simple
    cat << 'EOFPYTHON' > /tmp/webhook_server.py
#!/usr/bin/env python3
import json
import os
import subprocess
import http.server
import socketserver
from datetime import datetime

PORT = 8080

class WebhookHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/webhook':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data)
                
                # Log webhook recibido
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                print(f"[{timestamp}] Webhook recibido de GitHub")
                
                # Verificar que es un push al branch main
                if data.get('ref') == 'refs/heads/main':
                    print(f"[{timestamp}] Push detectado en branch main - Iniciando deployment")
                    
                    # Ejecutar script de deployment
                    result = subprocess.run(['/opt/hero_budget/scripts/webhook_deploy.sh'], 
                                          capture_output=True, text=True)
                    
                    if result.returncode == 0:
                        print(f"[{timestamp}] Deployment exitoso")
                        self.send_response(200)
                    else:
                        print(f"[{timestamp}] Error en deployment: {result.stderr}")
                        self.send_response(500)
                else:
                    print(f"[{timestamp}] Push ignorado (no es branch main)")
                    self.send_response(200)
                    
            except Exception as e:
                print(f"Error procesando webhook: {e}")
                self.send_response(400)
                
            self.end_headers()
            self.wfile.write(b'OK')
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), WebhookHandler) as httpd:
        print(f"Webhook server iniciado en puerto {PORT}")
        httpd.serve_forever()
EOFPYTHON

    # Crear script de deployment webhook
    cat << 'EOFWEBHOOK' > /tmp/webhook_deploy.sh
#!/bin/bash
# Script de deployment automático para webhooks

VPS_PATH="/opt/hero_budget"
LOG_FILE="$VPS_PATH/logs/webhook_deploy.log"

# Función de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log "=== Iniciando deployment automático ==="

cd $VPS_PATH

# Crear backup
log "Creando backup del código actual..."
cp -r backend backend.backup.$(date +%Y%m%d_%H%M%S)

# Git pull con rebase
log "Actualizando código desde GitHub..."
git pull --rebase origin main

if [ $? -eq 0 ]; then
    log "✅ Código actualizado exitosamente"
    
    # Compilar bills_management
    log "Compilando bills_management..."
    cd backend/bills_management
    go build .
    
    if [ $? -eq 0 ]; then
        log "✅ Compilación exitosa"
        
        # Reiniciar servicios
        log "Reiniciando servicios..."
        $VPS_PATH/restart_services.sh
        
        log "✅ Deployment completado exitosamente"
    else
        log "❌ Error en compilación"
        exit 1
    fi
else
    log "❌ Error actualizando código"
    exit 1
fi
EOFWEBHOOK

    # Transferir scripts al VPS
    scp /tmp/webhook_server.py $VPS_USER@$VPS_HOST:$VPS_PATH/scripts/
    scp /tmp/webhook_deploy.sh $VPS_USER@$VPS_HOST:$VPS_PATH/scripts/
    
    # Configurar permisos en VPS
    ssh $VPS_USER@$VPS_HOST << EOFREMOTE
chmod +x $VPS_PATH/scripts/webhook_deploy.sh
chmod +x $VPS_PATH/scripts/webhook_server.py

# Crear servicio systemd para webhook
cat << EOFSERVICE > /etc/systemd/system/herobudget-webhook.service
[Unit]
Description=Hero Budget Webhook Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$VPS_PATH
ExecStart=/usr/bin/python3 $VPS_PATH/scripts/webhook_server.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Habilitar y comenzar servicio
systemctl daemon-reload
systemctl enable herobudget-webhook
systemctl start herobudget-webhook

echo "✅ Webhook server configurado y iniciado"
EOFREMOTE
    
    log_success "Automatización Python configurada"
}

# Función principal
main() {
    echo -e "${CYAN}🚀 Iniciando actualización de Bills Management en VPS...${NC}"
    
    # Verificar SSH
    if ! verify_ssh; then
        log_error "Error de conectividad. Verifique la conexión SSH al VPS."
        exit 1
    fi
    
    # Transferir archivos
    transfer_files
    
    # Actualizar nginx
    update_nginx_config
    
    # Reiniciar servicios
    restart_services
    
    # Verificar endpoints
    sleep 5
    verify_endpoints
    
    # Configurar automatización
    setup_automation
    
    echo -e "${WHITE}"
    echo "============================================================================="
    echo "   ✅ ACTUALIZACIÓN COMPLETADA EXITOSAMENTE"
    echo "============================================================================="
    echo -e "${NC}"
    
    echo -e "${GREEN}🎉 ENDPOINTS DISPONIBLES EN PRODUCCIÓN:${NC}"
    echo -e "${WHITE}  • GET /bills: https://$DOMAIN/bills?user_id=1${NC}"
    echo -e "${WHITE}  • POST /bills/update: https://$DOMAIN/bills/update${NC}"
    echo -e "${WHITE}  • POST /bills/delete: https://$DOMAIN/bills/delete${NC}"
    
    echo -e "\n${CYAN}📋 CONFIGURACIÓN GITHUB WEBHOOK:${NC}"
    echo -e "${WHITE}  • URL: http://$VPS_HOST:8080/webhook${NC}"
    echo -e "${WHITE}  • Content-Type: application/json${NC}"
    echo -e "${WHITE}  • Events: Just the push event${NC}"
    
    echo -e "\n${GREEN}🎯 ESTADO: Sistema actualizado y funcionando en producción${NC}"
}

# Ejecutar función principal
main "$@" 