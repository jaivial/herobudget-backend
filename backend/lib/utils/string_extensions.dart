// Archivo de utilidades para extensiones de String
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
