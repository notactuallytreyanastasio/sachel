import XCTest
@testable import SachelGit

final class CommitViewTests: XCTestCase {
    var mockRepository: MockGitRepository!
    var commitView: CommitView!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockGitRepository()
        mockRepository.mockFiles = [
            FileStatus(path: "file1.txt", staged: true),
            FileStatus(path: "file2.txt", staged: true)
        ]
        commitView = CommitView(repository: mockRepository)
    }
    
    func testCommitViewTitle() {
        XCTAssertEqual(commitView.title, "Commit")
    }
    
    func testInitialMode() {
        XCTAssertEqual(commitView.mode, .normal)
        XCTAssertEqual(commitView.commitMessage, "")
        XCTAssertEqual(commitView.cursorPosition, 0)
    }
    
    func testEnterInsertMode() {
        commitView.handleKey(.char("i"))
        
        XCTAssertEqual(commitView.mode, .insert)
        XCTAssertEqual(commitView.cursorPosition, 0)
    }
    
    func testExitInsertMode() {
        // Enter insert mode first
        commitView.handleKey(.char("i"))
        XCTAssertEqual(commitView.mode, .insert)
        
        // Exit insert mode
        commitView.handleKey(.escape)
        XCTAssertEqual(commitView.mode, .normal)
    }
    
    func testInsertCharacters() {
        commitView.handleKey(.char("i")) // Enter insert mode
        commitView.handleKey(.char("H"))
        commitView.handleKey(.char("e"))
        commitView.handleKey(.char("l"))
        commitView.handleKey(.char("l"))
        commitView.handleKey(.char("o"))
        
        XCTAssertEqual(commitView.commitMessage, "Hello")
        XCTAssertEqual(commitView.cursorPosition, 5)
    }
    
    func testBackspaceInInsertMode() {
        commitView.handleKey(.char("i")) // Enter insert mode
        commitView.handleKey(.char("H"))
        commitView.handleKey(.char("i"))
        commitView.handleKey(.backspace)
        
        XCTAssertEqual(commitView.commitMessage, "H")
        XCTAssertEqual(commitView.cursorPosition, 1)
    }
    
    func testBackspaceAtBeginning() {
        commitView.handleKey(.char("i")) // Enter insert mode
        commitView.handleKey(.backspace) // Should do nothing
        
        XCTAssertEqual(commitView.commitMessage, "")
        XCTAssertEqual(commitView.cursorPosition, 0)
    }
    
    func testInsertNewline() {
        commitView.handleKey(.char("i")) // Enter insert mode
        commitView.handleKey(.char("L"))
        commitView.handleKey(.char("i"))
        commitView.handleKey(.char("n"))
        commitView.handleKey(.char("e"))
        commitView.handleKey(.enter)
        commitView.handleKey(.char("2"))
        
        XCTAssertEqual(commitView.commitMessage, "Line\n2")
        XCTAssertEqual(commitView.cursorPosition, 6)
    }
    
    func testCursorMovement() {
        commitView.handleKey(.char("i")) // Enter insert mode
        commitView.handleKey(.char("H"))
        commitView.handleKey(.char("e"))
        commitView.handleKey(.char("l"))
        commitView.handleKey(.char("l"))
        commitView.handleKey(.char("o"))
        
        // Move cursor left
        commitView.handleKey(.left)
        XCTAssertEqual(commitView.cursorPosition, 4)
        
        commitView.handleKey(.left)
        XCTAssertEqual(commitView.cursorPosition, 3)
        
        // Move cursor right
        commitView.handleKey(.right)
        XCTAssertEqual(commitView.cursorPosition, 4)
        
        // Test boundaries
        for _ in 0..<10 {
            commitView.handleKey(.left)
        }
        XCTAssertEqual(commitView.cursorPosition, 0)
        
        for _ in 0..<10 {
            commitView.handleKey(.right)
        }
        XCTAssertEqual(commitView.cursorPosition, 5)
    }
    
    func testCommitWithMessage() {
        // Add a commit message
        commitView.handleKey(.char("i"))
        let message = "Test commit message"
        for char in message {
            commitView.handleKey(.char(char))
        }
        commitView.handleKey(.escape)
        
        // Commit
        commitView.handleKey(.ctrl("c"))
        
        XCTAssertTrue(mockRepository.commitCalled)
        XCTAssertEqual(mockRepository.lastCommitMessage, message)
        XCTAssertFalse(mockRepository.lastCommitAmend)
    }
    
    func testCommitWithoutMessage() {
        // Try to commit without message
        commitView.handleKey(.ctrl("c"))
        
        XCTAssertFalse(mockRepository.commitCalled)
        XCTAssertFalse(commitView.errorMessage.isEmpty)
    }
    
    func testAmendCommit() {
        // Add a commit message
        commitView.handleKey(.char("i"))
        let message = "Amended commit"
        for char in message {
            commitView.handleKey(.char(char))
        }
        commitView.handleKey(.escape)
        
        // Amend commit
        commitView.handleKey(.ctrl("a"))
        
        XCTAssertTrue(mockRepository.commitCalled)
        XCTAssertEqual(mockRepository.lastCommitMessage, message)
        XCTAssertTrue(mockRepository.lastCommitAmend)
    }
    
    func testRefreshStagedFiles() {
        commitView.handleKey(.char("r"))
        
        XCTAssertTrue(mockRepository.statusCalled)
    }
    
    func testWordWrapping() {
        let longText = String(repeating: "A", count: 100)
        let wrapped = commitView.wrapText(longText, width: 50)
        
        XCTAssertGreaterThan(wrapped.count, 1)
        for line in wrapped {
            XCTAssertLessThanOrEqual(line.count, 50)
        }
    }
    
    func testWordWrappingWithNewlines() {
        let text = "Line 1\nLine 2\nVery long line that should be wrapped because it exceeds the width limit"
        let wrapped = commitView.wrapText(text, width: 30)
        
        XCTAssertGreaterThanOrEqual(wrapped.count, 4) // At least 4 lines after wrapping
        XCTAssertEqual(wrapped[0], "Line 1")
        XCTAssertEqual(wrapped[1], "Line 2")
    }
}

// MARK: - Extended Mock Repository for Commit

extension MockGitRepository {
    var commitCalled = false
    var lastCommitMessage: String?
    var lastCommitAmend = false
    
    override func commit(message: String, amend: Bool = false) throws -> String {
        commitCalled = true
        lastCommitMessage = message
        lastCommitAmend = amend
        return "abc123def456" // Mock commit hash
    }
}