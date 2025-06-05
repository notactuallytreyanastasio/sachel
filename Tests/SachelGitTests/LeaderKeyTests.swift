import XCTest
@testable import SachelGit

final class LeaderKeyTests: XCTestCase {
    var leaderKeyManager: LeaderKeyManager!
    var mockDelegate: MockLeaderKeyDelegate!
    
    override func setUp() {
        super.setUp()
        leaderKeyManager = LeaderKeyManager()
        mockDelegate = MockLeaderKeyDelegate()
        leaderKeyManager.delegate = mockDelegate
    }
    
    func testSpaceActivatesLeaderMode() {
        let handled = leaderKeyManager.handleKey(.space)
        
        XCTAssertTrue(handled)
        XCTAssertEqual(mockDelegate.lastHint, "Space")
    }
    
    func testValidGitStatusCommand() {
        _ = leaderKeyManager.handleKey(.space)
        _ = leaderKeyManager.handleKey(.char("g"))
        let handled = leaderKeyManager.handleKey(.char("s"))
        
        XCTAssertTrue(handled)
        XCTAssertEqual(mockDelegate.lastCommand, .gitStatus)
    }
    
    func testValidGitCommitCommand() {
        _ = leaderKeyManager.handleKey(.space)
        _ = leaderKeyManager.handleKey(.char("g"))
        let handled = leaderKeyManager.handleKey(.char("c"))
        
        XCTAssertTrue(handled)
        XCTAssertEqual(mockDelegate.lastCommand, .gitCommit)
    }
    
    func testPartialCommand() {
        _ = leaderKeyManager.handleKey(.space)
        let handled = leaderKeyManager.handleKey(.char("g"))
        
        XCTAssertTrue(handled)
        XCTAssertEqual(mockDelegate.lastHint, "Space → g")
        XCTAssertNil(mockDelegate.lastCommand)
    }
    
    func testInvalidCommand() {
        _ = leaderKeyManager.handleKey(.space)
        let handled = leaderKeyManager.handleKey(.char("x"))
        
        XCTAssertTrue(handled)
        XCTAssertTrue(mockDelegate.lastError?.contains("Unknown command") == true)
    }
    
    func testEscapeCancelsLeaderMode() {
        _ = leaderKeyManager.handleKey(.space)
        _ = leaderKeyManager.handleKey(.char("g"))
        let handled = leaderKeyManager.handleKey(.escape)
        
        XCTAssertTrue(handled)
        XCTAssertTrue(mockDelegate.hideLeaderHintCalled)
    }
    
    func testNonLeaderKeyNotHandled() {
        let handled = leaderKeyManager.handleKey(.char("j"))
        
        XCTAssertFalse(handled)
    }
    
    func testHelpCommand() {
        _ = leaderKeyManager.handleKey(.space)
        let handled = leaderKeyManager.handleKey(.char("h"))
        
        XCTAssertTrue(handled)
        XCTAssertEqual(mockDelegate.lastCommand, .help)
    }
    
    func testQuitCommand() {
        _ = leaderKeyManager.handleKey(.space)
        let handled = leaderKeyManager.handleKey(.char("q"))
        
        XCTAssertTrue(handled)
        XCTAssertEqual(mockDelegate.lastCommand, .quit)
    }
    
    func testAvailableCommands() {
        let commands = leaderKeyManager.getAvailableCommands()
        
        XCTAssertFalse(commands.isEmpty)
        XCTAssertTrue(commands.keys.contains("Space → g → s"))
        XCTAssertTrue(commands.keys.contains("Space → h"))
        XCTAssertTrue(commands.keys.contains("Space → q"))
    }
}

class MockLeaderKeyDelegate: LeaderKeyDelegate {
    var lastCommand: LeaderCommand?
    var lastHint: String?
    var lastError: String?
    var hideLeaderHintCalled = false
    
    func executeCommand(_ command: LeaderCommand) {
        lastCommand = command
    }
    
    func showLeaderHint(_ sequence: String) {
        lastHint = sequence
    }
    
    func hideLeaderHint() {
        hideLeaderHintCalled = true
    }
    
    func showError(_ message: String) {
        lastError = message
    }
}