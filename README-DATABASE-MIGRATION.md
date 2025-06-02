# 🗄️ Migración de Base de Datos - Hero Budget

## 📋 Descripción

Esta guía te ayudará a migrar tu base de datos SQLite local a PostgreSQL en el VPS de producción.

**¿Por qué migrar?**
- ✅ **Escalabilidad**: PostgreSQL maneja mejor múltiples conexiones concurrentes
- ✅ **Rendimiento**: Mejor optimización para consultas complejas  
- ✅ **Integridad**: ACID compliance y transacciones robustas
- ✅ **Backup**: Herramientas de backup y recovery más avanzadas
- ✅ **Producción**: Base de datos preparada para entorno empresarial

## 📁 Archivos de Migración

| Archivo | Descripción |
|---------|-------------|
| `setup-vps-postgresql.sh` | Configura PostgreSQL en el VPS |
| `migrate-database-to-vps.sh` | Migra datos de SQLite a PostgreSQL |
| `README-DATABASE-MIGRATION.md` | Esta guía de migración |

## 🚀 Proceso de Migración (3 Pasos)

### Paso 1: Configurar PostgreSQL en VPS

```bash
# Ejecutar desde tu máquina local
./setup-vps-postgresql.sh
```

**¿Qué hace este script?**
- ✅ Instala PostgreSQL en el VPS (si no está instalado)
- ✅ Crea la base de datos `herobudget`
- ✅ Crea el usuario `herobudget_user` con permisos
- ✅ Configura directorios de backup
- ✅ Verifica conectividad de la base de datos
- ✅ Actualiza credenciales en el script de migración

**Credenciales generadas:**
- **Base de datos**: `herobudget`
- **Usuario**: `herobudget_user`
- **Password**: `HeroBudget2024!Secure`

### Paso 2: Ejecutar Migración

```bash
# Ejecutar desde tu máquina local
./migrate-database-to-vps.sh
```

**¿Qué hace este script?**
- ✅ Verifica que la base SQLite local existe
- ✅ Exporta datos de SQLite
- ✅ Convierte formato SQLite → PostgreSQL
- ✅ Crea backup de la base actual en VPS
- ✅ Detiene servicios Hero Budget temporalmente
- ✅ Importa datos a PostgreSQL en VPS
- ✅ Verifica migración exitosa
- ✅ Reinicia servicios Hero Budget

### Paso 3: Verificar Migración

```bash
# Verificar que el VPS está funcionando
./verify-herobudget-setup.sh

# Test endpoints específicos
curl https://herobudget.jaimedigitalstudio.com/health
curl -X POST https://herobudget.jaimedigitalstudio.com/auth/google
```

## 🔍 Detalles de la Migración

### Base de Datos Local (Origen)
```
Archivo: /Users/usuario/Documents/PROYECTOS/herobudgetflutter/hero_budget/backend/google_auth/users.db
Tipo: SQLite 3
Tabla principal: users
```

### Base de Datos VPS (Destino)
```
Servidor: 178.16.130.178
Tipo: PostgreSQL 14+
Base de datos: herobudget
Usuario: herobudget_user
Tabla principal: users
```

### Esquema de la Tabla `users`

**SQLite (Origen):**
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    google_id TEXT UNIQUE,
    email TEXT UNIQUE,
    name TEXT,
    given_name TEXT,
    family_name TEXT,
    picture TEXT,
    locale TEXT,
    verified_email INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**PostgreSQL (Destino):**
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    google_id TEXT UNIQUE,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    given_name TEXT,
    family_name TEXT,
    picture TEXT,
    locale TEXT DEFAULT 'es',
    verified_email BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Conversiones Realizadas

| SQLite | PostgreSQL | Descripción |
|--------|------------|-------------|
| `INTEGER PRIMARY KEY AUTOINCREMENT` | `SERIAL PRIMARY KEY` | Auto-incremento |
| `INTEGER` (boolean) | `BOOLEAN` | Valores booleanos |
| `DATETIME` | `TIMESTAMP` | Fechas y horas |
| `0/1` | `false/true` | Valores booleanos |

## 🛡️ Seguridad y Backups

### Backup Automático
El script crea automáticamente un backup antes de la migración:
```
Ubicación: /opt/hero_budget/backups/
Formato: herobudget_backup_YYYYMMDD_HHMMSS.sql
```

### Rollback en Caso de Error
Si la migración falla, el script automáticamente:
1. Restaura la base de datos desde el backup
2. Reinicia los servicios Hero Budget
3. Reporta el error para debugging

### Verificación de Integridad
El script verifica que:
- ✅ Número de usuarios migrados coincide
- ✅ Conectividad a la base funciona
- ✅ Servicios Hero Budget responden
- ✅ Endpoints están accesibles

## 🔧 Personalización

### Cambiar Credenciales de Base de Datos

Si quieres usar credenciales diferentes, edita estas variables en `setup-vps-postgresql.sh`:

```bash
POSTGRES_DB="herobudget"                    # Nombre de la base de datos
POSTGRES_USER="herobudget_user"             # Usuario de la base de datos  
POSTGRES_PASSWORD="HeroBudget2024!Secure"   # Password (usa uno seguro)
```

### Cambiar Ubicación de SQLite

Si tu base SQLite está en otra ubicación, edita esta variable en `migrate-database-to-vps.sh`:

```bash
LOCAL_SQLITE_DB="/ruta/a/tu/database.db"
```

## 🚨 Troubleshooting

### Error: "SQLite database not found"
**Solución:** Verifica que el archivo existe:
```bash
ls -la /Users/usuario/Documents/PROYECTOS/herobudgetflutter/hero_budget/backend/google_auth/users.db
```

### Error: "PostgreSQL connection failed"
**Solución:** Ejecuta primero el setup de PostgreSQL:
```bash
./setup-vps-postgresql.sh
```

### Error: "Migration failed"
**Solución:** Verifica logs y restaura backup:
```bash
# En el VPS
ssh root@178.16.130.178
cd /opt/hero_budget/backups
ls -la  # Ver backups disponibles
sudo -u postgres psql -d herobudget < [backup_file].sql
```

### Error: "Services not responding"
**Solución:** Reinicia servicios manualmente:
```bash
# En el VPS
ssh root@178.16.130.178
systemctl restart herobudget
systemctl status herobudget
```

## ✅ Verificación Post-Migración

### 1. Verificar Datos en PostgreSQL
```bash
# Conectar al VPS
ssh root@178.16.130.178

# Verificar datos migrados
sudo -u postgres psql -d herobudget -c "SELECT COUNT(*) FROM users;"
sudo -u postgres psql -d herobudget -c "SELECT email, name, created_at FROM users LIMIT 5;"
```

### 2. Probar Autenticación
```bash
# Test de Google Auth
curl -X POST https://herobudget.jaimedigitalstudio.com/auth/google \
  -H "Content-Type: application/json" \
  -d '{"token":"test_token"}'
```

### 3. Monitorear Logs
```bash
# En el VPS
journalctl -u herobudget -f
tail -f /var/log/nginx/herobudget_*.log
```

## 📈 Beneficios Post-Migración

### Performance Mejorado
- ✅ **Conexiones concurrentes**: PostgreSQL maneja múltiples users simultáneamente
- ✅ **Consultas optimizadas**: Mejores índices y query planning
- ✅ **Cache inteligente**: Buffer pools y shared memory

### Escalabilidad
- ✅ **Horizontal scaling**: Preparado para múltiples replicas
- ✅ **Vertical scaling**: Mejor uso de CPU y memoria
- ✅ **Connection pooling**: Gestión eficiente de conexiones

### Mantenimiento
- ✅ **Backups automáticos**: Scripts de pg_dump programados
- ✅ **Monitoring**: Métricas detalladas de performance
- ✅ **Logs estructurados**: Mejor debugging y auditoría

## 🔄 Mantenimiento Continuo

### Backups Regulares
```bash
# Script de backup diario (programar en cron)
#!/bin/bash
sudo -u postgres pg_dump herobudget > "/opt/hero_budget/backups/daily_backup_$(date +%Y%m%d).sql"
```

### Limpieza de Backups Antiguos
```bash
# Mantener solo backups de últimos 30 días
find /opt/hero_budget/backups -name "*.sql" -mtime +30 -delete
```

### Monitoreo de Rendimiento
```bash
# Ver conexiones activas
sudo -u postgres psql -d herobudget -c "SELECT * FROM pg_stat_activity;"

# Ver tamaño de base de datos
sudo -u postgres psql -d herobudget -c "SELECT pg_size_pretty(pg_database_size('herobudget'));"
```

---

## 🎉 ¡Migración Completada!

Una vez completada la migración exitosamente:

✅ **Tu base de datos SQLite local ha sido migrada a PostgreSQL en el VPS**  
✅ **Los usuarios existentes pueden seguir autenticándose normalmente**  
✅ **Los microservicios están conectados a la nueva base de datos**  
✅ **El sistema está preparado para escalar en producción**

### Próximos Pasos Recomendados

1. **Actualizar Flutter App** para usar endpoints de producción
2. **Configurar monitoring** (Grafana, Prometheus)
3. **Implementar CI/CD** para deployments automáticos
4. **Configurar alertas** para monitoreo proactivo
5. **Documentar APIs** con Swagger/OpenAPI

---

**📞 Soporte:** Si encuentras problemas, revisa los logs en `/opt/hero_budget/backups/` y `/var/log/nginx/herobudget_*.log` 