import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/environment.dart';
import '../services/savings_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiDebugWidget extends StatefulWidget {
  const ApiDebugWidget({super.key});

  @override
  State<ApiDebugWidget> createState() => _ApiDebugWidgetState();
}

class _ApiDebugWidgetState extends State<ApiDebugWidget> {
  String? _userId;
  bool _isLoading = false;
  Map<String, dynamic> _debugInfo = {};
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      // 1. Cargar información básica
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');

      _addLog('🔍 Loading debug information...');
      _addLog('👤 User ID from SharedPreferences: ${_userId ?? "NULL"}');

      // 2. Información del ambiente
      final environmentInfo = EnvironmentConfig.environmentInfo;
      _addLog('🌍 Environment: ${environmentInfo['environment']}');
      _addLog('🔗 Base URL: ${environmentInfo['baseUrl']}');
      _addLog('🏭 Is Production: ${environmentInfo['isProduction']}');

      // 3. URLs específicas
      final savingsUrl = ApiConfig.savingsManagementUrl;
      _addLog('💰 Savings URL: $savingsUrl');

      if (_userId != null) {
        final fullUrl = '$savingsUrl/fetch?user_id=$_userId';
        _addLog('📡 Full request URL: $fullUrl');
      }

      // 4. Test de conectividad
      await _testConnectivity();

      setState(() {
        _debugInfo = {
          'userId': _userId,
          'environment': environmentInfo,
          'savingsUrl': savingsUrl,
          'endpoints': ApiConfig.allEndpoints,
        };
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Error loading debug info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnectivity() async {
    _addLog('🧪 Testing connectivity...');

    try {
      // Test 1: Base URL
      final baseUrl = EnvironmentConfig.baseUrl;
      _addLog('📡 Testing base URL: $baseUrl');

      if (EnvironmentConfig.isDevelopment) {
        // Para desarrollo, probar puertos específicos
        await _testPort(8089, 'Savings Service');
        await _testPort(8081, 'Google Auth Service');
        await _testPort(8088, 'Budget Service');
      }

      // Test 2: Savings endpoint específico
      await _testSavingsEndpoint();
    } catch (e) {
      _addLog('❌ Connectivity test failed: $e');
    }
  }

  Future<void> _testPort(int port, String serviceName) async {
    try {
      final url = 'http://localhost:$port/health';
      _addLog('🔌 Testing $serviceName at port $port...');

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        _addLog('✅ $serviceName: OK (${response.statusCode})');
      } else {
        _addLog('⚠️ $serviceName: ${response.statusCode}');
      }
    } catch (e) {
      _addLog('❌ $serviceName: ERROR ($e)');
    }
  }

  Future<void> _testSavingsEndpoint() async {
    if (_userId == null) {
      _addLog('❌ Cannot test savings endpoint: no user_id');
      return;
    }

    try {
      _addLog('💰 Testing savings endpoint...');
      final savingsService = SavingsService();

      // Mostrar URL exacta que se va a usar
      final baseUrl = ApiConfig.savingsManagementUrl;
      final fullUrl = '$baseUrl/fetch?user_id=$_userId';
      _addLog('📡 Request URL: $fullUrl');

      final response = await http
          .get(
            Uri.parse(fullUrl),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      _addLog('📊 Response Status: ${response.statusCode}');
      _addLog('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _addLog('✅ Savings endpoint: SUCCESS');
        _addLog('📦 Response data: ${data.toString()}');
      } else {
        _addLog('❌ Savings endpoint: FAILED (${response.statusCode})');
      }
    } catch (e) {
      _addLog('❌ Savings endpoint test failed: $e');
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.add('[$timestamp] $message');
    });
    print(message); // También imprimir en consola
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _switchEnvironment() async {
    try {
      if (EnvironmentConfig.isDevelopment) {
        ApiConfig.useProduction();
        _addLog('🔄 Switched to PRODUCTION mode');
      } else {
        ApiConfig.useLocalhost();
        _addLog('🔄 Switched to LOCALHOST mode');
      }
      await _loadDebugInfo();
    } catch (e) {
      _addLog('❌ Error switching environment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _switchEnvironment,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildActionsCard(),
                    const SizedBox(height: 16),
                    _buildLogsCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Info',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildInfoRow('User ID', _userId ?? 'NULL'),
            _buildInfoRow(
              'Environment',
              EnvironmentConfig.currentEnvironment.toString(),
            ),
            _buildInfoRow('Base URL', EnvironmentConfig.baseUrl),
            _buildInfoRow(
              'Is Production',
              EnvironmentConfig.isProduction.toString(),
            ),
            _buildInfoRow('Savings URL', ApiConfig.savingsManagementUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testConnectivity,
                  child: const Text('Test Connectivity'),
                ),
                ElevatedButton(
                  onPressed: _testSavingsEndpoint,
                  child: const Text('Test Savings'),
                ),
                ElevatedButton(
                  onPressed: _switchEnvironment,
                  child: Text(
                    EnvironmentConfig.isDevelopment
                        ? 'Switch to Prod'
                        : 'Switch to Local',
                  ),
                ),
                ElevatedButton(
                  onPressed: _clearLogs,
                  child: const Text('Clear Logs'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Debug Logs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: SelectableText(
                      _logs[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
