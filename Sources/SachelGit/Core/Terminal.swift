import Foundation

#if os(macOS) || os(Linux)
import Darwin
#endif

enum Key: Equatable {
    case char(Character)
    case up, down, left, right
    case enter, escape, tab, space
    case ctrl(Character)
    case backspace, delete
    
    var char: String {
        switch self {
        case .char(let c): return String(c)
        case .space: return " "
        case .enter: return "\n"
        case .tab: return "\t"
        default: return ""
        }
    }
    
    static func from(byte: UInt8) -> Key? {
        switch byte {
        case 0x0D: return .enter
        case 0x1B: return .escape
        case 0x09: return .tab
        case 0x20: return .space
        case 0x7F: return .backspace
        case 0x01...0x1A: 
            let scalar = UnicodeScalar(byte + 0x60)
            let char = Character(scalar)
            return .ctrl(char)
        default:
            let scalar = UnicodeScalar(byte)
            return .char(Character(scalar))
        }
        return nil
    }
    
    static func from(escapeSequence: [UInt8]) -> Key? {
        if escapeSequence.count >= 3 && escapeSequence[0] == 0x1B && escapeSequence[1] == 0x5B {
            switch escapeSequence[2] {
            case 0x41: return .up      // ESC[A
            case 0x42: return .down    // ESC[B
            case 0x43: return .right   // ESC[C
            case 0x44: return .left    // ESC[D
            default: return nil
            }
        }
        return nil
    }
}

enum ANSICode {
    static let clearScreen = "\u{1B}[2J"
    static let clearLine = "\u{1B}[K"
    static let home = "\u{1B}[H"
    static let hideCursor = "\u{1B}[?25l"
    static let showCursor = "\u{1B}[?25h"
    static let reset = "\u{1B}[0m"
    
    // Colors
    static let red = "\u{1B}[31m"
    static let green = "\u{1B}[32m"
    static let yellow = "\u{1B}[33m"
    static let blue = "\u{1B}[34m"
    static let magenta = "\u{1B}[35m"
    static let cyan = "\u{1B}[36m"
    static let white = "\u{1B}[37m"
    
    // Bright colors
    static let brightRed = "\u{1B}[91m"
    static let brightGreen = "\u{1B}[92m"
    static let brightYellow = "\u{1B}[93m"
    static let brightBlue = "\u{1B}[94m"
    static let brightCyan = "\u{1B}[96m"
    
    // Background colors
    static let bgRed = "\u{1B}[41m"
    static let bgGreen = "\u{1B}[42m"
    static let bgYellow = "\u{1B}[43m"
    static let bgBlue = "\u{1B}[44m"
    
    static func moveCursor(row: Int, col: Int) -> String {
        return "\u{1B}[\(row);\(col)H"
    }
}

struct TerminalSize {
    let width: Int
    let height: Int
}

class Terminal {
    private var originalTermios: termios?
    private var isRawMode = false
    
    var size: TerminalSize {
        var w = winsize()
        _ = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
        return TerminalSize(width: Int(w.ws_col), height: Int(w.ws_row))
    }
    
    init() {
        setupSignalHandlers()
    }
    
    deinit {
        cleanup()
    }
    
    func enableRawMode() throws {
        guard !isRawMode else { return }
        
        var raw = termios()
        if tcgetattr(STDIN_FILENO, &raw) != 0 {
            throw TerminalError.failedToGetTerminalAttributes
        }
        
        originalTermios = raw
        
        // Disable canonical mode and echo
        raw.c_lflag &= ~(UInt(ECHO | ICANON | ISIG))
        raw.c_iflag &= ~(UInt(IXON | ICRNL))
        raw.c_oflag &= ~(UInt(OPOST))
        
        // Set minimum characters for read and timeout
        raw.c_cc.16 = 0  // VMIN
        raw.c_cc.17 = 1  // VTIME (1/10 of a second)
        
        if tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) != 0 {
            throw TerminalError.failedToSetTerminalAttributes
        }
        
        isRawMode = true
        print(ANSICode.hideCursor, terminator: "")
        fflush(stdout)
    }
    
    func disableRawMode() {
        guard isRawMode, var original = originalTermios else { return }
        
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
        isRawMode = false
        print(ANSICode.showCursor, terminator: "")
        fflush(stdout)
    }
    
    func readKey() -> Key? {
        var buffer = [UInt8](repeating: 0, count: 3)
        let bytesRead = read(STDIN_FILENO, &buffer, 3)
        
        if bytesRead == 1 {
            return Key.from(byte: buffer[0])
        } else if bytesRead == 3 {
            return Key.from(escapeSequence: buffer)
        }
        return nil
    }
    
    func write(_ text: String) {
        print(text, terminator: "")
        fflush(stdout)
    }
    
    func writeLine(_ text: String) {
        print(text)
        fflush(stdout)
    }
    
    func moveCursor(row: Int, col: Int) {
        write(ANSICode.moveCursor(row: row, col: col))
    }
    
    func clearScreen() {
        write(ANSICode.clearScreen + ANSICode.home)
    }
    
    func clearLine() {
        write(ANSICode.clearLine)
    }
    
    func cleanup() {
        disableRawMode()
        clearScreen()
        write(ANSICode.showCursor)
    }
    
    private func setupSignalHandlers() {
        signal(SIGINT) { _ in
            // Handle Ctrl+C gracefully
            exit(0)
        }
        
        signal(SIGTERM) { _ in
            exit(0)
        }
        
        atexit {
            // Ensure cleanup happens on exit
            let terminal = Terminal()
            terminal.cleanup()
        }
    }
}

enum TerminalError: Error {
    case failedToGetTerminalAttributes
    case failedToSetTerminalAttributes
    case invalidTerminalSize
}