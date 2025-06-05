import Foundation
import SwiftGit2

class GitRepository {
    private let repository: Repository
    
    init(repository: Repository) {
        self.repository = repository
    }
    
    var name: String {
        return repository.directoryURL?.lastPathComponent ?? "unknown"
    }
    
    func currentBranch() -> String {
        do {
            let head = try repository.HEAD()
            if let branch = head.targetBranch {
                return branch.name
            }
            return head.oid.description.prefix(7).description
        } catch {
            return "unknown"
        }
    }
    
    func status() throws -> [FileStatus] {
        let status = try repository.status()
        
        return status.compactMap { entry in
            let flags = entry.status
            
            return FileStatus(
                path: entry.headToIndex?.newFile.path ?? entry.indexToWorkdir?.newFile.path ?? "",
                staged: flags.contains(.indexNew) || flags.contains(.indexModified) || flags.contains(.indexDeleted),
                modified: flags.contains(.workTreeModified),
                untracked: flags.contains(.workTreeNew),
                deleted: flags.contains(.workTreeDeleted) || flags.contains(.indexDeleted),
                renamed: flags.contains(.indexRenamed),
                conflicted: flags.contains(.conflicted)
            )
        }
    }
    
    func diff(for file: String? = nil, cached: Bool = false) throws -> [FileDiff] {
        let diff: Diff
        
        if cached {
            // Show staged changes (index vs HEAD)
            diff = try repository.diffTreeToIndex()
        } else {
            // Show unstaged changes (working directory vs index)
            diff = try repository.diffIndexToWorkdir()
        }
        
        var fileDiffs: [FileDiff] = []
        
        try diff.forEach { delta in
            let filePath = delta.newFile.path
            
            // Filter by file if specified
            if let file = file, filePath != file {
                return
            }
            
            var hunks: [Hunk] = []
            
            try diff.patch(for: delta) { patch in
                for hunkIndex in 0..<patch.hunkCount {
                    let hunk = try patch.hunk(at: hunkIndex)
                    let header = hunk.header
                    
                    var lines: [DiffLine] = []
                    
                    for lineIndex in 0..<hunk.lineCount {
                        let line = try hunk.line(at: lineIndex)
                        
                        let lineType: DiffLine.LineType = switch line.origin {
                        case "+": .addition
                        case "-": .deletion
                        default: .context
                        }
                        
                        let diffLine = DiffLine(
                            content: line.content,
                            type: lineType,
                            oldLineNumber: lineType != .addition ? line.oldLineNumber : nil,
                            newLineNumber: lineType != .deletion ? line.newLineNumber : nil
                        )
                        
                        lines.append(diffLine)
                    }
                    
                    let hunkObj = Hunk(
                        oldStart: hunk.oldStart,
                        oldCount: hunk.oldCount,
                        newStart: hunk.newStart,
                        newCount: hunk.newCount,
                        lines: lines,
                        header: header
                    )
                    
                    hunks.append(hunkObj)
                }
            }
            
            let fileDiff = FileDiff(path: filePath, hunks: hunks)
            fileDiffs.append(fileDiff)
        }
        
        return fileDiffs
    }
    
    func stageFile(_ path: String) throws {
        try repository.index.add(path: path)
        try repository.index.write()
    }
    
    func unstageFile(_ path: String) throws {
        try repository.index.remove(path: path)
        try repository.index.write()
    }
    
    func stageHunk(_ hunk: Hunk, in file: String) throws {
        let patch = hunk.toPatch(filename: file)
        try applyPatch(patch, toIndex: true)
    }
    
    func unstageHunk(_ hunk: Hunk, in file: String) throws {
        let patch = hunk.toPatch(filename: file)
        try applyPatch(patch, toIndex: false)
    }
    
    func stageLines(_ lineIndices: Set<Int>, in hunk: Hunk, file: String) throws {
        let modifiedHunk = hunk.withSelectedLines(lineIndices)
        try stageHunk(modifiedHunk, in: file)
    }
    
    func commit(message: String, amend: Bool = false) throws -> String {
        let signature = try repository.signature()
        let index = repository.index
        let tree = try index.writeTree()
        
        let parents: [Commit]
        if amend {
            // For amend, we want the parents of the current HEAD
            let head = try repository.HEAD()
            if let currentCommit = head.commit {
                parents = Array(currentCommit.parents)
            } else {
                parents = []
            }
        } else {
            // Normal commit, HEAD is the parent
            if let head = try? repository.HEAD().commit {
                parents = [head]
            } else {
                parents = []
            }
        }
        
        let commit = try repository.createCommit(
            tree: tree,
            parents: parents,
            message: message,
            signature: signature
        )
        
        return commit.oid.description
    }
    
    func discardChanges(in file: String) throws {
        // Checkout the file from HEAD to discard changes
        try repository.checkout(path: file)
    }
    
    private func applyPatch(_ patch: String, toIndex: Bool) throws {
        // This is a simplified version - in a real implementation,
        // you'd use libgit2's patch application functions
        // For now, we'll use the file-level operations
        print("Would apply patch: \(patch)")
    }
}

struct FileDiff {
    let path: String
    let hunks: [Hunk]
    
    var totalAdditions: Int {
        return hunks.reduce(0) { $0 + $1.additionCount }
    }
    
    var totalDeletions: Int {
        return hunks.reduce(0) { $0 + $1.deletionCount }
    }
}