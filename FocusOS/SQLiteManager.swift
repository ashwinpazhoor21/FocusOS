import Foundation
import SQLite3

// MARK: - SQLiteManager (single responsibility: open DB + run SQL safely)
final class SQLiteManager {
    static let shared = SQLiteManager()

    private var db: OpaquePointer? = nil
    private let queue = DispatchQueue(label: "FocusOS.SQLiteQueue") // serialize access

    private init() {
        openOrCreateDatabase()
        createTablesIfNeeded()
        addWindowTitleColumnIfNeeded() // ✅ migrate existing DBs
    }

    deinit {
        closeDatabase()
    }

    // MARK: Paths

    private func databaseURL() -> URL {
        let fm = FileManager.default
        let appSupport = try! fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = appSupport.appendingPathComponent("FocusOS", isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try! fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent("focusos.sqlite")
    }

    // MARK: DB Lifecycle

    private func openOrCreateDatabase() {
        let url = databaseURL()
        let path = url.path

        if sqlite3_open(path, &db) != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(db))
            print("❌ SQLite open failed: \(msg)")
        } else {
            // Good SQLite defaults
            _ = execute(sql: "PRAGMA journal_mode = WAL;")
            _ = execute(sql: "PRAGMA synchronous = NORMAL;")
            _ = execute(sql: "PRAGMA foreign_keys = ON;")
        }
    }

    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }

    // MARK: Schema

    private func createTablesIfNeeded() {
        let createEvents = """
        CREATE TABLE IF NOT EXISTS app_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL NOT NULL,
            bundle_id TEXT NOT NULL,
            app_name TEXT NOT NULL,
            is_idle INTEGER NOT NULL DEFAULT 0,
            window_title TEXT
        );
        """

        let idxEvents = """
        CREATE INDEX IF NOT EXISTS idx_app_events_ts
        ON app_events(timestamp);
        """

        let createSessions = """
        CREATE TABLE IF NOT EXISTS focus_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_ts REAL NOT NULL,
            end_ts REAL NOT NULL,
            bundle_id TEXT NOT NULL,
            app_name TEXT NOT NULL,
            duration_sec INTEGER NOT NULL,
            ended_by_idle INTEGER NOT NULL DEFAULT 0
        );
        """

        let idxSessions = """
        CREATE INDEX IF NOT EXISTS idx_sessions_start
        ON focus_sessions(start_ts);
        """

        // ✅ NEW: violations table
        let createViolations = """
        CREATE TABLE IF NOT EXISTS focus_violations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL NOT NULL,
            bundle_id TEXT NOT NULL,
            app_name TEXT NOT NULL
        );
        """

        let idxViolations = """
        CREATE INDEX IF NOT EXISTS idx_violations_ts
        ON focus_violations(timestamp);
        """

        _ = execute(sql: createEvents)
        _ = execute(sql: idxEvents)
        _ = execute(sql: createSessions)
        _ = execute(sql: idxSessions)

        _ = execute(sql: createViolations)
        _ = execute(sql: idxViolations)
    }

    // Adds the column for older DBs that were created before window_title existed
    private func addWindowTitleColumnIfNeeded() {
        // Safe: if the column already exists, SQLite returns an error — we ignore it.
        _ = execute(sql: "ALTER TABLE app_events ADD COLUMN window_title TEXT;")
    }

    // MARK: Helpers

    @discardableResult
    private func execute(sql: String) -> Bool {
        var errMsg: UnsafeMutablePointer<Int8>?
        let rc = sqlite3_exec(db, sql, nil, nil, &errMsg)
        if rc != SQLITE_OK {
            let msg = errMsg.map { String(cString: $0) } ?? "unknown"
            // Ignore “duplicate column name” errors from migrations
            if !msg.lowercased().contains("duplicate column name") {
                print("❌ SQLite exec failed: \(msg)")
            }
            sqlite3_free(errMsg)
            return false
        }
        return true
    }

    // MARK: Insert App Event

    func insertAppEvent(timestamp: Date, bundleId: String, appName: String, isIdle: Bool, windowTitle: String?) {
        queue.async {
            let sql = """
            INSERT INTO app_events(timestamp, bundle_id, app_name, is_idle, window_title)
            VALUES (?, ?, ?, ?, ?);
            """
            var stmt: OpaquePointer? = nil
            guard sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ prepare insertAppEvent failed: \(msg)")
                return
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_double(stmt, 1, timestamp.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 2, (bundleId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (appName as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 4, isIdle ? 1 : 0)

            if let title = windowTitle, !title.isEmpty {
                sqlite3_bind_text(stmt, 5, (title as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 5)
            }

            if sqlite3_step(stmt) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ insertAppEvent failed: \(msg)")
            }
        }
    }

    // MARK: Read events for a day (used by sessionizer)

    struct AppEventRow {
        let ts: Date
        let bundleId: String
        let appName: String
        let isIdle: Bool
        let windowTitle: String?
    }

    func fetchAppEvents(forDay day: Date) -> [AppEventRow] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!

        let startSec = start.timeIntervalSince1970
        let endSec = end.timeIntervalSince1970

        return queue.sync {
            var rows: [AppEventRow] = []

            let sql = """
            SELECT timestamp, bundle_id, app_name, is_idle, window_title
            FROM app_events
            WHERE timestamp >= ? AND timestamp < ?
            ORDER BY timestamp ASC;
            """

            var stmt: OpaquePointer? = nil
            guard sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ prepare fetchAppEvents failed: \(msg)")
                return []
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_double(stmt, 1, startSec)
            sqlite3_bind_double(stmt, 2, endSec)

            while sqlite3_step(stmt) == SQLITE_ROW {
                let tsSec = sqlite3_column_double(stmt, 0)

                let bundlePtr = sqlite3_column_text(stmt, 1)
                let namePtr = sqlite3_column_text(stmt, 2)
                let idleInt = sqlite3_column_int(stmt, 3)
                let titlePtr = sqlite3_column_text(stmt, 4)

                let bundleId = bundlePtr != nil ? String(cString: bundlePtr!) : "unknown"
                let appName = namePtr != nil ? String(cString: namePtr!) : "unknown"
                let windowTitle = titlePtr != nil ? String(cString: titlePtr!) : nil

                rows.append(AppEventRow(
                    ts: Date(timeIntervalSince1970: tsSec),
                    bundleId: bundleId,
                    appName: appName,
                    isIdle: idleInt == 1,
                    windowTitle: windowTitle
                ))
            }

            return rows
        }
    }

    // MARK: Sessions table helpers

    func deleteSessions(forDay day: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!

        let startSec = start.timeIntervalSince1970
        let endSec = end.timeIntervalSince1970

        queue.async {
            let sql = "DELETE FROM focus_sessions WHERE start_ts >= ? AND start_ts < ?;"
            var stmt: OpaquePointer? = nil
            guard sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ prepare deleteSessions failed: \(msg)")
                return
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_double(stmt, 1, startSec)
            sqlite3_bind_double(stmt, 2, endSec)

            if sqlite3_step(stmt) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ deleteSessions failed: \(msg)")
            }
        }
    }

    func insertSession(start: Date, end: Date, bundleId: String, appName: String, durationSec: Int, endedByIdle: Bool) {
        queue.async {
            let sql = """
            INSERT INTO focus_sessions(start_ts, end_ts, bundle_id, app_name, duration_sec, ended_by_idle)
            VALUES (?, ?, ?, ?, ?, ?);
            """
            var stmt: OpaquePointer? = nil
            guard sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ prepare insertSession failed: \(msg)")
                return
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_double(stmt, 1, start.timeIntervalSince1970)
            sqlite3_bind_double(stmt, 2, end.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 3, (bundleId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (appName as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 5, Int32(durationSec))
            sqlite3_bind_int(stmt, 6, endedByIdle ? 1 : 0)

            if sqlite3_step(stmt) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ insertSession failed: \(msg)")
            }
        }
    }

    // MARK: Fetch sessions for metrics

    struct SessionRow {
        let start: Date
        let end: Date
        let bundleId: String
        let appName: String
        let durationSec: Int
    }

    func fetchSessions(forDay day: Date) -> [SessionRow] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!

        let startSec = start.timeIntervalSince1970
        let endSec = end.timeIntervalSince1970

        return queue.sync {
            var rows: [SessionRow] = []

            let sql = """
            SELECT start_ts, end_ts, bundle_id, app_name, duration_sec
            FROM focus_sessions
            WHERE start_ts >= ? AND start_ts < ?
            ORDER BY start_ts ASC;
            """

            var stmt: OpaquePointer? = nil
            guard sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ prepare fetchSessions failed: \(msg)")
                return []
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_double(stmt, 1, startSec)
            sqlite3_bind_double(stmt, 2, endSec)

            while sqlite3_step(stmt) == SQLITE_ROW {
                let s = sqlite3_column_double(stmt, 0)
                let e = sqlite3_column_double(stmt, 1)

                let bundlePtr = sqlite3_column_text(stmt, 2)
                let namePtr = sqlite3_column_text(stmt, 3)
                let dur = Int(sqlite3_column_int(stmt, 4))

                let bundleId = bundlePtr != nil ? String(cString: bundlePtr!) : "unknown"
                let appName = namePtr != nil ? String(cString: namePtr!) : "unknown"

                rows.append(SessionRow(
                    start: Date(timeIntervalSince1970: s),
                    end: Date(timeIntervalSince1970: e),
                    bundleId: bundleId,
                    appName: appName,
                    durationSec: dur
                ))
            }

            return rows
        }
    }

    // MARK: Focus Mode Violations (NEW)

    func insertViolation(timestamp: Date, bundleId: String, appName: String) {
        queue.async {
            let sql = """
            INSERT INTO focus_violations(timestamp, bundle_id, app_name)
            VALUES (?, ?, ?);
            """
            var stmt: OpaquePointer? = nil
            guard sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ prepare insertViolation failed: \(msg)")
                return
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_double(stmt, 1, timestamp.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 2, (bundleId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (appName as NSString).utf8String, -1, nil)

            if sqlite3_step(stmt) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ insertViolation failed: \(msg)")
            }
        }
    }

    func fetchViolationCount(forDay day: Date) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!

        let startSec = start.timeIntervalSince1970
        let endSec = end.timeIntervalSince1970

        return queue.sync {
            let sql = """
            SELECT COUNT(*)
            FROM focus_violations
            WHERE timestamp >= ? AND timestamp < ?;
            """
            var stmt: OpaquePointer? = nil
            guard sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ prepare fetchViolationCount failed: \(msg)")
                return 0
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_double(stmt, 1, startSec)
            sqlite3_bind_double(stmt, 2, endSec)

            if sqlite3_step(stmt) == SQLITE_ROW {
                return Int(sqlite3_column_int(stmt, 0))
            }
            return 0
        }
    }

    // Optional: fetch last N violations for richer summaries
    struct ViolationRow {
        let ts: Date
        let bundleId: String
        let appName: String
    }

    func fetchViolations(forDay day: Date, limit: Int = 10) -> [ViolationRow] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!

        let startSec = start.timeIntervalSince1970
        let endSec = end.timeIntervalSince1970

        return queue.sync {
            var out: [ViolationRow] = []

            let sql = """
            SELECT timestamp, bundle_id, app_name
            FROM focus_violations
            WHERE timestamp >= ? AND timestamp < ?
            ORDER BY timestamp DESC
            LIMIT ?;
            """

            var stmt: OpaquePointer? = nil
            guard sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(self.db))
                print("❌ prepare fetchViolations failed: \(msg)")
                return []
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_double(stmt, 1, startSec)
            sqlite3_bind_double(stmt, 2, endSec)
            sqlite3_bind_int(stmt, 3, Int32(limit))

            while sqlite3_step(stmt) == SQLITE_ROW {
                let tsSec = sqlite3_column_double(stmt, 0)
                let bundlePtr = sqlite3_column_text(stmt, 1)
                let namePtr = sqlite3_column_text(stmt, 2)

                let bundleId = bundlePtr != nil ? String(cString: bundlePtr!) : "unknown"
                let appName = namePtr != nil ? String(cString: namePtr!) : "unknown"

                out.append(ViolationRow(
                    ts: Date(timeIntervalSince1970: tsSec),
                    bundleId: bundleId,
                    appName: appName
                ))
            }

            return out
        }
    }
}
