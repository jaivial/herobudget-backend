# Solución de Problemas de Repositorios en VPS

## Problema Identificado

Durante la actualización del sistema aparecen estos errores:
- Error 418 "I'm a teapot" del repositorio PHP Sury
- Advertencia sobre clave MongoDB en keyring legacy

## Solución Paso a Paso

### 1. Limpiar repositorio PHP Sury problemático

```bash
# Eliminar el repositorio problemático
sudo rm -f /etc/apt/sources.list.d/sury-php.list
sudo rm -f /etc/apt/sources.list.d/php.list

# Limpiar cualquier configuración relacionada
sudo apt-key del 95BD4743
```

### 2. Arreglar la clave de MongoDB

```bash
# Descargar e instalar la clave correcta de MongoDB
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg

# Actualizar el repositorio de MongoDB para usar el nuevo keyring
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Eliminar la entrada antigua si existe
sudo rm -f /etc/apt/sources.list.d/mongodb-org.list
```

### 3. Limpiar cache y actualizar

```bash
# Limpiar cache de apt
sudo apt clean
sudo apt autoclean

# Actualizar lista de paquetes
sudo apt update

# Ahora actualizar el sistema
sudo apt upgrade -y
```

### 4. Si persisten problemas, usar método alternativo

Si aún hay problemas, puedes omitir los repositorios problemáticos:

```bash
# Actualizar solo los repositorios oficiales de Ubuntu
sudo apt update --allow-releaseinfo-change

# Actualizar paquetes disponibles
sudo apt upgrade -y --allow-downgrades
```

### 5. Verificar que todo esté funcionando

```bash
# Verificar que no hay errores
sudo apt update

# Debería mostrar solo repositorios válidos sin errores
```

## Comandos Completos para Ejecutar

Ejecuta estos comandos en orden:

```bash
# Paso 1: Limpiar repositorios problemáticos
sudo rm -f /etc/apt/sources.list.d/sury-php.list
sudo rm -f /etc/apt/sources.list.d/php.list

# Paso 2: Arreglar MongoDB
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo rm -f /etc/apt/sources.list.d/mongodb-org.list

# Paso 3: Limpiar y actualizar
sudo apt clean
sudo apt update
sudo apt upgrade -y
```

## Continuar con el Despliegue

Una vez solucionados estos problemas, puedes continuar con el **Paso 1.3** de la guía de despliegue:

```bash
# Instalar Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Instalar Nginx
apt install nginx -y

# Instalar Certbot para SSL
apt install certbot python3-certbot-nginx -y

# Instalar SQLite
apt install sqlite3 -y

# Instalar herramientas adicionales
apt install git curl unzip lsof -y
```

## Notas Importantes

- **MongoDB**: No es necesario para Hero Budget ya que usas SQLite, pero es mejor mantener el repositorio limpio
- **PHP Sury**: Tampoco es necesario para tu proyecto Go, por eso lo eliminamos
- **Verificación**: Siempre ejecuta `sudo apt update` después de hacer cambios para verificar que no hay errores

¡Una vez completados estos pasos, tu VPS estará listo para continuar con el despliegue de Hero Budget! 