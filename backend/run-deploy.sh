#!/bin/bash

# =============================================================================
# HERO BUDGET - DEPLOYMENT WRAPPER
# =============================================================================
# Wrapper para asegurar que deploy-microservices-to-vps.sh se ejecute con bash
# =============================================================================

# Verificar que bash esté disponible
if ! command -v bash >/dev/null 2>&1; then
    echo "❌ Error: bash no está disponible en el sistema"
    exit 1
fi

# Obtener directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-microservices-to-vps.sh"

# Verificar que el script existe
if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
    echo "❌ Error: No se encuentra deploy-microservices-to-vps.sh"
    echo "   Buscando en: $DEPLOY_SCRIPT"
    exit 1
fi

# Hacer ejecutable si no lo es
if [[ ! -x "$DEPLOY_SCRIPT" ]]; then
    chmod +x "$DEPLOY_SCRIPT"
fi

echo "🚀 Ejecutando deployment de microservicios con bash..."
echo "📁 Script: $DEPLOY_SCRIPT"
echo "🖥️  Shell: $(bash --version | head -1)"
echo ""

# Ejecutar con bash explícitamente
exec bash "$DEPLOY_SCRIPT" "$@" 