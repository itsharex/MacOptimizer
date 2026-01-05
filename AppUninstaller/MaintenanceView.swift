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

// MARK: - Maintenance Service
class MaintenanceService: ObservableObject {
    static let shared = MaintenanceService()
    
    @Published var selectedTask: MaintenanceTask = .freeRam
    @Published var selectedTasks: Set<MaintenanceTask> = Set(MaintenanceTask.allCases)
    @Published var isRunning = false
    @Published var currentRunningTask: MaintenanceTask?
    @Published var completedTasks: Set<MaintenanceTask> = []
    
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
        }
        
        for task in MaintenanceTask.allCases {
            if selectedTasks.contains(task) {
                await MainActor.run { currentRunningTask = task }
                await executeTask(task)
                await MainActor.run {
                    completedTasks.insert(task)
                    UserDefaults.standard.set(Date(), forKey: task.lastRunKey)
                }
            }
        }
        
        await MainActor.run {
            currentRunningTask = nil
            isRunning = false
        }
    }
    
    private func executeTask(_ task: MaintenanceTask) async {
        switch task {
        case .freeRam:
            await freeRAM()
        case .purgeableSpace:
            await freePurgeableSpace()
        case .flushDns:
            await flushDNS()
        case .speedUpMail:
            await speedUpMail()
        case .rebuildSpotlight:
            await rebuildSpotlight()
        case .repairPermissions:
            await repairPermissions()
        case .repairApps:
            await repairApps()
        case .timeMachine:
            await cleanTimeMachine()
        }
    }
    
    // MARK: - 释放 RAM (使用 purge 命令)
    private func freeRAM() async {
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
    }
    
    // MARK: - 释放可清除空间
    private func freePurgeableSpace() async {
        // 1. 清理系统临时文件
        let tempDirs = [
            FileManager.default.temporaryDirectory.path,
            "/private/var/folders"
        ]
        
        for dir in tempDirs {
            let cleanup = Process()
            cleanup.executableURL = URL(fileURLWithPath: "/usr/bin/find")
            cleanup.arguments = [dir, "-type", "f", "-atime", "+7", "-delete"]
            try? cleanup.run()
            cleanup.waitUntilExit()
        }
        
        // 2. 清理用户缓存中的旧文件
        let userCaches = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches")
        
        if let enumerator = FileManager.default.enumerator(at: userCaches, includingPropertiesForKeys: [.contentModificationDateKey]) {
            let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
            while let fileURL = enumerator.nextObject() as? URL {
                if let modDate = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                   modDate < oneWeekAgo {
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
        }
        
        // 3. 运行 purge 清理磁盘缓存
        let purge = Process()
        purge.executableURL = URL(fileURLWithPath: "/usr/sbin/purge")
        try? purge.run()
        purge.waitUntilExit()
    }
    
    // MARK: - 刷新 DNS 缓存
    private func flushDNS() async {
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
        
        // 额外: 清理 lookupd 缓存
        let lookupd = Process()
        lookupd.executableURL = URL(fileURLWithPath: "/usr/bin/dscacheutil")
        lookupd.arguments = ["-flushcache"]
        try? lookupd.run()
        lookupd.waitUntilExit()
    }
    
    // MARK: - 加速邮件 (优化 Mail 数据库)
    private func speedUpMail() async {
        let mailDataPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mail")
        
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
                
                break
            }
        }
        
        // 清理邮件下载缓存
        let mailDownloads = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mail Downloads")
        if FileManager.default.fileExists(atPath: mailDownloads.path) {
            if let contents = try? FileManager.default.contentsOfDirectory(at: mailDownloads, includingPropertiesForKeys: nil) {
                for item in contents {
                    try? FileManager.default.removeItem(at: item)
                }
            }
        }
    }
    
    // MARK: - 重建 Spotlight 索引
    private func rebuildSpotlight() async {
        // 重建用户主目录的 Spotlight 索引
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        
        let mdutil = Process()
        mdutil.executableURL = URL(fileURLWithPath: "/usr/bin/mdutil")
        mdutil.arguments = ["-E", homePath]
        try? mdutil.run()
        mdutil.waitUntilExit()
        
        // 强制重新索引
        let mdimport = Process()
        mdimport.executableURL = URL(fileURLWithPath: "/usr/bin/mdimport")
        mdimport.arguments = [homePath]
        try? mdimport.run()
        // 不等待完成，因为索引需要很长时间
    }
    
    // MARK: - 修复磁盘权限
    private func repairPermissions() async {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        
        // 修复主目录权限
        let chmodHome = Process()
        chmodHome.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodHome.arguments = ["755", homePath]
        try? chmodHome.run()
        chmodHome.waitUntilExit()
        
        // 修复 Library 目录权限
        let chmodLib = Process()
        chmodLib.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodLib.arguments = ["-R", "u+rwX", "\(homePath)/Library"]
        try? chmodLib.run()
        chmodLib.waitUntilExit()
        
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
            }
        }
        
        // 修复 .ssh 目录权限 (如果存在)
        let sshPath = "\(homePath)/.ssh"
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
        }
    }
    
    // MARK: - 清理时间机器快照
    private func cleanTimeMachine() async {
        // 列出所有本地快照
        let listTask = Process()
        listTask.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
        listTask.arguments = ["listlocalsnapshots", "/"]
        
        let pipe = Pipe()
        listTask.standardOutput = pipe
        
        try? listTask.run()
        listTask.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return }
        
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
        
        // 删除所有本地快照 (保留最新的一个)
        for date in snapshotDates.dropLast() {
            let deleteTask = Process()
            deleteTask.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
            deleteTask.arguments = ["deletelocalsnapshots", date]
            try? deleteTask.run()
            deleteTask.waitUntilExit()
        }
    }
    
    // MARK: - 修复应用程序
    private func repairApps() async {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let fileManager = FileManager.default
        
        // 1. 清理应用崩溃日志
        let crashReportsPath = home.appendingPathComponent("Library/Logs/DiagnosticReports")
        if let contents = try? fileManager.contentsOfDirectory(at: crashReportsPath, includingPropertiesForKeys: nil) {
            for item in contents where item.pathExtension == "crash" || item.pathExtension == "ips" {
                try? fileManager.removeItem(at: item)
            }
        }
        
        // 2. 清理损坏的 Saved Application State
        let savedStatePath = home.appendingPathComponent("Library/Saved Application State")
        if let contents = try? fileManager.contentsOfDirectory(at: savedStatePath, includingPropertiesForKeys: nil) {
            for item in contents {
                try? fileManager.removeItem(at: item)
            }
        }
        
        // 3. 清理应用 Containers 中的临时文件
        let containersPath = home.appendingPathComponent("Library/Containers")
        if let apps = try? fileManager.contentsOfDirectory(at: containersPath, includingPropertiesForKeys: nil) {
            for app in apps {
                let tempPath = app.appendingPathComponent("Data/tmp")
                if let tempContents = try? fileManager.contentsOfDirectory(at: tempPath, includingPropertiesForKeys: nil) {
                    for item in tempContents {
                        try? fileManager.removeItem(at: item)
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
            try? fileManager.removeItem(at: path)
        }
        
        print("[repairApps] Crash logs cleaned, saved states cleared, Launch Services reset")
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
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.green)
            }
            
            Text(loc.currentLanguage == .chinese ? "完成！" : "Done!")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(loc.currentLanguage == .chinese
                     ? "\(service.completedTasks.count) 个任务已完成"
                     : "\(service.completedTasks.count) tasks completed")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: { viewState = 0 }) {
                Text(loc.currentLanguage == .chinese ? "返回" : "Back")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 50)
        }
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
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Content
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(loc.currentLanguage == .chinese ? "维护" : "Maintenance")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(loc.currentLanguage == .chinese ? "运行一组可快速优化系统性能的脚本。" : "Run a set of scripts to quickly optimize system performance.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        ShredderFeatureRow(icon: "gauge", title: loc.currentLanguage == .chinese ? "提高驱动器性能" : "Improve Drive Performance", description: loc.currentLanguage == .chinese ? "保护磁盘，确保其文件系统和物理状态良好。" : "Maintain the disk to ensure its file system and physical health are good.")
                        ShredderFeatureRow(icon: "exclamationmark.triangle", title: loc.currentLanguage == .chinese ? "消除应用程序错误" : "Fix Application Errors", description: loc.currentLanguage == .chinese ? "通过修改权限以及运行维护脚本解决不适当的应用程序行为。" : "Fix improper application behavior by repairing permissions and running maintenance scripts.")
                        ShredderFeatureRow(icon: "magnifyingglass", title: loc.currentLanguage == .chinese ? "提高搜索性能" : "Improve Search Performance", description: loc.currentLanguage == .chinese ? "为您的“聚焦”数据库重新建立索引，提高搜索速度和质量。" : "Reindex your Spotlight database to improve search speed and quality.")
                    }
                    
                    Button(action: { viewState = 0 }) {
                        Text(loc.currentLanguage == .chinese ? "查看 7 个任务..." : "View 7 Tasks...")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.blue) // Use Blue button
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .shadow(radius: 5)
                }
                .frame(maxWidth: 400)
                .padding(.leading, 60)
                
                Spacer()
                
                // Right Icon (Pink Checklist)
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.8, green: 0.4, blue: 0.7), Color(red: 0.6, green: 0.2, blue: 0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 300, height: 350)
                        .rotationEffect(.degrees(-8))
                        .shadow(radius: 20)
                    
                    // Checklist Items (Visual)
                    VStack(spacing: 25) {
                        ForEach(0..<3) { i in
                            HStack(spacing: 15) {
                                RoundedRectangle(cornerRadius: 8) // Checkbox
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                                    )
                                
                                RoundedRectangle(cornerRadius: 6) // Line
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 140, height: 12)
                            }
                        }
                    }
                    .rotationEffect(.degrees(-8))
                    
                    // Wrench
                    Image(systemName: "wrench.navigational.fill") // or wrench.adjustable
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                        .offset(x: 100, y: 100)
                }
                .padding(.trailing, 60)
            }
        }
        .background(BackgroundStyles.privacy)
    }
}
