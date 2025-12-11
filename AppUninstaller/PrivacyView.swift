import SwiftUI

struct PrivacyView: View {
    @Binding var selectedModule: AppModule
    @StateObject private var service = PrivacyScannerService()
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var showingCleanAlert = false
    @State private var cleanResult: (cleaned: Int64, failed: Int64)?
    @State private var pulse = false
    @State private var animateScan = false
    @State private var showingCloseBrowserAlert = false
    @State private var showingDetails = false
    
    // 汇总状态
    var totalFoundSize: Int64 {
        service.totalSize
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 头部
                headerView
                
                if service.isScanning {
                    scanningView
                } else if service.privacyItems.isEmpty {
                    emptyStateView
                } else {
                    // 内容区
                    contentView
                }
            }
        }
        .onAppear {
            if service.privacyItems.isEmpty {
                Task { await service.scanAll() }
            }
        }
        .alert(loc.currentLanguage == .chinese ? "清理完成" : "Cleanup Complete", isPresented: $showingCleanAlert) {
            Button(loc.L("confirm"), role: .cancel) {}
        } message: {
            if let result = cleanResult {
                Text(loc.currentLanguage == .chinese ?
                     "已清理隐私数据: \(ByteCountFormatter.string(fromByteCount: result.cleaned, countStyle: .file))" :
                     "Cleaned privacy data: \(ByteCountFormatter.string(fromByteCount: result.cleaned, countStyle: .file))")
            }
        }
        .sheet(isPresented: $showingDetails) {
            detailSheet
        }
    }
    
    // MARK: - 头部视图
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.currentLanguage == .chinese ? "隐私保护" : "Privacy Protection")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                Text(loc.currentLanguage == .chinese ? "保护您的隐私数据安全" : "Protect your privacy data")
                    .foregroundColor(.secondaryText)
            }
            Spacer()
            
            // 搜索或状态
            if !service.isScanning {
                HStack {
                    Image(systemName: "shield.check.fill")
                        .foregroundColor(.green)
                    Text(loc.currentLanguage == .chinese ? "隐私保护已开启" : "Privacy Protection On")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
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
                    Text(loc.currentLanguage == .chinese ? "隐私数据项 (\(service.privacyItems.count))" : "Privacy Items (\(service.privacyItems.count))")
                        .font(.headline)
                        .foregroundColor(.secondaryText)
                        .padding(.leading, 4)
                    
                    privacyListView
                }
                .frame(maxWidth: .infinity)
                
                // 右侧预览区
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc.currentLanguage == .chinese ? "隐私保护效果" : "Privacy Result")
                        .font(.headline)
                        .foregroundColor(.secondaryText)
                    
                    privacyPreviewCard
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
            PrivacyStatsCard(
                icon: "clock.arrow.circlepath",
                title: loc.currentLanguage == .chinese ? "浏览记录" : "Browsing History",
                count: service.totalHistoryCount,
                size: size(for: .history),
                color: .blue
            )
            
            PrivacyStatsCard(
                icon: "magnifyingglass",
                title: loc.currentLanguage == .chinese ? "搜索历史" : "Search History",
                count: service.totalHistoryCount, // Usually same file
                size: size(for: .history) / 2, // Estimate
                color: .purple
            )
            
            PrivacyStatsCard(
                icon: "lock.circle", // Cookie icon replacement
                title: loc.currentLanguage == .chinese ? "Cookie 文件" : "Cookies",
                count: service.totalCookiesCount, 
                size: size(for: .cookies),
                color: .green
            )
        }
    }
    
    private func size(for type: PrivacyType) -> Int64 {
        service.privacyItems.filter { $0.type == type }.reduce(0) { $0 + $1.size }
    }
    
    // MARK: - 隐私列表
    private var privacyListView: some View {
        List {
            ForEach(BrowserType.allCases, id: \.self) { browser in
                let items = service.privacyItems.filter { $0.browser == browser }
                if !items.isEmpty {
                    Section(header: 
                        HStack {
                            Image(systemName: browser.icon)
                            Text(browser.rawValue)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                    ) {
                        ForEach(items) { item in
                            PrivacyRow(item: item, service: service)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar) // Or plain
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - 预览卡片
    private var privacyPreviewCard: some View {
        VStack(spacing: 24) {
            HStack(spacing: 20) {
                // Broken Shield (Before)
                VStack {
                    Image(systemName: "shield.slash.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondaryText)
                    Text(loc.currentLanguage == .chinese ? "隐私数据" : "Privacy Data")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Text(ByteCountFormatter.string(fromByteCount: totalFoundSize, countStyle: .file))
                        .font(.headline)
                        .foregroundColor(.secondaryText)
                }
                
                // Secure Shield (After)
                VStack {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                            .offset(x: 4, y: 4)
                    }
                    Text(loc.currentLanguage == .chinese ? "隐私数据" : "Privacy Data")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Text(ByteCountFormatter.string(fromByteCount: service.selectedSize, countStyle: .file))
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            .padding(.top, 16)
            
            Divider().background(Color.white.opacity(0.1))
            
            Button(action: {
                // View Details
            }) {
                Text(loc.currentLanguage == .chinese ? "查看详情" : "View Details")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .padding(24)
        .background(Color.white) // Use card background but light/dark aware? Assuming dark mode app based on styles
        .colorScheme(.light) // Force light for this card based on screenshot? Screenshot is white.
        .cornerRadius(16)
    }
    
    // MARK: - 底部操作栏
    private var bottomActionBar: some View {
        HStack {
            Button(loc.currentLanguage == .chinese ? "查看详情" : "View Details") {
                showingDetails = true
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
            
            Spacer()
            
            Button(action: {
                handleCleanAction()
            }) {
                Text(loc.currentLanguage == .chinese ? "清理隐私数据" : "Clean Privacy Data")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 44)
                    .background(
                        LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(22)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(loc.currentLanguage == .chinese ? "跳过" : "Skip") {
                skipToNextModule()
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondaryText)
        }
        .padding(24)
        .background(Color.black.opacity(0.2))
        .alert(loc.currentLanguage == .chinese ? "关闭浏览器" : "Close Browsers", isPresented: $showingCloseBrowserAlert) {
            Button(loc.currentLanguage == .chinese ? "关闭并清理" : "Close and Clean", role: .destructive) {
                Task {
                    await performClean(closeBrowsers: true)
                }
            }
            Button(loc.L("cancel"), role: .cancel) { }
        } message: {
            Text(loc.currentLanguage == .chinese ? "检测到浏览器正在运行，清理前需要将其关闭以确保数据被彻底清除。" : "Browsers are running. They need to be closed to ensure data is completely removed.")
        }
    }
    
    private func handleCleanAction() {
        let runningBrowsers = service.checkRunningBrowsers()
        if !runningBrowsers.isEmpty {
            showingCloseBrowserAlert = true
        } else {
            Task {
                await performClean(closeBrowsers: false)
            }
        }
    }
    
    private func performClean(closeBrowsers: Bool) async {
        if closeBrowsers {
            _ = await service.closeBrowsers()
        }
        
        let result = await service.cleanSelected()
        await MainActor.run {
            cleanResult = result
            showingCleanAlert = true
        }
    }
    
    // MARK: - 扫描动画 (复用/简化)
    private var scanningView: some View {
        VStack(spacing: 40) {
            Spacer()
            ZStack {
                Circle().stroke(Color.white.opacity(0.1), lineWidth: 10).frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: service.scanProgress)
                    .stroke(Color.purple, lineWidth: 10)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: service.scanProgress)
                
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
            }
            Text(loc.currentLanguage == .chinese ? "正在扫描隐私风险..." : "Scanning privacy risks...")
                .font(.title2)
                .foregroundColor(.white)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "shield.check.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            Text(loc.currentLanguage == .chinese ? "您的隐私很安全" : "Your privacy is safe")
                .font(.title)
                .foregroundColor(.white)
            Spacer()
        }
    }
    
    // MARK: - 跳过到下一个模块
    private func skipToNextModule() {
        let allModules = AppModule.allCases
        if let currentIndex = allModules.firstIndex(of: selectedModule),
           currentIndex < allModules.count - 1 {
            selectedModule = allModules[currentIndex + 1]
        } else {
            // 如果是最后一个，回到第一个
            selectedModule = allModules.first ?? .monitor
        }
    }
    
    // MARK: - 详情 Sheet
    private var detailSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text(loc.currentLanguage == .chinese ? "扫描详情" : "Scan Details")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: { showingDetails = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            List {
                ForEach(service.privacyItems) { item in
                    HStack {
                        Image(systemName: item.type.icon)
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text(item.displayPath)
                                .font(.system(size: 13, weight: .medium))
                            Text(item.path.path)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Subviews

struct PrivacyStatsCard: View {
    let icon: String
    let title: String
    let count: Int
    let size: Int64
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray) // Fixed: use gray instead of secondaryText
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(count)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.black) // Fixed: use black for white bg
                    Text("项")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.8))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .colorScheme(.light)
    }
}

struct PrivacyRow: View {
    let item: PrivacyItem
    @ObservedObject var service: PrivacyScannerService
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { newValue in
                    if let index = service.privacyItems.firstIndex(where: { $0.id == item.id }) {
                        service.privacyItems[index].isSelected = newValue
                    }
                    service.objectWillChange.send()
                }
            ))
            .toggleStyle(CheckboxStyle())
            .labelsHidden()
            
            Image(systemName: item.type.icon)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading) {
                Text(item.displayPath)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primaryText)
                Text(item.path.lastPathComponent)
                    .font(.system(size: 11))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                .font(.system(size: 13))
                .foregroundColor(.primaryText)
        }
        .padding(.vertical, 4)
    }
}
