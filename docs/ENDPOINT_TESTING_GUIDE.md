# Guía de Testing de Endpoints - Hero Budget

## Descripción

Esta guía proporciona instrucciones completas para probar todos los endpoints de Hero Budget, identificar problemas comunes y sus soluciones.

## 🛠️ Herramientas de Testing

### 1. Script de Validación Automática

```bash
# Testing local (requiere servicios corriendo)
python scripts/endpoint_validation.py local

# Testing producción  
python scripts/endpoint_validation.py production
```

### 2. Pruebas Manuales con cURL

#### 🔐 Endpoints de Autenticación

```bash
# Health check general
curl -X GET "https://herobudget.jaimedigitalstudio.com/health"

# Verificar email para signup
curl -X POST "https://herobudget.jaimedigitalstudio.com/signup/check-email" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'

# Verificar email para signin
curl -X POST "https://herobudget.jaimedigitalstudio.com/signin/check-email" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

#### 💰 Endpoints Financieros

```bash
# Cash/Bank Distribution
curl -X GET "https://herobudget.jaimedigitalstudio.com/cash-bank/distribution?user_id=test_user"

# Transfer Cash to Bank
curl -X POST "https://herobudget.jaimedigitalstudio.com/transfer/cash-to-bank" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test_user","amount":100.0,"date":"2025-01-15T10:00:00Z"}'

# Transfer Bank to Cash
curl -X POST "https://herobudget.jaimedigitalstudio.com/transfer/bank-to-cash" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test_user","amount":50.0,"date":"2025-01-15T10:00:00Z"}'
```

#### 📊 Endpoints de Transacciones

```bash
# Budget Overview
curl -X GET "https://herobudget.jaimedigitalstudio.com/budget-overview?user_id=test_user"

# Transaction History
curl -X GET "https://herobudget.jaimedigitalstudio.com/transactions/history?user_id=test_user"

# Categories
curl -X GET "https://herobudget.jaimedigitalstudio.com/categories?user_id=test_user"
```

## 🚨 Problemas Comunes y Soluciones

### Error 404 - Endpoint No Encontrado

**Síntomas:**
```json
{"error":"Endpoint not found","available_endpoints":[...]}
```

**Causas Posibles:**
1. URL incorrecta en el frontend
2. Endpoint no configurado en nginx
3. Servicio no corriendo en el puerto especificado

**Solución:**
1. Verificar configuración en `lib/config/api_config.dart`
2. Verificar nginx config en `/etc/nginx/sites-available/herobudget`
3. Verificar servicios corriendo: `sudo systemctl status herobudget-*`

### Error 500 - Internal Server Error

**Síntomas:**
```json
{"error":"Internal server error"}
```

**Causas Posibles:**
1. Error en base de datos (tabla no existe)
2. Validación de datos fallida
3. Conexión a BD perdida

**Solución para Cash/Bank 500s:**
```bash
# Verificar que tablas existan
sqlite3 backend/google_auth/users.db ".schema monthly_cash_bank_balance"

# Recrear tablas si es necesario
cd backend/cash_bank_management
go run main.go  # Esto recreará tablas automáticamente
```

### Error 422 - Validation Error  

**Síntomas:**
```json
{"error":"User ID is required"}
```

**Causa:** Payloads de testing incorrectos

**Solución:**
Usar payloads apropiados según el endpoint:

```json
// Para endpoints que requieren user_id
{"user_id": "valid_user_id", "amount": 100.0}

// Para endpoints de email
{"email": "valid@email.com"}

// Para transferencias
{"user_id": "test_user", "amount": 100.0, "date": "2025-01-15T10:00:00Z"}
```

### Error de Conexión - Service Unreachable

**Síntomas:**
```
Connection refused / Service not running
```

**Solución:**
```bash
# Verificar servicios locales
./start_services.sh

# Verificar servicios en producción
sudo systemctl status herobudget-*
sudo systemctl restart herobudget-cash-bank
```

## 📋 Checklist de Testing

### ✅ Pre-requisitos para Testing Local

- [ ] Backend services corriendo (`./start_services.sh`)
- [ ] Base de datos SQLite en `backend/google_auth/users.db`
- [ ] Python con requests instalado (`pip install requests`)
- [ ] Puertos 8081-8098 disponibles

### ✅ Pre-requisitos para Testing Producción

- [ ] Dominio `herobudget.jaimedigitalstudio.com` accesible
- [ ] SSL certificate válido
- [ ] Servicios systemd corriendo
- [ ] Nginx configurado correctamente

### ✅ Tests Críticos a Ejecutar

1. **Health Check General**
   ```bash
   curl -X GET "https://herobudget.jaimedigitalstudio.com/health"
   # Esperado: 200 OK
   ```

2. **Cash/Bank Distribution**
   ```bash
   curl -X GET "https://herobudget.jaimedigitalstudio.com/cash-bank/distribution?user_id=19"
   # Esperado: 200 OK con JSON de distribución
   ```

3. **Transfer Endpoints**
   ```bash
   # Test bank to cash
   curl -X POST "https://herobudget.jaimedigitalstudio.com/transfer/bank-to-cash" \
     -H "Content-Type: application/json" \
     -d '{"user_id":"19","amount":200}'
   # Esperado: 200 OK
   ```

4. **Budget Overview**
   ```bash
   curl -X GET "https://herobudget.jaimedigitalstudio.com/budget-overview?user_id=19"
   # Esperado: 200 OK con datos de presupuesto
   ```

## 🔧 Configuración de Payloads por Endpoint

| Endpoint | Método | Payload Requerido |
|----------|--------|-------------------|
| `/health` | GET | Ninguno |
| `/signup/check-email` | POST | `{"email":"test@example.com"}` |
| `/signin/check-email` | POST | `{"email":"test@example.com"}` |
| `/cash-bank/distribution` | GET | `?user_id=test_user` |
| `/transfer/cash-to-bank` | POST | `{"user_id":"test","amount":100,"date":"2025-01-15"}` |
| `/transfer/bank-to-cash` | POST | `{"user_id":"test","amount":100,"date":"2025-01-15"}` |
| `/budget-overview` | GET | `?user_id=test_user` |
| `/transactions/history` | GET | `?user_id=test_user` |
| `/categories` | GET | `?user_id=test_user` |

## 📊 Interpretación de Resultados

### ✅ Resultado Exitoso (200 OK)
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { /* datos del endpoint */ }
}
```

### ❌ Error de Validación (400/422)
```json
{
  "success": false,
  "message": "User ID is required",
  "error": "validation_error"
}
```

### 🔥 Error de Servidor (500)
```json
{
  "success": false,
  "message": "Internal server error",
  "error": "database_error"
}
```

### 🔌 Error de Conexión
```
curl: (7) Failed to connect to localhost port 8090: Connection refused
```

## 🛡️ Troubleshooting Avanzado

### Verificar Estado de Servicios
```bash
# Local
ps aux | grep "port 809"

# Producción
sudo systemctl list-units --state=active | grep herobudget
```

### Verificar Logs de Errores
```bash
# Nginx logs
sudo tail -f /var/log/nginx/herobudget_error.log

# Service logs
sudo journalctl -f -u herobudget-cash-bank
```

### Verificar Base de Datos
```bash
# Conectar a SQLite
sqlite3 backend/google_auth/users.db

# Verificar tablas críticas
.tables
SELECT COUNT(*) FROM monthly_cash_bank_balance;
```

### Recrear Configuración de Nginx
```bash
# Recargar configuración
sudo nginx -t
sudo systemctl reload nginx
```

## 📈 Métricas de Testing

Un testing exitoso debe mostrar:
- **Success Rate**: > 90%
- **Response Time**: < 500ms para la mayoría de endpoints
- **Error Rate**: < 5% de errores 500
- **Availability**: > 99% de endpoints accesibles

## 🎯 Próximos Pasos

Después de ejecutar tests:

1. **Si Success Rate < 90%**: Investigar servicios caídos
2. **Si hay errores 500**: Verificar logs y base de datos  
3. **Si hay errores 404**: Verificar configuración nginx
4. **Si todos los tests pasan**: ✅ Sistema listo para producción 