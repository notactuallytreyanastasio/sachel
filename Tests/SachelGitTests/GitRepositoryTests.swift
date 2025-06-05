import XCTest
import Foundation
@testable import SachelGit

final class GitRepositoryTests: XCTestCase {
    
    func testFileStatusIndicators() {
        XCTAssertEqual(FileStatus(path: "test.txt", staged: true).statusIndicator, "S")
        XCTAssertEqual(FileStatus(path: "test.txt", modified: true).statusIndicator, "M")
        XCTAssertEqual(FileStatus(path: "test.txt", untracked: true).statusIndicator, "?")
        XCTAssertEqual(FileStatus(path: "test.txt", deleted: true).statusIndicator, "D")
        XCTAssertEqual(FileStatus(path: "test.txt", renamed: true).statusIndicator, "R")
        XCTAssertEqual(FileStatus(path: "test.txt", conflicted: true).statusIndicator, "U")
    }
    
    func testFileStatusColors() {
        XCTAssertEqual(FileStatus(path: "test.txt", staged: true).statusColor, ANSICode.green)
        XCTAssertEqual(FileStatus(path: "test.txt", modified: true).statusColor, ANSICode.yellow)
        XCTAssertEqual(FileStatus(path: "test.txt", untracked: true).statusColor, ANSICode.cyan)
        XCTAssertEqual(FileStatus(path: "test.txt", deleted: true).statusColor, ANSICode.red)
        XCTAssertEqual(FileStatus(path: "test.txt", conflicted: true).statusColor, ANSICode.brightRed)
    }
    
    func testFileStatusCanStage() {
        XCTAssertTrue(FileStatus(path: "test.txt", modified: true).canStage)
        XCTAssertTrue(FileStatus(path: "test.txt", untracked: true).canStage)
        XCTAssertTrue(FileStatus(path: "test.txt", deleted: true).canStage)
        XCTAssertFalse(FileStatus(path: "test.txt", staged: true).canStage)
        XCTAssertFalse(FileStatus(path: "test.txt").canStage)
    }
    
    func testFileStatusCanUnstage() {
        XCTAssertTrue(FileStatus(path: "test.txt", staged: true).canUnstage)
        XCTAssertFalse(FileStatus(path: "test.txt", modified: true).canUnstage)
        XCTAssertFalse(FileStatus(path: "test.txt").canUnstage)
    }
}

final class HunkTests: XCTestCase {
    
    func testHunkCreation() {
        let lines = [
            DiffLine(content: "unchanged line", type: .context, oldLineNumber: 1, newLineNumber: 1),
            DiffLine(content: "removed line", type: .deletion, oldLineNumber: 2, newLineNumber: nil),
            DiffLine(content: "added line", type: .addition, oldLineNumber: nil, newLineNumber: 2)
        ]
        
        let hunk = Hunk(oldStart: 1, oldCount: 2, newStart: 1, newCount: 2, lines: lines)
        
        XCTAssertEqual(hunk.oldStart, 1)
        XCTAssertEqual(hunk.oldCount, 2)
        XCTAssertEqual(hunk.newStart, 1)
        XCTAssertEqual(hunk.newCount, 2)
        XCTAssertEqual(hunk.lines.count, 3)
    }
    
    func testHunkHeaderLine() {
        let hunk = Hunk(oldStart: 10, oldCount: 5, newStart: 12, newCount: 7, lines: [])
        XCTAssertEqual(hunk.headerLine, "@@ -10,5 +12,7 @@")
        
        let hunkWithHeader = Hunk(oldStart: 10, oldCount: 5, newStart: 12, newCount: 7, lines: [], header: "custom header")
        XCTAssertEqual(hunkWithHeader.headerLine, "custom header")
    }
    
    func testHunkCounts() {
        let lines = [
            DiffLine(content: "unchanged", type: .context, oldLineNumber: 1, newLineNumber: 1),
            DiffLine(content: "removed", type: .deletion, oldLineNumber: 2, newLineNumber: nil),
            DiffLine(content: "added1", type: .addition, oldLineNumber: nil, newLineNumber: 2),
            DiffLine(content: "added2", type: .addition, oldLineNumber: nil, newLineNumber: 3)
        ]
        
        let hunk = Hunk(oldStart: 1, oldCount: 2, newStart: 1, newCount: 3, lines: lines)
        
        XCTAssertEqual(hunk.additionCount, 2)
        XCTAssertEqual(hunk.deletionCount, 1)
        XCTAssertEqual(hunk.contextCount, 1)
    }
    
    func testHunkWithSelectedLines() {
        let lines = [
            DiffLine(content: "context1", type: .context, oldLineNumber: 1, newLineNumber: 1),
            DiffLine(content: "removed1", type: .deletion, oldLineNumber: 2, newLineNumber: nil),
            DiffLine(content: "removed2", type: .deletion, oldLineNumber: 3, newLineNumber: nil),
            DiffLine(content: "added1", type: .addition, oldLineNumber: nil, newLineNumber: 2),
            DiffLine(content: "context2", type: .context, oldLineNumber: 4, newLineNumber: 3)
        ]
        
        let hunk = Hunk(oldStart: 1, oldCount: 4, newStart: 1, newCount: 3, lines: lines)
        
        // Select only the first deletion and the addition
        let selectedLines: Set<Int> = [1, 3]
        let modifiedHunk = hunk.withSelectedLines(selectedLines)
        
        // Should include all context lines plus selected lines
        XCTAssertEqual(modifiedHunk.lines.count, 4) // context1, removed1, added1, context2
        XCTAssertEqual(modifiedHunk.lines[0].type, .context)
        XCTAssertEqual(modifiedHunk.lines[1].type, .deletion)
        XCTAssertEqual(modifiedHunk.lines[2].type, .addition)
        XCTAssertEqual(modifiedHunk.lines[3].type, .context)
    }
    
    func testDiffLineDisplayContent() {
        let contextLine = DiffLine(content: "unchanged", type: .context, oldLineNumber: 1, newLineNumber: 1)
        let additionLine = DiffLine(content: "added", type: .addition, oldLineNumber: nil, newLineNumber: 2)
        let deletionLine = DiffLine(content: "removed", type: .deletion, oldLineNumber: 2, newLineNumber: nil)
        
        XCTAssertEqual(contextLine.displayContent, " unchanged")
        XCTAssertEqual(additionLine.displayContent, "+added")
        XCTAssertEqual(deletionLine.displayContent, "-removed")
    }
    
    func testDiffLineColors() {
        let contextLine = DiffLine(content: "unchanged", type: .context, oldLineNumber: 1, newLineNumber: 1)
        let additionLine = DiffLine(content: "added", type: .addition, oldLineNumber: nil, newLineNumber: 2)
        let deletionLine = DiffLine(content: "removed", type: .deletion, oldLineNumber: 2, newLineNumber: nil)
        
        XCTAssertEqual(contextLine.color, ANSICode.white)
        XCTAssertEqual(additionLine.color, ANSICode.green)
        XCTAssertEqual(deletionLine.color, ANSICode.red)
    }
}