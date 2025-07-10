const express = require("express")
const cors = require("cors")
const bcrypt = require("bcrypt")
const jwt = require("jsonwebtoken")
const sql = require("mssql")
const crypto = require("crypto")
const helmet = require("helmet")
const rateLimit = require("express-rate-limit")
require("dotenv").config()

const app = express()
const PORT = process.env.PORT || 3000
const JWT_SECRET = process.env.JWT_SECRET || "skypagos_secret_key_2024_super_secure"

// Configuración de la base de datos
const dbConfig = {
  server: "192.168.2.244",
  database: "SkyPagos",
  user: "sa",
  password: "Sky2022*!",
  port: 1433,
  options: {
    encrypt: false,
    trustServerCertificate: true,
    enableArithAbort: true,
    connectTimeout: 60000,
    requestTimeout: 60000,
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
}

// Middleware de seguridad
app.use(helmet())
app.use(
  cors({
    origin: "*", // Permitir cualquier origen
    credentials: true,
  }),
)
app.use(express.json({ limit: "10mb" }))
app.use(express.urlencoded({ extended: true }))

/// Rate limiting global (puedes reducir esto también si lo necesitas)
const limiter = rateLimit({
  windowMs: 1000, // 1 segundo
  max: 100, // máximo 100 requests por segundo
  message: {
    error: "Demasiadas solicitudes, intenta nuevamente en 1 segundo",
  },
})
app.use("/api/", limiter)

// Rate limiting específico para login
const loginLimiter = rateLimit({
  windowMs: 1000, // 1 segundo
  max: 5, // máximo 5 intentos de login por segundo por IP
  message: {
    error: "Demasiados intentos de login, intenta nuevamente en 1 segundo",
  },
})

// Conexión a la base de datos
let pool

async function connectDB() {
  try {
    pool = await sql.connect(dbConfig)
    console.log("✅ Conectado a SQL Server exitosamente")

    // Verificar que las tablas existen
    const result = await pool.request().query(`
      SELECT COUNT(*) as count FROM INFORMATION_SCHEMA.TABLES 
      WHERE TABLE_NAME IN ('usuarios', 'transacciones', 'tipos_transaccion')
    `)

    if (result.recordset[0].count < 3) {
      console.log("⚠️  Advertencia: Algunas tablas no existen. Ejecuta los scripts SQL primero.")
    }
  } catch (err) {
    console.error("❌ Error conectando a la base de datos:", err.message)
    console.log("💡 Verifica que:")
    console.log("   - SQL Server esté ejecutándose")
    console.log("   - Las credenciales sean correctas")
    console.log("   - La base de datos 'SkyPagos' exista")
    process.exit(1)
  }
}

// Middleware de autenticación
const authenticateToken = (req, res, next) => {
  // Simula un usuario autenticado con userId de prueba
  req.user = { userId: 1 } // o cualquier ID válido que tengas
  next()
}

// Generar código de transacción único
function generateTransactionCode() {
  const timestamp = Date.now().toString()
  const random = crypto.randomBytes(4).toString("hex").toUpperCase()
  return `SKY${timestamp.slice(-6)}${random}`
}

// Función para hashear PIN
async function hashPin(pin) {
  const saltRounds = 10
  return await bcrypt.hash(pin, saltRounds)
}

// RUTAS DE AUTENTICACIÓN

// Login
app.post("/api/auth/login", loginLimiter, async (req, res) => {
  try {
    const { documento, pin } = req.body

    // Verificar que se proporcione documento y PIN
    if (!documento || !pin) {
      return res.status(400).json({ 
        error: "Documento y PIN son requeridos" 
      })
    }

    // Validar formato de documento
    if (!/^\d{8,15}$/.test(documento)) {
      return res.status(400).json({ error: "Formato de documento inválido (8-15 dígitos)" })
    }

    const request = pool.request()
    const query = "SELECT * FROM usuarios WHERE documento = @documento AND estado = 'ACTIVO'"
    
    request.input("documento", sql.NVarChar, documento)

    const result = await request.query(query)

    if (result.recordset.length === 0) {
      return res.status(401).json({ error: "Usuario no encontrado o inactivo" })
    }

    const user = result.recordset[0]

    // Verificar PIN (permitir PIN simple para pruebas)
    let validPin = false
    if (pin === "1234") {
      validPin = true // PIN de prueba
    } else {
      try {
        validPin = await bcrypt.compare(pin, user.pin)
      } catch (bcryptError) {
        // Si el PIN no está hasheado, comparar directamente
        validPin = pin === user.pin
      }
    }

    if (!validPin) {
      return res.status(401).json({ error: "PIN incorrecto" })
    }

    // Generar token JWT
    const token = jwt.sign(
      {
        userId: user.id,
        documento: user.documento,
        nombre: user.nombre,
      },
      JWT_SECRET,
      { expiresIn: "24h" }
    )

    // Guardar sesión
    try {
      await request
        .input("usuario_id", sql.Int, user.id)
        .input("token", sql.NVarChar, token)
        .input("fecha_expiracion", sql.DateTime, new Date(Date.now() + 24 * 60 * 60 * 1000))
        .input("ip_address", sql.NVarChar, req.ip)
        .query(`INSERT INTO sesiones (usuario_id, token, fecha_expiracion, ip_address)
                VALUES (@usuario_id, @token, @fecha_expiracion, @ip_address)`)
    } catch (sessionError) {
      console.log("Advertencia: No se pudo guardar la sesión:", sessionError.message)
    }

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        nombre: user.nombre,
        apellido: user.apellido,
        telefono: user.telefono,
        email: user.email,
        documento: user.documento,
        tipo_documento: user.tipo_documento,
        saldo: Number.parseFloat(user.saldo),
        foto_perfil: user.foto_perfil,
      },
    })
  } catch (error) {
    console.error("Error en login:", error)
    res.status(500).json({ error: "Error interno del servidor" })
  }
})

// Registro
app.post("/api/auth/register", async (req, res) => {
  try {
    const { nombre, apellido, telefono, email, pin, documento } = req.body

    if (!nombre || !apellido || !telefono || !pin || !documento) {
      return res.status(400).json({ error: "Todos los campos obligatorios son requeridos" })
    }

    // Validaciones
    if (!/^\d{10}$/.test(telefono)) {
      return res.status(400).json({ error: "El teléfono debe tener 10 dígitos" })
    }

    if (pin.length < 4) {
      return res.status(400).json({ error: "El PIN debe tener al menos 4 dígitos" })
    }

    const request = pool.request()

    // Verificar si el usuario ya existe
    const existingUser = await request
      .input("telefono", sql.NVarChar, telefono)
      .input("documento", sql.NVarChar, documento)
      .query("SELECT id FROM usuarios WHERE telefono = @telefono OR documento = @documento")

    if (existingUser.recordset.length > 0) {
      return res.status(400).json({ error: "Ya existe un usuario con ese teléfono o documento" })
    }

    // Hashear PIN
    const hashedPin = await hashPin(pin)

    // Insertar nuevo usuario
    const result = await request
      .input("nombre", sql.NVarChar, nombre)
      .input("apellido", sql.NVarChar, apellido)
      .input("telefono_new", sql.NVarChar, telefono)
      .input("email", sql.NVarChar, email || null)
      .input("pin", sql.NVarChar, hashedPin)
      .input("documento_new", sql.NVarChar, documento)
      .query(`INSERT INTO usuarios (nombre, apellido, telefono, email, pin, documento) 
              OUTPUT INSERTED.id
              VALUES (@nombre, @apellido, @telefono_new, @email, @pin, @documento_new)`)

    const userId = result.recordset[0].id

    res.json({
      success: true,
      message: "Usuario registrado exitosamente",
      userId,
    })
  } catch (error) {
    console.error("Error en registro:", error)
    res.status(500).json({ error: "Error interno del servidor" })
  }
})

// RUTAS PROTEGIDAS

// Obtener perfil del usuario
app.get("/api/user/profile", authenticateToken, async (req, res) => {
  try {
    const request = pool.request()
    const result = await request
      .input("userId", sql.Int, req.user.userId)
      .query(`SELECT id, nombre, apellido, telefono, email, saldo, limite_diario, limite_mensual, foto_perfil 
              FROM usuarios WHERE id = @userId`)

    if (result.recordset.length === 0) {
      return res.status(404).json({ error: "Usuario no encontrado" })
    }

    const user = result.recordset[0]
    user.saldo = Number.parseFloat(user.saldo)
    user.limite_diario = Number.parseFloat(user.limite_diario)
    user.limite_mensual = Number.parseFloat(user.limite_mensual)

    res.json({
      success: true,
      user,
    })
  } catch (error) {
    console.error("Error obteniendo perfil:", error)
    res.status(500).json({ error: "Error interno del servidor" })
  }
})

// Obtener saldo
app.get("/api/user/balance", authenticateToken, async (req, res) => {
  try {
    const request = pool.request()
    const result = await request
      .input("userId", sql.Int, req.user.userId)
      .query("SELECT saldo FROM usuarios WHERE id = @userId")

    res.json({
      success: true,
      saldo: Number.parseFloat(result.recordset[0].saldo),
    })
  } catch (error) {
    console.error("Error obteniendo saldo:", error)
    res.status(500).json({ error: "Error interno del servidor" })
  }
})

// Enviar dinero
app.post("/api/transactions/send", authenticateToken, async (req, res) => {
  try {
    const { telefono_destino, monto, descripcion } = req.body
    const userId = req.user.userId

    if (!telefono_destino || !monto || monto <= 0) {
      return res.status(400).json({ error: "Datos inválidos" })
    }

    if (!/^\d{8}$/.test(telefono_destino)) {
      return res.status(400).json({ error: "Formato de teléfono destino inválido" })
    }

    const montoNum = Number.parseFloat(monto)
    if (montoNum < 1 || montoNum > 10000) {
      return res.status(400).json({ error: "El monto debe estar entre Bs. 1.00 y Bs. 10,000.00" })
    }

    const request = pool.request()

    // Verificar saldo del usuario origen
    const saldoResult = await request
      .input("userId", sql.Int, userId)
      .query("SELECT saldo FROM usuarios WHERE id = @userId")

    const saldoActual = Number.parseFloat(saldoResult.recordset[0].saldo)
    const comision = montoNum * 0.005 // 0.5% de comisión
    const montoTotal = montoNum + comision

    if (saldoActual < montoTotal) {
      return res.status(400).json({
        error: "Saldo insuficiente",
        saldo_actual: saldoActual,
        monto_requerido: montoTotal,
      })
    }

    // Buscar usuario destino
    const destinoResult = await request
      .input("telefono_destino", sql.NVarChar, telefono_destino)
      .query("SELECT id, nombre, apellido FROM usuarios WHERE telefono = @telefono_destino AND estado = 'ACTIVO'")

    if (destinoResult.recordset.length === 0) {
      return res.status(404).json({ error: "Usuario destino no encontrado o inactivo" })
    }

    const userDestino = destinoResult.recordset[0]
    const codigoTransaccion = generateTransactionCode()

    // Iniciar transacción
    const transaction = pool.transaction()
    await transaction.begin()

    try {
      const transactionRequest = transaction.request()

      // Insertar transacción
      await transactionRequest
        .input("codigo_transaccion", sql.NVarChar, codigoTransaccion)
        .input("usuario_origen_id", sql.Int, userId)
        .input("usuario_destino_id", sql.Int, userDestino.id)
        .input("tipo_transaccion_id", sql.Int, 1) // Envío de dinero
        .input("monto", sql.Decimal(15, 2), montoNum)
        .input("comision", sql.Decimal(15, 2), comision)
        .input("monto_total", sql.Decimal(15, 2), montoTotal)
        .input("descripcion", sql.NVarChar, descripcion || "Envío de dinero")
        .input("telefono_destino", sql.NVarChar, telefono_destino)
        .input("nombre_destino", sql.NVarChar, `${userDestino.nombre} ${userDestino.apellido}`)
        .input("estado", sql.NVarChar, "COMPLETADA")
        .query(`INSERT INTO transacciones 
                (codigo_transaccion, usuario_origen_id, usuario_destino_id, tipo_transaccion_id, 
                 monto, comision, monto_total, descripcion, telefono_destino, nombre_destino, estado, fecha_procesamiento)
                VALUES (@codigo_transaccion, @usuario_origen_id, @usuario_destino_id, @tipo_transaccion_id,
                        @monto, @comision, @monto_total, @descripcion, @telefono_destino, @nombre_destino, @estado, GETDATE())`)

      // Actualizar saldo origen
      await transactionRequest
        .input("nuevo_saldo_origen", sql.Decimal(15, 2), saldoActual - montoTotal)
        .input("userId_origen", sql.Int, userId)
        .query("UPDATE usuarios SET saldo = @nuevo_saldo_origen WHERE id = @userId_origen")

      // Actualizar saldo destino
      await transactionRequest
        .input("monto_destino", sql.Decimal(15, 2), montoNum)
        .input("userId_destino", sql.Int, userDestino.id)
        .query("UPDATE usuarios SET saldo = saldo + @monto_destino WHERE id = @userId_destino")

      await transaction.commit()

      res.json({
        success: true,
        message: "Transferencia realizada exitosamente",
        transaccion: {
          codigo: codigoTransaccion,
          monto: montoNum,
          comision: comision,
          total: montoTotal,
          destino: `${userDestino.nombre} ${userDestino.apellido}`,
          telefono_destino: telefono_destino,
        },
      })
    } catch (error) {
      await transaction.rollback()
      throw error
    }
  } catch (error) {
    console.error("Error en envío de dinero:", error)
    res.status(500).json({ error: "Error procesando la transacción" })
  }
})

// Obtener historial de transacciones
app.get("/api/transactions/history", authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query
    const offset = (Number.parseInt(page) - 1) * Number.parseInt(limit)

    const request = pool.request()
    const result = await request
      .input("userId", sql.Int, req.user.userId)
      .input("limit", sql.Int, Number.parseInt(limit))
      .input("offset", sql.Int, offset)
      .query(`SELECT t.*, tt.nombre as tipo_nombre
              FROM transacciones t
              LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
              WHERE t.usuario_origen_id = @userId OR t.usuario_destino_id = @userId
              ORDER BY t.fecha_transaccion DESC
              OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY`)

    // Convertir decimales a números
    const transacciones = result.recordset.map((t) => ({
      ...t,
      monto: Number.parseFloat(t.monto),
      comision: Number.parseFloat(t.comision),
      monto_total: Number.parseFloat(t.monto_total),
    }))

    res.json({
      success: true,
      transacciones,
      page: Number.parseInt(page),
      limit: Number.parseInt(limit),
    })
  } catch (error) {
    console.error("Error obteniendo historial:", error)
    res.status(500).json({ error: "Error interno del servidor" })
  }
})

// Obtener beneficiarios
app.get("/api/beneficiaries", authenticateToken, async (req, res) => {
  try {
    const request = pool.request()
    const result = await request
      .input("userId", sql.Int, req.user.userId)
      .query("SELECT * FROM beneficiarios WHERE usuario_id = @userId ORDER BY nombre")

    res.json({
      success: true,
      beneficiarios: result.recordset,
    })
  } catch (error) {
    console.error("Error obteniendo beneficiarios:", error)
    res.status(500).json({ error: "Error interno del servidor" })
  }
})

// Agregar beneficiario
app.post("/api/beneficiaries", authenticateToken, async (req, res) => {
  try {
    const { nombre, telefono, alias } = req.body

    if (!nombre || !telefono) {
      return res.status(400).json({ error: "Nombre y teléfono son requeridos" })
    }

    if (!/^\d{8}$/.test(telefono)) {
      return res.status(400).json({ error: "Formato de teléfono inválido" })
    }

    const request = pool.request()
    await request
      .input("usuario_id", sql.Int, req.user.userId)
      .input("nombre", sql.NVarChar, nombre)
      .input("telefono", sql.NVarChar, telefono)
      .input("alias", sql.NVarChar, alias)
      .query(`INSERT INTO beneficiarios (usuario_id, nombre, telefono, alias)
              VALUES (@usuario_id, @nombre, @telefono, @alias)`)

    res.json({
      success: true,
      message: "Beneficiario agregado exitosamente",
    })
  } catch (error) {
    console.error("Error agregando beneficiario:", error)
    res.status(500).json({ error: "Error interno del servidor" })
  }
})

// Obtener notificaciones
app.get("/api/notifications", authenticateToken, async (req, res) => {
  try {
    const request = pool.request()
    const result = await request.input("userId", sql.Int, req.user.userId).query(`SELECT * FROM notificaciones 
              WHERE usuario_id = @userId 
              ORDER BY fecha_creacion DESC`)

    res.json({
      success: true,
      notificaciones: result.recordset,
    })
  } catch (error) {
    console.error("Error obteniendo notificaciones:", error)
    res.status(500).json({ error: "Error interno del servidor" })
  }
})

// Ruta de prueba
app.get("/api/test", (req, res) => {
  res.json({
    success: true,
    message: "🚀 API SkyPagos funcionando correctamente",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
    database: pool ? "Conectada" : "Desconectada",
  })
})

// Ruta de estado de la base de datos
app.get("/api/health", async (req, res) => {
  try {
    const result = await pool.request().query("SELECT COUNT(*) as usuarios FROM usuarios")
    res.json({
      success: true,
      database: "Conectada",
      usuarios_registrados: result.recordset[0].usuarios,
      timestamp: new Date().toISOString(),
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      database: "Error de conexión",
      error: error.message,
    })
  }
})

// Manejo de errores global
app.use((err, req, res, next) => {
  console.error("Error no manejado:", err)
  res.status(500).json({
    error: "Error interno del servidor",
    message: process.env.NODE_ENV === "development" ? err.message : "Algo salió mal",
  })
})

// Manejo de rutas no encontradas
app.use("*", (req, res) => {
  res.status(404).json({
    error: "Ruta no encontrada",
    message: `La ruta ${req.originalUrl} no existe`,
  })
})

// Inicializar servidor
async function startServer() {
  try {
    await connectDB()

    app.listen(PORT, "0.0.0.0", () => {
      console.log(`🚀 Servidor SkyPagos corriendo en puerto ${PORT}`)
      console.log(`🌐 Acceso externo: http://localhost:${PORT}/api/test`)
      console.log(`📊 Panel de pruebas: http://localhost:${PORT}/api/test`)
      console.log(`💚 Estado de salud: http://localhost:${PORT}/api/health`)
      console.log(`📱 Listo para recibir conexiones de la app Flutter`)
    })
  } catch (error) {
    console.error("❌ Error iniciando el servidor:", error)
    process.exit(1)
  }
}

startServer()

// Manejo de cierre graceful
process.on("SIGINT", async () => {
  console.log("\n🛑 Cerrando servidor...")
  if (pool) {
    await pool.close()
    console.log("📊 Conexión a base de datos cerrada")
  }
  process.exit(0)
})
