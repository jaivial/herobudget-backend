#!/usr/bin/env python3
"""
Servidor de webhook simple para GitHub
Reemplaza a Jenkins con una solución más ligera
"""

import os
import sys
import json
import subprocess
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import hmac
import hashlib
import time
import urllib.request

# Configuración
PORT = 9090
WEBHOOK_SECRET = os.environ.get('WEBHOOK_SECRET', '')
REPO_PATH = '/opt/hero_budget'
LOG_FILE = '/opt/hero_budget/logs/webhook.log'

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)

class WebhookHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Health check endpoint"""
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'Hero Budget Webhook Server - RUNNING\n')

    def do_POST(self):
        """Handle GitHub webhook"""
        try:
            # Parse GitHub webhook
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            # Verify signature if secret is set
            if WEBHOOK_SECRET:
                signature = self.headers.get('X-Hub-Signature-256')
                if not self.verify_signature(post_data, signature):
                    self.send_error(401, 'Invalid signature')
                    return

            # Parse JSON payload
            payload = json.loads(post_data.decode('utf-8'))
            
            # Check if it's a push to main branch
            if (payload.get('ref') == 'refs/heads/main' and 
                payload.get('repository', {}).get('name') == 'herobudget-backend'):
                
                logging.info("🚀 GitHub webhook recibido - Iniciando deployment...")
                
                # Execute deployment script
                result = self.execute_deployment()
                
                if result:
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    response = {'status': 'success', 'message': 'Deployment executed'}
                else:
                    self.send_response(500)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    response = {'status': 'error', 'message': 'Deployment failed'}
                
                self.wfile.write(json.dumps(response).encode('utf-8'))
            else:
                # Not a main branch push, ignore
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                response = {'status': 'ignored', 'message': 'Not a main branch push'}
                self.wfile.write(json.dumps(response).encode('utf-8'))
                
        except Exception as e:
            logging.error(f"Error procesando webhook: {e}")
            self.send_error(500, str(e))

    def verify_signature(self, payload_body, signature_header):
        """Verify GitHub webhook signature"""
        if not signature_header:
            return False
        
        expected_signature = hmac.new(
            WEBHOOK_SECRET.encode('utf-8'),
            payload_body,
            hashlib.sha256
        ).hexdigest()
        
        return hmac.compare_digest(
            f'sha256={expected_signature}',
            signature_header
        )

    def execute_deployment(self):
        """Execute the deployment script"""
        try:
            script_path = os.path.join(REPO_PATH, 'scripts', 'local_deploy.sh')
            
            logging.info(f"Ejecutando: {script_path}")
            
            # Agregar Go al PATH
            env = os.environ.copy()
            env['PATH'] = '/usr/local/go/bin:' + env.get('PATH', '')
            
            result = subprocess.run(
                [script_path],
                cwd=REPO_PATH,
                capture_output=True,
                text=True,
                timeout=300,  # 5 minutos máximo
                env=env
            )
            
            logging.info(f"Exit code: {result.returncode}")
            logging.info(f"STDOUT: {result.stdout}")
            
            if result.stderr:
                logging.warning(f"STDERR: {result.stderr}")
            
            # Si el deployment fue exitoso, ejecutar health check rápido
            if result.returncode == 0:
                self.post_deployment_health_check()
            
            return result.returncode == 0
            
        except subprocess.TimeoutExpired:
            logging.error("Deployment script timeout después de 5 minutos")
            return False
        except Exception as e:
            logging.error(f"Error ejecutando deployment: {e}")
            return False

    def post_deployment_health_check(self):
        """Ejecutar health check rápido post-deployment"""
        try:
            logging.info("🏥 Ejecutando health check post-deployment...")
            
            # URLs a verificar
            health_urls = [
                "https://herobudget.jaimedigitalstudio.com/health",
                "https://herobudget.jaimedigitalstudio.com/signup/check-email"
            ]
            
            successful_checks = 0
            total_checks = len(health_urls)
            
            for url in health_urls:
                try:
                    if "check-email" in url:
                        # POST request para check-email
                        data = '{"email":"test@example.com"}'.encode('utf-8')
                        req = urllib.request.Request(url, data=data, 
                                                   headers={'Content-Type': 'application/json'})
                    else:
                        # GET request para health
                        req = urllib.request.Request(url)
                    
                    response = urllib.request.urlopen(req, timeout=10)
                    if response.status == 200:
                        logging.info(f"✅ Health check OK: {url}")
                        successful_checks += 1
                    else:
                        logging.warning(f"⚠️ Health check HTTP {response.status}: {url}")
                        
                except Exception as e:
                    logging.warning(f"❌ Health check failed: {url} - {e}")
            
            health_percentage = (successful_checks * 100) // total_checks
            logging.info(f"📊 Post-deployment health: {health_percentage}% ({successful_checks}/{total_checks} OK)")
            
            if health_percentage >= 75:
                logging.info("🎉 Deployment saludable - Sistema operacional")
            elif health_percentage >= 50:
                logging.warning("⚠️ Deployment parcial - Algunos servicios necesitan atención")
            else:
                logging.error("❌ Deployment problemático - Verificar servicios manualmente")
                
        except Exception as e:
            logging.error(f"Error en health check post-deployment: {e}")

    def log_message(self, format, *args):
        """Override para usar nuestro logging"""
        logging.info(f"{self.address_string()} - {format % args}")

def main():
    # Crear directorio de logs si no existe
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    
    # Crear servidor HTTP
    server = HTTPServer(('0.0.0.0', PORT), WebhookHandler)
    
    logging.info(f"🚀 Hero Budget Webhook Server iniciado en puerto {PORT}")
    logging.info(f"📋 Repositorio: {REPO_PATH}")
    logging.info(f"📝 Logs: {LOG_FILE}")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logging.info("👋 Servidor detenido por usuario")
    except Exception as e:
        logging.error(f"Error en servidor: {e}")
    finally:
        server.server_close()

if __name__ == '__main__':
    main() 