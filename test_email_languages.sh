#!/bin/bash

# Test script para verificar emails multiidioma en Hero Budget
# Fecha: 30 de mayo de 2025

echo "🌐 HERO BUDGET - PRUEBA DE EMAILS MULTIIDIOMA"
echo "=============================================="
echo ""

# Email de prueba (usar uno que exista en la BD)
EMAIL="jaimebillanueba99@gmail.com"
URL="http://127.0.0.1:8086/reset-password/request"

# Lista de idiomas a probar
declare -a LANGUAGES=("en" "es" "fr" "de" "it" "pt" "ru" "zh" "ja" "nl" "el" "da" "gsw" "hi")
declare -a LANGUAGE_NAMES=("English" "Español" "Français" "Deutsch" "Italiano" "Português" "Русский" "中文" "日本語" "Nederlands" "Ελληνικά" "Dansk" "Schwiizerdütsch" "हिन्दी")

echo "🔍 Verificando servicio..."
if ! curl -s "$URL" >/dev/null 2>&1; then
    echo "❌ Error: El servicio reset-password no está disponible en $URL"
    echo "💡 Asegúrate de que el servicio esté ejecutándose:"
    echo "   cd backend/reset_password && ./reset_password.exe"
    exit 1
fi
echo "✅ Servicio activo"
echo ""

echo "📧 Probando emails en todos los idiomas..."
echo ""

SUCCESS_COUNT=0
TOTAL_COUNT=${#LANGUAGES[@]}

for i in "${!LANGUAGES[@]}"; do
    lang="${LANGUAGES[$i]}"
    lang_name="${LANGUAGE_NAMES[$i]}"
    
    echo "🌍 Probando $lang_name ($lang)..."
    
    # Realizar petición
    RESPONSE=$(curl -s -X POST "$URL" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$EMAIL\",\"language\":\"$lang\"}")
    
    # Verificar respuesta
    if echo "$RESPONSE" | grep -q '"success":true'; then
        echo "✅ $lang_name: Email enviado correctamente"
        ((SUCCESS_COUNT++))
    else
        echo "❌ $lang_name: Error - $RESPONSE"
    fi
    
    # Pequeña pausa entre peticiones
    sleep 0.5
done

echo ""
echo "📊 RESULTADOS:"
echo "=============="
echo "✅ Éxitos: $SUCCESS_COUNT/$TOTAL_COUNT idiomas"
echo "📧 Total emails enviados: $SUCCESS_COUNT"

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    echo ""
    echo "🎉 ¡TODOS LOS IDIOMAS FUNCIONAN CORRECTAMENTE!"
    echo "🌟 El sistema multiidioma está completamente operativo"
else
    echo ""
    echo "⚠️  Algunos idiomas tuvieron problemas"
    echo "🔧 Revisa la configuración del backend"
fi

echo ""
echo "🔍 Información adicional:"
echo "- Plantillas: backend/reset_password/email_templates.json"
echo "- Backend: backend/reset_password/main.go"
echo "- Frontend: lib/services/reset_password_service.dart"
echo ""
echo "✨ Sistema implementado exitosamente!" 