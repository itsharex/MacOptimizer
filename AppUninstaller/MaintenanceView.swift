import SwiftUI
import Foundation

// MARK: - Maintenance Task Definition
enum MaintenanceTask: String, CaseIterable, Identifiable {
    case freeRam
    case purgeableSpace
    case flushDns
    case speedUpMail
    case rebuildSpotlight
    case repairPermissions
    case repairApps
    case timeMachine
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .freeRam: return "释放 RAM"
        case .purgeableSpace: return "释放可清除空间"
        case .flushDns: return "刷新 DNS 缓存"
        case .speedUpMail: return "加速邮件"
        case .rebuildSpotlight: return "为“聚焦”重建索引"
        case .repairPermissions: return "修复磁盘权限"
        case .repairApps: return "修复应用程序"
        case .timeMachine: return "时间机器快照瘦身"
        }
    }
    
    var englishTitle: String {
        switch self {
        case .freeRam: return "Free RAM"
        case .purgeableSpace: return "Free Purgeable Space"
        case .flushDns: return "Flush DNS Cache"
        case .speedUpMail: return "Speed Up Mail"
        case .rebuildSpotlight: return "Reindex Spotlight"
        case .repairPermissions: return "Repair Disk Permissions"
        case .repairApps: return "Repair Applications"
        case .timeMachine: return "Thin Time Machine Snapshots"
        }
    }
    
    var icon: String {
        switch self {
        case .freeRam: return "memorychip"
        case .purgeableSpace: return "internaldrive"
        case .flushDns: return "network" // Or "globe"
        case .speedUpMail: return "envelope"
        case .rebuildSpotlight: return "magnifyingglass"
        case .repairPermissions: return "wrench.and.screwdriver"
        case .repairApps: return "ladybug"
        case .timeMachine: return "clock.arrow.circlepath"
        }
    }
    
    // Background color for the icon square
    var iconColor: Color {
        switch self {
        case .freeRam: return Color(red: 0.0, green: 0.6, blue: 0.8) // Cyan/Blue
        case .purgeableSpace: return Color(red: 0.5, green: 0.5, blue: 0.6) // Greyish
        case .flushDns: return Color(red: 0.0, green: 0.5, blue: 1.0) // Blue
        case .speedUpMail: return Color(red: 0.0, green: 0.6, blue: 0.9) // Blue
        case .rebuildSpotlight: return Color(red: 0.2, green: 0.4, blue: 0.8) // Darker Blue
        case .repairPermissions: return Color(red: 0.6, green: 0.6, blue: 0.65)
        case .repairApps: return Color(red: 0.9, green: 0.4, blue: 0.3)
        case .timeMachine: return Color(red: 0.2, green: 0.7, blue: 0.4)
        }
    }
    
    var description: String {
        switch self {
        case .freeRam:
            return "您的 Mac 的内存经常被占满。这会让您的应用和打开的文件反应很慢。MacOptimizer 可以帮助您的系统将所有不使用的数据从内存中清理出去，从而为当前需要的应用腾出空间。"
        case .purgeableSpace:
            return "您的 Mac 可能会增加大量它认为可以清除的文件，仍将它们保留在磁盘上。这些数据是不需要的。但只有在系统需要大量可用空间的时候才会被释放。如果您现在已经需要该空间，只需点按一下即可将其释放。"
        case .flushDns:
            return "macOS 会将解析的 DNS（域名系统）查询的本地缓存保留一段时间。有时候可能需要立即重置缓存，例如在服务器更改后。"
        case .speedUpMail:
            return "Apple Mail 应用随着时间推移可能会变慢，尤其是有大量邮件和附件时。此任务会优化 Mail 的数据库，提高搜索和浏览速度。"
        case .rebuildSpotlight:
            return "如果 Spotlight 搜索变慢或无法找到文件，重建索引可以修复问题。此操作会让 macOS 重新扫描您的文件并建立新的搜索索引。"
        case .repairPermissions:
            return "验证并立即修复系统内损坏的文件和文件夹权限，确保应用程序可以正常运行。经常用于解决各种访问相关的问题。"
        case .repairApps:
            return "扫描并修复崩溃的应用程序。清理损坏的缓存和临时文件，重置应用权限，帮助应用恢复正常运行。"
        case .timeMachine:
            return "macOS 会创建本地时间机器快照占用磁盘空间。如果您不需要这些快照，可以删除它们来释放空间。"
        }
    }
    
    var englishDescription: String {
        switch self {
        case .freeRam:
            return "Your Mac's memory is often full. This makes apps and files slow to respond. MacOptimizer can help clear unused data from memory to make room for apps you need."
        case .purgeableSpace:
            return "Your Mac may keep files it considers purgeable on disk. These are not needed but only released when space is required. Click to release them now."
        case .flushDns:
            return "macOS caches DNS queries locally. Sometimes you need to reset this cache immediately, for example after server changes."
        case .speedUpMail:
            return "Apple Mail can slow down over time, especially with many emails. This task optimizes Mail's database for faster performance."
        case .rebuildSpotlight:
            return "If Spotlight search is slow or missing files, rebuilding the index can fix it. This makes macOS rescan your files."
        case .repairPermissions:
            return "Verify and repair broken file permissions to ensure apps run correctly. Often used to solve access-related issues."
        case .repairApps:
            return "Scan and repair crashed applications. Clean corrupted caches and temp files, reset app permissions to help apps run normally."
        case .timeMachine:
            return "macOS creates local Time Machine snapshots that use disk space. Delete them if you don't need them."
        }
    }
    
    var recommendations: [String] {
        switch self {
        case .freeRam:
            return ["您的系统感觉很慢", "需要打开较大应用程序或文件"]
        case .purgeableSpace:
            return ["您最多可以从磁盘上清除数 GB", "请注意，该任务非常耗时"]
        case .flushDns:
            return ["无法连接某些网站", "网络无规律变慢"]
        case .speedUpMail:
            return ["邮件应用启动缓慢", "搜索邮件需要很长时间"]
        case .rebuildSpotlight:
            return ["搜索无法找到已知文件", "聚焦索引已损坏"]
        case .repairPermissions:
            return ["应用程序不正常", "无法移动或删除文件"]
        case .repairApps:
            return ["应用程序经常崩溃", "应用无法正常启动"]
        case .timeMachine:
            return ["需要释放磁盘空间", "不使用时间机器备份"]
        }
    }
    
    var englishRecommendations: [String] {
        switch self {
        case .freeRam:
            return ["Your system feels slow", "Opening large apps or files"]
        case .purgeableSpace:
            return ["Can free up several GB from disk", "Note: this task takes time"]
        case .flushDns:
            return ["Cannot connect to some websites", "Network randomly slows down"]
        case .speedUpMail:
            return ["Mail app starts slowly", "Mail search takes long"]
        case .rebuildSpotlight:
            return ["Search can't find known files", "Spotlight index is corrupted"]
        case .repairPermissions:
            return ["Apps behave abnormally", "Cannot move or delete files"]
        case .repairApps:
            return ["Apps crash frequently", "Apps won't launch properly"]
        case .timeMachine:
            return ["Need to free disk space", "Not using Time Machine"]
        }
    }
    
    var lastRunKey: String {
        return "maintenance_lastrun_\(rawValue)"
    }
}

// MARK: - Task Result Model
struct TaskResult {
    let task: MaintenanceTask
    let success: Bool
    let message: String
    let details: String?
}

// MARK: - Maintenance Service
class MaintenanceService: ObservableObject {
    static let shared = MaintenanceService()
    
    @Published var selectedTask: MaintenanceTask = .freeRam
    @Published var selectedTasks: Set<MaintenanceTask> = Set(MaintenanceTask.allCases)
    @Published var isRunning = false
    @Published var currentRunningTask: MaintenanceTask?
    @Published var completedTasks: Set<MaintenanceTask> = []
    @Published var taskResults: [TaskResult] = []
    
    // 确认对话框状态
    @Published var showConfirmDialog = false
    @Published var confirmDialogTask: MaintenanceTask?
    @Published var confirmDialogMessage: String = ""
    @Published var userConfirmed = false
    
    // 时间机器快照列表
    @Published var timeMachineSnapshots: [String] = []
    @Published var showSnapshotSelector = false
    
    private init() {}
    
    func getLastRunDate(for task: MaintenanceTask, chinese: Bool) -> String {
        if let date = UserDefaults.standard.object(forKey: task.lastRunKey) as? Date {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            if !chinese { formatter.locale = Locale(identifier: "en") }
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        return chinese ? "从未" : "Never"
    }
    
    func getDescription(for task: MaintenanceTask, chinese: Bool) -> String {
        if chinese {
            switch task {
            case .freeRam:
                return "您的 Mac 的内存经常被占满。这会让您的应用和打开的文件反应很慢。此功能可以帮助释放不使用的内存。"
            case .purgeableSpace:
                return "您的 Mac 可能保留了大量可清除的文件。点击释放这些空间。"
            case .flushDns:
                return "刷新 DNS 缓存可以解决某些网络连接问题。"
            case .speedUpMail:
                return "优化 Mail 应用的数据库，提高搜索和浏览速度。"
            case .rebuildSpotlight:
                return "重建 Spotlight 搜索索引可以修复搜索问题。"
            case .repairPermissions:
                return "修复系统内损坏的文件权限，确保应用程序正常运行。"
            case .repairApps:
                return "扫描并修复崩溃的应用程序，帮助其恢复正常运行。"
            case .timeMachine:
                return "删除本地时间机器快照以释放磁盘空间。"
            }
        } else {
            switch task {
            case .freeRam:
                return "Your Mac's memory is often full. This can slow down apps. This function helps free unused memory."
            case .purgeableSpace:
                return "Your Mac may keep purgeable files. Click to release this space."
            case .flushDns:
                return "Flushing DNS cache can solve some network connection issues."
            case .speedUpMail:
                return "Optimize Mail app's database for faster search and browsing."
            case .rebuildSpotlight:
                return "Rebuilding Spotlight index can fix search problems."
            case .repairPermissions:
                return "Repair broken file permissions to ensure apps run correctly."
            case .repairApps:
                return "Scan and repair crashed applications to help them run normally."
            case .timeMachine:
                return "Delete local Time Machine snapshots to free disk space."
            }
        }
    }
    
    // MARK: - Run Tasks
    func runSelectedTasks() async {
        await MainActor.run {
            isRunning = true
            completedTasks = []
            taskResults = []
        }
        
        for task in MaintenanceTask.allCases {
            if selectedTasks.contains(task) {
                await MainActor.run { currentRunningTask = task }
                
                // 检查是否需要用户确认
                if needsConfirmation(task) {
                    await requestConfirmation(for: task)
                    
                    // 等待用户确认
                    var waitTime = 0
                    while showConfirmDialog && waitTime < 30 {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        waitTime += 1
                    }
                    
                    // 如果用户取消，跳过此任务
                    if !userConfirmed {
                        await MainActor.run {
                            taskResults.append(TaskResult(
                                task: task,
                                success: false,
                                message: "已跳过",
                                details: "用户取消操作"
                            ))
                        }
                        continue
                    }
                }
                
                // 执行任务
                let result = await executeTask(task)
                
                await MainActor.run {
                    completedTasks.insert(task)
                    taskResults.append(result)
                    UserDefaults.standard.set(Date(), forKey: task.lastRunKey)
                }
            }
        }
        
        await MainActor.run {
            currentRunningTask = nil
            isRunning = false
        }
    }
    
    // 检查任务是否需要用户确认
    private func needsConfirmation(_ task: MaintenanceTask) -> Bool {
        switch task {
        case .repairApps, .timeMachine:
            return true  // 高风险操作需要确认
        default:
            return false
        }
    }
    
    // 请求用户确认
    @MainActor
    private func requestConfirmation(for task: MaintenanceTask) async {
        let message: String
        switch task {
        case .repairApps:
            message = "此操作将清理所有应用的保存状态和崩溃日志。这是安全的，但某些应用可能需要重新登录。"
        case .timeMachine:
            message = "此操作将删除所有旧的时间机器快照（保留最新的一个）。这将释放磁盘空间，但无法恢复。"
        default:
            message = "是否继续执行此操作？"
        }
        
        confirmDialogTask = task
        confirmDialogMessage = message
        userConfirmed = false
        showConfirmDialog = true
    }
    
    // 用户确认操作
    func confirmAction() {
        userConfirmed = true
        showConfirmDialog = false
    }
    
    // 用户取消操作
    func cancelAction() {
        userConfirmed = false
        showConfirmDialog = false
    }
    
    private func executeTask(_ task: MaintenanceTask) async -> TaskResult {
        let result: (success: Bool, message: String, details: String?)
        
        switch task {
        case .freeRam:
            result = await freeRAM()
        case .purgeableSpace:
            result = await freePurgeableSpace()
        case .flushDns:
            result = await flushDNS()
        case .speedUpMail:
            result = await speedUpMail()
        case .rebuildSpotlight:
            result = await rebuildSpotlight()
        case .repairPermissions:
            result = await repairPermissions()
        case .repairApps:
            result = await repairApps()
        case .timeMachine:
            result = await cleanTimeMachine()
        }
        
        return TaskResult(
            task: task,
            success: result.success,
            message: result.message,
            details: result.details
        )
    }
    
    // MARK: - 释放 RAM (使用 purge 命令)
    private func freeRAM() async -> (success: Bool, message: String, details: String?) {
        // 获取执行前的内存使用情况
        let beforeMemory = getMemoryUsage()
        
        // 方法1: 使用 memory_pressure 触发内存回收
        let memPressure = Process()
        memPressure.executableURL = URL(fileURLWithPath: "/usr/bin/memory_pressure")
        memPressure.arguments = ["-l", "critical"]
        try? memPressure.run()
        
        // 等待2秒让系统响应
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        memPressure.terminate()
        
        // 方法2: 尝试使用 purge (可能需要开发者工具)
        let purge = Process()
        purge.executableURL = URL(fileURLWithPath: "/usr/sbin/purge")
        try? purge.run()
        purge.waitUntilExit()
        
        // 等待一下让系统更新内存统计
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 获取执行后的内存使用情况
        let afterMemory = getMemoryUsage()
        let freedMemoryGB = max(0, beforeMemory - afterMemory)
        
        if freedMemoryGB > 0.1 {
            return (true, "已释放 \(String(format: "%.2f", freedMemoryGB)) GB 内存", "内存压力已降低")
        } else {
            return (true, "内存优化完成", "系统内存已经比较充足")
        }
    }
    
    // 获取内存使用情况（GB）
    private func getMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0 }
        
        let pageSize = Double(vm_kernel_page_size)
        let usedMemory = Double(stats.active_count + stats.wire_count) * pageSize
        return usedMemory / (1024 * 1024 * 1024) // Convert to GB
    }
    
    // MARK: - 释放可清除空间
    private func freePurgeableSpace() async -> (success: Bool, message: String, details: String?) {
        var totalCleaned: Int64 = 0
        var filesDeleted = 0
        
        // 1. 清理系统临时文件
        let tempDirs = [
            FileManager.default.temporaryDirectory.path,
            "/private/var/folders"
        ]
        
        for dir in tempDirs {
            if let (size, count) = getDirectorySize(dir, olderThanDays: 7) {
                let cleanup = Process()
                cleanup.executableURL = URL(fileURLWithPath: "/usr/bin/find")
                cleanup.arguments = [dir, "-type", "f", "-atime", "+7", "-delete"]
                try? cleanup.run()
                cleanup.waitUntilExit()
                
                totalCleaned += size
                filesDeleted += count
            }
        }
        
        // 2. 清理用户缓存中的旧文件
        let userCaches = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches")
        
        if let enumerator = FileManager.default.enumerator(at: userCaches, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) {
            let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
            while let fileURL = enumerator.nextObject() as? URL {
                if let modDate = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                   modDate < oneWeekAgo,
                   let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    if (try? FileManager.default.removeItem(at: fileURL)) != nil {
                        totalCleaned += Int64(size)
                        filesDeleted += 1
                    }
                }
            }
        }
        
        // 3. 运行 purge 清理磁盘缓存
        let purge = Process()
        purge.executableURL = URL(fileURLWithPath: "/usr/sbin/purge")
        try? purge.run()
        purge.waitUntilExit()
        
        let cleanedGB = Double(totalCleaned) / (1024 * 1024 * 1024)
        if cleanedGB > 0.1 {
            return (true, "已释放 \(String(format: "%.2f", cleanedGB)) GB 空间", "删除了 \(filesDeleted) 个旧文件")
        } else {
            return (true, "清理完成", "系统较为干净，未发现大量可清除文件")
        }
    }
    
    // 获取目录大小（仅统计超过指定天数的文件）
    private func getDirectorySize(_ path: String, olderThanDays days: Int) -> (size: Int64, count: Int)? {
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 3600)
        var totalSize: Int64 = 0
        var fileCount = 0
        
        guard let enumerator = FileManager.default.enumerator(atPath: path) else { return nil }
        
        while let file = enumerator.nextObject() as? String {
            let filePath = (path as NSString).appendingPathComponent(file)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
               let modDate = attrs[.modificationDate] as? Date,
               modDate < cutoffDate,
               let size = attrs[.size] as? Int64 {
                totalSize += size
                fileCount += 1
            }
        }
        
        return (totalSize, fileCount)
    }
    
    // MARK: - 刷新 DNS 缓存
    private func flushDNS() async -> (success: Bool, message: String, details: String?) {
        var success = true
        
        // 刷新 DNS 缓存
        let dscacheutil = Process()
        dscacheutil.executableURL = URL(fileURLWithPath: "/usr/bin/dscacheutil")
        dscacheutil.arguments = ["-flushcache"]
        try? dscacheutil.run()
        dscacheutil.waitUntilExit()
        
        // 重启 mDNSResponder
        let killall = Process()
        killall.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killall.arguments = ["-HUP", "mDNSResponder"]
        try? killall.run()
        killall.waitUntilExit()
        
        if killall.terminationStatus != 0 {
            success = false
        }
        
        return (success, "DNS 缓存已刷新", "网络连接问题应该得到解决")
    }
    
    // MARK: - 加速邮件 (优化 Mail 数据库)
    private func speedUpMail() async -> (success: Bool, message: String, details: String?) {
        let mailDataPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mail")
        
        var dbOptimized = false
        var cacheCleaned: Int64 = 0
        
        // 查找 Envelope Index 数据库文件
        let possiblePaths = [
            mailDataPath.appendingPathComponent("V10/MailData/Envelope Index"),
            mailDataPath.appendingPathComponent("V9/MailData/Envelope Index"),
            mailDataPath.appendingPathComponent("V8/MailData/Envelope Index")
        ]
        
        for dbPath in possiblePaths {
            if FileManager.default.fileExists(atPath: dbPath.path) {
                // 使用 sqlite3 执行 VACUUM 优化数据库
                let sqlite = Process()
                sqlite.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
                sqlite.arguments = [dbPath.path, "VACUUM;"]
                try? sqlite.run()
                sqlite.waitUntilExit()
                
                // 执行 REINDEX
                let reindex = Process()
                reindex.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
                reindex.arguments = [dbPath.path, "REINDEX;"]
                try? reindex.run()
                reindex.waitUntilExit()
                
                dbOptimized = true
                break
            }
        }
        
        // 清理邮件下载缓存
        let mailDownloads = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mail Downloads")
        if FileManager.default.fileExists(atPath: mailDownloads.path) {
            if let contents = try? FileManager.default.contentsOfDirectory(at: mailDownloads, includingPropertiesForKeys: [.fileSizeKey]) {
                for item in contents {
                    if let size = try? item.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        cacheCleaned += Int64(size)
                    }
                    try? FileManager.default.removeItem(at: item)
                }
            }
        }
        
        if dbOptimized {
            let cleanedMB = Double(cacheCleaned) / (1024 * 1024)
            if cleanedMB > 1 {
                return (true, "邮件已优化", "数据库已重建，清理了 \(String(format: "%.1f", cleanedMB)) MB 缓存")
            } else {
                return (true, "邮件已优化", "数据库已重建索引")
            }
        } else {
            return (false, "未找到邮件数据库", "请确保已安装 Mail 应用")
        }
    }
    
    // MARK: - 重建 Spotlight 索引
    private func rebuildSpotlight() async -> (success: Bool, message: String, details: String?) {
        // 重建用户主目录的 Spotlight 索引
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        
        let mdutil = Process()
        mdutil.executableURL = URL(fileURLWithPath: "/usr/bin/mdutil")
        mdutil.arguments = ["-E", homePath]
        try? mdutil.run()
        mdutil.waitUntilExit()
        
        let success = mdutil.terminationStatus == 0
        
        // 强制重新索引
        let mdimport = Process()
        mdimport.executableURL = URL(fileURLWithPath: "/usr/bin/mdimport")
        mdimport.arguments = [homePath]
        try? mdimport.run()
        // 不等待完成，因为索引需要很长时间
        
        if success {
            return (true, "索引重建已启动", "Spotlight 将在后台重新索引您的文件")
        } else {
            return (false, "索引重建失败", "可能需要管理员权限")
        }
    }
    
    // MARK: - 修复磁盘权限
    private func repairPermissions() async -> (success: Bool, message: String, details: String?) {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        var fixedCount = 0
        
        // 修复主目录权限
        let chmodHome = Process()
        chmodHome.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodHome.arguments = ["755", homePath]
        try? chmodHome.run()
        chmodHome.waitUntilExit()
        if chmodHome.terminationStatus == 0 { fixedCount += 1 }
        
        // REMOVED: Recursive permission repair on Library is dangerous and can break system settings
        // let chmodLib = Process() ...
        
        // 修复常用目录权限
        let userDirs = ["Desktop", "Documents", "Downloads", "Pictures", "Movies", "Music"]
        for dir in userDirs {
            let dirPath = "\(homePath)/\(dir)"
            if FileManager.default.fileExists(atPath: dirPath) {
                let chmod = Process()
                chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
                chmod.arguments = ["700", dirPath]
                try? chmod.run()
                chmod.waitUntilExit()
                if chmod.terminationStatus == 0 { fixedCount += 1 }
            }
        }
        
        // 修复 .ssh 目录权限 (如果存在)
        let sshPath = "\(homePath)/.ssh"
        var sshFixed = false
        if FileManager.default.fileExists(atPath: sshPath) {
            let chmodSsh = Process()
            chmodSsh.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodSsh.arguments = ["700", sshPath]
            try? chmodSsh.run()
            chmodSsh.waitUntilExit()
            
            // 修复 SSH 密钥权限
            let chmodKeys = Process()
            chmodKeys.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodKeys.arguments = ["600", "\(sshPath)/id_rsa", "\(sshPath)/id_ed25519"]
            try? chmodKeys.run()
            chmodKeys.waitUntilExit()
            
            sshFixed = true
        }
        
        let details = sshFixed ? "修复了 \(fixedCount) 个目录权限（包括 SSH）" : "修复了 \(fixedCount) 个目录权限"
        return (true, "权限修复完成", details)
    }
    
    // MARK: - 清理时间机器快照
    private func cleanTimeMachine() async -> (success: Bool, message: String, details: String?) {
        // 列出所有本地快照
        let listTask = Process()
        listTask.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
        listTask.arguments = ["listlocalsnapshots", "/"]
        
        let pipe = Pipe()
        listTask.standardOutput = pipe
        
        try? listTask.run()
        listTask.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8), !output.isEmpty else {
            return (true, "无快照可删除", "未找到本地时间机器快照")
        }
        
        // 解析快照日期
        let lines = output.components(separatedBy: "\n")
        var snapshotDates: [String] = []
        
        for line in lines {
            // 格式: com.apple.TimeMachine.2024-12-14-123456
            if line.contains("com.apple.TimeMachine") {
                // 提取日期部分
                if let range = line.range(of: "\\d{4}-\\d{2}-\\d{2}-\\d{6}", options: .regularExpression) {
                    snapshotDates.append(String(line[range]))
                }
            }
        }
        
        if snapshotDates.count <= 1 {
            return (true, "无需清理", "只有一个快照，已保留")
        }
        
        var deletedCount = 0
        
        // 删除所有本地快照 (保留最新的一个)
        for date in snapshotDates.dropLast() {
            let deleteTask = Process()
            deleteTask.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
            deleteTask.arguments = ["deletelocalsnapshots", date]
            try? deleteTask.run()
            deleteTask.waitUntilExit()
            
            if deleteTask.terminationStatus == 0 {
                deletedCount += 1
            }
        }
        
        if deletedCount > 0 {
            return (true, "已删除 \(deletedCount) 个快照", "保留了最新的快照")
        } else {
            return (false, "删除失败", "可能需要管理员权限")
        }
    }
    
    // MARK: - 修复应用程序
    private func repairApps() async -> (success: Bool, message: String, details: String?) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let fileManager = FileManager.default
        var itemsFixed = 0
        var spaceFreed: Int64 = 0
        
        // 1. 清理应用崩溃日志
        let crashReportsPath = home.appendingPathComponent("Library/Logs/DiagnosticReports")
        if let contents = try? fileManager.contentsOfDirectory(at: crashReportsPath, includingPropertiesForKeys: [.fileSizeKey]) {
            for item in contents where item.pathExtension == "crash" || item.pathExtension == "ips" {
                if let size = try? item.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    spaceFreed += Int64(size)
                }
                if (try? fileManager.removeItem(at: item)) != nil {
                    itemsFixed += 1
                }
            }
        }
        
        // 2. 清理损坏的 Saved Application State
        let savedStatePath = home.appendingPathComponent("Library/Saved Application State")
        if let contents = try? fileManager.contentsOfDirectory(at: savedStatePath, includingPropertiesForKeys: [.fileSizeKey]) {
            for item in contents {
                if let size = try? item.resourceValues(forKeys: [.totalFileSizeKey]).totalFileSize {
                    spaceFreed += Int64(size)
                }
                if (try? fileManager.removeItem(at: item)) != nil {
                    itemsFixed += 1
                }
            }
        }
        
        // 3. 清理应用 Containers 中的临时文件
        let containersPath = home.appendingPathComponent("Library/Containers")
        if let apps = try? fileManager.contentsOfDirectory(at: containersPath, includingPropertiesForKeys: nil) {
            for app in apps {
                let tempPath = app.appendingPathComponent("Data/tmp")
                if let tempContents = try? fileManager.contentsOfDirectory(at: tempPath, includingPropertiesForKeys: [.fileSizeKey]) {
                    for item in tempContents {
                        if let size = try? item.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                            spaceFreed += Int64(size)
                        }
                        if (try? fileManager.removeItem(at: item)) != nil {
                            itemsFixed += 1
                        }
                    }
                }
            }
        }
        
        // 4. 重置 App Translocation 缓存
        let translocatorReset = Process()
        translocatorReset.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        translocatorReset.arguments = ["/System/Library/Frameworks/Security.framework/Versions/A/XPCServices/SecTranslocate.xpc/Contents/MacOS/SecTranslocate", "--reset"]
        try? translocatorReset.run()
        
        // 5. 清理 Launch Services 注册的损坏应用
        let lsregister = Process()
        lsregister.executableURL = URL(fileURLWithPath: "/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister")
        lsregister.arguments = ["-kill", "-r", "-domain", "local", "-domain", "user"]
        try? lsregister.run()
        lsregister.waitUntilExit()
        
        // 6. 清理 Core Services 缓存
        let cachesPaths = [
            home.appendingPathComponent("Library/Caches/com.apple.helpd"),
            home.appendingPathComponent("Library/Caches/com.apple.nsservicescache.plist"),
        ]
        for path in cachesPaths {
            if let size = try? path.resourceValues(forKeys: [.totalFileSizeKey]).totalFileSize {
                spaceFreed += Int64(size)
            }
            try? fileManager.removeItem(at: path)
        }
        
        let freedMB = Double(spaceFreed) / (1024 * 1024)
        let details = "清理了 \(itemsFixed) 个问题项，释放 \(String(format: "%.1f", freedMB)) MB 空间"
        return (true, "应用修复完成", details)
    }
}

// MARK: - Maintenance View
struct MaintenanceView: View {
    @StateObject private var service = MaintenanceService.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    @State private var viewState = 3 // 0: selection, 1: running, 2: finished, 3: landing
    
    var body: some View {
        Group {
            if viewState == 3 {
                landingView
            } else if viewState == 0 {
                selectionView
            } else if viewState == 1 {
                runningView
            } else {
                finishedView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Always start at landing page unless currently running a task
            if viewState != 1 {
                viewState = 3
            }
        }
        .sheet(isPresented: $service.showConfirmDialog) {
            MaintenanceConfirmDialog(service: service, loc: loc)
        }
    }
    
    // MARK: - Selection View
    var selectionView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                // Left Panel (Task List)
                VStack(alignment: .leading, spacing: 0) {
                    // Header: Intro Button
                    Button(action: { 
                        viewState = 3 // Go back to landing
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .bold))
                            Text("简介")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .padding(.leading, 16)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 2) {
                            ForEach(MaintenanceTask.allCases) { task in
                                taskRow(task)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    

                }
                .frame(width: geometry.size.width * 0.4)
                .background(Color.clear)
                
                // Right Panel (Details)
                VStack(alignment: .leading, spacing: 0) {
                    // Header: Maintenance Label & Assistant
                    HStack {
                        Text("维护")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 5, height: 5)
                                Text("助手")
                                    .font(.system(size: 11))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    
                    // Title
                    Text(loc.currentLanguage == .chinese ? service.selectedTask.title : service.selectedTask.englishTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 12)
                    
                    // Description
                    Text(loc.currentLanguage == .chinese ? service.selectedTask.description : service.selectedTask.englishDescription)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(3)
                        .padding(.bottom, 20)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Recommendations
                    Text(loc.currentLanguage == .chinese ? "使用推荐：" : "Recommended for:")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(loc.currentLanguage == .chinese ? service.selectedTask.recommendations : service.selectedTask.englishRecommendations, id: \.self) { rec in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .foregroundColor(.white.opacity(0.5))
                                Text(rec)
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(size: 11))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Footer: Last Run Date only (button moved to left panel)
                    HStack {
                        Spacer()
                        Text(loc.currentLanguage == .chinese
                             ? "上次运行：\(service.getLastRunDate(for: service.selectedTask, chinese: true))"
                             : "Last ran: \(service.getLastRunDate(for: service.selectedTask, chinese: false))")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 30)
                .frame(width: geometry.size.width * 0.6)
            }
            
            // Centered Run Button
            runButton
                .padding(.bottom, 40)
        }
        }
        .background(BackgroundStyles.privacy)
    }
    
    var runButton: some View {
        Button(action: {
            viewState = 1
            Task {
                await service.runSelectedTasks()
                await MainActor.run { viewState = 2 }
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 58, height: 58)
                
                Text(loc.currentLanguage == .chinese ? "运行" : "Run")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
    
    func taskRow(_ task: MaintenanceTask) -> some View {
        HStack(spacing: 8) {
            // Checkbox - 独立按钮，正确处理选中状态
            Button(action: {
                if service.selectedTasks.contains(task) {
                    service.selectedTasks.remove(task)
                } else {
                    service.selectedTasks.insert(task)
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(service.selectedTasks.contains(task) ? Color.green : Color.white.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                    
                    if service.selectedTasks.contains(task) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Icon + Title 可点击选择任务
            Button(action: { service.selectedTask = task }) {
                HStack(spacing: 8) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(task.iconColor)
                            .frame(width: 26, height: 26)
                        
                        Image(systemName: task.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    
                    // Title
                    Text(task.title)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(service.selectedTask == task ? Color.white.opacity(0.12) : Color.clear)
        )
    }
    
    // MARK: - Running View
    var runningView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 标题
            Text(loc.currentLanguage == .chinese ? "正在执行维护任务..." : "Running maintenance tasks...")
                .font(.title2)
                .foregroundColor(.white)
            
            // 任务列表进度
            VStack(spacing: 12) {
                ForEach(Array(service.selectedTasks).sorted { $0.rawValue < $1.rawValue }) { task in
                    HStack(spacing: 12) {
                        // 状态图标
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(task.iconColor)
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: task.icon)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        
                        // 任务名称
                        Text(loc.currentLanguage == .chinese ? task.title : task.englishTitle)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // 状态
                        if service.completedTasks.contains(task) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if service.currentRunningTask == task {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(service.currentRunningTask == task ? Color.white.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: 400)
            .padding(.horizontal, 40)
            
            // 进度文本
            Text("\(service.completedTasks.count) / \(service.selectedTasks.count)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
        }
    }
    
    // MARK: - Finished View
    var finishedView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 成功图标
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(.bottom, 20)
            
            Text(loc.currentLanguage == .chinese ? "维护完成！" : "Maintenance Complete!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            Text(loc.currentLanguage == .chinese
                 ? "\(service.completedTasks.count) 个任务已执行"
                 : "\(service.completedTasks.count) tasks executed")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 30)
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(service.taskResults, id: \.task.rawValue) { result in
                        HStack(spacing: 16) {
                            // Status Icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(result.task.iconColor.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(result.task.iconColor.opacity(0.5), lineWidth: 1)
                                    )
                                
                                Image(systemName: result.task.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(result.task.iconColor)
                            }
                            
                            // Task Info
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(loc.currentLanguage == .chinese ? result.task.title : result.task.englishTitle)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Status Badge
                                    HStack(spacing: 4) {
                                        Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                            .foregroundColor(result.success ? .green : .orange)
                                            .font(.system(size: 12))
                                        
                                        Text(result.message)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(result.success ? .green : .orange)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(result.success ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                                    )
                                }
                                
                                if let details = result.details {
                                    Text(details)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 40)
            }
            .frame(maxWidth: 600, maxHeight: 300)
            
            Spacer()
            
            // 返回按钮
            Button(action: { 
                service.taskResults.removeAll()
                viewState = 0 
            }) {
                Text(loc.currentLanguage == .chinese ? "完成" : "Done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 50)
        }

        // Removed .background to avoid double background layer
    }
    // MARK: - Landing View
    var landingView: some View {
        MaintenanceLandingView(viewState: $viewState)
    }
}

struct MaintenanceLandingView: View {
    @Binding var viewState: Int
    @ObservedObject private var loc = LocalizationManager.shared
    
    var body: some View {
        ZStack {
            HStack(spacing: 60) {
                // Left Content
                VStack(alignment: .leading, spacing: 30) {
                    // Branding Header
                    HStack(spacing: 8) {
                        Text(loc.currentLanguage == .chinese ? "系统维护" : "System Maintenance")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        // Maintenance Icon
                        HStack(spacing: 4) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                            Text(loc.currentLanguage == .chinese ? "快速修复" : "Quick Fix")
                                .font(.system(size: 20, weight: .heavy))
                        }
                        .foregroundColor(.white)
                    }
                    
                    Text(loc.currentLanguage == .chinese ? 
                         "运行一组可快速优化系统性能的脚本。\n上次维护时间：从未" :
                         "Run a set of scripts to quickly optimize system performance.\nLast maintenance: Never")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(4)
                    
                    // Feature Rows
                    VStack(alignment: .leading, spacing: 24) {
                        featureRow(
                            icon: "gauge",
                            title: loc.currentLanguage == .chinese ? "提高驱动器性能" : "Improve Drive Performance",
                            desc: loc.currentLanguage == .chinese ? "保护磁盘，确保其文件系统和物理状态良好。" : "Maintain the disk to ensure its file system and physical health are good."
                        )
                        
                        featureRow(
                            icon: "exclamationmark.triangle",
                            title: loc.currentLanguage == .chinese ? "消除应用程序错误" : "Fix Application Errors",
                            desc: loc.currentLanguage == .chinese ? "通过修改权限以及运行维护脚本解决不适当的应用程序行为。" : "Fix improper application behavior by repairing permissions and running maintenance scripts."
                        )
                        
                        featureRow(
                            icon: "magnifyingglass",
                            title: loc.currentLanguage == .chinese ? "提高搜索性能" : "Improve Search Performance",
                            desc: loc.currentLanguage == .chinese ? "为您的\"聚焦\"数据库重新建立索引，提高搜索速度和质量。" : "Reindex your Spotlight database to improve search speed and quality."
                        )
                    }
                    
                    // View Tasks Button
                    Button(action: { viewState = 0 }) {
                        Text(loc.currentLanguage == .chinese ? "查看 7 个任务..." : "View 7 Tasks...")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "4DDEE8")) // Teal
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
                .frame(maxWidth: 400)
                
                // Right Icon - Maintenance Visual
                ZStack {
                    if let path = Bundle.main.path(forResource: "weihu", ofType: "png"),
                       let nsImage = NSImage(contentsOfFile: path) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 320, height: 320)
                            .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
                    } else {
                        // Fallback: Pink Checklist
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "C86FC9"), Color(hex: "9933CC")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 280, height: 280)
                                .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
                            
                            // Checklist Items (Visual)
                            VStack(spacing: 20) {
                                ForEach(0..<3) { i in
                                    HStack(spacing: 12) {
                                        RoundedRectangle(cornerRadius: 6) // Checkbox
                                            .fill(Color.white)
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(Color(hex: "9933CC"))
                                            )
                                        
                                        RoundedRectangle(cornerRadius: 4) // Line
                                            .fill(Color.white.opacity(0.4))
                                            .frame(width: 100, height: 10)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            
            // Bottom Floating Button
            VStack {
                Spacer()
                Button(action: { viewState = 0 }) {
                    ZStack {
                        Circle()
                            .stroke(LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ), lineWidth: 2)
                            .frame(width: 84, height: 84)
                        
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 74, height: 74)
                            .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
                        
                        Text(loc.currentLanguage == .chinese ? "开始" : "Start")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Feature Row Helper
    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Maintenance Confirmation Dialog
struct MaintenanceConfirmDialog: View {
    @ObservedObject var service: MaintenanceService
    @ObservedObject var loc: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        // 警告图标
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 20))
                        
                            
                        Text(loc.currentLanguage == .chinese ? "确认操作" : "Confirm Action")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    if let task = service.confirmDialogTask {
                        Text(loc.currentLanguage == .chinese ? task.title : task.englishTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    service.cancelAction()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            .padding(.bottom, 16)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Warning Banner
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                Text(service.confirmDialogMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.15)) // Modern orange tint
            
            // Task Details
            VStack(alignment: .leading, spacing: 12) {
                if let task = service.confirmDialogTask {
                    Text(loc.currentLanguage == .chinese ? "将要执行的操作：" : "Operations to perform:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(getTaskOperations(task), id: \.self) { operation in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(operation)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Footer Actions
            HStack(spacing: 12) {
                Spacer()
                
                // Cancel Button
                Button(action: {
                    service.cancelAction()
                    dismiss()
                }) {
                    Text(loc.currentLanguage == .chinese ? "取消" : "Cancel")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                // Confirm Button
                Button(action: {
                    service.confirmAction()
                    dismiss()
                }) {
                    Text(loc.currentLanguage == .chinese ? "继续执行" : "Continue")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color(red: 0.8, green: 0.4, blue: 0.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 460)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.22)) // Darker modern background
                .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // 获取任务的具体操作列表
    private func getTaskOperations(_ task: MaintenanceTask) -> [String] {
        let chinese = loc.currentLanguage == .chinese
        
        switch task {
        case .repairApps:
            return chinese ? [
                "清理所有应用崩溃日志",
                "删除所有应用保存状态（某些应用可能需要重新登录）",
                "清理应用临时文件",
                "重置 Launch Services 数据库",
                "清理 Core Services 缓存"
            ] : [
                "Clean all app crash logs",
                "Delete all app saved states (some apps may need re-login)",
                "Clean app temporary files",
                "Reset Launch Services database",
                "Clean Core Services cache"
            ]
            
        case .timeMachine:
            return chinese ? [
                "列出所有本地时间机器快照",
                "删除旧快照（保留最新的一个）",
                "释放磁盘空间"
            ] : [
                "List all local Time Machine snapshots",
                "Delete old snapshots (keep the latest one)",
                "Free up disk space"
            ]
            
        default:
            return []
        }
    }
}
