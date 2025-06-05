#!/bin/bash

# =============================================================================
# SCRIPT CORREGIDO PARA SOLUCIONAR EL PROBLEMA DE CATEGORIES UPDATE
# =============================================================================
# Versión corregida con manejo apropiado de salida
# =============================================================================

# Configuración de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuración
LOCALHOST_BASE="http://localhost"
CATEGORIES_PORT="8096"
USER_ID="36"

echo -e "${WHITE}"
echo "============================================================================="
echo "   🔧 CATEGORIES UPDATE ENDPOINT - SOLUTION IMPLEMENTATION (v2)"
echo "============================================================================="
echo -e "${NC}"

# Función para obtener categorías existentes (corregida)
get_existing_categories() {
    local url="$LOCALHOST_BASE:$CATEGORIES_PORT/categories?user_id=$USER_ID"
    local response=$(curl -s -w "\n%{http_code}" -X GET \
        -H "Content-Type: application/json" \
        "$url" 2>/dev/null)
    
    local status_code=$(echo "$response" | tail -n1)
    local content=$(echo "$response" | sed '$d')
    
    if [ "$status_code" -eq 200 ]; then
        echo -e "${GREEN}✅ Categorías obtenidas exitosamente${NC}" >&2
        echo -e "${BLUE}Response:${NC}" >&2
        echo "$content" | jq '.' 2>/dev/null >&2 || echo "$content" >&2
        
        # Extraer el primer ID de categoría si existe
        local category_id=$(echo "$content" | jq -r '.data[0].id // empty' 2>/dev/null)
        if [ -n "$category_id" ] && [ "$category_id" != "null" ] && [ "$category_id" != "empty" ]; then
            echo -e "${GREEN}📝 Primera categoría encontrada con ID: $category_id${NC}" >&2
            echo "$category_id"
            return 0
        else
            echo -e "${YELLOW}⚠️ No se encontraron categorías existentes${NC}" >&2
            return 1
        fi
    else
        echo -e "${RED}❌ Error obteniendo categorías: Status $status_code${NC}" >&2
        echo "$content" >&2
        return 1
    fi
}

# Función para crear una nueva categoría y obtener su ID (corregida)
create_test_category() {
    local create_data='{
        "user_id": "'$USER_ID'",
        "name": "Test Category for Update",
        "type": "expense",
        "emoji": "🧪"
    }'
    
    local url="$LOCALHOST_BASE:$CATEGORIES_PORT/categories/add"
    local response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$create_data" \
        "$url" 2>/dev/null)
    
    local status_code=$(echo "$response" | tail -n1)
    local content=$(echo "$response" | sed '$d')
    
    if [ "$status_code" -eq 200 ]; then
        echo -e "${GREEN}✅ Categoría creada exitosamente${NC}" >&2
        echo -e "${BLUE}Response:${NC}" >&2
        echo "$content" | jq '.' 2>/dev/null >&2 || echo "$content" >&2
        
        # Extraer el ID de la categoría recién creada
        local category_id=$(echo "$content" | jq -r '.data.id // empty' 2>/dev/null)
        if [ -n "$category_id" ] && [ "$category_id" != "null" ] && [ "$category_id" != "empty" ]; then
            echo -e "${GREEN}📝 Nueva categoría creada con ID: $category_id${NC}" >&2
            echo "$category_id"
            return 0
        else
            echo -e "${RED}❌ No se pudo extraer el ID de la categoría creada${NC}" >&2
            return 1
        fi
    else
        echo -e "${RED}❌ Error creando categoría: Status $status_code${NC}" >&2
        echo "$content" >&2
        return 1
    fi
}

# Función para probar el endpoint update con un ID válido
test_categories_update() {
    local category_id=$1
    
    echo -e "${CYAN}3. Probando Categories Update con ID válido: $category_id${NC}"
    
    local update_data='{
        "user_id": "'$USER_ID'",
        "category_id": '$category_id',
        "name": "Updated Test Category",
        "type": "income",
        "emoji": "💰"
    }'
    
    local url="$LOCALHOST_BASE:$CATEGORIES_PORT/categories/update"
    
    echo -e "${BLUE}Request URL: $url${NC}"
    echo -e "${BLUE}Request Data:${NC}"
    echo "$update_data" | jq '.' 2>/dev/null || echo "$update_data"
    
    local response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$update_data" \
        "$url" 2>/dev/null)
    
    local status_code=$(echo "$response" | tail -n1)
    local content=$(echo "$response" | sed '$d')
    
    if [ "$status_code" -eq 200 ]; then
        echo -e "${GREEN}✅ Categories Update EXITOSO - Status: $status_code${NC}"
        echo -e "${BLUE}Response:${NC}"
        echo "$content" | jq '.' 2>/dev/null || echo "$content"
        return 0
    else
        echo -e "${RED}❌ Categories Update FALLÓ - Status: $status_code${NC}"
        echo -e "${RED}Response:${NC}"
        echo "$content"
        return 1
    fi
}

# Función para verificar el resultado final
verify_update() {
    local category_id=$1
    
    echo -e "${CYAN}4. Verificando que la actualización fue exitosa...${NC}"
    
    # Obtener todas las categorías nuevamente y buscar la actualizada
    local url="$LOCALHOST_BASE:$CATEGORIES_PORT/categories?user_id=$USER_ID"
    local response=$(curl -s -w "\n%{http_code}" -X GET \
        -H "Content-Type: application/json" \
        "$url" 2>/dev/null)
    
    local status_code=$(echo "$response" | tail -n1)
    local content=$(echo "$response" | sed '$d')
    
    if [ "$status_code" -eq 200 ]; then
        # Buscar la categoría específica
        local found_category=$(echo "$content" | jq ".data[] | select(.id == $category_id)" 2>/dev/null)
        
        if [ -n "$found_category" ]; then
            echo -e "${GREEN}✅ Categoría actualizada encontrada:${NC}"
            echo "$found_category" | jq '.' 2>/dev/null || echo "$found_category"
            
            # Verificar que el nombre cambió
            local updated_name=$(echo "$found_category" | jq -r '.name // empty' 2>/dev/null)
            if [ "$updated_name" = "Updated Test Category" ]; then
                echo -e "${GREEN}🎉 VERIFICACIÓN EXITOSA: El nombre fue actualizado correctamente${NC}"
                return 0
            else
                echo -e "${YELLOW}⚠️ El nombre no se actualizó como se esperaba: '$updated_name'${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ No se encontró la categoría con ID $category_id después de la actualización${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Error verificando la actualización: Status $status_code${NC}"
        return 1
    fi
}

# Función principal
main() {
    echo -e "${WHITE}🚀 INICIANDO SOLUCIÓN DEL PROBLEMA CATEGORIES UPDATE${NC}"
    echo ""
    
    # Paso 1: Intentar obtener una categoría existente
    echo -e "${WHITE}PASO 1: Obtener categoría existente${NC}"
    echo -e "${CYAN}1. Obteniendo categorías existentes para el usuario $USER_ID...${NC}"
    
    category_id=$(get_existing_categories)
    local get_result=$?
    
    if [ $get_result -ne 0 ] || [ -z "$category_id" ]; then
        # Paso 2: Si no hay categorías, crear una nueva
        echo -e "${WHITE}PASO 2: Crear nueva categoría de prueba${NC}"
        echo -e "${CYAN}2. Creando una nueva categoría de prueba...${NC}"
        
        category_id=$(create_test_category)
        local create_result=$?
        
        if [ $create_result -ne 0 ] || [ -z "$category_id" ]; then
            echo -e "${RED}❌ FALLO: No se pudo obtener o crear una categoría válida${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ Usando categoría existente con ID: $category_id${NC}"
    fi
    
    echo ""
    
    # Paso 3: Probar el endpoint update
    echo -e "${WHITE}PASO 3: Probar Categories Update${NC}"
    if test_categories_update "$category_id"; then
        echo ""
        
        # Paso 4: Verificar resultado
        echo -e "${WHITE}PASO 4: Verificar resultado${NC}"
        if verify_update "$category_id"; then
            echo ""
            echo -e "${GREEN}"
            echo "============================================================================="
            echo "   🎉 SOLUCIÓN EXITOSA: CATEGORIES UPDATE ENDPOINT FUNCIONA CORRECTAMENTE"
            echo "============================================================================="
            echo -e "${NC}"
            echo -e "${GREEN}✅ El problema era que se estaba usando un category_id que no existía${NC}"
            echo -e "${GREEN}✅ Con un ID válido ($category_id), el endpoint funciona perfectamente${NC}"
            echo -e "${GREEN}✅ El formato de datos era correcto desde el principio${NC}"
            echo ""
            exit 0
        else
            echo -e "${RED}❌ La actualización no se verificó correctamente${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ El endpoint update aún tiene problemas${NC}"
        exit 1
    fi
}

# Verificar dependencias
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ Error: curl es requerido pero no está instalado${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️ Advertencia: jq no está instalado - la salida JSON no será formateada${NC}"
fi

# Ejecutar función principal
main 