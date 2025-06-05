import XCTest
@testable import SachelGit

final class DiffViewTests: XCTestCase {
    var mockRepository: MockGitRepository!
    var diffView: DiffView!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockGitRepository()
        setupMockDiffData()
        diffView = DiffView(repository: mockRepository)
    }
    
    private func setupMockDiffData() {
        let lines = [
            DiffLine(content: "unchanged line", type: .context, oldLineNumber: 1, newLineNumber: 1),
            DiffLine(content: "removed line", type: .deletion, oldLineNumber: 2, newLineNumber: nil),
            DiffLine(content: "added line", type: .addition, oldLineNumber: nil, newLineNumber: 2),
            DiffLine(content: "another context", type: .context, oldLineNumber: 3, newLineNumber: 3)
        ]
        
        let hunk1 = Hunk(oldStart: 1, oldCount: 3, newStart: 1, newCount: 3, lines: lines)
        let hunk2 = Hunk(oldStart: 10, oldCount: 2, newStart: 10, newCount: 3, lines: Array(lines.prefix(2)))
        
        mockRepository.mockFileDiffs = [
            FileDiff(path: "file1.txt", hunks: [hunk1, hunk2]),
            FileDiff(path: "file2.txt", hunks: [hunk1])
        ]
    }
    
    func testDiffViewTitle() {
        XCTAssertEqual(diffView.title, "Git Diff")
    }
    
    func testHunkNavigation() {
        // Test navigation to next hunk
        diffView.handleKey(.char("j"))
        XCTAssertEqual(diffView.currentHunkIndex, 1)
        
        // Test boundary - shouldn't go beyond last hunk
        diffView.handleKey(.char("j"))
        XCTAssertEqual(diffView.currentHunkIndex, 1)
        
        // Test navigation to previous hunk
        diffView.handleKey(.char("k"))
        XCTAssertEqual(diffView.currentHunkIndex, 0)
        
        // Test boundary - shouldn't go below 0
        diffView.handleKey(.char("k"))
        XCTAssertEqual(diffView.currentHunkIndex, 0)
    }
    
    func testFileNavigation() {
        // Test navigation to next file
        diffView.handleKey(.char("J"))
        XCTAssertEqual(diffView.currentFileIndex, 1)
        XCTAssertEqual(diffView.currentHunkIndex, 0) // Should reset hunk index
        
        // Test boundary - shouldn't go beyond last file
        diffView.handleKey(.char("J"))
        XCTAssertEqual(diffView.currentFileIndex, 1)
        
        // Test navigation to previous file
        diffView.handleKey(.char("K"))
        XCTAssertEqual(diffView.currentFileIndex, 0)
        XCTAssertEqual(diffView.currentHunkIndex, 0) // Should reset hunk index
        
        // Test boundary - shouldn't go below 0
        diffView.handleKey(.char("K"))
        XCTAssertEqual(diffView.currentFileIndex, 0)
    }
    
    func testStageHunk() {
        diffView.handleKey(.char("s"))
        
        XCTAssertTrue(mockRepository.stageHunkCalled)
        XCTAssertEqual(mockRepository.lastHunkFile, "file1.txt")
    }
    
    func testUnstageHunk() {
        // Switch to staged mode first
        diffView.handleKey(.tab)
        diffView.handleKey(.char("u"))
        
        XCTAssertTrue(mockRepository.unstageHunkCalled)
        XCTAssertEqual(mockRepository.lastHunkFile, "file1.txt")
    }
    
    func testStageAllHunksInFile() {
        diffView.handleKey(.char("S"))
        
        XCTAssertTrue(mockRepository.stageFileCalled)
        XCTAssertEqual(mockRepository.lastStagedFile, "file1.txt")
    }
    
    func testUnstageAllHunksInFile() {
        // Switch to staged mode first
        diffView.handleKey(.tab)
        diffView.handleKey(.char("U"))
        
        XCTAssertTrue(mockRepository.unstageFileCalled)
        XCTAssertEqual(mockRepository.lastUnstagedFile, "file1.txt")
    }
    
    func testLineSelectionMode() {
        // Enter line selection mode
        diffView.handleKey(.char("v"))
        XCTAssertTrue(diffView.isLineSelectionMode)
        
        // Exit line selection mode
        diffView.handleKey(.escape)
        XCTAssertFalse(diffView.isLineSelectionMode)
    }
    
    func testModeToggle() {
        XCTAssertEqual(diffView.mode, .unstaged)
        
        diffView.handleKey(.tab)
        XCTAssertEqual(diffView.mode, .staged)
        
        diffView.handleKey(.tab)
        XCTAssertEqual(diffView.mode, .unstaged)
    }
    
    func testRefresh() {
        diffView.handleKey(.char("r"))
        
        XCTAssertTrue(mockRepository.diffCalled)
    }
}

// MARK: - Extended Mock Repository

extension MockGitRepository {
    var mockFileDiffs: [FileDiff] = []
    var diffCalled = false
    var stageHunkCalled = false
    var unstageHunkCalled = false
    var stageLinesSet: Set<Int>?
    var lastHunkFile: String?
    
    override func diff(for file: String? = nil, cached: Bool = false) throws -> [FileDiff] {
        diffCalled = true
        return mockFileDiffs
    }
    
    override func stageHunk(_ hunk: Hunk, in file: String) throws {
        stageHunkCalled = true
        lastHunkFile = file
    }
    
    override func unstageHunk(_ hunk: Hunk, in file: String) throws {
        unstageHunkCalled = true
        lastHunkFile = file
    }
    
    override func stageLines(_ lineIndices: Set<Int>, in hunk: Hunk, file: String) throws {
        stageLinesSet = lineIndices
        lastHunkFile = file
    }
}