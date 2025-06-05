import Foundation

class HelpView: BaseView {
    
    init() {
        super.init(title: "Help & Keybindings")
    }
    
    override func render(terminal: Terminal) {
        terminal.clearScreen()
        renderHeader(terminal: terminal)
        
        let size = terminal.size
        var currentRow = 4
        
        // Leader key commands
        terminal.moveCursor(row: currentRow, col: 2)
        terminal.write(ANSICode.brightYellow + "Leader Key Commands (Space + ...):" + ANSICode.reset)
        currentRow += 2
        
        let leaderCommands = [
            ("g → s", "Git Status view"),
            ("g → c", "Commit view"),
            ("g → d", "Diff view"),
            ("g → l", "Log view (coming soon)"),
            ("h", "Help/keybinding overview"),
            ("q", "Quit current view")
        ]
        
        for (keys, description) in leaderCommands {
            terminal.moveCursor(row: currentRow, col: 4)
            terminal.write(ANSICode.cyan + "Space → \(keys)" + ANSICode.reset + " : \(description)")
            currentRow += 1
        }
        
        currentRow += 1
        
        // Status view commands
        terminal.moveCursor(row: currentRow, col: 2)
        terminal.write(ANSICode.brightYellow + "Status View Commands:" + ANSICode.reset)
        currentRow += 2
        
        let statusCommands = [
            ("j/k", "Navigate up/down through files"),
            ("Enter", "Open file diff view"),
            ("s", "Stage file/hunk"),
            ("u", "Unstage file/hunk"),
            ("d", "Discard changes (with confirmation)"),
            ("r", "Refresh status")
        ]
        
        for (keys, description) in statusCommands {
            terminal.moveCursor(row: currentRow, col: 4)
            terminal.write(ANSICode.cyan + keys + ANSICode.reset + " : \(description)")
            currentRow += 1
        }
        
        currentRow += 1
        
        // Diff view commands
        terminal.moveCursor(row: currentRow, col: 2)
        terminal.write(ANSICode.brightYellow + "Diff/Hunk View Commands:" + ANSICode.reset)
        currentRow += 2
        
        let diffCommands = [
            ("j/k", "Navigate between hunks"),
            ("J/K", "Navigate between files"),
            ("s", "Stage current hunk"),
            ("S", "Stage all hunks in file"),
            ("u", "Unstage current hunk"),
            ("U", "Unstage all hunks in file"),
            ("v", "Enter line-selection mode"),
            ("Space", "Toggle hunk selection"),
            ("Tab", "Switch between staged/unstaged view")
        ]
        
        for (keys, description) in diffCommands {
            if currentRow >= size.height - 5 { break }
            terminal.moveCursor(row: currentRow, col: 4)
            terminal.write(ANSICode.cyan + keys + ANSICode.reset + " : \(description)")
            currentRow += 1
        }
        
        currentRow += 1
        
        // Commit view commands
        if currentRow < size.height - 5 {
            terminal.moveCursor(row: currentRow, col: 2)
            terminal.write(ANSICode.brightYellow + "Commit View Commands:" + ANSICode.reset)
            currentRow += 2
            
            let commitCommands = [
                ("i", "Enter insert mode (edit commit message)"),
                ("Esc", "Exit insert mode"),
                ("Ctrl+Enter", "Confirm commit"),
                ("Ctrl+a", "Amend last commit")
            ]
            
            for (keys, description) in commitCommands {
                if currentRow >= size.height - 5 { break }
                terminal.moveCursor(row: currentRow, col: 4)
                terminal.write(ANSICode.cyan + keys + ANSICode.reset + " : \(description)")
                currentRow += 1
            }
        }
        
        renderFooter(terminal: terminal, helpText: "Press any key to return")
    }
    
    override func handleKey(_ key: Key) {
        // Any key press returns from help view
        // This would typically be handled by the app to switch back to previous view
    }
}