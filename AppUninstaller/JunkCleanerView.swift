import SwiftUI
import AVFoundation
import Quartz

struct JunkCleanerView: View {
    // 扫描状态枚举
    enum ScanState {
        case initial    // 初始页面
        case scanning   // 扫描中
        case cleaning   // 清理中
        case completed  // 扫描完成（结果页）
        case finished   // 清理完成（最终页）
    }

    // 使用共享的服务管理器
    @ObservedObject private var cleaner = ScanServiceManager.shared.junkCleaner
    @ObservedObject private var loc = LocalizationManager.shared
    
    // View State
    @State private var showingDetails = false // 控制详情页显示
    @State private var selectedCategory: JunkType? // 选中的分类
    @State private var searchText = ""
    @State private var showingCleanAlert = false
    @State private var cleanedAmount: Int64 = 0
    @State private var failedFiles: [String] = []
    @State private var showRetryWithAdmin = false
    @State private var cleanResult: (cleaned: Int64, failed: Int64, requiresAdmin: Bool)?
    @State private var showCleaningFinished = false
    @State private var wasScanning = false // 跟踪扫描状态变化
    
    // Animation State
    @State private var pulse = false
    @State private var animateScan = false
    @State private var isAnimating = false
    
    // 扫描状态 - 使用计算属性，根据 cleaner 状态动态计算
    private var scanState: ScanState {
        if cleaner.isScanning {
            return .scanning
        } else if cleaner.isCleaning {
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
    
    // 计算属性：检查是否已有扫描结果
    private var hasScanResults: Bool {
        return cleaner.totalSize > 0 || !cleaner.junkItems.isEmpty
    }
    
    // 静态音频播放器引用，防止被提前释放
    private static var soundPlayer: NSSound?
    
    // 播放扫描完成提示音
    private func playScanCompleteSound() {
        if let soundURL = Bundle.main.url(forResource: "CleanDidFinish", withExtension: "m4a") {
            // 停止之前的播放
            JunkCleanerView.soundPlayer?.stop()
            // 创建新的播放器并保持引用
            JunkCleanerView.soundPlayer = NSSound(contentsOf: soundURL, byReference: false)
            JunkCleanerView.soundPlayer?.play()
        }
    }
    
    var body: some View {
        ZStack {
            switch scanState {
            case .initial:
                initialPage
            case .scanning:
                scanningPage
            case .completed:
                if showingDetails {
                    detailPage
                } else {
                    summaryPage
                }
            case .cleaning:
                cleaningPage
            case .finished:
                finishedPage
            }
        }
        .alert(loc.currentLanguage == .chinese ? "部分文件需要管理员权限" : "Some Files Require Admin Privileges", isPresented: $showRetryWithAdmin) {
            Button(loc.currentLanguage == .chinese ? "使用管理员权限删除" : "Delete with Admin", role: .destructive) {
                 showCleaningFinished = true
            }
            Button(loc.L("cancel"), role: .cancel) {
                showCleaningFinished = true
            }
        } message: {
            Text(loc.currentLanguage == .chinese ?
                 "部分文件因权限不足无法删除。" :
                 "Some files could not be deleted due to insufficient permissions.")
        }
        // 监听扫描完成并播放提示音
        .onReceive(cleaner.$isScanning) { isScanning in
            if wasScanning && !isScanning && hasScanResults {
                // 扫描从进行中变为完成，播放提示音
                playScanCompleteSound()
            }
            wasScanning = isScanning
        }
    }
    
    // MARK: - 1. 初始页面
    private var initialPage: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 60) {
                // Left Side: Text and Features
                VStack(alignment: .leading, spacing: 20) {
                    Text(loc.currentLanguage == .chinese ? "系统垃圾" : "System Junk")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(loc.currentLanguage == .chinese ? "清理您的系统来获得最大的性能和释放自由空间。" : "Clean up your system to maximize performance and free up space.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                    
                    Spacer().frame(height: 10)
                    
                    // Feature 1: Optimize System
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "chart.bar") // Icon resembling the waveform/chart
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc.currentLanguage == .chinese ? "优化系统" : "Optimize System")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text(loc.currentLanguage == .chinese ? "移除临时文件以释放空间，提升 Mac 的性能。" : "Remove temporary files to free up space, improve Mac performance.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Feature 2: Fix Errors
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "pill") // Icon resembling the pill
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc.currentLanguage == .chinese ? "解决所有类型的错误" : "Fix all types of errors")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text(loc.currentLanguage == .chinese ? "删除各种可能会导致应用程序反应异常的破损项目。" : "Delete various broken items that may cause application anomalies.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(width: 300)
                
                // Right Side: Large Pink Mouse Icon
                if let imagePath = Bundle.main.path(forResource: "system_clean_menu", ofType: "png"),
                   let nsImage = NSImage(contentsOfFile: imagePath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 380, height: 380)
                        .shadow(color: .pink.opacity(0.3), radius: 20, x: 0, y: 10)
                } else {
                    // Fallback
                    GlassyPurpleDisc(scale: 1.5)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Scan Button (Bottom Center)
            ZStack {
                Circle()
                    .stroke(LinearGradient(colors: [.white.opacity(0.5), .blue.opacity(0.5)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                    .frame(width: 60, height: 60)
                    .shadow(color: .blue.opacity(0.5), radius: 5)
                
                 Button(action: { startScan() }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "7D7AFF"), Color(hex: "5E5CE6")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                        
                        Text(loc.currentLanguage == .chinese ? "扫描" : "Scan")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
            }
             .padding(.bottom, 60)
        }
    }

    // MARK: - 2. 扫描中页面
    private var scanningPage: some View {
        VStack {
            HStack {
                 Spacer()
                 Text(loc.currentLanguage == .chinese ? "系统垃圾" : "System Junk")
                     .foregroundColor(.white.opacity(0.7))
                 Spacer()
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Center Image with Animation
            ZStack {
                if let imagePath = Bundle.main.path(forResource: "system_clean_menu", ofType: "png"),
                   let nsImage = NSImage(contentsOfFile: imagePath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 320, height: 320)
                }
            }
            .padding(.bottom, 40)
            
            // Status Text
            Text(loc.currentLanguage == .chinese ? "正在分析系统..." : "Analyzing System...")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.bottom, 8)
            
            Text(cleaner.currentScanningPath)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4)) // Grey path
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 60)
                .frame(height: 20)
            
            Text(cleaner.currentScanningCategory)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 4)
            
            Spacer()
            
            // Stop Button with Ring & Size (Standardized)
            HStack(spacing: 20) {
                 Button(action: { cleaner.stopScanning() }) {
                    ZStack {
                        // Progress/Ring Background
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 3)
                            .frame(width: 60, height: 60)
                        
                        // Progress Ring (Determinate)
                        Circle()
                            .trim(from: 0, to: max(0.01, cleaner.scanProgress))
                            .stroke(
                                AngularGradient(gradient: Gradient(colors: [.white.opacity(0.8), .white.opacity(0.1)]), center: .center),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(Angle(degrees: -90))
                            .animation(.linear(duration: 0.2), value: cleaner.scanProgress)
                        
                        // Inner Button
                        Circle()
                            .fill(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 48, height: 48)
                        
                        Text(loc.currentLanguage == .chinese ? "停止" : "Stop")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                // Real-time Size
                Text(ByteCountFormatter.string(fromByteCount: cleaner.totalSize, countStyle: .file))
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
            }
            .padding(.bottom, 20)

        }
        .onAppear { isAnimating = true }
    }
    
    // MARK: - 3. Summary Page (Results)
    private var summaryPage: some View {
        VStack(spacing: 0) {
            // Navbar
            HStack {
                Button(action: { cleaner.reset(); showCleaningFinished = false }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(loc.currentLanguage == .chinese ? "重新开始" : "Start Over")
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                Spacer()
                Text(loc.currentLanguage == .chinese ? "系统垃圾" : "System Junk")
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                // Assistant Pill
                Button(action: { /* Help */ }) {
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: "40C4FF")).frame(width: 6, height: 6)
                        Text(loc.currentLanguage == .chinese ? "助手" : "Assistant")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
            
            HStack(spacing: 80) {
                // Left: Image
                if let imagePath = Bundle.main.path(forResource: "system_clean_menu", ofType: "png"),
                   let nsImage = NSImage(contentsOfFile: imagePath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 380, height: 380)
                        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                }
                
                // Right: Results Text - 动态显示已选中的分类
                VStack(alignment: .leading, spacing: 12) {
                    Text(loc.currentLanguage == .chinese ? "扫描完毕" : "Scan Complete")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(ByteCountFormatter.string(fromByteCount: cleaner.selectedSize, countStyle: .file))
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(Color(hex: "40C4FF"))
                        
                        Text(loc.currentLanguage == .chinese ? "已选中" : "Selected")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // 动态显示已选中的分类列表
                    VStack(alignment: .leading, spacing: 6) {
                        Text(loc.currentLanguage == .chinese ? "包括" : "Includes")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        // 获取已选中的分类
                        ForEach(selectedCategories, id: \.self) { category in
                            HStack(spacing: 6) {
                                Text("•")
                                Text(category.rawValue)
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.leading, 8)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    HStack(spacing: 30) {
                        Button(action: { withAnimation { showingDetails = true } }) {
                            Text(loc.currentLanguage == .chinese ? "查看项目" : "Review Details")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Text(loc.currentLanguage == .chinese ? "共发现 \(ByteCountFormatter.string(fromByteCount: cleaner.totalSize, countStyle: .file))" : "Found \(ByteCountFormatter.string(fromByteCount: cleaner.totalSize, countStyle: .file))")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Clean Button
            Button(action: { startCleaning() }) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Color.white.opacity(0.2), .clear], center: .center, startRadius: 40, endRadius: 70))
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .stroke(LinearGradient(colors: [.white.opacity(0.5), .blue.opacity(0.5)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                        .frame(width: 60, height: 60)

                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "7D7AFF").opacity(0.8), Color(hex: "5E5CE6").opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                        .shadow(radius: 5)
                    
                    Text(loc.currentLanguage == .chinese ? "清理" : "Clean")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 60)
        }
    }
    
    /// 获取已选中的分类列表（按大小降序）
    private var selectedCategories: [JunkType] {
        let selectedItems = cleaner.junkItems.filter { $0.isSelected }
        let categorySizes: [JunkType: Int64] = Dictionary(grouping: selectedItems, by: { $0.type })
            .mapValues { items in items.reduce(0) { $0 + $1.size } }
        return categorySizes.keys.sorted { categorySizes[$0] ?? 0 > categorySizes[$1] ?? 0 }
    }
    
    // ... Detail/Cleaning/Finished Pages (Unchanged for now) ...
    
    // MARK: - 4. Detail Page
    private var detailPage: some View {
        VStack(spacing: 0) {
            // Navbar
            HStack {
                Button(action: {
                    withAnimation {
                        showingDetails = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(loc.currentLanguage == .chinese ? "返回" : "Back")
                    }
                    .foregroundColor(.secondaryText)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(loc.currentLanguage == .chinese ? "系统垃圾" : "System Junk")
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack {
                     Image(systemName: "magnifyingglass").foregroundColor(.secondaryText)
                     TextField(loc.currentLanguage == .chinese ? "搜索" : "Search", text: $searchText)
                         .textFieldStyle(.plain)
                         .frame(width: 100)
                }
                .padding(6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            Divider().background(Color.white.opacity(0.1))
            
            HSplitView {
                JunkSidebarView(selectedCategory: $selectedCategory, cleaner: cleaner)
                JunkDetailContentView(selectedCategory: selectedCategory, cleaner: cleaner)
            }
            
            // Bottom Clean Button Overlay
            // Bottom Clean Button Overlay
             ZStack {
                // Gradient Background
                LinearGradient(colors: [Color(hex: "4A4385").opacity(0.01), Color(hex: "4A4385").opacity(1.0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 100)
                
                 HStack(spacing: 16) {
                     // Clean Button - Glowing Gradient Circle
                     Button(action: { startCleaning() }) {
                         ZStack {
                             // Glow
                             Circle()
                                 .fill(Color(hex: "7D7AFF").opacity(0.4))
                                 .frame(width: 60, height: 60)
                                 .blur(radius: 10)
                             
                             // Border
                             Circle()
                                 .stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                                 .frame(width: 56, height: 56)
                             
                             // Fill
                             Circle()
                                 .fill(LinearGradient(colors: [Color(hex: "7D7AFF"), Color(hex: "5E5CE6")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                 .frame(width: 50, height: 50)
                             
                             Text(loc.currentLanguage == .chinese ? "清理" : "Clean")
                                 .font(.system(size: 12, weight: .semibold))
                                 .foregroundColor(.white)
                         }
                     }
                     .buttonStyle(.plain)
                     .padding(.bottom, 10)
                     
                     // Total Size Text
                     Text(ByteCountFormatter.string(fromByteCount: cleaner.selectedSize, countStyle: .file))
                         .font(.system(size: 18, weight: .medium))
                         .foregroundColor(.white)
                         .padding(.bottom, 10)
                 }
            }
            .frame(height: 100)
            .frame(height: 80)
        }
        .onAppear {
            if selectedCategory == nil, let first = cleaner.junkItems.first {
                selectedCategory = first.type
            }
        }
    }
    
    private var cleaningPage: some View {
        ZStack {
            // 主内容
            VStack(spacing: 0) {
                // 顶部导航栏 - 占位，保持导航栏高度
                HStack {
                    Spacer()
                    Text(loc.currentLanguage == .chinese ? "系统垃圾" : "System Junk")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // 主内容区域
                HStack(alignment: .top, spacing: 60) {
                    // 左侧：大图标
                    VStack {
                        if let imagePath = Bundle.main.path(forResource: "system_clean_menu", ofType: "png"),
                           let nsImage = NSImage(contentsOfFile: imagePath) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 300, height: 300) // 稍微调大一点
                                .shadow(color: .black.opacity(0.3), radius: 25, y: 15)
                                .rotationEffect(.degrees(cleaningRotation))
                                .onAppear {
                                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                                        cleaningRotation = 360
                                    }
                                }
                                .onDisappear {
                                    cleaningRotation = 0
                                }
                        }
                    }
                    .frame(width: 360, height: 360) // 固定容器大小
                    
                    // 右侧：标题 + 分类列表
                    VStack(alignment: .leading, spacing: 0) {
                        // 标题 - 增加顶部 Padding 使其下沉，与左侧图片顶部大致对齐或稍微靠下
                        Text(loc.currentLanguage == .chinese ? "正在清理系统..." : "Cleaning System...")
                            .font(.system(size: 26, weight: .semibold)) // 字体加大加粗
                            .foregroundColor(.white)
                            .padding(.bottom, 32) // 增加标题到底部的间距
                            .padding(.top, 40) // 核心调整：文字下沉
                        
                        // 分类列表 - 增加间距
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(cleaner.cleaningCategories, id: \.self) { category in
                                CleaningCategoryRow(
                                    category: category,
                                    status: cleaner.categoryCleaningStatus[category] ?? .pending,
                                    cleanedSize: cleaner.categoryCleanedSize[category] ?? 0,
                                    totalSize: getCategorySelectedSize(category)
                                )
                            }
                        }
                    }
                    .frame(maxWidth: 450, alignment: .leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                // 整体稍微上移一点，保持视觉中心
                .offset(y: -40)
                
                Spacer()
            }
            
            // 底部停止按钮
            VStack {
                Spacer()
                Button(action: { 
                    // 停止清理功能
                }) {
                    ZStack {
                        // 外圈渐变 - 绿色
                        Circle()
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [.green.opacity(0.8), .teal.opacity(0.8), .green.opacity(0.8)]),
                                    center: .center
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: .green.opacity(0.3), radius: 10)
                        
                        // 内圈背景
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 72, height: 72)
                        
                        Text(loc.currentLanguage == .chinese ? "停止" : "Stop")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 50)
            }
        }
    }
    
    // 清理动画旋转角度
    @State private var cleaningRotation: Double = 0
    
    /// 获取某个分类中已选中项目的总大小
    private func getCategorySelectedSize(_ category: JunkType) -> Int64 {
        cleaner.junkItems
            .filter { $0.type == category && $0.isSelected }
            .reduce(0) { $0 + $1.size }
    }
    
    private var finishedPage: some View {
        ZStack {
            // 主内容
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button(action: { cleaner.reset(); showCleaningFinished = false }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(loc.currentLanguage == .chinese ? "重新开始" : "Start Over")
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text(loc.currentLanguage == .chinese ? "系统垃圾" : "System Junk")
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    // 助手按钮占位
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Circle().fill(Color(hex: "40C4FF")).frame(width: 6, height: 6)
                            Text(loc.currentLanguage == .chinese ? "助手" : "Assistant")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // 主内容区域 - 左图右文
                HStack(spacing: 80) {
                    // 左侧：大图标
                    if let imagePath = Bundle.main.path(forResource: "system_clean_menu", ofType: "png"),
                       let nsImage = NSImage(contentsOfFile: imagePath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 380, height: 380)
                            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    }
                    
                    // 右侧：清理结果信息
                    VStack(alignment: .leading, spacing: 16) {
                        Text(loc.currentLanguage == .chinese ? "清理完毕" : "Cleanup Complete")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                        
                        // 清理大小 + 勾选图标
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            
                            Text(ByteCountFormatter.string(fromByteCount: cleanResult?.cleaned ?? cleanedAmount, countStyle: .file))
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(Color(hex: "40C4FF"))
                            
                            Text(loc.currentLanguage == .chinese ? "已清理" : "Cleaned")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // 磁盘剩余空间信息
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc.currentLanguage == .chinese ? 
                                 "您现在启动磁盘中有 \(DiskSpaceManager.shared.formattedFree) 可用空间。" :
                                 "You now have \(DiskSpaceManager.shared.formattedFree) available on your startup disk.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(loc.currentLanguage == .chinese ? 
                                 "通过检查其余项目，恢复更多空间。" :
                                 "Check remaining items to recover more space.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 8)
                        
                        // 操作按钮
                        HStack(spacing: 16) {
                            Button(action: { 
                                // 跳转到详情页查看剩余项目，而不是重置
                                showCleaningFinished = false
                                showingDetails = true
                            }) {
                                Text(loc.currentLanguage == .chinese ? "查看剩余项目" : "Review Remaining")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                // 分享成果功能（可选）
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text(loc.currentLanguage == .chinese ? "分享成果" : "Share Result")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 16)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            
            // 底部左侧 - 查看日志
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        // 打开删除日志
                        let logPath = FileManager.default.homeDirectoryForCurrentUser
                            .appendingPathComponent("Library/Application Support/MacOptimizer/deletion_log.json")
                        NSWorkspace.shared.activateFileViewerSelecting([logPath])
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 12))
                            Text(loc.currentLanguage == .chinese ? "查看日志" : "View Log")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.yellow.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 24)
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            // 清理完成后更新磁盘空间
            DiskSpaceManager.shared.updateDiskSpace()
        }
    }

    func startScan() {
        // scanState 会通过 cleaner.isScanning 自动变为 .scanning
        Task {
            await cleaner.scanJunk()
        }
    }
    
    func startCleaning() {
        // scanState 会通过 cleaner.isCleaning 自动变为 .cleaning
        Task {
            cleaner.isCleaning = true
            // 使用逐分类清理方法，按设计图要求逐个分类清理
            let result = await cleaner.cleanSelectedByCategory()
            cleanResult = (result.cleaned, result.failed, result.requiresAdmin)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            cleaner.isCleaning = false
            showCleaningFinished = true
        }
    }
}

// MARK: - Extracted Subviews for Detail Page

struct JunkSidebarView: View {
    @Binding var selectedCategory: JunkType?
    @ObservedObject var cleaner: JunkCleaner
    @ObservedObject private var loc = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    let allSelected = cleaner.junkItems.allSatisfy { $0.isSelected }
                    cleaner.junkItems.forEach { $0.isSelected = !allSelected }
                    cleaner.objectWillChange.send()
                }) {
                    Text(cleaner.junkItems.allSatisfy { $0.isSelected } ? (loc.currentLanguage == .chinese ? "取消全选" : "Deselect All") : (loc.currentLanguage == .chinese ? "全选" : "Select All"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(loc.currentLanguage == .chinese ? "排序方式按 大小" : "Sort by Size")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                    Image(systemName: "chevron.down")
                         .font(.system(size: 10))
                         .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(cleaner.junkItems.map { $0.type }.removingDuplicates(), id: \.self) { type in
                        JunkCategoryRow(type: type, 
                                    // 传递选中状态用于可能的微弱高亮，或者完全不传递
                                    // 这里保留 isSelected 以便将来可以添加极简的指示，但目前 Row 内部已去除了强背景
                                    isSelected: selectedCategory == type,
                                    cleaner: cleaner)
                            .background(
                                // 为当前选中的分类添加一个极淡的背景，类似右侧 Hover 效果，确保用户知道自己在看哪个分类
                                // 如果用户完全不想看见背景，可以改为 Color.clear，但我建议保留一点点提示
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedCategory == type ? Color.white.opacity(0.1) : Color.clear)
                                    .padding(.horizontal, 4)
                            )
                            .onTapGesture {
                                selectedCategory = type
                            }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(minWidth: 280)
        }
        .background(Color.black.opacity(0.1)) // More transparent dark sidebar
    }
}

struct JunkDetailContentView: View {
    let selectedCategory: JunkType?
    @ObservedObject var cleaner: JunkCleaner
    @ObservedObject private var loc = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let type = selectedCategory {
                let items = cleaner.junkItems.filter { $0.type == type }
                
                // Content Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(type.rawValue)
                        .font(.system(size: 24, weight: .bold)) // Larger Title
                        .foregroundColor(.white)
                    
                    Text(type.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8)) // Brighter description
                        .lineSpacing(4)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 24)
                
                // Sort by Size (Right Aligned)
                 HStack {
                     Spacer()
                     Text(loc.currentLanguage == .chinese ? "排序方式按 大小" : "Sort by Size")
                         .font(.system(size: 13))
                         .foregroundColor(.white.opacity(0.6))
                     Image(systemName: "triangle.fill")
                         .font(.system(size: 6))
                         .rotationEffect(.degrees(180))
                         .foregroundColor(.white.opacity(0.6))
                 }
                 .padding(.horizontal, 30)
                 .padding(.bottom, 10)
                
                // Items List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            JunkItemRow(item: item)
                        }
                    }
                    .padding(.bottom, 100) // Space for floating button
                }
            } else {
                // Empty State
                Spacer()
                Text(loc.currentLanguage == .chinese ? "选择左侧类别查看详情" : "Select a category to view details")
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
            }
        }
        .frame(minWidth: 460)
         // Ensure standard background is transparent so global background shows through
        .background(Color.clear) 
    }
}


// Helper for Array duplicate removal
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

// Category Row View
struct JunkCategoryRow: View {
    let type: JunkType
    let isSelected: Bool
    @ObservedObject var cleaner: JunkCleaner
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var isHovering: Bool = false
    
    // 实时从 cleaner 获取 items（而不是使用快照）
    private var items: [JunkItem] {
        cleaner.junkItems.filter { $0.type == type }
    }
    
    // 只计算已选中的文件大小
    var totalSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    // 勾选状态：未选、部分选中、全选
    enum CheckState {
        case none      // 未选
        case partial   // 部分选中
        case all       // 全选
    }
    
    var checkState: CheckState {
        guard !items.isEmpty else { return .none }
        let selectedCount = items.filter { $0.isSelected }.count
        if selectedCount == 0 {
            return .none
        } else if selectedCount == items.count {
            return .all
        } else {
            return .partial
        }
    }
    
    var isChecked: Bool {
        !items.isEmpty && items.allSatisfy { $0.isSelected }
    }
    
    var categoryColor: Color {
        // Match specific colors from design if possible, otherwise use specific gradients
        switch type {
        case .unusedDiskImages: return Color(hex: "A0A0A0") // Grey/Silver
        case .universalBinaries: return Color(hex: "FF9F0A") // Orange
        case .userCache: return Color(hex: "FFB340") // Light Orange
        case .systemCache: return Color(hex: "5AC8FA") // Blue
        case .userLogs: return Color(hex: "8E8E93") // Grey
        case .systemLogs: return Color(hex: "8E8E93") // Grey
        case .brokenLoginItems: return .red
        case .oldUpdates: return .green
        case .iosBackups: return .cyan
        case .downloads: return Color(hex: "0A84FF") // Blue
        default: return .purple
        }
    }
    
    var body: some View {
        HStack {
            // Selection Pill Background
            HStack {
                 // 勾选框 - 使用 .onTapGesture 确保可靠点击
                 ZStack {
                     Circle()
                         .stroke(checkState != .none ? Color(hex: "40C4FF") : Color.white.opacity(0.3), lineWidth: 1.5)
                         .frame(width: 20, height: 20)
                     
                     if checkState == .all {
                         // 全选状态：实心圆+对勾
                         Circle()
                            .fill(Color(hex: "40C4FF"))
                            .frame(width: 20, height: 20)
                         Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                     } else if checkState == .partial {
                         // 半勾选状态：实心圆+减号
                         Circle()
                            .fill(Color(hex: "40C4FF"))
                            .frame(width: 20, height: 20)
                         Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                     }
                 }
                 .frame(width: 20, height: 20)
                 .contentShape(Rectangle())
                 .onTapGesture {
                     // 在主线程上同步执行，避免时序问题
                     Task { @MainActor in
                         let newState: Bool
                         if checkState == .all {
                             // 全选 -> 取消全选
                             newState = false
                         } else {
                             // 未选或部分选中 -> 全选
                             newState = true
                         }
                         items.forEach { $0.isSelected = newState }
                         cleaner.objectWillChange.send()
                     }
                 }
                 .padding(.leading, 12)
                
                // Icon
                ZStack {
                     // Colored Background Circle
                    Circle()
                        .fill(
                            LinearGradient(colors: [categoryColor, categoryColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .padding(.leading, 8)
                
                Text(type.rawValue)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .padding(.leading, 4)
                
                Spacer()
                
                Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 13))
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        // 移除选中背景色，只保留 Hover 效果
                        isHovering ? Color.white.opacity(0.08) : Color.clear
                    )
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            // 全选
            Button {
                items.forEach { $0.isSelected = true }
                cleaner.objectWillChange.send()
            } label: {
                Label(
                    loc.currentLanguage == .chinese ? "全选 \"\(type.rawValue)\"" : "Select All \"\(type.rawValue)\"",
                    systemImage: "checkmark.circle.fill"
                )
            }
            .disabled(checkState == .all)
            
            // 取消全选
            Button {
                items.forEach { $0.isSelected = false }
                cleaner.objectWillChange.send()
            } label: {
                Label(
                    loc.currentLanguage == .chinese ? "取消全选 \"\(type.rawValue)\"" : "Deselect All \"\(type.rawValue)\"",
                    systemImage: "circle"
                )
            }
            .disabled(checkState == .none)
        }
    }
}


// MARK: - Subviews
struct JunkItemRow: View {
    @ObservedObject var item: JunkItem
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkbox - 使用独立的点击区域，避免状态冲突
            ZStack {
                Circle()
                    .stroke(item.isSelected ? Color(hex: "40C4FF") : Color.white.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
                
                if item.isSelected {
                    Circle()
                        .fill(Color(hex: "40C4FF"))
                        .frame(width: 18, height: 18)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 18, height: 18)
            .contentShape(Rectangle())
            .onTapGesture {
                // 在主线程上同步执行，避免时序问题
                Task { @MainActor in
                    item.isSelected.toggle()
                    ScanServiceManager.shared.junkCleaner.objectWillChange.send()
                }
            }
            
            // File Icon
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.path.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
            
            // Name
            Text(item.name)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            // Size
            Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.white.opacity(0.08) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            // 取消选择/选择
            Button {
                item.isSelected.toggle()
                ScanServiceManager.shared.junkCleaner.objectWillChange.send()
            } label: {
                Label(
                    item.isSelected ? 
                        (loc.currentLanguage == .chinese ? "取消选择 \"\(item.name)\"" : "Deselect \"\(item.name)\"") :
                        (loc.currentLanguage == .chinese ? "选择 \"\(item.name)\"" : "Select \"\(item.name)\""),
                    systemImage: item.isSelected ? "checkmark.circle.fill" : "circle"
                )
            }
            
            Divider()
            
            // 在访达中显示
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([item.path])
            } label: {
                Label(
                    loc.currentLanguage == .chinese ? "在 \"访达\" 中显示" : "Show in Finder",
                    systemImage: "folder"
                )
            }
            
            // 快速查看
            Button {
                quickLookFile()
            } label: {
                Label(
                    loc.currentLanguage == .chinese ? "快速查看 \"\(item.name)\"" : "Quick Look \"\(item.name)\"",
                    systemImage: "eye"
                )
            }
        }
    }
    
    // 快速查看文件
    private func quickLookFile() {
        guard let panel = QLPreviewPanel.shared() else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - Helpers

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

// Removed duplicate GradientStyles struct here. Using global one in Styles.swift

// MARK: - Glassy Purple Disc (Icon)
struct GlassyPurpleDisc: View {
    var scale: CGFloat = 1.0
    var rotation: Double = 0
    var isSpinning: Bool = false
    
    var body: some View {
        ZStack {
            // Outer Ring
            Circle()
                .fill(
                    LinearGradient(colors: [Color(hex: "BF5AF2").opacity(0.2), Color(hex: "5E5CE6").opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 260 * scale, height: 260 * scale)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            // Middle Glass Purple
            Circle()
                .fill(
                    LinearGradient(colors: [Color(hex: "AC44CF").opacity(0.8), Color(hex: "5E5CE6").opacity(0.6)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 200 * scale, height: 200 * scale)
                .shadow(color: Color(hex: "BF5AF2").opacity(0.5), radius: 25, y: 10)
                .overlay(    
                    Circle().stroke(
                        LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom), 
                        lineWidth: 1
                    )
                )
            
            // Inner Core
            Circle()
                .fill(LinearGradient(colors: [.white, Color(hex: "E0B0FF")], startPoint: .top, endPoint: .bottom))
                .frame(width: 80 * scale, height: 80 * scale)
                .shadow(color: .black.opacity(0.2), radius: 5)
            
            // Spinner Detail
            if isSpinning {
                 Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 140 * scale, height: 140 * scale)
                    .rotationEffect(.degrees(rotation))
            } else {
                 // Static Center (Broom or Trash Icon)
                 Image(systemName: "trash.fill")
                    .font(.system(size: 30 * scale))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "BF5AF2"), Color(hex: "5E5CE6")], startPoint: .top, endPoint: .bottom))
            }
        }
    }
}

// MARK: - Custom Checkbox Style
struct CircleCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            ZStack {
                Circle()
                    .stroke(configuration.isOn ? Color(hex: "40C4FF") : Color.white.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
                
                if configuration.isOn {
                    Circle()
                        .fill(Color(hex: "40C4FF"))
                        .frame(width: 18, height: 18)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Universal Binary Warning Dialog
// UniversalBinaryWarningDialog 已移除 - 通用二进制瘦身功能已禁用

// MARK: - 清理分类行组件
struct CleaningCategoryRow: View {
    let category: JunkType
    let status: JunkCleaner.CleaningStatus
    let cleanedSize: Int64
    let totalSize: Int64
    
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 分类图标 - 使用圆角矩形背景
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(categoryColor)
            }
            
            // 分类名称
            Text(category.rawValue)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            // 状态指示器
            switch status {
            case .pending:
                // 等待中 - 显示省略号按钮
                Button(action: {}) {
                    Text("•••")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                
            case .cleaning:
                // 正在清理 - 显示大小和加载动画
                HStack(spacing: 8) {
                    Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // 加载动画
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                }
                
            case .completed:
                // 完成 - 显示勾选图标
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var categoryColor: Color {
        switch category {
        case .downloads: return Color(hex: "5AC8FA")        // 蓝色
        case .systemCache: return Color(hex: "5AC8FA")      // 蓝色
        case .userLogs: return Color(hex: "8E8E93")         // 灰色
        case .systemLogs: return Color(hex: "8E8E93")       // 灰色
        case .userCache: return Color(hex: "FF9F0A")        // 橙色
        case .unusedDiskImages: return Color(hex: "A0A0A0") // 银色
        case .xcodeDerivedData: return Color(hex: "BF5AF2") // 紫色
        case .browserCache: return Color(hex: "30D158")     // 绿色
        case .chatCache: return Color(hex: "FF375F")        // 红色
        case .crashReports: return Color(hex: "FF9F0A")     // 橙色
        default: return Color(hex: "8E8E93")                // 默认灰色
        }
    }
}
