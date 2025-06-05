#!/bin/bash
# Corrección final de nginx para endpoints restantes

echo "🔧 Aplicando correcciones finales de nginx..."

# Conectar al VPS y aplicar correcciones
ssh root@178.16.130.178 << 'EOFVPS'

# Backup actual
cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.final.backup

# Crear archivo temporal con todas las correcciones
cat << 'EOFNGINX' > /tmp/nginx_corrections.txt

    # Money Flow Data Service (Port 8097) - NUEVA ENTRADA
    location /money-flow {
        limit_req zone=api_limit burst=20 nodelay;
        proxy_pass http://money_flow_sync_service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Savings Management Service (Port 8089) - NUEVA ENTRADA
    location /savings {
        limit_req zone=api_limit burst=20 nodelay;
        proxy_pass http://savings_service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

EOFNGINX

# Buscar línea donde está cash-bank y añadir las nuevas configuraciones después
LINENO=$(grep -n "location /cash-bank" /etc/nginx/sites-available/herobudget | cut -d: -f1)
if [ ! -z "$LINENO" ]; then
    # Buscar la línea donde termina el bloque cash-bank (siguiente "}")
    ENDBLOCK=$((LINENO + 15))
    
    # Insertar las nuevas configuraciones después del bloque cash-bank
    sed -i "${ENDBLOCK}r /tmp/nginx_corrections.txt" /etc/nginx/sites-available/herobudget
    
    echo "✅ Configuraciones añadidas después de línea $ENDBLOCK"
else
    echo "❌ No se encontró configuración cash-bank"
    exit 1
fi

# Verificar configuración
echo "🧪 Verificando configuración nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuración válida - Recargando nginx..."
    systemctl reload nginx
    
    # Verificar que los servicios estén corriendo
    echo "🏥 Verificando servicios en puertos..."
    netstat -tulpn | grep -E ":8089|:8097" | head -10
else
    echo "❌ Error en configuración - Restaurando backup..."
    cp /etc/nginx/sites-available/herobudget.final.backup /etc/nginx/sites-available/herobudget
fi

EOFVPS

echo "✅ Correcciones finales aplicadas" 