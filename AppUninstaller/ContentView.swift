import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedModule: AppModule = .smartClean
    
    var body: some View {
        ZStack {
            // 全屏背景 (沉浸式)
            selectedModule.backgroundGradient
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // 左侧导航
                NavigationSidebar(selectedModule: $selectedModule)
                    .zIndex(1)
                
                // 右侧内容
                ZStack {
                    // Color.clear // 内容区域背景透明
                    
                    Group {
                        switch selectedModule {
                        case .uninstaller:
                            UninstallerMainView()
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        case .deepClean:
                            DeepCleanView(selectedModule: $selectedModule)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        case .cleaner:
                            JunkCleanerView()
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        case .optimizer:
                            MaintenanceView()
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        case .largeFiles:
                            LargeFileView(selectedModule: $selectedModule)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        case .fileExplorer:
                            FileExplorerView()
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        case .trash:
                            TrashView()
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        case .monitor:
                            MonitorView()
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        case .privacy:
                            PrivacyView(selectedModule: $selectedModule)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        case .smartClean:
                            SmartCleanerView(selectedModule: $selectedModule)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedModule)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
    }
}

// 包装现有的 Uninstaller 视图
struct UninstallerMainView: View {
    @StateObject private var appScanner = AppScanner()
    
    var body: some View {
        AppUninstallerView(appScanner: appScanner)
    }
}

// 拆分出来的应用列表视图
struct AppListView: View {
    let apps: [InstalledApp]
    let selectedApp: InstalledApp?
    let isScanning: Bool
    @Binding var searchText: String
    let onSelect: (InstalledApp) -> Void
    let onRefresh: () -> Void
    @ObservedObject var loc: LocalizationManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部工具栏
            HStack {
                Text(loc.currentLanguage == .chinese ? "应用列表" : "App List")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.3))
                TextField(loc.L("search_apps"), text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            
            if isScanning {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Text(loc.currentLanguage == .chinese ? "扫描应用中..." : "Scanning apps...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                Spacer()
            } else {
                List(apps) { app in
                    AppListRow(app: app, isSelected: selectedApp?.id == app.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(app)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            
            // 底部统计
            HStack {
                Text(loc.currentLanguage == .chinese ? "\(apps.count) 个应用" : "\(apps.count) apps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(12)
            .background(Color.black.opacity(0.2))
        }
        .background(Color.black.opacity(0.2))
    }
}

// 拆分出来的空状态视图
struct EmptySelectionView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.square")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.1))
            Text(loc.currentLanguage == .chinese ? "选择一个应用以查看详情" : "Select an app to view details")
                .font(.title3)
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

// 列表行组件 (适配新风格)
struct AppListRow: View {
    @ObservedObject var app: InstalledApp
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primaryText)
                
                Text(app.formattedSize)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondaryText)
            }
            
            Spacer()
            
            if !app.residualFiles.isEmpty {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : Color.clear)
        )
    }
}
