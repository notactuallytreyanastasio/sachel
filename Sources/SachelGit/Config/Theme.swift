import Foundation

struct Theme {
    // Dracula-inspired color scheme as specified in OPUS_INSTRUCTIONS.md
    
    // Primary colors
    static let background = "" // Dark background (default terminal)
    static let foreground = ANSICode.white   // Light foreground
    
    // Git status colors
    static let addedLines = ANSICode.brightGreen    // #50FA7B equivalent
    static let removedLines = ANSICode.brightRed    // #FF5555 equivalent  
    static let modifiedHunks = ANSICode.brightYellow // #F1FA8C equivalent
    static let stagedItems = ANSICode.brightCyan    // #8BE9FD equivalent
    static let conflicts = ANSICode.yellow          // #FFB86C equivalent (closest to orange)
    
    // UI element colors
    static let header = ANSICode.brightBlue
    static let selected = ANSICode.bgBlue
    static let border = ANSICode.cyan
    static let help = ANSICode.cyan
    static let error = ANSICode.brightRed
    static let success = ANSICode.brightGreen
    static let warning = ANSICode.brightYellow
    static let info = ANSICode.brightCyan
    
    // Syntax highlighting colors (for future use)
    static let keyword = ANSICode.magenta
    static let string = ANSICode.green
    static let comment = ANSICode.blue
    static let number = ANSICode.cyan
    static let `operator` = ANSICode.yellow
    static let type = ANSICode.brightBlue
    
    // File type colors
    static let executable = ANSICode.brightGreen
    static let directory = ANSICode.brightBlue
    static let symlink = ANSICode.cyan
    static let archive = ANSICode.red
    static let image = ANSICode.magenta
    static let document = ANSICode.yellow
}

enum Language: String, CaseIterable {
    case swift = "swift"
    case python = "py"
    case javascript = "js"
    case typescript = "ts"
    case rust = "rs"
    case go = "go"
    case c = "c"
    case cpp = "cpp"
    case java = "java"
    case kotlin = "kt"
    case shell = "sh"
    case markdown = "md"
    case json = "json"
    case yaml = "yml"
    case xml = "xml"
    case html = "html"
    case css = "css"
    case unknown = ""
    
    static func from(fileExtension: String) -> Language {
        let ext = fileExtension.lowercased()
        return Language.allCases.first { $0.rawValue == ext } ?? .unknown
    }
    
    static func from(filename: String) -> Language {
        let ext = URL(fileURLWithPath: filename).pathExtension
        return from(fileExtension: ext)
    }
    
    var keywords: [String] {
        switch self {
        case .swift:
            return ["func", "var", "let", "class", "struct", "enum", "protocol", "extension", 
                    "if", "else", "switch", "case", "for", "while", "return", "import", "public", "private"]
        case .python:
            return ["def", "class", "if", "else", "elif", "for", "while", "return", "import", 
                    "from", "try", "except", "with", "as", "pass", "break", "continue"]
        case .javascript, .typescript:
            return ["function", "var", "let", "const", "class", "if", "else", "for", "while", 
                    "return", "import", "export", "async", "await", "try", "catch"]
        case .rust:
            return ["fn", "let", "mut", "struct", "enum", "impl", "trait", "if", "else", 
                    "match", "for", "while", "return", "use", "pub", "mod"]
        case .go:
            return ["func", "var", "const", "type", "struct", "interface", "if", "else", 
                    "for", "switch", "case", "return", "package", "import"]
        default:
            return []
        }
    }
    
    var commentPrefixes: [String] {
        switch self {
        case .swift, .javascript, .typescript, .rust, .go, .c, .cpp, .java, .kotlin:
            return ["//", "/*"]
        case .python, .shell:
            return ["#"]
        case .html, .xml:
            return ["<!--"]
        default:
            return []
        }
    }
}