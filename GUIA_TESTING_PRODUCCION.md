# 🚀 Guía de Testing en Producción - Hero Budget

## 🎯 Objetivo

Verificar que todas las correcciones de APIs funcionen correctamente en el ambiente de producción.

## 🔄 Cómo Cambiar a Producción

### Opción 1: Código (Temporal)
```dart
// En main.dart, antes de runApp():
void main() {
  EnvironmentConfig.forceProduction();  // ← Agregar esta línea
  runApp(HeroBudgetApp());
}
```

### Opción 2: Build de Release (Automático)
```bash
# Para iOS
flutter build ios --release

# Para Android  
flutter build apk --release
```

### Opción 3: Testing Rápido con ApiConfig
```dart
// En cualquier parte del código donde necesites verificar:
ApiConfig.switchToProductionAndShow();  // Cambia a producción y muestra URLs
```

## 🧪 Verificación de URLs

### 1. Verificar URLs Generadas
```dart
// Agregar en cualquier parte donde puedas hacer print():
ApiConfig.printProductionUrls();
```

**Output esperado:**
```
🚀 PRODUCTION URLs VERIFICATION:
Base URL: https://herobudget.jaimedigitalstudio.com

💰 Financial Operations:
  Income: https://herobudget.jaimedigitalstudio.com/incomes
  Expense: https://herobudget.jaimedigitalstudio.com/expenses
```

### 2. Verificar URLs Específicas de Income/Expense
```dart
ApiConfig.printIncomeExpenseUrls();
```

## 📱 Testing de Funcionalidades

### ✅ 1. Google Authentication
**Qué probar:**
- Login con Google
- Obtención de token/session
- Verificar que se guarda user_id

**URL esperada:** `https://herobudget.jaimedigitalstudio.com/auth/google`

### ✅ 2. Income Management
**Qué probar:**
- Agregar income desde dashboard
- Agregar income desde income service
- Ver lista de incomes
- Editar/eliminar income

**URLs esperadas:**
- Add: `https://herobudget.jaimedigitalstudio.com/incomes/add`
- Get: `https://herobudget.jaimedigitalstudio.com/incomes?user_id=X`

### ✅ 3. Expense Management  
**Qué probar:**
- Agregar expense desde dashboard
- Agregar expense desde expense service
- Ver lista de expenses
- Editar/eliminar expense

**URLs esperadas:**
- Add: `https://herobudget.jaimedigitalstudio.com/expenses/add`
- Get: `https://herobudget.jaimedigitalstudio.com/expenses?user_id=X`

### ✅ 4. Budget Overview
**Qué probar:**
- Cambiar períodos (weekly, monthly)
- Verificar que se actualicen las métricas
- Money flow calculations

**URL esperada:** `https://herobudget.jaimedigitalstudio.com/budget-overview`

### ✅ 5. Dashboard Data
**Qué probar:**
- Carga inicial del dashboard
- Refresh de datos
- Navegación entre períodos

## 🔍 Debugging en Producción

### 1. Logs de Network
Verificar en logs que aparezcan URLs como:
```
📡 Response status: 200
📦 Response body: {"success":true...}
🔄 BudgetOverviewService: Making request to https://herobudget.jaimedigitalstudio.com/budget-overview
```

### 2. Errores Comunes
```bash
# ❌ Si ves esto, hay problema:
❌ Error 404 - https://herobudget.jaimedigitalstudio.com/income/add

# ✅ Debería ser esto:
✅ Success 200 - https://herobudget.jaimedigitalstudio.com/incomes/add
```

### 3. Testing Manual con cURL (Si tienes acceso al backend)
```bash
# Test básico de conectividad
curl -X GET "https://herobudget.jaimedigitalstudio.com/health" 

# Test income add
curl -X POST "https://herobudget.jaimedigitalstudio.com/incomes/add" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","amount":100,"category":"Test"}'

# Test expense add  
curl -X POST "https://herobudget.jaimedigitalstudio.com/expenses/add" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","amount":50,"category":"Test"}'
```

## 🚨 Problemas Potenciales y Soluciones

### 1. CORS Issues
**Error:** `CORS policy: No 'Access-Control-Allow-Origin' header`
**Solución:** Backend debe configurar CORS para requests móviles

### 2. HTTPS Certificate Issues
**Error:** `Certificate verification failed`
**Solución:** Verificar que el certificado SSL esté válido

### 3. Network Timeouts
**Error:** `TimeoutException`
**Solución:** Aumentar timeouts en production o verificar conectividad

### 4. 404 Errors Persistentes
**Error:** URLs returning 404
**Posibles causas:**
- Backend no deployado con endpoints esperados
- Routing incorrecto en servidor
- Paths diferentes en producción vs desarrollo

## 📋 Checklist de Testing

### Pre-Testing
- [ ] Switch a modo producción activado
- [ ] URLs de producción verificadas con `printProductionUrls()`
- [ ] Backend de producción funcionando

### Core Functionality
- [ ] Login con Google funciona
- [ ] Dashboard carga sin errores 404
- [ ] Budget overview se actualiza
- [ ] Cambio de períodos funciona

### Income/Expense Operations
- [ ] Agregar income desde dashboard
- [ ] Agregar expense desde dashboard  
- [ ] Ver lista de incomes
- [ ] Ver lista de expenses
- [ ] Editar income/expense
- [ ] Eliminar income/expense

### Performance & UX
- [ ] Tiempos de respuesta aceptables
- [ ] No hay errores en logs
- [ ] UI responde correctamente
- [ ] Datos se persisten correctamente

## 🏁 Resultado Esperado

Al completar todos los tests, deberías ver en los logs algo como:

```
✅ Budget overview received successfully
✅ Income added successfully  
✅ Expense added successfully
✅ Dashboard data loaded successfully
💰 All financial operations working correctly
```

## 🆘 Si Algo Falla

1. **Verificar URLs**: `ApiConfig.printProductionUrls()`
2. **Verificar ambiente**: `EnvironmentConfig.printEnvironmentInfo()`
3. **Volver a localhost**: `ApiConfig.switchToLocalhostAndShow()`
4. **Revisar logs** para URLs incorrectas
5. **Contactar backend team** si los endpoints no responden

---

**Status**: 🚀 Ready for Production Testing  
**Last Updated**: 2025-05-30  
**Estimated Testing Time**: 30-45 minutes 