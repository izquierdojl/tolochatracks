package com.izquierdojl.tolochatracks

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class RutaForegroundService : Service() {
    companion object {
        const val CANAL_ID = "grabacion_ruta"
        const val NOTIFICACION_ID = 4201
        const val ACCION_INICIAR = "com.izquierdojl.tolochatracks.ruta.INICIAR"
        const val ACCION_ACTUALIZAR = "com.izquierdojl.tolochatracks.ruta.ACTUALIZAR"
        const val ACCION_PAUSAR = "com.izquierdojl.tolochatracks.ruta.PAUSAR"
        const val ACCION_REANUDAR = "com.izquierdojl.tolochatracks.ruta.REANUDAR"
        const val ACCION_DETENER = "com.izquierdojl.tolochatracks.ruta.DETENER"
        const val EXTRA_PAUSADO = "pausado"
    }

    private var pausado = false
    private var guardando = false
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        crearCanal()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACCION_INICIAR -> {
                pausado = false
                guardando = false
                iniciarPrimerPlano()
            }
            ACCION_ACTUALIZAR -> {
                pausado = intent.getBooleanExtra(EXTRA_PAUSADO, false)
                guardando = false
                actualizarNotificacion()
            }
            ACCION_PAUSAR -> {
                pausado = true
                actualizarNotificacion()
                enviarAccion("pausar")
            }
            ACCION_REANUDAR -> {
                pausado = false
                actualizarNotificacion()
                enviarAccion("reanudar")
            }
            ACCION_DETENER -> {
                guardando = true
                actualizarNotificacion("Guardando la ruta…")
                enviarAccion("detener")
            }
            else -> iniciarPrimerPlano()
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun iniciarPrimerPlano() {
        adquirirWakeLock()
        val notificacion = construirNotificacion()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICACION_ID,
                notificacion,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION,
            )
        } else {
            startForeground(NOTIFICACION_ID, notificacion)
        }
    }

    private fun actualizarNotificacion(texto: String? = null) {
        val gestor = getSystemService(NotificationManager::class.java)
        gestor.notify(NOTIFICACION_ID, construirNotificacion(texto))
    }

    private fun construirNotificacion(texto: String? = null): Notification {
        val abrirApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val titulo = when {
            guardando -> "TolochaTracks · Guardando"
            pausado -> "TolochaTracks · En pausa"
            else -> "TolochaTracks · Grabando"
        }
        val cuerpo = texto ?: when {
            guardando -> "Guardando la ruta en el dispositivo"
            pausado -> "La ruta está en pausa. Toca Reanudar para continuar."
            else -> "Registrando tu ruta en segundo plano"
        }
        val builder = NotificationCompat.Builder(this, CANAL_ID)
            .setSmallIcon(R.drawable.ic_stat_tolochatracks)
            .setContentTitle(titulo)
            .setContentText(cuerpo)
            .setContentIntent(abrirApp)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        if (!guardando) {
            if (pausado) {
                builder.addAction(
                    R.drawable.ic_stat_play,
                    "Reanudar",
                    accion(ACCION_REANUDAR, 2),
                )
            } else {
                builder.addAction(
                    R.drawable.ic_stat_pause,
                    "Pausar",
                    accion(ACCION_PAUSAR, 1),
                )
            }
            builder.addAction(
                R.drawable.ic_stat_stop,
                "Finalizar",
                accion(ACCION_DETENER, 3),
            )
        }
        return builder.build()
    }

    private fun accion(accion: String, codigo: Int): PendingIntent = PendingIntent.getService(
        this,
        codigo,
        Intent(this, RutaForegroundService::class.java).setAction(accion),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun enviarAccion(accion: String) {
        Handler(Looper.getMainLooper()).post {
            CanalRuta.canal?.invokeMethod("accion", accion)
        }
    }

    private fun adquirirWakeLock() {
        if (wakeLock?.isHeld == true) return
        wakeLock = getSystemService(PowerManager::class.java)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "TolochaTracks:grabacion")
            .apply {
                setReferenceCounted(false)
                acquire(12 * 60 * 60 * 1000L)
            }
    }

    private fun crearCanal() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val canal = NotificationChannel(
            CANAL_ID,
            "Grabación de rutas",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Notificación del servicio de grabación GPS"
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
    }

    override fun onDestroy() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }
}
