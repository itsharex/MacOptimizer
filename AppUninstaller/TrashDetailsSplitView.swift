import SwiftUI

struct TrashDetailsSplitView: View {
    @ObservedObject var scanner: TrashScanner
    @ObservedObject private var loc = LocalizationManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: String = "trash_on_mac" // Default selection
    @State private var searchText = ""
    @State private var showCleanConfirmation = false
    
    // 模拟的分类数据，根据设计图只有 "mac 上的废纸篓"
    private let categories = ["trash_on_mac"]
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧侧边栏
            VStack(spacing: 0) {
                // 顶部返回按钮 area
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(loc.currentLanguage == .chinese ? "返回" : "Back")
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(16)
                
                // 全选/取消全选 header
                HStack {
                    Button(loc.currentLanguage == .chinese ? "取消全选" : "Deselect All") {
                        // TODO: Implement selection logic
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Text(loc.currentLanguage == .chinese ? "排序方式按 大小" : "Sort by Size")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                // 分类列表
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(categories, id: \.self) { category in
                            categoryRow(title: loc.currentLanguage == .chinese ? "mac 上的废纸篓" : "Trash on mac", size: scanner.formattedTotalSize, isSelected: selectedCategory == category)
                                .onTapGesture {
                                    selectedCategory = category
                                }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .frame(width: 260)
            // .background(Color.black.opacity(0.2)) // Removed to match unified design
            .background(Color.clear)
            
            // 右侧文件列表
            VStack(spacing: 0) {
                // ... (Previous content: Header, Title, Sort, List)
                // 顶部工具栏 (搜索等)
                HStack {
                    Spacer()
                    
                    Text(loc.currentLanguage == .chinese ? "废纸篓" : "Trash")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading, 40) // Balance
                    
                    Spacer()
                    
                    // 搜索框
                    HStack {
                        Image(systemName: "magnifyingglass")
                        // ...
                        .foregroundColor(.white.opacity(0.6))
                        TextField(loc.currentLanguage == .chinese ? "搜索" : "Search", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(6)
                    .frame(width: 200)
                    
                    // 助手按钮
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Circle().fill(Color.white).frame(width: 6, height: 6)
                            Text(loc.currentLanguage == .chinese ? "助手" : "Assistant")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                
                // 列表标题区域
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.currentLanguage == .chinese ? "mac 上的废纸篓" : "mac Trash")
                        .font(.system(size: 28, weight: .bold)) // Large Title
                        .foregroundColor(.white)
                    
                    Text(loc.currentLanguage == .chinese ? "系统废纸篓文件夹存储先前删除的项目，但是它们仍然占用磁盘空间。" : "System Trash folder stores deleted items which still take up space.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 排序栏
                HStack {
                    Spacer()
                    Text(loc.currentLanguage == .chinese ? "排序方式按 大小" : "Sort by Size")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 6))
                        .rotationEffect(.degrees(180))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                
                // 文件列表
                List {
                    ForEach(scanner.items) { item in
                         TrashDetailRow(item: item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                
                Spacer()
                
                // 底部清理按钮 (Button Bottom Left as requested by user's red box)
                HStack(spacing: 24) {
                    ZStack {
                         // Glow
                         Circle()
                            .stroke(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                            .frame(width: 80, height: 80)
                        
                        Button(action: {
                            showCleanConfirmation = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.25)) // Semi-transparent button
                                    .frame(width: 70, height: 70)
                                    .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
                                
                                VStack(spacing: 2) {
                                    Text(loc.currentLanguage == .chinese ? "清倒" : "Clean")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Size next to it
                    Text(scanner.formattedTotalSize)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer() // Push to Left
                }
                .padding(.leading, 40) // Align roughly with content margin
                .padding(.bottom, 30)
            }
        }
        .confirmationDialog(loc.L("empty_trash"), isPresented: $showCleanConfirmation) {
            Button(loc.L("empty_trash"), role: .destructive) {
                Task {
                   _ = await scanner.emptyTrash()
                   // Back to main view handled by state in parent usually, or reset
                   presentationMode.wrappedValue.dismiss()
                }
            }
            Button(loc.L("cancel"), role: .cancel) {}
        } message: {
            Text(loc.currentLanguage == .chinese ? "此操作不可撤销，所有文件将被永久删除。" : "This cannot be undone.")
        }
    }
    
    private func categoryRow(title: String, size: String, isSelected: Bool) -> some View {
        HStack {
            // Custom Checkbox
            ZStack {
                Circle()
                    .fill(Color(hex: "007AFF")) // Blue fill
                    .frame(width: 18, height: 18)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Icon Background
            ZStack {
                // Trash icon looks like a folder with items or just trash can
                if let imagePath = Bundle.main.path(forResource: "feizhilou", ofType: "png"), // Use trash icon for category
                   let nsImage = NSImage(contentsOfFile: imagePath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                     Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                }
            }
            .frame(width: 32, height: 32)
            
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 13, weight: .medium))
            
            Spacer()
            
            Text(size)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.white.opacity(0.15) : Color.clear) // Rounded pill selection
        .cornerRadius(6)
    }
}

struct TrashDetailRow: View {
    let item: TrashItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox (Blue circle with checkmark)
            ZStack {
                Circle()
                    .fill(Color(hex: "007AFF"))
                    .frame(width: 16, height: 16)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Folder Icon (Blue)
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "5AC8FA")) // Light Blue Folder Color
            
            Text(item.name)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            Text(item.formattedSize)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
