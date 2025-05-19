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
- **Color Primario**: `#6A1B9A` (Púrpura Profundo)
- **Color Secundario**: `#BA68C8` (Púrpura Claro)
- **Color Terciario**: `#D1C4E9` (Lavanda Claro)
- **Color de Fondo**: `#121212` (Casi Negro)
- **Superficie**: `#1E1E1E` (Gris Muy Oscuro)
- **Acento Púrpura**: `#9C27B0` (Púrpura)

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

## Diseño y Espaciado
- Diseño coherente con Material Design 3
- Espaciado estándar entre elementos: 8px, 16px, 24px
- Márgenes de página consistentes

## Iconografía
- Uso de Material Icons para consistencia
- En tema oscuro: Color terciario `#D1C4E9`

## Navegación
- Navegación por cajón deslizable (Drawer)
- Navegación de fondo para acciones principales
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

## Directrices para Desarrolladores
1. Utilizar siempre constantes de color definidas en `app_theme.dart`
2. Mantener coherencia con Material Design 3
3. Probar en modo claro y oscuro
4. Implementar diseños responsivos que funcionen en diferentes tamaños de pantalla
5. Seguir las directrices de accesibilidad

## Convenciones de Nomenclatura
- Nombres de componentes descriptivos y coherentes
- Prefijo de componentes reutilizables

## Proceso de Actualización
Este documento debe actualizarse cuando:
1. Se introduce un nuevo componente de UI
2. Se modifica la paleta de colores
3. Se cambian los estándares de diseño
4. Se añaden nuevas funcionalidades con elementos visuales únicos

---
Última actualización: [Fecha actual] 