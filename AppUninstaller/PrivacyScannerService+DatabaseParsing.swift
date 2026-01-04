import Foundation
import AppKit
import SQLite3

// MARK: - 浏览器数据库解析扩展

extension PrivacyScannerService {
    
    // MARK: - 数据库操作辅助方法
    
    /// 统计数据库表的行数
    func countRows(db: OpaquePointer?, table: String) -> Int {
        let query = "SELECT COUNT(*) FROM \(table)"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return 0
        }
        
        return Int(sqlite3_column_int(statement, 0))
    }
    
    /// 执行查询并将结果映射为字典数组 (for debugging/details)
    func executeQuery(db: OpaquePointer?, query: String) -> [[String: Any]] {
        var statement: OpaquePointer?
        var results: [[String: Any]] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columns = sqlite3_column_count(statement)
            
            for i in 0..<columns {
                let name = String(cString: sqlite3_column_name(statement, i))
                let type = sqlite3_column_type(statement, i)
                
                switch type {
                case SQLITE_INTEGER:
                    row[name] = Int(sqlite3_column_int(statement, i))
                case SQLITE_FLOAT:
                    row[name] = Double(sqlite3_column_double(statement, i))
                case SQLITE_TEXT:
                    if let cString = sqlite3_column_text(statement, i) {
                        row[name] = String(cString: cString)
                    }
                default:
                    break
                }
            }
            results.append(row)
        }
        return results
    }
    
    // MARK: - 应用图标获取
    
    /// 获取应用真实图标
    func getAppIcon(for browser: BrowserType) -> NSImage? {
        let bundleIds: [BrowserType: String] = [
            .chrome: "com.google.Chrome",
            .safari: "com.apple.Safari",
            .firefox: "org.mozilla.firefox"
        ]
        
        guard let bundleId = bundleIds[browser],
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
    
    // MARK: - Chrome 数据库解析
    
    /// 解析 Chrome History 数据库 (复制到临时位置避免锁定问题)
    func parseChromeHistory(at url: URL) -> (visits: Int, downloads: Int, searches: Int) {
        // Chrome 运行时数据库会被锁定，需要复制到临时位置再读取
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("chrome_history_\(UUID().uuidString).db")
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        do {
            try FileManager.default.copyItem(at: url, to: tempURL)
        } catch {
            print("❌ Failed to copy Chrome History for reading: \(error.localizedDescription)")
            return (0, 0, 0)
        }
        
        var db: OpaquePointer?
        guard sqlite3_open(tempURL.path, &db) == SQLITE_OK else {
            print("❌ Failed to open Chrome History copy: \(tempURL.path)")
            return (0, 0, 0)
        }
        defer { sqlite3_close(db) }
        
        let visits = countRows(db: db, table: "visits")
        let downloads = countRows(db: db, table: "downloads")
        let searches = countRows(db: db, table: "keyword_search_terms")
        
        return (visits, downloads, searches)
    }
    
    /// 复制数据库到临时位置并打开 (避免浏览器运行时锁定问题)
    private func openDatabaseCopy(at url: URL) -> (db: OpaquePointer?, tempURL: URL?) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("db_copy_\(UUID().uuidString).db")
        
        do {
            try FileManager.default.copyItem(at: url, to: tempURL)
        } catch {
            return (nil, nil)
        }
        
        var db: OpaquePointer?
        guard sqlite3_open(tempURL.path, &db) == SQLITE_OK else {
            try? FileManager.default.removeItem(at: tempURL)
            return (nil, nil)
        }
        
        return (db, tempURL)
    }
    
    /// 关闭数据库并清理临时文件
    private func closeDatabaseCopy(db: OpaquePointer?, tempURL: URL?) {
        if let db = db { sqlite3_close(db) }
        if let tempURL = tempURL { try? FileManager.default.removeItem(at: tempURL) }
    }
    
    /// 解析 Chrome Cookies 数据库
    func parseChromeCookies(at url: URL) -> Int {
        let (db, tempURL) = openDatabaseCopy(at: url)
        defer { closeDatabaseCopy(db: db, tempURL: tempURL) }
        
        guard let db = db else { return 0 }
        return countRows(db: db, table: "cookies")
    }
    
    /// 解析 Chrome Cookies 详情 (按域名分组)
    func parseChromeCookiesDetails(at url: URL) -> [(domain: String, count: Int)] {
        let (db, tempURL) = openDatabaseCopy(at: url)
        defer { closeDatabaseCopy(db: db, tempURL: tempURL) }
        
        guard let db = db else { return [] }
        
        let query = "SELECT host_key, count(*) as count FROM cookies GROUP BY host_key ORDER BY count DESC LIMIT 100"
        let results = executeQuery(db: db, query: query)
        
        return results.compactMap { row in
            guard let domain = row["host_key"] as? String,
                  let count = row["count"] as? Int else { return nil }
            return (domain, count)
        }
    }
    
    /// 解析 Chrome Login Data (密码)
    func parseChromePasswords(at url: URL) -> Int {
        let (db, tempURL) = openDatabaseCopy(at: url)
        defer { closeDatabaseCopy(db: db, tempURL: tempURL) }
        
        guard let db = db else { return 0 }
        return countRows(db: db, table: "logins")
    }
    
    /// 解析 Chrome Web Data (自动填充)
    func parseChromeAutofill(at url: URL) -> Int {
        let (db, tempURL) = openDatabaseCopy(at: url)
        defer { closeDatabaseCopy(db: db, tempURL: tempURL) }
        
        guard let db = db else { return 0 }
        return countRows(db: db, table: "autofill")
    }
    
    // MARK: - Safari 数据库解析
    
    /// 解析 Safari History 数据库
    func parseSafariHistory(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_close(db) }
        
        return countRows(db: db, table: "history_visits")
    }
    
    /// 解析 Safari 下载列表 (plist)
    func parseSafariDownloads(at url: URL) -> Int {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let downloads = plist["DownloadHistory"] as? [[String: Any]] else {
            return 0
        }
        return downloads.count
    }
    
    // MARK: - Firefox 数据库解析
    
    /// 解析 Firefox History (places.sqlite)
    func parseFirefoxHistory(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_close(db) }
        
        // moz_historyvisits 包含所有访问记录
        return countRows(db: db, table: "moz_historyvisits")
    }
    
    /// 解析 Firefox Cookies (cookies.sqlite)
    func parseFirefoxCookies(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_close(db) }
        
        return countRows(db: db, table: "moz_cookies")
    }
    
    /// 解析 Firefox Form History (formhistory.sqlite)
    func parseFirefoxFormHistory(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_close(db) }
        
        return countRows(db: db, table: "moz_formhistory")
    }
    
    // MARK: - 智能浏览器数据清理 (使用 SQL DELETE 而不是删除文件)
    
    /// 执行 SQL DELETE 语句
    private func executeDelete(db: OpaquePointer?, sql: String) -> Bool {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        defer { sqlite3_finalize(statement) }
        
        return sqlite3_step(statement) == SQLITE_DONE
    }
    
    /// 清理 Chrome 浏览历史 (使用 SQL DELETE，保留登录状态)
    func clearChromeHistory(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            print("❌ [Clean] Failed to open Chrome History for cleaning")
            return 0
        }
        defer { sqlite3_close(db) }
        
        var deleted = 0
        
        // 清除 visits 表 (访问记录)
        if executeDelete(db: db, sql: "DELETE FROM visits") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome visits")
        }
        
        // 清除 urls 表 (URL 记录)
        if executeDelete(db: db, sql: "DELETE FROM urls") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome urls")
        }
        
        // 清除 downloads 表 (下载记录)
        if executeDelete(db: db, sql: "DELETE FROM downloads") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome downloads")
        }
        
        // 清除 keyword_search_terms 表 (搜索记录)
        if executeDelete(db: db, sql: "DELETE FROM keyword_search_terms") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome search terms")
        }
        
        // VACUUM 压缩数据库
        _ = executeDelete(db: db, sql: "VACUUM")
        
        return deleted
    }
    
    /// 清理 Chrome Cookies (会退出网站登录，但保留 Google 同步账号)
    func clearChromeCookies(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            print("❌ [Clean] Failed to open Chrome Cookies for cleaning")
            return 0
        }
        defer { sqlite3_close(db) }
        
        // 删除所有 cookies
        if executeDelete(db: db, sql: "DELETE FROM cookies") {
            print("✅ [Clean] Cleared Chrome cookies")
            _ = executeDelete(db: db, sql: "VACUUM")
            return 1
        }
        return 0
    }
    
    /// 清理 Chrome 自动填充 (保留已保存的密码)
    func clearChromeAutofillData(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            print("❌ [Clean] Failed to open Chrome Web Data for cleaning")
            return 0
        }
        defer { sqlite3_close(db) }
        
        var deleted = 0
        
        // 清除自动填充数据
        if executeDelete(db: db, sql: "DELETE FROM autofill") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome autofill")
        }
        
        // 清除自动填充档案
        if executeDelete(db: db, sql: "DELETE FROM autofill_profiles") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome autofill profiles")
        }
        
        _ = executeDelete(db: db, sql: "VACUUM")
        return deleted
    }
    
    /// 清理 Safari 浏览历史 (使用 SQL DELETE)
    func clearSafariHistory(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            print("❌ [Clean] Failed to open Safari History for cleaning")
            return 0
        }
        defer { sqlite3_close(db) }
        
        var deleted = 0
        
        // 清除访问记录
        if executeDelete(db: db, sql: "DELETE FROM history_visits") {
            deleted += 1
            print("✅ [Clean] Cleared Safari history_visits")
        }
        
        // 清除 URL 记录
        if executeDelete(db: db, sql: "DELETE FROM history_items") {
            deleted += 1
            print("✅ [Clean] Cleared Safari history_items")
        }
        
        _ = executeDelete(db: db, sql: "VACUUM")
        return deleted
    }
}
