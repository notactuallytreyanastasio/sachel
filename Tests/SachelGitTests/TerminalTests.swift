import XCTest
@testable import SachelGit

final class TerminalTests: XCTestCase {
    
    func testKeyFromByte() {
        XCTAssertEqual(Key.from(byte: 0x0D), .enter)
        XCTAssertEqual(Key.from(byte: 0x1B), .escape)
        XCTAssertEqual(Key.from(byte: 0x09), .tab)
        XCTAssertEqual(Key.from(byte: 0x20), .space)
        XCTAssertEqual(Key.from(byte: 0x7F), .backspace)
        XCTAssertEqual(Key.from(byte: 65), .char("A"))  // ASCII 'A'
        XCTAssertEqual(Key.from(byte: 97), .char("a"))  // ASCII 'a'
    }
    
    func testKeyFromEscapeSequence() {
        XCTAssertEqual(Key.from(escapeSequence: [0x1B, 0x5B, 0x41]), .up)
        XCTAssertEqual(Key.from(escapeSequence: [0x1B, 0x5B, 0x42]), .down)
        XCTAssertEqual(Key.from(escapeSequence: [0x1B, 0x5B, 0x43]), .right)
        XCTAssertEqual(Key.from(escapeSequence: [0x1B, 0x5B, 0x44]), .left)
        XCTAssertNil(Key.from(escapeSequence: [0x1B, 0x5B, 0x99]))
    }
    
    func testCtrlKeys() {
        XCTAssertEqual(Key.from(byte: 0x01), .ctrl("a"))  // Ctrl+A
        XCTAssertEqual(Key.from(byte: 0x03), .ctrl("c"))  // Ctrl+C
        XCTAssertEqual(Key.from(byte: 0x1A), .ctrl("z"))  // Ctrl+Z
    }
    
    func testKeyCharProperty() {
        XCTAssertEqual(Key.char("A").char, "A")
        XCTAssertEqual(Key.space.char, " ")
        XCTAssertEqual(Key.enter.char, "\n")
        XCTAssertEqual(Key.tab.char, "\t")
        XCTAssertEqual(Key.up.char, "")
    }
    
    func testANSICodeGeneration() {
        XCTAssertEqual(ANSICode.moveCursor(row: 10, col: 5), "\u{1B}[10;5H")
        XCTAssertEqual(ANSICode.clearScreen, "\u{1B}[2J")
        XCTAssertEqual(ANSICode.reset, "\u{1B}[0m")
    }
    
    func testTerminalSize() {
        let terminal = Terminal()
        let size = terminal.size
        
        // Terminal size should be positive
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }
}