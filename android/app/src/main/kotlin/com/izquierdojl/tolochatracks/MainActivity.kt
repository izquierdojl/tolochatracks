package com.izquierdojl.tolochatracks

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val canal = "com.izquierdojl.tolochatracks/exportacion"
    private val canalCompartir = "com.izquierdojl.tolochatracks/compartir"
    private val canalPermisos = "com.izquierdojl.tolochatracks/permisos"
    private val canalRuta = "com.izquierdojl.tolochatracks/ruta"
    private val canalBateria = "com.izquierdojl.tolochatracks/bateria"
    private val codigoArbol = 4101
    private val codigoNotificaciones = 4102
    private var resultadoPendiente: MethodChannel.Result? = null
    private var resultadoNotificaciones: MethodChannel.Result? = null
    private val ejecutor = Executors.newSingleThreadExecutor()
    private val principal = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canal).setMethodCallHandler { llamada, resultado ->
            when (llamada.method) {
                "elegirDirectorio" -> elegirDirectorio(resultado)
                "estadoDirectorio" -> resultado.success(estadoDirectorio(llamada.argument<String>("uri")))
                "exportar" -> exportar(llamada, resultado)
                "borrar" -> borrar(llamada, resultado)
                else -> resultado.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canalCompartir).setMethodCallHandler { llamada, resultado ->
            when (llamada.method) {
                "compartirArchivo" -> compartirArchivo(llamada, resultado)
                else -> resultado.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canalPermisos).setMethodCallHandler { llamada, resultado ->
            when (llamada.method) {
                "pedirNotificaciones" -> pedirNotificaciones(resultado)
                else -> resultado.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canalBateria).setMethodCallHandler { llamada, resultado ->
            when (llamada.method) {
                "estadoBateria" -> {
                    val gestor = getSystemService(PowerManager::class.java)
                    resultado.success(gestor.isIgnoringBatteryOptimizations(packageName))
                }
                "pedirExencionBateria" -> {
                    pedirExencionBateria()
                    resultado.success(true)
                }
                else -> resultado.notImplemented()
            }
        }
        val canalServicio = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canalRuta)
        CanalRuta.canal = canalServicio
        canalServicio.setMethodCallHandler { llamada, resultado ->
            try {
                when (llamada.method) {
                    "iniciar" -> {
                        iniciarServicioRuta(RutaForegroundService.ACCION_INICIAR)
                        resultado.success(true)
                    }
                    "actualizar" -> {
                        val pausado = llamada.argument<Boolean>("pausado") ?: false
                        iniciarServicioRuta(RutaForegroundService.ACCION_ACTUALIZAR, pausado)
                        resultado.success(true)
                    }
                    "detener" -> {
                        stopService(Intent(this, RutaForegroundService::class.java))
                        resultado.success(true)
                    }
                    else -> resultado.notImplemented()
                }
            } catch (e: Exception) {
                resultado.error("servicio_ruta", e.message, null)
            }
        }
    }

    private fun pedirExencionBateria() {
        try {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:$packageName")
                )
            )
        } catch (_: Exception) {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        }
    }

    private fun iniciarServicioRuta(accion: String, pausado: Boolean = false) {
        val intent = Intent(this, RutaForegroundService::class.java).apply {
            this.action = accion
            putExtra(RutaForegroundService.EXTRA_PAUSADO, pausado)
        }
        if (accion == RutaForegroundService.ACCION_ACTUALIZAR) {
            startService(intent)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun pedirNotificaciones(resultado: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        ) {
            resultado.success(true)
            return
        }
        if (resultadoNotificaciones != null) {
            resultado.success(true)
            return
        }
        resultadoNotificaciones = resultado
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), codigoNotificaciones)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != codigoNotificaciones) return
        val concedido = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        resultadoNotificaciones?.success(concedido)
        resultadoNotificaciones = null
    }

    private fun elegirDirectorio(resultado: MethodChannel.Result) {
        if (resultadoPendiente != null) {
            resultado.error("en_curso", "Ya hay un selector de directorio abierto.", null)
            return
        }
        resultadoPendiente = resultado
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
            )
        }
        try {
            startActivityForResult(intent, codigoArbol)
        } catch (e: Exception) {
            resultadoPendiente = null
            resultado.error("selector", "No se pudo abrir el selector de carpetas.", e.message)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != codigoArbol) return
        val resultado = resultadoPendiente ?: return
        resultadoPendiente = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            resultado.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        } catch (_: SecurityException) {
        }
        val nombre = DocumentFile.fromTreeUri(this, uri)?.name ?: uri.lastPathSegment ?: "Carpeta"
        resultado.success(mapOf("uri" to uri.toString(), "nombre" to nombre))
    }

    private fun estadoDirectorio(uriTexto: String?): Map<String, Any?> {
        if (uriTexto.isNullOrBlank()) {
            return mapOf("configurado" to false, "nombre" to null)
        }
        val uri = Uri.parse(uriTexto)
        val permiso = contentResolver.persistedUriPermissions.firstOrNull {
            it.uri == uri && it.isWritePermission
        }
        val documento = DocumentFile.fromTreeUri(this, uri)
        return mapOf(
            "configurado" to (permiso != null),
            "nombre" to (documento?.name ?: uri.lastPathSegment)
        )
    }

    private fun exportar(llamada: MethodCall, resultado: MethodChannel.Result) {
        val uriTexto = llamada.argument<String>("uri")
        val archivos = llamada.argument<List<Map<String, String>>>("archivos") ?: emptyList()
        if (uriTexto.isNullOrBlank()) {
            resultado.error("sin_directorio", "No hay un directorio de exportación configurado.", null)
            return
        }
        if (archivos.isEmpty()) {
            resultado.success(
                mapOf(
                    "exportados" to 0,
                    "errores" to emptyList<String>(),
                    "nombres" to emptyList<String>()
                )
            )
            return
        }
        ejecutor.execute {
            val errores = mutableListOf<String>()
            val nombres = mutableListOf<String>()
            var exportados = 0
            try {
                val uri = Uri.parse(uriTexto)
                val arbol = DocumentFile.fromTreeUri(this, uri)
                if (arbol == null || !arbol.canWrite()) {
                    principal.post {
                        resultado.error(
                            "sin_permiso",
                            "La carpeta ya no es accesible. Vuelve a elegirla en Ajustes.",
                            null
                        )
                    }
                    return@execute
                }
                for (archivo in archivos) {
                    val nombre = archivo["nombre"] ?: continue
                    val contenido = archivo["contenido"] ?: ""
                    val mime = archivo["mime"] ?: "application/octet-stream"
                    try {
                        arbol.findFile(nombre)?.delete()
                        val destino = arbol.createFile(mime, nombre)
                            ?: throw IllegalStateException("No se pudo crear el archivo")
                        contentResolver.openOutputStream(destino.uri, "wt")?.use { salida ->
                            salida.write(contenido.toByteArray(Charsets.UTF_8))
                        } ?: throw IllegalStateException("No se pudo abrir el archivo")
                        exportados += 1
                        nombres.add(nombre)
                    } catch (e: Exception) {
                        errores.add("$nombre: ${e.message ?: "error desconocido"}")
                    }
                }
                principal.post {
                    resultado.success(
                        mapOf(
                            "exportados" to exportados,
                            "errores" to errores,
                            "nombres" to nombres
                        )
                    )
                }
            } catch (e: Exception) {
                principal.post {
                    resultado.error("exportacion", e.message ?: "No se pudo exportar.", null)
                }
            }
        }
    }

    private fun borrar(llamada: MethodCall, resultado: MethodChannel.Result) {
        val uriTexto = llamada.argument<String>("uri")
        val nombres = llamada.argument<List<String>>("nombres") ?: emptyList()
        if (uriTexto.isNullOrBlank()) {
            resultado.error("sin_directorio", "No hay un directorio de exportación configurado.", null)
            return
        }
        if (nombres.isEmpty()) {
            resultado.success(
                mapOf(
                    "borrados" to 0,
                    "noEncontrados" to 0,
                    "errores" to emptyList<String>()
                )
            )
            return
        }
        ejecutor.execute {
            val errores = mutableListOf<String>()
            var borrados = 0
            var noEncontrados = 0
            try {
                val uri = Uri.parse(uriTexto)
                val arbol = DocumentFile.fromTreeUri(this, uri)
                if (arbol == null || !arbol.canWrite()) {
                    principal.post {
                        resultado.error(
                            "sin_permiso",
                            "La carpeta ya no es accesible. Vuelve a elegirla en Ajustes.",
                            null
                        )
                    }
                    return@execute
                }
                for (nombre in nombres) {
                    try {
                        val documento = arbol.findFile(nombre)
                        if (documento == null) {
                            noEncontrados += 1
                        } else if (documento.delete()) {
                            borrados += 1
                        } else {
                            errores.add("$nombre: no se pudo borrar")
                        }
                    } catch (e: Exception) {
                        errores.add("$nombre: ${e.message ?: "error desconocido"}")
                    }
                }
                principal.post {
                    resultado.success(
                        mapOf(
                            "borrados" to borrados,
                            "noEncontrados" to noEncontrados,
                            "errores" to errores
                        )
                    )
                }
            } catch (e: Exception) {
                principal.post {
                    resultado.error(
                        "borrado",
                        e.message ?: "No se pudieron borrar los archivos exportados.",
                        null
                    )
                }
            }
        }
    }

    private fun compartirArchivo(llamada: MethodCall, resultado: MethodChannel.Result) {
        val ruta = llamada.argument<String>("ruta")
        if (ruta.isNullOrBlank()) {
            resultado.error("sin_archivo", "No se indicó el archivo a compartir.", null)
            return
        }
        val archivo = File(ruta)
        if (!archivo.exists()) {
            resultado.error("sin_archivo", "El archivo a compartir no existe.", null)
            return
        }
        try {
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", archivo)
            val mime = llamada.argument<String>("mime") ?: "application/gpx+xml"
            val asunto = llamada.argument<String>("asunto") ?: "Ruta TolochaTracks"
            val intencion = Intent(Intent.ACTION_SEND).apply {
                type = mime
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, asunto)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intencion, "Compartir ruta"))
            resultado.success(true)
        } catch (e: Exception) {
            resultado.error(
                "compartir",
                e.message ?: "No se pudo abrir el selector para compartir.",
                null
            )
        }
    }

    override fun onDestroy() {
        ejecutor.shutdown()
        super.onDestroy()
    }
}
