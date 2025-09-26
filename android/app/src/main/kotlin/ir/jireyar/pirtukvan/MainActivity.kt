package ir.jireyar.pirtukvan

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pirtukvan/opened_file"
    private var methodChannel: MethodChannel? = null
    private var pendingPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            // Platform can expose methods to Flutter in future; currently none implemented.
            result.notImplemented()
        }
        // If an intent arrived earlier than channel setup, deliver it now
        pendingPath?.let {
            try {
                methodChannel?.invokeMethod("onFileOpened", it)
            } catch (_: Exception) {
            }
            pendingPath = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action == Intent.ACTION_VIEW) {
            val data: Uri? = intent.data
            if (data != null) {
                // Copy content:// URIs into cache and then send path to Flutter via MethodChannel
                val path = copyUriToCache(data)
                if (path != null) {
                    try {
                        if (methodChannel != null) {
                            methodChannel?.invokeMethod("onFileOpened", path)
                        } else {
                            // channel not yet ready, buffer the path
                            pendingPath = path
                        }
                    } catch (e: Exception) {
                        // ignore
                    }
                }
            }
        }
    }

    private fun copyUriToCache(uri: Uri): String? {
        try {
            val input = contentResolver.openInputStream(uri) ?: return null
            val fileName = queryFileName(uri) ?: "shared_file"
            val outFile = File(cacheDir, fileName)
            val out = FileOutputStream(outFile)
            input.use { inputStream ->
                out.use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            return outFile.absolutePath
        } catch (e: Exception) {
            return null
        }
    }

    private fun queryFileName(uri: Uri): String? {
        // Try to get last path segment as a fallback
        return uri.lastPathSegment
    }
}
