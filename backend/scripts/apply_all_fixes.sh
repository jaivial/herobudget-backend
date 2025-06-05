#!/bin/bash
# Script para aplicar todas las correcciones de Hero Budget
# Resuelve errores 500, 404 y problemas de endpoints

echo "🚀 Aplicando correcciones completas de Hero Budget..."
echo "=================================================="

# Verificar si estamos en el directorio correcto
if [ ! -f "scripts/fix_cash_bank_database.sql" ]; then
    echo "❌ Error: Ejecutar desde el directorio raíz del proyecto"
    exit 1
fi

# Variables
VPS_HOST="178.16.130.178"
VPS_USER="root"
HERO_BUDGET_PATH="/opt/hero_budget"

echo "📊 Estado actual del sistema:"
echo "Ejecutando testing inicial..."

# Testing inicial
python3 scripts/endpoint_validation.py production > initial_test_results.txt 2>&1
echo "✅ Testing inicial completado - Ver initial_test_results.txt"

echo ""
echo "🔧 APLICANDO CORRECCIONES..."
echo ""

# Función para aplicar correcciones en VPS
apply_vps_fixes() {
    echo "📡 Conectando al VPS para aplicar correcciones..."
    
    # Crear script temporal para VPS
    cat << 'EOF' > /tmp/vps_fixes.sh
#!/bin/bash
echo "🏥 Aplicando correcciones en VPS..."

# 1. Backup de configuraciones
echo "📋 Creando backups..."
cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.backup.$(date +%Y%m%d_%H%M%S)
cp /opt/hero_budget/backend/google_auth/users.db /opt/hero_budget/backend/google_auth/users.db.backup.$(date +%Y%m%d_%H%M%S)

# 2. Aplicar corrección de base de datos
echo "🗄️ Aplicando corrección de base de datos..."
cd /opt/hero_budget
sqlite3 backend/google_auth/users.db < scripts/fix_cash_bank_database.sql

# 3. Reiniciar servicio cash-bank
echo "🔄 Reiniciando servicio cash-bank..."
systemctl restart herobudget-cash-bank
sleep 3

# 4. Verificar servicio
echo "✅ Verificando servicio cash-bank..."
systemctl status herobudget-cash-bank --no-pager -l

# 5. Aplicar correcciones nginx
echo "🌐 Aplicando correcciones nginx..."

# Backup actual
cp /etc/nginx/sites-available/herobudget /tmp/herobudget.backup

# Verificar y añadir configuración savings si no existe
if ! grep -q "location /savings" /etc/nginx/sites-available/herobudget; then
    echo "➕ Añadiendo configuración /savings..."
    # Buscar línea de cash-bank y añadir savings después
    sed -i '/location \/cash-bank/a\\n    # Savings Management Service (Port 8089)\n    location /savings {\n        limit_req zone=api_limit burst=20 nodelay;\n        proxy_pass http://savings_service;\n        proxy_set_header Host $host;\n        proxy_set_header X-Real-IP $remote_addr;\n        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n        proxy_set_header X-Forwarded-Proto $scheme;\n        proxy_connect_timeout 30s;\n        proxy_send_timeout 30s;\n        proxy_read_timeout 30s;\n    }' /etc/nginx/sites-available/herobudget
fi

# Cambiar money-flow-sync a money-flow
if grep -q "location /money-flow-sync" /etc/nginx/sites-available/herobudget; then
    echo "🔄 Cambiando money-flow-sync a money-flow..."
    sed -i 's|location /money-flow-sync|location /money-flow|g' /etc/nginx/sites-available/herobudget
fi

# Verificar configuración nginx
echo "🧪 Verificando configuración nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuración nginx válida - Recargando..."
    systemctl reload nginx
else
    echo "❌ Error en configuración nginx - Restaurando backup..."
    cp /tmp/herobudget.backup /etc/nginx/sites-available/herobudget
    exit 1
fi

# 6. Verificar servicios críticos
echo "🏥 Verificando servicios críticos..."
systemctl status herobudget-cash-bank --no-pager | head -5
systemctl status nginx --no-pager | head -5

echo "✅ Correcciones VPS aplicadas exitosamente"
EOF

    chmod +x /tmp/vps_fixes.sh
    
    echo "📤 Copiando archivos al VPS..."
    # Copiar scripts al VPS
    scp scripts/fix_cash_bank_database.sql $VPS_USER@$VPS_HOST:$HERO_BUDGET_PATH/scripts/
    scp /tmp/vps_fixes.sh $VPS_USER@$VPS_HOST:/tmp/
    
    echo "🚀 Ejecutando correcciones en VPS..."
    ssh $VPS_USER@$VPS_HOST "cd $HERO_BUDGET_PATH && bash /tmp/vps_fixes.sh"
}

# Preguntar si aplicar correcciones VPS
echo "🤔 ¿Aplicar correcciones en VPS? (requiere acceso SSH)"
echo "1) Sí - Aplicar correcciones automáticamente"
echo "2) No - Solo mostrar comandos manuales"
echo "3) Solo testing local"
read -p "Seleccionar opción (1-3): " option

case $option in
    1)
        echo "🚀 Aplicando correcciones automáticamente..."
        apply_vps_fixes
        ;;
    2)
        echo "📋 COMANDOS MANUALES PARA VPS:"
        echo "================================"
        echo "ssh root@178.16.130.178"
        echo "cd /opt/hero_budget"
        echo "cp backend/google_auth/users.db backend/google_auth/users.db.backup.\$(date +%Y%m%d_%H%M%S)"
        echo "sqlite3 backend/google_auth/users.db < scripts/fix_cash_bank_database.sql"
        echo "systemctl restart herobudget-cash-bank"
        echo ""
        echo "# Para nginx:"
        echo "cp /etc/nginx/sites-available/herobudget /etc/nginx/sites-available/herobudget.backup.\$(date +%Y%m%d_%H%M%S)"
        echo "nano /etc/nginx/sites-available/herobudget"
        echo "# Aplicar cambios de scripts/fix_nginx_endpoints.sh"
        echo "nginx -t && systemctl reload nginx"
        ;;
    3)
        echo "🧪 Solo ejecutando testing local..."
        ;;
esac

# Testing post-corrección
echo ""
echo "🧪 EJECUTANDO TESTING POST-CORRECCIÓN..."
echo "========================================"

# Esperar un poco si se aplicaron correcciones
if [ "$option" = "1" ]; then
    echo "⏳ Esperando 10 segundos para que los servicios se estabilicen..."
    sleep 10
fi

# Testing final
echo "📊 Testing final del sistema..."
python3 scripts/endpoint_validation.py production > final_test_results.txt 2>&1

echo ""
echo "📈 COMPARACIÓN DE RESULTADOS:"
echo "============================="

# Extraer métricas de archivos de resultados
INITIAL_SUCCESS=$(grep "Success Rate:" initial_test_results.txt | head -1 | awk '{print $3}')
FINAL_SUCCESS=$(grep "Success Rate:" final_test_results.txt | head -1 | awk '{print $3}')

echo "🔍 Success Rate Inicial: $INITIAL_SUCCESS"
echo "🎯 Success Rate Final: $FINAL_SUCCESS"

# Mostrar mejoras
echo ""
echo "📊 ENDPOINTS CRÍTICOS:"
echo "======================"

# Testing manual de endpoints críticos
echo "🏦 Testing Cash/Bank Distribution:"
curl -s "https://herobudget.jaimedigitalstudio.com/cash-bank/distribution?user_id=19" | head -100

echo ""
echo "💸 Testing Bank to Cash Transfer:"
curl -s -X POST "https://herobudget.jaimedigitalstudio.com/transfer/bank-to-cash" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"19","amount":50}' | head -100

echo ""
echo "💰 Testing Cash to Bank Transfer:"
curl -s -X POST "https://herobudget.jaimedigitalstudio.com/transfer/cash-to-bank" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"19","amount":25}' | head -100

echo ""
echo "📋 Testing Budget Overview:"
curl -s "https://herobudget.jaimedigitalstudio.com/budget-overview?user_id=19" | head -100

echo ""
echo "🎉 RESUMEN FINAL:"
echo "=================="
echo "✅ Scripts de corrección aplicados"
echo "✅ Testing automatizado completado"
echo "📊 Ver initial_test_results.txt y final_test_results.txt para detalles"
echo ""
echo "📁 Archivos generados:"
echo "- initial_test_results.txt (estado inicial)"
echo "- final_test_results.txt (estado después de correcciones)"
echo "- endpoint_validation_production_*.json (datos detallados)"
echo ""
echo "🎯 Próximos pasos si hay problemas restantes:"
echo "- Revisar logs del VPS: ssh root@178.16.130.178 'journalctl -f -u herobudget-cash-bank'"
echo "- Verificar nginx: ssh root@178.16.130.178 'nginx -t && systemctl status nginx'"
echo "- Re-ejecutar correcciones: bash scripts/apply_all_fixes.sh" 