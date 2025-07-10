# SkyPagos - Pasarela de Pagos

Una aplicación completa de pasarela de pagos desarrollada con Flutter y Node.js, similar a Tigo Money.

## 🚀 Características

- **Interfaz moderna** inspirada en Tigo Money
- **Autenticación segura** con JWT
- **Envío de dinero** entre usuarios
- **Historial de transacciones** completo
- **Gestión de beneficiarios**
- **Notificaciones** en tiempo real
- **Base de datos SQL Server** robusta
- **API RESTful** con Node.js

## 📱 Capturas de Pantalla

- Splash Screen animado
- Login elegante con validaciones
- Dashboard principal con saldo
- Envío de dinero con confirmación
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

## 🔐 Datos de Prueba

### Usuarios de Prueba
- **Teléfono:** 70123456 | **PIN:** 1234
- **Teléfono:** 75987654 | **PIN:** 1234
- **Teléfono:** 68456789 | **PIN:** 1234

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
- `GET /api/user/balance` - Obtener saldo

### Transacciones
- `POST /api/transactions/send` - Enviar dinero
- `GET /api/transactions/history` - Historial

### Beneficiarios
- `GET /api/beneficiaries` - Listar beneficiarios
- `POST /api/beneficiaries` - Agregar beneficiario

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
2. **Login** - Autenticación con teléfono y PIN
3. **Registro** - Crear nueva cuenta
4. **Dashboard** - Saldo y acciones rápidas
5. **Envío de Dinero** - Transferencias entre usuarios
6. **Historial** - Lista de transacciones
7. **Perfil** - Información del usuario

### Características Técnicas
- Manejo de estados con setState
- Validación de formularios
- Animaciones fluidas
- Manejo de errores robusto
- Almacenamiento local de tokens
- Formateo de monedas y fechas

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
2. Comprobar la IP en `api_service.dart`
3. Asegurar que el dispositivo esté en la misma red

## 📈 Próximas Funcionalidades

- [ ] Autenticación biométrica
- [ ] Pagos con QR
- [ ] Notificaciones push
- [ ] Pago de servicios
- [ ] Dashboard administrativo
- [ ] Reportes y analytics

## 👥 Contribuir

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 📞 Soporte

Para soporte técnico o preguntas:
- Email: soporte@skypagos.com
- Teléfono: +591 70000000

---

**SkyPagos** - Tu billetera digital 💳✨
# APP-SKY
# APP-SKY
