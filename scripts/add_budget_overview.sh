#!/bin/bash
# Script para añadir /budget-overview a nginx

echo "🔧 Añadiendo /budget-overview a nginx..."

ssh root@178.16.130.178 << 'EOFREMOTE'

# Backup
cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.budget-overview.backup

# Verificar si ya existe
if grep -q "location /budget-overview" /etc/nginx/sites-available/herobudget; then
    echo "✅ /budget-overview ya existe"
    exit 0
fi

# Crear configuración
cat << 'EOFCONFIG' > /tmp/budget_overview_simple.txt

    # Budget Overview Service (Port 8098) - AÑADIDO POR API_CONFIG.DART
    location /budget-overview {
        limit_req zone=api_limit burst=20 nodelay;
        proxy_pass http://budget_overview_service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
EOFCONFIG

# Encontrar línea después de transactions/delete
LINE=$(grep -n "location /transactions/delete" /etc/nginx/sites-available/herobudget | cut -d: -f1)
INSERTLINE=$((LINE + 11))

echo "Insertando /budget-overview en línea $INSERTLINE"

# Insertar configuración
sed -i "${INSERTLINE}r /tmp/budget_overview_simple.txt" /etc/nginx/sites-available/herobudget

# Verificar configuración
echo "Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valid - Reloading nginx..."
    systemctl reload nginx
    echo "✅ /budget-overview añadido exitosamente"
    
    # Probar endpoint
    echo "Testing endpoint..."
    curl -s -I "https://herobudget.jaimedigitalstudio.com/budget-overview?user_id=19" | head -1
else
    echo "❌ Configuration error - Restoring backup..."
    cp /etc/nginx/sites-available/herobudget.budget-overview.backup /etc/nginx/sites-available/herobudget
fi

EOFREMOTE

echo "✅ Budget overview añadido completamente" 