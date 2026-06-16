import Foundation

extension URL {
    /// The folder to act on for a Finder item: the URL itself when it already
    /// points at a directory, otherwise the directory that contains it.
    var folderURL: URL {
        var isDirectory = ObjCBool(false)
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
            return self
        }
        return deletingLastPathComponent()
    }
}
