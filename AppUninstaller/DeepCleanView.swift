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
            // Background
            
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
        .onChange(of: scanner.isCleaning) { isCleaning in
             if isCleaning { viewState = .cleaning }
             else if cleanResult != nil { viewState = .finished }
        }
        .sheet(isPresented: $showingDetails) {
            DeepCleanDetailView(scanner: scanner, category: selectedCategoryForDetails, isPresented: $showingDetails)
        }
        .confirmationDialog(loc.L("confirm_clean"), isPresented: $showCleanConfirmation) {
            Button(loc.currentLanguage == .chinese ? "开始清理" : "Start Cleaning", role: .destructive) {
                Task {
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
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 180, height: 180)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 80))
                    .foregroundColor(.cyan)
            }
            .padding(.bottom, 40)
            
            // Title
            Text(loc.currentLanguage == .chinese ? "深度系统清理" : "Deep System Clean")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, 12)
            
            Text(loc.currentLanguage == .chinese ? 
                 "扫描整个 Mac 的大文件、垃圾文件、缓存、日志及应用残留。" :
                 "Scan your entire Mac for large files, junk, caches, logs, and leftovers.")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
                .padding(.bottom, 60)
            
            Spacer()
            
            // Start Button (using CircularActionButton)
            CircularActionButton(
                title: loc.currentLanguage == .chinese ? "扫描" : "Scan",
                gradient: CircularActionButton.blueGradient,
                action: {
                    Task { await scanner.startScan() }
                }
            )
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - 2. Scanning View (扫描中页面)
    var scanningView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 3-2 Grid Layout
            VStack(spacing: 20) {
                // Row 1: Large items, Junk, Logs
                HStack(spacing: 20) {
                    ForEach([DeepCleanCategory.largeFiles, .junkFiles, .systemLogs], id: \.self) { cat in
                        scanningCategoryCard(for: cat)
                    }
                }
                
                // Row 2: Caches, Residue
                HStack(spacing: 20) {
                    ForEach([DeepCleanCategory.systemCaches, .appResiduals], id: \.self) { cat in
                        scanningCategoryCard(for: cat)
                    }
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
            
            // Current scanning path (at bottom, like Smart Scan)
            Text(scanner.currentScanningUrl)
                .font(.caption)
                .foregroundColor(.secondaryText.opacity(0.6))
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .frame(height: 20) // Fixed height to prevent jump
        }
    }
    
    // MARK: - Scanning Card Helper
    func scanningCategoryCard(for category: DeepCleanCategory) -> some View {
        let isCompleted = scanner.completedCategories.contains(category)
        let isCurrent = scanner.currentCategory == category && scanner.isScanning && !isCompleted
        
        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: category.icon)
                        .font(.system(size: 36))
                        .foregroundColor(isCurrent ? category.color : category.color.opacity(0.5)) // Dim if waiting
                        .scaleEffect(isCurrent ? 1.1 : 1.0)
                        .animation(isCurrent ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isCurrent)
                }
                
                // Ring for current
                if isCurrent {
                    Circle()
                        .stroke(category.color.opacity(0.5), lineWidth: 2)
                        .frame(width: 84, height: 84)
                        .scaleEffect(1.1)
                        .opacity(0)
                        .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: isCurrent)
                }
            }
            
            VStack(spacing: 4) {
                Text(category.localizedName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if isCompleted {
                    let size = scanner.items.filter { $0.category == category }.reduce(0) { $0 + $1.size }
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                } else if isCurrent {
                    Text(LocalizationManager.shared.currentLanguage == .chinese ? "扫描中..." : "Scanning...")
                        .font(.caption)
                        .foregroundColor(category.color)
                } else {
                    Text(LocalizationManager.shared.currentLanguage == .chinese ? "等待中..." : "Waiting...")
                        .font(.caption)
                        .foregroundColor(.secondaryText.opacity(0.5))
                }
            }
        }
        .frame(width: 140)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.02))
        .cornerRadius(16)
    }
    
    // MARK: - 4. Cleaning View (清理中页面 - Dashboard Style)
    var cleaningView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Dashboard Grid for Cleaning - 3-2 Layout
            VStack(spacing: 20) {
                // Row 1
                HStack(spacing: 20) {
                    ForEach([DeepCleanCategory.largeFiles, .junkFiles, .systemLogs], id: \.self) { cat in
                        cleaningCategoryCard(for: cat)
                    }
                }
                // Row 2
                HStack(spacing: 20) {
                    ForEach([DeepCleanCategory.systemCaches, .appResiduals], id: \.self) { cat in
                        cleaningCategoryCard(for: cat)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 16) {
                // Display current item being cleaned
                Text(scanner.currentCleaningItem)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(height: 20)
                
                Text(scanner.scanStatus)
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: scanner.cleaningProgress)
                        .stroke(Color(hex: "00E8A8"), lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text(String(format: "%.0f%%", scanner.cleaningProgress * 100))
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 80)
        }
    }
    
    func cleaningCategoryCard(for category: DeepCleanCategory) -> some View {
        let isSelected = scanner.items.contains { $0.category == category && $0.isSelected }
        let isCurrent = scanner.currentCategory == category && scanner.isCleaning
        let isDone = !scanner.items.contains { $0.category == category } // If no items left (cleaned or empty)
        
        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                if isCurrent {
                    ProgressView()
                         .progressViewStyle(CircularProgressViewStyle(tint: category.color))
                         .scaleEffect(1.5)
                } else if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .bold)) // Cleaned
                        .foregroundColor(.green)
                } else if !isSelected {
                     Image(systemName: "minus.circle.fill") // Skipped
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.5))
                } else {
                     // Waiting to be cleaned
                     Image(systemName: category.icon)
                        .font(.system(size: 30))
                        .foregroundColor(category.color.opacity(0.5))
                }
            }
            
            Text(category.localizedName)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(width: 140)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.02))
        .cornerRadius(16)
    }
    
    // MARK: - 3. Results View (扫描结果页面)
    var resultsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                 Spacer()
                 Button(action: {
                     viewState = .initial
                     scanner.reset()
                 }) {
                     HStack(spacing: 6) {
                         Image(systemName: "arrow.clockwise")
                         Text(loc.currentLanguage == .chinese ? "重新扫描" : "Rescan")
                     }
                     .font(.system(size: 14, weight: .medium))
                     .foregroundColor(.white.opacity(0.8))
                     .padding(.horizontal, 12)
                     .padding(.vertical, 6)
                     .background(Color.white.opacity(0.1))
                     .cornerRadius(8)
                 }
                 .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
            
            // Dashboard Grid (Results Mode) - 3-2 Layout
            VStack(spacing: 20) {
                // Row 1
                HStack(spacing: 20) {
                    ForEach([DeepCleanCategory.largeFiles, .junkFiles, .systemLogs], id: \.self) { cat in
                        resultCategoryCard(for: cat)
                    }
                }
                // Row 2
                HStack(spacing: 20) {
                    ForEach([DeepCleanCategory.systemCaches, .appResiduals], id: \.self) { cat in
                        resultCategoryCard(for: cat)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Bottom Action Bar
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(LocalizationManager.shared.currentLanguage == .chinese ? "已选择" : "Selected")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Text(ByteCountFormatter.string(fromByteCount: scanner.selectedSize, countStyle: .file))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                
                
                // Start Cleaning Button
                CircularActionButton(
                    title: LocalizationManager.shared.currentLanguage == .chinese ? "运行" : "Run",
                    gradient: LinearGradient(colors: [Color(hex: "28C76F"), Color(hex: "00C853")], startPoint: .topLeading, endPoint: .bottomTrailing), // Green Gradient
                    scanSize: nil, // Only show "Run" text
                    action: {
                        if scanner.selectedCount > 0 {
                            showCleanConfirmation = true
                        }
                    }
                )
                .disabled(scanner.selectedCount == 0)
                .opacity(scanner.selectedCount == 0 ? 0.6 : 1.0)
            }
            .padding(.bottom, 40)
        }
    }
    
    func resultCategoryCard(for category: DeepCleanCategory) -> some View {
        let items = scanner.items.filter { $0.category == category }
        let size = items.reduce(0) { $0 + $1.size }
        
        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: category.icon)
                    .font(.system(size: 36))
                    .foregroundColor(category.color)
            }
            
            VStack(spacing: 4) {
                Text(category.localizedName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.white)
                
                Button(action: {
                    selectedCategoryForDetails = category
                    showingDetails = true
                }) {
                    Text(LocalizationManager.shared.currentLanguage == .chinese ? "查看详情" : "Details")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 14)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .frame(width: 140)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.02))
        .cornerRadius(16)
    }
    

    
    // MARK: - 5. Finished View (清理完成页面)
    var finishedView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.5), radius: 20, x: 0, y: 0)
            
            Text(loc.currentLanguage == .chinese ? "清理完成！" : "Cleanup Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let result = cleanResult {
                VStack(spacing: 12) {
                    Text(loc.currentLanguage == .chinese ? 
                         "成功释放空间：" : "Space Freed:")
                        .font(.headline)
                        .foregroundColor(.secondaryText)
                    
                    Text(ByteCountFormatter.string(fromByteCount: result.size, countStyle: .file))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                    
                    Text(loc.currentLanguage == .chinese ? 
                         "删除了 \(result.count) 个不需要的文件" :
                         "Removed \(result.count) unwanted files")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
                .padding(.vertical, 20)
            }
            
            Spacer()
            
            Button(action: {
                viewState = .initial
                scanner.reset()
                cleanResult = nil
            }) {
                Text(loc.currentLanguage == .chinese ? "好的" : "Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.green)
                    .cornerRadius(25)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - 6. Detail View Setup (Split View)
// MARK: - 6. Detail View Setup (Split View)
struct DeepCleanDetailView: View {
    @ObservedObject var scanner: DeepCleanScanner
    @State var selectedCategory: DeepCleanCategory? // Local state for sidebar selection
    @Binding var isPresented: Bool
    
    // Binding passed from parent to initialize selection
    var initialCategory: DeepCleanCategory?
    
    init(scanner: DeepCleanScanner, category: DeepCleanCategory?, isPresented: Binding<Bool>) {
        self.scanner = scanner
        self._selectedCategory = State(initialValue: category ?? .junkFiles)
        self._isPresented = isPresented
        self.initialCategory = category
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                 Button(action: { isPresented = false }) {
                     HStack(spacing: 4) {
                         Image(systemName: "chevron.left")
                         Text(LocalizationManager.shared.currentLanguage == .chinese ? "返回摘要" : "Back")
                     }
                     .foregroundColor(.secondaryText)
                 }
                 .buttonStyle(.plain)
                 
                 Spacer()
                 
                 Text(LocalizationManager.shared.currentLanguage == .chinese ? "清理详情" : "Cleanup Details")
                     .font(.headline)
                     .foregroundColor(.white)
                 
                 Spacer()
                 
                 // Placeholder for alignment
                 HStack(spacing: 4) { Image(systemName: "chevron.left"); Text("Back") }.opacity(0)
            }
            .padding()
            .background(.ultraThinMaterial) // Glassmorphism Header
            
            HStack(spacing: 0) {
                // Left Sidebar: Categories
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(LocalizationManager.shared.currentLanguage == .chinese ? "扫描结果" : "Scan Results")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(DeepCleanCategory.allCases, id: \.self) { category in
                                categorySidebarRow(category)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .frame(width: 280)
                .background(.thinMaterial) // Glassy Sidebar
                
                // Right Content: Items
                if let category = selectedCategory {
                    rightPane(for: category)
                } else {
                    VStack {
                        Spacer()
                        Image(systemName: "arrow.left")
                            .font(.system(size: 48))
                            .foregroundColor(.secondaryText.opacity(0.5))
                        Text(LocalizationManager.shared.currentLanguage == .chinese ? "选择左侧分类查看详情" : "Select a category to view details")
                            .font(.title3)
                            .foregroundColor(.secondaryText)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(width: 900, height: 650)
        .background(
            ZStack {
                Color(red: 0.1, green: 0.05, blue: 0.2) // Deep base
                // Ambient glow
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .blur(radius: 80)
                    .offset(x: -200, y: -200)
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .blur(radius: 80)
                    .offset(x: 200, y: 200)
            }
        )
        .onAppear {
            if let initial = initialCategory {
                selectedCategory = initial
            } else if selectedCategory == nil {
                // Default to first category with items, or just first category
                selectedCategory = DeepCleanCategory.allCases.first
            }
        }
    }
    
    func categorySidebarRow(_ category: DeepCleanCategory) -> some View {
        let items = scanner.items.filter { $0.category == category }
        let size = items.reduce(0) { $0 + $1.size }
        let isSelected = selectedCategory == category
        
        return Button(action: {
            selectedCategory = category
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(category.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(category.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.localizedName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    
                    Text("\(items.count) " + (LocalizationManager.shared.currentLanguage == .chinese ? "项" : "items"))
                        .font(.caption2)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    func rightPane(for category: DeepCleanCategory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title Area
            VStack(alignment: .leading, spacing: 8) {
                Text(category.localizedName)
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                let items = scanner.items.filter { $0.category == category }
                Text("\(items.count) " + (LocalizationManager.shared.currentLanguage == .chinese ? "个项目，共 " : "items, ") + ByteCountFormatter.string(fromByteCount: items.reduce(0) { $0 + $1.size }, countStyle: .file))
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            .padding()
            
            // Filte List
            ScrollView {
                LazyVStack(spacing: 8) {
                    let items = scanner.items.filter { $0.category == category }.sorted { $0.size > $1.size }
                    if items.isEmpty {
                        Text(LocalizationManager.shared.currentLanguage == .chinese ? "无项目" : "No items")
                            .foregroundColor(.secondaryText)
                            .padding(.top, 40)
                    } else {
                        ForEach(items) { item in
                            DeepCleanItemRow(item: item, scanner: scanner)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct DeepCleanItemRow: View {
    let item: DeepCleanItem
    @ObservedObject var scanner: DeepCleanScanner
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { _ in scanner.toggleSelection(for: item) }
            ))
            .toggleStyle(CheckboxStyle())
            .labelsHidden()
            
            if let icon = item.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            } else {
                Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                Text(item.url.path)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            Text(item.formattedSize)
                .foregroundColor(.secondaryText)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}
