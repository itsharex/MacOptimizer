import Foundation
import AppKit

struct PortItem: Identifiable {
    let id = UUID()
    let command: String      // 进程名
    let pid: Int             // 进程ID
    let user: String         // 用户
    let port: Int?           // 端口号
    let `protocol`: String   // TCP/UDP
    let state: String        // LISTEN, ESTABLISHED, etc.
    let address: String      // 监听地址
    
    var displayName: String {
        // 美化进程名
        command.replacingOccurrences(of: "\\x", with: "")
    }
    
    var portString: String {
        if let p = port {
            return String(p)
        }
        return "-"
    }
    
    var icon: NSImage? {
        // 尝试获取应用图标
        let runningApps = NSWorkspace.shared.runningApplications
        if let app = runningApps.first(where: { $0.processIdentifier == Int32(pid) }) {
            return app.icon
        }
        return nil
    }
}

class PortScannerService: ObservableObject {
    @Published var ports: [PortItem] = []
    @Published var isScanning = false
    @Published var filterListeningOnly = true
    
    func scanPorts() async {
        await MainActor.run { isScanning = true }
        
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-i", "-P", "-n"] // Internet files, No port names, No host names
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: "\n")
                var items: [PortItem] = []
                var seenPorts: Set<String> = [] // 去重
                
                for (index, line) in lines.enumerated() {
                    if index == 0 || line.isEmpty { continue }
                    
                    // lsof output: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
                    let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                    guard parts.count >= 9 else { continue }
                    
                    let command = String(parts[0])
                    let pidStr = String(parts[1])
                    let user = String(parts[2])
                    let name = parts[8...].joined(separator: " ")
                    
                    guard let pid = Int(pidStr) else { continue }
                    
                    // 解析 NAME 字段: *:8080 或 127.0.0.1:3306 或 *:3306 (LISTEN)
                    var port: Int? = nil
                    var proto = "TCP"
                    var state = ""
                    var address = "*"
                    
                    // 检查协议类型
                    if name.contains("UDP") {
                        proto = "UDP"
                    }
                    
                    // 解析状态
                    if name.contains("(LISTEN)") {
                        state = "LISTEN"
                    } else if name.contains("(ESTABLISHED)") {
                        state = "ESTABLISHED"
                    } else if name.contains("(CLOSE_WAIT)") {
                        state = "CLOSE_WAIT"
                    } else if name.contains("(TIME_WAIT)") {
                        state = "TIME_WAIT"
                    }
                    
                    // 过滤：只显示 LISTEN 状态
                    if filterListeningOnly && state != "LISTEN" {
                        continue
                    }
                    
                    // 解析端口号 - 格式: address:port 或 *:port
                    let cleanName = name.replacingOccurrences(of: "(LISTEN)", with: "")
                        .replacingOccurrences(of: "(ESTABLISHED)", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    
                    if let colonIndex = cleanName.lastIndex(of: ":") {
                        let portPart = String(cleanName[cleanName.index(after: colonIndex)...])
                            .trimmingCharacters(in: .whitespaces)
                            .components(separatedBy: "->").first ?? ""
                        port = Int(portPart.trimmingCharacters(in: .whitespaces))
                        
                        let addrPart = String(cleanName[..<colonIndex])
                        address = addrPart.isEmpty ? "*" : addrPart
                    }
                    
                    // 去重：同一进程同一端口只显示一次
                    let uniqueKey = "\(pid)-\(port ?? 0)"
                    if seenPorts.contains(uniqueKey) { continue }
                    seenPorts.insert(uniqueKey)
                    
                    let item = PortItem(
                        command: command,
                        pid: pid,
                        user: user,
                        port: port,
                        protocol: proto,
                        state: state,
                        address: address
                    )
                    items.append(item)
                }
                
                // 按端口号排序
                items.sort { ($0.port ?? 0) < ($1.port ?? 0) }
                
                await MainActor.run {
                    self.ports = items
                    self.isScanning = false
                }
            }
        } catch {
            print("Port Scan Error: \(error)")
            await MainActor.run { isScanning = false }
        }
    }
    
    /// 终止进程释放端口
    func terminateProcess(_ item: PortItem) {
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-9", String(item.pid)]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            // 刷新列表
            Task { await scanPorts() }
        } catch {
            print("Failed to terminate process: \(error)")
        }
    }
}
