#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Solucionando compilación de microservicios...${NC}"
echo -e "${BLUE}================================================${NC}"

# Lista completa de microservicios
services=(
    "google_auth"
    "signup"
    "language_cookie"
    "signin"
    "reset_password"
    "fetch_dashboard"
    "dashboard_data"
    "budget_management"
    "savings_management"
    "cash_bank_management"
    "bills_management"
    "profile_management"
    "income_management"
    "expense_management"
    "categories_management"
    "money_flow_sync"
    "budget_overview_fetch"
)

# Ir al directorio backend
cd /opt/hero_budget/backend || { echo -e "${RED}❌ No se pudo acceder al directorio backend${NC}"; exit 1; }

echo -e "${YELLOW}📁 Directorio actual: $(pwd)${NC}"
echo

# Contador de éxitos/fallos
success_count=0
total_count=${#services[@]}

# Función para compilar un servicio
compile_service() {
    local service=$1
    echo -e "${YELLOW}📦 Procesando $service...${NC}"
    
    if [ ! -d "$service" ]; then
        echo -e "${RED}❌ Directorio $service no encontrado${NC}"
        return 1
    fi
    
    cd "$service" || { echo -e "${RED}❌ No se pudo acceder al directorio $service${NC}"; return 1; }
    
    # Mostrar contenido del directorio
    echo -e "${BLUE}   📂 Contenido del directorio:${NC}"
    ls -la
    
    # Limpiar builds anteriores
    rm -f "$service" 2>/dev/null
    
    # Verificar que existe main.go o archivos .go
    if [ ! -f "main.go" ] && [ ! -f "*.go" ] && [ $(ls -1 *.go 2>/dev/null | wc -l) -eq 0 ]; then
        echo -e "${RED}❌ No se encontraron archivos .go en $service${NC}"
        cd ..
        return 1
    fi
    
    # Limpiar módulos y reinstalar dependencias
    echo -e "${BLUE}   🧹 Limpiando módulos...${NC}"
    go mod tidy
    
    # Compilar con flags específicos
    echo -e "${BLUE}   🔨 Compilando...${NC}"
    if go build -v -o "$service" .; then
        echo -e "${GREEN}   ✅ Compilación exitosa${NC}"
        
        # Verificar que el ejecutable se creó
        if [ -f "$service" ]; then
            # Hacer ejecutable
            chmod +x "$service"
            
            # Verificar que es ejecutable
            if [ -x "$service" ]; then
                echo -e "${GREEN}   ✅ Ejecutable creado y configurado: $service${NC}"
                ls -la "$service"
                cd ..
                return 0
            else
                echo -e "${RED}   ❌ El archivo se creó pero no es ejecutable${NC}"
                cd ..
                return 1
            fi
        else
            echo -e "${RED}   ❌ El ejecutable no se creó${NC}"
            cd ..
            return 1
        fi
    else
        echo -e "${RED}   ❌ Error en la compilación${NC}"
        cd ..
        return 1
    fi
}

# Compilar cada servicio
for service in "${services[@]}"; do
    if compile_service "$service"; then
        ((success_count++))
    fi
    echo
done

echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}📊 Resumen de compilación:${NC}"
echo -e "${GREEN}✅ Servicios compilados exitosamente: $success_count/$total_count${NC}"

# Verificación final detallada
echo
echo -e "${YELLOW}🔍 Verificación final de ejecutables...${NC}"
echo -e "${YELLOW}======================================${NC}"

verified=0
for service in "${services[@]}"; do
    if [ -f "$service/$service" ] && [ -x "$service/$service" ]; then
        file_size=$(stat -f%z "$service/$service" 2>/dev/null || stat -c%s "$service/$service" 2>/dev/null)
        echo -e "${GREEN}✅ $service - OK (${file_size} bytes)${NC}"
        ((verified++))
    else
        echo -e "${RED}❌ $service - FALTA O NO EJECUTABLE${NC}"
        # Intentar encontrar el archivo
        if [ -d "$service" ]; then
            echo -e "${BLUE}   🔍 Buscando archivos en $service:${NC}"
            ls -la "$service/" | grep -E "(^-.*x.*|main|$service)"
        fi
    fi
done

echo
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}✅ Ejecutables verificados: $verified/$total_count${NC}"

if [ $verified -eq $total_count ]; then
    echo -e "${GREEN}🎉 ¡Todos los servicios compilados correctamente!${NC}"
    
    # Crear resumen de archivos
    echo
    echo -e "${YELLOW}📋 Resumen de ejecutables creados:${NC}"
    for service in "${services[@]}"; do
        if [ -f "$service/$service" ]; then
            echo "   $(pwd)/$service/$service"
        fi
    done
else
    echo -e "${RED}⚠️  Algunos servicios no se compilaron correctamente${NC}"
    echo -e "${YELLOW}💡 Verificando posibles problemas...${NC}"
    
    # Verificar Go
    echo -e "${BLUE}🔧 Versión de Go:${NC}"
    go version
    
    # Verificar variables de entorno
    echo -e "${BLUE}🔧 Variables de entorno de Go:${NC}"
    echo "GOPATH: $GOPATH"
    echo "GOROOT: $GOROOT"
    
    # Mostrar espacio en disco
    echo -e "${BLUE}🔧 Espacio en disco:${NC}"
    df -h .
fi

echo
echo -e "${BLUE}🔧 Script de solución completado${NC}" 