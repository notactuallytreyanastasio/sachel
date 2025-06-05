import Foundation

class GitRepository {
    
    init(repository: Any? = nil) {
        // Base implementation - will be overridden by MockGitRepository
    }
    
    var name: String {
        return "demo-repository"
    }
    
    func currentBranch() -> String {
        return "main"
    }
    
    func status() throws -> [FileStatus] {
        return []
    }
    
    func diff(for file: String? = nil, cached: Bool = false) throws -> [FileDiff] {
        return []
    }
    
    func stageFile(_ path: String) throws {
        // Base implementation
    }
    
    func unstageFile(_ path: String) throws {
        // Base implementation
    }
    
    func stageHunk(_ hunk: Hunk, in file: String) throws {
        // Base implementation
    }
    
    func unstageHunk(_ hunk: Hunk, in file: String) throws {
        // Base implementation
    }
    
    func stageLines(_ lineIndices: Set<Int>, in hunk: Hunk, file: String) throws {
        // Base implementation
    }
    
    func commit(message: String, amend: Bool = false) throws -> String {
        return "abc123"
    }
    
    func discardChanges(in file: String) throws {
        // Base implementation
    }
}