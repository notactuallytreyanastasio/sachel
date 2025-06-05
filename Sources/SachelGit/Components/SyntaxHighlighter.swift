import Foundation

struct SyntaxHighlighter {
    static func highlight(_ text: String, language: Language) -> String {
        guard language != .unknown else {
            return text
        }
        
        var highlightedText = text
        
        // Highlight keywords
        highlightedText = highlightKeywords(highlightedText, language: language)
        
        // Highlight strings
        highlightedText = highlightStrings(highlightedText, language: language)
        
        // Highlight comments
        highlightedText = highlightComments(highlightedText, language: language)
        
        // Highlight numbers
        highlightedText = highlightNumbers(highlightedText)
        
        return highlightedText
    }
    
    static func highlightDiffLine(_ line: DiffLine, language: Language) -> String {
        let baseColor = line.color
        let content = line.content
        
        // For diff lines, we want to maintain the base color but add syntax highlighting
        let highlighted = highlight(content, language: language)
        
        // Apply the diff color as base and reset at the end
        return baseColor + highlighted + ANSICode.reset
    }
    
    private static func highlightKeywords(_ text: String, language: Language) -> String {
        var result = text
        
        for keyword in language.keywords {
            // Use word boundaries to avoid highlighting partial matches
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
            
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(location: 0, length: result.count)
                
                result = regex.stringByReplacingMatches(
                    in: result,
                    options: [],
                    range: range,
                    withTemplate: "\(Theme.keyword)$0\(ANSICode.reset)"
                )
            } catch {
                // If regex fails, continue without highlighting this keyword
                continue
            }
        }
        
        return result
    }
    
    private static func highlightStrings(_ text: String, language: Language) -> String {
        var result = text
        
        // Highlight double-quoted strings
        result = highlightPattern(
            result,
            pattern: "\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"",
            color: Theme.string
        )
        
        // Highlight single-quoted strings (for languages that support them)
        if language != .json {
            result = highlightPattern(
                result,
                pattern: "'[^'\\\\]*(?:\\\\.[^'\\\\]*)*'",
                color: Theme.string
            )
        }
        
        // Highlight template literals for JavaScript/TypeScript
        if language == .javascript || language == .typescript {
            result = highlightPattern(
                result,
                pattern: "`[^`\\\\]*(?:\\\\.[^`\\\\]*)*`",
                color: Theme.string
            )
        }
        
        return result
    }
    
    private static func highlightComments(_ text: String, language: Language) -> String {
        var result = text
        
        for prefix in language.commentPrefixes {
            if prefix == "//" || prefix == "#" {
                // Line comments - highlight from prefix to end of line
                let pattern = "\(NSRegularExpression.escapedPattern(for: prefix)).*$"
                result = highlightPattern(result, pattern: pattern, color: Theme.comment)
            } else if prefix == "/*" {
                // Block comments
                result = highlightPattern(
                    result,
                    pattern: "/\\*[\\s\\S]*?\\*/",
                    color: Theme.comment
                )
            } else if prefix == "<!--" {
                // HTML/XML comments
                result = highlightPattern(
                    result,
                    pattern: "<!--[\\s\\S]*?-->",
                    color: Theme.comment
                )
            }
        }
        
        return result
    }
    
    private static func highlightNumbers(_ text: String) -> String {
        // Highlight integers and floating-point numbers
        let patterns = [
            "\\b\\d+\\.\\d+\\b",  // Floating point
            "\\b\\d+\\b",         // Integers
            "\\b0x[0-9a-fA-F]+\\b", // Hexadecimal
            "\\b0b[01]+\\b",      // Binary
            "\\b0o[0-7]+\\b"      // Octal
        ]
        
        var result = text
        
        for pattern in patterns {
            result = highlightPattern(result, pattern: pattern, color: Theme.number)
        }
        
        return result
    }
    
    private static func highlightPattern(_ text: String, pattern: String, color: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
            let range = NSRange(location: 0, length: text.count)
            
            return regex.stringByReplacingMatches(
                in: text,
                options: [],
                range: range,
                withTemplate: "\(color)$0\(ANSICode.reset)"
            )
        } catch {
            return text
        }
    }
    
    static func getFileIcon(_ filename: String) -> String {
        let language = Language.from(filename: filename)
        let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
        
        switch language {
        case .swift:
            return "🔶"
        case .python:
            return "🐍"
        case .javascript:
            return "📜"
        case .typescript:
            return "📘"
        case .rust:
            return "🦀"
        case .go:
            return "🐹"
        case .java:
            return "☕"
        case .c, .cpp:
            return "🔧"
        case .html:
            return "🌐"
        case .css:
            return "🎨"
        case .markdown:
            return "📝"
        case .json:
            return "📋"
        case .yaml:
            return "⚙️"
        case .shell:
            return "🐚"
        default:
            // Generic file type icons
            if ["jpg", "jpeg", "png", "gif", "bmp", "svg"].contains(ext) {
                return "🖼️"
            } else if ["mp3", "wav", "flac", "aac"].contains(ext) {
                return "🎵"
            } else if ["mp4", "avi", "mov", "mkv"].contains(ext) {
                return "🎥"
            } else if ["zip", "tar", "gz", "7z", "rar"].contains(ext) {
                return "📦"
            } else if ["pdf", "doc", "docx", "txt"].contains(ext) {
                return "📄"
            } else {
                return "📁"
            }
        }
    }
}