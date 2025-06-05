import Foundation

class StatusView: BaseView {
    private let repository: GitRepository
    private var files: [FileStatus] = []
    private var selectedIndex = 0
    private var isLoading = false
    private var errorMessage = ""
    
    init(repository: GitRepository) {
        self.repository = repository
        super.init(title: "Git Status")
        refresh()
    }
    
    override func render(terminal: Terminal) {
        terminal.clearScreen()
        
        let branch = repository.currentBranch()
        renderHeader(terminal: terminal, subtitle: "Branch: \(branch)")
        
        if isLoading {
            renderLoading(terminal: terminal)
            return
        }
        
        if !errorMessage.isEmpty {
            renderError(terminal: terminal)
            return
        }
        
        renderFileList(terminal: terminal)
        renderFooter(terminal: terminal, helpText: "j/k: navigate | s: stage | u: unstage | Enter: view diff | r: refresh | Space: leader")
    }
    
    override func handleKey(_ key: Key) {
        switch key {
        case .char("j"):
            navigateDown()
        case .char("k"):
            navigateUp()
        case .char("s"):
            stageCurrentFile()
        case .char("u"):
            unstageCurrentFile()
        case .char("d"):
            discardCurrentFile()
        case .char("r"):
            refresh()
        case .enter:
            // This would open diff view - for now just refresh
            refresh()
        default:
            break
        }
    }
    
    private func renderLoading(terminal: Terminal) {
        let size = terminal.size
        let message = "Loading repository status..."
        
        terminal.moveCursor(row: size.height / 2, col: 1)
        terminal.write(centerText(message, width: size.width))
    }
    
    private func renderError(terminal: Terminal) {
        let size = terminal.size
        
        terminal.moveCursor(row: size.height / 2, col: 1)
        terminal.write(ANSICode.red + centerText("Error: \(errorMessage)", width: size.width) + ANSICode.reset)
    }
    
    private func renderFileList(terminal: Terminal) {
        let size = terminal.size
        let startRow = 4
        let maxRows = size.height - 8 // Leave space for header and footer
        
        if files.isEmpty {
            terminal.moveCursor(row: startRow + 2, col: 1)
            terminal.write(ANSICode.green + centerText("✓ Working directory clean", width: size.width) + ANSICode.reset)
            return
        }
        
        // Group files by status
        let stagedFiles = files.filter { $0.staged }
        let unstagedFiles = files.filter { !$0.staged }
        
        var currentRow = startRow
        
        // Render staged files
        if !stagedFiles.isEmpty {
            terminal.moveCursor(row: currentRow, col: 1)
            terminal.write(ANSICode.green + "Staged Changes:" + ANSICode.reset)
            currentRow += 1
            
            for (index, file) in stagedFiles.enumerated() {
                if currentRow >= startRow + maxRows { break }
                
                let globalIndex = index
                let isSelected = globalIndex == selectedIndex
                renderFileLine(terminal: terminal, file: file, row: currentRow, isSelected: isSelected)
                currentRow += 1
            }
            
            currentRow += 1 // Add spacing
        }
        
        // Render unstaged files
        if !unstagedFiles.isEmpty {
            if currentRow < startRow + maxRows {
                terminal.moveCursor(row: currentRow, col: 1)
                terminal.write(ANSICode.yellow + "Unstaged Changes:" + ANSICode.reset)
                currentRow += 1
                
                for (index, file) in unstagedFiles.enumerated() {
                    if currentRow >= startRow + maxRows { break }
                    
                    let globalIndex = stagedFiles.count + index
                    let isSelected = globalIndex == selectedIndex
                    renderFileLine(terminal: terminal, file: file, row: currentRow, isSelected: isSelected)
                    currentRow += 1
                }
            }
        }
    }
    
    private func renderFileLine(terminal: Terminal, file: FileStatus, row: Int, isSelected: Bool) {
        terminal.moveCursor(row: row, col: 1)
        
        let prefix = isSelected ? "▶ " : "  "
        let status = file.statusIndicator
        let color = file.statusColor
        let resetColor = ANSICode.reset
        
        let background = isSelected ? ANSICode.bgBlue : ""
        let endBackground = isSelected ? ANSICode.reset : ""
        
        terminal.write("\(background)\(prefix)\(color)\(status)\(resetColor) \(file.displayName)\(endBackground)")
        
        if isSelected {
            // Clear to end of line to maintain background
            terminal.write(ANSICode.clearLine)
        }
    }
    
    private func navigateDown() {
        if !files.isEmpty {
            selectedIndex = min(selectedIndex + 1, files.count - 1)
        }
    }
    
    private func navigateUp() {
        selectedIndex = max(selectedIndex - 1, 0)
    }
    
    private func stageCurrentFile() {
        guard selectedIndex < files.count else { return }
        let file = files[selectedIndex]
        
        if file.canStage {
            do {
                try repository.stageFile(file.path)
                refresh()
            } catch {
                errorMessage = "Failed to stage \(file.path): \(error.localizedDescription)"
            }
        }
    }
    
    private func unstageCurrentFile() {
        guard selectedIndex < files.count else { return }
        let file = files[selectedIndex]
        
        if file.canUnstage {
            do {
                try repository.unstageFile(file.path)
                refresh()
            } catch {
                errorMessage = "Failed to unstage \(file.path): \(error.localizedDescription)"
            }
        }
    }
    
    private func discardCurrentFile() {
        guard selectedIndex < files.count else { return }
        let file = files[selectedIndex]
        
        if !file.staged && (file.modified || file.deleted) {
            do {
                try repository.discardChanges(in: file.path)
                refresh()
            } catch {
                errorMessage = "Failed to discard changes in \(file.path): \(error.localizedDescription)"
            }
        }
    }
    
    private func refresh() {
        isLoading = true
        errorMessage = ""
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let status = try self?.repository.status() ?? []
                
                DispatchQueue.main.async {
                    self?.files = status
                    self?.isLoading = false
                    self?.selectedIndex = min(self?.selectedIndex ?? 0, max(0, status.count - 1))
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                }
            }
        }
    }
}