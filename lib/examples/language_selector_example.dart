import 'package:flutter/material.dart';
import '../services/app_service.dart';
import '../utils/screen_wrapper_extension.dart';
import '../widgets/language_widgets.dart';

/// Este archivo muestra tres formas diferentes de implementar el botón selector de idioma
/// en cualquier pantalla de la aplicación.

class LanguageSelectorExampleScreen extends StatelessWidget {
  const LanguageSelectorExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ejemplo 1: Usando el método de extensión .withLanguageSelector()
    return _buildContentWidget().withLanguageSelector(
      // Puedes proporcionar tu propio AppBar personalizado (opcional)
      appBar: AppBar(
        title: const Text('Ejemplo 1: Usando extensión'),
        backgroundColor: Colors.purple,
      ),
    );

    // Ejemplo 2: Usando directamente el LocalizedScreenWrapper
    /*
    return LocalizedScreenWrapper(
      appBar: AppBar(
        title: const Text('Ejemplo 2: Usando wrapper'),
        backgroundColor: Colors.blue,
      ),
      child: _buildContentWidget(),
    );
    */

    // Ejemplo 3: Usando el método de AppService para agregar el botón a un AppBar existente
    /*
    final appBar = AppService.addLanguageSelectorToAppBar(
      context,
      title: 'Ejemplo 3: Usando AppService',
      backgroundColor: Colors.green,
    );

    return Scaffold(
      appBar: appBar,
      body: _buildContentWidget(),
    );
    */
  }

  // Widget de contenido común para los tres ejemplos
  Widget _buildContentWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Este es un ejemplo de cómo integrar el\nbotón selector de idioma',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          const Text(
            'Puedes elegir entre 3 formas diferentes:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildMethodDescription(
            '1. Usando la extensión .withLanguageSelector()',
            'Más simple y limpio',
          ),
          _buildMethodDescription(
            '2. Usando LocalizedScreenWrapper directamente',
            'Más control sobre los parámetros',
          ),
          _buildMethodDescription(
            '3. Usando AppService.addLanguageSelectorToAppBar()',
            'Personalización completa del AppBar',
          ),
        ],
      ),
    );
  }

  Widget _buildMethodDescription(String title, String description) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
