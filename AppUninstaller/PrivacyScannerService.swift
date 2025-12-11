import Foundation
import Combine
import AppKit

// MARK: - 隐私数据类型
enum PrivacyType: String, CaseIterable, Identifiable {
    case history = "浏览记录"
    case cookies = "Cookie 文件"
    case downloads = "下载记录"
    case cache = "浏览器缓存"
    case malware = "恶意软件" // 保留原恶意软件扫描
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .history: return "clock.arrow.circlepath"
        case .cookies: return "lock.circle" // or a cookie icon if available, SF Symbols maybe "circle.dotted" or similar
        case .downloads: return "arrow.down.circle"
        case .cache: return "photo.stack"
        case .malware: return "exclamationmark.shield.fill"
        }
    }
}

// MARK: - 浏览器类型
enum BrowserType: String, CaseIterable, Identifiable {
    case safari = "Safari"
    case chrome = "Google Chrome"
    case firefox = "Firefox"
    case system = "System" // For malware or system-wide privacy
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .safari: return "safari"
        case .chrome: return "globe" // Placeholder, maybe specific icon logic
        case .firefox: return "flame"
        case .system: return "applelogo"
        }
    }
}

// MARK: - 隐私项模型
struct PrivacyItem: Identifiable, Equatable {
    let id = UUID()
    let browser: BrowserType
    let type: PrivacyType
    let path: URL
    let size: Int64
    let displayPath: String // 用于显示更友好的路径或描述
    var isSelected: Bool = true
}

// MARK: - 隐私扫描服务
class PrivacyScannerService: ObservableObject {
    @Published var privacyItems: [PrivacyItem] = []
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0
    @Published var malwareScanner = MalwareScanner() // 集成原有点恶意软件扫描
    
    // 统计数据
    var totalHistoryCount: Int { count(for: .history) }
    var totalCookiesCount: Int { count(for: .cookies) }
    var totalDownloadsCount: Int { count(for: .downloads) }
    
    private let fileManager = FileManager.default
    
    private func count(for type: PrivacyType) -> Int {
        privacyItems.filter { $0.type == type }.count
    }
    
    var totalSize: Int64 {
        privacyItems.reduce(0) { $0 + $1.size }
    }
    
    var selectedSize: Int64 {
        privacyItems.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    // MARK: - 扫描方法
    func scanAll() async {
        await MainActor.run {
            isScanning = true
            privacyItems.removeAll()
            scanProgress = 0
        }
        
        // 1. 扫描浏览器数据
        let browsers = BrowserType.allCases.filter { $0 != .system }
        for (index, browser) in browsers.enumerated() {
            let items = await scanBrowser(browser)
            await MainActor.run {
                privacyItems.append(contentsOf: items)
                scanProgress = Double(index + 1) / Double(browsers.count + 1) // +1 for malware
            }
        }
        
        // 2. 扫描恶意软件
        await malwareScanner.scan()
        let threats = malwareScanner.threats
        
        let malwareItems = threats.map { threat in
            PrivacyItem(
                browser: .system,
                type: .malware,
                path: threat.path,
                size: threat.size,
                displayPath: threat.name
            )
        }
        
        await MainActor.run {
            privacyItems.append(contentsOf: malwareItems)
            scanProgress = 1.0
            isScanning = false
        }
    }
    
    // MARK: - 辅助方法：添加关联文件 (WAL/SHM)
    private func addWithRelatedFiles(path: URL, type: PrivacyType, browser: BrowserType, description: String, to items: inout [PrivacyItem]) {
        if let size = fileSize(at: path) {
            items.append(PrivacyItem(browser: browser, type: type, path: path, size: size, displayPath: description))
        }
        
        let walPath = path.appendingPathExtension("wal")
        if let size = fileSize(at: walPath) {
            items.append(PrivacyItem(browser: browser, type: type, path: walPath, size: size, displayPath: "\(description) (WAL)"))
        }
        
        let shmPath = path.appendingPathExtension("shm")
        if let size = fileSize(at: shmPath) {
            items.append(PrivacyItem(browser: browser, type: type, path: shmPath, size: size, displayPath: "\(description) (SHM)"))
        }
    }
    
    // MARK: - 进程检测与终止
    func checkRunningBrowsers() -> [BrowserType] {
        var running: [BrowserType] = []
        let apps = NSWorkspace.shared.runningApplications
        
        for app in apps {
            guard let bundleId = app.bundleIdentifier else { continue }
            if bundleId.contains("com.apple.Safari") {
                if !running.contains(.safari) { running.append(.safari) }
            } else if bundleId.contains("com.google.Chrome") {
                if !running.contains(.chrome) { running.append(.chrome) }
            } else if bundleId.contains("org.mozilla.firefox") {
                if !running.contains(.firefox) { running.append(.firefox) }
            }
        }
        return running
    }
    
    func closeBrowsers() async -> Bool {
        let apps = NSWorkspace.shared.runningApplications
        var success = true
        
        for app in apps {
            guard let bundleId = app.bundleIdentifier else { continue }
            if bundleId.contains("com.apple.Safari") || 
               bundleId.contains("com.google.Chrome") || 
               bundleId.contains("org.mozilla.firefox") {
                
                app.terminate()
                
                // 等待一段时间看是否关闭
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                if !app.isTerminated {
                    app.forceTerminate()
                }
                
                if !app.isTerminated {
                    success = false
                }
            }
        }
        return success
    }
    
    // MARK: - 清理方法
    func cleanSelected() async -> (cleaned: Int64, failed: Int64) {
        var cleaned: Int64 = 0
        var failed: Int64 = 0
        
        let itemsToDelete = privacyItems.filter { $0.isSelected }
        
        for item in itemsToDelete {
            do {
                if item.type == .malware {
                   // 尝试直接删除
                   try fileManager.removeItem(at: item.path)
                   cleaned += item.size
                } else {
                    // 普通文件删除
                    try fileManager.removeItem(at: item.path)
                    cleaned += item.size
                }
            } catch {
                print("Failed to delete \(item.path.path): \(error)")
                failed += item.size
            }
        }
        
        await MainActor.run {
            // Remove deleted items from list
            privacyItems.removeAll { item in
                itemsToDelete.contains { $0.id == item.id }
            }
        }
        
        return (cleaned, failed)
    }
    
    // MARK: - Helper Scanning Methods
    
    private func scanBrowser(_ browser: BrowserType) async -> [PrivacyItem] {
        var items: [PrivacyItem] = []
        
        switch browser {
        case .safari:
            items.append(contentsOf: scanSafari())
        case .chrome:
            items.append(contentsOf: scanChrome())
        case .firefox:
            items.append(contentsOf: scanFirefox())
        case .system:
            break
        }
        
        return items
    }
    
    private func scanSafari() -> [PrivacyItem] {
        var items: [PrivacyItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        
        // 1. History
        // 1. History
        let historyURL = home.appendingPathComponent("Library/Safari/History.db")
        addWithRelatedFiles(path: historyURL, type: .history, browser: .safari, description: "Safari 浏览记录数据库", to: &items)
        
        // 2. Downloads
        let downloadsURL = home.appendingPathComponent("Library/Safari/Downloads.plist")
         if let size = fileSize(at: downloadsURL) {
            items.append(PrivacyItem(browser: .safari, type: .downloads, path: downloadsURL, size: size, displayPath: "Safari 下载记录列表"))
        }
        
        // 3. Cookies (Usually in ~/Library/Containers/com.apple.Safari/Data/Library/Cookies/Cookies.binarycookies on newer macOS, or ~/Library/Cookies)
        let cookiesURL = home.appendingPathComponent("Library/Cookies/Cookies.binarycookies")
        if let size = fileSize(at: cookiesURL) {
            items.append(PrivacyItem(browser: .safari, type: .cookies, path: cookiesURL, size: size, displayPath: "Safari Cookie 文件"))
        }
        
        // 检查 Containers 路径 (Sanboxed)
        let sandboxCookies = home.appendingPathComponent("Library/Containers/com.apple.Safari/Data/Library/Cookies/Cookies.binarycookies")
        if let size = fileSize(at: sandboxCookies) {
            items.append(PrivacyItem(browser: .safari, type: .cookies, path: sandboxCookies, size: size, displayPath: "Safari (沙盒) Cookie 文件"))
        }
        
        return items
    }
    
    private func scanChrome() -> [PrivacyItem] {
        var items: [PrivacyItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        let chromeDir = home.appendingPathComponent("Library/Application Support/Google/Chrome")
        
        guard fileManager.fileExists(atPath: chromeDir.path) else { return [] }
        
        // 获取所有配置文件目录 (Default, Profile 1, Profile 2, ...)
        var profileDirs: [URL] = []
        if let contents = try? fileManager.contentsOfDirectory(at: chromeDir, includingPropertiesForKeys: [.isDirectoryKey]) {
            for item in contents {
                let name = item.lastPathComponent
                // Chrome profile directories are "Default" or "Profile X"
                if name == "Default" || name.hasPrefix("Profile ") {
                    var isDir: ObjCBool = false
                    if fileManager.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue {
                        profileDirs.append(item)
                    }
                }
            }
        }
        
        if profileDirs.isEmpty {
            // Fallback to Default
            let defaultPath = chromeDir.appendingPathComponent("Default")
            if fileManager.fileExists(atPath: defaultPath.path) {
                profileDirs.append(defaultPath)
            }
        }
        
        for profile in profileDirs {
            let profileName = profile.lastPathComponent
            
            // History
            let historyURL = profile.appendingPathComponent("History")
            addWithRelatedFiles(path: historyURL, type: .history, browser: .chrome, description: "Chrome 浏览记录 (\(profileName))", to: &items)
            
            // History-journal
            let historyJournal = profile.appendingPathComponent("History-journal")
            if let size = fileSize(at: historyJournal) {
                items.append(PrivacyItem(browser: .chrome, type: .history, path: historyJournal, size: size, displayPath: "Chrome History-journal (\(profileName))"))
            }
            
            // Cookies
            let cookiesURL = profile.appendingPathComponent("Cookies")
            addWithRelatedFiles(path: cookiesURL, type: .cookies, browser: .chrome, description: "Chrome Cookies (\(profileName))", to: &items)
            
            // Cookies-journal
            let cookiesJournal = profile.appendingPathComponent("Cookies-journal")
            if let size = fileSize(at: cookiesJournal) {
                items.append(PrivacyItem(browser: .chrome, type: .cookies, path: cookiesJournal, size: size, displayPath: "Chrome Cookies-journal (\(profileName))"))
            }
        }
        
        // Cache (all profiles share cache structure usually, check both)
        let defaultCacheURL = home.appendingPathComponent("Library/Caches/Google/Chrome/Default/Cache")
        if let size = folderSize(at: defaultCacheURL), size > 0 {
            items.append(PrivacyItem(browser: .chrome, type: .cache, path: defaultCacheURL, size: size, displayPath: "Chrome 缓存 (Default)"))
        }
        
        return items
    }
    
    private func scanFirefox() -> [PrivacyItem] {
        var items: [PrivacyItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        let profilesPath = home.appendingPathComponent("Library/Application Support/Firefox/Profiles")
        
        guard let profiles = try? fileManager.contentsOfDirectory(at: profilesPath, includingPropertiesForKeys: nil), !profiles.isEmpty else { return [] }
        
        for profile in profiles {
            // History (places.sqlite)
            // History (places.sqlite)
            let historyURL = profile.appendingPathComponent("places.sqlite")
            addWithRelatedFiles(path: historyURL, type: .history, browser: .firefox, description: "Firefox 历史记录 (\(profile.lastPathComponent))", to: &items)
            
            // Cookies (cookies.sqlite)
            // Cookies (cookies.sqlite)
            let cookiesURL = profile.appendingPathComponent("cookies.sqlite")
            addWithRelatedFiles(path: cookiesURL, type: .cookies, browser: .firefox, description: "Firefox Cookie (\(profile.lastPathComponent))", to: &items)
        }
        
        return items
    }
    
    private func fileSize(at url: URL) -> Int64? {
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path) else { return nil }
        return attrs[.size] as? Int64
    }
    
    private func folderSize(at url: URL) -> Int64? {
        // Simple folder size calculation
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return nil }
        var size: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }
}
