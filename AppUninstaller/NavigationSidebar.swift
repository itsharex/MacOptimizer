import SwiftUI

// MARK: - 侧边栏分组定义
enum SidebarSection: String, CaseIterable {
    case main = ""           // 智能扫描（顶部无标题）
    case cleanup = "清理"    // 系统垃圾、邮件附件、废纸篓
    case protection = "保护" // 移除恶意软件、隐私
    case speed = "速度"      // 优化、维护
    case apps = "应用程序"   // 卸载器、更新程序、扩展
    case files = "文件"      // 空间透镜、大型和旧文件、碎纸机
    
    var englishTitle: String {
        switch self {
        case .main: return ""
        case .cleanup: return "Cleanup"
        case .protection: return "Protection"
        case .speed: return "Speed"
        case .apps: return "Applications"
        case .files: return "Files"
        }
    }
    
    var modules: [AppModule] {
        switch self {
        case .main:
            return [.smartClean]
        case .cleanup:
            return [.cleaner, .deepClean, .trash]
        case .protection:
            return [.malware, .privacy]
        case .speed:
            return [.optimizer, .maintenance, .monitor]
        case .apps:
            return [.uninstaller, .updater]
        case .files:
            return [.fileExplorer, .largeFiles, .shredder]
        }
    }
}

struct NavigationSidebar: View {
    @Binding var selectedModule: AppModule
    @ObservedObject var localization = LocalizationManager.shared
    @State private var showSettings = false
    @State private var showUpdatePopup = false
    @StateObject private var updateService = UpdateCheckerService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部 Logo 区域 (可点击检查更新)
            Button(action: {
                if updateService.hasUpdate {
                    showUpdatePopup = true
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.8, green: 0.2, blue: 0.5), Color(red: 0.5, green: 0.1, blue: 0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "sparkles")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(localization.currentLanguage == .chinese ? "Mac优化大师" : "MacOptimizer")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        // 显示版本更新提示
                        if updateService.hasUpdate {
                            Text(localization.currentLanguage == .chinese ? "发现新版本" : "New Version")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(8)
                                .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showUpdatePopup) {
                UpdatePopupView()
            }
            
            // 分组导航菜单
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(SidebarSection.allCases, id: \.self) { section in
                        // 分组标题
                        if !section.rawValue.isEmpty {
                            Text(localization.currentLanguage == .chinese ? section.rawValue : section.englishTitle)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.leading, 16)
                                .padding(.top, section == .cleanup ? 8 : 16)
                                .padding(.bottom, 4)
                        }
                        
                        // 分组项目
                        ForEach(section.modules) { module in
                            SidebarMenuItem(
                                module: module,
                                isSelected: selectedModule == module,
                                action: { selectedModule = module },
                                localization: localization
                            )
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
            }
            
            Spacer()
            
            // 底部版本信息 & 设置
            VStack(spacing: 12) {
                HStack {
                    // 语言切换按钮
                    Button(action: { localization.toggleLanguage() }) {
                        HStack(spacing: 4) {
                            Text(localization.currentLanguage.flag)
                                .font(.system(size: 14))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // 设置按钮
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(6)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(localization.currentLanguage == .chinese ? "设置" : "Settings")
                }
                
                HStack(spacing: 6) {
                    Text("v3.0.3")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Pro Version")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .padding(.bottom, 16)
        }
        .frame(width: 200)
        .background(
            // 毛玻璃效果背景
            ZStack {
                Color.black.opacity(0.3)
                
                // 顶部渐变高光
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.08), location: 0),
                        .init(color: Color.clear, location: 0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
    }
}

// MARK: - 侧边栏菜单项
struct SidebarMenuItem: View {
    let module: AppModule
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject var localization: LocalizationManager
    @State private var isHovering = false
    
    // 获取本地化的模块名称
    private var localizedName: String {
        switch module {
        case .monitor: return localization.currentLanguage == .chinese ? "控制台" : "Monitor"
        case .uninstaller: return localization.currentLanguage == .chinese ? "卸载器" : "Uninstaller"
        case .updater: return localization.currentLanguage == .chinese ? "更新程序" : "Updater"
        case .deepClean: return localization.currentLanguage == .chinese ? "深度清理" : "Deep Clean"
        case .cleaner: return localization.currentLanguage == .chinese ? "系统垃圾" : "System Junk"
        case .maintenance: return localization.currentLanguage == .chinese ? "维护" : "Maintenance"
        case .optimizer: return localization.currentLanguage == .chinese ? "优化" : "Optimization"
        case .shredder: return localization.currentLanguage == .chinese ? "碎纸机" : "Shredder"
        case .largeFiles: return localization.currentLanguage == .chinese ? "大型和旧文件" : "Large & Old Files"
        case .fileExplorer: return localization.currentLanguage == .chinese ? "空间透镜" : "Space Lens"
        case .trash: return localization.currentLanguage == .chinese ? "废纸篓" : "Trash Bins"
        case .privacy: return localization.currentLanguage == .chinese ? "隐私" : "Privacy"
        case .malware: return localization.currentLanguage == .chinese ? "移除恶意软件" : "Malware Removal"
        case .smartClean: return localization.currentLanguage == .chinese ? "智能扫描" : "Smart Scan"
        }
    }
    
    // 获取模块图标
    private var moduleIcon: String {
        module.icon
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // 图标
                Image(systemName: moduleIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .frame(width: 20)
                
                // 名称
                Text(localizedName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        // 选中状态 - 渐变背景 + 左侧高亮边框
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            // 左侧高亮边框
                            HStack {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(module.gradient)
                                    .frame(width: 3)
                                Spacer()
                            }
                        }
                    } else if isHovering {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }
}
