# Building Sachel
I set out here with no goal in particular.

I am simply a user of git, and figured "why not slap an interface on it".

Anyways, we don't need reasoning here.
We are mostly just doing some fun experimentation.
In this programming adventure we are going to implement a git interface for some reason, and we're going to use Claude Code to do it.

This post isn't about git.
It's about exploring tools and showing how people create things using new tools.

So here, I'm making a thing, and will bring you along for the ride.

## Getting Started
I started this off in a painfully simple manner.

I wanted to view unstaged changes, stage hunks, and commit things.

I didn't really care what I built it in, so I figured why not mess with Claude to do it.

So, first I wrote out some instructions:

[skip](#looking-at-the-base)

---

# Sachel Git

A simple tool to do git things.

Starting with interactive hunk staging.

I want to fundamentally make a GOOD git GUI that anyone can use that is keyboard driven.

To start, we will use space as the leader key before an action.

for example

space -> g -> s

should open a git status view

I will provide a UI screenshot

---

## Looking at the base
This is a simple enough beginning, and I wanted it to kind of be a free flowing thing for Claude.

But that won't get me far with any workable code, so instead I decided that I was going to take this and some prose and throw it at Claude Opus 4 and have it make some specifications for the MVP for me.

So I prompted it:

> I have the following CLAUDE.md that is quite lacking.
> Can you flesh out the vision of the MVP of this product and also output specifications and instructions that will ultimately be fed to sonnet 4 to implement for you in Swift
> [...]

And I got quite a lot as a result!

[skip](#what-we-got)
---
<detail>
# Sachel Git - Swift MVP Specification & Vision

## Product Vision

    Sachel Git is a keyboard-driven Git GUI built in Swift that makes version control accessible to everyone while remaining powerful for advanced users. It combines the efficiency of terminal-based workflows with the clarity of visual interfaces, creating a native, high-performance tool that grows with the user's expertise.

### Core Philosophy
    - **Keyboard-first, mouse-optional**: Every action accessible via intuitive keyboard shortcuts
    - **Progressive disclosure**: Simple for beginners, powerful for experts
    - **Visual clarity**: Complex Git operations made understandable through clear UI
    - **Native performance**: Leveraging Swift's speed and efficiency

## MVP Scope

### Phase 1: Core Features (MVP)
    1. **Interactive Hunk Staging**
       - Visual diff viewer with syntax highlighting
       - Stage/unstage individual hunks with single keypress
       - Stage/unstage individual lines within hunks
       - Quick navigation between changes

    2. **Git Status View**
       - Clear visualization of working directory state
       - Grouped display: staged, unstaged, untracked files
       - Quick actions on files (stage all, discard, ignore)

    3. **Commit Interface**
       - Inline commit message editor
       - Commit message templates and history
       - Amend last commit functionality

    4. **Basic Navigation**
       - Space-based leader key system
       - Vim-style navigation (j/k for up/down, h/l for left/right)
       - Context-sensitive help system

## Keyboard Navigation System

### Leader Key Architecture
    All primary actions initiated with `Space` as the leader key, followed by mnemonic shortcuts:

    ```
    Space → g → s    : Git Status view
    Space → g → c    : Commit view
    Space → g → d    : Diff view
    Space → g → l    : Log view (future)
    Space → h        : Help/keybinding overview
    Space → q        : Quit current view
    ```

### Context-Specific Keys (No Leader Required)
    **In Status View:**
    - `j/k`: Navigate up/down through files
    - `Enter`: Open file diff view
    - `s`: Stage file/hunk
    - `u`: Unstage file/hunk
    - `d`: Discard changes (with confirmation)
    - `i`: Add to .gitignore
    - `r`: Refresh status

    **In Diff/Hunk View:**
    - `j/k`: Navigate between hunks
    - `J/K`: Navigate between files
    - `s`: Stage current hunk
    - `S`: Stage all hunks in file
    - `u`: Unstage current hunk
    - `U`: Unstage all hunks in file
    - `v`: Enter line-selection mode
    - `Space`: Toggle hunk selection
    - `Tab`: Switch between staged/unstaged view

    **In Line Selection Mode:**
    - `j/k`: Extend selection down/up
    - `s`: Stage selected lines
    - `u`: Unstage selected lines
    - `Esc`: Exit line selection

    **In Commit View:**
    - `i`: Enter insert mode (edit commit message)
    - `Esc`: Exit insert mode
    - `Ctrl+Enter`: Confirm commit
    - `Ctrl+a`: Amend last commit

## User Interface Design

### Layout Structure
    ```
    ┌─────────────────────────────────────────────────────────┐
    │ Sachel Git - [Current Branch] - [Repository Name]       │
    ├─────────────────────────────────────────────────────────┤
    │ Status Bar: [Mode] | [Current View] | [Keybind Hints]   │
    ├─────────────────────────────────────────────────────────┤
    │                                                         │
    │                   Main Content Area                     │
    │                                                         │
    │                                                         │
    ├─────────────────────────────────────────────────────────┤
    │ Context Help: [Dynamic key hints based on current view] │
    └─────────────────────────────────────────────────────────┘
    ```

### Color Scheme
    - **Added lines**: Green (#50FA7B)
    - **Removed lines**: Red (#FF5555)
    - **Modified hunks**: Yellow (#F1FA8C)
    - **Staged items**: Blue (#8BE9FD)
    - **Conflicts**: Orange (#FFB86C)
    - **Background**: Dark (#282A36)
    - **Foreground**: Light (#F8F8F2)

## Technical Implementation Instructions for Sonnet 4

### Technology Stack
    - **Language**: Swift 5.9+
    - **TUI Framework**: Custom-built using Swift's Terminal control
    - **Git Integration**: SwiftGit2 (libgit2 Swift wrapper)
    - **Syntax Highlighting**: Splash or custom implementation
    - **Build System**: Swift Package Manager

### Project Structure
    ```
    SachelGit/
    ├── Package.swift
    ├── Sources/
    │   ├── SachelGit/
    │   │   ├── main.swift
    │   │   ├── App.swift
    │   │   ├── Core/
    │   │   │   ├── Terminal.swift      # Terminal control and rendering
    │   │   │   ├── KeyHandler.swift    # Keyboard input handling
    │   │   │   └── LeaderKey.swift     # Leader key system
    │   │   ├── Views/
    │   │   │   ├── View.swift          # Base view protocol
    │   │   │   ├── StatusView.swift    # Git status view
    │   │   │   ├── DiffView.swift      # Diff/hunk view
    │   │   │   ├── CommitView.swift    # Commit interface
    │   │   │   └── HelpView.swift      # Help overlay
    │   │   ├── Components/
    │   │   │   ├── FileTree.swift      # File list component
    │   │   │   ├── DiffViewer.swift    # Diff display component
    │   │   │   ├── HunkSelector.swift  # Hunk selection logic
    │   │   │   └── StatusBar.swift     # Status bar component
    │   │   ├── Git/
    │   │   │   ├── Repository.swift    # Git repository wrapper
    │   │   │   ├── DiffParser.swift    # Diff parsing
    │   │   │   ├── HunkManager.swift   # Hunk staging operations
    │   │   │   └── GitTypes.swift      # Git-related types
    │   │   ├── Models/
    │   │   │   ├── FileStatus.swift
    │   │   │   ├── Hunk.swift
    │   │   │   └── DiffLine.swift
    │   │   └── Config/
    │   │       ├── Keybindings.swift
    │   │       └── Theme.swift
    │   └── SachelGitCore/              # Reusable core library
    │       └── ...
    ├── Tests/
    │   └── SachelGitTests/
    └── README.md
    ```

### Implementation Steps

    1. **Set Up Terminal Control System**
    ```swift
    // Terminal.swift
    import Foundation

    class Terminal {
        private var originalTermios: termios?
        
        init() {
            enableRawMode()
            hideCursor()
        }
        
        func enableRawMode() {
            var raw = termios()
            tcgetattr(STDIN_FILENO, &raw)
            originalTermios = raw
            
            raw.c_lflag &= ~(UInt(ECHO | ICANON))
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
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
        
        func moveCursor(row: Int, col: Int) {
            print("\u{1B}[\(row);\(col)H", terminator: "")
        }
        
        func clearScreen() {
            print("\u{1B}[2J\u{1B}[H", terminator: "")
        }
    }
    ```

    2. **Create App Architecture**
    ```swift
    // App.swift
    import Foundation
    import SwiftGit2

    @main
    class SachelGitApp {
        private let terminal = Terminal()
        private var currentView: View
        private let repository: Repository
        private var leaderMode = false
        private var leaderBuffer = ""
        
        init() throws {
            // Initialize repository
            let repoPath = FileManager.default.currentDirectoryPath
            self.repository = try Repository.at(URL(fileURLWithPath: repoPath))
            
            // Start with status view
            self.currentView = StatusView(repository: repository)
        }
        
        func run() {
            terminal.clearScreen()
            currentView.render(terminal: terminal)
            
            while true {
                if let key = terminal.readKey() {
                    if leaderMode {
                        handleLeaderKey(key)
                    } else if key == .space {
                        leaderMode = true
                        showLeaderHint()
                    } else {
                        currentView.handleKey(key)
                        currentView.render(terminal: terminal)
                    }
                }
            }
        }
        
        private func handleLeaderKey(_ key: Key) {
            leaderBuffer.append(key.char)
            
            switch leaderBuffer {
            case "gs":
                switchToView(StatusView(repository: repository))
            case "gc":
                switchToView(CommitView(repository: repository))
            case "gd":
                switchToView(DiffView(repository: repository))
            case "q":
                cleanup()
                exit(0)
            default:
                if leaderBuffer.count >= 2 {
                    leaderMode = false
                    leaderBuffer = ""
                    showError("Unknown command: Space → \(leaderBuffer)")
                }
            }
        }
    }
    ```

    3. **Implement Git Repository Wrapper**
    ```swift
    // Repository.swift
    import SwiftGit2

    class GitRepository {
        private let repo: Repository
        
        init(at path: URL) throws {
            self.repo = try Repository.at(path)
        }
        
        func status() throws -> [FileStatus] {
            let status = try repo.status()
            return status.compactMap { entry in
                FileStatus(
                    path: entry.path,
                    staged: entry.status.contains(.indexNew) || 
                            entry.status.contains(.indexModified),
                    modified: entry.status.contains(.workTreeModified),
                    untracked: entry.status.contains(.workTreeNew)
                )
            }
        }
        
        func diff(for file: String, cached: Bool = false) throws -> [Hunk] {
            let options = DiffOptions()
            options.pathspec = [file]
            
            let diff = cached ? 
                try repo.diffIndexToWorkdir(options: options) :
                try repo.diffTreeToIndex(options: options)
                
            return parseDiff(diff)
        }
        
        func stageHunk(_ hunk: Hunk, in file: String) throws {
            // Create a patch from the hunk
            let patch = createPatch(from: hunk, file: file)
            
            // Apply the patch to the index
            try applyPatch(patch, toIndex: true)
        }
    }
    ```

    4. **Build View System**
    ```swift
    // View.swift
    protocol View {
        func render(terminal: Terminal)
        func handleKey(_ key: Key)
    }

    // StatusView.swift
    class StatusView: View {
        private let repository: GitRepository
        private var files: [FileStatus] = []
        private var selectedIndex = 0
        
        init(repository: GitRepository) {
            self.repository = repository
            refresh()
        }
        
        func render(terminal: Terminal) {
            terminal.clearScreen()
            terminal.moveCursor(row: 1, col: 1)
            
            // Header
            print("Git Status - \(repository.currentBranch)")
            print(String(repeating: "─", count: terminal.width))
            
            // File list
            for (index, file) in files.enumerated() {
                let marker = index == selectedIndex ? "▶" : " "
                let status = file.statusIndicator
                let color = file.statusColor
                
                print("\(marker) \(color)\(status) \(file.path)\u{1B}[0m")
            }
            
            // Help bar
            terminal.moveCursor(row: terminal.height - 1, col: 1)
            print("j/k: navigate | s: stage | u: unstage | Enter: view diff | Space: leader")
        }
        
        func handleKey(_ key: Key) {
            switch key {
            case .char("j"):
                selectedIndex = min(selectedIndex + 1, files.count - 1)
            case .char("k"):
                selectedIndex = max(selectedIndex - 1, 0)
            case .char("s"):
                stageCurrentFile()
            case .char("u"):
                unstageCurrentFile()
            case .enter:
                openDiffView()
            case .char("r"):
                refresh()
            default:
                break
            }
        }
    }
    ```

    5. **Implement Hunk Staging Logic**
    ```swift
    // HunkManager.swift
    struct Hunk {
        let oldStart: Int
        let oldCount: Int
        let newStart: Int
        let newCount: Int
        let lines: [DiffLine]
        
        func toPatch(filename: String) -> String {
            var patch = "diff --git a/\(filename) b/\(filename)\n"
            patch += "--- a/\(filename)\n"
            patch += "+++ b/\(filename)\n"
            patch += "@@ -\(oldStart),\(oldCount) +\(newStart),\(newCount) @@\n"
            
            for line in lines {
                patch += line.content
            }
            
            return patch
        }
    }

    extension GitRepository {
        func stageLines(_ lines: Range<Int>, in hunk: Hunk, file: String) throws {
            // Create a new hunk with only the selected lines
            var modifiedHunk = hunk
            var selectedLines: [DiffLine] = []
            var newCount = 0
            
            for (index, line) in hunk.lines.enumerated() {
                if lines.contains(index) || line.type == .context {
                    selectedLines.append(line)
                    if line.type != .deletion {
                        newCount += 1
                    }
                }
            }
            
            modifiedHunk.lines = selectedLines
            modifiedHunk.newCount = newCount
            
            let patch = modifiedHunk.toPatch(filename: file)
            try applyPatch(patch, toIndex: true)
        }
    }
    ```

    6. **Create Syntax Highlighting**
    ```swift
    // SyntaxHighlighter.swift
    struct SyntaxHighlighter {
        static func highlight(_ line: String, language: Language) -> NSAttributedString {
            // Use Splash or implement basic highlighting
            let highlighted = NSMutableAttributedString(string: line)
            
            // Apply syntax colors based on language rules
            if let keywordRanges = findKeywords(in: line, for: language) {
                for range in keywordRanges {
                    highlighted.addAttribute(.foregroundColor, 
                                           value: Theme.keywordColor, 
                                           range: range)
                }
            }
            
            return highlighted
        }
    }
    ```

### Key Implementation Details

    **Terminal Control Escape Sequences:**
    ```swift
    enum ANSICode {
        static let clearScreen = "\u{1B}[2J"
        static let moveCursor = "\u{1B}[%d;%dH"
        static let hideCursor = "\u{1B}[?25l"
        static let showCursor = "\u{1B}[?25h"
        
        // Colors
        static let red = "\u{1B}[31m"
        static let green = "\u{1B}[32m"
        static let yellow = "\u{1B}[33m"
        static let blue = "\u{1B}[34m"
        static let reset = "\u{1B}[0m"
    }
    ```

    **Key Detection:**
    ```swift
    enum Key: Equatable {
        case char(Character)
        case up, down, left, right
        case enter, escape, tab, space
        case ctrl(Character)
        
        static func from(byte: UInt8) -> Key? {
            switch byte {
            case 0x0D: return .enter
            case 0x1B: return .escape
            case 0x09: return .tab
            case 0x20: return .space
            case 0x01...0x1A: return .ctrl(Character(UnicodeScalar(byte + 0x60)))
            default:
                if let scalar = UnicodeScalar(byte) {
                    return .char(Character(scalar))
                }
            }
            return nil
        }
    }
    ```

### Performance Optimizations
    - Use lazy loading for large diffs
    - Implement diff caching with file modification timestamps
    - Use GCD for background Git operations
    - Optimize terminal rendering with dirty region tracking

### Testing Strategy
    ```swift
    // Example test
    import XCTest
    @testable import SachelGit

    class HunkManagerTests: XCTestCase {
        func testStagePartialHunk() throws {
            let repo = try TestRepository.create()
            let hunk = createTestHunk()
            
            try repo.stageLines(2..<5, in: hunk, file: "test.swift")
            
            let staged = try repo.stagedChanges()
            XCTAssertEqual(staged.count, 3)
        }
    }
    ```

### Build Configuration
    ```swift
    // Package.swift
    // swift-tools-version: 5.9
    import PackageDescription

    let package = Package(
        name: "SachelGit",
        platforms: [
            .macOS(.v12)
        ],
        products: [
            .executable(name: "sachel", targets: ["SachelGit"])
        ],
        dependencies: [
            .package(url: "https://github.com/SwiftGit2/SwiftGit2.git", from: "0.10.0"),
            .package(url: "https://github.com/JohnSundell/Splash", from: "0.16.0")
        ],
        targets: [
            .executableTarget(
                name: "SachelGit",
                dependencies: ["SwiftGit2", "Splash"]
            ),
            .testTarget(
                name: "SachelGitTests",
                dependencies: ["SachelGit"]
            )
        ]
    )
    ```

## Success Metrics
    - Application startup time < 100ms
    - Smooth 60fps scrolling in large diffs
    - Memory usage < 50MB for typical repositories
    - All common operations achievable in ≤ 3 keystrokes

## Future Enhancements (Post-MVP)
    - Branch visualization and management
    - Interactive rebase with visual representation
    - Merge conflict resolution interface
    - Git log graph visualization
    - Stash management
    - Multi-repository workspace support
    - Plugin system using Swift dynamic libraries
    - Integration with native macOS features (Touch Bar, Quick Look)
</detail>

---

## What we got
This is quite a bit to digest, but let's go over it in parts.
