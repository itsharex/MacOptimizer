import Foundation
import AppKit
import CryptoKit
import Vision

// MARK: - 清理类型
enum CleanerCategory: String, CaseIterable {
    case duplicates = "重复文件"
    case similarPhotos = "相似照片"
    case localizations = "多语言文件"
    case largeFiles = "大文件"
    
    var icon: String {
        switch self {
        case .duplicates: return "doc.on.doc"
        case .similarPhotos: return "photo.on.rectangle"
        case .localizations: return "globe"
        case .largeFiles: return "externaldrive.fill"
        }
    }
    
    var englishName: String {
        switch self {
        case .duplicates: return "Duplicates"
        case .similarPhotos: return "Similar Photos"
        case .localizations: return "Localizations"
        case .largeFiles: return "Large Files"
        }
    }
}

// MARK: - 文件项
struct CleanerFileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    var isSelected: Bool = true  // 默认全选
    let groupId: String  // 用于分组显示
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: CleanerFileItem, rhs: CleanerFileItem) -> Bool {
        lhs.url == rhs.url
    }
}

// MARK: - 重复文件组
struct DuplicateGroup: Identifiable {
    let id = UUID()
    let hash: String
    var files: [CleanerFileItem]
    
    var totalSize: Int64 {
        files.reduce(0) { $0 + $1.size }
    }
    
    var wastedSize: Int64 {
        // 保留一个，其他都是浪费
        guard files.count > 1 else { return 0 }
        return files.dropFirst().reduce(0) { $0 + $1.size }
    }
}

// MARK: - 智能清理服务
class SmartCleanerService: ObservableObject {
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var similarPhotoGroups: [DuplicateGroup] = []
    @Published var localizationFiles: [CleanerFileItem] = []
    @Published var largeFiles: [CleanerFileItem] = []
    
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var currentScanPath: String = ""
    @Published var currentCategory: CleanerCategory = .duplicates
    
    private let fileManager = FileManager.default
    
    // 保留的语言
    private let keepLocalizations = ["en.lproj", "Base.lproj", "zh-Hans.lproj", "zh-Hant.lproj", "zh_CN.lproj", "zh_TW.lproj", "Chinese.lproj", "English.lproj"]
    
    // 默认扫描目录
    private var scanDirectories: [URL] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Pictures")
        ]
    }
    
    // MARK: - 扫描重复文件
    func scanDuplicates() async {
        await MainActor.run {
            isScanning = true
            scanProgress = 0
            duplicateGroups = []
            currentCategory = .duplicates
        }
        
        var sizeGroups: [Int64: [URL]] = [:]
        var totalFiles = 0
        var processedFiles = 0
        
        // 1. 按大小分组
        for dir in scanDirectories {
            guard let enumerator = fileManager.enumerator(at: dir, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) else { continue }
            
            for case let fileURL as URL in enumerator {
                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                      let isDir = values.isDirectory, !isDir,
                      let size = values.fileSize, size > 1024 else { continue } // 跳过小于 1KB 的文件
                
                let size64 = Int64(size)
                if sizeGroups[size64] == nil {
                    sizeGroups[size64] = []
                }
                sizeGroups[size64]?.append(fileURL)
                totalFiles += 1
            }
        }
        
        // 2. 对同大小文件计算 MD5
        var hashGroups: [String: [CleanerFileItem]] = [:]
        let potentialDuplicates = sizeGroups.filter { $0.value.count > 1 }
        
        for (_, files) in potentialDuplicates {
            for url in files {
                processedFiles += 1
                await MainActor.run {
                    scanProgress = Double(processedFiles) / Double(max(totalFiles, 1))
                    currentScanPath = url.lastPathComponent
                }
                
                if let hash = md5Hash(of: url),
                   let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    let item = CleanerFileItem(
                        url: url,
                        name: url.lastPathComponent,
                        size: Int64(size),
                        groupId: hash
                    )
                    if hashGroups[hash] == nil {
                        hashGroups[hash] = []
                    }
                    hashGroups[hash]?.append(item)
                }
            }
        }
        
        // 3. 筛选真正的重复组
        let groups = hashGroups.compactMap { (hash, files) -> DuplicateGroup? in
            guard files.count > 1 else { return nil }
            return DuplicateGroup(hash: hash, files: files)
        }.sorted { $0.wastedSize > $1.wastedSize }
        
        await MainActor.run {
            duplicateGroups = groups
            isScanning = false
            scanProgress = 1.0
            currentScanPath = ""
        }
    }
    
    // MARK: - 扫描相似照片
    func scanSimilarPhotos() async {
        await MainActor.run {
            isScanning = true
            scanProgress = 0
            similarPhotoGroups = []
            currentCategory = .similarPhotos
        }
        
        let picturesDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Pictures")
        var photos: [(url: URL, fingerprint: VNFeaturePrintObservation)] = []
        var processedCount = 0
        var totalCount = 0
        
        // 收集所有图片
        if let enumerator = fileManager.enumerator(at: picturesDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                if ["jpg", "jpeg", "png", "heic", "heif", "tiff"].contains(ext) {
                    totalCount += 1
                }
            }
        }
        
        // 计算图片特征
        if let enumerator = fileManager.enumerator(at: picturesDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                guard ["jpg", "jpeg", "png", "heic", "heif", "tiff"].contains(ext) else { continue }
                
                processedCount += 1
                await MainActor.run {
                    scanProgress = Double(processedCount) / Double(max(totalCount, 1))
                    currentScanPath = fileURL.lastPathComponent
                }
                
                if let fingerprint = await extractImageFingerprint(from: fileURL) {
                    photos.append((url: fileURL, fingerprint: fingerprint))
                }
            }
        }
        
        // 比较相似度
        var similarGroups: [String: [CleanerFileItem]] = [:]
        var matched: Set<URL> = []
        
        for i in 0..<photos.count {
            guard !matched.contains(photos[i].url) else { continue }
            
            var groupFiles: [CleanerFileItem] = []
            let size1 = (try? photos[i].url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            groupFiles.append(CleanerFileItem(
                url: photos[i].url,
                name: photos[i].url.lastPathComponent,
                size: Int64(size1),
                groupId: photos[i].url.path
            ))
            
            for j in (i+1)..<photos.count {
                guard !matched.contains(photos[j].url) else { continue }
                
                var distance: Float = 0
                try? photos[i].fingerprint.computeDistance(&distance, to: photos[j].fingerprint)
                
                // 距离越小越相似，阈值 0.5 表示约 50% 相似
                if distance < 0.4 {
                    matched.insert(photos[j].url)
                    let size2 = (try? photos[j].url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    groupFiles.append(CleanerFileItem(
                        url: photos[j].url,
                        name: photos[j].url.lastPathComponent,
                        size: Int64(size2),
                        groupId: photos[i].url.path
                    ))
                }
            }
            
            if groupFiles.count > 1 {
                matched.insert(photos[i].url)
                similarGroups[photos[i].url.path] = groupFiles
            }
        }
        
        let groups = similarGroups.map { (key, files) in
            DuplicateGroup(hash: key, files: files)
        }.sorted { $0.totalSize > $1.totalSize }
        
        await MainActor.run {
            similarPhotoGroups = groups
            isScanning = false
            scanProgress = 1.0
            currentScanPath = ""
        }
    }
    
    // MARK: - 扫描多语言文件
    func scanLocalizations() async {
        await MainActor.run {
            isScanning = true
            scanProgress = 0
            localizationFiles = []
            currentCategory = .localizations
        }
        
        let applicationsDir = URL(fileURLWithPath: "/Applications")
        let userAppsDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        
        var items: [CleanerFileItem] = []
        var totalApps = 0
        var processedApps = 0
        
        // 计算总数
        for dir in [applicationsDir, userAppsDir] {
            if let contents = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                totalApps += contents.filter { $0.pathExtension == "app" }.count
            }
        }
        
        for dir in [applicationsDir, userAppsDir] {
            guard let apps = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            
            for app in apps where app.pathExtension == "app" {
                processedApps += 1
                await MainActor.run {
                    scanProgress = Double(processedApps) / Double(max(totalApps, 1))
                    currentScanPath = app.lastPathComponent
                }
                
                let resourcesDir = app.appendingPathComponent("Contents/Resources")
                guard let resources = try? fileManager.contentsOfDirectory(at: resourcesDir, includingPropertiesForKeys: nil) else { continue }
                
                for resource in resources {
                    let name = resource.lastPathComponent
                    guard name.hasSuffix(".lproj"), !keepLocalizations.contains(name) else { continue }
                    
                    let size = calculateSize(at: resource)
                    let item = CleanerFileItem(
                        url: resource,
                        name: "\(app.deletingPathExtension().lastPathComponent) - \(name)",
                        size: size,
                        groupId: app.lastPathComponent
                    )
                    items.append(item)
                }
            }
        }
        
        await MainActor.run {
            localizationFiles = items.sorted { $0.size > $1.size }
            isScanning = false
            scanProgress = 1.0
            currentScanPath = ""
        }
    }
    
    // MARK: - 扫描大文件
    func scanLargeFiles(minSize: Int64 = 100 * 1024 * 1024) async { // 默认 100MB
        await MainActor.run {
            isScanning = true
            scanProgress = 0
            largeFiles = []
            currentCategory = .largeFiles
        }
        
        var items: [CleanerFileItem] = []
        let homeDir = fileManager.homeDirectoryForCurrentUser
        var processedCount = 0
        
        if let enumerator = fileManager.enumerator(at: homeDir, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) {
            for case let fileURL as URL in enumerator {
                processedCount += 1
                if processedCount % 100 == 0 {
                    await MainActor.run {
                        currentScanPath = fileURL.lastPathComponent
                    }
                }
                
                // 跳过 Library 等系统目录
                if fileURL.path.contains("/Library/") { continue }
                
                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                      let isDir = values.isDirectory, !isDir,
                      let size = values.fileSize, Int64(size) >= minSize else { continue }
                
                let item = CleanerFileItem(
                    url: fileURL,
                    name: fileURL.lastPathComponent,
                    size: Int64(size),
                    groupId: "large"
                )
                items.append(item)
            }
        }
        
        await MainActor.run {
            largeFiles = items.sorted { $0.size > $1.size }
            isScanning = false
            scanProgress = 1.0
            currentScanPath = ""
        }
    }
    
    // MARK: - 删除选中文件
    func deleteSelectedFiles(from category: CleanerCategory) async -> (success: Int, failed: Int, size: Int64) {
        var success = 0
        var failed = 0
        var freedSize: Int64 = 0
        
        switch category {
        case .duplicates:
            for i in 0..<duplicateGroups.count {
                for j in 0..<duplicateGroups[i].files.count {
                    if duplicateGroups[i].files[j].isSelected {
                        do {
                            try fileManager.trashItem(at: duplicateGroups[i].files[j].url, resultingItemURL: nil)
                            freedSize += duplicateGroups[i].files[j].size
                            success += 1
                        } catch {
                            failed += 1
                        }
                    }
                }
            }
            await scanDuplicates()
            
        case .similarPhotos:
            for i in 0..<similarPhotoGroups.count {
                for j in 0..<similarPhotoGroups[i].files.count {
                    if similarPhotoGroups[i].files[j].isSelected {
                        do {
                            try fileManager.trashItem(at: similarPhotoGroups[i].files[j].url, resultingItemURL: nil)
                            freedSize += similarPhotoGroups[i].files[j].size
                            success += 1
                        } catch {
                            failed += 1
                        }
                    }
                }
            }
            await scanSimilarPhotos()
            
        case .localizations:
            for file in localizationFiles where file.isSelected {
                do {
                    try fileManager.removeItem(at: file.url)
                    freedSize += file.size
                    success += 1
                } catch {
                    failed += 1
                }
            }
            await scanLocalizations()
            
        case .largeFiles:
            for file in largeFiles where file.isSelected {
                do {
                    try fileManager.trashItem(at: file.url, resultingItemURL: nil)
                    freedSize += file.size
                    success += 1
                } catch {
                    failed += 1
                }
            }
            await scanLargeFiles()
        }
        
        return (success, failed, freedSize)
    }
    
    // MARK: - 辅助方法
    
    private func md5Hash(of url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    private func extractImageFingerprint(from url: URL) async -> VNFeaturePrintObservation? {
        guard let image = NSImage(contentsOf: url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            return nil
        }
    }
    
    private func calculateSize(at url: URL) -> Int64 {
        var totalSize: Int64 = 0
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        return totalSize
    }
    
    // MARK: - 统计
    
    func selectedCount(for category: CleanerCategory) -> Int {
        switch category {
        case .duplicates:
            return duplicateGroups.flatMap { $0.files }.filter { $0.isSelected }.count
        case .similarPhotos:
            return similarPhotoGroups.flatMap { $0.files }.filter { $0.isSelected }.count
        case .localizations:
            return localizationFiles.filter { $0.isSelected }.count
        case .largeFiles:
            return largeFiles.filter { $0.isSelected }.count
        }
    }
    
    func selectedSize(for category: CleanerCategory) -> Int64 {
        switch category {
        case .duplicates:
            return duplicateGroups.flatMap { $0.files }.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
        case .similarPhotos:
            return similarPhotoGroups.flatMap { $0.files }.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
        case .localizations:
            return localizationFiles.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
        case .largeFiles:
            return largeFiles.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
        }
    }
    
    func totalWastedSize() -> Int64 {
        let duplicateWaste = duplicateGroups.reduce(0) { $0 + $1.wastedSize }
        let photoWaste = similarPhotoGroups.reduce(0) { $0 + $1.wastedSize }
        let locWaste = localizationFiles.reduce(0) { $0 + $1.size }
        return duplicateWaste + photoWaste + locWaste
    }
    
    // MARK: - 一键扫描所有
    func scanAll() async {
        await scanDuplicates()
        await scanSimilarPhotos()
        await scanLocalizations()
        await scanLargeFiles()
    }
    
    // MARK: - 一键清理所有
    func cleanAll() async -> (success: Int, failed: Int, size: Int64) {
        var totalSuccess = 0
        var totalFailed = 0
        var totalSize: Int64 = 0
        
        // 清理重复文件（保留每组的第一个）
        for i in 0..<duplicateGroups.count {
            for j in 1..<duplicateGroups[i].files.count { // 跳过第一个
                do {
                    try fileManager.trashItem(at: duplicateGroups[i].files[j].url, resultingItemURL: nil)
                    totalSize += duplicateGroups[i].files[j].size
                    totalSuccess += 1
                } catch {
                    totalFailed += 1
                }
            }
        }
        
        // 清理相似照片（保留每组的第一个）
        for i in 0..<similarPhotoGroups.count {
            for j in 1..<similarPhotoGroups[i].files.count {
                do {
                    try fileManager.trashItem(at: similarPhotoGroups[i].files[j].url, resultingItemURL: nil)
                    totalSize += similarPhotoGroups[i].files[j].size
                    totalSuccess += 1
                } catch {
                    totalFailed += 1
                }
            }
        }
        
        // 清理多语言文件
        for file in localizationFiles {
            do {
                try fileManager.removeItem(at: file.url)
                totalSize += file.size
                totalSuccess += 1
            } catch {
                totalFailed += 1
            }
        }
        
        // 刷新所有数据
        await MainActor.run {
            duplicateGroups = []
            similarPhotoGroups = []
            localizationFiles = []
        }
        
        return (totalSuccess, totalFailed, totalSize)
    }
    
    // MARK: - 全选/取消全选
    func selectAll(for category: CleanerCategory, selected: Bool) {
        switch category {
        case .duplicates:
            for i in 0..<duplicateGroups.count {
                for j in 0..<duplicateGroups[i].files.count {
                    duplicateGroups[i].files[j].isSelected = selected
                }
            }
        case .similarPhotos:
            for i in 0..<similarPhotoGroups.count {
                for j in 0..<similarPhotoGroups[i].files.count {
                    similarPhotoGroups[i].files[j].isSelected = selected
                }
            }
        case .localizations:
            for i in 0..<localizationFiles.count {
                localizationFiles[i].isSelected = selected
            }
        case .largeFiles:
            for i in 0..<largeFiles.count {
                largeFiles[i].isSelected = selected
            }
        }
    }
    
    // 总可清理大小
    var totalCleanableSize: Int64 {
        let dupSize = duplicateGroups.reduce(0) { $0 + $1.wastedSize }
        let photoSize = similarPhotoGroups.reduce(0) { $0 + $1.wastedSize }
        let locSize = localizationFiles.reduce(0) { $0 + $1.size }
        return dupSize + photoSize + locSize
    }
}
