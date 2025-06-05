# Claude's Design Approach & Engineering Thoughts

## Overview

This document maps out my complete thought process and engineering approach while building the Sachel Git Terminal User Interface. I'll explain the logical progression, key decisions, challenges faced, and solutions implemented for each component.

## 🧭 Initial Analysis & Strategic Planning

### Reading the Requirements

**First Step: Deep Analysis of OPUS_INSTRUCTIONS.md**

When I received the specification, I immediately performed a thorough analysis:

1. **Identified the Core Vision**: "Keyboard-driven Git GUI that makes version control accessible while remaining powerful"
2. **Recognized Key Constraints**: Terminal-based (TUI), not graphical (GUI)
3. **Mapped MVP Requirements**: Interactive hunk staging, status view, commit interface, keyboard navigation
4. **Noted Success Metrics**: <100ms startup, 60fps scrolling, <50MB memory, ≤3 keystrokes for operations

### Initial Mistake & Course Correction

**Critical Learning Moment**: I initially misunderstood and built a macOS GUI application with SwiftUI/AppKit. This taught me the importance of careful requirement analysis.

**Why This Happened**: 
- I saw "Swift" and "macOS" and defaulted to familiar GUI patterns
- Didn't pay enough attention to "TUI" vs "GUI" distinction
- The provided screenshot looked like a desktop application

**Course Correction Strategy**:
1. Immediately recognized the error when re-reading requirements
2. Completely pivoted architecture to terminal-based approach
3. Leveraged the mistake: The initial GUI work helped me understand the data models and interaction patterns needed

**Key Insight**: Sometimes false starts provide valuable architectural insights that inform the correct approach.

## 🏗️ Architectural Foundation (Bottom-Up Approach)

### 1. Terminal Control System - The Foundation Layer

**Why Start Here**: Everything else depends on reliable terminal control and input handling.

**Core Challenges**:
- Raw terminal mode management (disable canonical input)
- ANSI escape sequence handling for colors and cursor control
- Cross-platform key detection (arrow keys, control characters)
- Proper cleanup on exit (essential for TUI apps)

**Design Decisions**:

```swift
class Terminal {
    private var originalTermios: termios?  // Save original state
    private var isRawMode = false          // Track state
    
    // Why termios: Direct control over terminal behavior
    // Why save original: Clean restoration on exit
    // Why track state: Prevent double-enable/disable
}
```

**Key Insight**: TUI applications must be "good citizens" - they take over the terminal completely but must restore it perfectly on exit.

**Implementation Strategy**:
1. **Signal Handling**: Setup SIGINT/SIGTERM handlers for graceful cleanup
2. **ANSI Codes**: Created centralized constants for all escape sequences
3. **Key Detection**: Built robust mapping from raw bytes to semantic key events
4. **Error Handling**: Graceful fallbacks if terminal operations fail

### 2. Leader Key System - The Interaction Framework

**Why This Pattern**: The specification explicitly required Space-based leader keys, inspired by vim/emacs patterns.

**Design Philosophy**: 
- **Discoverability**: Users can explore commands by typing partial sequences
- **Efficiency**: Common operations require minimal keystrokes
- **Consistency**: All primary actions follow the same pattern
- **Safety**: Timeout mechanism prevents accidentally triggering commands

**Implementation Architecture**:

```swift
class LeaderKeyManager {
    private var isLeaderMode = false      // State tracking
    private var leaderBuffer = ""         // Command building
    private var leaderTimer: Timer?       // Timeout mechanism
    
    // Why state machine: Clear separation of modes
    // Why timeout: Prevents hanging in leader mode
    // Why buffer: Allows multi-character sequences
}
```

**Architectural Benefits**:
1. **Extensibility**: Easy to add new command sequences
2. **Feedback**: Visual indication of current command state
3. **Cancellation**: Escape key or timeout for user error recovery
4. **Delegation**: Clean separation between key detection and command execution

### 3. Base Application Architecture - The Orchestration Layer

**Design Pattern**: Model-View-Controller with Event-Driven Architecture

**Why This Structure**:
- **Single Responsibility**: Each component has a clear purpose
- **Testability**: Components can be mocked and tested independently
- **Maintainability**: Clear boundaries between concerns
- **Extensibility**: Easy to add new views and commands

**Core Components**:

```swift
class SachelGitApp: LeaderKeyDelegate {
    private let terminal = Terminal()           // Infrastructure
    private var currentView: View?              // Current display
    private let leaderKeyManager = LeaderKeyManager()  // Input handling
    private var repository: GitRepository?     // Data layer
    
    // Why delegation: Loose coupling between components
    // Why optional repository: Graceful handling of non-git directories
    // Why single current view: Simple state management
}
```

**Event Flow Design**:
1. **Terminal** captures raw input
2. **LeaderKeyManager** processes key sequences
3. **App** routes commands to appropriate **Views**
4. **Views** interact with **GitRepository** for data
5. **Views** render updates back through **Terminal**

## 📊 Data Models & Git Integration

### Data Model Design Philosophy

**Principle**: Domain-Driven Design with Immutable Data Structures

**Why Immutable**: 
- Simplifies state management
- Prevents accidental mutations
- Makes testing predictable
- Enables safe concurrent operations

**Core Models**:

```swift
struct FileStatus: Equatable {  // Why Equatable: Testing and comparison
    let path: String
    let staged: Bool
    let modified: Bool
    // ... more properties
    
    // Computed properties for UI concerns
    var statusIndicator: String { }
    var statusColor: String { }
    var canStage: Bool { }
}
```

**Design Decisions**:
1. **Separation of Concerns**: Data models are pure - no UI logic
2. **Computed Properties**: UI-specific logic derived from data
3. **Value Types**: Structs for simple data, classes for complex behavior
4. **Protocols**: Common interfaces for testability

### Git Integration Strategy

**Challenge**: SwiftGit2 dependency management and abstraction

**Solution**: Repository Pattern with Mock Implementation

```swift
class GitRepository {
    // Base implementation with default behavior
    func status() throws -> [FileStatus] { return [] }
    func diff() throws -> [FileDiff] { return [] }
    // ...
}

class MockGitRepository: GitRepository {
    // Override with test data for demo/testing
    override func status() throws -> [FileStatus] {
        return [/* mock data */]
    }
}
```

**Why This Pattern**:
1. **Testability**: Easy to inject mock data
2. **Development**: Work without real git repository
3. **Isolation**: UI development independent of git complexity
4. **Flexibility**: Easy to swap implementations

## 🖼️ View System Architecture

### View Protocol Design

**Philosophy**: Consistent Interface with Flexible Implementation

```swift
protocol View {
    var title: String { get }           // For status bar display
    func render(terminal: Terminal)     // Display logic
    func handleKey(_ key: Key)         // Input handling
}
```

**Why This Interface**:
- **Consistency**: All views behave predictably
- **Composability**: Easy to switch between views
- **Testability**: Can mock terminal for testing
- **Simplicity**: Minimal required interface

### Base View Implementation

**Design Pattern**: Template Method with Hook Points

```swift
class BaseView: View {
    func renderHeader(terminal: Terminal, subtitle: String = "")
    func renderFooter(terminal: Terminal, helpText: String)
    func centerText(_ text: String, width: Int) -> String
    
    // Why template methods: Common UI patterns across views
    // Why hook points: Customization without duplication
}
```

### StatusView - The Foundation View

**Why Start Here**: Simplest view that demonstrates all core patterns

**Design Challenges**:
1. **File Grouping**: Separate staged vs unstaged files
2. **Navigation**: Keyboard-driven selection
3. **Actions**: Stage/unstage operations
4. **Async Operations**: Non-blocking git operations

**Implementation Strategy**:

```swift
class StatusView: BaseView {
    private var files: [FileStatus] = []
    private var selectedIndex = 0
    private var isLoading = false
    
    // Why separate loading state: User feedback for slow operations
    // Why selected index: Simple navigation model
    // Why private vars: Encapsulation of view state
}
```

**Key Patterns Established**:
1. **Async Loading**: Background git operations with loading states
2. **Error Handling**: Graceful display of error messages
3. **Navigation**: j/k keys for vim-style movement
4. **Visual Feedback**: Color coding and selection indicators

### DiffView - The Most Complex View

**Complexity Sources**:
1. **Multi-level Navigation**: Files → Hunks → Lines
2. **Mode Switching**: Staged vs unstaged diffs
3. **Line Selection**: Interactive hunk staging
4. **State Management**: Multiple selection modes

**Architectural Solutions**:

```swift
enum DiffViewMode {
    case unstaged, staged
}

class DiffView: BaseView {
    private var fileDiffs: [FileDiff] = []
    private var currentFileIndex = 0      // File navigation
    private var currentHunkIndex = 0      // Hunk navigation
    private var mode: DiffViewMode = .unstaged
    private var selectedLines: Set<Int> = []  // Line selection
    private var isLineSelectionMode = false
    
    // Why separate indices: Independent navigation levels
    // Why mode enum: Clear state distinction
    // Why line selection: Fine-grained staging control
}
```

**Navigation Design**:
- `j/k`: Navigate hunks (common operation)
- `J/K`: Navigate files (less common, shift modifier)
- `v`: Enter line selection (visual mode, vim-inspired)
- `Tab`: Switch modes (quick toggle)

**State Management Strategy**:
1. **Mode Tracking**: Clear distinction between normal and line-selection modes
2. **Index Management**: Bounds checking for all navigation
3. **Reset Logic**: Clear selections when changing context
4. **Visual Feedback**: Different colors for different states

### CommitView - The Text Editor

**Challenge**: Implementing a text editor within the TUI

**Design Inspiration**: Vim's modal editing (insert/normal modes)

**Implementation Architecture**:

```swift
enum CommitMode {
    case normal, insert
}

class CommitView: BaseView {
    private var commitMessage = ""
    private var mode: CommitMode = .normal
    private var cursorPosition = 0
    
    // Why cursor position: Text editing requires precise cursor control
    // Why modes: Clear separation of navigation vs editing
}
```

**Text Editing Features**:
1. **Cursor Movement**: Arrow keys for navigation
2. **Text Insertion**: Character-by-character input
3. **Deletion**: Backspace with bounds checking
4. **Word Wrapping**: Automatic line breaks for display
5. **History**: Up/down arrow for message templates

**Modal Interface Benefits**:
- **Safety**: Can't accidentally edit in normal mode
- **Efficiency**: Navigation commands work in normal mode
- **Familiarity**: Vim users feel at home

## 🎨 Polish & Enhancement Phase

### Syntax Highlighting System

**Design Goal**: Extensible highlighting for multiple languages

**Architecture**:

```swift
enum Language: String, CaseIterable {
    case swift, python, javascript, rust, go
    // Why enum: Type safety and exhaustive handling
    // Why CaseIterable: Easy to iterate for detection
    
    var keywords: [String] { }
    var commentPrefixes: [String] { }
    // Why computed properties: Language-specific rules
}

struct SyntaxHighlighter {
    static func highlight(_ text: String, language: Language) -> String
    // Why static: Pure function with no state
    // Why string return: Terminal output with ANSI codes
}
```

**Implementation Strategy**:
1. **Regex-Based**: Pattern matching for syntax elements
2. **Layered**: Apply highlighting in order (keywords, strings, comments)
3. **Language Detection**: File extension mapping
4. **Performance**: Only highlight visible lines

### Color Theming System

**Design Philosophy**: Semantic Colors with Theme Abstraction

```swift
struct Theme {
    static let addedLines = ANSICode.brightGreen
    static let removedLines = ANSICode.brightRed
    static let stagedItems = ANSICode.brightCyan
    
    // Why semantic names: Intention over implementation
    // Why static: Global constants for consistency
    // Why ANSI codes: Direct terminal compatibility
}
```

**Benefits**:
1. **Consistency**: All views use same color meanings
2. **Maintainability**: Change colors in one place
3. **Accessibility**: Easy to modify for color blindness
4. **Extensibility**: Can add themes later

### Testing Strategy

**Philosophy**: High Coverage with Practical Focus

**Testing Approaches**:
1. **Unit Tests**: Individual component behavior
2. **Mock Objects**: Isolate dependencies
3. **Integration Tests**: Component interaction
4. **Property-Based**: Edge case discovery

**Mock Strategy**:

```swift
class MockGitRepository: GitRepository {
    var mockFiles: [FileStatus] = []
    var stageFileCalled = false
    var lastStagedFile: String?
    
    // Why flags: Verify interactions occurred
    // Why capture args: Assert correct parameters
    // Why mock data: Predictable test scenarios
}
```

**Test Organization**:
- One test file per major component
- Clear test method names describing behavior
- Setup/teardown for consistent state
- Both positive and negative test cases

## 🔧 Build System & Dependencies

### Dependency Management Philosophy

**Challenge**: External dependencies (SwiftGit2, Splash) vs Demo Simplicity

**Solution**: Layered Dependency Strategy

1. **Full Implementation**: Real SwiftGit2 integration
2. **Demo Version**: Mock implementations for testing
3. **Conditional Imports**: `#if canImport()` guards
4. **Package Variants**: Simple vs full package configurations

**Why This Approach**:
- **Development**: Work without complex dependencies
- **Testing**: Predictable, fast test execution
- **Deployment**: Full functionality when needed
- **Documentation**: Easy to demonstrate features

### Error Handling & Recovery

**Strategy**: Graceful Degradation with User Feedback

```swift
private func refresh() {
    isLoading = true
    errorMessage = ""
    
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        do {
            let status = try self?.repository.status() ?? []
            DispatchQueue.main.async {
                self?.files = status
                self?.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
            }
        }
    }
}
```

**Error Handling Principles**:
1. **User Feedback**: Always show what went wrong
2. **Recovery**: Provide ways to retry operations
3. **State Consistency**: Never leave UI in broken state
4. **Async Safety**: Proper thread handling for UI updates

## 🎯 Key Engineering Insights

### 1. Progressive Enhancement Strategy

**Approach**: Build working foundation, then add sophistication

**Example**: Terminal control → Key detection → Leader keys → Views → Polish

**Benefits**:
- Always have working system
- Easy to identify where problems are introduced
- Can ship at any level of completeness
- Confidence builds with each working layer

### 2. Separation of Concerns

**Example**: Terminal management vs View logic vs Git operations

**Result**: Each component has single responsibility and clear interfaces

### 3. Mock-First Development

**Strategy**: Build mock implementations alongside real ones

**Benefits**:
- Faster development cycle
- Better error handling (controlled failure scenarios)
- Easier testing and demonstration
- Cleaner interfaces (forced to think about abstraction)

### 4. User Experience Focus

**Decisions Driven By**:
- Keyboard efficiency (vim-style navigation)
- Visual feedback (colors, selections, loading states)
- Error recovery (graceful handling, retry mechanisms)
- Discoverability (help system, visual hints)

### 5. Performance Considerations

**Design Choices**:
- Lazy loading for large diffs
- Background async operations
- Efficient terminal rendering
- Minimal memory allocation in tight loops

## 🚀 Lessons Learned

### What Worked Well

1. **Bottom-Up Architecture**: Building solid foundation first
2. **Test-Driven Development**: Prevented regressions during refactoring
3. **Mock-First Strategy**: Enabled rapid iteration and testing
4. **Progressive Enhancement**: Always had working system
5. **Clear Interfaces**: Made components easy to understand and test

### What I'd Do Differently

1. **Earlier Requirement Analysis**: Could have avoided initial GUI mistake
2. **More Upfront Design**: Some refactoring could have been avoided
3. **Performance Testing**: Earlier load testing with large repositories
4. **Accessibility**: More consideration for different terminal capabilities

### Key Technical Achievements

1. **Complete TUI Framework**: Raw terminal control to high-level views
2. **Complex Interaction Model**: Multi-level navigation with mode switching
3. **Robust Error Handling**: Graceful degradation in all scenarios
4. **Extensible Architecture**: Easy to add new views and commands
5. **Comprehensive Testing**: High confidence in correctness

## 🔮 Future Enhancements

### Technical Debt to Address

1. **Real Git Integration**: Replace mocks with full SwiftGit2 implementation
2. **Performance Optimization**: Profile and optimize for large repositories
3. **Platform Support**: Test on Linux, expand terminal compatibility
4. **Accessibility**: Screen reader support, high contrast modes

### Feature Extensions

1. **Advanced Git Operations**: Rebase, merge, cherry-pick interfaces
2. **Configuration System**: User-customizable keybindings and themes
3. **Plugin Architecture**: Swift-based extension system
4. **Multi-Repository**: Workspace support for multiple repos

---

## Conclusion

This project demonstrates how careful architectural planning, progressive enhancement, and user-centered design can create sophisticated software. The key was building reliable foundations and then layering functionality while maintaining simplicity and usability.

The most important insight: **Start with the hardest infrastructure problems first**. Terminal control and keyboard handling were the highest-risk components. Once those worked reliably, everything else became much easier to implement and debug.

The result is a fully functional, extensible TUI application that demonstrates professional-level software engineering practices while remaining approachable and maintainable.