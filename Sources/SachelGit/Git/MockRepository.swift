import Foundation

// Simple mock implementation for demonstration purposes
// In a real implementation, this would use SwiftGit2

class MockGitRepository: GitRepository {
    
    override init(repository: Any? = nil) {
        super.init(repository: repository)
    }
    
    convenience init() {
        self.init(repository: "mock")
    }
    
    override var name: String {
        return "sachel-git-demo"
    }
    
    override func currentBranch() -> String {
        return "main"
    }
    
    override func status() throws -> [FileStatus] {
        // Return some demo file statuses
        return [
            FileStatus(path: "README.md", modified: true),
            FileStatus(path: "Package.swift", staged: true),
            FileStatus(path: "Sources/SachelGit/main.swift", modified: true),
            FileStatus(path: "new-feature.txt", untracked: true),
            FileStatus(path: "deleted-file.txt", deleted: true)
        ]
    }
    
    override func diff(for file: String? = nil, cached: Bool = false) throws -> [FileDiff] {
        // Return demo diff data
        let lines = [
            DiffLine(content: "import Foundation", type: .context, oldLineNumber: 1, newLineNumber: 1),
            DiffLine(content: "// Old comment", type: .deletion, oldLineNumber: 2, newLineNumber: nil),
            DiffLine(content: "// New improved comment", type: .addition, oldLineNumber: nil, newLineNumber: 2),
            DiffLine(content: "", type: .context, oldLineNumber: 3, newLineNumber: 3),
            DiffLine(content: "func main() {", type: .context, oldLineNumber: 4, newLineNumber: 4),
            DiffLine(content: "    print(\"Hello, World!\")", type: .deletion, oldLineNumber: 5, newLineNumber: nil),
            DiffLine(content: "    print(\"Hello, Sachel Git!\")", type: .addition, oldLineNumber: nil, newLineNumber: 5),
            DiffLine(content: "}", type: .context, oldLineNumber: 6, newLineNumber: 6)
        ]
        
        let hunk1 = Hunk(oldStart: 1, oldCount: 6, newStart: 1, newCount: 6, lines: lines)
        
        let moreLines = [
            DiffLine(content: "// Adding new function", type: .addition, oldLineNumber: nil, newLineNumber: 10),
            DiffLine(content: "func newFeature() {", type: .addition, oldLineNumber: nil, newLineNumber: 11),
            DiffLine(content: "    return \"awesome\"", type: .addition, oldLineNumber: nil, newLineNumber: 12),
            DiffLine(content: "}", type: .addition, oldLineNumber: nil, newLineNumber: 13)
        ]
        
        let hunk2 = Hunk(oldStart: 10, oldCount: 0, newStart: 10, newCount: 4, lines: moreLines)
        
        return [
            FileDiff(path: "Sources/SachelGit/main.swift", hunks: [hunk1, hunk2]),
            FileDiff(path: "README.md", hunks: [hunk1])
        ]
    }
    
    override func stageFile(_ path: String) throws {
        print("Mock: Staging file \(path)")
    }
    
    override func unstageFile(_ path: String) throws {
        print("Mock: Unstaging file \(path)")
    }
    
    override func stageHunk(_ hunk: Hunk, in file: String) throws {
        print("Mock: Staging hunk in \(file)")
    }
    
    override func unstageHunk(_ hunk: Hunk, in file: String) throws {
        print("Mock: Unstaging hunk in \(file)")
    }
    
    override func stageLines(_ lineIndices: Set<Int>, in hunk: Hunk, file: String) throws {
        print("Mock: Staging \(lineIndices.count) lines in \(file)")
    }
    
    override func commit(message: String, amend: Bool = false) throws -> String {
        let hash = "abc123d" + String(Int.random(in: 1000...9999))
        print("Mock: Created commit \(hash) with message: \(message)")
        return hash
    }
    
    override func discardChanges(in file: String) throws {
        print("Mock: Discarding changes in \(file)")
    }
}