# Sachel Git - Terminal User Interface

A keyboard-driven Git GUI built in Swift that makes version control accessible through intuitive terminal interface.

## Features Implemented ✅

### Core MVP Features (as per OPUS_INSTRUCTIONS.md)

1. **Interactive Hunk Staging** ✅
   - Visual diff viewer with syntax highlighting
   - Stage/unstage individual hunks with single keypress (`s`/`u`)
   - Stage/unstage individual lines within hunks (`v` for line selection)
   - Quick navigation between changes (`j`/`k` for hunks, `J`/`K` for files)

2. **Git Status View** ✅
   - Clear visualization of working directory state
   - Grouped display: staged, unstaged, untracked files
   - Quick actions on files (stage, unstage, discard, refresh)

3. **Commit Interface** ✅
   - Vim-like insert/normal modes (`i` to enter, `Esc` to exit)
   - Commit message editor with word wrapping
   - Amend last commit functionality (`Ctrl+A`)
   - Message history navigation (`↑`/`↓`)

4. **Keyboard Navigation System** ✅
   - Space-based leader key system
   - All actions accessible via keyboard shortcuts
   - Context-sensitive help system

## Keyboard Shortcuts

### Leader Key Commands (Space + ...)
- `Space → g → s` : Git Status view
- `Space → g → c` : Commit view  
- `Space → g → d` : Diff view
- `Space → h` : Help/keybinding overview
- `Space → q` : Quit current view

### Status View
- `j`/`k` : Navigate up/down through files
- `Enter` : Open file diff view
- `s` : Stage file
- `u` : Unstage file
- `d` : Discard changes
- `r` : Refresh status

### Diff/Hunk View
- `j`/`k` : Navigate between hunks
- `J`/`K` : Navigate between files
- `s` : Stage current hunk
- `S` : Stage all hunks in file
- `u` : Unstage current hunk
- `U` : Unstage all hunks in file
- `v` : Enter line-selection mode
- `Tab` : Switch between staged/unstaged view

### Line Selection Mode
- `j`/`k` : Extend selection down/up
- `s` : Stage selected lines
- `u` : Unstage selected lines
- `Esc` : Exit line selection

### Commit View
- `i` : Enter insert mode (edit commit message)
- `Esc` : Exit insert mode
- `Ctrl+Enter` : Confirm commit
- `Ctrl+A` : Amend last commit

## Technical Architecture

### Project Structure
```
Sources/SachelGit/
├── main.swift                 # Application entry point
├── App.swift                  # Main application class
├── Core/
│   ├── Terminal.swift         # Terminal control and rendering
│   └── LeaderKey.swift        # Leader key system
├── Views/
│   ├── View.swift             # Base view protocol
│   ├── StatusView.swift       # Git status view
│   ├── DiffView.swift         # Diff/hunk view
│   ├── CommitView.swift       # Commit interface
│   └── HelpView.swift         # Help overlay
├── Components/
│   └── SyntaxHighlighter.swift # Syntax highlighting
├── Git/
│   └── Repository.swift       # Git repository wrapper
├── Models/
│   ├── FileStatus.swift       # File status model
│   └── Hunk.swift            # Diff hunk model
└── Config/
    └── Theme.swift           # Color scheme (Dracula-inspired)
```

### Dependencies
- **SwiftGit2** : Git repository operations
- **Splash** : Syntax highlighting (future use)

### Color Scheme
Dracula-inspired theme with semantic colors:
- **Added lines**: Green (#50FA7B)
- **Removed lines**: Red (#FF5555)  
- **Modified hunks**: Yellow (#F1FA8C)
- **Staged items**: Blue (#8BE9FD)
- **Conflicts**: Orange (#FFB86C)

## Building & Running

```bash
# Build the project
swift build

# Run the executable
./.build/debug/sachel

# Run tests
swift test
```

## Testing

Comprehensive unit test coverage including:
- Terminal key detection and ANSI escape sequences
- Leader key system functionality
- Git repository operations (mocked)
- View navigation and interaction
- Syntax highlighting and theme colors
- File status and hunk management

## Success Metrics (Per Requirements)

- ✅ Keyboard-first interface with intuitive shortcuts
- ✅ Progressive disclosure (simple for beginners, powerful for experts) 
- ✅ Visual clarity for complex Git operations
- ✅ Native Swift performance
- ✅ All common operations achievable in ≤ 3 keystrokes
- ✅ Complete MVP scope implemented

## Future Enhancements

The architecture supports easy extension for post-MVP features:
- Branch visualization and management
- Interactive rebase interface
- Merge conflict resolution
- Git log graph visualization  
- Stash management
- Multi-repository workspace support

---

**Note**: This is a fully functional TUI implementation following the exact specifications in OPUS_INSTRUCTIONS.md. The application provides a modern, efficient alternative to traditional Git GUIs while maintaining the power and speed of command-line workflows.