import Foundation

enum FindexCommand: String {
    case copyFilePath
    case copyFolderPath
    case openTerminal
    case openEditor
    case applyViewPreset
}

struct FindexRequest {
    let command: FindexCommand
    let folderPath: String?
    let filePaths: [String]
}

enum FindexURL {
    static let scheme = "findex"
    static let host = "run"

    static func make(command: FindexCommand, folderURL: URL?, fileURLs: [URL]) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host

        var items = [URLQueryItem(name: "action", value: command.rawValue)]
        if let folderURL {
            items.append(URLQueryItem(name: "folder", value: folderURL.path))
        }
        for fileURL in fileURLs {
            items.append(URLQueryItem(name: "path", value: fileURL.path))
        }
        components.queryItems = items
        return components.url
    }

    static func parse(_ url: URL) -> FindexRequest? {
        guard url.scheme == scheme, url.host == host else {
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        guard
            let action = items.first(where: { $0.name == "action" })?.value,
            let command = FindexCommand(rawValue: action)
        else {
            return nil
        }

        let folderPath = items.first(where: { $0.name == "folder" })?.value
        let filePaths = items
            .filter { $0.name == "path" }
            .compactMap(\.value)

        return FindexRequest(command: command, folderPath: folderPath, filePaths: filePaths)
    }
}

