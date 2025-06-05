import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/extensions.dart';
import '../main.dart';

/// Widget que escucha los cambios de idioma y automáticamente reconstruye su texto
/// cuando el idioma cambia.
class LocalizedText extends StatefulWidget {
  /// La clave de traducción que se usará
  final String translationKey;

  /// El estilo del texto (opcional)
  final TextStyle? style;

  /// Alineación del texto (opcional)
  final TextAlign? textAlign;

  /// Número máximo de líneas (opcional)
  final int? maxLines;

  /// Comportamiento de overflow (opcional)
  final TextOverflow? overflow;

  /// Si se debe centrar el texto usando Center (opcional)
  final bool center;

  /// Construye un widget de texto localizado
  const LocalizedText(
    this.translationKey, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.center = false,
  }) : super(key: key);

  @override
  State<LocalizedText> createState() => _LocalizedTextState();
}

class _LocalizedTextState extends State<LocalizedText> {
  StreamSubscription? _languageChangeSubscription;

  @override
  void initState() {
    super.initState();
    // Suscribirse a los cambios de idioma
    _languageChangeSubscription = languageChangeNotifier.languageChangeStream
        .listen((_) {
          // Forzar reconstrucción cuando cambia el idioma
          if (mounted) setState(() {});
        });
  }

  @override
  void dispose() {
    _languageChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el texto traducido, con un fallback al key original si no existe
    final translatedText = context.tr.translate(widget.translationKey);

    // Evitar parpadeos manteniendo la estructura del widget anterior
    final bool isEmpty = translatedText == widget.translationKey;

    // Construir el widget Text con las propiedades
    final textWidget = Text(
      translatedText,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );

    // Si se requiere centrar, envolver en un widget Center
    return widget.center ? Center(child: textWidget) : textWidget;
  }
}
