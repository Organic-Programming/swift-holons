import Foundation

public struct CertificationInvocation: Equatable {
    public let command: String
    public let arguments: [String]
    public let currentDirectoryPath: String
    public let environment: [String: String]

    public init(
        command: String,
        arguments: [String],
        currentDirectoryPath: String,
        environment: [String: String]
    ) {
        self.command = command
        self.arguments = arguments
        self.currentDirectoryPath = currentDirectoryPath
        self.environment = environment
    }
}

public enum CertificationCLIError: Error, CustomStringConvertible {
    case launchFailed(String)

    public var description: String {
        switch self {
        case let .launchFailed(message):
            return "process launch failed: \(message)"
        }
    }
}

public enum CertificationCLI {
    public static let sdkName = "swift-holons"
    public static let serverSDKName = "go-holons"
    public static let preferredGoBinary = "/Users/bpds/go/go1.25.1/bin/go"
    public static let defaultGoCache = "/tmp/go-cache"

    public static func packageRoot(from sourceFilePath: String = #filePath) -> URL {
        URL(fileURLWithPath: sourceFilePath)
            .deletingLastPathComponent() // Holons
            .deletingLastPathComponent() // Sources
            .deletingLastPathComponent() // swift-holons
    }

    public static func sdkRoot(packageRoot: URL = packageRoot()) -> URL {
        packageRoot.deletingLastPathComponent()
    }

    public static func goHolonsDirectory(packageRoot: URL = packageRoot()) -> URL {
        sdkRoot(packageRoot: packageRoot).appendingPathComponent("go-holons", isDirectory: true)
    }

    public static func echoClientHelperPath(packageRoot: URL = packageRoot()) -> URL {
        sdkRoot(packageRoot: packageRoot)
            .appendingPathComponent("js-web-holons", isDirectory: true)
            .appendingPathComponent("cmd", isDirectory: true)
            .appendingPathComponent("echo-client-go", isDirectory: true)
            .appendingPathComponent("main.go")
    }

    public static func resolveGoBinary(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> String {
        if let configured = environment["GO_BIN"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !configured.isEmpty {
            return configured
        }
        if FileManager.default.isExecutableFile(atPath: preferredGoBinary) {
            return preferredGoBinary
        }
        return "go"
    }

    public static func makeEchoClientInvocation(
        userArgs: [String],
        environment: [String: String] = ProcessInfo.processInfo.environment,
        packageRoot: URL = packageRoot()
    ) -> CertificationInvocation {
        var arguments: [String] = [
            "run",
            echoClientHelperPath(packageRoot: packageRoot).path,
            "--sdk", sdkName,
            "--server-sdk", serverSDKName,
        ]
        arguments.append(contentsOf: userArgs)

        var env = environment
        if env["GOCACHE"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            env["GOCACHE"] = defaultGoCache
        }

        return CertificationInvocation(
            command: resolveGoBinary(environment: environment),
            arguments: arguments,
            currentDirectoryPath: goHolonsDirectory(packageRoot: packageRoot).path,
            environment: env
        )
    }

    public static func makeEchoServerInvocation(
        userArgs: [String],
        version: String = Holons.version,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        packageRoot: URL = packageRoot()
    ) -> CertificationInvocation {
        var arguments: [String] = ["run", "./cmd/echo-server"]
        arguments.append(contentsOf: userArgs)

        if !containsFlag(userArgs, named: "--sdk") {
            arguments.append(contentsOf: ["--sdk", sdkName])
        }
        if !containsFlag(userArgs, named: "--version") {
            arguments.append(contentsOf: ["--version", version])
        }

        var env = environment
        if env["GOCACHE"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            env["GOCACHE"] = defaultGoCache
        }

        return CertificationInvocation(
            command: resolveGoBinary(environment: environment),
            arguments: arguments,
            currentDirectoryPath: goHolonsDirectory(packageRoot: packageRoot).path,
            environment: env
        )
    }

    public static func run(_ invocation: CertificationInvocation) throws -> Int32 {
        let process = Process()
        if invocation.command.contains("/") {
            process.executableURL = URL(fileURLWithPath: invocation.command)
            process.arguments = invocation.arguments
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [invocation.command] + invocation.arguments
        }

        process.currentDirectoryURL = URL(fileURLWithPath: invocation.currentDirectoryPath)
        process.environment = invocation.environment
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        do {
            try process.run()
        } catch {
            throw CertificationCLIError.launchFailed("\(invocation.command): \(error)")
        }

        process.waitUntilExit()
        return process.terminationStatus
    }

    public static func containsFlag(_ args: [String], named name: String) -> Bool {
        args.contains { arg in
            arg == name || arg.hasPrefix("\(name)=")
        }
    }
}
