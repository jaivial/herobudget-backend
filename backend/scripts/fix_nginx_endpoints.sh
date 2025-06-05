#!/bin/bash
# Script para corregir configuración de endpoints en nginx
# Resuelve problemas 404 y 405 en Hero Budget

echo "🔧 Corrigiendo configuración de endpoints en nginx..."

# Backup de configuración actual
sudo cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.backup.$(date +%Y%m%d_%H%M%S)

# Crear archivo temporal con correcciones
cat << 'EOF' > /tmp/nginx_fixes.conf
    # =============================================================================
    # CORRECCIONES DE ENDPOINTS - AÑADIR A LA CONFIGURACIÓN EXISTENTE
    # =============================================================================

    # Savings Management Service (Port 8089) - FALTABA
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

    # Money Flow Data Service (Port 8097) - CORREGIR PATH
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

    # Budget Overview - PERMITIR GET
    location /budget-overview {
        limit_req zone=api_limit burst=20 nodelay;
        
        # Permitir métodos GET y POST
        if ($request_method !~ ^(GET|POST|OPTIONS)$) {
            return 405;
        }
        
        proxy_pass http://budget_overview_service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

EOF

echo "📋 Correcciones creadas en /tmp/nginx_fixes.conf"
echo ""
echo "🚨 INSTRUCCIONES PARA APLICAR CORRECCIONES:"
echo ""
echo "1. Conectarte al VPS:"
echo "   ssh root@178.16.130.178"
echo ""
echo "2. Editar configuración de nginx:"
echo "   nano /etc/nginx/sites-available/herobudget"
echo ""
echo "3. Buscar la sección de FINANCIAL SERVICES y añadir las configuraciones de savings:"
echo "   (Copiar el bloque location /savings desde nginx_fixes.conf)"
echo ""
echo "4. Buscar money-flow-sync y cambiar a money-flow:"
echo "   location /money-flow-sync → location /money-flow"
echo ""
echo "5. Buscar budget-overview y añadir validación de métodos HTTP"
echo ""
echo "6. Verificar configuración:"
echo "   nginx -t"
echo ""
echo "7. Recargar nginx:"
echo "   systemctl reload nginx"
echo ""
echo "8. Verificar servicios corriendo:"
echo "   systemctl status herobudget-savings"
echo "   systemctl status herobudget-money-flow"
echo "   systemctl status herobudget-budget-overview"
echo ""
echo "💡 También puedes usar este comando para aplicar automáticamente:"
echo "   cat /tmp/nginx_fixes.conf"

# Test de endpoints después de la corrección
echo ""
echo "🧪 COMANDOS DE TESTING POST-CORRECCIÓN:"
echo ""
echo "# Test savings endpoint"
echo "curl -X GET 'https://herobudget.jaimedigitalstudio.com/savings/health'"
echo ""
echo "# Test money-flow endpoint"  
echo "curl -X GET 'https://herobudget.jaimedigitalstudio.com/money-flow/data?user_id=19'"
echo ""
echo "# Test budget-overview endpoint"
echo "curl -X GET 'https://herobudget.jaimedigitalstudio.com/budget-overview?user_id=19'"
echo ""
echo "✅ Script completado. Aplicar correcciones manualmente en el VPS." 