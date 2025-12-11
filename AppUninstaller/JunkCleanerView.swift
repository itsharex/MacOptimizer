import SwiftUI

struct JunkCleanerView: View {
    @StateObject private var cleaner = JunkCleaner()
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var showingCleanAlert = false
    @State private var cleanedAmount: Int64 = 0
    @State private var animateScan = false
    @State private var pulse = false
    @State private var searchText = ""
    
    // 汇总状态
    var totalFoundSize: Int64 {
        cleaner.junkItems.reduce(0) { $0 + $1.size }
    }
    
    var filteredItems: [JunkItem] {
        if searchText.isEmpty {
            return cleaner.junkItems
        } else {
            return cleaner.junkItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 头部
                headerView
                
                if cleaner.isScanning {
                    scanningView
                } else if cleaner.junkItems.isEmpty {
                    emptyStateView
                } else {
                    // 内容区
                    contentView
                }
            }
        }
        .onAppear {
            if cleaner.junkItems.isEmpty {
                Task { await cleaner.scanJunk() }
            }
        }
        .alert(loc.L("clean_complete"), isPresented: $showingCleanAlert) {
            Button(loc.L("confirm"), role: .cancel) {}
        } message: {
            Text(loc.currentLanguage == .chinese ? "成功清理了 \(ByteCountFormatter.string(fromByteCount: cleanedAmount, countStyle: .file)) 的垃圾文件。" : "Cleaned \(ByteCountFormatter.string(fromByteCount: cleanedAmount, countStyle: .file)) of junk files.")
        }
    }
    
    // MARK: - 头部视图
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.currentLanguage == .chinese ? "系统垃圾" : "System Junk")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                Text(loc.currentLanguage == .chinese ? "发现可清理的系统垃圾文件" : "Found cleanable system junk files")
                    .foregroundColor(.secondaryText)
            }
            Spacer()
            
            // 搜索框
            if !cleaner.isScanning && !cleaner.junkItems.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondaryText)
                    TextField(loc.currentLanguage == .chinese ? "搜索文件..." : "Search files...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .frame(width: 250)
            }
        }
        .padding(24)
        .padding(.bottom, 0)
    }
    
    // MARK: - 内容视图
    private var contentView: some View {
        VStack(spacing: 20) {
            // 顶部统计卡片
            statsCardsView
                .padding(.horizontal, 24)
            
            // 左右分栏
            HStack(alignment: .top, spacing: 20) {
                // 左侧列表
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc.currentLanguage == .chinese ? "可清理文件 (\(filteredItems.count) 项)" : "Cleanable Files (\(filteredItems.count) items)")
                        .font(.headline)
                        .foregroundColor(.secondaryText)
                        .padding(.leading, 4)
                    
                    fileListView
                }
                .frame(maxWidth: .infinity)
                
                // 右侧预览区
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc.currentLanguage == .chinese ? "清理效果预览" : "Cleanup Result Preview")
                        .font(.headline)
                        .foregroundColor(.secondaryText)
                    
                    cleanupPreviewCard
                }
                .frame(width: 280)
            }
            .padding(.horizontal, 24)
            
            // 底部操作栏
            bottomActionBar
        }
        .padding(.top, 10)
    }
    
    // MARK: - 统计卡片
    private var statsCardsView: some View {
        HStack(spacing: 16) {
            JunkStatsCard(
                icon: "trash.fill",
                title: loc.currentLanguage == .chinese ? "垃圾文件" : "Junk Files",
                count: count(for: .junk),
                size: size(for: .junk),
                color: .blue
            )
            
            JunkStatsCard(
                icon: "archivebox.fill",
                title: loc.currentLanguage == .chinese ? "缓存文件" : "Cache Files",
                count: count(for: .cache),
                size: size(for: .cache),
                color: .purple
            )
            
            JunkStatsCard(
                icon: "doc.text.fill",
                title: loc.currentLanguage == .chinese ? "日志文件" : "Log Files",
                count: count(for: .log),
                size: size(for: .log),
                color: .green
            )
        }
    }
    
    // MARK: - 文件列表
    private var fileListView: some View {
        List {
            ForEach(filteredItems) { item in
                HStack(spacing: 12) {
                    Toggle("", isOn: Binding(
                        get: { item.isSelected },
                        set: { newValue in
                            item.isSelected = newValue
                            cleaner.objectWillChange.send()
                        }
                    ))
                    .toggleStyle(CheckboxStyle())
                    .labelsHidden()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: item.type.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primaryText)
                            .lineLimit(1)
                        Text(item.type.description) // 使用描述作为类型/来源展示
                            .font(.system(size: 11))
                            .foregroundColor(.tertiaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                }
                .listRowBackground(Color.cardBackground)
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - 清理预览卡片
    private var cleanupPreviewCard: some View {
        VStack(spacing: 24) {
            // 前
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 24))
                    .foregroundColor(.secondaryText)
                    .frame(width: 40)
                
                VStack(alignment: .leading) {
                    Text(loc.currentLanguage == .chinese ? "系统垃圾" : "System Junk")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Text(ByteCountFormatter.string(fromByteCount: totalFoundSize, countStyle: .file))
                        .font(.title2)
                        .foregroundColor(.secondaryText)
                }
                Spacer()
            }
            .padding(.top, 16)
            
            // 箭头
            Image(systemName: "arrow.down")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.3))
            
            // 后
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
                    .frame(width: 40)
                
                VStack(alignment: .leading) {
                    Text(loc.currentLanguage == .chinese ? "即将清理" : "To Clean")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Text(ByteCountFormatter.string(fromByteCount: cleaner.selectedSize, countStyle: .file))
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                }
                Spacer()
            }
            .padding(.bottom, 16)
            
            Divider().background(Color.white.opacity(0.1))
            
            Button(action: {
                // View Details logic if needed, currently detail IS the list on left
            }) {
                Text(loc.currentLanguage == .chinese ? "查看详情" : "View Details")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - 底部操作栏
    private var bottomActionBar: some View {
        HStack {
            Button(loc.currentLanguage == .chinese ? "查看详情" : "View Details") {
                // Placeholder
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
            .opacity(0) // Hidden but keeps alignment if needed, or just remove
            
            Spacer()
            
            Button(action: {
                generateHapticFeedback()
                Task {
                    let result = await cleaner.cleanSelected()
                    cleanedAmount = result.cleaned
                    showingCleanAlert = true
                }
            }) {
                Text(loc.currentLanguage == .chinese ? "清理" : "Clean")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 44)
                    .background(
                        LinearGradient(colors: [.green, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(22)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(cleaner.selectedSize == 0)
            
            Spacer()
            
            Button(loc.currentLanguage == .chinese ? "跳过" : "Skip") {
                // Action
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondaryText)
            .opacity(0) // Placeholder
        }
        .padding(24)
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - 扫描动画视图 (保留)
    private var scanningView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                // 外层脉冲
                Circle()
                    .fill(GradientStyles.cleaner.opacity(0.1))
                    .frame(width: 240, height: 240)
                    .scaleEffect(pulse ? 1.2 : 1.0)
                    .opacity(pulse ? 0 : 0.5)
                    .onAppear {
                        withAnimation(Animation.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                            pulse = true
                        }
                    }
                
                // 旋转光环
                Circle()
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [.cleanerStart.opacity(0), .cleanerStart]), center: .center),
                        lineWidth: 4
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(animateScan ? 360 : 0))
                    .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: animateScan)
                    .onAppear { animateScan = true }
                
                // 中心图标
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundStyle(GradientStyles.cleaner)
            }
            
            VStack(spacing: 12) {
                Text(loc.currentLanguage == .chinese ? "正在深入扫描..." : "Deep Scanning...")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                ProgressView(value: cleaner.scanProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .cleanerStart))
                    .frame(width: 240)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.success.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(GradientStyles.cleaner)
            }
            
            VStack(spacing: 8) {
                Text(loc.currentLanguage == .chinese ? "系统非常干净" : "System is Very Clean")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(loc.currentLanguage == .chinese ? "没有发现需要清理的垃圾文件" : "No junk files found")
                    .foregroundColor(.secondaryText)
            }
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    enum StatsCategory {
        case junk, cache, log
    }
    
    private func filterItems(_ category: StatsCategory) -> [JunkItem] {
        cleaner.junkItems.filter { item in
            switch category {
            case .cache:
                return [.userCache, .systemCache, .browserCache, .appCache, .chatCache, .xcodeDerivedData].contains(item.type)
            case .log:
                return [.userLogs, .systemLogs, .crashReports].contains(item.type)
            case .junk:
                return [.tempFiles, .mailAttachments].contains(item.type)
            }
        }
    }
    
    private func count(for category: StatsCategory) -> Int {
        filterItems(category).count
    }
    
    private func size(for category: StatsCategory) -> Int64 {
        filterItems(category).reduce(0) { $0 + $1.size }
    }
    
    private func generateHapticFeedback() {
        let haptic = NSHapticFeedbackManager.defaultPerformer
        haptic.perform(.alignment, performanceTime: .default)
    }
}

// MARK: - 垃圾统计卡片
struct JunkStatsCard: View {
    let icon: String
    let title: String
    let count: Int
    let size: Int64
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondaryText)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(count)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("项")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.caption)
                    .foregroundColor(.tertiaryText)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
