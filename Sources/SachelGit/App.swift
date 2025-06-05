import Foundation

class SachelGitApp: LeaderKeyDelegate {
    private let terminal = Terminal()
    private var currentView: View?
    private let leaderKeyManager = LeaderKeyManager()
    private var repository: GitRepository?
    private var isRunning = true
    
    private var statusBarMessage = ""
    private var currentMode = "NORMAL"
    
    init() throws {
        leaderKeyManager.delegate = self
        try setupRepository()
        try terminal.enableRawMode()
    }
    
    deinit {
        terminal.cleanup()
    }
    
    func run() {
        terminal.clearScreen()
        
        // Start with status view
        if let repo = repository {
            switchToView(StatusView(repository: repo))
        } else {
            showError("Not a Git repository")
            return
        }
        
        // Main event loop
        while isRunning {
            if let key = terminal.readKey() {
                handleKey(key)
            }
            
            // Small delay to prevent high CPU usage
            usleep(10000) // 10ms
        }
    }
    
    private func handleKey(_ key: Key) {
        // Handle Ctrl+C for graceful exit
        if case .ctrl(let char) = key, char == "c" {
            quit()
            return
        }
        
        // Check if leader key manager handles the key
        if leaderKeyManager.handleKey(key) {
            return
        }
        
        // Pass to current view
        currentView?.handleKey(key)
        render()
    }
    
    private func render() {
        terminal.clearScreen()
        
        // Render current view
        currentView?.render(terminal: terminal)
        
        // Render status bar
        renderStatusBar()
        
        // Render any messages
        if !statusBarMessage.isEmpty {
            renderMessage()
        }
    }
    
    private func renderStatusBar() {
        let size = terminal.size
        terminal.moveCursor(row: size.height - 2, col: 1)
        
        let branch = repository?.currentBranch() ?? "unknown"
        let repoName = repository?.name ?? "unknown"
        let status = "\(currentMode) | \(currentView?.title ?? "Unknown") | \(branch) | \(repoName)"
        
        terminal.write(ANSICode.bgBlue + ANSICode.white + status.padding(toLength: size.width, withPad: " ", startingAt: 0) + ANSICode.reset)
    }
    
    private func renderMessage() {
        let size = terminal.size
        terminal.moveCursor(row: size.height - 1, col: 1)
        terminal.write(statusBarMessage.padding(toLength: size.width, withPad: " ", startingAt: 0))
    }
    
    private func setupRepository() throws {
        // For demo purposes, use a mock repository
        // In production, this would use SwiftGit2 to open the actual repository
        repository = MockGitRepository()
    }
    
    private func switchToView(_ view: View) {
        currentView = view
        render()
    }
    
    private func quit() {
        isRunning = false
        terminal.cleanup()
        exit(0)
    }
}

// MARK: - LeaderKeyDelegate

extension SachelGitApp {
    func executeCommand(_ command: LeaderCommand) {
        guard let repo = repository else {
            showError("No repository available")
            return
        }
        
        switch command {
        case .gitStatus:
            switchToView(StatusView(repository: repo))
        case .gitCommit:
            switchToView(CommitView(repository: repo))
        case .gitDiff:
            switchToView(DiffView(repository: repo))
        case .gitLog:
            showError("Log view not yet implemented")
        case .help:
            switchToView(HelpView())
        case .quit:
            quit()
        }
        
        statusBarMessage = ""
    }
    
    func showLeaderHint(_ sequence: String) {
        statusBarMessage = "Leader: \(sequence)"
        renderMessage()
    }
    
    func hideLeaderHint() {
        statusBarMessage = ""
        render()
    }
    
    func showError(_ message: String) {
        statusBarMessage = ANSICode.red + "Error: \(message)" + ANSICode.reset
        renderMessage()
        
        // Clear error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if self?.statusBarMessage.contains("Error:") == true {
                self?.statusBarMessage = ""
                self?.render()
            }
        }
    }
}

enum SachelGitError: Error, LocalizedError {
    case notAGitRepository(path: String)
    case repositoryError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAGitRepository(let path):
            return "Not a Git repository: \(path)"
        case .repositoryError(let message):
            return "Repository error: \(message)"
        }
    }
}