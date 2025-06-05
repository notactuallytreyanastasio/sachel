import Foundation

protocol View {
    var title: String { get }
    func render(terminal: Terminal)
    func handleKey(_ key: Key)
}

class BaseView: View {
    let title: String
    
    init(title: String) {
        self.title = title
    }
    
    func render(terminal: Terminal) {
        // Default implementation - subclasses should override
        terminal.clearScreen()
        terminal.moveCursor(row: 1, col: 1)
        terminal.write("Base View - Override render() method")
    }
    
    func handleKey(_ key: Key) {
        // Default implementation - subclasses should override
    }
    
    func renderHeader(terminal: Terminal, subtitle: String = "") {
        let size = terminal.size
        terminal.moveCursor(row: 1, col: 1)
        
        let headerText = subtitle.isEmpty ? title : "\(title) - \(subtitle)"
        terminal.write(ANSICode.brightBlue + headerText + ANSICode.reset)
        
        terminal.moveCursor(row: 2, col: 1)
        terminal.write(String(repeating: "─", count: min(headerText.count, size.width)))
    }
    
    func renderFooter(terminal: Terminal, helpText: String) {
        let size = terminal.size
        terminal.moveCursor(row: size.height - 3, col: 1)
        terminal.write(String(repeating: "─", count: size.width))
        
        terminal.moveCursor(row: size.height - 2, col: 1)
        terminal.write(ANSICode.cyan + helpText + ANSICode.reset)
    }
    
    func centerText(_ text: String, width: Int) -> String {
        let padding = max(0, width - text.count) / 2
        return String(repeating: " ", count: padding) + text
    }
}