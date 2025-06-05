#!/bin/bash
# Script para insertar configuraciones nginx

ssh root@178.16.130.178 << 'EOFREMOTE'

echo "🔧 Insertando configuraciones nginx..."

# Backup
cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.insert.backup

# Encontrar línea donde termina el bloque transfer
LINE=$(grep -n 'location /transfer' /etc/nginx/sites-available/herobudget | cut -d: -f1)
ENDLINE=$((LINE + 11))

echo "Insertando después de línea $ENDLINE"

# Crear configuraciones a insertar
cat << 'EOFCONFIGS' > /tmp/new_configs.txt

    # Money Flow Data Service (Port 8097)
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

    # Savings Management Service (Port 8089)
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
EOFCONFIGS

# Insertar las configuraciones
sed -i "${ENDLINE}r /tmp/new_configs.txt" /etc/nginx/sites-available/herobudget

# Verificar que no haya duplicados de savings (por intentos anteriores)
if [ $(grep -c "location /savings" /etc/nginx/sites-available/herobudget) -gt 1 ]; then
    echo "⚠️ Removiendo duplicados de savings..."
    # Restaurar backup y volver a intentar
    cp /etc/nginx/sites-available/herobudget.insert.backup /etc/nginx/sites-available/herobudget
    sed -i "${ENDLINE}r /tmp/new_configs.txt" /etc/nginx/sites-available/herobudget
fi

# Verificar configuración
echo "🧪 Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valid - Reloading nginx..."
    systemctl reload nginx
    
    echo "🏥 Verificando servicios..."
    netstat -tulpn | grep -E ":8089|:8097"
    
    echo "✅ Nginx reloaded successfully"
else
    echo "❌ Configuration error - Restoring backup..."
    cp /etc/nginx/sites-available/herobudget.insert.backup /etc/nginx/sites-available/herobudget
    nginx -t
fi

EOFREMOTE 