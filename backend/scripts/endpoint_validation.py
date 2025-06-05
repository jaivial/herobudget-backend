#!/usr/bin/env python3
"""
Hero Budget - Endpoint Validation Script
Valida todos los endpoints de la aplicación en desarrollo y producción
"""

import requests
import json
import time
import sys
from datetime import datetime
from typing import Dict, List, Tuple, Optional

# Configuración de endpoints
LOCAL_BASE = "http://localhost"
PROD_BASE = "https://herobudget.jaimedigitalstudio.com"

# Configuración de servicios con puertos locales
SERVICES = {
    "google_auth": {"port": 8081, "path": "/auth/google", "method": "GET"},
    "signup": {"port": 8082, "path": "/signup/check-email", "method": "POST"},
    "language": {"port": 8083, "path": "/language/get", "method": "GET"},
    "signin": {"port": 8084, "path": "/signin/check-email", "method": "POST"},
    "dashboard": {"port": 8085, "path": "/health", "method": "GET"},
    "reset_password": {"port": 8086, "path": "/reset-password/check-email", "method": "POST"},
    "dashboard_data": {"port": 8087, "path": "/dashboard/data", "method": "GET"},
    "budget": {"port": 8088, "path": "/budget/fetch", "method": "GET"},
    "savings": {"port": 8089, "path": "/savings/health", "method": "GET"},
    "cash_bank": {"port": 8090, "path": "/cash-bank/distribution", "method": "GET"},
    "bills": {"port": 8091, "path": "/bills", "method": "GET"},
    "profile": {"port": 8092, "path": "/profile/ping", "method": "GET"},
    "income": {"port": 8093, "path": "/incomes", "method": "GET"},
    "expense": {"port": 8094, "path": "/expenses", "method": "GET"},
    "transaction_delete": {"port": 8095, "path": "/transactions/delete", "method": "POST"},
    "categories": {"port": 8096, "path": "/categories", "method": "GET"},
    "money_flow": {"port": 8097, "path": "/money-flow/data", "method": "GET"},
    "budget_overview": {"port": 8098, "path": "/budget-overview", "method": "GET"},
}

# Endpoints especiales de transferencias
TRANSFER_ENDPOINTS = {
    "cash_to_bank": {"port": 8090, "path": "/transfer/cash-to-bank", "method": "POST"},
    "bank_to_cash": {"port": 8090, "path": "/transfer/bank-to-cash", "method": "POST"},
}

class EndpointValidator:
    def __init__(self, environment: str = "local"):
        self.environment = environment
        self.base_url = LOCAL_BASE if environment == "local" else PROD_BASE
        self.results: List[Dict] = []
        self.session = requests.Session()
        self.session.timeout = 10
        
    def test_endpoint(self, name: str, config: Dict) -> Dict:
        """Testa un endpoint específico"""
        result = {
            "name": name,
            "status": "unknown",
            "response_code": None,
            "response_time": None,
            "error": None,
            "url": "",
            "timestamp": datetime.now().isoformat()
        }
        
        try:
            # Construir URL
            if self.environment == "local":
                url = f"{self.base_url}:{config['port']}{config['path']}"
            else:
                url = f"{self.base_url}{config['path']}"
            
            result["url"] = url
            
            # Preparar datos de prueba según el endpoint
            data = self._get_test_data(name, config)
            headers = {"Content-Type": "application/json"}
            
            # Realizar solicitud
            start_time = time.time()
            
            if config["method"] == "GET":
                response = self.session.get(url, headers=headers, params=data)
            elif config["method"] == "POST":
                response = self.session.post(url, headers=headers, json=data)
            else:
                response = self.session.request(config["method"], url, headers=headers, json=data)
            
            end_time = time.time()
            
            result["response_code"] = response.status_code
            result["response_time"] = round((end_time - start_time) * 1000, 2)
            
            # Evaluar resultado
            if response.status_code == 200:
                result["status"] = "success"
            elif response.status_code == 404:
                result["status"] = "not_found"
                result["error"] = "Endpoint not found"
            elif response.status_code == 500:
                result["status"] = "server_error"
                result["error"] = "Internal server error"
            elif response.status_code in [400, 422]:
                result["status"] = "client_error"
                result["error"] = "Bad request/Validation error"
            else:
                result["status"] = "error"
                result["error"] = f"HTTP {response.status_code}"
                
        except requests.exceptions.ConnectionError:
            result["status"] = "connection_error"
            result["error"] = "Service not running or unreachable"
        except requests.exceptions.Timeout:
            result["status"] = "timeout"
            result["error"] = "Request timeout"
        except Exception as e:
            result["status"] = "error"
            result["error"] = str(e)
            
        return result
    
    def _get_test_data(self, name: str, config: Dict) -> Optional[Dict]:
        """Obtiene datos de prueba apropiados para cada endpoint"""
        test_data = {
            "signup": {"email": "test@example.com"},
            "signin": {"email": "test@example.com"},
            "reset_password": {"email": "test@example.com"},
            "cash_to_bank": {
                "user_id": "test_user",
                "amount": 100.0,
                "date": datetime.now().isoformat()
            },
            "bank_to_cash": {
                "user_id": "test_user", 
                "amount": 50.0,
                "date": datetime.now().isoformat()
            },
            "transaction_delete": {
                "user_id": "test_user",
                "transaction_id": "test_transaction"
            }
        }
        
        # Para endpoints GET con user_id, usar parámetros
        if config["method"] == "GET" and name in ["dashboard_data", "cash_bank", "budget", "savings"]:
            return {"user_id": "test_user"}
            
        return test_data.get(name)
    
    def validate_all_services(self) -> Dict:
        """Valida todos los servicios"""
        print(f"🔍 Testing {self.environment.upper()} environment...")
        print(f"Base URL: {self.base_url}")
        print("=" * 60)
        
        # Testear servicios principales
        all_services = {**SERVICES, **TRANSFER_ENDPOINTS}
        
        for name, config in all_services.items():
            result = self.test_endpoint(name, config)
            self.results.append(result)
            
            # Mostrar resultado en tiempo real
            status_icon = self._get_status_icon(result["status"])
            print(f"{status_icon} {name:<20} {result['response_code'] or 'N/A':<4} "
                  f"{result['response_time'] or 0:<6}ms {result.get('error', '')}")
        
        return self._generate_summary()
    
    def _get_status_icon(self, status: str) -> str:
        """Obtiene icono según el status"""
        icons = {
            "success": "✅",
            "not_found": "❌", 
            "server_error": "🔥",
            "client_error": "⚠️",
            "connection_error": "🔌",
            "timeout": "⏰",
            "error": "❌",
            "unknown": "❓"
        }
        return icons.get(status, "❓")
    
    def _generate_summary(self) -> Dict:
        """Genera resumen de resultados"""
        total = len(self.results)
        success = len([r for r in self.results if r["status"] == "success"])
        errors = len([r for r in self.results if r["status"] in ["server_error", "error"]])
        not_found = len([r for r in self.results if r["status"] == "not_found"])
        connection_errors = len([r for r in self.results if r["status"] == "connection_error"])
        
        summary = {
            "environment": self.environment,
            "total_endpoints": total,
            "successful": success,
            "errors": errors,
            "not_found": not_found,
            "connection_errors": connection_errors,
            "success_rate": round((success / total) * 100, 1) if total > 0 else 0,
            "timestamp": datetime.now().isoformat(),
            "details": self.results
        }
        
        print("\n" + "=" * 60)
        print(f"📊 SUMMARY - {self.environment.upper()}")
        print("=" * 60)
        print(f"Total Endpoints: {total}")
        print(f"✅ Successful: {success}")
        print(f"❌ Errors: {errors}")
        print(f"🔌 Connection Errors: {connection_errors}")
        print(f"❓ Not Found: {not_found}")
        print(f"📈 Success Rate: {summary['success_rate']}%")
        
        return summary

def main():
    """Función principal"""
    if len(sys.argv) > 1:
        environment = sys.argv[1].lower()
        if environment not in ["local", "production"]:
            print("Usage: python endpoint_validation.py [local|production]")
            sys.exit(1)
    else:
        environment = "local"
    
    validator = EndpointValidator(environment)
    summary = validator.validate_all_services()
    
    # Guardar resultados
    filename = f"endpoint_validation_{environment}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(filename, 'w') as f:
        json.dump(summary, f, indent=2)
    
    print(f"\n💾 Results saved to: {filename}")
    
    # Mostrar problemas críticos
    critical_issues = [r for r in summary["details"] if r["status"] in ["server_error", "not_found"]]
    if critical_issues:
        print("\n🚨 CRITICAL ISSUES:")
        for issue in critical_issues:
            print(f"  - {issue['name']}: {issue['error']} ({issue['url']})")

if __name__ == "__main__":
    main() 