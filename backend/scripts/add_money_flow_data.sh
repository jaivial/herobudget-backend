#!/bin/bash
# Script para añadir configuración money-flow/data

ssh root@178.16.130.178 << 'EOFREMOTE'

# Backup
cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.money-flow.backup

# Crear configuración temporal
cat << 'EOFCONFIG' > /tmp/money_flow_data.txt

    # Money Flow Data Service (Port 8097)
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

# Encontrar línea de money-flow/sync e insertar antes
LINE=$(grep -n 'location /money-flow/sync' /etc/nginx/sites-available/herobudget | cut -d: -f1)
INSERTLINE=$((LINE - 1))

echo "Insertando configuración en línea $INSERTLINE"

# Insertar configuración
sed -i "${INSERTLINE}r /tmp/money_flow_data.txt" /etc/nginx/sites-available/herobudget

# Verificar configuración
echo "Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valid - Reloading nginx..."
    systemctl reload nginx
    echo "✅ Nginx reloaded successfully"
else
    echo "❌ Configuration error - Restoring backup..."
    cp /etc/nginx/sites-available/herobudget.money-flow.backup /etc/nginx/sites-available/herobudget
    nginx -t
fi

EOFREMOTE 