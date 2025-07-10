<?php
// scripts/create_database_premium.php

// Configuración para SQL Server
define('DB_HOST', '192.168.2.244');
define('DB_NAME', 'SkyPagos1');
define('DB_USER', 'sa');
define('DB_PASS', 'Sky2022*!');
define('DB_PORT', 1433);

try {
    // Conexión inicial sin especificar base de datos
    $connectionInfo = array(
        "UID" => DB_USER,
        "PWD" => DB_PASS,
        "CharacterSet" => "UTF-8",
        "TrustServerCertificate" => true,
        "Encrypt" => false
    );
    
    $conn = sqlsrv_connect(DB_HOST . ',' . DB_PORT, $connectionInfo);
    
    if ($conn === false) {
        die(print_r(sqlsrv_errors(), true));
    }
    
    echo "Conexión establecida exitosamente.\n";
    
    // Crear base de datos si no existe
    $createDbSql = "
    IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '" . DB_NAME . "')
    BEGIN
        CREATE DATABASE [" . DB_NAME . "]
    END";
    
    $stmt = sqlsrv_query($conn, $createDbSql);
    if ($stmt === false) {
        die(print_r(sqlsrv_errors(), true));
    }
    
    echo "Base de datos creada o ya existe.\n";
    
    // Cerrar conexión inicial
    sqlsrv_close($conn);
    
    // Conectar a la base de datos específica
    $connectionInfo['Database'] = DB_NAME;
    $conn = sqlsrv_connect(DB_HOST . ',' . DB_PORT, $connectionInfo);
    
    if ($conn === false) {
        die(print_r(sqlsrv_errors(), true));
    }
    
    // Crear tablas avanzadas
    $tables = [
        // Tabla de usuarios mejorada
        "CREATE TABLE usuarios (
            id INT IDENTITY(1,1) PRIMARY KEY,
            nombre NVARCHAR(100) NOT NULL,
            apellido NVARCHAR(100) NOT NULL,
            email NVARCHAR(150) UNIQUE NOT NULL,
            telefono NVARCHAR(20),
            password_hash NVARCHAR(255) NOT NULL,
            fecha_registro DATETIME DEFAULT GETDATE(),
            activo BIT DEFAULT 1,
            avatar NVARCHAR(255),
            pin NVARCHAR(6),
            biometric_enabled BIT DEFAULT 0,
            two_factor_enabled BIT DEFAULT 0,
            two_factor_secret NVARCHAR(32),
            fecha_nacimiento DATE,
            genero NVARCHAR(10),
            direccion NVARCHAR(255),
            ciudad NVARCHAR(100),
            pais NVARCHAR(100) DEFAULT 'Bolivia',
            documento_identidad NVARCHAR(20),
            tipo_documento NVARCHAR(20) DEFAULT 'CI',
            nivel_verificacion INT DEFAULT 1,
            puntos_recompensa INT DEFAULT 0,
            referido_por INT,
            codigo_referido NVARCHAR(10) UNIQUE,
            tema_preferido NVARCHAR(20) DEFAULT 'light',
            idioma_preferido NVARCHAR(10) DEFAULT 'es',
            notificaciones_push BIT DEFAULT 1,
            notificaciones_email BIT DEFAULT 1,
            ultima_actividad DATETIME DEFAULT GETDATE(),
            ip_registro NVARCHAR(45),
            dispositivo_registro NVARCHAR(255)
        )",
        
        // Tabla de cuentas mejorada
        "CREATE TABLE cuentas (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            numero_cuenta NVARCHAR(20) UNIQUE NOT NULL,
            saldo DECIMAL(15,2) DEFAULT 0.00,
            saldo_bloqueado DECIMAL(15,2) DEFAULT 0.00,
            tipo_cuenta NVARCHAR(20) DEFAULT 'PRINCIPAL',
            moneda NVARCHAR(3) DEFAULT 'BOB',
            fecha_creacion DATETIME DEFAULT GETDATE(),
            activa BIT DEFAULT 1,
            limite_diario DECIMAL(15,2) DEFAULT 5000.00,
            limite_mensual DECIMAL(15,2) DEFAULT 50000.00,
            gasto_diario DECIMAL(15,2) DEFAULT 0.00,
            gasto_mensual DECIMAL(15,2) DEFAULT 0.00,
            fecha_ultimo_reset_diario DATE DEFAULT CAST(GETDATE() AS DATE),
            fecha_ultimo_reset_mensual DATE DEFAULT CAST(GETDATE() AS DATE)
        )",
        
        // Tabla de servicios mejorada
        "CREATE TABLE servicios (
            id INT IDENTITY(1,1) PRIMARY KEY,
            nombre NVARCHAR(100) NOT NULL,
            descripcion NVARCHAR(255),
            categoria NVARCHAR(50),
            subcategoria NVARCHAR(50),
            icono NVARCHAR(100),
            color NVARCHAR(7),
            activo BIT DEFAULT 1,
            comision DECIMAL(5,2) DEFAULT 0.00,
            comision_fija DECIMAL(10,2) DEFAULT 0.00,
            monto_minimo DECIMAL(10,2) DEFAULT 1.00,
            monto_maximo DECIMAL(10,2) DEFAULT 10000.00,
            disponible_24h BIT DEFAULT 1,
            tiempo_procesamiento INT DEFAULT 0,
            cashback_porcentaje DECIMAL(5,2) DEFAULT 0.00,
            requiere_validacion BIT DEFAULT 0,
            proveedor NVARCHAR(100),
            url_api NVARCHAR(255),
            parametros_api NVARCHAR(MAX),
            orden_visualizacion INT DEFAULT 0,
            popular BIT DEFAULT 0,
            nuevo BIT DEFAULT 0,
            promocion BIT DEFAULT 0,
            fecha_creacion DATETIME DEFAULT GETDATE()
        )",
        
        // Tabla de transacciones mejorada
        "CREATE TABLE transacciones (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            cuenta_id INT FOREIGN KEY REFERENCES cuentas(id),
            servicio_id INT FOREIGN KEY REFERENCES servicios(id),
            tipo_transaccion NVARCHAR(20) NOT NULL,
            monto DECIMAL(15,2) NOT NULL,
            comision DECIMAL(15,2) DEFAULT 0.00,
            cashback DECIMAL(15,2) DEFAULT 0.00,
            referencia NVARCHAR(50) UNIQUE,
            referencia_externa NVARCHAR(100),
            descripcion NVARCHAR(255),
            estado NVARCHAR(20) DEFAULT 'PENDIENTE',
            fecha_transaccion DATETIME DEFAULT GETDATE(),
            fecha_procesamiento DATETIME,
            numero_destino NVARCHAR(50),
            nombre_destinatario NVARCHAR(200),
            comprobante NVARCHAR(100),
            ip_origen NVARCHAR(45),
            dispositivo_origen NVARCHAR(255),
            ubicacion_lat DECIMAL(10,8),
            ubicacion_lng DECIMAL(11,8),
            metodo_autenticacion NVARCHAR(20),
            intentos_fallidos INT DEFAULT 0,
            codigo_error NVARCHAR(10),
            mensaje_error NVARCHAR(255),
            tiempo_respuesta INT,
            moneda NVARCHAR(3) DEFAULT 'BOB',
            tasa_cambio DECIMAL(10,4) DEFAULT 1.0000,
            categoria_gasto NVARCHAR(50),
            etiquetas NVARCHAR(255),
            es_recurrente BIT DEFAULT 0,
            transaccion_padre_id INT,
            puntos_ganados INT DEFAULT 0
        )",
        
        // Tabla de tarjetas virtuales
        "CREATE TABLE tarjetas_virtuales (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            numero_tarjeta NVARCHAR(19) UNIQUE NOT NULL,
            nombre_titular NVARCHAR(100) NOT NULL,
            fecha_expiracion NVARCHAR(5) NOT NULL,
            cvv NVARCHAR(4) NOT NULL,
            tipo NVARCHAR(20) DEFAULT 'VIRTUAL',
            marca NVARCHAR(20) DEFAULT 'VISA',
            limite DECIMAL(15,2) DEFAULT 1000.00,
            saldo_disponible DECIMAL(15,2) DEFAULT 0.00,
            activa BIT DEFAULT 1,
            bloqueada BIT DEFAULT 0,
            fecha_creacion DATETIME DEFAULT GETDATE(),
            fecha_vencimiento DATETIME,
            pin NVARCHAR(4),
            contactless BIT DEFAULT 1,
            internacional BIT DEFAULT 0,
            online BIT DEFAULT 1,
            color NVARCHAR(7) DEFAULT '#0066CC',
            diseno NVARCHAR(50) DEFAULT 'classic'
        )",
        
        // Tabla de inversiones/ahorros
        "CREATE TABLE inversiones (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            nombre NVARCHAR(100) NOT NULL,
            tipo NVARCHAR(50) NOT NULL,
            monto_inicial DECIMAL(15,2) NOT NULL,
            monto_actual DECIMAL(15,2) NOT NULL,
            tasa_interes DECIMAL(5,2) NOT NULL,
            plazo_dias INT NOT NULL,
            fecha_inicio DATETIME DEFAULT GETDATE(),
            fecha_vencimiento DATETIME NOT NULL,
            estado NVARCHAR(20) DEFAULT 'ACTIVA',
            renovacion_automatica BIT DEFAULT 0,
            interes_ganado DECIMAL(15,2) DEFAULT 0.00,
            fecha_ultimo_calculo DATETIME DEFAULT GETDATE(),
            riesgo NVARCHAR(20) DEFAULT 'BAJO',
            categoria NVARCHAR(50),
            objetivo NVARCHAR(255),
            meta_ahorro DECIMAL(15,2),
            aporte_mensual DECIMAL(15,2) DEFAULT 0.00,
            dia_aporte INT DEFAULT 1,
            notificar_vencimiento BIT DEFAULT 1
        )",
        
        // Tabla de préstamos
        "CREATE TABLE prestamos (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            monto_solicitado DECIMAL(15,2) NOT NULL,
            monto_aprobado DECIMAL(15,2),
            tasa_interes DECIMAL(5,2) NOT NULL,
            plazo_meses INT NOT NULL,
            cuota_mensual DECIMAL(15,2),
            estado NVARCHAR(20) DEFAULT 'SOLICITADO',
            fecha_solicitud DATETIME DEFAULT GETDATE(),
            fecha_aprobacion DATETIME,
            fecha_desembolso DATETIME,
            fecha_vencimiento DATETIME,
            proposito NVARCHAR(255),
            ingresos_declarados DECIMAL(15,2),
            score_crediticio INT,
            garantia NVARCHAR(255),
            documentos_adjuntos NVARCHAR(MAX),
            observaciones NVARCHAR(MAX),
            aprobado_por INT,
            cuotas_pagadas INT DEFAULT 0,
            saldo_pendiente DECIMAL(15,2),
            dias_mora INT DEFAULT 0,
            interes_mora DECIMAL(15,2) DEFAULT 0.00
        )",
        
        // Tabla de notificaciones
        "CREATE TABLE notificaciones (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            titulo NVARCHAR(200) NOT NULL,
            mensaje NVARCHAR(MAX) NOT NULL,
            tipo NVARCHAR(50) NOT NULL,
            categoria NVARCHAR(50),
            leida BIT DEFAULT 0,
            fecha_creacion DATETIME DEFAULT GETDATE(),
            fecha_lectura DATETIME,
            accion_url NVARCHAR(255),
            icono NVARCHAR(100),
            color NVARCHAR(7),
            prioridad INT DEFAULT 1,
            expira DATETIME,
            datos_adicionales NVARCHAR(MAX),
            push_enviado BIT DEFAULT 0,
            email_enviado BIT DEFAULT 0,
            dispositivo_token NVARCHAR(255)
        )",
        
        // Tabla de recompensas y cashback
        "CREATE TABLE recompensas (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            transaccion_id INT FOREIGN KEY REFERENCES transacciones(id),
            tipo NVARCHAR(50) NOT NULL,
            puntos INT DEFAULT 0,
            cashback DECIMAL(10,2) DEFAULT 0.00,
            descripcion NVARCHAR(255),
            fecha_otorgado DATETIME DEFAULT GETDATE(),
            fecha_vencimiento DATETIME,
            canjeado BIT DEFAULT 0,
            fecha_canje DATETIME,
            categoria NVARCHAR(50),
            multiplicador DECIMAL(3,1) DEFAULT 1.0,
            promocion_id INT,
            referencia NVARCHAR(50)
        )",
        
        // Tabla de códigos QR
        "CREATE TABLE codigos_qr (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            codigo NVARCHAR(100) UNIQUE NOT NULL,
            tipo NVARCHAR(20) NOT NULL,
            monto DECIMAL(15,2),
            descripcion NVARCHAR(255),
            activo BIT DEFAULT 1,
            usos_maximos INT DEFAULT 1,
            usos_actuales INT DEFAULT 0,
            fecha_creacion DATETIME DEFAULT GETDATE(),
            fecha_expiracion DATETIME,
            datos_adicionales NVARCHAR(MAX),
            ubicacion_lat DECIMAL(10,8),
            ubicacion_lng DECIMAL(11,8),
            comercio NVARCHAR(200)
        )",
        
        // Tabla de contactos frecuentes
        "CREATE TABLE contactos (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            nombre NVARCHAR(100) NOT NULL,
            telefono NVARCHAR(20),
            email NVARCHAR(150),
            numero_cuenta NVARCHAR(20),
            banco NVARCHAR(100),
            tipo_contacto NVARCHAR(20) DEFAULT 'PERSONAL',
            favorito BIT DEFAULT 0,
            fecha_agregado DATETIME DEFAULT GETDATE(),
            ultima_transaccion DATETIME,
            total_transacciones INT DEFAULT 0,
            avatar NVARCHAR(255),
            notas NVARCHAR(255)
        )",
        
        // Tabla de dispositivos
        "CREATE TABLE dispositivos (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            device_id NVARCHAR(255) UNIQUE NOT NULL,
            nombre NVARCHAR(100),
            tipo NVARCHAR(50),
            sistema_operativo NVARCHAR(50),
            version_app NVARCHAR(20),
            token_push NVARCHAR(255),
            activo BIT DEFAULT 1,
            confiable BIT DEFAULT 0,
            fecha_registro DATETIME DEFAULT GETDATE(),
            ultima_actividad DATETIME DEFAULT GETDATE(),
            ip_address NVARCHAR(45),
            ubicacion NVARCHAR(255),
            biometric_available BIT DEFAULT 0,
            nfc_available BIT DEFAULT 0
        )",
        
        // Tabla de promociones
        "CREATE TABLE promociones (
            id INT IDENTITY(1,1) PRIMARY KEY,
            titulo NVARCHAR(200) NOT NULL,
            descripcion NVARCHAR(MAX),
            tipo NVARCHAR(50) NOT NULL,
            descuento_porcentaje DECIMAL(5,2) DEFAULT 0.00,
            descuento_fijo DECIMAL(10,2) DEFAULT 0.00,
            cashback_extra DECIMAL(5,2) DEFAULT 0.00,
            puntos_extra INT DEFAULT 0,
            fecha_inicio DATETIME NOT NULL,
            fecha_fin DATETIME NOT NULL,
            activa BIT DEFAULT 1,
            codigo_promocional NVARCHAR(20),
            usos_maximos INT,
            usos_actuales INT DEFAULT 0,
            servicios_aplicables NVARCHAR(MAX),
            usuarios_elegibles NVARCHAR(MAX),
            monto_minimo DECIMAL(10,2) DEFAULT 0.00,
            imagen NVARCHAR(255),
            terminos_condiciones NVARCHAR(MAX),
            prioridad INT DEFAULT 1
        )",
        
        // Tabla de logs de seguridad
        "CREATE TABLE logs_seguridad (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT,
            evento NVARCHAR(100) NOT NULL,
            descripcion NVARCHAR(MAX),
            ip_address NVARCHAR(45),
            user_agent NVARCHAR(MAX),
            fecha_evento DATETIME DEFAULT GETDATE(),
            nivel_riesgo NVARCHAR(20) DEFAULT 'BAJO',
            accion_tomada NVARCHAR(255),
            datos_adicionales NVARCHAR(MAX),
            dispositivo_id NVARCHAR(255),
            ubicacion_lat DECIMAL(10,8),
            ubicacion_lng DECIMAL(11,8),
            bloqueado BIT DEFAULT 0
        )",
        
        // Tabla de configuración avanzada
        "CREATE TABLE configuracion_avanzada (
            id INT IDENTITY(1,1) PRIMARY KEY,
            clave NVARCHAR(50) UNIQUE NOT NULL,
            valor NVARCHAR(MAX),
            tipo_dato NVARCHAR(20) DEFAULT 'STRING',
            categoria NVARCHAR(50),
            descripcion NVARCHAR(255),
            editable BIT DEFAULT 1,
            fecha_creacion DATETIME DEFAULT GETDATE(),
            fecha_actualizacion DATETIME DEFAULT GETDATE(),
            actualizado_por NVARCHAR(100)
        )",
        
        // Tabla de análisis de gastos
        "CREATE TABLE analisis_gastos (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            mes INT NOT NULL,
            anio INT NOT NULL,
            categoria NVARCHAR(50) NOT NULL,
            total_gastado DECIMAL(15,2) NOT NULL,
            total_transacciones INT NOT NULL,
            promedio_transaccion DECIMAL(15,2),
            comparacion_mes_anterior DECIMAL(5,2),
            presupuesto_asignado DECIMAL(15,2),
            porcentaje_presupuesto DECIMAL(5,2),
            fecha_calculo DATETIME DEFAULT GETDATE(),
            tendencia NVARCHAR(20),
            recomendacion NVARCHAR(MAX)
        )"
    ];
    
    foreach ($tables as $tableSql) {
        $stmt = sqlsrv_query($conn, $tableSql);
        if ($stmt === false) {
            echo "Error creando tabla: " . print_r(sqlsrv_errors(), true) . "\n";
        } else {
            echo "Tabla creada exitosamente.\n";
        }
    }
    
    // Insertar datos iniciales avanzados
    $insertData = [
        // Servicios completos
        "INSERT INTO servicios (nombre, descripcion, categoria, subcategoria, icono, color, comision, monto_minimo, monto_maximo, cashback_porcentaje, popular, proveedor) VALUES 
        ('Recargas Tigo', 'Recarga tu línea Tigo', 'Telefonía', 'Recargas', 'phone', '#0066CC', 2.5, 10.00, 500.00, 1.0, 1, 'Tigo'),
        ('Recargas Claro', 'Recarga tu línea Claro', 'Telefonía', 'Recargas', 'phone', '#FF0000', 2.5, 10.00, 500.00, 1.0, 1, 'Claro'),
        ('Recargas Viva', 'Recarga tu línea Viva', 'Telefonía', 'Recargas', 'phone', '#FF6600', 2.5, 10.00, 500.00, 1.0, 1, 'Viva'),
        ('Pago de Luz', 'Pago de servicios eléctricos', 'Servicios', 'Básicos', 'zap', '#FFD700', 1.5, 50.00, 2000.00, 0.5, 1, 'ENDE'),
        ('Pago de Agua', 'Pago de servicios de agua', 'Servicios', 'Básicos', 'droplets', '#00BFFF', 1.5, 30.00, 1500.00, 0.5, 1, 'SAGUAPAC'),
        ('Pago de Gas', 'Pago de servicios de gas', 'Servicios', 'Básicos', 'flame', '#FF4500', 1.5, 20.00, 800.00, 0.5, 1, 'YPFB'),
        ('Transferencias', 'Transferir dinero', 'Transferencias', 'P2P', 'send', '#32CD32', 0.5, 1.00, 10000.00, 0.0, 1, 'SkyPagos'),
        ('Netflix', 'Pago de suscripción Netflix', 'Entretenimiento', 'Streaming', 'tv', '#E50914', 3.0, 50.00, 200.00, 2.0, 1, 'Netflix'),
        ('Spotify', 'Pago de suscripción Spotify', 'Entretenimiento', 'Música', 'music', '#1DB954', 3.0, 30.00, 100.00, 2.0, 0, 'Spotify'),
        ('Amazon Prime', 'Pago de suscripción Amazon', 'Entretenimiento', 'Streaming', 'shopping-cart', '#FF9900', 3.0, 40.00, 150.00, 2.0, 0, 'Amazon'),
        ('Uber', 'Pago de viajes Uber', 'Transporte', 'Rideshare', 'car', '#000000', 2.0, 10.00, 500.00, 1.5, 1, 'Uber'),
        ('Rappi', 'Pago de delivery Rappi', 'Delivery', 'Comida', 'truck', '#FF441F', 2.5, 20.00, 300.00, 1.0, 1, 'Rappi'),
        ('Universidad', 'Pago de pensiones universitarias', 'Educación', 'Universidades', 'graduation-cap', '#4A90E2', 1.0, 500.00, 5000.00, 0.0, 0, 'Universidades'),
        ('Seguros', 'Pago de primas de seguros', 'Seguros', 'Vida', 'shield', '#8B4513', 1.5, 100.00, 2000.00, 0.5, 0, 'Seguros'),
        ('Impuestos', 'Pago de impuestos SIN', 'Gobierno', 'Impuestos', 'file-text', '#800080', 0.5, 50.00, 10000.00, 0.0, 0, 'SIN')",
        
        // Configuración avanzada
        "INSERT INTO configuracion_avanzada (clave, valor, tipo_dato, categoria, descripcion) VALUES 
        ('app_name', 'SkyPagos Premium', 'STRING', 'General', 'Nombre de la aplicación'),
        ('version', '2.0.0', 'STRING', 'General', 'Versión de la aplicación'),
        ('comision_defecto', '2.50', 'DECIMAL', 'Transacciones', 'Comisión por defecto en porcentaje'),
        ('monto_minimo', '1.00', 'DECIMAL', 'Transacciones', 'Monto mínimo para transacciones'),
        ('monto_maximo', '10000.00', 'DECIMAL', 'Transacciones', 'Monto máximo para transacciones'),
        ('limite_diario_defecto', '5000.00', 'DECIMAL', 'Límites', 'Límite diario por defecto'),
        ('limite_mensual_defecto', '50000.00', 'DECIMAL', 'Límites', 'Límite mensual por defecto'),
        ('puntos_por_boliviano', '1', 'INTEGER', 'Recompensas', 'Puntos ganados por cada boliviano gastado'),
        ('cashback_defecto', '0.5', 'DECIMAL', 'Recompensas', 'Cashback por defecto en porcentaje'),
        ('tasa_interes_ahorro', '8.5', 'DECIMAL', 'Inversiones', 'Tasa de interés anual para ahorros'),
        ('tasa_interes_prestamo', '18.0', 'DECIMAL', 'Préstamos', 'Tasa de interés anual para préstamos'),
        ('dias_expiracion_qr', '30', 'INTEGER', 'QR', 'Días de expiración para códigos QR'),
        ('intentos_maximos_login', '5', 'INTEGER', 'Seguridad', 'Intentos máximos de login antes de bloqueo'),
        ('tiempo_bloqueo_minutos', '30', 'INTEGER', 'Seguridad', 'Tiempo de bloqueo en minutos'),
        ('notificaciones_activas', '1', 'BOOLEAN', 'Notificaciones', 'Notificaciones push activas'),
        ('mantenimiento_activo', '0', 'BOOLEAN', 'Sistema', 'Modo mantenimiento activo'),
        ('soporte_chat_activo', '1', 'BOOLEAN', 'Soporte', 'Chat de soporte activo'),
        ('criptomonedas_activas', '1', 'BOOLEAN', 'Crypto', 'Soporte para criptomonedas activo'),
        ('nfc_pagos_activo', '1', 'BOOLEAN', 'NFC', 'Pagos por NFC activos'),
        ('biometric_required', '0', 'BOOLEAN', 'Seguridad', 'Autenticación biométrica requerida')"
    ];
    
    foreach ($insertData as $insertSql) {
        $stmt = sqlsrv_query($conn, $insertSql);
        if ($stmt === false) {
            echo "Error insertando datos: " . print_r(sqlsrv_errors(), true) . "\n";
        } else {
            echo "Datos insertados exitosamente.\n";
        }
    }
    
    echo "¡Base de datos premium creada exitosamente con todas las funcionalidades avanzadas!\n";
    
    sqlsrv_close($conn);
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
