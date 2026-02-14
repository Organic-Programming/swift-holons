import Foundation
import XCTest
@testable import Holons

final class CertificationCLITests: XCTestCase {
    private var packageRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // HolonsTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // swift-holons
    }

    func testResolveGoBinaryUsesEnvironmentOverride() {
        let binary = CertificationCLI.resolveGoBinary(
            environment: ["GO_BIN": " /opt/custom/go "]
        )
        XCTAssertEqual(binary, "/opt/custom/go")
    }

    func testEchoClientInvocationDefaults() {
        let invocation = CertificationCLI.makeEchoClientInvocation(
            userArgs: ["stdio://", "--message", "cert"],
            environment: ["GO_BIN": "go-custom"],
            packageRoot: packageRoot
        )

        let helperPath = packageRoot
            .deletingLastPathComponent() // sdk
            .appendingPathComponent("js-web-holons")
            .appendingPathComponent("cmd")
            .appendingPathComponent("echo-client-go")
            .appendingPathComponent("main.go")

        XCTAssertEqual(invocation.command, "go-custom")
        XCTAssertEqual(
            invocation.currentDirectoryPath,
            packageRoot.deletingLastPathComponent().appendingPathComponent("go-holons").path
        )
        XCTAssertEqual(invocation.arguments[0], "run")
        XCTAssertEqual(invocation.arguments[1], helperPath.path)
        XCTAssertEqual(invocation.arguments[2], "--sdk")
        XCTAssertEqual(invocation.arguments[3], "swift-holons")
        XCTAssertEqual(invocation.arguments[4], "--server-sdk")
        XCTAssertEqual(invocation.arguments[5], "go-holons")
        XCTAssertEqual(Array(invocation.arguments.suffix(3)), ["stdio://", "--message", "cert"])
        XCTAssertEqual(invocation.environment["GOCACHE"], "/tmp/go-cache")
    }

    func testEchoClientInvocationPreservesGOCache() {
        let invocation = CertificationCLI.makeEchoClientInvocation(
            userArgs: [],
            environment: ["GO_BIN": "go-custom", "GOCACHE": "/custom/cache"],
            packageRoot: packageRoot
        )

        XCTAssertEqual(invocation.environment["GOCACHE"], "/custom/cache")
    }

    func testEchoServerInvocationAddsDefaults() {
        let invocation = CertificationCLI.makeEchoServerInvocation(
            userArgs: ["--listen", "stdio://"],
            version: "1.2.3",
            environment: ["GO_BIN": "go-custom"],
            packageRoot: packageRoot
        )

        XCTAssertEqual(invocation.command, "go-custom")
        XCTAssertEqual(invocation.arguments[0], "run")
        XCTAssertEqual(invocation.arguments[1], "./cmd/echo-server")
        XCTAssertTrue(invocation.arguments.contains("--sdk"))
        XCTAssertTrue(invocation.arguments.contains("swift-holons"))
        XCTAssertTrue(invocation.arguments.contains("--version"))
        XCTAssertTrue(invocation.arguments.contains("1.2.3"))
    }

    func testEchoServerInvocationRespectsOverrides() {
        let invocation = CertificationCLI.makeEchoServerInvocation(
            userArgs: [
                "--sdk", "custom-sdk",
                "--version=9.9.9",
            ],
            environment: ["GO_BIN": "go-custom"],
            packageRoot: packageRoot
        )

        XCTAssertEqual(invocation.arguments.filter { $0 == "--sdk" }.count, 1)
        XCTAssertEqual(invocation.arguments.filter { $0 == "--version" }.count, 0)
        XCTAssertTrue(invocation.arguments.contains("--version=9.9.9"))
    }
}
