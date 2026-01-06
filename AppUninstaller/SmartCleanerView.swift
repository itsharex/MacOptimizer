import SwiftUI

// 扫描状态枚举
enum ScanState {
    case initial    // 初始页面
    case scanning   // 扫描中
    case cleaning   // 清理中
    case completed  // 扫描完成（结果页）
    case finished   // 清理完成（最终页）
}

struct SmartCleanerView: View {
    // 导航绑定 - 用于跳转到其他页面
    @Binding var selectedModule: AppModule
    
    // 使用共享的服务管理器
    @ObservedObject private var service = ScanServiceManager.shared.smartCleanerService
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var selectedCategory: CleanerCategory = .systemJunk
    @State private var showDeleteConfirmation = false
    @State private var deleteResult: (success: Int, failed: Int, size: Int64)?
    @State private var showResult = false
    @State private var showCleaningFinished = false
    @State private var showRunningAppsSafetyAlert = false
    
    // 管理员权限重试
    @State private var failedFiles: [CleanerFileItem] = []
    @State private var showRetryWithAdmin = false
    
    // Detail Sheet State
    @State private var showDetailSheet = false
    @State private var initialDetailCategory: CleanerCategory? = nil
    
    // 扫描状态
    private var scanState: ScanState {
        if service.isScanning {
            return .scanning
        } else if service.isCleaning {
            // cleaningPage UI is simpler, we can reuse simplified scanning layout or keeping it
            return .cleaning
        } else if showRetryWithAdmin {
            return .cleaning 
        } else if showCleaningFinished {
            return .finished
        } else if hasScanResults {
            return .completed
        }
        return .initial
    }
    
    // 计算属性：检查 service 是否已有扫描结果
    private var hasScanResults: Bool {
        return service.systemJunkTotalSize > 0 ||
               !service.duplicateGroups.isEmpty ||
               !service.similarPhotoGroups.isEmpty ||
               !service.largeFiles.isEmpty ||
               !service.userCacheFiles.isEmpty ||
               !service.systemCacheFiles.isEmpty ||
               !service.virusThreats.isEmpty ||
               service.hasAppUpdates ||
               !service.startupItems.isEmpty ||
               !service.performanceApps.isEmpty
    }

    // 计算扫描到的总大小
    private var totalScannedSize: Int64 {
        let topLevelCategories: [CleanerCategory] = [
            .systemJunk, .duplicates, .similarPhotos, .largeFiles, .virus
        ]
        return topLevelCategories.reduce(0) { $0 + service.sizeFor(category: $1) }
    }
    
    var body: some View {
        ZStack {
            // 背景 - 匹配设计图的紫靛色渐变
            BackgroundStyles.smartClean
                .ignoresSafeArea()
            
            // Main Content
            VStack {
                 // Header
                 headerView
                 
                 // Dynamic Content
                 switch scanState {
                 case .initial:
                     initialPage
                 case .scanning:
                     scanningPage
                 case .completed:
                     resultsPage
                 case .cleaning:
                     cleaningPage
                 case .finished:
                     cleaningFinishedPage
                 }
            }
            .padding(.bottom, 100) // Increase padding to avoid button overlap

            // Floating Main Action Button
            VStack {
                Spacer()
                mainActionButton
                    .padding(.bottom, 30) // Raise button to be fully visible
            }
        }
        // Sheet for details
        .sheet(isPresented: $showDetailSheet) {
            AllCategoriesDetailSheet(
                service: service,
                loc: loc,
                isPresented: $showDetailSheet,
                initialCategory: initialDetailCategory
            )
        }
        // Alerts & Confirmations ... (Keeping existing logic)
        .confirmationDialog(
            loc.currentLanguage == .chinese ? "确认删除" : "Confirm Delete",
            isPresented: $showDeleteConfirmation
        ) {
            Button(loc.currentLanguage == .chinese ? "开始清理" : "Start Cleaning", role: .destructive) {
                Task {
                    let result = await service.cleanAll()
                    deleteResult = (result.success, result.failed, result.size)
                    failedFiles = result.failedFiles
                    if result.failed > 0 && !failedFiles.isEmpty {
                        showRetryWithAdmin = true
                    } else {
                        showCleaningFinished = true
                    }
                }
            }
            Button(loc.L("cancel"), role: .cancel) {}
        } message: {
            Text(loc.currentLanguage == .chinese ? "将清理所有选中的垃圾文件，释放空间。" : "Clean all selected files to free up space.")
        }
        .alert(loc.currentLanguage == .chinese ? "部分文件需要管理员权限" : "Some Files Require Admin Privileges", isPresented: $showRetryWithAdmin) {
             Button(loc.currentLanguage == .chinese ? "使用管理员权限删除" : "Delete with Admin", role: .destructive) {
                 Task {
                     let adminResult = await service.cleanWithPrivileges(files: failedFiles)
                     if let currentResult = deleteResult {
                         deleteResult = (
                             currentResult.success + adminResult.success,
                             adminResult.failed,
                             currentResult.size + adminResult.size
                         )
                     }
                     failedFiles = []
                     showCleaningFinished = true
                 }
             }
             Button(loc.L("cancel"), role: .cancel) { showCleaningFinished = true }
        } message: {

            Text(loc.currentLanguage == .chinese ?
                 "有 \(failedFiles.count) 个文件因权限不足无法删除。" :
                 "\(failedFiles.count) files could not be deleted due to permissions.")
        }
        .alert(loc.currentLanguage == .chinese ? "重要提示：正在运行的应用" : "Important: Running Applications", isPresented: $showRunningAppsSafetyAlert) {
            Button(loc.currentLanguage == .chinese ? "确认并继续" : "Confirm and Continue", role: .destructive) {
                showDeleteConfirmation = true
            }
            Button(loc.L("cancel"), role: .cancel) {}
        } message: {
            Text(loc.currentLanguage == .chinese ?
                 "检测到您已勾选正在运行的应用。关闭它们可能会导致未保存的数据丢失。确认要继续吗？" :
                 "Running applications are selected to be closed. This may cause loss of unsaved data. Do you want to continue?")
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            if scanState == .completed || scanState == .finished {
                Button(action: { Task { service.resetAll() } }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text(loc.currentLanguage == .chinese ? "重新开始" : "Start Over")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Center Title
             Text(loc.currentLanguage == .chinese ? "智能扫描" : "Smart Scan")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            
            // Right Action -  removed helper/rescan button
            // Placeholder to balance layout
            Text("           ").opacity(0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }
    
    // MARK: - Initial Page (Ready State)
    private var initialPage: some View {
        VStack {
            Spacer()
            
            // 核心图标区域 - 匹配设计图（无圆圈光晕）
            ZStack {
                // 显示器主图标 - 使用自定义图片
                if let imagePath = Bundle.main.path(forResource: "resubscribe_welcome@2x", ofType: "png"),
                   let nsImage = NSImage(contentsOfFile: imagePath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 360, height: 360)
                        .shadow(color: Color.pink.opacity(0.2), radius: 20, x: 0, y: 8)
                } else {
                    // 备用：使用应用图标
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 260, height: 260)
                        .shadow(color: Color.pink.opacity(0.2), radius: 20, x: 0, y: 8)
                }
            }
            .padding(.bottom, 60)
            
            VStack(spacing: 12) {
                Text(loc.currentLanguage == .chinese ? "欢迎使用 Mac优化大师" : "Welcome to MacOptimizer")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundColor(.white)
                
                Text(loc.currentLanguage == .chinese ? "开始全面、仔细扫描您的 Mac。" : "Start a comprehensive and thorough scan of your Mac.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 100)
            
            Spacer()
        }
    }

    // MARK: - Scanning Page (3-Column Layout)
    private var scanningPage: some View {
        VStack {
            // Title & Subtitle for Scanning - Added per user request
            VStack(spacing: 12) {
                Text(loc.currentLanguage == .chinese ? "正在查看它..." : "Checking it...")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                
                Text(loc.currentLanguage == .chinese ? "稍等片刻。我们都希望它易如反掌。" : "Just a moment. We hope it's effortless.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
            
            threeColumnLayout(state: .scanning)
            
            Spacer()
        }
    }
    
    // MARK: - Results Page (3-Column Layout)
    private var resultsPage: some View {
        VStack {
            // Title & Subtitle for Results
            VStack(spacing: 12) {
                Text(loc.currentLanguage == .chinese ? "好了，我发现的内容都在这里。" : "Okay, here's what I found.")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                
                Text(loc.currentLanguage == .chinese ? "保持您的 Mac 干净、安全、性能优化的所有任务正在等候。立即运行！" : "All tasks to keep your Mac clean, safe, and optimized are waiting. Run now!")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
            
            threeColumnLayout(state: .completed)
            
            Spacer()
        }
    }
    
    // MARK: - Cleaning/Finished Pages
    private var cleaningPage: some View {
        VStack {
            threeColumnLayout(state: .cleaning)
            
            Spacer()
            
            // Progress
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text(loc.currentLanguage == .chinese ? "正在清理中..." : "Cleaning in progress...")
                    .font(.caption) .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 40)
        }
    }
    
    private var cleaningFinishedPage: some View {
        VStack {
            threeColumnLayout(state: .finished)
            Spacer()
            // Main Button handles the "Back" or "Done" action via mainActionButton
        }
    }

    // MARK: - 3-Column Layout Implementation
    private func threeColumnLayout(state: ScanState) -> some View {
        HStack(spacing: 40) {
            // 1. Cleanup Group
            itemColumn(
                title: loc.currentLanguage == .chinese ? "清理" : "Cleanup",
                iconName: "clean-up.866fafd0",
                description: state == .scanning ? (loc.currentLanguage == .chinese ? "正在查找不需要的文件..." : "Searching for unwanted files...") : (loc.currentLanguage == .chinese ? "移除不需要的垃圾" : "Remove unwanted junk"),
                categories: [.systemJunk, .duplicates, .similarPhotos, .largeFiles, .appUpdates],
                state: state,
                color: Color(red: 0.1, green: 0.6, blue: 0.9), // Blue
                currentPath: (service.isScanning && [.systemJunk, .duplicates, .similarPhotos, .largeFiles, .appUpdates].contains(service.currentCategory)) ? service.currentScanPath : nil
            )
            
            // 2. Protection Group
            itemColumn(
                title: loc.currentLanguage == .chinese ? "保护" : "Protection",
                iconName: "protection.80f7790f",
                description: state == .scanning ? (loc.currentLanguage == .chinese ? "正在确定潜在威胁..." : "Determining potential threats...") : (loc.currentLanguage == .chinese ? "消除潜在威胁" : "Eliminate potential threats"),
                categories: [.virus],
                state: state,
                color: Color(red: 0.2, green: 0.8, blue: 0.5), // Green
                currentPath: (service.isScanning && service.currentCategory == .virus) ? service.currentScanPath : nil
            )
            
            // 3. Speed Group
            itemColumn(
                title: loc.currentLanguage == .chinese ? "速度" : "Speed",
                iconName: "smart-scan.2f4ddf59", // Speedometer
                description: state == .scanning ? (loc.currentLanguage == .chinese ? "定义合适的任务..." : "Defining suitable tasks...") : (loc.currentLanguage == .chinese ? "提升系统性能" : "Boost system performance"),
                categories: [.startupItems, .performanceApps],
                state: state,
                color: Color(red: 0.9, green: 0.3, blue: 0.5), // Pink
                currentPath: (service.isScanning && [.startupItems, .performanceApps].contains(service.currentCategory)) ? service.currentScanPath : nil
            )
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Column Item View
    @ViewBuilder
    private func itemColumn(
        title: String,
        iconName: String,
        description: String,
        categories: [CleanerCategory],
        state: ScanState,
        color: Color,
        currentPath: String? = nil
    ) -> some View {
        VStack(spacing: 16) {
            // Icon Area
            ZStack {
                // Background Glow/Shape - Enlarged
                RoundedRectangle(cornerRadius: 30) // Adjusted corner radius for larger size
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120) // Increased from 100x100
                    .shadow(color: color.opacity(0.4), radius: 10, y: 5)
                
                // Image Icon - Enlarged
                if let imagePath = Bundle.main.path(forResource: iconName, ofType: "png"),
                   let nsImage = NSImage(contentsOfFile: imagePath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72) // Increased from 64x64
                        .modifier(ScanningAnimationModifier(isScanning: state == .scanning))
                } else {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 48)) // Increased from 40
                        .foregroundColor(.white)
                }
            }
            .frame(height: 140) // Increased from 120
            
            // Status Check + Title
            HStack(spacing: 6) {
                if state == .scanning {
                   if currentPath != nil {
                       // Active scanning for this group
                       ProgressView()
                           .scaleEffect(0.6)
                           .frame(width: 16, height: 16)
                   } else {
                       // Waiting
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                   }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Description
            Text(description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(height: 36)
            
            // Scanning Path / Result
            if state == .scanning {
                if let path = currentPath {
                     Text(path)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(height: 20)
                } else {
                     Text(loc.currentLanguage == .chinese ? "正在等待..." : "Waiting...")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(height: 20)
                }
            } else if state == .completed || state == .finished {
                Group {
                    if title == (loc.currentLanguage == .chinese ? "清理" : "Cleanup") {
                        // Cleanup Result: Size
                        let size = categories.reduce(0) { $0 + service.sizeFor(category: $1) }
                        if size > 0 {
                            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(color)
                        } else {
                             Text(loc.currentLanguage == .chinese ? "好" : "Good")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Color.green)
                        }
                    } else if title == (loc.currentLanguage == .chinese ? "保护" : "Protection") {
                         // Protection Result: Threats count
                         let threats = service.virusThreats.count
                         if threats > 0 {
                             Text("\(threats)")
                                 .font(.system(size: 32, weight: .light))
                                 .foregroundColor(.red)
                         } else {
                             Text(loc.currentLanguage == .chinese ? "好" : "Good")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Color.green)
                         }
                    } else {
                        // Speed Result: Items count
                        let count = service.startupItems.count + service.performanceApps.count
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(color)
                        } else {
                             Text(loc.currentLanguage == .chinese ? "好" : "Good")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Color.green)
                        }
                    }
                }
                .frame(height: 40)
                
                // Footer Status / Button
                if title == (loc.currentLanguage == .chinese ? "清理" : "Cleanup") {
                    Button(action: {
                        initialDetailCategory = .systemJunk // or .userCache default
                        showDetailSheet = true
                    }) {
                        Text(loc.currentLanguage == .chinese ? "查看详情..." : "View Details...")
                            .font(.system(size: 12))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                } else if title == (loc.currentLanguage == .chinese ? "保护" : "Protection") {
                    if service.virusThreats.isEmpty {
                        Text(loc.currentLanguage == .chinese ? "没有找到威胁" : "No threats found")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    } else {
                        Text("\(service.virusThreats.count) " + (loc.currentLanguage == .chinese ? "个威胁" : "threats"))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    let count = service.startupItems.count + service.performanceApps.count
                    if count > 0 {
                        Text("\(count) " + (loc.currentLanguage == .chinese ? "个任务可运行" : "tasks available"))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    } else {
                        Text(loc.currentLanguage == .chinese ? "已优化" : "Optimized")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            } else {
                 // Spacing for scanning/cleaning state where results aren't shown yet
                 Spacer().frame(height: 60)
            }
        }
        .frame(width: 180)
    }

    // MARK: - Animation Modifier
    struct ScanningAnimationModifier: ViewModifier {
        let isScanning: Bool
        @State private var isAnimating = false
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isScanning && isAnimating ? 1.1 : 1.0)
                .animation(isScanning ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isAnimating)
                .onAppear {
                    if isScanning { isAnimating = true }
                }
                .onChange(of: isScanning) { newValue in
                    isAnimating = newValue
                }
        }
    }
    
    // MARK: - Rotating Ring Component
    struct RotatingCircleRing: View {
        @State private var rotation: Double = 0
        
        var body: some View {
            Circle()
                .trim(from: 0.2, to: 1)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.white.opacity(0.8), .white.opacity(0.1)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }

    // MARK: - Main Action Button (Scan Orb)
    @ViewBuilder
    private var mainActionButton: some View {
        switch scanState {
        case .initial:
            // Start Orb
            Button(action: {
                Task { await service.scanAll() }
            }) {
                ZStack {
                    // Outer Glow
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.purple.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 90
                        ))
                        .frame(width: 160, height: 160)
                    
                    // Main Orb
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.8, green: 0.2, blue: 0.7), Color(red: 0.5, green: 0.1, blue: 0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .purple.opacity(0.6), radius: 15, x: 0, y: 8)
                        .overlay(
                            // Glassy reflection
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.7), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    
                    Text(loc.currentLanguage == .chinese ? "开始" : "Start")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
            }
            .buttonStyle(.plain)
            
        case .scanning:
            // New Stop Button with Rotating Ring and Real-time Size
            HStack(spacing: 20) {
                // Stop Button Group
                Button(action: { service.stopScanning() }) {
                    ZStack {
                        // Background Circle
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        // Rotating Progress Ring
                        RotatingCircleRing()
                            .frame(width: 80, height: 80)
                        
                        // Inner Button (Stop)
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 64, height: 64)
                        
                        Text(loc.currentLanguage == .chinese ? "停止" : "Stop")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                // Real-time Size Display
                Text(ByteCountFormatter.string(fromByteCount: totalScannedSize, countStyle: .file))
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.bottom, 20)
                         
        case .completed:
            // Run Orb (Updated text)
            Button(action: {
                if service.performanceApps.contains(where: { $0.isSelected }) {
                    showRunningAppsSafetyAlert = true
                } else {
                    showDeleteConfirmation = true
                }
            }) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.blue.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 90
                        ))
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.1, green: 0.3, blue: 0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .blue.opacity(0.6), radius: 15, x: 0, y: 8)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    
                    VStack(spacing: 2) {
                        Text(loc.currentLanguage == .chinese ? "运行" : "Run")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            
        case .finished:
             // Back/Done Orb
             Button(action: {
                 Task { service.resetAll(); showCleaningFinished = false }
             }) {
                 ZStack {
                     Circle()
                         .fill(RadialGradient(colors: [Color.green.opacity(0.4), .clear], center: .center, startRadius: 40, endRadius: 90))
                         .frame(width: 160, height: 160)
                     
                     Circle()
                         .fill(LinearGradient(colors: [Color.green, Color.green.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                         .frame(width: 100, height: 100)
                         .shadow(color: .green.opacity(0.6), radius: 15, x: 0, y: 8)
                     
                     Text(loc.currentLanguage == .chinese ? "返回" : "Back")
                         .font(.system(size: 18, weight: .bold))
                         .foregroundColor(.white)
                 }
             }
             .buttonStyle(.plain)
             
        default:
            EmptyView()
        }
    }

    
    // MARK: - Display Helpers
    private func getDisplayTitle(for category: CleanerCategory) -> String {
        switch category {
        case .systemJunk: return loc.currentLanguage == .chinese ? "系统垃圾" : "System Junk"
        case .duplicates: return loc.currentLanguage == .chinese ? "重复文件" : "Duplicates"
        case .similarPhotos: return loc.currentLanguage == .chinese ? "相似照片" : "Similar Photos"
        case .largeFiles: return loc.currentLanguage == .chinese ? "大文件" : "Large Files"
        case .virus: return loc.currentLanguage == .chinese ? "病毒防护" : "Virus Protection"
        case .startupItems: return loc.currentLanguage == .chinese ? "启动项" : "Startup Items"
        case .performanceApps: return loc.currentLanguage == .chinese ? "性能优化" : "Performance"
        case .appUpdates: return loc.currentLanguage == .chinese ? "应用更新" : "App Updates"
        default: return ""
        }
    }
    
    private func getResultText(for category: CleanerCategory) -> String {
        let size = service.sizeFor(category: category)
        if size > 0 || [.systemJunk, .duplicates, .similarPhotos, .largeFiles].contains(category) {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        
        switch category {
        case .virus: return service.virusThreats.isEmpty ? (loc.currentLanguage == .chinese ? "0 个威胁" : "0 Threats") : "\(service.virusThreats.count) \(loc.currentLanguage == .chinese ? "个威胁" : "Threats")"
        case .startupItems: return "\(service.startupItems.count) \(loc.currentLanguage == .chinese ? "个项目" : "Items")"
        case .performanceApps: return "\(service.performanceApps.count) \(loc.currentLanguage == .chinese ? "个应用" : "Apps")"
        case .appUpdates: return service.hasAppUpdates ? (loc.currentLanguage == .chinese ? "有更新" : "Has Update") : (loc.currentLanguage == .chinese ? "无更新" : "No Updates")
        default: return "0 KB"
        }
    }
    
    private func getSubText(for category: CleanerCategory) -> String {
        switch category {
        case .systemJunk, .duplicates, .similarPhotos, .largeFiles: return loc.currentLanguage == .chinese ? "可清理" : "Cleanable"
        case .virus: return service.virusThreats.isEmpty ? (loc.currentLanguage == .chinese ? "已保护" : "Safe") : (loc.currentLanguage == .chinese ? "可移除" : "Removable")
        case .startupItems: return loc.currentLanguage == .chinese ? "可优化" : "Optimizable"
        case .performanceApps: return loc.currentLanguage == .chinese ? "待查看" : "To Review"
        case .appUpdates: return loc.currentLanguage == .chinese ? "要安装" : "To Install"
        default: return ""
        }
    }
    
    private func getScanningTitle(for category: CleanerCategory) -> String {
        switch category {
        case .systemJunk: return loc.currentLanguage == .chinese ? "正在查找垃圾文件......" : "Searching for junk..."
        case .duplicates: return loc.currentLanguage == .chinese ? "正在寻找重复文件..." : "Finding duplicates..."
        case .similarPhotos: return loc.currentLanguage == .chinese ? "正在查找相似照片..." : "Finding similar photos..."
        case .largeFiles: return loc.currentLanguage == .chinese ? "正在扫描大文件..." : "Scanning for large files..."
        case .virus: return loc.currentLanguage == .chinese ? "正在查找潜在威胁..." : "Scanning for threats..."
        case .startupItems: return loc.currentLanguage == .chinese ? "正在分析启动项..." : "Analyzing startup items..."
        case .performanceApps: return loc.currentLanguage == .chinese ? "正在检查后台应用..." : "Checking background apps..."
        case .appUpdates: return loc.currentLanguage == .chinese ? "正在检查应用更新..." : "Checking for updates..."
        default: return ""
        }
    }
    
    private func getGradient(for category: CleanerCategory) -> LinearGradient {
        switch category {
        case .systemJunk:
            return LinearGradient(colors: [Color(red: 0.2, green: 0.9, blue: 0.6), Color(red: 0.1, green: 0.6, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .duplicates:
            return LinearGradient(colors: [Color(red: 0.3, green: 0.7, blue: 1.0), Color(red: 0.1, green: 0.4, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .similarPhotos:
            return LinearGradient(colors: [Color(red: 0.7, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.2, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .largeFiles:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.7, blue: 0.3), Color(red: 0.8, green: 0.4, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .virus:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.3, blue: 0.4), Color(red: 0.7, green: 0.1, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .startupItems:
            return LinearGradient(colors: [Color(red: 0.4, green: 0.4, blue: 0.9), Color(red: 0.2, green: 0.2, blue: 0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .performanceApps:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.4, blue: 0.7), Color(red: 0.8, green: 0.2, blue: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .appUpdates:
            return LinearGradient(colors: [Color(red: 0.2, green: 0.8, blue: 1.0), Color(red: 0.1, green: 0.5, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color.gray, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private func getCleaningSubText(for category: CleanerCategory) -> String {
        switch category {
        case .systemJunk, .duplicates, .similarPhotos, .largeFiles: return loc.currentLanguage == .chinese ? "已清理" : "Cleaned"
        case .virus: return loc.currentLanguage == .chinese ? "已防护" : "Protected"
        case .performanceApps, .startupItems: return loc.currentLanguage == .chinese ? "已优化" : "Optimized"
        case .appUpdates: return loc.currentLanguage == .chinese ? "已检查" : "Checked"
        default: return ""
        }
    }
    
    private func getCleaningTitle(for category: CleanerCategory) -> String {
        switch category {
        case .systemJunk: return loc.currentLanguage == .chinese ? "正在清理垃圾文件..." : "Cleaning junk..."
        case .duplicates, .similarPhotos, .largeFiles: return loc.currentLanguage == .chinese ? "正在整理文件..." : "Organizing files..."
        case .virus: return loc.currentLanguage == .chinese ? "正在移除威胁..." : "Removing threats..."
        case .startupItems: return loc.currentLanguage == .chinese ? "正在优化启动项..." : "Optimizing startup..."
        case .performanceApps: return loc.currentLanguage == .chinese ? "正在优化性能..." : "Optimizing performance..."
        case .appUpdates: return loc.currentLanguage == .chinese ? "正在检查更新状态..." : "Checking update status..."
        default: return ""
        }
    }
    
    private func getFinishedResultText(for category: CleanerCategory) -> String {
        if category == .systemJunk && deleteResult != nil {
            return ByteCountFormatter.string(fromByteCount: deleteResult!.size, countStyle: .file) + " " + (loc.currentLanguage == .chinese ? "已清理" : "Cleaned")
        }
        return getCleaningSubText(for: category)
    }
}

// MARK: - Dashboard Card Component
struct DashboardCard: View {
    let title: String
    let mainText: String
    let subText: String
    let icon: String // SF Symbol
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                // Header (Checkbox visually represented by Icon for now per design)
                HStack {
                     Image(systemName: "checkmark.square.fill") // Fake checkbox for aesthetic
                        .foregroundColor(.white.opacity(0.6))
                     Text(title)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Text(mainText)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Right Side Graphic (Glassmorphism Icon)
            VStack {
                ZStack {
                    // Glassy background for icon
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)
                        .shadow(radius: 10)
                    
                    Image(systemName: icon)
                         .resizable()
                         .aspectRatio(contentMode: .fit)
                         .frame(width: 40, height: 40)
                         .foregroundColor(.white)
                }
                
                Spacer()
                
                Button("查看") { action() } // View Button
                .buttonStyle(SmallGlassButtonStyle())
            }
        }
        .padding(20)
        .frame(height: 180)
        .background(
            ZStack {
                gradient.opacity(0.3) // Tint
                Color.black.opacity(0.3) // Darken
                Rectangle().fill(.thinMaterial) // Blur
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Status Pill for Scanning
struct StatusPill: View {
    let label: String
    let active: Bool
    
    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(active ? Color.purple : Color.white.opacity(0.1))
            .cornerRadius(20)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(active ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .animation(.easeInOut, value: active)
    }
}

// MARK: - Small Glass Button
struct SmallGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// Block state for consistent rendering
enum ScanBlockState {
    case idle       // Not yet scanned
    case active     // Currently scanning/cleaning
    case completed  // Finished
}

// MARK: - Scan Block View (Fixed Size, No Flashing)
struct ScanBlockView: View {
    let category: CleanerCategory
    let isActive: Bool
    let isCompleted: Bool
    let title: String
    let resultText: String
    let subText: String
    let icon: String
    let gradient: LinearGradient
    let scanningTitle: String
    let currentPath: String
    @ObservedObject var loc: LocalizationManager
    var viewDetailsAction: (() -> Void)? = nil
    
    private var state: ScanBlockState {
        if isActive { return .active }
        if isCompleted { return .completed }
        return .idle
    }
    
    var body: some View {
        // Fixed size container - prevents layout shifts
        ZStack {
            // Background based on state
            backgroundView
            
            // Content based on state
            contentView
        }
        .frame(height: 180) // Fixed height to prevent jumping
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderColor, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: state)
    }
    
    private var borderColor: Color {
        switch state {
        case .active: return Color.white.opacity(0.3)
        case .completed: return Color.white.opacity(0.1)
        case .idle: return Color.white.opacity(0.05)
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch state {
        case .active:
            // 扫描中：半透明背景 + 描边闪烁感
            ZStack {
                Color.black.opacity(0.3)
                gradient.opacity(0.15)
                
                // 动效背景装饰
                RoundedRectangle(cornerRadius: 20)
                    .fill(gradient)
                    .opacity(0.15)
                    .mask(LinearGradient(colors: [.black, .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        case .completed:
            // 完成后：经典的玻璃态 (Glassmorphism)
            ZStack {
                Color.white.opacity(0.06)
                gradient.opacity(0.12)
                LinearGradient(
                    colors: [.white.opacity(0.1), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .idle:
            // 待扫描：纯净极简
            ZStack {
                Color.black.opacity(0.15)
                Color.white.opacity(0.02)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch state {
        case .active:
            activeContent
        case .completed:
            completedContent
        case .idle:
            idleContent
        }
    }
    
    // Active state content
    private var activeContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scanningTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            // Icon with glow
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Color.white.opacity(0.25), Color.clear], center: .center, startRadius: 20, endRadius: 60))
                        .frame(width: 100, height: 100)
                    
                    RoundedRectangle(cornerRadius: 18)
                        .fill(gradient)
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(45))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                .rotationEffect(.degrees(45))
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 8)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            
            Spacer()
            
            Text(currentPath)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(16)
    }
    
    // Completed state content
    private var completedContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                // “查看详情”入口
                if let action = viewDetailsAction {
                    Button(action: action) {
                        HStack(spacing: 2) {
                            Text(loc.currentLanguage == .chinese ? "查看详情" : "Details")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(resultText)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subText)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gradient.opacity(0.5))
                        .frame(width: 45, height: 45)
                        .rotationEffect(.degrees(45))
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            Spacer()
        }
        .padding(14)
    }
    
    // Idle state content
    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            Spacer()
            
            // Faded icon
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(gradient.opacity(0.25))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
            }
            
            Spacer()
        }
        .padding(14)
    }
}

// MARK: - Cleaning Block View
struct CleaningBlockView: View {
    let title: String
    let resultText: String
    let subText: String
    let icon: String
    let gradient: LinearGradient
    let cleaningTitle: String
    let isActive: Bool
    let isCompleted: Bool
    let currentPath: String
    @ObservedObject var loc: LocalizationManager
    var viewDetailsAction: (() -> Void)? = nil
    
    // Action for "View Details" button
    
    var body: some View {
        ZStack {
            // Background
            ZStack {
                if isActive {
                    gradient.opacity(0.8)
                } else if isCompleted {
                    Color.white.opacity(0.06)
                    gradient.opacity(0.1)
                } else {
                    Color.black.opacity(0.15)
                    Color.white.opacity(0.02)
                }
                
                // 玻璃高光
                LinearGradient(
                    colors: [.white.opacity(0.1), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            // Content
            if isActive {
                // Active cleaning
                VStack(alignment: .leading, spacing: 8) {
                    Text(cleaningTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(RadialGradient(colors: [Color.white.opacity(0.25), Color.clear], center: .center, startRadius: 20, endRadius: 50))
                                .frame(width: 80, height: 80)
                            
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Text(currentPath)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(14)
            } else if isCompleted {
                // Completed
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        if let action = viewDetailsAction {
                            Button(action: action) {
                                HStack(spacing: 2) {
                                    Text(loc.currentLanguage == .chinese ? "查看详情" : "Details")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.purple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(resultText)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            Text(subText)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(gradient.opacity(0.5))
                                .frame(width: 45, height: 45)
                                .rotationEffect(.degrees(45))
                            
                            Image(systemName: icon)
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    
                    Spacer()
                }
                .padding(12)
            } else {
                // Idle
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(gradient.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(12)
            }
        }
        .frame(height: 180)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isActive ? Color.white.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: isActive)
        .animation(.easeInOut(duration: 0.3), value: isCompleted)
    }
}

// MARK: - Result Block View (for completed scan results)
struct ResultBlockView: View {
    let title: String
    let resultText: String
    let subText: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 玻璃态背景
                ZStack {
                    Color.white.opacity(0.06)
                    gradient.opacity(0.08)
                    LinearGradient(
                        colors: [.white.opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(gradient.opacity(0.6))
                                .frame(width: 55, height: 55)
                                .rotationEffect(.degrees(45))
                            
                            Image(systemName: icon)
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Text(resultText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(subText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(14)
            }
            .frame(height: 180)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Finished Block View (all blocks completed)
struct FinishedBlockView: View {
    let title: String
    let resultText: String
    let icon: String
    let gradient: LinearGradient
    var viewDetailsAction: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // 玻璃态背景
            ZStack {
                Color.white.opacity(0.06)
                gradient.opacity(0.05)
                LinearGradient(
                    colors: [.white.opacity(0.08), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    // “查看详情”入口 (可选)
                    if let action = viewDetailsAction {
                        Button(action: action) {
                            HStack(spacing: 2) {
                                let lang = LocalizationManager.shared.currentLanguage
                                Text(lang == .chinese ? "查看详情" : "Details")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    Text(resultText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(gradient.opacity(0.5))
                            .frame(width: 45, height: 45)
                            .rotationEffect(.degrees(45))
                        
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(14)
        }
        .frame(height: 180)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// 扫过光效动画
struct WipingAnimation: ViewModifier {
    @State private var offset: CGFloat = -300
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    offset = 400
                }
            }
    }
}
