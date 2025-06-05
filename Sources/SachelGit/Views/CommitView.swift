import Foundation

enum CommitMode {
    case normal
    case insert
}

class CommitView: BaseView {
    private let repository: GitRepository
    private var commitMessage = ""
    private var mode: CommitMode = .normal
    private var cursorPosition = 0
    private var isCommitting = false
    private var errorMessage = ""
    private var successMessage = ""
    private var stagedFiles: [FileStatus] = []
    private var messageHistory: [String] = []
    private var historyIndex = -1
    
    init(repository: GitRepository) {
        self.repository = repository
        super.init(title: "Commit")
        loadStagedFiles()
        loadMessageHistory()
    }
    
    override func render(terminal: Terminal) {
        terminal.clearScreen()
        
        let modeText = mode == .insert ? "INSERT" : "NORMAL"
        renderHeader(terminal: terminal, subtitle: "Mode: \(modeText)")
        
        if isCommitting {
            renderCommitting(terminal: terminal)
            return
        }
        
        if !errorMessage.isEmpty {
            renderError(terminal: terminal)
            return
        }
        
        if !successMessage.isEmpty {
            renderSuccess(terminal: terminal)
            return
        }
        
        renderCommitInterface(terminal: terminal)
        renderFooter(terminal: terminal, helpText: getHelpText())
    }
    
    override func handleKey(_ key: Key) {
        if isCommitting {
            return
        }
        
        switch mode {
        case .normal:
            handleNormalModeKey(key)
        case .insert:
            handleInsertModeKey(key)
        }
    }
    
    private func handleNormalModeKey(_ key: Key) {
        switch key {
        case .char("i"):
            enterInsertMode()
        case .ctrl("c"):
            if !commitMessage.isEmpty {
                performCommit()
            }
        case .ctrl("a"):
            amendLastCommit()
        case .char("r"):
            loadStagedFiles()
        case .up:
            navigateMessageHistory(direction: -1)
        case .down:
            navigateMessageHistory(direction: 1)
        default:
            break
        }
    }
    
    private func handleInsertModeKey(_ key: Key) {
        switch key {
        case .escape:
            exitInsertMode()
        case .enter:
            insertCharacter("\n")
        case .backspace:
            deleteCharacter()
        case .left:
            moveCursorLeft()
        case .right:
            moveCursorRight()
        case .up:
            moveCursorUp()
        case .down:
            moveCursorDown()
        case .char(let char):
            insertCharacter(String(char))
        case .ctrl("c"):
            // Allow Ctrl+C to commit even in insert mode
            if !commitMessage.isEmpty {
                exitInsertMode()
                performCommit()
            }
        default:
            break
        }
    }
    
    private func renderCommitting(terminal: Terminal) {
        let size = terminal.size
        let message = "Creating commit..."
        
        terminal.moveCursor(row: size.height / 2, col: 1)
        terminal.write(centerText(message, width: size.width))
    }
    
    private func renderError(terminal: Terminal) {
        let size = terminal.size
        
        terminal.moveCursor(row: size.height / 2, col: 1)
        terminal.write(ANSICode.red + centerText("Error: \(errorMessage)", width: size.width) + ANSICode.reset)
    }
    
    private func renderSuccess(terminal: Terminal) {
        let size = terminal.size
        
        terminal.moveCursor(row: size.height / 2, col: 1)
        terminal.write(ANSICode.green + centerText(successMessage, width: size.width) + ANSICode.reset)
    }
    
    private func renderCommitInterface(terminal: Terminal) {
        let size = terminal.size
        let startRow = 4
        
        // Show staged files summary
        terminal.moveCursor(row: startRow, col: 1)
        terminal.write(ANSICode.green + "Staged Files (\(stagedFiles.count)):" + ANSICode.reset)
        
        let maxFilesToShow = min(5, stagedFiles.count)
        for i in 0..<maxFilesToShow {
            terminal.moveCursor(row: startRow + 1 + i, col: 2)
            let file = stagedFiles[i]
            terminal.write("\(file.statusColor)\(file.statusIndicator)\(ANSICode.reset) \(file.path)")
        }
        
        if stagedFiles.count > maxFilesToShow {
            terminal.moveCursor(row: startRow + 1 + maxFilesToShow, col: 2)
            terminal.write(ANSICode.yellow + "... and \(stagedFiles.count - maxFilesToShow) more" + ANSICode.reset)
        }
        
        let messageStartRow = startRow + min(6, stagedFiles.count + 2) + 1
        
        // Commit message area
        terminal.moveCursor(row: messageStartRow, col: 1)
        terminal.write(ANSICode.brightBlue + "Commit Message:" + ANSICode.reset)
        
        terminal.moveCursor(row: messageStartRow + 1, col: 1)
        terminal.write(String(repeating: "─", count: size.width))
        
        // Render commit message with word wrapping
        renderCommitMessage(terminal: terminal, startRow: messageStartRow + 2, maxRows: size.height - messageStartRow - 8)
        
        // Show cursor in insert mode
        if mode == .insert {
            let (cursorRow, cursorCol) = calculateCursorPosition(startRow: messageStartRow + 2, width: size.width)
            terminal.moveCursor(row: cursorRow, col: cursorCol)
            terminal.write(ANSICode.showCursor)
        } else {
            terminal.write(ANSICode.hideCursor)
        }
    }
    
    private func renderCommitMessage(terminal: Terminal, startRow: Int, maxRows: Int) {
        let size = terminal.size
        let lines = wrapText(commitMessage, width: size.width - 2)
        
        for (index, line) in lines.prefix(maxRows).enumerated() {
            terminal.moveCursor(row: startRow + index, col: 1)
            terminal.write(line)
            terminal.clearLine()
        }
        
        // Clear any remaining lines
        for i in lines.count..<maxRows {
            terminal.moveCursor(row: startRow + i, col: 1)
            terminal.clearLine()
        }
    }
    
    private func wrapText(_ text: String, width: Int) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var wrappedLines: [String] = []
        
        for line in lines {
            if line.count <= width {
                wrappedLines.append(line)
            } else {
                // Simple word wrapping
                var currentLine = ""
                let words = line.components(separatedBy: .whitespaces)
                
                for word in words {
                    if currentLine.isEmpty {
                        currentLine = word
                    } else if (currentLine + " " + word).count <= width {
                        currentLine += " " + word
                    } else {
                        wrappedLines.append(currentLine)
                        currentLine = word
                    }
                }
                
                if !currentLine.isEmpty {
                    wrappedLines.append(currentLine)
                }
            }
        }
        
        return wrappedLines
    }
    
    private func calculateCursorPosition(startRow: Int, width: Int) -> (row: Int, col: Int) {
        let textUpToCursor = String(commitMessage.prefix(cursorPosition))
        let lines = wrapText(textUpToCursor, width: width - 2)
        
        if lines.isEmpty {
            return (startRow, 1)
        }
        
        let row = startRow + lines.count - 1
        let col = lines.last?.count ?? 0
        
        return (row, col + 1)
    }
    
    private func enterInsertMode() {
        mode = .insert
        cursorPosition = commitMessage.count
    }
    
    private func exitInsertMode() {
        mode = .normal
    }
    
    private func insertCharacter(_ char: String) {
        let index = commitMessage.index(commitMessage.startIndex, offsetBy: cursorPosition)
        commitMessage.insert(contentsOf: char, at: index)
        cursorPosition += char.count
    }
    
    private func deleteCharacter() {
        guard cursorPosition > 0 else { return }
        
        let index = commitMessage.index(commitMessage.startIndex, offsetBy: cursorPosition - 1)
        commitMessage.remove(at: index)
        cursorPosition -= 1
    }
    
    private func moveCursorLeft() {
        cursorPosition = max(0, cursorPosition - 1)
    }
    
    private func moveCursorRight() {
        cursorPosition = min(commitMessage.count, cursorPosition + 1)
    }
    
    private func moveCursorUp() {
        // Simple implementation - move to beginning of previous line
        let _ = commitMessage.components(separatedBy: .newlines)
        // Find current line and move up - simplified for now
        cursorPosition = max(0, cursorPosition - 40) // Approximate line length
    }
    
    private func moveCursorDown() {
        // Simple implementation - move to beginning of next line
        cursorPosition = min(commitMessage.count, cursorPosition + 40) // Approximate line length
    }
    
    private func performCommit(amend: Bool = false) {
        guard !commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Commit message cannot be empty"
            return
        }
        
        isCommitting = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let commitHash = try self.repository.commit(message: self.commitMessage, amend: amend)
                
                DispatchQueue.main.async {
                    self.isCommitting = false
                    self.successMessage = amend ? 
                        "Amended commit \(String(commitHash.prefix(7)))" : 
                        "Created commit \(String(commitHash.prefix(7)))"
                    
                    self.saveMessageToHistory()
                    
                    // Clear the commit message after successful commit
                    self.commitMessage = ""
                    self.cursorPosition = 0
                    self.mode = .normal
                    
                    // Auto-clear success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.successMessage = ""
                        self.loadStagedFiles() // Refresh staged files
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isCommitting = false
                    self.errorMessage = error.localizedDescription
                    
                    // Auto-clear error message after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.errorMessage = ""
                    }
                }
            }
        }
    }
    
    private func amendLastCommit() {
        performCommit(amend: true)
    }
    
    private func loadStagedFiles() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let allFiles = try self?.repository.status() ?? []
                let staged = allFiles.filter { $0.staged }
                
                DispatchQueue.main.async {
                    self?.stagedFiles = staged
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to load staged files: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadMessageHistory() {
        // In a real implementation, this would load from Git commit history
        // or a local cache file
        messageHistory = [
            "feat: add new feature",
            "fix: resolve bug in authentication",
            "docs: update README with installation instructions",
            "refactor: improve code structure"
        ]
    }
    
    private func saveMessageToHistory() {
        let trimmedMessage = commitMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedMessage.isEmpty && !messageHistory.contains(trimmedMessage) {
            messageHistory.insert(trimmedMessage, at: 0)
            // Keep only last 20 messages
            if messageHistory.count > 20 {
                messageHistory = Array(messageHistory.prefix(20))
            }
        }
    }
    
    private func navigateMessageHistory(direction: Int) {
        guard !messageHistory.isEmpty else { return }
        
        if historyIndex == -1 && direction == -1 {
            // Start navigating history
            historyIndex = 0
            commitMessage = messageHistory[0]
        } else if historyIndex >= 0 {
            let newIndex = historyIndex + direction
            if newIndex >= 0 && newIndex < messageHistory.count {
                historyIndex = newIndex
                commitMessage = messageHistory[historyIndex]
            } else if newIndex < 0 {
                // Back to current message
                historyIndex = -1
                commitMessage = ""
            }
        }
        
        cursorPosition = commitMessage.count
    }
    
    private func getHelpText() -> String {
        switch mode {
        case .normal:
            return "i: insert mode | Ctrl+C: commit | Ctrl+A: amend | ↑↓: history | r: refresh | Space: leader"
        case .insert:
            return "Esc: normal mode | Ctrl+C: commit | Type to edit message"
        }
    }
}