#!/bin/bash
# Script para añadir endpoint /update/locale

echo "🌐 Añadiendo endpoint /update/locale a nginx..."

ssh root@178.16.130.178 << 'EOFREMOTE'

# Backup
cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.locale.backup

# Verificar si ya existe
if grep -q "location /update/locale" /etc/nginx/sites-available/herobudget; then
    echo "✅ /update/locale ya existe"
    exit 0
fi

echo "Añadiendo endpoint /update/locale..."

# Crear configuración
cat << 'EOFLOCALE' > /tmp/locale_endpoint.txt

    # Update Locale Endpoint (Port 8092) - Profile Service
    location /update/locale {
        limit_req zone=api_limit burst=20 nodelay;
        proxy_pass http://profile_service/update/locale;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
EOFLOCALE

# Encontrar línea después de /profile
LINE=$(grep -n "location /profile" /etc/nginx/sites-available/herobudget | cut -d: -f1)
INSERTLINE=$((LINE + 11))

echo "Insertando /update/locale en línea $INSERTLINE"

# Insertar configuración
sed -i "${INSERTLINE}r /tmp/locale_endpoint.txt" /etc/nginx/sites-available/herobudget

# Verificar configuración
echo "Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valid - Reloading nginx..."
    systemctl reload nginx
    echo "✅ /update/locale añadido exitosamente"
    
    # Probar endpoint
    echo "Testing /update/locale..."
    curl -s -I "https://herobudget.jaimedigitalstudio.com/update/locale" | head -1
else
    echo "❌ Configuration error - Restoring backup..."
    cp /etc/nginx/sites-available/herobudget.locale.backup /etc/nginx/sites-available/herobudget
fi

EOFREMOTE

echo "✅ Locale endpoint correction completed" 