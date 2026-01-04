import SwiftUI
import AppKit

// MARK: - Legacy Components Support
// These components are used by MonitorView and potentially other parts of the app, 
// originally defined in SmartCleanerView.swift but moved here during redesign.

struct ResultCategoryCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let value: String
    var valueSecondary: String? = nil
    let hasDetails: Bool
    let onDetailTap: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }
            
            // 中间文本
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // 右侧数值
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                if let secondary = valueSecondary {
                    Text(secondary)
                        .font(.caption2)
                        .foregroundColor(.secondaryText)
                }
            }
            
            // 查看详情按钮
            if hasDetails {
                Button(action: onDetailTap) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isHovering ? .white : .secondaryText)
                        .padding(8)
                        .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .onHover { isHovering = $0 }
            } else {
                // 占位，保持对齐
                Color.clear.frame(width: 30, height: 30)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(isHovering ? 0.2 : 0.05), lineWidth: 1)
        )
        .onHover { isHovering = $0 }
    }
}

struct CleaningTaskRow: View {
    let icon: String
    let color: Color
    let title: String
    enum Status { case waiting, processing, completed }
    let status: Status
    let fileSize: String?
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(color).frame(width: 32, height: 32)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            if let size = fileSize {
                Text(size)
                    .foregroundColor(.secondaryText)
                    .font(.body)
                    .frame(width: 90, alignment: .trailing)
            }
            
            ZStack {
                switch status {
                case .waiting:
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondaryText)
                case .processing:
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 16, height: 16)
                case .completed:
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }
}

// MARK: - All Categories Detail Sheet (Original Three-Column Design)

struct AllCategoriesDetailSheet: View {
    @ObservedObject var service: SmartCleanerService
    @ObservedObject var loc: LocalizationManager
    @Binding var isPresented: Bool
    var initialCategory: CleanerCategory?
    
    @State private var selectedMainCategory: CleanerCategory? = nil
    @State private var selectedSubcategory: CleanerCategory? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部栏
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(loc.currentLanguage == .chinese ? "返回摘要" : "Back")
                    }
                    .foregroundColor(.secondaryText)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(loc.currentLanguage == .chinese ? "清理详情" : "Cleanup Details")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) { Image(systemName: "chevron.left"); Text("Back") }.opacity(0)
            }
            .padding()
            .background(.ultraThinMaterial) // Glassmorphism Header
            
            // 直接使用左右布局
            allCategoriesOverview
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
                if initial == .systemJunk {
                    selectedMainCategory = .systemJunk
                } else if [.userCache, .systemCache, .oldUpdates, .languageFiles, .systemLogs, .userLogs, .brokenLoginItems].contains(initial) {
                    selectedMainCategory = .systemJunk
                    selectedSubcategory = initial
                } else {
                    selectedMainCategory = initial
                }
            }
        }
    }
    
    // 所有主分类概览 - 左右布局
    private var allCategoriesOverview: some View {
        HStack(spacing: 0) {
            // 左侧分类列表
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(loc.currentLanguage == .chinese ? "扫描结果" : "Scan Results")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 8) {
                        // 系统垃圾
                        MainCategoryRow(
                            icon: "trash.fill",
                            title: loc.currentLanguage == .chinese ? "系统垃圾" : "System Junk",
                            size: service.systemJunkTotalSize,
                            count: service.countFor(category: .systemJunk),
                            color: .pink,
                            isSelected: selectedMainCategory == .systemJunk,
                            onTap: { selectedMainCategory = .systemJunk; selectedSubcategory = nil }
                        )
                        
                        // 重复文件
                        MainCategoryRow(
                            icon: "doc.on.doc",
                            title: loc.currentLanguage == .chinese ? "重复文件" : "Duplicates",
                            size: service.sizeFor(category: .duplicates),
                            count: service.duplicateGroups.flatMap { $0.files }.count,
                            color: .blue,
                            isSelected: selectedMainCategory == .duplicates,
                            onTap: { selectedMainCategory = .duplicates; selectedSubcategory = nil }
                        )
                        
                        // 相似照片
                        MainCategoryRow(
                            icon: "photo.on.rectangle",
                            title: loc.currentLanguage == .chinese ? "相似照片" : "Similar Photos",
                            size: service.sizeFor(category: .similarPhotos),
                            count: service.similarPhotoGroups.flatMap { $0.files }.count,
                            color: .purple,
                            isSelected: selectedMainCategory == .similarPhotos,
                            onTap: { selectedMainCategory = .similarPhotos; selectedSubcategory = nil }
                        )
                        
                        // 大文件
                        MainCategoryRow(
                            icon: "externaldrive.fill",
                            title: loc.currentLanguage == .chinese ? "大文件" : "Large Files",
                            size: service.sizeFor(category: .largeFiles),
                            count: service.largeFiles.count,
                            color: .orange,
                            isSelected: selectedMainCategory == .largeFiles,
                            onTap: { selectedMainCategory = .largeFiles; selectedSubcategory = nil }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.vertical, 8)
                        
                        // 病毒威胁
                        MainCategoryRow(
                            icon: "ant.fill",
                            title: loc.currentLanguage == .chinese ? "病毒威胁" : "Virus Threats",
                            size: 0,
                            count: service.virusThreats.count,
                            color: .red,
                            isSelected: selectedMainCategory == .virus,
                            onTap: { selectedMainCategory = .virus; selectedSubcategory = nil }
                        )
                        
                        // 启动项
                        MainCategoryRow(
                            icon: "power",
                            title: loc.currentLanguage == .chinese ? "启动项" : "Startup Items",
                            size: 0,
                            count: service.startupItems.count,
                            color: .orange,
                            isSelected: selectedMainCategory == .startupItems,
                            onTap: { selectedMainCategory = .startupItems; selectedSubcategory = nil }
                        )
                        
                        // 性能优化
                        MainCategoryRow(
                            icon: "gauge",
                            title: loc.currentLanguage == .chinese ? "性能优化" : "Performance",
                            size: 0,
                            count: service.performanceApps.count,
                            color: .green,
                            isSelected: selectedMainCategory == .performanceApps,
                            onTap: { selectedMainCategory = .performanceApps; selectedSubcategory = nil }
                        )
                        
                        // 应用更新
                        MainCategoryRow(
                            icon: "arrow.triangle.2.circlepath.circle.fill",
                            title: loc.currentLanguage == .chinese ? "应用更新" : "App Updates",
                            size: 0,
                            count: service.hasAppUpdates ? 1 : 0,
                            color: .blue,
                            isSelected: selectedMainCategory == .appUpdates,
                            onTap: { selectedMainCategory = .appUpdates; selectedSubcategory = nil }
                        )
                    }
                    .padding()
                }
                

                
                Spacer()
            }
            .frame(width: 280)
            .background(.thinMaterial) // Glassy Sidebar
            
            // 右侧详情区域 - 根据选择的分类显示内容
            if let mainCategory = selectedMainCategory {
                switch mainCategory {
                case .systemJunk:
                    systemJunkRightPane
                case .virus:
                    virusRightPane
                case .startupItems:
                    startupItemsRightPane
                case .performanceApps:
                    performanceAppsRightPane
                case .appUpdates:
                    appUpdatesRightPane
                default:
                    // 其他分类 - 直接显示文件列表
                    rightPaneFileList(for: mainCategory)
                }
            } else {
                // 未选择时显示提示
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
    }
    
    // 系统垃圾右侧面板 - 显示子分类或具体文件
    private var systemJunkRightPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.currentLanguage == .chinese ? "系统垃圾" : "System Junk")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                Text(loc.currentLanguage == .chinese ? "清理您的系统来获得最大的性能和释放自由空间。" : "Clean your system for best performance and free space.")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            .padding()
            
            if let subcategory = selectedSubcategory {
                // 显示该子分类的文件列表
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { selectedSubcategory = nil }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(loc.currentLanguage == .chinese ? "返回子分类" : "Back")
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    Text(loc.currentLanguage == .chinese ? subcategory.rawValue : subcategory.englishName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                }
                
                // 文件列表
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if subcategory == .userCache {
                            // 特殊处理：按应用分组展示系统缓存
                            ForEach(service.appCacheGroups) { group in
                                AppCacheGroupRow(group: group, service: service, onToggleFile: { file in
                                    service.toggleFileSelection(file: file, in: .userCache)
                                })
                            }
                            
                            // 同时也显示那些没有对应应用的散项
                            let orphanFiles = filesFor(category: .userCache).filter { file in
                                !service.appCacheGroups.flatMap { $0.files }.contains { $0.url == file.url }
                            }
                            
                            if !orphanFiles.isEmpty {
                                Text(loc.currentLanguage == .chinese ? "其他文件夹" : "Other Folders")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                    .padding(.top)
                                
                                ForEach(orphanFiles.sorted { $0.size > $1.size }, id: \.url) { file in
                                    FileItemRow(file: file, showPath: true, service: service, onToggle: {
                                        service.toggleFileSelection(file: file, in: .userCache)
                                    })
                                }
                            }
                        } else {
                            // 常规列表展示
                            ForEach(filesFor(category: subcategory).sorted { $0.size > $1.size }, id: \.url) { file in
                                FileItemRow(file: file, showPath: true, service: service, onToggle: {
                                    service.toggleFileSelection(file: file, in: subcategory)
                                })
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                // 显示子分类列表
                ScrollView {
                    VStack(spacing: 12) {
                        DrillDownCategoryRow(icon: "person.crop.circle.fill", title: loc.currentLanguage == .chinese ? "用户缓存文件" : "User Cache", size: service.sizeFor(category: .userCache), count: service.countFor(category: .userCache), color: .cyan, onTap: { selectedSubcategory = .userCache })
                        DrillDownCategoryRow(icon: "internaldrive.fill", title: loc.currentLanguage == .chinese ? "系统缓存文件" : "System Cache", size: service.sizeFor(category: .systemCache), count: service.countFor(category: .systemCache), color: .blue, onTap: { selectedSubcategory = .systemCache })
                        DrillDownCategoryRow(icon: "arrow.down.circle.fill", title: loc.currentLanguage == .chinese ? "旧更新" : "Old Updates", size: service.sizeFor(category: .oldUpdates), count: service.countFor(category: .oldUpdates), color: .orange, onTap: { selectedSubcategory = .oldUpdates })
                        DrillDownCategoryRow(icon: "textformat.abc", title: loc.currentLanguage == .chinese ? "语言文件" : "Language Files", size: service.sizeFor(category: .languageFiles), count: service.countFor(category: .languageFiles), color: .purple, onTap: { selectedSubcategory = .languageFiles })
                        DrillDownCategoryRow(icon: "doc.text.fill", title: loc.currentLanguage == .chinese ? "系统日志文件" : "System Logs", size: service.sizeFor(category: .systemLogs), count: service.countFor(category: .systemLogs), color: .green, onTap: { selectedSubcategory = .systemLogs })
                        DrillDownCategoryRow(icon: "person.text.rectangle.fill", title: loc.currentLanguage == .chinese ? "用户日志文件" : "User Logs", size: service.sizeFor(category: .userLogs), count: service.countFor(category: .userLogs), color: .teal, onTap: { selectedSubcategory = .userLogs })
                        DrillDownCategoryRow(icon: "exclamationmark.triangle.fill", title: loc.currentLanguage == .chinese ? "损坏的登录项" : "Broken Login Items", size: service.sizeFor(category: .brokenLoginItems), count: service.countFor(category: .brokenLoginItems), color: .red, onTap: { selectedSubcategory = .brokenLoginItems })
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // 右侧文件列表面板
    private func rightPaneFileList(for category: CleanerCategory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.currentLanguage == .chinese ? category.rawValue : category.englishName)
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                let files = filesFor(category: category)
                Text("\(files.count) " + (loc.currentLanguage == .chinese ? "个项目，共 " : "items, ") + ByteCountFormatter.string(fromByteCount: files.reduce(0) { $0 + $1.size }, countStyle: .file))
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            .padding()
            
            // 文件列表
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filesFor(category: category).sorted { $0.size > $1.size }, id: \.url) { file in
                        FileItemRow(file: file, showPath: true, service: service, onToggle: {
                            service.toggleFileSelection(file: file, in: category)
                        })
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // 获取分类对应的文件列表
    private func filesFor(category: CleanerCategory) -> [CleanerFileItem] {
        switch category {
        case .userCache: return service.userCacheFiles
        case .systemCache: return service.systemCacheFiles
        case .oldUpdates: return service.oldUpdateFiles
        case .languageFiles: return service.languageFiles
        case .systemLogs: return service.systemLogFiles
        case .userLogs: return service.userLogFiles
        case .brokenLoginItems: return service.brokenLoginItems
        case .duplicates: return service.duplicateGroups.flatMap { $0.files }
        case .similarPhotos: return service.similarPhotoGroups.flatMap { $0.files }
        case .largeFiles: return service.largeFiles
        case .localizations: return service.localizationFiles
        default: return []
        }
    }
    
    // MARK: - 病毒威胁右侧面板
    private var virusRightPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.currentLanguage == .chinese ? "病毒威胁" : "Virus Threats")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                Text(service.virusThreats.isEmpty ? 
                     (loc.currentLanguage == .chinese ? "未检测到威胁" : "No threats detected") :
                     "\(service.virusThreats.count) " + (loc.currentLanguage == .chinese ? "个威胁" : "threats found"))
                    .font(.subheadline)
                    .foregroundColor(service.virusThreats.isEmpty ? .green : .red)
            }
            .padding()
            
            if service.virusThreats.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    Text(loc.currentLanguage == .chinese ? "您的系统是安全的" : "Your system is safe")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(.top)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(service.virusThreats, id: \.id) { threat in
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(threat.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(threat.path.path)
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Text(threat.type.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(4)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 启动项右侧面板
    private var startupItemsRightPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.currentLanguage == .chinese ? "启动项" : "Startup Items")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                Text("\(service.startupItems.count) " + (loc.currentLanguage == .chinese ? "个项目会在开机时自动启动" : "items start automatically"))
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            .padding()
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(service.startupItems, id: \.id) { item in
                        HStack(spacing: 12) {
                            // 勾选框
                            Button(action: {
                                item.isSelected.toggle()
                                service.objectWillChange.send()
                            }) {
                                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isSelected ? .blue : .gray)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.plain)
                            
                            Image(systemName: "power")
                                .foregroundColor(.orange)
                                .font(.title2)
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.body)
                                    .foregroundColor(.white)
                                Text(item.url.path)
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text(item.isEnabled ? (loc.currentLanguage == .chinese ? "已启用" : "Enabled") : (loc.currentLanguage == .chinese ? "已禁用" : "Disabled"))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(item.isEnabled ? Color.orange.opacity(0.2) : Color.gray.opacity(0.2))
                                .foregroundColor(item.isEnabled ? .orange : .gray)
                                .cornerRadius(4)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 性能优化右侧面板
    private var performanceAppsRightPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.currentLanguage == .chinese ? "性能优化" : "Performance")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                Text("\(service.performanceApps.count) " + (loc.currentLanguage == .chinese ? "个应用正在消耗资源" : "apps consuming resources"))
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            .padding()
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(service.performanceApps) { app in
                        HStack(spacing: 12) {
                            // 勾选框
                            Button(action: {
                                app.isSelected.toggle()
                                service.objectWillChange.send()
                            }) {
                                Image(systemName: app.isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(app.isSelected ? .blue : .gray)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.plain)
                            
                            Image(nsImage: app.icon)
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading) {
                                Text(app.name)
                                    .font(.body)
                                    .foregroundColor(.white)
                                Text(app.app.bundleIdentifier ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "cpu")
                                    .foregroundColor(.green)
                                Text(loc.currentLanguage == .chinese ? "运行中" : "Running")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                        }
                        .padding()
                        .background(Color.white.opacity(app.isSelected ? 0.1 : 0.05))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 应用更新右侧面板
    private var appUpdatesRightPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.currentLanguage == .chinese ? "应用更新" : "App Updates")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                Text(service.hasAppUpdates ? 
                     (loc.currentLanguage == .chinese ? "有可用更新" : "Updates available") :
                     (loc.currentLanguage == .chinese ? "所有应用已是最新" : "All apps up to date"))
                    .font(.subheadline)
                    .foregroundColor(service.hasAppUpdates ? .blue : .green)
            }
            .padding()
            
            VStack {
                Spacer()
                Image(systemName: service.hasAppUpdates ? "arrow.down.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(service.hasAppUpdates ? .blue : .green)
                Text(service.hasAppUpdates ? 
                     (loc.currentLanguage == .chinese ? "点击更新按钮检查更新" : "Click update button to check") :
                     (loc.currentLanguage == .chinese ? "无需更新" : "No updates needed"))
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(.top)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 主分类行
struct MainCategoryRow: View {
    let icon: String
    let title: String
    let size: Int64
    let count: Int
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white : .primary.opacity(0.9))
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                            .foregroundColor(.secondaryText)
                    }
                }
                
                Spacer()
                
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondaryText)
                    .font(.system(size: 12))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .contentShape(Rectangle()) // Ensure full area is clickable
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 文件项行（支持文件夹钻取）
struct FileItemRow: View {
    let file: CleanerFileItem
    let showPath: Bool
    @ObservedObject var service: SmartCleanerService
    var onToggle: (() -> Void)? = nil
    
    @State private var isExpanded: Bool = false
    @State private var subItems: [CleanerFileItem] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 可点击的复选框
                Button(action: {
                    onToggle?()
                }) {
                    Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(file.isSelected ? .blue : .gray)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                
                Image(nsImage: file.icon)
                    .resizable()
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(file.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if file.isDirectory {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondaryText)
                        }
                    }
                    
                    if showPath {
                        Text(file.url.deletingLastPathComponent().path)
                            .font(.system(size: 11))
                            .foregroundColor(.tertiaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Text(file.formattedSize)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                if file.isDirectory {
                    Button(action: {
                        toggleExpand()
                    }) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color.white.opacity(file.isSelected ? 0.1 : 0.05))
            .cornerRadius(10)
            .onTapGesture {
                if file.isDirectory {
                    toggleExpand()
                }
            }
            
            // 展开子项
            if isExpanded && !subItems.isEmpty {
                VStack(spacing: 2) {
                    ForEach(subItems, id: \.url) { subFile in
                        FileItemRow(file: subFile, showPath: false, service: service, onToggle: {
                            // 子文件勾选：这里需要一个递归勾选逻辑，或者简单点只支持单选
                            // 为了简化，我们只通过 service 切换该 URL 的状态
                            service.toggleFileSelection(file: subFile, in: .userCache)
                        })
                        .padding(.leading, 20)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func toggleExpand() {
        if isExpanded {
            isExpanded = false
        } else {
            if subItems.isEmpty {
                isLoading = true
                Task {
                    let items = await service.loadSubItems(for: file)
                    await MainActor.run {
                        subItems = items
                        isLoading = false
                        withAnimation { isExpanded = true }
                    }
                }
            } else {
                withAnimation { isExpanded = true }
            }
        }
    }
}

// MARK: - 应用缓存分组行
struct AppCacheGroupRow: View {
    let group: AppCacheGroup
    @ObservedObject var service: SmartCleanerService
    let onToggleFile: (CleanerFileItem) -> Void
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 主行：应用信息
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    Image(nsImage: group.icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.appName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(group.files.count) " + (group.files.count == 1 ? "location" : "locations"))
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text(ByteCountFormatter.string(fromByteCount: group.totalSize, countStyle: .file))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            
            // 展开内容：具体子文件夹
            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(group.files.sorted { $0.size > $1.size }, id: \.url) { file in
                        FileItemRow(file: file, showPath: false, service: service, onToggle: {
                            onToggleFile(file)
                        })
                        .padding(.leading, 16)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - 可点击的分类行（带钻取）
struct DrillDownCategoryRow: View {
    let icon: String
    let title: String
    let size: Int64
    let count: Int
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 22))
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    if count > 0 {
                        Text("\(count) " + (count == 1 ? "file" : "files"))
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondaryText)
                    .font(.system(size: 14))
                
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 90, alignment: .trailing)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helper Views

struct DetailSidebarRow: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 20)
                Text(title)
                    .foregroundColor(isSelected ? .white : .secondaryText)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? color.opacity(0.8) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
