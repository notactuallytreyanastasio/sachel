import XCTest
@testable import SachelGit

final class StatusViewTests: XCTestCase {
    var mockRepository: MockGitRepository!
    var statusView: StatusView!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockGitRepository()
        statusView = StatusView(repository: mockRepository)
    }
    
    func testStatusViewTitle() {
        XCTAssertEqual(statusView.title, "Git Status")
    }
    
    func testNavigationKeys() {
        // Setup test files
        mockRepository.mockFiles = [
            FileStatus(path: "file1.txt", modified: true),
            FileStatus(path: "file2.txt", staged: true),
            FileStatus(path: "file3.txt", untracked: true)
        ]
        
        // Test initial state
        XCTAssertEqual(statusView.selectedIndex, 0)
        
        // Test navigation down
        statusView.handleKey(.char("j"))
        XCTAssertEqual(statusView.selectedIndex, 1)
        
        statusView.handleKey(.char("j"))
        XCTAssertEqual(statusView.selectedIndex, 2)
        
        // Test boundary - shouldn't go beyond last file
        statusView.handleKey(.char("j"))
        XCTAssertEqual(statusView.selectedIndex, 2)
        
        // Test navigation up
        statusView.handleKey(.char("k"))
        XCTAssertEqual(statusView.selectedIndex, 1)
        
        statusView.handleKey(.char("k"))
        XCTAssertEqual(statusView.selectedIndex, 0)
        
        // Test boundary - shouldn't go below 0
        statusView.handleKey(.char("k"))
        XCTAssertEqual(statusView.selectedIndex, 0)
    }
    
    func testStageFile() {
        mockRepository.mockFiles = [
            FileStatus(path: "modified.txt", modified: true)
        ]
        
        statusView.handleKey(.char("s"))
        
        XCTAssertTrue(mockRepository.stageFileCalled)
        XCTAssertEqual(mockRepository.lastStagedFile, "modified.txt")
    }
    
    func testUnstageFile() {
        mockRepository.mockFiles = [
            FileStatus(path: "staged.txt", staged: true)
        ]
        
        statusView.handleKey(.char("u"))
        
        XCTAssertTrue(mockRepository.unstageFileCalled)
        XCTAssertEqual(mockRepository.lastUnstagedFile, "staged.txt")
    }
    
    func testRefresh() {
        statusView.handleKey(.char("r"))
        
        XCTAssertTrue(mockRepository.statusCalled)
    }
}

// MARK: - Mock Repository

class MockGitRepository: GitRepository {
    var mockFiles: [FileStatus] = []
    var mockCurrentBranch = "main"
    var mockName = "test-repo"
    
    var statusCalled = false
    var stageFileCalled = false
    var unstageFileCalled = false
    var lastStagedFile: String?
    var lastUnstagedFile: String?
    
    override var name: String {
        return mockName
    }
    
    override func currentBranch() -> String {
        return mockCurrentBranch
    }
    
    override func status() throws -> [FileStatus] {
        statusCalled = true
        return mockFiles
    }
    
    override func stageFile(_ path: String) throws {
        stageFileCalled = true
        lastStagedFile = path
        
        // Update mock files to reflect staging
        for i in 0..<mockFiles.count {
            if mockFiles[i].path == path {
                mockFiles[i] = FileStatus(
                    path: path,
                    staged: true,
                    modified: false,
                    untracked: false,
                    deleted: mockFiles[i].deleted,
                    renamed: mockFiles[i].renamed,
                    conflicted: mockFiles[i].conflicted
                )
                break
            }
        }
    }
    
    override func unstageFile(_ path: String) throws {
        unstageFileCalled = true
        lastUnstagedFile = path
        
        // Update mock files to reflect unstaging
        for i in 0..<mockFiles.count {
            if mockFiles[i].path == path {
                mockFiles[i] = FileStatus(
                    path: path,
                    staged: false,
                    modified: true,
                    untracked: false,
                    deleted: mockFiles[i].deleted,
                    renamed: mockFiles[i].renamed,
                    conflicted: mockFiles[i].conflicted
                )
                break
            }
        }
    }
}