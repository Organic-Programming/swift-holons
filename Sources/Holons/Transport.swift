import Foundation

public enum TransportError: Error, CustomStringConvertible {
    case unsupportedURI(String)
    case invalidURI(String)

    public var description: String {
        switch self {
        case let .unsupportedURI(uri):
            return "unsupported transport URI: \(uri)"
        case let .invalidURI(uri):
            return "invalid transport URI: \(uri)"
        }
    }
}

public enum TransportScheme: String, CaseIterable {
    case tcp
    case unix
    case stdio
    case mem
    case ws
    case wss

    public static func from(_ uri: String) -> String {
        guard let idx = uri.range(of: "://") else {
            return uri
        }
        return String(uri[..<idx.lowerBound])
    }
}

public struct TransportURI: Equatable {
    public let raw: String
    public let scheme: String
    public let host: String?
    public let port: Int?
    public let path: String?

    public init(raw: String, scheme: String, host: String? = nil, port: Int? = nil, path: String? = nil) {
        self.raw = raw
        self.scheme = scheme
        self.host = host
        self.port = port
        self.path = path
    }
}

public enum Listener: Equatable {
    case tcp(host: String, port: Int)
    case unix(path: String)
    case stdio
    case mem(name: String)
    case ws(host: String, port: Int, path: String, secure: Bool)
}

public enum Transport {
    public static let defaultURI = "tcp://:9090"

    public static func scheme(_ uri: String) -> String {
        TransportScheme.from(uri)
    }

    public static func parse(_ uri: String) throws -> TransportURI {
        let s = scheme(uri)

        switch s {
        case "tcp":
            let value = String(uri.dropFirst("tcp://".count))
            let split = splitHostPort(value, defaultPort: 9090)
            return TransportURI(raw: uri, scheme: s, host: split.host, port: split.port)
        case "unix":
            let path = String(uri.dropFirst("unix://".count))
            guard !path.isEmpty else { throw TransportError.invalidURI(uri) }
            return TransportURI(raw: uri, scheme: s, path: path)
        case "stdio":
            return TransportURI(raw: "stdio://", scheme: "stdio")
        case "mem":
            let name = uri.hasPrefix("mem://") ? String(uri.dropFirst("mem://".count)) : ""
            return TransportURI(raw: uri, scheme: "mem", path: name)
        case "ws", "wss":
            let secure = s == "wss"
            let trimmed = String(uri.dropFirst(secure ? "wss://".count : "ws://".count))
            let pieces = trimmed.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            let addr = String(pieces.first ?? "")
            let path = pieces.count > 1 ? "/" + String(pieces[1]) : "/grpc"
            let split = splitHostPort(addr, defaultPort: secure ? 443 : 80)
            return TransportURI(raw: uri, scheme: s, host: split.host, port: split.port, path: path)
        default:
            throw TransportError.unsupportedURI(uri)
        }
    }

    public static func listen(_ uri: String) throws -> Listener {
        let parsed = try parse(uri)

        switch parsed.scheme {
        case "tcp":
            return .tcp(host: parsed.host ?? "0.0.0.0", port: parsed.port ?? 9090)
        case "unix":
            return .unix(path: parsed.path ?? "")
        case "stdio":
            return .stdio
        case "mem":
            return .mem(name: parsed.path ?? "")
        case "ws", "wss":
            return .ws(
                host: parsed.host ?? "0.0.0.0",
                port: parsed.port ?? (parsed.scheme == "wss" ? 443 : 80),
                path: parsed.path ?? "/grpc",
                secure: parsed.scheme == "wss"
            )
        default:
            throw TransportError.unsupportedURI(uri)
        }
    }

    private static func splitHostPort(_ value: String, defaultPort: Int) -> (host: String, port: Int) {
        guard let idx = value.lastIndex(of: ":") else {
            return (value.isEmpty ? "0.0.0.0" : value, defaultPort)
        }

        let host = String(value[..<idx])
        let portString = String(value[value.index(after: idx)...])
        let hostValue = host.isEmpty ? "0.0.0.0" : host
        let portValue = Int(portString) ?? defaultPort
        return (hostValue, portValue)
    }
}
