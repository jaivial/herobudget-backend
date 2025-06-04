# Guía de UI/UX para Hero Budget

## Introducción
Este documento define los estándares de interfaz de usuario y experiencia de usuario para la aplicación Hero Budget. Su propósito es mantener la coherencia en toda la aplicación y proporcionar una guía para futuras modificaciones y ampliaciones.

## Paleta de Colores

### Tema Claro
- **Color Primario**: `#6A1B9A` (Púrpura Profundo)
- **Color Secundario**: `#9C27B0` (Púrpura)
- **Color Terciario**: `#BA68C8` (Púrpura Claro)
- **Color de Fondo**: `#F3E5F5` (Lavanda Muy Claro)
- **Superficie**: `#FFFFFF` (Blanco)
- **Fondo de Scaffold**: `#F5F5F5` (Gris Muy Claro)

### Tema Oscuro
- **Color Primario**: `#BA68C8` (Púrpura Claro - Mejorado para legibilidad)
- **Color Secundario**: `#D1C4E9` (Lavanda Claro)
- **Color Terciario**: `#E1BEE7` (Lavanda Muy Claro)
- **Color de Fondo**: `#121212` (Casi Negro)
- **Superficie**: `#1E1E1E` (Gris Muy Oscuro)
- **Acento Púrpura**: `#BA68C8` (Púrpura Claro)

### Colores Semánticos
- **Éxito/Positivo**: `#4CAF50` (Verde)
- **Advertencia/En Riesgo**: `#FF9800` (Naranja)
- **Error/Negativo**: `#F44336` (Rojo)
- **Información**: `#2196F3` (Azul)
- **Heredado**: `#9C27B0` (Púrpura)

## Tipografía
Hero Budget utiliza la tipografía predeterminada de Material Design.

## Componentes de UI

### Botones
- **Botones Elevados**: Bordes redondeados con radio de 8px
- **Botones de Texto**: Color púrpura en tema oscuro

### Tarjetas
- **Tema Claro**: Fondo blanco
- **Tema Oscuro**: Color de superficie `#1E1E1E`

### Barras de Aplicación
- **Tema Claro**: Fondo blanco, texto negro, sin elevación
- **Tema Oscuro**: Color de superficie `#1E1E1E`, texto blanco, sin elevación

### Indicadores de Gasto
- **Badge de Porcentaje**: Fondo morado con texto blanco
- **Monto Restante Positivo**: Color verde
- **Monto Restante Negativo**: Color rojo
- **Indicador de Límite Excedido**: Borde rojo y señal de alerta

### Barras de Progreso
- **Gastos Realizados**: Segmento rojo
- **Gastos Próximos**: Segmento naranja
- **Fondo**: Gris claro
- **Indicador de 100%**: Círculo rojo con signo de exclamación

## Diseño y Espaciado
- Diseño coherente con Material Design 3
- Espaciado estándar entre elementos: 8px, 16px, 24px
- Márgenes de página consistentes

## Iconografía
- Uso de Material Icons para consistencia
- En tema oscuro: Color terciario `#D1C4E9`
- **Iconos específicos**:
  - Flujo de dinero: `account_balance_wallet`
  - Dinero heredado: `history`
  - Gastos: `arrow_upward`
  - Ingresos: `arrow_downward`
  - Tasa diaria: `calendar_today`
  - Facturas próximas: `calendar_today`

## Navegación
- **Navegación Inferior**: Barra de navegación simplificada con 3 botones:
  - Inicio (Home): Acceso al dashboard principal
  - Acciones Rápidas (+): Botón flotante central para acciones frecuentes
  - Perfil: Acceso a la configuración y perfil del usuario
- Navegación por cajón deslizable (Drawer) para funciones adicionales
- Navegación por pestañas para secciones relacionadas

## Diálogos y Alertas
- Fondo de tarjeta estándar
- Bordes redondeados
- Botones de acción alineados correctamente

## Formularios e Inputs
- Campos con bordes redondeados
- Validación visual clara
- Mensajes de error concisos

## Modo Oscuro/Claro
- Implementación completa de tema oscuro y claro
- Opción para cambiar entre modos en configuración
- Detección automática de preferencia del sistema

## Animaciones y Transiciones
- Transiciones suaves entre pantallas
- Animaciones sutiles para retroalimentación
- Uso de efectos de confeti para celebraciones/logros

## Accesibilidad
- Contraste adecuado para legibilidad
- Tamaños de fuente ajustables
- Soporte para lectores de pantalla

## Localización
- Soporte completo para múltiples idiomas
- Adaptación del diseño para diferentes longitudes de texto

### Sistema de Traducciones
- **Arquitectura**: Sistema basado en JSON con archivos en `assets/l10n/`
- **Idiomas Soportados**: 14 idiomas (en, es, fr, it, de, gsw, el, nl, da, ru, pt, zh, ja, hi)
- **Implementación**: 
  - `AppLocalizations` clase para manejo de traducciones
  - Extensión `context.tr.translate()` para acceso fácil
  - Fallback automático a inglés para claves faltantes
- **Detección de Idioma**: 
  - Detección automática del idioma del dispositivo
  - Almacenamiento de preferencia en SharedPreferences
  - Sincronización con el servidor (cuando está disponible)

### Resolución de Problemas de Localización
- **Problema común**: Pantallas mostrando solo en inglés
- **Causa principal**: Configuración incorrecta de locale o claves de traducción faltantes
- **Solución**: 
  1. Verificar que todas las claves existan en todos los archivos de idioma
  2. Comprobar la configuración de `MaterialApp.locale`
  3. Asegurar que `AppLocalizations.delegate` esté correctamente configurado
- **Fallback**: Sistema automático de fallback a inglés para claves no encontradas

## Elementos de UI específicos

### Widget de Flujo de Dinero
- **Estructura**: Organización vertical clara con secciones delimitadas
- **Encabezado**: Título a la izquierda y porcentaje de gasto a la derecha en morado
- **Monto Restante**: Número grande con color semántico (verde/rojo) según valor
- **Ingresos Totales**: Alineado a la derecha, tamaño más pequeño, color azul
- **Dinero Heredado**: Badge morado con icono de historial
- **Barra de Progreso**: 
  - Segmento rojo para gastos realizados
  - Segmento naranja para gastos próximos
  - Indicador de alerta cuando se supera el 100%
- **Gastos Combinados**: Con porcentaje y color semántico según nivel de gasto
- **Tasa Diaria**: Muestra el promedio diario de gasto con formato de divisa

## Directrices para Desarrolladores
1. Utilizar siempre constantes de color definidas en `app_theme.dart`
2. Mantener coherencia con Material Design 3
3. Probar en modo claro y oscuro
4. Implementar diseños responsivos que funcionen en diferentes tamaños de pantalla
5. Seguir las directrices de accesibilidad
6. Utilizar colores semánticos para comunicar estados (positivo, negativo, advertencia)

## Convenciones de Nomenclatura
- Nombres de componentes descriptivos y coherentes
- Prefijo de componentes reutilizables

## Proceso de Actualización
Este documento debe actualizarse cuando:
1. Se introduce un nuevo componente de UI
2. Se modifica la paleta de colores
3. Se cambian los estándares de diseño
4. Se añaden nuevas funcionalidades con elementos visuales únicos

## Flujo de Autenticación

### Verificación de Email Obligatoria

**Principio**: Ningún usuario puede acceder a la aplicación sin verificar su email.

#### Comportamiento en Inicio Automático
- Al abrir la app, si existe una sesión guardada, se verifica el estado de verificación del email
- Si el email no está verificado, se redirige automáticamente a `EmailOTPVerificationScreen`
- Se envía automáticamente un nuevo código OTP al email del usuario

#### Comportamiento en Login Manual
- Si el usuario intenta hacer login con credenciales válidas pero email no verificado:
  - No se muestra error de "credenciales incorrectas"
  - Se redirige automáticamente a `EmailOTPVerificationScreen`
  - Se envía automáticamente un nuevo código OTP

#### Pantalla de Verificación OTP
- **Ubicación**: `lib/screens/verification/email_otp_verification_screen.dart`
- **Funcionalidad**: 
  - Campos de entrada para código de 6 dígitos
  - Envío automático de código al cargar la pantalla
  - Botón de reenvío con cooldown de 60 segundos
  - Verificación automática al completar los 6 dígitos

#### Estados de Navegación
1. **Cuenta verificada**: Dashboard principal
2. **Cuenta no verificada**: Pantalla de verificación OTP
3. **Verificación exitosa**: Pantalla de éxito → Dashboard

### Consistencia Visual
- Mantener el mismo estilo de iconos y colores en todas las pantallas de verificación
- Usar `AppTheme.getPrimaryColor(context)` para elementos principales
- Mostrar feedback visual claro para estados de carga y error

### Experiencia de Usuario
- **Transparencia**: El usuario siempre sabe por qué está en la pantalla de verificación
- **Automatización**: Códigos se envían automáticamente sin intervención del usuario
- **Feedback**: Mensajes claros sobre el estado de envío y verificación de códigos

---
Última actualización: 2023-10-31 