# SkyPagos - Pasarela de Pagos

Una aplicación completa de pasarela de pagos desarrollada con Flutter y Node.js.

## 🚀 Características

- **Interfaz moderna** 
- **Autenticación segura** con JWT
- **Historial de transacciones** completo
- **Gestión de beneficiarios**
- **Notificaciones** en tiempo real
- **Base de datos SQL Server** robusta
- **API RESTful** con Node.js

## 📱 Capturas de Pantalla

- Splash Screen animado
- Login elegante con validaciones
- Dashboard principal con saldo
- Historial detallado de transacciones
- Perfil de usuario completo

## 🛠️ Tecnologías Utilizadas

### Backend
- **Node.js** con Express
- **SQL Server** como base de datos
- **JWT** para autenticación
- **bcrypt** para encriptación
- **CORS** y **Helmet** para seguridad

### Frontend
- **Flutter** (Dart)
- **HTTP** para comunicación con API
- **SharedPreferences** para almacenamiento local
- **Material Design 3**

## 📋 Requisitos Previos

- Node.js (v16 o superior)
- Flutter SDK (v3.1 o superior)
- SQL Server
- Visual Studio Code o Android Studio

## 🔧 Instalación

### 1. Configurar la Base de Datos

\`\`\`sql
-- Ejecutar en SQL Server Management Studio
-- 1. Ejecutar scripts/01-create-database.sql
-- 2. Ejecutar scripts/02-seed-data.sql
\`\`\`

### 2. Configurar el Backend

\`\`\`bash
cd api
npm install
npm start
\`\`\`

El servidor estará disponible en `http://localhost:3000`

### 3. Configurar la App Flutter

\`\`\`bash
cd flutter_app
flutter pub get
flutter run
\`\`\`





## 📊 Estructura del Proyecto

\`\`\`
SkyPagos/
├── api/                    # Backend Node.js
│   ├── server.js          # Servidor principal
│   ├── package.json       # Dependencias
│   └── .env              # Variables de entorno
├── scripts/               # Scripts SQL
│   ├── 01-create-database.sql
│   └── 02-seed-data.sql
└── flutter_app/          # App Flutter
    ├── lib/
    │   ├── main.dart
    │   ├── models/        # Modelos de datos
    │   ├── screens/       # Pantallas
    │   ├── services/      # Servicios API
    │   └── utils/         # Utilidades y tema
    └── pubspec.yaml
\`\`\`

## 🌐 API Endpoints

### Autenticación
- `POST /api/auth/login` - Iniciar sesión
- `POST /api/auth/register` - Registrar usuario

### Usuario
- `GET /api/user/profile` - Obtener perfil





### Utilidades
- `GET /api/test` - Probar conexión
- `GET /api/health` - Estado del servidor

## 🔒 Seguridad

- Autenticación JWT con expiración
- Encriptación de PINs con bcrypt
- Rate limiting para prevenir ataques
- Validación de datos en frontend y backend
- Headers de seguridad con Helmet

## 📱 Funcionalidades de la App

### Pantallas Principales
1. **Splash Screen** - Verificación de conexión
2. **Login** - Autenticación con cedula y PIN
3. **Registro** - Crear nueva cuenta
4. **Dashboard** - acciones rápidas
6. **Historial** - Lista de transacciones
7. **Perfil** - Información del usuario

### Características Técnicas
- Manejo de estados con setState
- Validación de formularios
- Animaciones fluidas
- Manejo de errores robusto
- Almacenamiento local de tokens

## 🚨 Solución de Problemas

### Error de conexión a la base de datos
1. Verificar que SQL Server esté ejecutándose
2. Comprobar las credenciales en `server.js`
3. Asegurar que la base de datos `SkyPagos` exista

### Error "npm no reconocido"
1. Instalar Node.js desde https://nodejs.org/
2. Reiniciar la terminal
3. Verificar con `node --version`

### Error de conexión en Flutter
1. Verificar que el servidor esté corriendo
2. Comprobar la IP en `api_service.dart` y todos los services en general
3. Asegurar que el dispositivo esté en la misma red

## 📈 Próximas Funcionalidades

- [ ] Autenticación biométrica
- [ ] Notificaciones push
- [ ] Pago de servicios



## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 📞 Soporte

Para soporte técnico o preguntas:
- Email: sistemas@oral-plus.com


---

**SkyPagos** - Tu billetera digital 💳✨
# APP-SKY
# APP-SKY
# APP-SKY
