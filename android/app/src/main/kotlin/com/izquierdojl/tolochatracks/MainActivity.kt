package com.izquierdojl.tolochatracks

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val canal = "com.izquierdojl.tolochatracks/exportacion"
    private val codigoArbol = 4101
    private var resultadoPendiente: MethodChannel.Result? = null
    private val ejecutor = Executors.newSingleThreadExecutor()
    private val principal = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canal).setMethodCallHandler { llamada, resultado ->
            when (llamada.method) {
                "elegirDirectorio" -> elegirDirectorio(resultado)
                "estadoDirectorio" -> resultado.success(estadoDirectorio(llamada.argument<String>("uri")))
                "exportar" -> exportar(llamada, resultado)
                else -> resultado.notImplemented()
            }
        }
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
            resultado.success(mapOf("exportados" to 0, "errores" to emptyList<String>()))
            return
        }
        ejecutor.execute {
            val errores = mutableListOf<String>()
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
                    } catch (e: Exception) {
                        errores.add("$nombre: ${e.message ?: "error desconocido"}")
                    }
                }
                principal.post {
                    resultado.success(mapOf("exportados" to exportados, "errores" to errores))
                }
            } catch (e: Exception) {
                principal.post {
                    resultado.error("exportacion", e.message ?: "No se pudo exportar.", null)
                }
            }
        }
    }

    override fun onDestroy() {
        ejecutor.shutdown()
        super.onDestroy()
    }
}
