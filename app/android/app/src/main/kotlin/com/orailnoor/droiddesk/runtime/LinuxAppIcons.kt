package com.orailnoor.droiddesk.runtime

import android.content.Context
import android.util.Log
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * Finds a real icon for a Linux package.
 *
 * Installed packages use the icon named by their own .desktop entry. Anything else falls back
 * to the Papirus icon theme (fetched once from jsDelivr and cached), which covers most Linux GUI
 * apps by name. Command-line tools usually have neither and return null.
 */
object LinuxAppIcons {
    private const val TAG = "LinuxAppIcons"
    private const val PAPIRUS_URL =
        "https://cdn.jsdelivr.net/gh/PapirusDevelopmentTeam/papirus-icon-theme@20260801/Papirus/64x64/apps/"
    private const val MISS_TTL_MS = 7L * 24 * 60 * 60 * 1000
    private val SAFE_NAME = Regex("[A-Za-z0-9._+-]{1,128}")

    /** Returns `{"format": "png"|"svg", "bytes": ByteArray}` or null when no icon is known. */
    fun find(
        context: Context,
        prefixDir: File?,
        packageName: String,
        iconNames: List<String>,
    ): Map<String, Any>? {
        if (!SAFE_NAME.matches(packageName)) return null
        exportedContainerIcon(context, packageName)?.let { return it }
        val localIconNames = prefixDir?.let { desktopIconNames(it, packageName) }.orEmpty()
        for (name in localIconNames) {
            prefixDir?.let { localIcon(it, name) }?.let { return it }
        }
        containerIcon(context, packageName)?.let { return it }
        val candidates = (iconNames + localIconNames + packageName)
            .filter { SAFE_NAME.matches(it) }
            .distinct()
        for (name in candidates) {
            papirusIcon(context, name)?.let { return it }
        }
        return null
    }

    /**
     * Icon exported by scripts/ubuntu-menu-sync.sh into the shared launcher
     * directory, keyed by desktop-file id. XPM exports are skipped because the
     * Flutter side only renders PNG/SVG (placeholder covers the rest).
     */
    private fun exportedContainerIcon(context: Context, desktopId: String): Map<String, Any>? {
        val iconsDir = File(context.filesDir, "home/.local/share/ubuntutab/apps/icons")
        for (ext in listOf("png", "svg")) {
            iconFromFile(File(iconsDir, "$desktopId.$ext"), ext)?.let { return it }
        }
        return null
    }

    /**
     * Resolves the Icon= key of a proot Ubuntu container .desktop entry against
     * the container's own icon theme tree (ROOTFS path mirrors
     * scripts/ubuntu-menu-sync.sh: $PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu-24.04).
     */
    private fun containerIcon(context: Context, desktopId: String): Map<String, Any>? {
        val rootfs = File(context.filesDir, "usr/var/lib/proot-distro/installed-rootfs/ubuntu-24.04")
        if (!rootfs.isDirectory) return null
        val desktopFile = listOf(
            File(rootfs, "usr/share/applications/$desktopId.desktop"),
            File(rootfs, "root/.local/share/applications/$desktopId.desktop"),
        ).firstOrNull(File::isFile) ?: return null
        val iconName = runCatching {
            desktopFile.useLines { lines ->
                lines.firstOrNull { it.startsWith("Icon=") }?.removePrefix("Icon=")?.trim()
            }
        }.getOrNull()?.takeIf { it.isNotEmpty() } ?: return null

        val candidates = buildList {
            if (iconName.startsWith("/")) {
                add(File(rootfs, iconName.removePrefix("/")))
            } else if (SAFE_NAME.matches(iconName)) {
                val iconsRoot = File(rootfs, "usr/share/icons")
                val themes = iconsRoot.listFiles()?.map { it.name }?.sorted().orEmpty()
                for (size in listOf("512x512", "256x256", "128x128", "96x96", "64x64", "48x48", "32x32")) {
                    for (theme in themes) add(File(iconsRoot, "$theme/$size/apps/$iconName.png"))
                }
                for (size in listOf("scalable", "256x256", "128x128", "48x48")) {
                    for (theme in themes) add(File(iconsRoot, "$theme/$size/apps/$iconName.svg"))
                }
                add(File(rootfs, "usr/share/pixmaps/$iconName.png"))
                add(File(rootfs, "usr/share/pixmaps/$iconName.svg"))
            }
        }
        for (file in candidates) {
            // XPM and extension-less files are not renderable on the Flutter side.
            val ext = file.extension.lowercase()
            if (ext != "png" && ext != "svg") continue
            iconFromFile(file, if (ext == "svg") "svg" else "png")?.let { return it }
        }
        return null
    }

    private fun iconFromFile(file: File, format: String): Map<String, Any>? {
        if (!file.isFile || file.length() !in 1..2_000_000) return null
        return runCatching { mapOf("format" to format, "bytes" to file.readBytes()) }.getOrNull()
    }

    /** Icon names from the package's installed .desktop files, via dpkg's file list. */
    private fun desktopIconNames(prefixDir: File, packageName: String): List<String> {
        val infoDir = File(prefixDir, "var/lib/dpkg/info")
        val listFile = listOf("$packageName.list", "$packageName:aarch64.list")
            .map { File(infoDir, it) }
            .firstOrNull { it.isFile } ?: return emptyList()
        return runCatching {
            listFile.readLines()
                .filter { it.contains("/share/applications/") && it.endsWith(".desktop") }
                .mapNotNull { path -> relocate(prefixDir, path) }
                .filter { it.isFile }
                .mapNotNull { desktop ->
                    desktop.readLines()
                        .firstOrNull { it.startsWith("Icon=") }
                        ?.removePrefix("Icon=")
                        ?.trim()
                        ?.takeIf { it.isNotEmpty() }
                }
                .distinct()
        }.getOrDefault(emptyList())
    }

    /** dpkg lists Termux's original /data/data/com.termux/files/usr paths; map them onto our prefix. */
    private fun relocate(prefixDir: File, path: String): File? {
        val index = path.indexOf("/usr/")
        return if (index < 0) null else File(prefixDir, path.substring(index + "/usr/".length))
    }

    private fun localIcon(prefixDir: File, iconName: String): Map<String, Any>? {
        val direct = if (iconName.startsWith("/")) relocate(prefixDir, iconName) ?: File(iconName) else null
        val candidates = buildList {
            direct?.let(::add)
            if (SAFE_NAME.matches(iconName)) {
                val themes = listOf("hicolor", "Papirus", "Adwaita")
                val sizes = listOf("256x256", "128x128", "96x96", "64x64", "48x48", "scalable")
                for (theme in themes) for (size in sizes) for (ext in listOf("png", "svg")) {
                    add(File(prefixDir, "share/icons/$theme/$size/apps/$iconName.$ext"))
                }
                add(File(prefixDir, "share/pixmaps/$iconName.png"))
                add(File(prefixDir, "share/pixmaps/$iconName.svg"))
            }
        }
        val file = candidates.firstOrNull { it.isFile && it.length() in 1..2_000_000 } ?: return null
        val format = if (file.extension.equals("svg", ignoreCase = true)) "svg" else "png"
        return runCatching { mapOf("format" to format, "bytes" to file.readBytes()) }.getOrNull()
    }

    private fun papirusIcon(context: Context, iconName: String): Map<String, Any>? {
        val cacheDir = File(context.cacheDir, "linux-icons").apply { mkdirs() }
        val cached = File(cacheDir, "$iconName.svg")
        val miss = File(cacheDir, "$iconName.miss")
        if (cached.isFile && cached.length() > 0) {
            return mapOf("format" to "svg", "bytes" to cached.readBytes())
        }
        if (miss.isFile && System.currentTimeMillis() - miss.lastModified() < MISS_TTL_MS) return null

        var notFound = false
        val bytes = runCatching {
            val connection = URL("$PAPIRUS_URL$iconName.svg").openConnection() as HttpURLConnection
            connection.connectTimeout = 6_000
            connection.readTimeout = 8_000
            try {
                when (connection.responseCode) {
                    200 -> connection.inputStream.use { it.readBytes() }
                    404 -> null.also { notFound = true }
                    else -> null
                }
            } finally {
                connection.disconnect()
            }
        }.onFailure { Log.d(TAG, "Papirus fetch failed for $iconName: ${it.message}") }
            .getOrNull()

        val isSvg = bytes != null && bytes.size < 500_000 &&
            String(bytes, 0, minOf(bytes.size, 200)).contains("<svg")
        if (!isSvg) {
            // Remember real misses only; network errors retry next time.
            if (notFound) miss.writeText("")
            return null
        }
        cached.writeBytes(bytes!!)
        return mapOf("format" to "svg", "bytes" to bytes)
    }
}
