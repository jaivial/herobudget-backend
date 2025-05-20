# Registro de Cambios

Todos los cambios notables en este proyecto se documentarán en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Sin publicar]

### Añadido
- Nuevo widget de selección para filtrar por periodos en cada pantalla.
- Función de autocompletado para categorías en formularios de gastos e ingresos.
- Implementación del análisis predictivo de gastos mensuales.
- Widget para mostrar consejos de ahorro basados en patrones de gasto.
- Tasa diaria de gasto en el widget de flujo de dinero.
- Posibilidad de navegar hacia fechas futuras en el selector de periodos para planificación financiera.
- Compatibilidad del backend para procesar consultas con fechas futuras.
- Adición de parámetro de fecha específica en las peticiones al backend para mostrar datos precisos según el periodo seleccionado.
- Sistema de caché para almacenar y mantener los datos por tipo de periodo y fecha.
- Sistema de proyección de datos para meses sin transacciones, basado en patrones históricos.

### Cambiado
- Reorganización completa del widget de flujo de dinero con mejor diseño visual.
- Mejora en la visualización del porcentaje de gasto (ahora en morado).
- Optimización del gráfico de barras para representar gastos realizados y próximos.
- Adición de indicador visual cuando se supera el 100% del presupuesto.
- Implementación de tema oscuro en todos los componentes de la aplicación.
- Actualizada la fórmula de cálculo de tasa diaria en la API backend.
- Modificado el selector de periodos para mantener la coherencia de datos al navegar entre diferentes periodos.
- Mejorada la lógica de persistencia entre navegaciones temporales para mantener el estado.

### Corregido
- Arreglado un problema crítico en la navegación temporal del presupuesto que causaba que la UI se reiniciara y mostrara datos incorrectos después de múltiples avances/retrocesos.
- Corregido un error específico donde al avanzar a meses futuros o retroceder a meses pasados se reiniciaban los datos a cero.
- Modificado el componente `period_selector.dart` para implementar un sistema de persistencia de navegación por tipo de período.
- Mejorado el manejo de fechas en la navegación temporal para evitar fechas inválidas cuando se cambia entre meses de diferente duración.
- Agregada validación de rango de fechas para evitar navegación a períodos futuros lejanos.
- Corregido el microservicio `money_flow_calculation` para mejorar el manejo de fechas personalizadas y evitar el restablecimiento silencioso a la fecha actual.
- Implementado sistema de proyección de datos históricos para meses sin transacciones registradas.
- Solución al problema donde los datos de budget overview no se actualizaban al cambiar de periodo.
- Eliminada la restricción que impedía navegar a periodos futuros.
- Corregido el cálculo de fechas en el backend para usar la fecha seleccionada por el usuario en lugar de siempre la fecha actual.
- Solución al problema de visualización en dispositivos con pantalla pequeña.
- Corrección de error en el cálculo del saldo heredado de periodos anteriores.

### Mejoras técnicas
- Implementado un sistema de persistencia del estado de navegación temporal que conserva el contexto al cambiar entre tipos de período.
- Implementado sistema de caché de datos en el frontend para mantener la consistencia entre navegaciones.
- Modificada la lógica de navegación para preservar las fechas seleccionadas para cada tipo de período independientemente.
- Añadido sistema de validación para garantizar que las fechas calculadas sean siempre válidas.
- Implementada proyección de datos basada en patrones históricos para meses sin transacciones registradas.
- Mejorado el sistema de logging en los microservicios Go para facilitar el diagnóstico y seguimiento de errores.
- Implementado pequeño retraso entre la actualización de la UI y las peticiones al backend para resolver problemas de sincronización.
- Agregado extensivo registro (logs) para diagnóstico en los componentes de UI y servicios del backend.

## [1.2.0] - 2023-09-15

### Añadido
- Nueva funcionalidad para programar recordatorios de pago.
- Exportación de informes en formato PDF y CSV.
- Integración con servicios bancarios para sincronización automática.

### Cambiado
- Rediseño del panel de control para mayor claridad visual.
- Mejora en la velocidad de carga de datos históricos.

### Corregido
- Solución al problema de sincronización en dispositivos iOS.
- Corrección del fallo en la visualización de gráficos semanales.

## [1.1.0] - 2023-06-30

### Añadido
- Funcionalidad multi-cuenta para gestionar diferentes presupuestos.
- Widget de flujo de dinero mensual con visualización de gastos e ingresos.
- Categorización automática de gastos basada en patrones de usuario.

### Cambiado
- Mejorada la interfaz para edición de transacciones.
- Optimización del rendimiento en dispositivos de gama media.

### Corregido
- Solución a problemas de autenticación con Google.
- Corrección de errores en el cálculo de presupuestos recurrentes.

## [1.0.0] - 2023-03-15

### Añadido
- Lanzamiento inicial de la aplicación Hero Budget.
- Funcionalidades básicas de gestión de presupuestos.
- Sistema de autenticación y perfiles de usuario.
- Registro de gastos e ingresos con categorización.
- Visualización de estadísticas básicas.

---
Última actualización: 2023-11-30 