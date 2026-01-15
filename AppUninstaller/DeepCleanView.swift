import SwiftUI

// MARK: - Deep Clean States
enum DeepCleanState {
    case initial
    case scanning
    case results
    case cleaning
    case finished
}

struct DeepCleanView: View {
    @Binding var selectedModule: AppModule
    @ObservedObject private var scanner = ScanServiceManager.shared.deepCleanScanner
    @State private var viewState: DeepCleanState = .initial
    @State private var showingDetails = false
    @State private var selectedCategoryForDetails: DeepCleanCategory?
    @ObservedObject private var loc = LocalizationManager.shared
    
    // Alert States
    @State private var showCleanConfirmation = false
    @State private var cleanResult: (count: Int, size: Int64)?
    
    var body: some View {
        ZStack {
            VStack {
                 switch viewState {
                 case .initial:
                     initialView
                 case .scanning:
                     scanningView
                 case .results:
                     resultsView
                 case .cleaning:
                     cleaningView
                 case .finished:
                     finishedView
                 }
            }
            
            // Bottom Floating Scan Button (Only on initial view)
            if viewState == .initial {
                VStack {
                    Spacer()
                    Button(action: {
                        Task { await scanner.startScan() }
                    }) {
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
                            
                            Text(loc.currentLanguage == .chinese ? "扫描" : "Scan")
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
        .onAppear {
            // Sync state if already scanning
            if scanner.isScanning {
                viewState = .scanning
            } else if scanner.isCleaning {
                viewState = .cleaning
            } else if scanner.totalSize > 0 && viewState == .initial {
                 viewState = .results // Resume results if available
            }
        }
        .onChange(of: scanner.isScanning) { isScanning in
             if isScanning { viewState = .scanning }
             else if scanner.totalSize > 0 { viewState = .results }
        }
        .onChange(of: scanner.isCleaning) { newValue in
             if newValue {
                 viewState = .cleaning
             } else if viewState == .cleaning {
                 // 清理完成，切换到完成页面
                 viewState = .finished
             }
        }
        .sheet(isPresented: $showingDetails) {
            DeepCleanDetailView(scanner: scanner, category: selectedCategoryForDetails, isPresented: $showingDetails)
        }
        .confirmationDialog(loc.L("confirm_clean"), isPresented: $showCleanConfirmation) {
            Button(loc.currentLanguage == .chinese ? "开始清理" : "Start Cleaning", role: .destructive) {
                Task { @MainActor in
                    let result = await scanner.cleanSelected()
                    cleanResult = result
                }
            }
            Button(loc.L("cancel"), role: .cancel) {}
        } message: {
            Text(loc.currentLanguage == .chinese ? 
                 "确定要清理选中的 \(scanner.selectedCount) 个项目吗？总大小 \(ByteCountFormatter.string(fromByteCount: scanner.selectedSize, countStyle: .file))" :
                 "Are you sure you want to clean \(scanner.selectedCount) selected items? Total size: \(ByteCountFormatter.string(fromByteCount: scanner.selectedSize, countStyle: .file))")
        }
    }
    
    // MARK: - 1. Initial View (初始化页面)
    var initialView: some View {
        HStack(spacing: 60) {
            // Left Content
            VStack(alignment: .leading, spacing: 30) {
                // Branding Header
                HStack(spacing: 8) {
                    Text(loc.currentLanguage == .chinese ? "深度系统清理" : "Deep System Clean")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    // Magnifying Glass Icon
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass.circle.fill")
                        Text(loc.currentLanguage == .chinese ? "全面扫描" : "Full Scan")
                            .font(.system(size: 20, weight: .heavy))
                    }
                    .foregroundColor(.white)
                }
                
                Text(loc.currentLanguage == .chinese ? 
                     "扫描整个 Mac 的大文件、垃圾文件、缓存、日志及应用残留。\n上次扫描时间：从未" :
                     "Scan your entire Mac for large files, junk, caches, logs, and leftovers.\nLast scan: Never")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
                
                // Feature Rows
                VStack(alignment: .leading, spacing: 24) {
                    featureRow(
                        icon: "doc.text.magnifyingglass",
                        title: loc.currentLanguage == .chinese ? "查找大文件" : "Find Large Files",
                        desc: loc.currentLanguage == .chinese ? "快速定位占用空间的大文件和旧文件。" : "Quickly locate large and old files taking up space."
                    )
                    
                    featureRow(
                        icon: "trash.circle",
                        title: loc.currentLanguage == .chinese ? "清理系统垃圾" : "Clean System Junk",
                        desc: loc.currentLanguage == .chinese ? "移除缓存、日志和临时文件释放空间。" : "Remove caches, logs and temp files to free up space."
                    )
                    
                    featureRow(
                        icon: "app.badge",
                        title: loc.currentLanguage == .chinese ? "检测应用残留" : "Detect App Residuals",
                        desc: loc.currentLanguage == .chinese ? "查找已卸载应用遗留的文件和数据。" : "Find files and data left behind by uninstalled apps."
                    )
                }
                
                // Configure Button (Cyan)
                Button(action: {}) {
                    Text(loc.currentLanguage == .chinese ? "配置扫描选项..." : "Configure Scan Options...")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "4DDEE8")) // Cyan
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }
            .frame(maxWidth: 400)
            
            // Right Icon - Using shenduqingli.png
            ZStack {
                if let path = Bundle.main.path(forResource: "shenduqingli", ofType: "png"),
                   let nsImage = NSImage(contentsOfFile: path) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 320, height: 320)
                        .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
                } else {
                    // Fallback
                    RoundedRectangle(cornerRadius: 40)
                        .fill(LinearGradient(
                            colors: [Color(hex: "00B4D8"), Color(hex: "0077B6")],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 280, height: 280)
                        .overlay(
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 50)
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
    
    // MARK: - 2. Scanning View (扫描中页面 - 铺满布局)
    var scanningView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 自适应网格布局
            VStack(spacing: 20) {
                // Row 1: Large Files, System Junk, Log Files (铺满)
                HStack(spacing: 20) {
                    scanningCategoryCard(for: .largeFiles)
                    scanningCategoryCard(for: .junkFiles)
                    scanningCategoryCard(for: .systemLogs)
                }
                
                // Row 2: Caches, Residue (铺满左右)
                HStack(spacing: 20) {
                    scanningCategoryCard(for: .systemCaches)
                    scanningCategoryCard(for: .appResiduals)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Progress
            CircularActionButton(
                title: loc.currentLanguage == .chinese ? "停止" : "Stop",
                gradient: CircularActionButton.stopGradient,
                progress: scanner.scanProgress,
                showProgress: true,
                scanSize: ByteCountFormatter.string(fromByteCount: scanner.totalSize, countStyle: .file),
                action: {
                    scanner.stopScan()
                    viewState = .initial
                }
            )
            .padding(.bottom, 20)
            
            // Current scanning path
            Text(scanner.currentScanningUrl)
                .font(.caption)
                .foregroundColor(.secondaryText.opacity(0.6))
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .frame(height: 20)
        }
    }
    
    // MARK: - Scanning Card (图片背景卡片 - 自适应宽度)
    func scanningCategoryCard(for category: DeepCleanCategory) -> some View {
        let isCompleted = scanner.completedCategories.contains(category)
        let isCurrent = scanner.currentCategory == category && scanner.isScanning && !isCompleted
        
        return ZStack(alignment: .topLeading) {
            // 图片作为整个卡片的背景
            GeometryReader { geometry in
                if let imageName = getCategoryImageName(category),
                   let nsImage = NSImage(named: imageName) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: 240)
                        .clipped()
                        .scaleEffect(isCurrent ? 1.05 : 1.0)
                        .animation(isCurrent ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isCurrent)
                } else {
                    // 后备方案：渐变背景
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    getCategoryGradientTop(category),
                                    getCategoryGradientBottom(category)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geometry.size.width, height: 240)
                        .overlay(
                            Image(systemName: getCategoryCustomIcon(category))
                                .font(.system(size: 80, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
            }
            
            // 底部渐变遮罩（让文字更清晰）
            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 100)
            }
            
            // 左上角标记（参考设计图 - 所有卡片都显示）
            HStack(spacing: 8) {
                // 完成后显示勾选标记
                if isCompleted {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // 分类名称（所有卡片都显示）
                Text(category.localizedName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .padding(.leading, 16)
            .padding(.top, 16)
            
            // 扫描中的脉动边框
            if isCurrent {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(getCategoryGradientTop(category), lineWidth: 3)
                    .scaleEffect(1.05)
                    .opacity(0)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: isCurrent)
            }
            
            // 底部文字信息（统一样式）
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    // 主要文字（文件大小或状态）
                    if isCompleted {
                        let size = scanner.items.filter { $0.category == category }.reduce(0) { $0 + $1.size }
                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        let itemCount = scanner.items.filter { $0.category == category }.count
                        Text(loc.currentLanguage == .chinese ? "\(itemCount) 项" : "\(itemCount) items")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    } else if isCurrent {
                        Text(loc.currentLanguage == .chinese ? "扫描中..." : "Scanning...")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        // 显示当前扫描路径
                        if !scanner.currentScanningUrl.isEmpty {
                            Text(scanner.currentScanningUrl)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                    } else {
                        Text(loc.currentLanguage == .chinese ? "等待中..." : "Waiting...")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 240)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - 3. Results View (扫描结果页面 - 与扫描中页面布局完全一致)
    var resultsView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 大卡片网格（与扫描中页面完全一致的布局）
            VStack(spacing: 20) {
                // Row 1: 三张卡片铺满
                HStack(spacing: 20) {
                    resultCategoryCard(for: .largeFiles)
                    resultCategoryCard(for: .junkFiles)
                    resultCategoryCard(for: .systemLogs)
                }
                
                // Row 2: 两张卡片铺满左右
                HStack(spacing: 20) {
                    resultCategoryCard(for: .systemCaches)
                    resultCategoryCard(for: .appResiduals)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Action Button with Size Display (横向布局)
            HStack(spacing: 20) {
                CircularActionButton(
                    title: loc.currentLanguage == .chinese ? "运行" : "Clean",
                    gradient: CircularActionButton.greenGradient,
                    action: {
                        if scanner.selectedCount > 0 {
                            showCleanConfirmation = true
                        }
                    }
                )
                
                // Size Display (只显示大小数字)
                if scanner.selectedCount > 0 {
                    Text(ByteCountFormatter.string(fromByteCount: scanner.selectedSize, countStyle: .file))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "40C4FF"))
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Result Card (与扫描中页面完全一致)
    func resultCategoryCard(for category: DeepCleanCategory) -> some View {
        let items = scanner.items.filter { $0.category == category }
        let totalSize = items.reduce(0) { $0 + $1.size }
        let isCompleted = !items.isEmpty // 扫描结果页面所有分类都是完成状态
        
        return ZStack(alignment: .topLeading) {
                // 图片作为整个卡片的背景
                GeometryReader { geometry in
                    if let imageName = getCategoryImageName(category),
                       let nsImage = NSImage(named: imageName) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: 240)
                            .clipped()
                    } else {
                        // 后备方案：渐变背景
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        getCategoryGradientTop(category),
                                        getCategoryGradientBottom(category)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: geometry.size.width, height: 240)
                            .overlay(
                                Image(systemName: getCategoryCustomIcon(category))
                                    .font(.system(size: 80, weight: .medium))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }
                }
                .allowsHitTesting(false) // 让点击穿透到下层的按钮
                
                // 底部渐变遮罩（和扫描中一致）
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 100)
                }
                .allowsHitTesting(false) // 让点击穿透到下层的按钮
                
                // 左上角标记（和扫描中完全一致）
                HStack(spacing: 8) {
                    // 勾选标记（所有卡片都显示）
                    if isCompleted {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 分类名称
                    Text(category.localizedName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .padding(.leading, 16)
                .padding(.top, 16)
                
                // 底部文字信息（和扫描中完全一致）
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            Text(loc.currentLanguage == .chinese ? "\(items.count) 项" : "\(items.count) items")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.85))
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        
                        Spacer()
                        
                        // 右下角"查看详情"按钮
                        Button(action: {
                            selectedCategoryForDetails = category
                            showingDetails = true
                        }) {
                            Text(loc.currentLanguage == .chinese ? "查看详情" : "View Details")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 240)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    
    // MARK: - 4. Cleaning View (类似智能扫描的清理页面)
    var cleaningView: some View {
        VStack {
            Spacer().frame(height: 60)
            
            HStack(spacing: 80) {
                // Left: Current Category Image
                Group {
                    if let category = scanner.cleaningCurrentCategory {
                        let imageName = getCategoryImageName(category)
                        if let imageName = imageName,
                           let nsImage = NSImage(named: imageName) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 240, height: 240)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                                .id(category) // unique ID triggers transition
                                .modifier(CleaningLargeIconAnimation())
                        } else {
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 120))
                                .foregroundColor(.blue)
                        }
                    } else {
                        // Fallback
                        ProgressView()
                            .scaleEffect(2.0)
                            .frame(width: 240, height: 240)
                    }
                }
                .animation(.easeInOut(duration: 0.6), value: scanner.cleaningCurrentCategory)
                .frame(width: 300)
                
                // Right: Text & Task List
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(loc.currentLanguage == .chinese ? "正在清理系统..." : "Cleaning System...")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(loc.currentLanguage == .chinese ? "正在移除不需要的文件，优化您的 Mac。" : "Removing unwanted files and optimizing your Mac.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    VStack(spacing: 16) {
                        // Only show categories with selected items (只显示有选中项目的分类)
                        let allCategories: [DeepCleanCategory] = [.junkFiles, .systemLogs, .systemCaches, .appResiduals, .largeFiles]
                        let categoriesToShow = allCategories.filter { cat in
                            scanner.items.contains { $0.category == cat && $0.isSelected }
                        }
                        
                        ForEach(categoriesToShow, id: \.self) { cat in
                            let isActive = scanner.cleaningCurrentCategory == cat
                            let isDone = scanner.cleanedCategories.contains(cat)
                            
                            HStack(spacing: 12) {
                                // Icon Circle
                                ZStack {
                                    Circle()
                                        .fill(getCategoryGradientTop(cat).opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(getCategoryGradientTop(cat))
                                }
                                
                                Text(cat.localizedName)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if isActive {
                                    Text(scanner.cleaningDescription)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.4))
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .frame(width: 20, height: 20)
                                } else if isDone {
                                    Text(ByteCountFormatter.string(fromByteCount: scanner.sizeFor(category: cat), countStyle: .file))
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.4))
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.green)
                                } else {
                                    Text("...")
                                        .foregroundColor(.white.opacity(0.2))
                                }
                            }
                            .frame(width: 340)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 500)
            
            Spacer()
        }
    }
    
    // MARK: - 5. Finished View (类似智能扫描的完成页面)
    var finishedView: some View {
        VStack {
            Spacer().frame(height: 100)
            
            HStack(spacing: 60) {
                // Left: Hero Image
                if let imagePath = Bundle.main.path(forResource: "welcome", ofType: "png"),
                   let nsImage = NSImage(contentsOfFile: imagePath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 500, height: 500)
                } else {
                    Image(systemName: "desktopcomputer")
                        .resizable()
                        .frame(width: 300, height: 300)
                        .foregroundColor(.pink)
                }
                
                // Right: Results
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(loc.currentLanguage == .chinese ? "做得不错！" : "Well done!")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text(loc.currentLanguage == .chinese ? "您的 Mac 状态很好。" : "Your Mac is in good shape.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    VStack(spacing: 12) {
                        // 1. Deep Cleanup Result
                        DeepCleanResultRow(
                            icon: getCategoryImageName(.junkFiles) ?? "system_clean",
                            title: loc.currentLanguage == .chinese ? "深度清理" : "Deep Clean",
                            subtitle: loc.currentLanguage == .chinese ? "不需要的文件已移除" : "Files removed",
                            stat: ByteCountFormatter.string(fromByteCount: scanner.cleanedSize, countStyle: .file)
                        )
                        
                        // 2. Items Cleaned
                        if let result = cleanResult {
                            DeepCleanResultRow(
                                icon: "trash.fill",
                                title: loc.currentLanguage == .chinese ? "清理项目" : "Items Cleaned",
                                subtitle: loc.currentLanguage == .chinese ? "已成功清理" : "Successfully cleaned",
                                stat: "\(result.count) " + (loc.currentLanguage == .chinese ? "个项目" : "items")
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 550)
            
            Spacer()
        }
        .overlay(
            // Bottom: Done Button
            VStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        viewState = .initial
                        scanner.reset()
                        cleanResult = nil
                    }
                }) {
                    Text(loc.currentLanguage == .chinese ? "完成" : "Done")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 160, height: 50)
                        .background(Color.green)
                        .cornerRadius(25)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
        )
    }
    
    // MARK: - 辅助函数
    private func getCategoryGradientTop(_ category: DeepCleanCategory) -> Color {
        switch category {
        case .largeFiles: return Color(hex: "FF6B9D") // 粉红
        case .junkFiles: return Color(hex: "FF5757") // 红色
        case .systemLogs: return Color(hex: "5B9BD5") // 蓝色
        case .systemCaches: return Color(hex: "70C1B3") // 青色
        case .appResiduals: return Color(hex: "FFD93D") // 黄色
        }
    }
    
    private func getCategoryGradientBottom(_ category: DeepCleanCategory) -> Color {
        switch category {
        case .largeFiles: return Color(hex: "C23B8C") // 深粉
        case .junkFiles: return Color(hex: "B80F0A") // 深红
        case .systemLogs: return Color(hex: "2E5C8A") // 深蓝
        case .systemCaches: return Color(hex: "29A39B") // 深青
        case .appResiduals: return Color(hex: "F77F00") // 橙色
        }
    }
    
    private func getCategoryCustomIcon(_ category: DeepCleanCategory) -> String {
        switch category {
        case .largeFiles: return "doc.fill"
        case .junkFiles: return "trash.fill"
        case .systemLogs: return "doc.text.fill"
        case .systemCaches: return "server.rack"
        case .appResiduals: return "app.badge"
        }
    }
    
    private func getCategoryImageName(_ category: DeepCleanCategory) -> String? {
        switch category {
        case .largeFiles: return "deepclean_large_files"
        case .junkFiles: return "deepclean_system_junk"
        case .systemLogs: return "deepclean_log_files"
        case .systemCaches: return "deepclean_cache_files"
        case .appResiduals: return "deepclean_app_residue"
        }
    }
}

// MARK: - Detail View (详情页面 - 保持之前的实现)
struct DeepCleanDetailView: View {
    @ObservedObject var scanner: DeepCleanScanner
    var category: DeepCleanCategory?
    @Binding var isPresented: Bool
    @State private var selectedCategory: DeepCleanCategory?
    @ObservedObject private var loc = LocalizationManager.shared
    
    var body: some View {
        HSplitView {
            // Left Sidebar
            leftSidebar
                .frame(width: 280)
            
            // Right Content
            if let category = selectedCategory {
                rightPane(for: category)
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "arrow.left")
                        .font(.system(size: 48))
                        .foregroundColor(.secondaryText.opacity(0.5))
                    Text(loc.currentLanguage == .chinese ? "选择左侧分类查看详情" : "Select a category to view details")
                        .font(.title3)
                        .foregroundColor(.secondaryText)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 900, height: 650)
        .background(BackgroundStyles.deepClean)
        .onAppear {
            if let initial = category {
                selectedCategory = initial
            } else if selectedCategory == nil {
                selectedCategory = DeepCleanCategory.allCases.first
            }
        }
    }
    
    // MARK: - Left Sidebar
    private var leftSidebar: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { isPresented = false }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text(loc.currentLanguage == .chinese ? "返回概要" : "Back to Overview")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: selectAllItems) {
                    Text(loc.currentLanguage == .chinese ? "全选" : "Select All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "40C4FF"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color.white.opacity(0.05))
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(DeepCleanCategory.allCases, id: \.self) { cat in
                        categorySidebarRow(cat)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(width: 280)
        .background(Color.black.opacity(0.2))
    }
    
    private func categorySidebarRow(_ category: DeepCleanCategory) -> some View {
        let items = scanner.items.filter { $0.category == category }
        let totalSize = items.reduce(0) { $0 + $1.size }
        let isSelected = selectedCategory == category
        
        // 计算勾选状态
        let selectedCount = items.filter { $0.isSelected }.count
        let checkState: SelectionState = {
            if items.isEmpty || selectedCount == 0 { return .none }
            if selectedCount == items.count { return .all }
            return .partial
        }()
        
        return Button(action: {
            selectedCategory = category
        }) {
            HStack(spacing: 10) {
                // 三态勾选框（紧凑型）
                ZStack {
                    Circle()
                        .stroke(checkState != .none ? Color(hex: "40C4FF") : Color.white.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    
                    if checkState == .all {
                        Circle()
                            .fill(Color(hex: "40C4FF"))
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    } else if checkState == .partial {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 18, height: 18)
                        Image(systemName: "minus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Task { @MainActor in
                        scanner.toggleCategorySelection(category, to: checkState != .all)
                    }
                }
                
                // 小图标（紧凑型）
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    getCategoryGradientTop(category).opacity(0.3),
                                    getCategoryGradientBottom(category).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(getCategoryGradientTop(category))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.localizedName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 3) {
                        Text("\(items.count)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondaryText)
                        
                        Text("·")
                            .font(.system(size: 10))
                            .foregroundColor(.secondaryText.opacity(0.5))
                        
                        Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "40C4FF"))
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    // 勾选状态枚举
    private enum SelectionState {
        case none, partial, all
    }
    
    // MARK: - Right Pane
    private func rightPane(for category: DeepCleanCategory) -> some View {
        let items = scanner.items.filter { $0.category == category }
        
        return VStack(spacing: 0) {
            // Header（紧凑型）
            VStack(alignment: .leading, spacing: 6) {
                Text(category.localizedName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                let totalSize = items.reduce(0) { $0 + $1.size }
                Text("\(items.count) \(loc.currentLanguage == .chinese ? "个项目" : "items"), \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.05))
            
            // Items List
            if items.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text(loc.currentLanguage == .chinese ? "该分类暂无项目" : "No items in this category")
                        .font(.title3)
                        .foregroundColor(.secondaryText)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            DeepCleanItemRow(item: item, scanner: scanner)
                            
                            if item.id != items.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func selectAllItems() {
        guard let category = selectedCategory else { return }
        scanner.toggleCategorySelection(category, to: true)
    }
    
    // 辅助函数
    private func getCategoryGradientTop(_ category: DeepCleanCategory) -> Color {
        switch category {
        case .largeFiles: return Color(hex: "FF6B9D")
        case .junkFiles: return Color(hex: "FF5757")
        case .systemLogs: return Color(hex: "5B9BD5")
        case .systemCaches: return Color(hex: "70C1B3")
        case .appResiduals: return Color(hex: "FFD93D")
        }
    }
    
    private func getCategoryGradientBottom(_ category: DeepCleanCategory) -> Color {
        switch category {
        case .largeFiles: return Color(hex: "C23B8C")
        case .junkFiles: return Color(hex: "B80F0A")
        case .systemLogs: return Color(hex: "2E5C8A")
        case .systemCaches: return Color(hex: "29A39B")
        case .appResiduals: return Color(hex: "F77F00")
        }
    }
}

// MARK: - Item Row（紧凑型）
struct DeepCleanItemRow: View {
    let item: DeepCleanItem
    @ObservedObject var scanner: DeepCleanScanner
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox（紧凑型）
            ZStack {
                Circle()
                    .stroke(item.isSelected ? Color(hex: "40C4FF") : Color.white.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 16, height: 16)
                
                if item.isSelected {
                    Circle()
                        .fill(Color(hex: "40C4FF"))
                        .frame(width: 16, height: 16)
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Task { @MainActor in
                    scanner.toggleSelection(for: item)
                }
            }
            
            // Icon（更小）
            Image(systemName: "doc.fill")
                .font(.system(size: 12))
                .foregroundColor(.blue.opacity(0.8))
                .frame(width: 20)
            
            // Name & Path（紧凑字体）
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(item.url.path)
                    .font(.system(size: 9))
                    .foregroundColor(.secondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Size（更小）
            Text(item.formattedSize)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "40C4FF"))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.white.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Deep Clean Result Row (清理完成结果行)
struct DeepCleanResultRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let stat: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            if let nsImage = NSImage(named: icon) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            } else {
                // Fallback SF Symbol
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
            }
            
            // Title & Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Stat
            Text(stat)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "40C4FF"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .frame(width: 400)
    }
}
