package com.rivalfit.rivalfit

import android.app.Activity
import android.app.AlertDialog
import android.os.Bundle

class StepsPrivacyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AlertDialog.Builder(this)
            .setTitle("Privacidad de tus pasos")
            .setMessage(
                "RivalFit lee el total de pasos de hoy de Health Connect para mostrarlo " +
                    "en Entrenar. El total se consulta en tu teléfono y no se envía a un servidor " +
                    "ni se usa para el ranking. Puedes retirar el permiso en Health Connect.",
            )
            .setPositiveButton("Cerrar") { _, _ -> finish() }
            .setOnCancelListener { finish() }
            .show()
    }
}
