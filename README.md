# LEGO---UCAB-SBD

Proyecto de sistema de base de datos. Para el registro de las ventas en tiendas físicas, incluyendo el manejo de inventario, ventas online de productos lego e inscripción al inside tour de lego.

##  Instalación y Configuración

### Requisitos Previos

- Node.js (versión 14 o superior)
- npm (viene incluido con Node.js)
- Oracle Database (versión estándar del proyecto - todos los miembros del equipo usan la misma versión)
- Oracle Instant Client (requerido para el driver oracledb)

### Pasos de Instalación

1. **Instalar Node.js** (si no lo tienes instalado):
   ```bash
   # Verificar instalación
   node --version
   npm --version
   ```

2. **Instalar dependencias del proyecto**:
   ```bash
   npm install
   ```
   
   **Nota:** El proyecto usa `oracledb` como driver para Oracle Database. Si encuentras problemas de instalación, asegúrate de tener Oracle Instant Client instalado en tu sistema.

3. **Configurar variables de entorno**:
   
   Crea un archivo `.env` en la raíz del proyecto copiando el archivo `env.example.txt` como plantilla:
   ```bash
   cp env.example.txt .env
   ```
   
   Luego edita el archivo `.env` con tus credenciales de Oracle:
   ```env
   # Configuración del Servidor NO TOCAR
   PORT=3000

   # Configuración de la Base de Datos Oracle
   # IMPORTANTE: DB_NAME debe ser el SERVICE NAME (no el SID)
   # En SQLDeveloper, si usas "Service name", ese es el valor que va en DB_NAME
   # Ejemplo: Si en SQLDeveloper tienes Service name = FREEPDB1, entonces DB_NAME=FREEPDB1
   DB_HOST=localhost
   DB_PORT=1521
   DB_NAME=FREEPDB1
   DB_USER=system
   DB_PASSWORD=tu_password_aqui
   ```
   
   **⚠️ Importante:**
   - `DB_NAME` debe ser el **Service name** de tu base de datos Oracle (no el SID)
   - Para encontrar tu Service name, revisa la configuración en SQLDeveloper
   - Todos los miembros del equipo usan la misma versión de Oracle, por lo que la configuración será similar
   
4. **Iniciar el servidor**:
   ```bash
   npm start
   ```
   
   **Nota:** Si obtienes el error `EADDRINUSE: address already in use :::3000`, significa que el puerto 3000 está en uso. Puedes:
   - Detener el proceso que está usando el puerto
   - O cambiar el `PORT` en tu archivo `.env` a otro puerto (ej: 3001)

5. **Acceder a la aplicación**:
   
   Abre tu navegador y visita: `http://localhost:3000`

## 📁 Estructura del Proyecto

```
LEGO---UCAB-SBD/
├── codsql/
   ├── create.sql
├── backend/
│   ├── server.js      # Servidor Express principal
│   └── db.js          # Configuración de conexión a BD
├── frontend/
│   ├── index.html     # Página principal
│   ├── styles.css     # Estilos CSS
│   └── script.js      # JavaScript del frontend
├── .env               # Variables de entorno (crear manualmente)
├── init/
   └── 01_create_users.sql   
├── .gitignore         # Archivos a ignorar en git
├── package.json       # Dependencias del proyecto
└── README.md          # Este archivo
```

## 🔧 Configuración de Base de Datos

El proyecto está configurado para trabajar con **Oracle Database**. Todos los miembros del equipo usan la misma versión de Oracle, por lo que la configuración será uniforme.

### Driver de Oracle

El proyecto usa `oracledb` como driver para conectarse a Oracle Database. Este driver ya está incluido en las dependencias del proyecto (`package.json`).

### Formato de Conexión

Oracle Database usa un formato de conexión específico:
- **Host**: `localhost` (o la IP de tu servidor Oracle)
- **Puerto**: `1521` (puerto estándar de Oracle)
- **Service Name**: El nombre del servicio de tu base de datos (ej: `FREEPDB1`)

**⚠️ Importante:** 
- En Oracle, cuando usas "Service name" (no SID), el valor de `DB_NAME` en el `.env` debe ser exactamente el Service name
- Para verificar tu Service name, revisa la configuración de conexión en SQLDeveloper

### Verificación de Conexión

El proyecto incluye un endpoint de prueba que verifica la conexión con la base de datos:
- Al acceder a `http://localhost:3000`, verás un mensaje indicando el estado de la conexión
- El endpoint `/api/db-test` realiza una verificación real de conexión ejecutando `SELECT 1 FROM DUAL`



## 📝 Endpoints Disponibles

- `GET /` - Página principal (index.html)
- `GET /api/test` - Prueba de conexión del servidor
- `GET /api/db-test` - Prueba de configuración de base de datos

## 🛠️ Desarrollo

Para desarrollo, puedes usar:
```bash
npm run dev
```

## 📚 Tecnologías Utilizadas

- **Backend**: Express.js
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Base de Datos**: Oracle Database (versión estándar del proyecto)
- **Driver de BD**: oracledb
- **Variables de Entorno**: dotenv 
