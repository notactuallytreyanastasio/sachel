import Foundation

protocol LeaderKeyDelegate: AnyObject {
    func executeCommand(_ command: LeaderCommand)
    func showLeaderHint(_ sequence: String)
    func hideLeaderHint()
    func showError(_ message: String)
}

enum LeaderCommand {
    case gitStatus
    case gitCommit
    case gitDiff
    case gitLog
    case help
    case quit
}

class LeaderKeyManager {
    weak var delegate: LeaderKeyDelegate?
    
    private var isLeaderMode = false
    private var leaderBuffer = ""
    private var leaderTimer: Timer?
    
    private let leaderTimeout: TimeInterval = 2.0
    
    private let commandMap: [String: LeaderCommand] = [
        "gs": .gitStatus,
        "gc": .gitCommit,
        "gd": .gitDiff,
        "gl": .gitLog,
        "h": .help,
        "q": .quit
    ]
    
    func handleKey(_ key: Key) -> Bool {
        if isLeaderMode {
            return handleLeaderKey(key)
        } else if key == .space {
            startLeaderSequence()
            return true
        }
        return false
    }
    
    private func startLeaderSequence() {
        isLeaderMode = true
        leaderBuffer = ""
        resetLeaderTimer()
        delegate?.showLeaderHint("Space")
    }
    
    private func handleLeaderKey(_ key: Key) -> Bool {
        guard let char = key.char.first, char.isLetter || char.isNumber else {
            if key == .escape {
                cancelLeaderSequence()
                return true
            }
            return false
        }
        
        leaderBuffer.append(char.lowercased())
        resetLeaderTimer()
        
        // Check for exact match
        if let command = commandMap[leaderBuffer] {
            executeCommand(command)
            return true
        }
        
        // Check if buffer is a prefix of any command
        let hasValidPrefix = commandMap.keys.contains { $0.hasPrefix(leaderBuffer) }
        if hasValidPrefix {
            delegate?.showLeaderHint("Space → \(leaderBuffer)")
            return true
        }
        
        // Invalid sequence
        delegate?.showError("Unknown command: Space → \(leaderBuffer)")
        cancelLeaderSequence()
        return true
    }
    
    private func executeCommand(_ command: LeaderCommand) {
        cancelLeaderSequence()
        delegate?.executeCommand(command)
    }
    
    private func cancelLeaderSequence() {
        isLeaderMode = false
        leaderBuffer = ""
        leaderTimer?.invalidate()
        leaderTimer = nil
        delegate?.hideLeaderHint()
    }
    
    private func resetLeaderTimer() {
        leaderTimer?.invalidate()
        leaderTimer = Timer.scheduledTimer(withTimeInterval: leaderTimeout, repeats: false) { [weak self] _ in
            self?.timeoutLeaderSequence()
        }
    }
    
    private func timeoutLeaderSequence() {
        if !leaderBuffer.isEmpty {
            delegate?.showError("Command timeout: Space → \(leaderBuffer)")
        }
        cancelLeaderSequence()
    }
    
    func getAvailableCommands() -> [String: String] {
        return [
            "Space → g → s": "Git Status view",
            "Space → g → c": "Commit view",
            "Space → g → d": "Diff view",
            "Space → g → l": "Log view",
            "Space → h": "Help/keybinding overview",
            "Space → q": "Quit current view"
        ]
    }
}