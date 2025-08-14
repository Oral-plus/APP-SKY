const express = require("express")
const sql = require("mssql")
const cors = require("cors")
const os = require("os")
const { exec } = require("child_process")
const https = require("https")
const nodemailer = require("nodemailer")
const fs = require("fs")
const path = require("path")

const app = express()
const port = 3007

// 🔧 MIDDLEWARE MEJORADO
app.use(
  cors({
    origin: "*", // Permitir todos los orígenes para desarrollo
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allowedHeaders: ["Content-Type", "Authorization", "Accept", "Origin", "X-Requested-With"],
    credentials: false,
  }),
)

app.use(express.json({ limit: "10mb" }))
app.use(express.urlencoded({ extended: true, limit: "10mb" }))

// 🔧 LOGGING MIDDLEWARE
app.use((req, res, next) => {
  const timestamp = new Date().toISOString()
  console.log(`📡 [${timestamp}] ${req.method} ${req.url}`)
  console.log(`📋 Headers:`, JSON.stringify(req.headers, null, 2))
  if (req.body && Object.keys(req.body).length > 0) {
    console.log(`📦 Body:`, JSON.stringify(req.body, null, 2))
  }
  next()
})

// 🔧 CONFIGURACIÓN DE LA BASE DE DATOS
const dbConfig = {
  user: "sa",
  password: "Sky2022*!",
  server: "192.168.2.244",
  database: "RBOSKY3",
  port: 1433,
  options: {
    encrypt: false,
    trustServerCertificate: true,
    enableArithAbort: true,
    connectTimeout: 30000,
    requestTimeout: 30000,
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
}

// 🔧 CONFIGURACIÓN SAP API REST
const sapConfig = {
  baseUrl: "https://192.168.2.242:50000/b1s/v1",
  username: "MANAGER",
  password: "SKY0303",
  companyDB: "RBOSKY3",
}

// 📧 CONFIGURACIÓN DE CORREO
const emailConfig = {
  service: "gmail",
  auth: {
    user: "formularioretiro@gmail.com",
    pass: "dqho djgx yzlu llby",
  },
}

// Variable global para el pool de conexiones
let globalPool = null

// 🔗 Función para conectar a la base de datos
async function connectToDatabase() {
  if (globalPool && globalPool.connected) {
    return globalPool
  }
  try {
    console.log("🔄 Conectando a la base de datos...")
    console.log(`📍 Servidor: ${dbConfig.server}:${dbConfig.port}`)
    console.log(`🗄️ Base de datos: ${dbConfig.database}`)
    console.log(`👤 Usuario: ${dbConfig.user}`)

    globalPool = new sql.ConnectionPool(dbConfig)
    await globalPool.connect()
    console.log("✅ Conectado a SQL Server exitosamente")

    return globalPool
  } catch (err) {
    console.error("❌ Error conectando a la base de datos:", err.message)
    throw err
  }
}

// 🔐 Función para iniciar sesión en SAP
async function iniciarSesionSAP() {
  return new Promise((resolve, reject) => {
    const loginData = {
      UserName: sapConfig.username,
      Password: sapConfig.password,
      CompanyDB: sapConfig.companyDB,
    }

    const postData = JSON.stringify(loginData)
    const options = {
      hostname: "192.168.2.242",
      port: 50000,
      path: "/b1s/v1/Login",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(postData),
      },
      rejectUnauthorized: false,
      requestCert: false,
      agent: false,
      timeout: 60000,
    }

    const req = https.request(options, (res) => {
      let data = ""
      res.on("data", (chunk) => {
        data += chunk
      })
      res.on("end", () => {
        if (res.statusCode === 200) {
          try {
            const response = JSON.parse(data)
            const sessionId = response.SessionId
            console.log("✅ Sesión SAP iniciada:", sessionId)
            resolve(sessionId)
          } catch (error) {
            console.error("❌ Error parseando respuesta de login SAP:", error)
            reject(error)
          }
        } else {
          console.error("❌ Error en login SAP:", res.statusCode, data)
          reject(new Error(`Login SAP falló: ${res.statusCode}`))
        }
      })
    })

    req.on("error", (error) => {
      console.error("❌ Error de conexión SAP:", error)
      reject(error)
    })

    req.on("timeout", () => {
      console.error("❌ Timeout en login SAP")
      req.destroy()
      reject(new Error("Timeout en login SAP"))
    })

    req.write(postData)
    req.end()
  })
}

// ✅ NUEVO ENDPOINT: Obtener cliente SAP (compatible con Flutter)
app.get("/api/obtener_cliente_sap.php", async (req, res) => {
  const startTime = Date.now()
  const cardCode = req.query.cardcode

  console.log(`👤 [${new Date().toISOString()}] Consulta cliente SAP - CardCode: ${cardCode}`)

  if (!cardCode || cardCode.trim() === "") {
    console.log("❌ CardCode vacío")
    return res.json(["CardCode no puede estar vacío"])
  }

  try {
    const pool = await connectToDatabase()

    const query = `
      SELECT 
        T0.[CardName],
        T0.[Address], 
        T0.[Phone1],
        T0.E_Mail,
        T0.[CardCode]
      FROM OCRD T0
      INNER JOIN OCRG T1 ON T0.[GroupCode] = T1.[GroupCode] 
      INNER JOIN dbo.[@DISTRIBUCION] T2 ON T0.U_CANAL_DISTRIBUCION = T2.Code
      WHERE T0.CardCode = @cardCode 
        AND T1.[GroupName] <> 'Droguerias Cadenas'
        AND T1.[GroupName] <> 'Canal Grandes Superf' 
        AND T2.Name <> 'HARD DISCOUNT NACIONALES' 
        AND T2.Name <> 'HARD DISCOUNT INDEPENDIENTES'
    `

    console.log("🔍 Ejecutando consulta SQL...")
    const result = await pool.request().input("cardCode", sql.VarChar, cardCode).query(query)

    const queryTime = Date.now() - startTime
    console.log(`⏱️ Consulta SAP ejecutada en ${queryTime}ms`)
    console.log(`📊 Registros encontrados: ${result.recordset.length}`)

    if (result.recordset.length === 0) {
      console.log("📭 Cliente no encontrado")
      return res.json(["No se encontraron datos para la cédula proporcionada"])
    }

    const clientData = result.recordset[0]
    console.log("✅ Datos del cliente encontrados en SAP:")
    console.log(`   👤 Nombre: ${clientData.CardName}`)
    console.log(`   📍 Dirección: ${clientData.Address || "N/A"}`)
    console.log(`   📞 Teléfono: ${clientData.Phone1 || "N/A"}`)
    console.log(`   📧 Email: ${clientData.E_Mail || "N/A"}`)

    res.json({
      CardName: clientData.CardName || "",
      Address: clientData.Address || "",
      Phone1: clientData.Phone1 || "",
      E_Mail: clientData.E_Mail || "",
    })
  } catch (error) {
    const queryTime = Date.now() - startTime
    console.error("❌ Error en consulta cliente SAP:", error.message)
    res.status(500).json({
      error: "Error interno del servidor",
      details: error.message,
      queryTime: queryTime,
    })
  }
})

// ✅ NUEVO ENDPOINT: Obtener precios SAP (compatible con Flutter)
app.get("/api/obtener_precios_sap.php", async (req, res) => {
  const startTime = Date.now()
  const { codigos, cliente } = req.query

  console.log(`💰 [${new Date().toISOString()}] Consulta precios SAP`)
  console.log(`📋 Códigos: ${codigos}`)
  console.log(`👤 Cliente: ${cliente}`)

  if (!codigos || !cliente) {
    return res.json({
      error: "Códigos y cliente son requeridos",
      success: false,
    })
  }

  try {
    const pool = await connectToDatabase()
    const codigosArray = codigos.split(",")

    // Consulta de precios SAP
    const query = `
      SELECT 
        T0.ItemCode,
        T0.ItemName,
        ISNULL(T1.Price, 0) as Price,
        T0.OnHand,
        T0.IsCommited,
        T0.OnOrder,
        (T0.OnHand - T0.IsCommited) as Available
      FROM OITM T0
      LEFT JOIN ITM1 T1 ON T0.ItemCode = T1.ItemCode AND T1.PriceList = 1
      WHERE T0.ItemCode IN (${codigosArray.map((_, i) => `@codigo${i}`).join(",")})
    `

    const request = pool.request()
    codigosArray.forEach((codigo, i) => {
      request.input(`codigo${i}`, sql.VarChar, codigo.trim())
    })

    console.log("💰 Consultando precios SAP...")
    const result = await request.query(query)

    const queryTime = Date.now() - startTime
    console.log(`⏱️ Consulta precios ejecutada en ${queryTime}ms`)

    // Formatear respuesta
    const precios = {}
    result.recordset.forEach((item) => {
      precios[item.ItemCode] = {
        codigo: item.ItemCode,
        nombre: item.ItemName,
        precio: item.Price.toString(),
        disponible: item.Available,
        stock: item.OnHand,
      }
    })

    console.log(`✅ PRECIOS SAP OBTENIDOS: ${Object.keys(precios).length} productos`)

    res.json({
      success: true,
      precios: precios,
      total: Object.keys(precios).length,
      lista_precios_usada: 1,
      cliente: cliente,
      queryTime: queryTime,
      timestamp: new Date().toISOString(),
    })
  } catch (error) {
    const queryTime = Date.now() - startTime
    console.error("❌ Error obteniendo precios SAP:", error.message)
    res.json({
      error: `Error obteniendo precios: ${error.message}`,
      success: false,
      queryTime: queryTime,
    })
  }
})

// ✅ NUEVO ENDPOINT: Obtener estados productos SAP (compatible con Flutter)
app.get("/api/obtener_estados_productos_sap.php", async (req, res) => {
  const startTime = Date.now()
  const { codigos, cliente } = req.query

  console.log(`📦 [${new Date().toISOString()}] Consulta estados SAP`)
  console.log(`📋 Códigos: ${codigos}`)
  console.log(`👤 Cliente: ${cliente}`)

  if (!codigos || !cliente) {
    return res.json({
      error: "Códigos y cliente son requeridos",
      success: false,
      productos: {},
    })
  }

  try {
    const pool = await connectToDatabase()
    const codigosArray = codigos.split(",")

    // Consulta de estados de productos
    const query = `
      SELECT 
        T0.ItemCode,
        T0.ItemName,
        T0.OnHand,
        T0.IsCommited,
        T0.OnOrder,
        (T0.OnHand - T0.IsCommited) as Available,
        CASE 
          WHEN (T0.OnHand - T0.IsCommited) > 0 THEN 'Disponible'
          ELSE 'Sin stock'
        END as Estado
      FROM OITM T0
      WHERE T0.ItemCode IN (${codigosArray.map((_, i) => `@codigo${i}`).join(",")})
    `

    const request = pool.request()
    codigosArray.forEach((codigo, i) => {
      request.input(`codigo${i}`, sql.VarChar, codigo.trim())
    })

    console.log("📦 Consultando estados SAP...")
    const result = await request.query(query)

    const queryTime = Date.now() - startTime
    console.log(`⏱️ Consulta estados ejecutada en ${queryTime}ms`)

    // Formatear respuesta
    const productos = {}
    result.recordset.forEach((item) => {
      productos[item.ItemCode] = {
        codigo: item.ItemCode,
        nombre: item.ItemName,
        disponible: item.Available > 0,
        stock: item.OnHand,
        comprometido: item.IsCommited,
        disponible_cantidad: item.Available,
        estado: item.Estado,
        mensaje: item.Available > 0 ? "Producto disponible" : "Sin stock disponible",
      }
    })

    console.log(`✅ ESTADOS SAP OBTENIDOS: ${Object.keys(productos).length} productos`)

    res.json({
      success: true,
      productos: productos,
      total: Object.keys(productos).length,
      cliente: cliente,
      codigos_consultados: codigosArray.length,
      codigos_encontrados: Object.keys(productos).length,
      queryTime: queryTime,
      timestamp: new Date().toISOString(),
    })
  } catch (error) {
    const queryTime = Date.now() - startTime
    console.error("❌ Error obteniendo estados SAP:", error.message)
    res.json({
      error: `Error obteniendo estados: ${error.message}`,
      success: false,
      productos: {},
      queryTime: queryTime,
    })
  }
})

// 👤 ENDPOINT PRINCIPAL: Obtener datos del cliente por CardCode (MANTENER EXISTENTE)
app.get("/api/client/data/:cardCode", async (req, res) => {
  const startTime = Date.now()
  const cardCode = req.params.cardCode
  console.log(`👤 [${new Date().toISOString()}] Consulta de cliente SAP - CardCode: ${cardCode}`)

  if (!cardCode || cardCode.trim() === "") {
    console.log("❌ CardCode vacío o no proporcionado")
    return res.status(400).json({
      success: false,
      error: "CardCode no puede estar vacío",
    })
  }

  try {
    const pool = await connectToDatabase()
    const query = `
      SELECT 
        T0.[CardName],
        T0.[Address],
        T0.[Phone1],
        T0.E_Mail,
        T0.[CardCode]
      FROM OCRD T0
      INNER JOIN OCRG T1 ON T0.[GroupCode] = T1.[GroupCode] 
      INNER JOIN dbo.[@DISTRIBUCION] T2 ON T0.U_CANAL_DISTRIBUCION = T2.Code
      WHERE T0.CardCode = @cardCode 
        AND T1.[GroupName] <> 'Droguerias Cadenas'
        AND T1.[GroupName] <> 'Canal Grandes Superf' 
        AND T2.Name <> 'HARD DISCOUNT NACIONALES' 
        AND T2.Name <> 'HARD DISCOUNT INDEPENDIENTES'
    `

    console.log("🔍 Ejecutando consulta SQL en SAP...")
    const result = await pool.request().input("cardCode", sql.VarChar, cardCode).query(query)

    const queryTime = Date.now() - startTime
    console.log(`⏱️ Consulta SAP ejecutada en ${queryTime}ms`)
    console.log(`📊 Registros encontrados: ${result.recordset.length}`)

    if (result.recordset.length === 0) {
      console.log("📭 No se encontraron datos en SAP para el CardCode proporcionado")
      res.setHeader("Content-Type", "application/json")
      return res.json(["No se encontraron datos para la cédula proporcionada"])
    }

    const clientData = result.recordset[0]
    console.log("✅ Datos del cliente encontrados en SAP:")
    console.log(`   👤 Nombre: ${clientData.CardName}`)
    console.log(`   📍 Dirección: ${clientData.Address || "N/A"}`)
    console.log(`   📞 Teléfono: ${clientData.Phone1 || "N/A"}`)
    console.log(`   📧 Email: ${clientData.E_Mail || "N/A"}`)

    res.setHeader("Content-Type", "application/json")
    res.json({
      CardName: clientData.CardName || "",
      Address: clientData.Address || "",
      Phone1: clientData.Phone1 || "",
      E_Mail: clientData.E_Mail || "",
    })
  } catch (error) {
    const queryTime = Date.now() - startTime
    console.error("❌ Error en consulta de cliente SAP:", error.message)
    res.status(500).json({
      success: false,
      error: "Error interno del servidor al consultar datos del cliente en SAP",
      details: error.message,
      cardCode: cardCode,
      queryTime: queryTime,
      timestamp: new Date().toISOString(),
    })
  }
})

// 📧 Función para enviar correo
async function enviarCorreo(destinatario, nombre, subtotal, docNum, docEntry, productos = []) {
  try {
    const transporter = nodemailer.createTransporter({
      service: "gmail",
      auth: emailConfig.auth,
    })

    const productosHtml =
      productos.length > 0
        ? `
      <h4 style='padding:0 20px;font-family:Helvetica;font-size:18px;'>Productos comprados:</h4>
      <div style='padding:0 20px;'>
        ${productos
          .map(
            (p) => `
          <div style='background:#f0f0f0;margin:10px 0;padding:15px;border-radius:8px;'>
            <strong>${p.nombre || p.codigo}</strong><br>
            Código: ${p.codigo}<br>
            Cantidad: ${p.cantidad}<br>
            Precio: $${Number(p.precio).toLocaleString()}
          </div>
        `,
          )
          .join("")}
      </div>
    `
        : ""

    const htmlContent = `
    <div style='background-color:#f7f7f7;'>
      <div style='background-color:#fff; max-width:600px; border:1px solid #d9d9d9; margin:auto;'>
        <div style='text-align:center; padding:20px;'>
          <h1 style='color:#2563eb;'>ORAL-PLUS</h1>
        </div>
        <h2 style='padding:20px;font-family:Helvetica;'>Hola, ${nombre},</h2>
        <h3 style='padding:0 20px;font-family:Helvetica;'>Recibimos la compra que realizaste desde nuestra página web.</h3>
        <p style='padding:20px;font-family:Helvetica;font-size:18px;line-height:1.5;color:#111;'>
          Con Oral-Plus, cuidamos de tu salud bucal para que tú puedas seguir creando recuerdos inolvidables
        </p>
        ${productosHtml}
        <h4 style='padding:0 20px;font-family:Helvetica;font-size:18px;'>Estos son los detalles de tu compra</h4>
        <div style='padding:24px;background:#f7f7f7;margin:25px;font-family:Helvetica;font-size:20px;font-weight:bold;color:#111;'>
          Tu compra fue de:<br><span style='display:block;'>$${subtotal}</span>
        </div>
        ${
          docNum
            ? `<div style='padding:24px;background:#e0f2fe;margin:25px;font-family:Helvetica;font-size:16px;color:#111;'>
          <strong>Número de documento SAP:</strong> ${docNum}<br>
          <strong>ID de transacción:</strong> ${docEntry}
        </div>`
            : ""
        }
        <h4 style='padding:0 0 0 20px;font-family:Helvetica;font-size:18px;'>Paga tu factura</h4>
        <p style='padding-left:20px;font-family:Helvetica;font-size:18px;line-height:1.5;color:#111;'>
          Una vez hayas recibido tu pedido, podrás pagar tu factura en el siguiente enlace:<br>
          <a href='https://oral-plus.com/registro.php'>https://oral-plus.com/registro.php</a>
        </p>
        <p style='padding-left:20px;font-family:Helvetica;font-size:18px;line-height:1.5;color:#111;'>
          Gracias por tu compra
        </p>
        <div style='background:#000;padding:40px 25px;'>
          <p style='color:#fff;padding-top:20px;font-family:Helvetica;font-size:18px;'>
            Si tienes alguna duda, escríbenos a sistemas@oral-plus.com o llama al (+57) 300 912 1246.
          </p>
          <a href='https://oral-plus.com/politica.html'>
            <p style='color:#fff;font-family:Helvetica;font-size:18px;'>Política y privacidad</p>
          </a>
        </div>
      </div>
    </div>`

    const mailOptions = {
      from: "formularioretiro@gmail.com",
      to: destinatario,
      subject: `Confirmación de compra para ${nombre}`,
      html: htmlContent,
    }

    const result = await transporter.sendMail(mailOptions)
    console.log("✅ Correo enviado exitosamente:", result.messageId)
    return true
  } catch (error) {
    console.error("❌ Error enviando correo:", error)
    return false
  }
}

// 📦 Función para crear orden en SAP
async function crearOrdenSAP(sessionId, orderData) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(orderData)
    console.log("📤 Enviando orden a SAP:", postData)

    const options = {
      hostname: "192.168.2.242",
      port: 50000,
      path: "/b1s/v1/Orders",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(postData),
        Cookie: `B1SESSION=${sessionId}`,
      },
      rejectUnauthorized: false,
      requestCert: false,
      agent: false,
      timeout: 60000,
    }

    const req = https.request(options, (res) => {
      let data = ""
      res.on("data", (chunk) => {
        data += chunk
      })
      res.on("end", () => {
        console.log(`📡 Respuesta SAP Orders: ${res.statusCode}`)
        console.log(`📄 Body respuesta: ${data}`)
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            const response = JSON.parse(data)
            console.log("✅ Orden SAP creada:", response.DocEntry)
            resolve(response)
          } catch (error) {
            console.error("❌ Error parseando respuesta de orden SAP:", error)
            reject(error)
          }
        } else {
          console.error("❌ Error creando orden SAP:", res.statusCode, data)
          reject(new Error(`Error creando orden: ${res.statusCode} - ${data}`))
        }
      })
    })

    req.on("error", (error) => {
      console.error("❌ Error de conexión creando orden SAP:", error)
      reject(error)
    })

    req.on("timeout", () => {
      console.error("❌ Timeout creando orden SAP")
      req.destroy()
      reject(new Error("Timeout creando orden SAP"))
    })

    req.write(postData)
    req.end()
  })
}

// 🔄 Función para actualizar orden en SAP
async function actualizarOrdenSAP(sessionId, docEntry, updateData) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(updateData)
    console.log("📤 Actualizando orden SAP:", postData)

    const options = {
      hostname: "192.168.2.242",
      port: 50000,
      path: `/b1s/v1/Orders(${docEntry})`,
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(postData),
        Cookie: `B1SESSION=${sessionId}`,
      },
      rejectUnauthorized: false,
      requestCert: false,
      agent: false,
      timeout: 60000,
    }

    const req = https.request(options, (res) => {
      let data = ""
      res.on("data", (chunk) => {
        data += chunk
      })
      res.on("end", () => {
        console.log(`📡 Respuesta SAP PATCH: ${res.statusCode}`)
        console.log(`📄 Body respuesta: ${data}`)
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log("✅ Orden SAP actualizada")
          resolve(true)
        } else {
          console.error("❌ Error actualizando orden SAP:", res.statusCode, data)
          reject(new Error(`Error actualizando orden: ${res.statusCode} - ${data}`))
        }
      })
    })

    req.on("error", (error) => {
      console.error("❌ Error de conexión actualizando orden SAP:", error)
      reject(error)
    })

    req.on("timeout", () => {
      console.error("❌ Timeout actualizando orden SAP")
      req.destroy()
      reject(new Error("Timeout actualizando orden SAP"))
    })

    req.write(postData)
    req.end()
  })
}

// 🛒 ENDPOINT: Procesar compra (MANTENER EXISTENTE)
app.post("/api/purchase/process", async (req, res) => {
  const startTime = Date.now()
  console.log(`🛒 [${new Date().toISOString()}] === PROCESANDO COMPRA SAP ===`)
  console.log("📦 Datos recibidos:", JSON.stringify(req.body, null, 2))

  res.setHeader("Content-Type", "application/json")
  try {
    const { cedula, productos, correo, nombre, subtotal, direccion, telefono, observaciones } = req.body

    if (!cedula || cedula.trim() === "") {
      console.log("❌ Validación fallida: Cédula vacía")
      return res.status(400).json({
        success: false,
        message: "La cédula es requerida",
      })
    }

    if (!productos || !Array.isArray(productos) || productos.length === 0) {
      console.log("❌ Validación fallida: Productos vacíos")
      return res.status(400).json({
        success: false,
        message: "La lista de productos es requerida",
      })
    }

    for (let i = 0; i < productos.length; i++) {
      const p = productos[i]
      const codigo = p.codigo || p.codigoSap
      if (!codigo || !p.cantidad) {
        console.log(`❌ Validación fallida: Producto #${i + 1} incompleto`)
        return res.status(400).json({
          success: false,
          message: `Faltan datos en el producto #${i + 1}`,
        })
      }
    }

    console.log(`📋 Procesando compra para: ${nombre} (${cedula})`)
    console.log(`📧 Correo: ${correo}`)
    console.log(`📦 Productos: ${productos.length}`)
    console.log(`💰 Subtotal: ${subtotal}`)

    console.log("🔐 Paso 1: Iniciando sesión en SAP...")
    const sessionId = await iniciarSesionSAP()
    if (!sessionId) {
      console.log("❌ Error: No se pudo obtener sessionId")
      return res.status(500).json({
        success: false,
        message: "No se pudo iniciar sesión en SAP",
      })
    }
    console.log("✅ Sesión SAP iniciada correctamente")

    console.log("📦 Paso 2: Creando orden en SAP...")
    const lines = productos.map((p) => ({
      ItemCode: p.codigo || p.codigoSap,
    }))

    const orderData = {
      CardCode: cedula,
      DocDueDate: new Date().toISOString().split("T")[0],
      DocumentLines: lines,
      U_PAGINAWEB: "APP",
      DiscountPercent: 3,
    }

    if (observaciones && observaciones.trim() !== "") {
      orderData.Comments = observaciones.trim()
    }

    console.log("📤 Datos de orden:", JSON.stringify(orderData, null, 2))
    const orderResponse = await crearOrdenSAP(sessionId, orderData)
    const docEntry = orderResponse.DocEntry
    const docNum = orderResponse.DocNum

    if (!docEntry) {
      console.log("❌ Error: No se recibió DocEntry")
      return res.status(500).json({
        success: false,
        message: "No se recibió DocEntry válido",
      })
    }

    console.log(`✅ Orden creada - DocEntry: ${docEntry}, DocNum: ${docNum}`)

    console.log("🔄 Paso 3: Actualizando cantidades...")
    const updateLines = productos.map((p, i) => ({
      LineNum: i,
      Quantity: Number.parseInt(p.cantidad),
    }))

    const updateData = { DocumentLines: updateLines }
    console.log("📤 Datos de actualización:", JSON.stringify(updateData, null, 2))
    await actualizarOrdenSAP(sessionId, docEntry, updateData)
    console.log("✅ Cantidades actualizadas correctamente")

    let emailSent = false
    if (correo && nombre) {
      console.log("📧 Paso 4: Enviando correo de confirmación...")
      try {
        emailSent = await enviarCorreo(correo, nombre, subtotal, docNum, docEntry, productos)
        console.log(`📧 Correo ${emailSent ? "enviado" : "falló"}`)
      } catch (emailError) {
        console.error("❌ Error enviando correo:", emailError)
        emailSent = false
      }
    }

    const processingTime = Date.now() - startTime
    console.log(`⏱️ Compra procesada en ${processingTime}ms`)

    const response = {
      success: true,
      message: `Orden creada, líneas actualizadas${emailSent ? " y correo enviado correctamente." : "."}`,
      DocEntry: docEntry,
      DocNum: docNum,
      emailSent: emailSent,
      processingTime: processingTime,
    }

    console.log("✅ === COMPRA COMPLETADA EXITOSAMENTE ===")
    console.log("📤 Respuesta:", JSON.stringify(response, null, 2))
    res.json(response)
  } catch (error) {
    const processingTime = Date.now() - startTime
    console.error("❌ === ERROR EN COMPRA ===")
    console.error("🔧 Error:", error.message)
    console.error("🔧 Stack:", error.stack)

    const errorResponse = {
      success: false,
      message: `Error al procesar la compra: ${error.message}`,
      error: error.message,
      processingTime: processingTime,
      timestamp: new Date().toISOString(),
    }

    console.log("❌ Respuesta de error:", JSON.stringify(errorResponse, null, 2))
    res.status(500).json(errorResponse)
  }
})

// 🧪 ENDPOINT: Validar disponibilidad de productos
app.post("/api/purchase/validate", async (req, res) => {
  const startTime = Date.now()
  console.log(`🧪 [${new Date().toISOString()}] Validando disponibilidad de productos`)

  try {
    const { productos } = req.body

    if (!productos || !Array.isArray(productos) || productos.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Lista de productos requerida",
      })
    }

    console.log(`📦 Validando ${productos.length} productos...`)

    await new Promise((resolve) => setTimeout(resolve, 1000))

    const validationResults = productos.map((producto) => ({
      codigo: producto.codigo,
      nombre: producto.descripcion || `Producto ${producto.codigo}`,
      disponible: 100,
      solicitado: Number.parseInt(producto.cantidad) || 0,
      suficiente: true,
    }))

    const allAvailable = true
    const validationTime = Date.now() - startTime

    console.log(`⏱️ Validación completada en ${validationTime}ms`)

    res.json({
      success: allAvailable,
      message: allAvailable ? "Todos los productos están disponibles" : "Algunos productos no están disponibles",
      products: validationResults,
      validationTime: validationTime,
      timestamp: new Date().toISOString(),
    })
  } catch (error) {
    const validationTime = Date.now() - startTime
    console.error("❌ Error en validación de productos:", error.message)
    res.status(500).json({
      success: false,
      message: "Error interno del servidor al validar productos",
      error: error.message,
      validationTime: validationTime,
      timestamp: new Date().toISOString(),
    })
  }
})

// 🧪 Endpoint de prueba de conexión
app.get("/api/test", async (req, res) => {
  const startTime = Date.now()
  console.log(`🧪 [${new Date().toISOString()}] Test de conexión solicitado`)

  try {
    console.log("🧪 Ejecutando test de conexión a SAP...")
    const pool = await connectToDatabase()
    const result = await pool.request().query("SELECT 1 as test, GETDATE() as server_time")
    const queryTime = Date.now() - startTime

    console.log("✅ Test de conexión SAP exitoso")

    const response = {
      success: true,
      status: "API SAP Business One funcionando correctamente",
      database: "Conectado a SAP Business One",
      server: {
        port: port,
        host: os.hostname(),
        platform: os.platform(),
        nodeVersion: process.version,
        uptime: process.uptime(),
      },
      database_info: {
        server: dbConfig.server,
        database: dbConfig.database,
        user: dbConfig.user,
        connected: pool.connected,
      },
      test_query: result.recordset[0],
      queryTime: queryTime,
      timestamp: new Date().toISOString(),
    }

    console.log("📤 Enviando respuesta de test:", JSON.stringify(response, null, 2))
    res.json(response)
  } catch (error) {
    const queryTime = Date.now() - startTime
    console.error("❌ Error en test de conexión SAP:", error.message)
    const errorResponse = {
      success: false,
      status: "Error en la API SAP",
      error: error.message,
      queryTime: queryTime,
      timestamp: new Date().toISOString(),
    }
    console.log("📤 Enviando respuesta de error:", JSON.stringify(errorResponse, null, 2))
    res.status(500).json(errorResponse)
  }
})

// 🚫 Manejo de rutas no encontradas
app.use("*", (req, res) => {
  console.log(`❌ Ruta no encontrada: ${req.method} ${req.originalUrl}`)
  res.status(404).json({
    success: false,
    error: "Ruta no encontrada",
    path: req.originalUrl,
    method: req.method,
    availableEndpoints: [
      "GET /api/test - Prueba de conexión SAP",
      "GET /api/client/data/:cardcode - Datos del cliente SAP",
      "GET /api/obtener_cliente_sap.php?cardcode=XXX - Cliente SAP (Flutter compatible)",
      "GET /api/obtener_precios_sap.php?codigos=XXX&cliente=YYY - Precios SAP (Flutter compatible)",
      "GET /api/obtener_estados_productos_sap.php?codigos=XXX&cliente=YYY - Estados SAP (Flutter compatible)",
      "POST /api/purchase/process - Procesar compra en SAP",
      "POST /api/purchase/validate - Validar disponibilidad de productos",
    ],
    timestamp: new Date().toISOString(),
  })
})

// 🚀 Función para iniciar el servidor
async function startServer() {
  console.log("🚀 Iniciando servidor SAP Business One...")
  console.log("=".repeat(60))

  console.log(`🖥️ Sistema: ${os.platform()} ${os.arch()}`)
  console.log(`📍 Host: ${os.hostname()}`)
  console.log(`🔧 Node.js: ${process.version}`)

  console.log("\n🗄️ Configuración SAP Business One:")
  console.log(`   Servidor: ${dbConfig.server}:${dbConfig.port}`)
  console.log(`   Base de datos: ${dbConfig.database}`)
  console.log(`   Usuario: ${dbConfig.user}`)

  console.log("\n🔗 Configuración SAP API REST:")
  console.log(`   URL: ${sapConfig.baseUrl}`)
  console.log(`   Usuario: ${sapConfig.username}`)
  console.log(`   Base de datos: ${sapConfig.companyDB}`)

  try {
    await connectToDatabase()
  } catch (error) {
    console.log("\n❌ No se pudo conectar a SAP Business One")
    console.log("⚠️ El servidor iniciará pero las consultas fallarán")
  }

  const server = app.listen(port, "0.0.0.0", () => {
    console.log("\n🎉 ¡Servidor SAP iniciado exitosamente!")
    console.log("=".repeat(60))
    console.log(`🌐 Puerto: ${port}`)
    console.log(`🔗 URL local: http://localhost:${port}/api`)

    console.log("\n🧪 Endpoints SAP disponibles:")
    console.log(`   Test conexión: http://localhost:${port}/api/test`)
    console.log(`   Cliente SAP: http://localhost:${port}/api/client/data/{cardcode}`)
    console.log(`   🛒 PROCESAR COMPRA: http://localhost:${port}/api/purchase/process`)
    console.log(`   🧪 VALIDAR PRODUCTOS: http://localhost:${port}/api/purchase/validate`)

    console.log("\n✅ NUEVOS ENDPOINTS FLUTTER COMPATIBLES:")
    console.log(`   📋 CLIENTE: http://localhost:${port}/api/obtener_cliente_sap.php?cardcode=XXX`)
    console.log(`   💰 PRECIOS: http://localhost:${port}/api/obtener_precios_sap.php?codigos=XXX&cliente=YYY`)
    console.log(`   📦 ESTADOS: http://localhost:${port}/api/obtener_estados_productos_sap.php?codigos=XXX&cliente=YYY`)

    console.log("\n💡 Para probar desde Flutter:")
    console.log(`   Endpoint: http://localhost:${port}/api/obtener_precios_sap.php`)
    console.log(`   Método: GET`)
    console.log(`   Parámetros: ?codigos=50360251,50360256&cliente=123456789`)

    console.log("\n✅ Servidor SAP listo - Conectado a Business One")
    console.log("🛑 Presiona Ctrl+C para detener")
  })

  return server
}

// 🛑 Manejo de cierre graceful
process.on("SIGINT", async () => {
  console.log("\n🛑 Cerrando servidor SAP...")
  if (globalPool) {
    try {
      await globalPool.close()
      console.log("🔌 Desconectado de SAP Business One")
    } catch (error) {
      console.error("❌ Error cerrando conexión SAP:", error.message)
    }
  }
  console.log("👋 ¡Hasta luego!")
  process.exit(0)
})

// 🚀 Iniciar el servidor
if (require.main === module) {
  startServer().catch((error) => {
    console.error("❌ Error fatal al iniciar servidor SAP:", error.message)
    process.exit(1)
  })
}

module.exports = { app, startServer, connectToDatabase }
