import SwiftUI
import Combine

// MARK: - Models

struct DeepCleanItem: Identifiable, @unchecked Sendable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let category: DeepCleanCategory
    var isSelected: Bool = true
    
    // New metadata for Apps
    var appIcon: NSImage? = nil
    var bundleId: String? = nil
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - App Info Helper Structure
struct InstalledAppInfo {
    let name: String
    let bundleId: String
    let url: URL
    let icon: NSImage
}

enum DeepCleanCategory: String, CaseIterable, Sendable {
    case largeFiles = "Large Files"
    case junkFiles = "System Junk"
    case systemLogs = "Log Files"
    case systemCaches = "Cache Files"
    case appResiduals = "App Residue"
    
    var localizedName: String {
        switch self {
        case .largeFiles: return LocalizationManager.shared.currentLanguage == .chinese ? "大文件" : "Large Files"
        case .junkFiles: return LocalizationManager.shared.currentLanguage == .chinese ? "系统垃圾" : "System Junk"
        case .systemLogs: return LocalizationManager.shared.currentLanguage == .chinese ? "日志文件" : "Log Files"
        case .systemCaches: return LocalizationManager.shared.currentLanguage == .chinese ? "缓存文件" : "Cache Files"
        case .appResiduals: return LocalizationManager.shared.currentLanguage == .chinese ? "应用残留" : "App Residue"
        }
    }
    
    var icon: String {
        switch self {
        case .largeFiles: return "arrow.down.doc.fill"
        case .junkFiles: return "trash.fill"
        case .systemLogs: return "doc.text.fill"
        case .systemCaches: return "externaldrive.fill"
        case .appResiduals: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .largeFiles: return .purple
        case .junkFiles: return .red
        case .systemLogs: return .gray
        case .systemCaches: return .blue
        case .appResiduals: return .orange
        }
    }
}

// MARK: - Scanner

class DeepCleanScanner: ObservableObject {
    @Published var items: [DeepCleanItem] = []
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var scanProgress: Double = 0.0
    @Published var scanStatus: String = ""
    @Published var currentScanningUrl: String = ""
    @Published var completedCategories: Set<DeepCleanCategory> = []
    
    // 统计数据
    @Published var totalSize: Int64 = 0
    @Published var cleanedSize: Int64 = 0
    @Published var cleaningProgress: Double = 0.0
    @Published var currentCleaningItem: String = ""
    
    // 清理状态跟踪
    @Published var cleaningCurrentCategory: DeepCleanCategory? = nil
    @Published var cleanedCategories: Set<DeepCleanCategory> = []
    @Published var cleaningDescription: String = ""
    
    // 选中的大小
    var selectedSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var selectedCount: Int {
        items.filter { $0.isSelected }.count
    }
    
    // Progress smoothing
    private var currentTaskProgressRange: (start: Double, end: Double) = (0, 0)
    private var scannedItemsCount: Int = 0
    private let progressSmoothingFactor: Double = 1000.0 // Items to reach 50% of range
    
    private let fileManager = FileManager.default
    private var scanTask: Task<Void, Never>?
    
    // 系统保护 - 绝对不删
    private let protectedPaths: Set<String> = [
        "/System",
        "/bin",
        "/sbin",
        "/usr",
        "/var/root"
    ]
    
    // MARK: - API
    
    @Published var currentCategory: DeepCleanCategory = .largeFiles // Default, updates during scan
    
    // MARK: - API
    
    func startScan() async {
        await MainActor.run {
            self.reset()
            self.isScanning = true
            self.scanStatus = LocalizationManager.shared.currentLanguage == .chinese ? "准备扫描..." : "Preparing..."
            self.scanProgress = 0.0
        }
        
        let categoriesToScan: [DeepCleanCategory] = [.junkFiles, .systemLogs, .systemCaches, .appResiduals, .largeFiles]
        let totalCategories = Double(categoriesToScan.count)
        
        for (index, category) in categoriesToScan.enumerated() {
            // Update Current Category
            await MainActor.run {
                self.currentCategory = category
                self.scanStatus = self.statusText(for: category)
                
                // Define range for this task
                let start = Double(index) / totalCategories
                let end = Double(index + 1) / totalCategories
                self.currentTaskProgressRange = (start, end)
                self.scannedItemsCount = 0
                self.scanProgress = start
            }
            
            // Perform Scan
            let newItems: [DeepCleanItem]
            switch category {
            case .largeFiles: newItems = await scanLargeFiles()
            case .junkFiles: newItems = await scanJunk()
            case .systemLogs: newItems = await scanLogs()
            case .systemCaches: newItems = await scanCaches()
            case .appResiduals: newItems = await scanResiduals()
            }
            
            // Update Results
             await MainActor.run {
                self.items.append(contentsOf: newItems)
                self.totalSize += newItems.reduce(0) { $0 + $1.size }
                self.completedCategories.insert(category)
                self.items.sort { $0.size > $1.size } // Keep sorted
                
                // Animate Progress (Complete this step)
                withAnimation(.linear(duration: 0.3)) {
                    self.scanProgress = Double(index + 1) / totalCategories
                }
            }
            
            // Small delay for visual pacing (optional, feels more "pro")
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        }
        
        await MainActor.run {
            self.isScanning = false
            self.scanStatus = LocalizationManager.shared.currentLanguage == .chinese ? "扫描完成" : "Scan Complete"
            self.scanProgress = 1.0
        }
    }
    
    private func statusText(for category: DeepCleanCategory) -> String {
        let isChinese = LocalizationManager.shared.currentLanguage == .chinese
        switch category {
        case .largeFiles: return isChinese ? "正在扫描大文件..." : "Scanning Large Files..."
        case .junkFiles: return isChinese ? "正在扫描系统垃圾..." : "Scanning System Junk..."
        case .systemLogs: return isChinese ? "正在扫描日志..." : "Scanning Logs..."
        case .systemCaches: return isChinese ? "正在扫描缓存..." : "Scanning Caches..."
        case .appResiduals: return isChinese ? "正在扫描应用残留..." : "Scanning App Residue..."
        }
    }
    
    // Throttled UI Update Helper
    private var lastUpdateTime: Date = Date()
    
    func updateScanningUrl(_ url: String) {
        let now = Date()
        guard now.timeIntervalSince(lastUpdateTime) > 0.05 else { return } // Update every 50ms max
        lastUpdateTime = now
        
        Task { @MainActor in
            self.currentScanningUrl = url
            
            // Asymptotic Progress Update
            self.scannedItemsCount += 1
            let progressWithinRange = 1.0 - (1.0 / (1.0 + Double(self.scannedItemsCount) / self.progressSmoothingFactor))
            let (start, end) = self.currentTaskProgressRange
            let newProgress = start + (end - start) * progressWithinRange
            
            // Only update if greater (monotonically increasing)
            if newProgress > self.scanProgress {
                self.scanProgress = newProgress
            }
        }
    }
    
    func sizeFor(category: DeepCleanCategory) -> Int64 {
        return items.filter { $0.category == category && $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    func stopScan() {
        scanTask?.cancel()
        isScanning = false
    }
    
    func cleanSelected() async -> (count: Int, size: Int64) {
        print("[DeepClean] 🧹 开始清理...")
        
        await MainActor.run {
            self.isCleaning = true
            self.scanStatus = LocalizationManager.shared.currentLanguage == .chinese ? "准备清理..." : "Preparing Cleanup..."
            self.cleaningProgress = 0
            self.cleanedCategories = []
        }
        
        let categoriesToClean: [DeepCleanCategory] = [.junkFiles, .systemLogs, .systemCaches, .appResiduals, .largeFiles]
        var totalDeletedCount = 0
        var totalDeletedSize: Int64 = 0
        var allFailures: [URL] = []
        
        let categoriesWithSelection = categoriesToClean.filter { cat in
            items.contains { $0.category == cat && $0.isSelected }
        }
        
        print("[DeepClean] 📋 找到 \(categoriesWithSelection.count) 个需要清理的分类")
        
        // 如果没有选中任何项目，直接返回
        guard !categoriesWithSelection.isEmpty else {
            print("[DeepClean] ⚠️ 没有选中任何项目，直接返回")
            await MainActor.run {
                self.isCleaning = false
            }
            return (0, 0)
        }
        
        let totalCategories = Double(categoriesWithSelection.count)
        
        for (index, category) in categoriesWithSelection.enumerated() {
            print("[DeepClean] 🔄 开始清理分类: \(category.localizedName)")
            
             await MainActor.run {
                self.cleaningCurrentCategory = category
                self.currentCategory = category
                self.scanStatus = LocalizationManager.shared.currentLanguage == .chinese ? 
                    "正在清理 \(category.localizedName)..." : "Cleaning \(category.localizedName)..."
                self.cleaningDescription = LocalizationManager.shared.currentLanguage == .chinese ? "正在清理..." : "Cleaning..."
            }
            
            let categoryItems = items.filter { $0.category == category && $0.isSelected }
            print("[DeepClean] 📦 该分类有 \(categoryItems.count) 个项目需要清理")
            var categoryFailures: [URL] = []
            
            for item in categoryItems {
                // ⚠️ 安全修复: 使用SafetyGuard检查
                if !SafetyGuard.shared.isSafeToDelete(item.url) {
                    print("[DeepClean] 🛡️ SafetyGuard blocked deletion: \(item.url.path)")
                    categoryFailures.append(item.url)
                    allFailures.append(item.url)
                    continue
                }
                
                do {
                    try fileManager.trashItem(at: item.url, resultingItemURL: nil)
                    totalDeletedCount += 1
                    totalDeletedSize += item.size
                } catch {
                    print("Delete failed for \(item.url): \(error.localizedDescription)")
                    categoryFailures.append(item.url)
                    allFailures.append(item.url)
                }
            }
            
            // Update items for this category immediately
            let capturedFailures = categoryFailures
            await MainActor.run {
                self.items.removeAll { item in
                    categoryItems.contains(where: { $0.id == item.id }) && !capturedFailures.contains(item.url)
                }
                
                // Mark category as cleaned
                self.cleanedCategories.insert(category)
                
                // Animate Progress
                withAnimation(.linear(duration: 0.3)) {
                    self.cleaningProgress = Double(index + 1) / totalCategories
                }
            }
            
            // Small delay for visual pacing (reduced from 300ms to 100ms)
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
        
        let finalDeletedSize = totalDeletedSize
        let finalDeletedCount = totalDeletedCount
        
        print("[DeepClean] ✅ 清理完成！共清理 \(finalDeletedCount) 个文件，释放 \(ByteCountFormatter.string(fromByteCount: finalDeletedSize, countStyle: .file))")
        
        await MainActor.run { [finalDeletedSize] in
            self.cleanedSize = finalDeletedSize
            self.totalSize -= finalDeletedSize
            self.isCleaning = false
            self.cleaningProgress = 1.0
            self.cleaningCurrentCategory = nil
            self.currentCleaningItem = ""
            self.scanStatus = LocalizationManager.shared.currentLanguage == .chinese ? "清理完成" : "Cleanup Complete"
            print("[DeepClean] 📢 已将 isCleaning 设置为 false，应该触发页面切换")
        }
        
        return (finalDeletedCount, finalDeletedSize)
    }
    
    func reset() {
        items = []
        totalSize = 0
        cleanedSize = 0
        scanProgress = 0
        scanStatus = ""
        currentScanningUrl = ""
        completedCategories = []
        cleaningCurrentCategory = nil
        cleanedCategories = []
        cleaningDescription = ""
    }
    
    // MARK: - Helper Methods
    
    private func updateStatus(_ status: String, category: DeepCleanCategory? = nil) async {
        await MainActor.run {
            self.scanStatus = status
        }
    }
    
    // MARK: - Scanning Implementations
    
    private func scanLargeFiles() async -> [DeepCleanItem] {
        // Scan User's Home Directory (~/) recursively
        let home = fileManager.homeDirectoryForCurrentUser
        let scanRoots = [home]
        
        // Exclude specific system/sensitive/app directories to prevent damage
        let config = ScanConfiguration(
            minFileSize: 50 * 1024 * 1024, // 50MB
            skipHiddenFiles: true,
            excludedPaths: [
                "Library",          // Contains App Data/Databases - Unsafe to delete single files
                "Applications",     // Apps themselves
                ".Trash",           // Already in Trash
                ".vol", ".Db",      // System mounts
                "Music/Music Library", // Protect Music Library DB
                "Pictures/Photos Library.photoslibrary" // Protect Photos DB
            ]
        )
        
        let results = await scanDirectoryConcurrently(directories: scanRoots, configuration: config) { url, values -> DeepCleanItem? in
            // SAFETY: Skip .app bundles and application-related files
            self.updateScanningUrl(url.path) // Trigger progress update
            
            if url.path.contains(".app") || 
               url.path.contains("/Applications/") ||
               url.path.contains("/Library/") { // Double check for Library in path
                return nil
            }
            
            return DeepCleanItem(
                url: url,
                name: url.lastPathComponent,
                size: Int64(values.fileSize ?? 0),
                category: .largeFiles
            )
        }
        
        return results
    }
    
    private func scanLogs() async -> [DeepCleanItem] {
        var logPaths = [String]()
        
        // 1. Standard Log Paths
        logPaths.append(contentsOf: [
            "~/Library/Logs",
            "~/Library/Application Support/CrashReporter",
            "~/Library/Logs/DiagnosticReports"
        ])
        
        // 2. Expand tilde
        let expandedPaths = logPaths.map { NSString(string: $0).expandingTildeInPath }
        
        let config = ScanConfiguration(
            minFileSize: 0,
            skipHiddenFiles: false
        )
        
        return await scanDirectoryConcurrently(directories: expandedPaths.map { URL(fileURLWithPath: $0) }, configuration: config) { url, values in
            self.updateScanningUrl(url.path)
            
            // Filter logic
            let isLog = url.pathExtension == "log" || 
                       url.pathExtension == "crash" ||
                       url.path.contains("/Logs/") || 
                       url.path.contains("/CrashReporter/")
            
            if isLog {
                return DeepCleanItem(
                    url: url,
                    name: url.lastPathComponent,
                    size: Int64(values.fileSize ?? 0),
                    category: .systemLogs
                )
            }
            return nil
        }
    }
    
    // MARK: - Dynamic App Scanning Helpers
    
    private func getInstalledApps() -> [InstalledAppInfo] {
        var apps: [InstalledAppInfo] = []
        let appDirs = [
            "/Applications",
            "/System/Applications",
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]
        
        for dir in appDirs {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: dir) else { continue }
            for item in contents {
                if item.hasSuffix(".app") {
                    let appUrl = URL(fileURLWithPath: dir).appendingPathComponent(item)
                    // Get Bundle ID
                    if let bundle = Bundle(url: appUrl),
                       let bundleId = bundle.bundleIdentifier {
                        let icon = NSWorkspace.shared.icon(forFile: appUrl.path)
                        let name = (item as NSString).deletingPathExtension
                        apps.append(InstalledAppInfo(name: name, bundleId: bundleId, url: appUrl, icon: icon))
                    }
                }
            }
        }
        return apps
    }
    
    private func scanCaches() async -> [DeepCleanItem] {
        var items: [DeepCleanItem] = []
        
        // 1. Dynamic App Scanning
        let apps = getInstalledApps()
        let home = fileManager.homeDirectoryForCurrentUser
        
        // Optimization: Use concurrent scanning for apps
        await withTaskGroup(of: DeepCleanItem?.self) { group in
            for app in apps {
                group.addTask {
                    // Predict Cache Path: ~/Library/Caches/[BundleID]
                    let cacheUrl = home.appendingPathComponent("Library/Caches").appendingPathComponent(app.bundleId)
                    
                    if self.fileManager.fileExists(atPath: cacheUrl.path) {
                        // Update UI occasionally
                        if Int.random(in: 0...50) == 0 { await MainActor.run { self.updateScanningUrl(cacheUrl.path) } }
                        
                        let size = await calculateSizeAsync(at: cacheUrl)
                        if size > 1024 * 1024 { // > 1MB
                             return DeepCleanItem(
                                url: cacheUrl,
                                name: app.name + " " + (LocalizationManager.shared.currentLanguage == .chinese ? "缓存" : "Cache"),
                                size: size,
                                category: .systemCaches,
                                appIcon: app.icon,
                                bundleId: app.bundleId
                            )
                        }
                    }
                    return nil
                }
            }
            
            for await item in group {
                if let item = item { items.append(item) }
            }
        }
        
        // 2. Scan Log Paths (using predicted Bundle IDs)
         // (This could be integrated here or in scanLogs, but let's stick to Caches for now as requested)
         
        // 3. Scan Generic Caches (browsers etc. matching specifically if not found by bundle ID)
        // Note: Chrome/Safari/etc usually have specific bundle IDs so getInstalledApps should catch them.
        // We can keep the manual list as a fallback or removal it?
        // Let's keep a small manual list for non-standard apps that might not be in /Applications or have weird cache paths (like Chrome's "Default/Cache")
        
        // Browsers specific paths not covered by Bundle ID Caches standard
        let manualItems = await scanManualCaches()
        items.append(contentsOf: manualItems)
        
        // Deduplicate
        return Array(Set(items.map { $0.url })).compactMap { url in
            items.first(where: { $0.url == url })
        }
    }
    
    private func scanManualCaches() async -> [DeepCleanItem] {
         var cachePaths = Set<String>()
        
        // Specific complex paths not just ~/Library/Caches/BundleID
        cachePaths.insert("~/Library/Caches/Google/Chrome") // Sometimes this is a container
        cachePaths.insert("~/Library/Application Support/Google/Chrome/Default/Cache")
        cachePaths.insert("~/Library/Caches/com.apple.Safari") // Safari uses standard ID but complex structure sometimes
        cachePaths.insert("~/Library/Caches/Firefox")
        
         // 3. Expand all paths
        let validPaths = cachePaths
            .map { NSString(string: $0).expandingTildeInPath }
            .map { URL(fileURLWithPath: $0) }
            .filter { fileManager.fileExists(atPath: $0.path) }
            
        var items: [DeepCleanItem] = []
        for dir in validPaths {
             let size = await calculateSizeAsync(at: dir)
             if size > 1024 {
                var displayName = dir.lastPathComponent
                if dir.path.contains("Chrome") { displayName = "Chrome Cache" }
                else if dir.path.contains("Firefox") { displayName = "Firefox Cache" }
                
                 items.append(DeepCleanItem(
                    url: dir,
                    name: displayName,
                    size: size,
                    category: .systemCaches
                ))
             }
        }
        return items
    }
    
    private func scanResiduals() async -> [DeepCleanItem] {
        print("[DeepClean] 🔍 开始扫描应用残留...")
        
        let home = fileManager.homeDirectoryForCurrentUser
        var items: [DeepCleanItem] = []
        
        // 1. 获取所有已安装应用的信息
        let installedApps = await getInstalledAppParams()
        print("[DeepClean] 📱 找到 \(installedApps.count) 个已安装应用")
        
        // 2. 扫描 Application Support (应用数据)
        let appSupport = home.appendingPathComponent("Library/Application Support")
        if fileManager.fileExists(atPath: appSupport.path) {
            updateScanningUrl(appSupport.path)
            if let contents = try? fileManager.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for folder in contents {
                    // Update UI occasionally
                    if Int.random(in: 0...10) == 0 { await MainActor.run { self.updateScanningUrl(folder.path) } }
                    
                    let folderName = folder.lastPathComponent
                    
                    // ⚠️ 关键：使用 isOrphanedFolder 判断是否为残留
                    if isOrphanedFolder(name: folderName, installedApps: installedApps) {
                        // ⚠️ 再次使用 SafetyGuard 验证
                        if SafetyGuard.shared.isSafeToDelete(folder) {
                            let size = await calculateSizeAsync(at: folder)
                            if size > 100_000 { // 只添加大于100KB的残留
                                items.append(DeepCleanItem(
                                    url: folder,
                                    name: folderName,
                                    size: size,
                                    category: .appResiduals
                                ))
                                print("[DeepClean] 🗑️ 发现残留: \(folderName)")
                            }
                        }
                    }
                }
            }
        }
        
        // 3. 扫描 Preferences (偏好设置)
        // ⚠️ 注意：Preferences 包含大量系统服务配置，需要极其谨慎
        // 为了安全，暂时禁用 Preferences 扫描，避免误删系统配置
        // let prefs = home.appendingPathComponent("Library/Preferences")
        // print("[DeepClean] ⚠️ Preferences 扫描已禁用，以防误删系统配置")
        
        // 如果未来要启用，需要更严格的白名单
        /*
        if fileManager.fileExists(atPath: prefs.path) {
            updateScanningUrl(prefs.path)
            if let contents = try? fileManager.contentsOfDirectory(at: prefs, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for file in contents {
                    guard file.pathExtension == "plist" else { continue }
                    
                    let bundleId = file.deletingPathExtension().lastPathComponent
                    
                    // 额外的安全检查
                    if isOrphanedFile(bundleId: bundleId, installedApps: installedApps) {
                        if SafetyGuard.shared.isSafeToDelete(file) {
                            // 只添加确定是第三方应用的 plist
                            if bundleId.contains(".") && 
                               !bundleId.hasPrefix("com.apple.") &&
                               !bundleId.hasPrefix("apple") {
                                if let attrs = try? fileManager.attributesOfItem(atPath: file.path),
                                   let size = attrs[.size] as? Int64, size > 100_000 { // 只添加 >100KB 的
                                    items.append(DeepCleanItem(
                                        url: file,
                                        name: file.lastPathComponent,
                                        size: size,
                                        category: .appResiduals
                                    ))
                                }
                            }
                        }
                    }
                }
            }
        }
        */
        
        // 4. 扫描 Containers (沙盒容器)
        let containers = home.appendingPathComponent("Library/Containers")
        if fileManager.fileExists(atPath: containers.path) {
            updateScanningUrl(containers.path)
            if let contents = try? fileManager.contentsOfDirectory(at: containers, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for folder in contents {
                    // Update UI occasionally
                    if Int.random(in: 0...10) == 0 { await MainActor.run { self.updateScanningUrl(folder.path) } }
                    
                    let bundleId = folder.lastPathComponent
                    
                    if isOrphanedFile(bundleId: bundleId, installedApps: installedApps) {
                        if SafetyGuard.shared.isSafeToDelete(folder) {
                            let size = await calculateSizeAsync(at: folder)
                            if size > 100_000 { // 只添加大于100KB的残留
                                items.append(DeepCleanItem(
                                    url: folder,
                                    name: bundleId,
                                    size: size,
                                    category: .appResiduals
                                ))
                            }
                        }
                    }
                }
            }
        }
        
        print("[DeepClean] ✅ 扫描完成，找到 \(items.count) 个应用残留")
        return items
    }
    
    // MARK: - 残留检测辅助方法
    
    /// 判断文件/文件夹名称是否为已卸载应用的残留
    private func isOrphanedFolder(name: String, installedApps: Set<String>) -> Bool {
        let lowerName = name.lowercased()
        
        // 1. 跳过系统目录和Apple服务
        let systemDirs = [
            // 核心系统目录
            "cloudkit", "geoservices", "familycircle", "knowledge", "metadata",
            "tmp", "t", "caches", "cache", "logs", "preferences", "temp",
            "cookies", "webkit", "httpstorages", "containers", "group containers",
            "databases", "keychains", "accounts", "mail", "calendars", "contacts",
            
            // Apple 应用和服务
            "safari", "finder", "dock", "spotlight", "siri",
            "passkit", "wallet",  // ⚠️ 钱包和密码服务
            "appstore", "facetime", "messages", "photos", "music", "tv",
            "icloud", "cloudphotosd", "cloudpaird",
            
            // 系统守护进程和代理
            "accountsd", "appleaccount", "identityservicesd",
            "itunesstored", "commerce", "storekit",
            "softwareupdate", "diagnostics"
        ]
        if systemDirs.contains(lowerName) { return false }
        
        // 2. 跳过以 . 开头的隐藏目录
        if name.hasPrefix(".") { return false }
        
        // 3. 跳过 Apple 系统目录
        if lowerName.hasPrefix("com.apple.") { return false }
        if lowerName.hasPrefix("apple") { return false }
        
        // 4. 检查是否匹配已安装应用
        // 精确匹配
        if installedApps.contains(lowerName) { return false }
        
        // 模糊匹配：检查是否包含已安装应用的名称
        for appId in installedApps {
            // 双向匹配
            if lowerName.contains(appId) || appId.contains(lowerName) {
                // 额外检查：避免误匹配过短的字符串
                if min(lowerName.count, appId.count) >= 5 {
                    return false
                }
            }
        }
        
        // 5. 检查 Bundle ID 格式的组件
        if lowerName.contains(".") {
            let components = lowerName.components(separatedBy: ".")
            for component in components where component.count >= 4 {
                for appId in installedApps {
                    if appId.contains(component) {
                        return false
                    }
                }
            }
        }
        
        // 通过所有检查，确认是残留
        return true
    }
    
    /// 判断 Bundle ID 是否为已卸载应用的残留
    private func isOrphanedFile(bundleId: String, installedApps: Set<String>) -> Bool {
        let lowerBundleId = bundleId.lowercased()
        
        // 1. 跳过以 . 开头的系统文件（如 .GlobalPreferences.plist）
        if bundleId.hasPrefix(".") { return false }
        
        // 2. 跳过所有 Apple 系统服务
        if lowerBundleId.hasPrefix("com.apple.") { return false }
        if lowerBundleId.hasPrefix("apple") { return false }
        
        // 3. 🛡️ 扩展的系统服务白名单（关键系统组件）
        let systemBundleIds = [
            // 核心系统服务
            "loginwindow", "finder", "dock", "systemuiserver", "controlcenter",
            "notificationcenter", "launchservicesd", "cfprefsd",
            
            // 系统守护进程
            "contextstoreagent", "contextstore",  // 上下文存储
            "pbs", "pasteboard",                   // 剪贴板服务
            "familycircled", "familycircle",       // 家庭共享
            "sharedfilelistd", "sharedfilelist",   // 共享文件列表
            "diagnostics_agent", "diagnostics",    // 系统诊断
            
            // Apple 账户和认证
            "passkit", "wallet", "passd",          // 钱包和密码服务 ⚠️ 重要
            "accountsd", "accounts",               // 账户管理
            "identityservicesd", "appleaccount",   // 身份验证
            
            // iCloud 和同步服务
            "cloudd", "icloud", "bird", "syncdefaultsd",
            "cloudphotosd", "cloudpaird", "cloudkitd",
            
            // App Store 和下载
            "itunesstored", "commerce", "storekit", "appstoreupdates",
            "softwareupdate", "softwareupdate_notify_agent",
            
            // 媒体和多媒体服务
            "mediaremoted", "coremedia", "avfoundation",
            "applemediaservices", "applemedialibrary",
            
            // 网络和安全
            "networkd", "securityd", "trustd", "keybagd",
            
            // 其他关键服务
            "coreduetd", "dasd", "rapportd", "askpermissiond"
        ]
        if systemBundleIds.contains(lowerBundleId) { return false }
        
        // 4. 精确匹配 Bundle ID
        if installedApps.contains(bundleId) || installedApps.contains(lowerBundleId) {
            return false
        }
        
        // 5. 模糊匹配：检查 Bundle ID 的各个组件
        let components = bundleId.components(separatedBy: ".")
        for component in components where component.count > 3 {
            for appId in installedApps {
                if appId.contains(component) || component.contains(appId) {
                    return false
                }
            }
        }
        
        // 通过所有检查，确认是残留
        return true
    }
    
    private func scanJunk() async -> [DeepCleanItem] {
        // Trash, Downloads (Older than X?), Xcode DerivedData
        let home = fileManager.homeDirectoryForCurrentUser
        let trash = home.appendingPathComponent(".Trash")
        
        var items: [DeepCleanItem] = []
        
        // 1. Scan Trash
        updateScanningUrl(trash.path)
        let trashSize = await calculateSizeAsync(at: trash)
        if trashSize > 0 {
            items.append(DeepCleanItem(
                url: trash,
                name: LocalizationManager.shared.currentLanguage == .chinese ? "废纸篓" : "Trash",
                size: trashSize,
                category: .junkFiles
            ))
        }
        
        // 2. Xcode DerivedData
        let developer = home.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        if fileManager.fileExists(atPath: developer.path) {
            updateScanningUrl(developer.path)
            let size = await calculateSizeAsync(at: developer)
             if size > 0 {
                items.append(DeepCleanItem(
                    url: developer,
                    name: "Xcode DerivedData",
                    size: size,
                    category: .junkFiles
                ))
            }
        }
        
        // 3. iOS Device Backups
        let iosBackups = home.appendingPathComponent("Library/Application Support/MobileSync/Backup")
        if fileManager.fileExists(atPath: iosBackups.path) {
            updateScanningUrl(iosBackups.path)
            let size = await calculateSizeAsync(at: iosBackups)
            if size > 0 {
                items.append(DeepCleanItem(
                    url: iosBackups,
                    name: LocalizationManager.shared.currentLanguage == .chinese ? "iOS 设备备份" : "iOS Backups",
                    size: size,
                    category: .junkFiles
                ))
            }
        }
        
        // 4. Mail Downloads
        let mailDownloads = home.appendingPathComponent("Library/Containers/com.apple.mail/Data/Library/Mail Downloads")
        if fileManager.fileExists(atPath: mailDownloads.path) {
            updateScanningUrl(mailDownloads.path)
            let size = await calculateSizeAsync(at: mailDownloads)
            if size > 0 {
                items.append(DeepCleanItem(
                    url: mailDownloads,
                    name: LocalizationManager.shared.currentLanguage == .chinese ? "邮件附件" : "Mail Attachments",
                    size: size,
                    category: .junkFiles
                ))
            }
        }
        
        // 5. 应用缓存 (App Caches) - 扫描 ~/Library/Caches 中的应用缓存
        // ⚠️ 注意：Caches 目录包含大量系统和应用缓存
        // 为了安全，只扫描明确知道是第三方应用的缓存
        let cachesDir = home.appendingPathComponent("Library/Caches")
        if fileManager.fileExists(atPath: cachesDir.path) {
            updateScanningUrl(cachesDir.path)
            if let cacheContents = try? fileManager.contentsOfDirectory(at: cachesDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for cacheFolder in cacheContents {
                    // Update UI occasionally
                    if Int.random(in: 0...5) == 0 { await MainActor.run { self.updateScanningUrl(cacheFolder.path) } }
                    
                    let folderName = cacheFolder.lastPathComponent.lowercased()
                    
                    // 🛡️ 第一层：明确跳过所有 Apple 系统缓存
                    if folderName.hasPrefix("com.apple.") {
                        continue  // 绝不扫描 Apple 系统缓存
                    }
                    
                    // 🛡️ 第二层：跳过当前正在运行的应用（我们自己的应用）
                    if folderName == "com.tool.appuninstaller" {
                        continue  // 不清理自己的缓存
                    }
                    
                    // 🛡️ 第三层：跳过已知的Apple系统服务缓存
                    let appleSystemServices = [
                        "passkit",  // Apple Wallet/密码服务
                        "cloudkit", "clouddocs", "cloudphotosd",
                        "familycircle", "familycircled",
                        "sqlite", "metadata", "applemedialibrary",
                        "applemediaservices", "itunesstored",
                        "commerce", "storekit", "appleaccount",
                        "accountsd", "identityservicesd",
                        "com.crashlytics", "diagnostics",
                        "appstoreupdates", "softwareupdate"
                    ]
                    if appleSystemServices.contains(folderName) {
                        continue  // 跳过Apple系统服务
                    }
                    
                    // 🛡️ 第四层：跳过所有正在运行的应用的缓存
                    let runningBundleIds = NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier?.lowercased() }
                    if runningBundleIds.contains(folderName) {
                        continue  // 不清理正在运行的应用的缓存
                    }
                    
                    // 🛡️ 第五层：SafetyGuard 最终检查
                    if SafetyGuard.shared.isSafeToDelete(cacheFolder) {
                        let size = await calculateSizeAsync(at: cacheFolder)
                        if size > 100_000 { // 只添加大于100KB的缓存
                            items.append(DeepCleanItem(
                                url: cacheFolder,
                                name: cacheFolder.lastPathComponent,
                                size: size,
                                category: .junkFiles
                            ))
                        }
                    }
                }
            }
        }
        
        // 6. 浏览器缓存 (Browser Caches)
        let browserCaches: [(name: String, path: String)] = [
            ("Safari 缓存", "Library/Caches/com.apple.Safari"),
            ("Chrome 缓存", "Library/Caches/Google/Chrome"),
            ("Firefox 缓存", "Library/Caches/Firefox"),
            ("Edge 缓存", "Library/Caches/com.microsoft.Edge")
        ]
        
        for (name, relativePath) in browserCaches {
            let cachePath = home.appendingPathComponent(relativePath)
            if fileManager.fileExists(atPath: cachePath.path) {
                updateScanningUrl(cachePath.path)
                let size = await calculateSizeAsync(at: cachePath)
                if size > 0 {
                    items.append(DeepCleanItem(
                        url: cachePath,
                        name: LocalizationManager.shared.currentLanguage == .chinese ? name : name.replacingOccurrences(of: " 缓存", with: " Cache"),
                        size: size,
                        category: .junkFiles
                    ))
                }
            }
        }
        
        return items
    }
    
    // MARK: - App Helpers
    
    /// 获取已安装应用的标识符集合 (Bundle ID + Name) - 改进版
    private func getInstalledAppParams() async -> Set<String> {
        var params = Set<String>()
        
        // 1. 扫描标准应用目录
        let appDirs = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]
        
        for dir in appDirs {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: dir) else { continue }
            
            for item in contents {
                if item.hasSuffix(".app") {
                    // 添加应用名称 (去除后缀)
                    let name = (item as NSString).deletingPathExtension
                    params.insert(name.lowercased())
                    
                    // 读取 Info.plist 获取 Bundle ID
                    let appPath = (dir as NSString).appendingPathComponent(item)
                    let plistPath = (appPath as NSString).appendingPathComponent("Contents/Info.plist")
                    
                    if let plistData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
                       let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
                       let bundleId = plist["CFBundleIdentifier"] as? String {
                        params.insert(bundleId.lowercased())
                        
                        // 提取 Bundle ID 各组件
                        for component in bundleId.components(separatedBy: ".") where component.count > 3 {
                            params.insert(component.lowercased())
                        }
                    }
                }
            }
        }
        
        // 2. 添加 Homebrew Cask 应用
        let homebrewPaths = ["/opt/homebrew/Caskroom", "/usr/local/Caskroom"]
        for caskPath in homebrewPaths {
            if let casks = try? fileManager.contentsOfDirectory(atPath: caskPath) {
                for cask in casks {
                    params.insert(cask.lowercased())
                }
            }
        }
        
        // 3. 添加正在运行的应用（最重要的安全检查）
        for app in NSWorkspace.shared.runningApplications {
            if let bundleId = app.bundleIdentifier {
                params.insert(bundleId.lowercased())
            }
            if let name = app.localizedName {
                params.insert(name.lowercased())
            }
        }
        
        // 4. 扩展的系统安全名单
        let systemSafelist = [
            // Apple 系统服务
            "com.apple", "cloudkit", "safari", "mail", "messages", "photos",
            "finder", "dock", "spotlight", "siri", "xcode", "instruments",
            "passkit", "wallet", "appstore", "facetime", "imessage",
            "familycircle", "familysharing", "icloud", "appleaccount",
            "findmy", "fmip", "healthkit", "homekit", "newsstand",
            "itunesstored", "commerce", "storekit", "applemediaservices",
            // 第三方常用应用
            "google", "chrome", "microsoft", "firefox", "adobe", "dropbox",
            "slack", "discord", "zoom", "telegram", "wechat", "qq", "tencent",
            "jetbrains", "vscode", "homebrew", "npm", "python", "ruby", "java",
            "todesk", "teamviewer", "anydesk"  // 远程桌面工具
        ]
        for safe in systemSafelist {
            params.insert(safe)
        }
        
        return params
    }
    
    private func isAppInstalled(_ name: String, params: Set<String>) -> Bool {
        let lowerName = name.lowercased()
        
        // 1. 直接匹配
        if params.contains(lowerName) { return true }
        
        // 2. 检查是否为系统保留
        if lowerName.starts(with: "com.apple.") { return true }
        if lowerName.starts(with: "apple") { return true }
        
        // 3. 模糊匹配：检查是否包含已安装应用名称
        for param in params {
            // 双向包含检查
            if lowerName.contains(param) || param.contains(lowerName) {
                return true
            }
        }
        
        // 4. 框架和插件保护
        let safePatterns = ["framework", "plugin", "extension", "helper", "service", "daemon", "agent"]
        for pattern in safePatterns {
            if lowerName.contains(pattern) { return true }
        }
        
        return false
    }

    
    // Toggle Logic
    func toggleSelection(for item: DeepCleanItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isSelected.toggle()
        }
        objectWillChange.send()
    }
    
    func toggleCategorySelection(_ category: DeepCleanCategory, to newState: Bool) {
        let categoryItems = items.filter { $0.category == category }
        for item in categoryItems {
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx].isSelected = newState
            }
        }
        objectWillChange.send()
    }
    
    func selectItems(in category: DeepCleanCategory) {
        for i in items.indices where items[i].category == category {
            items[i].isSelected = true
        }
    }
    
    func deselectItems(in category: DeepCleanCategory) {
        for i in items.indices where items[i].category == category {
            items[i].isSelected = false
        }
    }
    
    /// 删除单个项目
    @MainActor
    func deleteSingleItem(_ item: DeepCleanItem) async -> Bool {
        // ⚠️ BUG 修复：添加 SafetyGuard 检查
        if !SafetyGuard.shared.isSafeToDelete(item.url) {
            print("[DeepClean] 🛡️ SafetyGuard blocked deletion: \(item.url.path)")
            return false
        }
        
        do {
            // ⚠️ 安全改进：使用 trashItem 替代 removeItem，支持从废纸篓恢复
            try fileManager.trashItem(at: item.url, resultingItemURL: nil)
            items.removeAll { $0.id == item.id }
            totalSize -= item.size
            return true
        } catch {
            print("删除失败: \(item.url.path) - \(error)")
            return false
        }
    }
}

