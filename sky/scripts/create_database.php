<?php
// scripts/create_database.php

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
    
    // Crear tablas
    $tables = [
        // Tabla de usuarios
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
            pin NVARCHAR(6)
        )",
        
        // Tabla de cuentas
        "CREATE TABLE cuentas (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            numero_cuenta NVARCHAR(20) UNIQUE NOT NULL,
            saldo DECIMAL(15,2) DEFAULT 0.00,
            tipo_cuenta NVARCHAR(20) DEFAULT 'PRINCIPAL',
            fecha_creacion DATETIME DEFAULT GETDATE(),
            activa BIT DEFAULT 1
        )",
        
        // Tabla de servicios
        "CREATE TABLE servicios (
            id INT IDENTITY(1,1) PRIMARY KEY,
            nombre NVARCHAR(100) NOT NULL,
            descripcion NVARCHAR(255),
            categoria NVARCHAR(50),
            icono NVARCHAR(100),
            color NVARCHAR(7),
            activo BIT DEFAULT 1,
            comision DECIMAL(5,2) DEFAULT 0.00
        )",
        
        // Tabla de transacciones
        "CREATE TABLE transacciones (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            cuenta_id INT FOREIGN KEY REFERENCES cuentas(id),
            servicio_id INT FOREIGN KEY REFERENCES servicios(id),
            tipo_transaccion NVARCHAR(20) NOT NULL,
            monto DECIMAL(15,2) NOT NULL,
            comision DECIMAL(15,2) DEFAULT 0.00,
            referencia NVARCHAR(50),
            descripcion NVARCHAR(255),
            estado NVARCHAR(20) DEFAULT 'PENDIENTE',
            fecha_transaccion DATETIME DEFAULT GETDATE(),
            numero_destino NVARCHAR(50),
            comprobante NVARCHAR(100)
        )",
        
        // Tabla de métodos de pago
        "CREATE TABLE metodos_pago (
            id INT IDENTITY(1,1) PRIMARY KEY,
            usuario_id INT FOREIGN KEY REFERENCES usuarios(id),
            tipo NVARCHAR(20) NOT NULL,
            nombre NVARCHAR(100),
            numero_tarjeta NVARCHAR(20),
            fecha_expiracion NVARCHAR(7),
            banco NVARCHAR(100),
            activo BIT DEFAULT 1,
            fecha_agregado DATETIME DEFAULT GETDATE()
        )",
        
        // Tabla de configuración
        "CREATE TABLE configuracion (
            id INT IDENTITY(1,1) PRIMARY KEY,
            clave NVARCHAR(50) UNIQUE NOT NULL,
            valor NVARCHAR(255),
            descripcion NVARCHAR(255),
            fecha_actualizacion DATETIME DEFAULT GETDATE()
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
    
    // Insertar datos iniciales
    $insertData = [
        // Servicios iniciales
        "INSERT INTO servicios (nombre, descripcion, categoria, icono, color) VALUES 
        ('Recargas Tigo', 'Recarga tu línea Tigo', 'Telefonía', 'phone', '#0066CC'),
        ('Recargas Claro', 'Recarga tu línea Claro', 'Telefonía', 'phone', '#FF0000'),
        ('Recargas Viva', 'Recarga tu línea Viva', 'Telefonía', 'phone', '#FF6600'),
        ('Pago de Luz', 'Pago de servicios eléctricos', 'Servicios', 'zap', '#FFD700'),
        ('Pago de Agua', 'Pago de servicios de agua', 'Servicios', 'droplets', '#00BFFF'),
        ('Pago de Gas', 'Pago de servicios de gas', 'Servicios', 'flame', '#FF4500'),
        ('Transferencias', 'Transferir dinero', 'Transferencias', 'send', '#32CD32')",
        
        // Configuración inicial
        "INSERT INTO configuracion (clave, valor, descripcion) VALUES 
        ('app_name', 'SkyPagos', 'Nombre de la aplicación'),
        ('version', '1.0.0', 'Versión de la aplicación'),
        ('comision_defecto', '2.50', 'Comisión por defecto en porcentaje'),
        ('monto_minimo', '10.00', 'Monto mínimo para transacciones'),
        ('monto_maximo', '5000.00', 'Monto máximo para transacciones')"
    ];
    
    foreach ($insertData as $insertSql) {
        $stmt = sqlsrv_query($conn, $insertSql);
        if ($stmt === false) {
            echo "Error insertando datos: " . print_r(sqlsrv_errors(), true) . "\n";
        } else {
            echo "Datos insertados exitosamente.\n";
        }
    }
    
    echo "¡Base de datos y tablas creadas exitosamente!\n";
    
    sqlsrv_close($conn);
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
