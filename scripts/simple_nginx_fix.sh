#!/bin/bash
# Script simple para añadir solo money-flow/data

echo "🔧 Añadiendo /money-flow/data a nginx..."

ssh root@178.16.130.178 << 'EOFREMOTE'

# Backup
cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.simple.backup

# Verificar si ya existe
if grep -q "location /money-flow/data" /etc/nginx/sites-available/herobudget; then
    echo "✅ /money-flow/data ya existe"
    exit 0
fi

# Crear configuración
cat << 'EOFCONFIG' > /tmp/money_flow_data_simple.txt

    # Money Flow Data Service (Port 8097) - AÑADIDO POR API_CONFIG.DART
    location /money-flow/data {
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
EOFCONFIG

# Encontrar línea después de money-flow/sync
LINE=$(grep -n "location /money-flow/sync" /etc/nginx/sites-available/herobudget | cut -d: -f1)
INSERTLINE=$((LINE + 11))

echo "Insertando /money-flow/data en línea $INSERTLINE"

# Insertar configuración
sed -i "${INSERTLINE}r /tmp/money_flow_data_simple.txt" /etc/nginx/sites-available/herobudget

# Verificar configuración
echo "Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valid - Reloading nginx..."
    systemctl reload nginx
    echo "✅ /money-flow/data añadido exitosamente"
    
    # Probar endpoint
    echo "Testing endpoint..."
    curl -s -I "https://herobudget.jaimedigitalstudio.com/money-flow/data?user_id=19" | head -1
else
    echo "❌ Configuration error - Restoring backup..."
    cp /etc/nginx/sites-available/herobudget.simple.backup /etc/nginx/sites-available/herobudget
fi

EOFREMOTE

echo "✅ Corrección simple completada" 