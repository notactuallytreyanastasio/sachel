import Foundation

enum DiffViewMode {
    case unstaged
    case staged
}

class DiffView: BaseView {
    private let repository: GitRepository
    private var fileDiffs: [FileDiff] = []
    private var currentFileIndex = 0
    private var currentHunkIndex = 0
    private var mode: DiffViewMode = .unstaged
    private var isLoading = false
    private var errorMessage = ""
    private var selectedLines: Set<Int> = []
    private var isLineSelectionMode = false
    private var lineSelectionStart = 0
    
    init(repository: GitRepository, file: String? = nil) {
        self.repository = repository
        super.init(title: "Git Diff")
        refresh(file: file)
    }
    
    override func render(terminal: Terminal) {
        terminal.clearScreen()
        
        let modeText = mode == .staged ? "Staged" : "Unstaged"
        renderHeader(terminal: terminal, subtitle: "\(modeText) Changes")
        
        if isLoading {
            renderLoading(terminal: terminal)
            return
        }
        
        if !errorMessage.isEmpty {
            renderError(terminal: terminal)
            return
        }
        
        if fileDiffs.isEmpty {
            renderNoChanges(terminal: terminal)
            return
        }
        
        renderDiff(terminal: terminal)
        
        let helpText = isLineSelectionMode ? 
            "j/k: extend selection | s: stage lines | u: unstage lines | Esc: exit selection" :
            "j/k: hunks | J/K: files | s: stage | u: unstage | v: line select | Tab: toggle mode | Space: leader"
        
        renderFooter(terminal: terminal, helpText: helpText)
    }
    
    override func handleKey(_ key: Key) {
        if isLineSelectionMode {
            handleLineSelectionKey(key)
            return
        }
        
        switch key {
        case .char("j"):
            navigateToNextHunk()
        case .char("k"):
            navigateToPreviousHunk()
        case .char("J"):
            navigateToNextFile()
        case .char("K"):
            navigateToPreviousFile()
        case .char("s"):
            stageCurrentHunk()
        case .char("S"):
            stageAllHunksInFile()
        case .char("u"):
            unstageCurrentHunk()
        case .char("U"):
            unstageAllHunksInFile()
        case .char("v"):
            enterLineSelectionMode()
        case .tab:
            toggleMode()
        case .char("r"):
            refresh()
        default:
            break
        }
    }
    
    private func renderLoading(terminal: Terminal) {
        let size = terminal.size
        let message = "Loading diff..."
        
        terminal.moveCursor(row: size.height / 2, col: 1)
        terminal.write(centerText(message, width: size.width))
    }
    
    private func renderError(terminal: Terminal) {
        let size = terminal.size
        
        terminal.moveCursor(row: size.height / 2, col: 1)
        terminal.write(ANSICode.red + centerText("Error: \(errorMessage)", width: size.width) + ANSICode.reset)
    }
    
    private func renderNoChanges(terminal: Terminal) {
        let size = terminal.size
        let message = mode == .staged ? "No staged changes" : "No unstaged changes"
        
        terminal.moveCursor(row: size.height / 2, col: 1)
        terminal.write(ANSICode.green + centerText(message, width: size.width) + ANSICode.reset)
    }
    
    private func renderDiff(terminal: Terminal) {
        let size = terminal.size
        let startRow = 4
        let maxRows = size.height - 8
        
        guard currentFileIndex < fileDiffs.count else { return }
        let currentFile = fileDiffs[currentFileIndex]
        
        var currentRow = startRow
        
        // Render file header
        terminal.moveCursor(row: currentRow, col: 1)
        terminal.write(ANSICode.brightBlue + "File: \(currentFile.path)" + ANSICode.reset)
        terminal.write(" (+\(currentFile.totalAdditions)/-\(currentFile.totalDeletions))")
        currentRow += 1
        
        terminal.moveCursor(row: currentRow, col: 1)
        terminal.write(String(repeating: "─", count: size.width))
        currentRow += 1
        
        guard currentHunkIndex < currentFile.hunks.count else { return }
        let currentHunk = currentFile.hunks[currentHunkIndex]
        
        // Render hunk header
        terminal.moveCursor(row: currentRow, col: 1)
        terminal.write(ANSICode.cyan + currentHunk.headerLine + ANSICode.reset)
        currentRow += 1
        
        // Render hunk lines
        let visibleLines = min(currentHunk.lines.count, maxRows - (currentRow - startRow))
        
        for (lineIndex, line) in currentHunk.lines.prefix(visibleLines).enumerated() {
            terminal.moveCursor(row: currentRow, col: 1)
            
            let isSelected = isLineSelectionMode && selectedLines.contains(lineIndex)
            let background = isSelected ? ANSICode.bgYellow : ""
            let endBackground = isSelected ? ANSICode.reset : ""
            
            terminal.write("\(background)\(line.color)\(line.displayContent)\(ANSICode.reset)\(endBackground)")
            currentRow += 1
        }
        
        // Show hunk navigation info
        if currentFile.hunks.count > 1 {
            terminal.moveCursor(row: currentRow + 1, col: 1)
            terminal.write(ANSICode.yellow + "Hunk \(currentHunkIndex + 1) of \(currentFile.hunks.count)" + ANSICode.reset)
        }
        
        // Show file navigation info
        if fileDiffs.count > 1 {
            terminal.moveCursor(row: currentRow + 2, col: 1)
            terminal.write(ANSICode.yellow + "File \(currentFileIndex + 1) of \(fileDiffs.count)" + ANSICode.reset)
        }
    }
    
    private func handleLineSelectionKey(_ key: Key) {
        guard currentFileIndex < fileDiffs.count,
              currentHunkIndex < fileDiffs[currentFileIndex].hunks.count else { return }
        
        let hunk = fileDiffs[currentFileIndex].hunks[currentHunkIndex]
        
        switch key {
        case .char("j"):
            extendSelectionDown(hunk: hunk)
        case .char("k"):
            extendSelectionUp(hunk: hunk)
        case .char("s"):
            stageSelectedLines()
        case .char("u"):
            unstageSelectedLines()
        case .escape:
            exitLineSelectionMode()
        default:
            break
        }
    }
    
    private func navigateToNextHunk() {
        guard currentFileIndex < fileDiffs.count else { return }
        let currentFile = fileDiffs[currentFileIndex]
        
        if currentHunkIndex < currentFile.hunks.count - 1 {
            currentHunkIndex += 1
            resetLineSelection()
        }
    }
    
    private func navigateToPreviousHunk() {
        if currentHunkIndex > 0 {
            currentHunkIndex -= 1
            resetLineSelection()
        }
    }
    
    private func navigateToNextFile() {
        if currentFileIndex < fileDiffs.count - 1 {
            currentFileIndex += 1
            currentHunkIndex = 0
            resetLineSelection()
        }
    }
    
    private func navigateToPreviousFile() {
        if currentFileIndex > 0 {
            currentFileIndex -= 1
            currentHunkIndex = 0
            resetLineSelection()
        }
    }
    
    private func stageCurrentHunk() {
        guard mode == .unstaged,
              currentFileIndex < fileDiffs.count,
              currentHunkIndex < fileDiffs[currentFileIndex].hunks.count else { return }
        
        let file = fileDiffs[currentFileIndex]
        let hunk = file.hunks[currentHunkIndex]
        
        do {
            try repository.stageHunk(hunk, in: file.path)
            refresh()
        } catch {
            errorMessage = "Failed to stage hunk: \(error.localizedDescription)"
        }
    }
    
    private func unstageCurrentHunk() {
        guard mode == .staged,
              currentFileIndex < fileDiffs.count,
              currentHunkIndex < fileDiffs[currentFileIndex].hunks.count else { return }
        
        let file = fileDiffs[currentFileIndex]
        let hunk = file.hunks[currentHunkIndex]
        
        do {
            try repository.unstageHunk(hunk, in: file.path)
            refresh()
        } catch {
            errorMessage = "Failed to unstage hunk: \(error.localizedDescription)"
        }
    }
    
    private func stageAllHunksInFile() {
        guard mode == .unstaged, currentFileIndex < fileDiffs.count else { return }
        let file = fileDiffs[currentFileIndex]
        
        do {
            try repository.stageFile(file.path)
            refresh()
        } catch {
            errorMessage = "Failed to stage file: \(error.localizedDescription)"
        }
    }
    
    private func unstageAllHunksInFile() {
        guard mode == .staged, currentFileIndex < fileDiffs.count else { return }
        let file = fileDiffs[currentFileIndex]
        
        do {
            try repository.unstageFile(file.path)
            refresh()
        } catch {
            errorMessage = "Failed to unstage file: \(error.localizedDescription)"
        }
    }
    
    private func enterLineSelectionMode() {
        guard currentFileIndex < fileDiffs.count,
              currentHunkIndex < fileDiffs[currentFileIndex].hunks.count else { return }
        
        isLineSelectionMode = true
        selectedLines.removeAll()
        lineSelectionStart = 0
    }
    
    private func exitLineSelectionMode() {
        isLineSelectionMode = false
        selectedLines.removeAll()
        lineSelectionStart = 0
    }
    
    private func resetLineSelection() {
        if isLineSelectionMode {
            exitLineSelectionMode()
        }
    }
    
    private func extendSelectionDown(hunk: Hunk) {
        let maxLine = hunk.lines.count - 1
        if lineSelectionStart < maxLine {
            lineSelectionStart += 1
        }
        updateSelection(hunk: hunk)
    }
    
    private func extendSelectionUp(hunk: Hunk) {
        if lineSelectionStart > 0 {
            lineSelectionStart -= 1
        }
        updateSelection(hunk: hunk)
    }
    
    private func updateSelection(hunk: Hunk) {
        selectedLines.removeAll()
        
        // Find stageable lines around the selection
        for i in max(0, lineSelectionStart - 2)...min(hunk.lines.count - 1, lineSelectionStart + 2) {
            let line = hunk.lines[i]
            if line.type != .context {
                selectedLines.insert(i)
            }
        }
    }
    
    private func stageSelectedLines() {
        guard !selectedLines.isEmpty,
              currentFileIndex < fileDiffs.count,
              currentHunkIndex < fileDiffs[currentFileIndex].hunks.count else { return }
        
        let file = fileDiffs[currentFileIndex]
        let hunk = file.hunks[currentHunkIndex]
        
        do {
            try repository.stageLines(selectedLines, in: hunk, file: file.path)
            refresh()
        } catch {
            errorMessage = "Failed to stage selected lines: \(error.localizedDescription)"
        }
    }
    
    private func unstageSelectedLines() {
        guard !selectedLines.isEmpty,
              currentFileIndex < fileDiffs.count,
              currentHunkIndex < fileDiffs[currentFileIndex].hunks.count else { return }
        
        let file = fileDiffs[currentFileIndex]
        let hunk = file.hunks[currentHunkIndex]
        
        // For unstaging, we need the inverse operation
        let allLines = Set(0..<hunk.lines.count)
        let linesToKeep = allLines.subtracting(selectedLines)
        
        do {
            try repository.stageLines(linesToKeep, in: hunk, file: file.path)
            refresh()
        } catch {
            errorMessage = "Failed to unstage selected lines: \(error.localizedDescription)"
        }
    }
    
    private func toggleMode() {
        mode = mode == .staged ? .unstaged : .staged
        refresh()
    }
    
    private func refresh(file: String? = nil) {
        isLoading = true
        errorMessage = ""
        resetLineSelection()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let diffs = try self.repository.diff(for: file, cached: self.mode == .staged)
                
                DispatchQueue.main.async {
                    self.fileDiffs = diffs
                    self.isLoading = false
                    self.currentFileIndex = min(self.currentFileIndex, max(0, diffs.count - 1))
                    self.currentHunkIndex = 0
                    
                    if !diffs.isEmpty && self.currentFileIndex < diffs.count {
                        let file = diffs[self.currentFileIndex]
                        self.currentHunkIndex = min(self.currentHunkIndex, max(0, file.hunks.count - 1))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}