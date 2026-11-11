package com.flipbook.draw.animation

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Protect budget MediaTek devices with PowerVR GPUs from native libGLESv2_mtk.so / IMGeglMakeCurrent driver crashes
        val affectedChipsets = listOf("mt6762", "mt6765", "mt6761", "mt8768", "mt6763", "mt6769")
        val hardware = Build.HARDWARE.lowercase()
        val board = Build.BOARD.lowercase()
        val soc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Build.SOC_MODEL.lowercase()
        } else {
            ""
        }

        val isBuggyMtkDriver = affectedChipsets.any {
            hardware.contains(it) || board.contains(it) || soc.contains(it)
        }

        if (isBuggyMtkDriver) {
            // Enable software rendering on affected MediaTek PowerVR chipsets to bypass vendor driver SIGSEGV
            intent.putExtra("enable-software-rendering", true)
        }

        super.onCreate(savedInstanceState)
    }
}
