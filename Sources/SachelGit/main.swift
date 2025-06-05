import Foundation

do {
    let app = try SachelGitApp()
    app.run()
} catch {
    print("Error: \(error)")
    exit(1)
}