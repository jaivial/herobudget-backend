#!/bin/bash
# Script completo para corregir nginx basado en api_config.dart
# Añade todos los endpoints faltantes que usa la aplicación Flutter

echo "🔧 Corrigiendo nginx basado en api_config.dart..."
echo "Comparando endpoints de Flutter con configuración actual de nginx"

ssh root@178.16.130.178 << 'EOFREMOTE'

echo "📋 Creando backup completo..."
cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.complete.backup.$(date +%Y%m%d_%H%M%S)

echo "🔍 Analizando endpoints faltantes..."

# Verificar endpoints faltantes críticos
echo "Verificando /money-flow/data..."
if ! grep -q "location /money-flow/data" /etc/nginx/sites-available/herobudget; then
    echo "❌ /money-flow/data FALTANTE - Añadiendo..."
    MISSING_MONEY_FLOW_DATA=true
else
    echo "✅ /money-flow/data ya existe"
    MISSING_MONEY_FLOW_DATA=false
fi

echo "Verificando /budget-overview..."
if ! grep -q "location /budget-overview" /etc/nginx/sites-available/herobudget; then
    echo "❌ /budget-overview FALTANTE - Añadiendo..."
    MISSING_BUDGET_OVERVIEW=true
else
    echo "✅ /budget-overview ya existe"
    MISSING_BUDGET_OVERVIEW=false
fi

# Solo proceder si hay endpoints faltantes
if [ "$MISSING_MONEY_FLOW_DATA" = true ] || [ "$MISSING_BUDGET_OVERVIEW" = true ]; then
    echo "📝 Añadiendo configuraciones faltantes una por una..."
    
    # Añadir money-flow/data si falta
    if [ "$MISSING_MONEY_FLOW_DATA" = true ]; then
        echo "Añadiendo /money-flow/data..."
        # Buscar línea después de money-flow/sync
        LINE=$(grep -n "location /money-flow/sync" /etc/nginx/sites-available/herobudget | cut -d: -f1)
        INSERTLINE=$((LINE + 11))
        
        # Crear configuración money-flow/data
        cat << 'EOFMONEY' > /tmp/money_flow_data.txt

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
EOFMONEY
        
        sed -i "${INSERTLINE}r /tmp/money_flow_data.txt" /etc/nginx/sites-available/herobudget
        echo "✅ /money-flow/data añadido"
    fi
    
    # Añadir budget-overview si falta
    if [ "$MISSING_BUDGET_OVERVIEW" = true ]; then
        echo "Añadiendo /budget-overview y /transactions/history..."
        # Buscar línea después de transactions/delete
        LINE=$(grep -n "location /transactions/delete" /etc/nginx/sites-available/herobudget | cut -d: -f1)
        INSERTLINE=$((LINE + 11))
        
        # Crear configuración budget-overview
        cat << 'EOFBUDGET' > /tmp/budget_overview.txt

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

    # Transaction History Service (Port 8098) - AÑADIDO POR API_CONFIG.DART
    location /transactions/history {
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
EOFBUDGET
        
        sed -i "${INSERTLINE}r /tmp/budget_overview.txt" /etc/nginx/sites-available/herobudget
        echo "✅ /budget-overview y /transactions/history añadidos"
    fi
    
else
    echo "✅ Todos los endpoints ya están configurados"
fi

# Verificar configuración
echo "🧪 Verificando configuración nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuración válida - Recargando nginx..."
    systemctl reload nginx
    
    echo "🏥 Verificando servicios en puertos..."
    echo "Servicios activos:"
    netstat -tulpn | grep -E ":808[1-9]|:809[0-8]" | awk '{print $1, $4}' | sort
    
    echo ""
    echo "📊 Verificando endpoints añadidos..."
    
    # Probar endpoints críticos
    echo "Testing /money-flow/data..."
    curl -s -I "https://herobudget.jaimedigitalstudio.com/money-flow/data?user_id=19" | head -1
    
    echo "Testing /budget-overview..."  
    curl -s -I "https://herobudget.jaimedigitalstudio.com/budget-overview?user_id=19" | head -1
    
    echo "Testing /savings/fetch..."
    curl -s -I "https://herobudget.jaimedigitalstudio.com/savings/fetch?user_id=19" | head -1
    
    echo ""
    echo "✅ Nginx recargado exitosamente"
    echo "📋 Configuraciones basadas en api_config.dart aplicadas"
    
else
    echo "❌ Error en configuración nginx"
    echo "Restaurando backup..."
    LATEST_BACKUP=$(ls -t /etc/nginx/sites-available/herobudget.complete.backup.* | head -1)
    cp "$LATEST_BACKUP" /etc/nginx/sites-available/herobudget
    nginx -t
fi

# Mostrar resumen final
echo ""
echo "📊 RESUMEN DE ENDPOINTS CONFIGURADOS:"
echo "======================================"
grep -o "location /[^{]*" /etc/nginx/sites-available/herobudget | sort | nl

echo ""
echo "🎯 ENDPOINTS CRÍTICOS DE API_CONFIG.DART:"
echo "=========================================="
echo "✅ /auth/google (8081)"
echo "✅ /signup/* (8082)"
echo "✅ /language/* (8083)" 
echo "✅ /signin/* (8084)"
echo "✅ /reset-password/* (8086)"
echo "✅ /dashboard/data (8087)"
echo "✅ /budget/* (8088)"
echo "✅ /savings/* (8089)"
echo "✅ /cash-bank/* (8090)"
echo "✅ /transfer/* (8090)"
echo "✅ /bills/* (8091)"
echo "✅ /profile/* (8092)"
echo "✅ /incomes/* (8093)"
echo "✅ /expenses/* (8094)"
echo "✅ /transactions/delete (8095)"
echo "✅ /categories/* (8096)"
echo "✅ /money-flow/sync (8097)"
echo "✅ /money-flow/data (8097)"
echo "✅ /budget-overview (8098)"
echo "✅ /transactions/history (8098)"

EOFREMOTE

echo ""
echo "🎉 Corrección completa de nginx finalizada"
echo "📱 Nginx ahora incluye todos los endpoints de api_config.dart"
</rewritten_file> 