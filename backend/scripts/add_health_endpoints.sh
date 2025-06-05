#!/bin/bash
# Script para añadir health endpoints faltantes

echo "🏥 Añadiendo health endpoints faltantes a nginx..."

ssh root@178.16.130.178 << 'EOFREMOTE'

# Backup
cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.health.backup

echo "Añadiendo health endpoints..."

# Crear configuraciones de health
cat << 'EOFHEALTH' > /tmp/health_endpoints.txt

    # Savings Health Endpoint (Port 8089)
    location /savings/health {
        limit_req zone=api_limit burst=20 nodelay;
        proxy_pass http://savings_service/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Budget Overview Health Endpoint (Port 8098)
    location /budget-overview/health {
        limit_req zone=api_limit burst=20 nodelay;
        proxy_pass http://budget_overview_service/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
EOFHEALTH

# Encontrar línea después de /health general
LINE=$(grep -n "location /health" /etc/nginx/sites-available/herobudget | head -1 | cut -d: -f1)
INSERTLINE=$((LINE + 11))

echo "Insertando health endpoints en línea $INSERTLINE"

# Insertar configuración
sed -i "${INSERTLINE}r /tmp/health_endpoints.txt" /etc/nginx/sites-available/herobudget

# Verificar configuración
echo "Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valid - Reloading nginx..."
    systemctl reload nginx
    echo "✅ Health endpoints añadidos exitosamente"
    
    # Probar endpoints
    echo "Testing /savings/health..."
    curl -s -I "https://herobudget.jaimedigitalstudio.com/savings/health" | head -1
    
    echo "Testing /budget-overview/health..."
    curl -s -I "https://herobudget.jaimedigitalstudio.com/budget-overview/health" | head -1
else
    echo "❌ Configuration error - Restoring backup..."
    cp /etc/nginx/sites-available/herobudget.health.backup /etc/nginx/sites-available/herobudget
fi

EOFREMOTE

echo "✅ Health endpoints correction completed" 