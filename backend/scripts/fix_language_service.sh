#!/bin/bash
# Script para verificar y corregir servicio de language

echo "🌐 Verificando y corrigiendo servicio de language..."

ssh root@178.16.130.178 << 'EOFREMOTE'

echo "🔍 Verificando estado del servicio language (puerto 8083)..."

# Verificar si el puerto está en uso
if netstat -tulpn | grep -q ":8083"; then
    echo "✅ Puerto 8083 está en uso"
    netstat -tulpn | grep ":8083"
else
    echo "❌ Puerto 8083 NO está en uso - servicio language caído"
fi

# Verificar procesos relacionados con language
echo "🔍 Verificando procesos de language..."
ps aux | grep -E "(language|8083)" | grep -v grep

# Intentar reiniciar el servicio
echo "🔄 Intentando reiniciar servicio herobudget-language..."
if systemctl restart herobudget-language 2>/dev/null; then
    echo "✅ Servicio herobudget-language reiniciado"
    sleep 3
    systemctl status herobudget-language --no-pager -l
else
    echo "⚠️ Servicio herobudget-language no encontrado"
    echo "🔍 Verificando servicios herobudget disponibles..."
    systemctl list-units | grep herobudget
fi

# Verificar si hay algún proceso en el directorio language
echo "🔍 Verificando directorio language..."
cd /opt/hero_budget/backend/language_management
ls -la

# Intentar iniciar manualmente si no está corriendo
if ! netstat -tulpn | grep -q ":8083"; then
    echo "🚀 Intentando iniciar servicio language manualmente..."
    nohup go run main.go > /opt/hero_budget/logs/language_manual.log 2>&1 &
    sleep 3
    
    if netstat -tulpn | grep -q ":8083"; then
        echo "✅ Servicio language iniciado manualmente"
    else
        echo "❌ No se pudo iniciar servicio language"
        echo "📋 Logs del intento:"
        tail -10 /opt/hero_budget/logs/language_manual.log 2>/dev/null || echo "No hay logs disponibles"
    fi
fi

# Testing final del endpoint
echo "🧪 Testing endpoint language final..."
curl -s "http://localhost:8083/health" | head -50 || echo "Health endpoint no responde"

echo "Testing language/get..."
curl -s "http://localhost:8083/language/get?user_id=19" | head -50 || echo "Language get no responde"

EOFREMOTE

echo "✅ Language service correction completed" 