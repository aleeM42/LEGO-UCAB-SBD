# LEGO Store - Sistema de Gestión UCAB-SBD

Sistema completo de gestión para tiendas LEGO que incluye:
- **Inscripciones a Tours**: Registro de participantes, gestión de pagos y generación de entradas
- **Ventas en Tienda Física**: Gestión de inventario por lotes, facturación y descuento automático de stock
- **Ventas Online**: Catálogo por país, facturación con puntos de lealtad y gestión de envíos

## 📋 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

1. **Python 3.8 o superior**
   - Verifica tu versión: `python --version` o `python3 --version`
   - Descarga desde: https://www.python.org/downloads/

2. **Oracle Database** (versión 12c o superior)
   - Oracle Database Express Edition (XE) es suficiente para desarrollo
   - Descarga desde: https://www.oracle.com/database/technologies/xe-downloads.html

3. **Oracle Instant Client** (requerido para `oracledb`)
   - Descarga desde: https://www.oracle.com/database/technologies/instant-client/downloads.html
   - **Windows**: Descarga el ZIP, extrae y agrega la ruta al PATH del sistema
   - **Linux**: Instala el paquete RPM o descarga el ZIP
   - **macOS**: Usa Homebrew: `brew install instantclient-basic`

4. **Git** (opcional, para clonar el repositorio)
   - Descarga desde: https://git-scm.com/downloads

## 🚀 Instalación Paso a Paso

### Paso 1: Clonar o Descargar el Proyecto

Si tienes acceso al repositorio Git:
```bash
git clone <url-del-repositorio>
cd LEGO---UCAB-SBD
```

O descarga el proyecto como ZIP y extrae el contenido.

### Paso 2: Crear un Entorno Virtual (Recomendado)

Es recomendable usar un entorno virtual para aislar las dependencias del proyecto:

**Windows:**
```bash
# Crear entorno virtual
python -m venv venv

# Activar entorno virtual
venv\Scripts\activate
```

**Linux/macOS:**
```bash
# Crear entorno virtual
python3 -m venv venv

# Activar entorno virtual
source venv/bin/activate
```

Una vez activado, verás `(venv)` al inicio de tu línea de comandos.

### Paso 3: Instalar Dependencias de Python

Con el entorno virtual activado, instala las dependencias:

```bash
pip install -r requirements.txt
```

O si usas `pip3`:
```bash
pip3 install -r requirements.txt
```

**Dependencias que se instalarán:**
- `flask==2.3.3` - Framework web para el backend
- `flask-cors==4.0.0` - Soporte CORS para peticiones cross-origin
- `python-dotenv==1.0.0` - Manejo de variables de entorno
- `requests==2.31.0` - Cliente HTTP para el frontend
- `oracledb` - Driver de Oracle (se instala automáticamente si Oracle Instant Client está configurado)

**Nota sobre oracledb:**
- Si tienes problemas instalando `oracledb`, asegúrate de que Oracle Instant Client esté correctamente instalado y en el PATH
- En Windows, reinicia la terminal después de agregar Oracle Instant Client al PATH
- Verifica la instalación: `python -c "import oracledb; print(oracledb.__version__)"`

### Paso 4: Configurar la Base de Datos Oracle

1. **Asegúrate de que Oracle Database esté ejecutándose:**
   ```bash
   # Verifica el estado del servicio (Windows)
   # En Services, busca "OracleServiceXE" o similar
   
   # Linux (systemd)
   sudo systemctl status oracle-xe
   ```

2. **Crea el esquema de base de datos:**
   - Abre SQL*Plus o SQL Developer
   - Conecta como usuario con privilegios DBA (SYSTEM o SYS)
   - Ejecuta los scripts en el siguiente orden:
     ```sql
     -- 1. Crear usuario y esquema (si no existe)
     @init/01_create_users.sql
     
     -- 2. Crear tablas y secuencias
     @codsql/lego_create.sql
     
     -- 3. Insertar datos iniciales (opcional)
     @codsql/inserts.sql
     
     -- 4. Crear funciones, procedimientos y triggers
     @codsql/funciones y triggers.sql
     
     -- 5. Crear vistas (opcional)
     @codsql/vistas_inscripciones_entradas.sql
     ```

### Paso 5: Configurar Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto con la siguiente estructura:

```env
# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN ORACLE DATABASE
# ═══════════════════════════════════════════════════════════════════════════════

# Host de Oracle (localhost si está en tu máquina)
ORACLE_HOST=localhost

# Puerto de Oracle (por defecto 1521)
ORACLE_PORT=1521

# Service Name de la base de datos (NO el SID)
# Ejemplo: FREEPDB1, XEPDB1, etc.
# Para encontrarlo: SELECT name FROM v$services;
ORACLE_PDB=FREEPDB1

# Usuario de la base de datos
DB_USER=maria_M

# Contraseña del usuario
DB_PASS=MariaMarin123

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN FLASK (Backend)
# ═══════════════════════════════════════════════════════════════════════════════

# Host donde se ejecutará el servidor Flask
FLASK_HOST=127.0.0.1

# Puerto donde se ejecutará el servidor Flask
FLASK_PORT=5000
```

**⚠️ Importante:**
- **ORACLE_PDB** debe ser el **Service Name**, no el SID
- Para encontrar tu Service Name, ejecuta en SQL*Plus:
  ```sql
  SELECT name FROM v$services;
  ```
- O revisa la configuración de conexión en SQL Developer (usa "Service name" no "SID")
- **No subas el archivo `.env` al repositorio** (debe estar en `.gitignore`)

### Paso 6: Verificar la Configuración

Antes de ejecutar el proyecto, verifica que todo esté correctamente configurado:

1. **Verifica la conexión a Oracle:**
   ```bash
   # Desde Python
   python -c "import oracledb; conn = oracledb.connect(user='TU_USUARIO', password='TU_PASSWORD', dsn='localhost:1521/FREEPDB1'); print('Conexión exitosa'); conn.close()"
   ```

2. **Verifica que las dependencias estén instaladas:**
   ```bash
   pip list
   # Deberías ver flask, flask-cors, python-dotenv, requests, oracledb
   ```

## ▶️ Ejecución del Proyecto

El proyecto consta de dos componentes que deben ejecutarse por separado:

### 1. Iniciar el Backend (Servidor Flask)

Abre una terminal y ejecuta:

**Windows:**
```bash
# Asegúrate de estar en el directorio del proyecto
cd LEGO---UCAB-SBD

# Activa el entorno virtual (si lo usas)
venv\Scripts\activate

# Ejecuta el backend
python backend\backend.py
```

**Linux/macOS:**
```bash
# Asegúrate de estar en el directorio del proyecto
cd LEGO---UCAB-SBD

# Activa el entorno virtual (si lo usas)
source venv/bin/activate

# Ejecuta el backend
python3 backend/backend.py
```

Deberías ver un mensaje similar a:
```
================================================================================
[INFO] Iniciando backend LEGO...
[INFO] Base de datos: localhost:1521/FREEPDB1
[INFO] Usuario: maria_M
[INFO] Flask: 127.0.0.1:5000
[INFO] Backend listo. Abre /health o /api/v1/tours
================================================================================
 * Running on http://127.0.0.1:5000
```

**Verifica que el backend esté funcionando:**
- Abre tu navegador en: `http://127.0.0.1:5000/health`
- Deberías ver: `{"status": "healthy", "database": "connected"}`

### 2. Iniciar el Frontend (Aplicación Tkinter)

Abre **otra terminal** (deja el backend ejecutándose) y ejecuta:

**Windows:**
```bash
# Asegúrate de estar en el directorio del proyecto
cd LEGO---UCAB-SBD

# Activa el entorno virtual (si lo usas)
venv\Scripts\activate

# Ejecuta el frontend
python frontend\frontend.py
```

**Linux/macOS:**
```bash
# Asegúrate de estar en el directorio del proyecto
cd LEGO---UCAB-SBD

# Activa el entorno virtual (si lo usas)
source venv/bin/activate

# Ejecuta el frontend
python3 frontend/frontend.py
```

Se abrirá una ventana de la aplicación con las siguientes pestañas:
- **Tours Disponibles**: Inscripciones a tours LEGO
- **Registrar**: Registro de clientes y fans LEGO
- **Participantes**: Agregar participantes a inscripciones
- **Resumen**: Resumen de inscripciones
- **Pago**: Procesamiento de pagos
- **Confirmación**: Confirmación y comprobantes
- **Tienda Física**: Ventas en tiendas físicas
- **Online**: Ventas online

## 📁 Estructura del Proyecto

```
LEGO---UCAB-SBD/
├── backend/
│   ├── backend.py          # Servidor Flask (API REST)
│   └── logs/               # Logs de la aplicación
│       └── app.log
├── frontend/
│   └── frontend.py         # Aplicación Tkinter (GUI)
├── codsql/
│   ├── lego_create.sql     # Script de creación de tablas y secuencias
│   ├── inserts.sql         # Datos iniciales (opcional)
│   ├── funciones y triggers.sql  # Funciones, procedimientos y triggers PL/SQL
│   └── vistas_inscripciones_entradas.sql  # Vistas de la base de datos
├── init/
│   └── 01_create_users.sql # Script de creación de usuarios
├── .env                    # Variables de entorno (crear manualmente)
├── .gitignore              # Archivos a ignorar en git
├── requirements.txt        # Dependencias de Python
└── README.md               # Este archivo
```

## 🔧 Solución de Problemas Comunes

### Error: "ModuleNotFoundError: No module named 'oracledb'"

**Solución:**
1. Verifica que Oracle Instant Client esté instalado y en el PATH
2. Reinicia la terminal después de agregar Oracle Instant Client al PATH
3. Reinstala: `pip install --upgrade oracledb`

### Error: "ORA-12541: TNS:no listener"

**Solución:**
1. Verifica que Oracle Database esté ejecutándose
2. Verifica que el puerto 1521 esté correcto en `.env`
3. Verifica que el Service Name sea correcto (no el SID)

### Error: "ORA-01017: invalid username/password"

**Solución:**
1. Verifica las credenciales en el archivo `.env`
2. Asegúrate de que el usuario exista en la base de datos
3. Verifica que el usuario tenga los permisos necesarios

### Error: "Address already in use" (puerto 5000)

**Solución:**
1. Cambia el puerto en `.env`: `FLASK_PORT=5001`
2. O detén el proceso que está usando el puerto:
   - **Windows**: `netstat -ano | findstr :5000` y luego `taskkill /PID <PID> /F`
   - **Linux/macOS**: `lsof -ti:5000 | xargs kill`

### El frontend no se conecta al backend

**Solución:**
1. Verifica que el backend esté ejecutándose
2. Verifica que la URL en `frontend/frontend.py` sea correcta (línea 22):
   ```python
   API_BASE_URL = "http://127.0.0.1:5000"
   ```
3. Verifica que el puerto coincida con `FLASK_PORT` en `.env`

### Error al cargar catálogo o consultar clientes

**Solución:**
1. Verifica que la base de datos tenga datos iniciales (ejecuta `inserts.sql`)
2. Verifica que todas las funciones y procedimientos estén compilados correctamente
3. Revisa los logs del backend para ver el error específico

## 📚 Tecnologías Utilizadas

- **Backend**: Flask (Python)
- **Frontend**: Tkinter (Python)
- **Base de Datos**: Oracle Database
- **Driver de BD**: oracledb (Oracle)
- **Variables de Entorno**: python-dotenv
- **HTTP Client**: requests

## 🔐 Seguridad

- **Nunca subas el archivo `.env` al repositorio**
- Mantén las credenciales de base de datos seguras
- Usa diferentes credenciales para desarrollo y producción
- El archivo `.env` debe estar en `.gitignore`

## 📝 Notas Adicionales

- El proyecto usa **Service Name** de Oracle, no SID
- Todos los procedimientos almacenados están en PL/SQL
- Los logs se guardan en `backend/logs/app.log`
- El frontend se comunica con el backend mediante peticiones HTTP REST

## 🤝 Contribución

Para contribuir al proyecto:
1. Crea una rama para tu feature: `git checkout -b feature/nueva-funcionalidad`
2. Realiza tus cambios
3. Asegúrate de que todo funcione correctamente
4. Crea un Pull Request

## 📄 Licencia

Este proyecto es parte del curso de Sistemas de Base de Datos de la UCAB.

---

**¿Problemas?** Revisa la sección de [Solución de Problemas Comunes](#-solución-de-problemas-comunes) o contacta al equipo de desarrollo.
