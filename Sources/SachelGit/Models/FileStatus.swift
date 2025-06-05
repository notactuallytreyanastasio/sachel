import Foundation

struct FileStatus: Equatable {
    let path: String
    let staged: Bool
    let modified: Bool
    let untracked: Bool
    let deleted: Bool
    let renamed: Bool
    let conflicted: Bool
    
    init(path: String, 
         staged: Bool = false, 
         modified: Bool = false, 
         untracked: Bool = false, 
         deleted: Bool = false, 
         renamed: Bool = false, 
         conflicted: Bool = false) {
        self.path = path
        self.staged = staged
        self.modified = modified
        self.untracked = untracked
        self.deleted = deleted
        self.renamed = renamed
        self.conflicted = conflicted
    }
    
    var statusIndicator: String {
        if conflicted { return "U" }
        if deleted { return "D" }
        if renamed { return "R" }
        if staged { return "S" }
        if modified { return "M" }
        if untracked { return "?" }
        return " "
    }
    
    var statusColor: String {
        if conflicted { return ANSICode.brightRed }
        if deleted { return ANSICode.red }
        if renamed { return ANSICode.yellow }
        if staged { return ANSICode.green }
        if modified { return ANSICode.yellow }
        if untracked { return ANSICode.cyan }
        return ANSICode.white
    }
    
    var displayName: String {
        return path
    }
    
    var canStage: Bool {
        return !staged && (modified || untracked || deleted)
    }
    
    var canUnstage: Bool {
        return staged
    }
}