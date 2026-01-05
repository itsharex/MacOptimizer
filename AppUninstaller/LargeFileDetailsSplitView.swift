import SwiftUI

struct LargeFileDetailsSplitView: View {
    @ObservedObject var scanner: LargeFileScanner
    @ObservedObject private var loc = LocalizationManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: String = "All"
    @State private var searchText = ""
    @State private var sortOption: SortOption = .size
    
    enum SortOption {
        case size, name, date
    }
    
    // Categories matching the design
    private let categories = [
        "All", 
        "Archives", "Documents", "Movies", "Music", "Pictures", "Others", // Type based
        "Huge", "Medium", "Small", // Size based
        "One Month Ago", "One Week Ago", "One Year Ago" // Date based
    ]
    
    // Filter logic helper
    private func filterFiles(for category: String) -> [FileItem] {
        let files = scanner.foundFiles
        switch category {
        case "All": return files
        case "Movies": return files.filter { ["mp4", "mov", "avi", "mkv", "m4v"].contains($0.type.lowercased()) }
        case "Archives": return files.filter { ["zip", "rar", "7z", "tar", "gz", "dmg", "iso", "pkg"].contains($0.type.lowercased()) }
        case "Music": return files.filter { ["mp3", "wav", "aac", "flac", "m4a"].contains($0.type.lowercased()) }
        case "Pictures": return files.filter { ["jpg", "jpeg", "png", "gif", "heic", "tiff", "bmp", "svg"].contains($0.type.lowercased()) }
        case "Documents": return files.filter { ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "md"].contains($0.type.lowercased()) }
        case "Others":
            let knownTypes = ["mp4", "mov", "avi", "mkv", "m4v", "zip", "rar", "7z", "tar", "gz", "dmg", "iso", "pkg", "mp3", "wav", "aac", "flac", "m4a", "jpg", "jpeg", "png", "gif", "heic", "tiff", "bmp", "svg", "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "md"]
            return files.filter { !knownTypes.contains($0.type.lowercased()) }
            
        case "Huge": return files.filter { $0.size > 1024 * 1024 * 1024 } // > 1GB
        case "Medium": return files.filter { $0.size >= 500 * 1024 * 1024 && $0.size <= 1024 * 1024 * 1024 } // 500MB - 1GB
        case "Small": return files.filter { $0.size >= 50 * 1024 * 1024 && $0.size < 500 * 1024 * 1024 } // 50MB - 500MB
            
        case "One Month Ago":
            let date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return files.filter { $0.accessDate < date }
        case "One Week Ago":
            let date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return files.filter { $0.accessDate < date }
        case "One Year Ago":
            let date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            return files.filter { $0.accessDate < date }
            
        default: return files
        }
    }

    var filteredFiles: [FileItem] {
        let baseFiles = filterFiles(for: selectedCategory)
        
        let files = baseFiles.filter { file in
            if searchText.isEmpty { return true }
            return file.name.localizedCaseInsensitiveContains(searchText)
        }
        
        // Sorting
        return files.sorted {
            switch sortOption {
            case .size: return $0.size > $1.size
            case .name: return $0.name < $1.name
            case .date: return $0.accessDate > $1.accessDate
            }
        }
    }
    
    // Calculate total size for a category
    private func sizeForCategory(_ category: String) -> String {
        let files = filterFiles(for: category)
        let total = files.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
    
    var totalSelectedSize: Int64 {
        scanner.foundFiles.filter { scanner.selectedFiles.contains($0.id) }.reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 0) {
                // Return button area
                HStack {
                    Button(action: {
                        withAnimation {
                            scanner.reset()
                        }
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
                
                // Sidebar List
                ScrollView {
                    VStack(spacing: 2) {
                        groupHeader("All Files")
                        categoryRow(title: "All", isSelected: selectedCategory == "All")
                            .onTapGesture { selectedCategory = "All" }
                        
                        groupHeader("Type")
                        ForEach(["Archives", "Others"], id: \.self) { cat in
                            categoryRow(title: cat, isSelected: selectedCategory == cat)
                                .onTapGesture { selectedCategory = cat }
                        }
                        // Only show non-empty categories or main ones? User screenshot has limited list.
                        // I will add the others but maybe conditionally hide empty ones later if requested.
                        // For now showing specific requested ones + standard ones ensuring coverage.
                        ForEach(["Documents", "Movies", "Music", "Pictures"], id: \.self) { cat in
                            categoryRow(title: cat, isSelected: selectedCategory == cat)
                                .onTapGesture { selectedCategory = cat }
                        }
                        
                        groupHeader("Size")
                        ForEach(["Huge", "Medium", "Small"], id: \.self) { cat in
                            categoryRow(title: cat, isSelected: selectedCategory == cat)
                                .onTapGesture { selectedCategory = cat }
                        }
                        
                        groupHeader("Date")
                        ForEach(["One Week Ago", "One Month Ago", "One Year Ago"], id: \.self) { cat in
                            categoryRow(title: cat, isSelected: selectedCategory == cat)
                                .onTapGesture { selectedCategory = cat }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .frame(width: 200)
            .background(Color.white.opacity(0.05))
            
            // Content
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Text(categoryTitle(selectedCategory))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Sort Menu
                    Menu {
                        Button("Size") { sortOption = .size }
                        Button("Name") { sortOption = .name }
                        Button("Date") { sortOption = .date }
                    } label: {
                        HStack(spacing: 4) {
                            Text(loc.currentLanguage == .chinese ? "排序方式按" : "Sort by")
                            Text(sortOptionString)
                            Image(systemName: "chevron.down")
                        }
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    }
                    .menuStyle(.borderlessButton)
                    
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondaryText)
                        TextField(loc.currentLanguage == .chinese ? "搜索" : "Search", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                    }
                    .padding(6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
                    .frame(width: 200)
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                
                // File List
                List {
                    ForEach(filteredFiles) { file in
                        LargeFileItemRow(file: file, isSelected: scanner.selectedFiles.contains(file.id)) {
                            if scanner.selectedFiles.contains(file.id) {
                                scanner.selectedFiles.remove(file.id)
                            } else {
                                scanner.selectedFiles.insert(file.id)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                
                // Bottom Bar
                HStack(spacing: 20) {
                    Spacer()
                    
                    // Left side: Immediate Remove options
                    Menu {
                        Button(loc.L("selectAll")) {
                            scanner.selectedFiles = Set(filteredFiles.map { $0.id })
                        }
                        Button(loc.currentLanguage == .chinese ? "取消选择" : "Deselect All") {
                            scanner.selectedFiles.removeAll()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(loc.currentLanguage == .chinese ? "立即移除" : "Remove Immediately")
                            Image(systemName: "chevron.up")
                        }
                        .foregroundColor(.secondaryText)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    
                    // Center: Circular Action Button
                    Button(action: {
                        Task {
                            await scanner.deleteItems(scanner.selectedFiles)
                            scanner.selectedFiles.removeAll()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(scanner.selectedFiles.isEmpty ? Color.gray.opacity(0.3) : Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            
                            VStack(spacing: 4) {
                                Text(loc.currentLanguage == .chinese ? "移除" : "Remove")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Text(ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(scanner.selectedFiles.isEmpty)
                    
                    // Right Side: Hidden balancer
                    Menu { } label: {
                        HStack(spacing: 4) {
                            Text(loc.currentLanguage == .chinese ? "立即移除" : "Remove Immediately")
                            Image(systemName: "chevron.up") 
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .opacity(0)
                    .disabled(true)
                    
                    Spacer()
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
    }
    
    private var sortOptionString: String {
        switch sortOption {
        case .size: return loc.currentLanguage == .chinese ? "大小" : "Size"
        case .name: return loc.currentLanguage == .chinese ? "名称" : "Name"
        case .date: return loc.currentLanguage == .chinese ? "日期" : "Date"
        }
    }
    
    private func groupHeader(_ title: String) -> some View {
        HStack {
            Text(categoryLocalized(title))
                .font(.caption)
                .foregroundColor(.tertiaryText)
                .padding(.top, 8)
                .padding(.bottom, 4)
            Spacer()
        }
        .padding(.horizontal, 12)
    }
    
    private func categoryRow(title: String, isSelected: Bool) -> some View {
        HStack {
            // Circle Checkbox style indicator
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.blue : Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: 14, height: 14)
                if isSelected {
                    Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                }
            }
            
            Text(categoryLocalized(title))
                .foregroundColor(.white)
                .font(.system(size: 13))
            
            Spacer()
            
            // Show Size
            Text(sizeForCategory(title))
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
    
    private func categoryLocalized(_ title: String) -> String {
        guard loc.currentLanguage == .chinese else { return title }
        switch title {
        case "All Files": return "所有文件"
        case "Type": return "按类型"
        case "Size": return "按大小"
        case "Date": return "按访问日期"
            
        case "All": return "所有文件"
        case "Movies": return "视频"
        case "Archives": return "存档"
        case "Music": return "音乐"
        case "Pictures": return "图片"
        case "Documents": return "文档"
        case "Others": return "其他"
        case "Huge": return "巨大"
        case "Small": return "较小"
        case "Medium": return "中等"
        case "One Year Ago": return "一年前"
        case "One Month Ago": return "一个月前"
        case "One Week Ago": return "一周前"
        default: return title
        }
    }
    
    private func categoryTitle(_ title: String) -> String {
        return categoryLocalized(title)
    }
}

struct LargeFileItemRow: View {
    let file: FileItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .onTapGesture {
                    onToggle()
                }
            
            Image(nsImage: NSWorkspace.shared.icon(forFile: file.url.path))
                .resizable()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading) {
                Text(file.name)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(file.url.path)
                    .font(.system(size: 11))
                    .foregroundColor(.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(file.formattedSize)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                
                // Show date if available/relevant or just size
                // Text(file.accessDate.formatted()) ...
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}
