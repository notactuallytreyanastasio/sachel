import Foundation

struct DiffLine: Equatable {
    enum LineType {
        case context
        case addition
        case deletion
    }
    
    let content: String
    let type: LineType
    let oldLineNumber: Int?
    let newLineNumber: Int?
    
    var displayContent: String {
        let prefix = switch type {
        case .context: " "
        case .addition: "+"
        case .deletion: "-"
        }
        return prefix + content
    }
    
    var color: String {
        switch type {
        case .context: return Theme.foreground
        case .addition: return Theme.addedLines
        case .deletion: return Theme.removedLines
        }
    }
}

struct Hunk: Equatable {
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let lines: [DiffLine]
    let header: String
    
    init(oldStart: Int, oldCount: Int, newStart: Int, newCount: Int, lines: [DiffLine], header: String = "") {
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.lines = lines
        self.header = header
    }
    
    var headerLine: String {
        if !header.isEmpty {
            return header
        }
        return "@@ -\(oldStart),\(oldCount) +\(newStart),\(newCount) @@"
    }
    
    func toPatch(filename: String) -> String {
        var patch = "diff --git a/\(filename) b/\(filename)\n"
        patch += "--- a/\(filename)\n"
        patch += "+++ b/\(filename)\n"
        patch += "\(headerLine)\n"
        
        for line in lines {
            patch += line.displayContent
            if !line.content.hasSuffix("\n") {
                patch += "\n"
            }
        }
        
        return patch
    }
    
    func withSelectedLines(_ selectedLines: Set<Int>) -> Hunk {
        var newLines: [DiffLine] = []
        var newOldCount = 0
        var newNewCount = 0
        
        for (index, line) in lines.enumerated() {
            let shouldInclude = selectedLines.contains(index) || line.type == .context
            
            if shouldInclude {
                newLines.append(line)
                
                switch line.type {
                case .context:
                    newOldCount += 1
                    newNewCount += 1
                case .deletion:
                    newOldCount += 1
                case .addition:
                    newNewCount += 1
                }
            }
        }
        
        return Hunk(
            oldStart: oldStart,
            oldCount: newOldCount,
            newStart: newStart,
            newCount: newNewCount,
            lines: newLines,
            header: header
        )
    }
    
    var additionCount: Int {
        return lines.filter { $0.type == .addition }.count
    }
    
    var deletionCount: Int {
        return lines.filter { $0.type == .deletion }.count
    }
    
    var contextCount: Int {
        return lines.filter { $0.type == .context }.count
    }
}