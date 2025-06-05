import 'date_utils.dart';

void testISOWeekCalculation() {
  print('=== Probando cálculo de semana ISO ===');

  // Test cases conocidos
  final testCases = [
    {'date': '2025-01-01', 'expected': '2025-W01'},
    {'date': '2025-01-06', 'expected': '2025-W01'}, // Monday of week 1
    {'date': '2025-01-13', 'expected': '2025-W02'}, // Monday of week 2
    {'date': '2025-05-26', 'expected': '2025-W22'}, // El caso que está fallando
    {
      'date': '2024-12-30',
      'expected': '2025-W01',
    }, // Caso edge: pertenece al 2025
    {'date': '2024-01-01', 'expected': '2024-W01'},
  ];

  for (final testCase in testCases) {
    final date = DateTime.parse(testCase['date']!);
    final result = DateUtils.formatWeeklyDate(date);
    final expected = testCase['expected']!;

    print(
      'Fecha: ${testCase['date']} -> Resultado: $result, Esperado: $expected',
    );

    if (result == expected) {
      print('✅ CORRECTO');
    } else {
      print('❌ ERROR');
    }
    print('---');
  }

  // Test específico para el problema actual
  print('\n=== Test específico para el problema reportado ===');
  final problemDate =
      DateTime.now(); // Fecha actual que está causando problemas
  final weeklyFormat = DateUtils.formatWeeklyDate(problemDate);
  print('Fecha actual: $problemDate');
  print('Formato weekly: $weeklyFormat');

  // Verificar que podemos parsear de vuelta
  try {
    final parsedBack = DateUtils.parseWeeklyDate(weeklyFormat);
    print('Parseado de vuelta: $parsedBack');
    print('✅ Parse exitoso');
  } catch (e) {
    print('❌ Error al parsear: $e');
  }
}

void main() {
  testISOWeekCalculation();
}
