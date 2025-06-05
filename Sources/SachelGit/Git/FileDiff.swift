import Foundation

struct FileDiff {
    let path: String
    let hunks: [Hunk]
    
    var totalAdditions: Int {
        return hunks.reduce(0) { $0 + $1.additionCount }
    }
    
    var totalDeletions: Int {
        return hunks.reduce(0) { $0 + $1.deletionCount }
    }
}