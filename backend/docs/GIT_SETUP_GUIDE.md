# 🗂️ Configuración Git y Repositorio Backend - Hero Budget

## 📋 Descripción

Esta guía te ayudará a configurar un repositorio Git dedicado para el backend de Hero Budget y preparar el sistema de despliegue automático.

**¿Por qué un repositorio separado para backend?**
- ✅ **Deployments independientes**: Backend y frontend se despliegan por separado
- ✅ **CI/CD especializado**: Pipelines específicos para microservicios
- ✅ **Versionado granular**: Control de versiones enfocado en APIs
- ✅ **Equipos especializados**: Desarrolladores backend pueden trabajar independientemente

## 🚀 Configuración Inicial del Repositorio

### Paso 1: Crear Repositorio Git en Backend

```bash
# Navegar a la carpeta backend
cd backend

# Inicializar repositorio Git
git init

# Configurar información del usuario (si no está configurado globalmente)
git config user.name "jaivial"
git config user.email "jaimevillalcon@hotmail.com"

# Crear archivo .gitignore específico para backend
cat > .gitignore << 'EOF'
# Ejecutables
*.exe
*.dll
*.so
*.dylib

# Archivos de prueba
test-*
*.test

# Base de datos local
*.db
*.sqlite3

# Logs
*.log
logs/

# Archivos de configuración sensibles
.env
config/production.json

# Archivos temporales
tmp/
temp/
*.tmp

# Archivos del sistema
.DS_Store
Thumbs.db

# IDE específicos
.vscode/
.idea/
*.swp
*.swo

# Dependencias (si usas Go modules)
vendor/

# Archivos de backup
*.bak
*.backup
EOF
```

### Paso 2: Configurar Estructura Básica

```bash
# Crear estructura de carpetas estándar
mkdir -p {scripts,config,docs,tests}

# Crear README específico del backend
cat > README.md << 'EOF'
# Hero Budget Backend

Microservicios backend para la aplicación Hero Budget.

## Estructura de Microservicios

- `google_auth/` - Autenticación con Google OAuth
- `expense_management/` - Gestión de gastos
- `income_management/` - Gestión de ingresos
- `budget_management/` - Gestión de presupuestos
- `dashboard_data/` - Datos del dashboard
- `bills_management/` - Gestión de facturas
- (... otros microservicios)

## Despliegue

Ver `docs/DEPLOYMENT.md` para instrucciones de despliegue.

## CI/CD

El sistema usa Jenkins para despliegue automático.
Ver `docs/CI_CD_SETUP.md` para configuración.
EOF

# Crear primer commit
git add .
git commit -m "Initial backend repository setup

- Added .gitignore for Go backend
- Created basic directory structure
- Added README with microservices overview"
```

### Paso 3: Conectar con Repositorio Remoto

```bash
# Opción A: GitHub (recomendado)
# Crear repositorio en GitHub: herobudget-backend
git remote add origin https://github.com/jaivial/herobudget-backend.git
git branch -M main
git push -u origin main

# Opción B: GitLab
git remote add origin https://gitlab.com/TU_USUARIO/herobudget-backend.git
git branch -M main
git push -u origin main

# Opción C: Repositorio privado propio
git remote add origin git@tu-servidor.com:herobudget-backend.git
git branch -M main
git push -u origin main
```

## 🔧 Configuración de Branches

### Estrategia de Branching Recomendada

```bash
# Crear branch de desarrollo
git checkout -b develop
git push -u origin develop

# Crear branch de staging/testing
git checkout -b staging
git push -u origin staging

# Proteger branch main (configurar en GitHub/GitLab)
# - Requerir pull requests
# - Requerir reviews
# - Proteger contra force push
```

### Flujo de Trabajo Recomendado

```
feature/nueva-funcionalidad → develop → staging → main → production
```

## 📁 Estructura del Repositorio Backend

```
backend/
├── .git/                          # Control de versiones
├── .gitignore                     # Archivos ignorados
├── README.md                      # Documentación principal
├── go.mod                         # Dependencias Go
├── go.sum                         # Checksums de dependencias
├── main.go                        # Punto de entrada principal
├── schema.sql                     # Esquema de base de datos
├── scripts/                       # Scripts de despliegue y gestión
│   ├── deploy_backend.sh          # Script de despliegue
│   ├── manage_services.sh         # Gestión de servicios
│   ├── jenkins_setup.sh           # Configuración Jenkins
│   └── Jenkinsfile               # Pipeline CI/CD
├── config/                        # Archivos de configuración
│   ├── development.json           # Config desarrollo
│   ├── staging.json              # Config staging
│   └── production.json           # Config producción
├── docs/                          # Documentación
│   ├── API.md                    # Documentación API
│   ├── DEPLOYMENT.md             # Guía de despliegue
│   └── CI_CD_SETUP.md           # Configuración CI/CD
├── tests/                         # Tests automatizados
├── google_auth/                   # Microservicio autenticación
├── expense_management/            # Microservicio gastos
├── income_management/             # Microservicio ingresos
├── budget_management/             # Microservicio presupuestos
├── dashboard_data/                # Microservicio dashboard
├── bills_management/              # Microservicio facturas
└── [otros microservicios]/
```

## 🛠️ Scripts de Gestión

### Script de Preparación para Commits

```bash
# Crear script pre-commit
cat > scripts/pre-commit.sh << 'EOF'
#!/bin/bash
# Script pre-commit para backend Hero Budget

echo "🔍 Ejecutando verificaciones pre-commit..."

# Verificar formato Go
if command -v gofmt &> /dev/null; then
    UNFORMATTED=$(gofmt -l .)
    if [ -n "$UNFORMATTED" ]; then
        echo "❌ Archivos sin formatear:"
        echo "$UNFORMATTED"
        echo "Ejecuta: gofmt -w ."
        exit 1
    fi
fi

# Verificar tests (si existen)
if [ -d "tests" ]; then
    echo "🧪 Ejecutando tests..."
    go test ./... || exit 1
fi

echo "✅ Verificaciones pre-commit completadas"
EOF

chmod +x scripts/pre-commit.sh

# Instalar hook pre-commit
cp scripts/pre-commit.sh .git/hooks/pre-commit
```

## 🚀 Preparación para Despliegue VPS

### Configurar Credenciales VPS

```bash
# Crear archivo de configuración de despliegue
cat > config/vps.conf << 'EOF'
# Configuración VPS Hero Budget Backend
VPS_HOST="178.16.130.178"
VPS_USER="root"
VPS_PATH="/opt/hero_budget/backend"
VPS_BACKUP_PATH="/opt/hero_budget/backups"
SYSTEMD_SERVICE="herobudget"
EOF

# OPCIÓN A: Configuración SSH automática (RECOMENDADO)
# Ejecutar script de configuración SSH
chmod +x scripts/setup_ssh.sh
./scripts/setup_ssh.sh

# OPCIÓN B: Configuración SSH manual
# PASO 1: Generar clave SSH si no existe
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "🔑 Generando clave SSH..."
    ssh-keygen -t rsa -b 4096 -C "jaimevillalcon@hotmail.com" -f ~/.ssh/id_rsa -N ""
    echo "✅ Clave SSH generada"
else
    echo "✅ Clave SSH ya existe"
fi

# PASO 2: Mostrar clave pública para verificación
echo "🔍 Tu clave pública SSH:"
cat ~/.ssh/id_rsa.pub

# PASO 3: Agregar clave SSH al VPS
echo "📤 Copiando clave SSH al VPS..."
ssh-copy-id root@178.16.130.178

# PASO 4: Verificar conexión
echo "🔍 Verificando conexión SSH..."
ssh root@178.16.130.178 "echo '✅ Conexión SSH exitosa - $(date)'"
```

### Preparar Estructura en VPS

```bash
# Crear script de preparación VPS
cat > scripts/prepare_vps.sh << 'EOF'
#!/bin/bash
# Preparar estructura en VPS para backend Hero Budget

VPS_HOST="178.16.130.178"
VPS_USER="root"

echo "🚀 Preparando estructura en VPS..."

ssh $VPS_USER@$VPS_HOST << 'ENDSSH'
# Crear directorios necesarios
mkdir -p /opt/hero_budget/{backend,backups,logs}

# Configurar permisos
chown -R root:root /opt/hero_budget
chmod -R 755 /opt/hero_budget

# Crear directorio para logs de microservicios
mkdir -p /var/log/herobudget

echo "✅ Estructura VPS preparada"
ENDSSH
EOF

chmod +x scripts/prepare_vps.sh
```

## 📋 Checklist de Configuración

### ✅ Configuración Básica
- [ ] Repositorio Git inicializado en `backend/`
- [ ] `.gitignore` configurado para proyectos Go
- [ ] `README.md` creado con información del proyecto
- [ ] Estructura de carpetas básica creada
- [ ] Primer commit realizado

### ✅ Repositorio Remoto
- [ ] Repositorio remoto creado (GitHub/GitLab)
- [ ] Remote origin configurado
- [ ] Branch main protegido
- [ ] Branches develop y staging creados

### ✅ Preparación Despliegue
- [ ] SSH configurado para VPS
- [ ] Credenciales VPS documentadas
- [ ] Script de preparación VPS ejecutado
- [ ] Estructura en VPS verificada

### ✅ Scripts y Herramientas
- [ ] Script pre-commit instalado
- [ ] Configuración de despliegue creada
- [ ] Hooks Git configurados

## 🔄 Flujo de Desarrollo Diario

### 1. Antes de Empezar a Trabajar
```bash
git checkout develop
git pull origin develop
git checkout -b feature/nueva-funcionalidad
```

### 2. Durante el Desarrollo
```bash
# Hacer cambios en código
git add .
git commit -m "feat: descripción del cambio"
```

### 3. Finalizar Feature
```bash
git checkout develop
git pull origin develop
git checkout feature/nueva-funcionalidad
git rebase develop
git checkout develop
git merge feature/nueva-funcionalidad
git push origin develop
```

### 4. Despliegue a Staging
```bash
git checkout staging
git merge develop
git push origin staging
# Jenkins automáticamente desplegará a staging
```

### 5. Despliegue a Producción
```bash
git checkout main
git merge staging
git push origin main
# Jenkins automáticamente desplegará a producción
```

## 🚨 Troubleshooting

### Error: "Permission denied (publickey)"
**Solución:** Configurar SSH correctamente
```bash
ssh-keygen -t ed25519 -C "tu.email@ejemplo.com"
ssh-copy-id root@178.16.130.178
```

### Error: "Remote origin already exists"
**Solución:** Actualizar remote existente
```bash
git remote set-url origin https://github.com/TU_USUARIO/herobudget-backend.git
```

### Error: "Working directory not clean"
**Solución:** Confirmar o descartar cambios
```bash
git status
git add . && git commit -m "WIP: trabajo en progreso"
# o
git stash
```

---

**📝 Nota:** Una vez completada esta configuración, continúa con la guía de despliegue VPS en `docs/VPS_DEPLOYMENT_GUIDE.md` 