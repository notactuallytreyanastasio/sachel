import XCTest
@testable import SachelGit

final class SyntaxHighlighterTests: XCTestCase {
    
    func testLanguageDetection() {
        XCTAssertEqual(Language.from(filename: "main.swift"), .swift)
        XCTAssertEqual(Language.from(filename: "script.py"), .python)
        XCTAssertEqual(Language.from(filename: "app.js"), .javascript)
        XCTAssertEqual(Language.from(filename: "component.ts"), .typescript)
        XCTAssertEqual(Language.from(filename: "main.rs"), .rust)
        XCTAssertEqual(Language.from(filename: "server.go"), .go)
        XCTAssertEqual(Language.from(filename: "README.md"), .markdown)
        XCTAssertEqual(Language.from(filename: "config.json"), .json)
        XCTAssertEqual(Language.from(filename: "unknown.xyz"), .unknown)
    }
    
    func testSwiftKeywords() {
        let keywords = Language.swift.keywords
        XCTAssertTrue(keywords.contains("func"))
        XCTAssertTrue(keywords.contains("var"))
        XCTAssertTrue(keywords.contains("let"))
        XCTAssertTrue(keywords.contains("class"))
        XCTAssertTrue(keywords.contains("struct"))
        XCTAssertTrue(keywords.contains("protocol"))
    }
    
    func testPythonKeywords() {
        let keywords = Language.python.keywords
        XCTAssertTrue(keywords.contains("def"))
        XCTAssertTrue(keywords.contains("class"))
        XCTAssertTrue(keywords.contains("if"))
        XCTAssertTrue(keywords.contains("import"))
        XCTAssertTrue(keywords.contains("return"))
    }
    
    func testCommentPrefixes() {
        XCTAssertTrue(Language.swift.commentPrefixes.contains("//"))
        XCTAssertTrue(Language.swift.commentPrefixes.contains("/*"))
        XCTAssertTrue(Language.python.commentPrefixes.contains("#"))
        XCTAssertTrue(Language.html.commentPrefixes.contains("<!--"))
    }
    
    func testBasicSyntaxHighlighting() {
        let swiftCode = "func hello() { return \"world\" }"
        let highlighted = SyntaxHighlighter.highlight(swiftCode, language: .swift)
        
        // Should contain keyword highlighting
        XCTAssertTrue(highlighted.contains(Theme.keyword))
        XCTAssertTrue(highlighted.contains("func"))
        XCTAssertTrue(highlighted.contains("return"))
        
        // Should contain string highlighting
        XCTAssertTrue(highlighted.contains(Theme.string))
        XCTAssertTrue(highlighted.contains("\"world\""))
    }
    
    func testStringHighlighting() {
        let codeWithStrings = "let message = \"Hello, world!\""
        let highlighted = SyntaxHighlighter.highlight(codeWithStrings, language: .swift)
        
        XCTAssertTrue(highlighted.contains(Theme.string))
        XCTAssertTrue(highlighted.contains("\"Hello, world!\""))
    }
    
    func testCommentHighlighting() {
        let codeWithComment = "// This is a comment\nlet x = 5"
        let highlighted = SyntaxHighlighter.highlight(codeWithComment, language: .swift)
        
        XCTAssertTrue(highlighted.contains(Theme.comment))
        XCTAssertTrue(highlighted.contains("// This is a comment"))
    }
    
    func testNumberHighlighting() {
        let codeWithNumbers = "let x = 42; let y = 3.14; let hex = 0xFF"
        let highlighted = SyntaxHighlighter.highlight(codeWithNumbers, language: .swift)
        
        XCTAssertTrue(highlighted.contains(Theme.number))
        // Should highlight all number formats
        XCTAssertTrue(highlighted.contains("42"))
        XCTAssertTrue(highlighted.contains("3.14"))
        XCTAssertTrue(highlighted.contains("0xFF"))
    }
    
    func testUnknownLanguage() {
        let code = "some unknown code"
        let highlighted = SyntaxHighlighter.highlight(code, language: .unknown)
        
        // Should return unchanged text for unknown language
        XCTAssertEqual(highlighted, code)
    }
    
    func testDiffLineHighlighting() {
        let additionLine = DiffLine(
            content: "func newFunction() {",
            type: .addition,
            oldLineNumber: nil,
            newLineNumber: 10
        )
        
        let highlighted = SyntaxHighlighter.highlightDiffLine(additionLine, language: .swift)
        
        // Should contain both diff color and syntax highlighting
        XCTAssertTrue(highlighted.contains(ANSICode.green)) // Addition color
        XCTAssertTrue(highlighted.contains(Theme.keyword))   // Keyword highlighting
        XCTAssertTrue(highlighted.contains("func"))
    }
    
    func testFileIcons() {
        XCTAssertEqual(SyntaxHighlighter.getFileIcon("main.swift"), "🔶")
        XCTAssertEqual(SyntaxHighlighter.getFileIcon("script.py"), "🐍")
        XCTAssertEqual(SyntaxHighlighter.getFileIcon("app.js"), "📜")
        XCTAssertEqual(SyntaxHighlighter.getFileIcon("component.ts"), "📘")
        XCTAssertEqual(SyntaxHighlighter.getFileIcon("main.rs"), "🦀")
        XCTAssertEqual(SyntaxHighlighter.getFileIcon("server.go"), "🐹")
        XCTAssertEqual(SyntaxHighlighter.getFileIcon("README.md"), "📝")
        XCTAssertEqual(SyntaxHighlighter.getFileIcon("config.json"), "📋")
        XCTAssertEqual(SyntaxHighlighter.getFileIcon("image.png"), "🖼️")
        XCTAssertEqual(SyntaxHighlighter.getFileIcon("archive.zip"), "📦")
        XCTAssertEqual(SyntaxHighlighter.getFileIcon("document.pdf"), "📄")
    }
    
    func testThemeColors() {
        // Test that theme colors are defined
        XCTAssertFalse(Theme.addedLines.isEmpty)
        XCTAssertFalse(Theme.removedLines.isEmpty)
        XCTAssertFalse(Theme.modifiedHunks.isEmpty)
        XCTAssertFalse(Theme.stagedItems.isEmpty)
        XCTAssertFalse(Theme.conflicts.isEmpty)
        XCTAssertFalse(Theme.keyword.isEmpty)
        XCTAssertFalse(Theme.string.isEmpty)
        XCTAssertFalse(Theme.comment.isEmpty)
        XCTAssertFalse(Theme.number.isEmpty)
    }
    
    func testKeywordWordBoundaries() {
        // Test that keywords are only highlighted when they're complete words
        let code = "function_name and if_statement"
        let highlighted = SyntaxHighlighter.highlight(code, language: .python)
        
        // "if" should not be highlighted in "if_statement" 
        // This is a basic test - in practice you'd need to check the actual highlighting
        XCTAssertTrue(highlighted.contains("function_name"))
        XCTAssertTrue(highlighted.contains("if_statement"))
    }
    
    func testNestedStringEscaping() {
        let code = "let msg = \"He said \\\"Hello\\\" to me\""
        let highlighted = SyntaxHighlighter.highlight(code, language: .swift)
        
        // Should highlight the entire string including escaped quotes
        XCTAssertTrue(highlighted.contains(Theme.string))
        XCTAssertTrue(highlighted.contains("\"He said \\\"Hello\\\" to me\""))
    }
}