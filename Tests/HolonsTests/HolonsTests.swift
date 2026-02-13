import XCTest
@testable import Holons

final class HolonsTests: XCTestCase {
    func testSchemeExtraction() {
        XCTAssertEqual(Transport.scheme("tcp://:9090"), "tcp")
        XCTAssertEqual(Transport.scheme("unix:///tmp/x.sock"), "unix")
        XCTAssertEqual(Transport.scheme("stdio://"), "stdio")
        XCTAssertEqual(Transport.scheme("mem://"), "mem")
        XCTAssertEqual(Transport.scheme("ws://localhost:8080"), "ws")
        XCTAssertEqual(Transport.scheme("wss://localhost:8443"), "wss")
    }

    func testTransportParse() throws {
        let tcp = try Transport.parse("tcp://127.0.0.1:9000")
        XCTAssertEqual(tcp.scheme, "tcp")
        XCTAssertEqual(tcp.host, "127.0.0.1")
        XCTAssertEqual(tcp.port, 9000)

        let ws = try Transport.parse("ws://127.0.0.1:8080")
        XCTAssertEqual(ws.path, "/grpc")

        let wss = try Transport.parse("wss://example.com:8443/holon")
        XCTAssertEqual(wss.scheme, "wss")
        XCTAssertEqual(wss.path, "/holon")
    }

    func testListenVariants() throws {
        XCTAssertEqual(try Transport.listen("stdio://"), .stdio)
        XCTAssertEqual(try Transport.listen("mem://test"), .mem(name: "test"))
        XCTAssertEqual(try Transport.listen("unix:///tmp/test.sock"), .unix(path: "/tmp/test.sock"))
        XCTAssertEqual(try Transport.listen("tcp://:9090"), .tcp(host: "0.0.0.0", port: 9090))
    }

    func testParseFlags() {
        XCTAssertEqual(Serve.parseFlags(["--listen", "tcp://:8080"]), "tcp://:8080")
        XCTAssertEqual(Serve.parseFlags(["--port", "3000"]), "tcp://:3000")
        XCTAssertEqual(Serve.parseFlags([]), Transport.defaultURI)
    }

    func testIdentityParse() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("holons_test_\(UUID().uuidString).md")
        let content = """
        ---
        uuid: \"abc-123\"
        given_name: \"swift-holon\"
        lang: \"swift\"
        parents: [\"a\", \"b\"]
        aliases: [\"s1\"]
        ---
        # Swift Holon
        """

        try content.write(to: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let id = try Identity.parseHolon(tmp.path)
        XCTAssertEqual(id.uuid, "abc-123")
        XCTAssertEqual(id.givenName, "swift-holon")
        XCTAssertEqual(id.lang, "swift")
        XCTAssertEqual(id.parents, ["a", "b"])
        XCTAssertEqual(id.aliases, ["s1"])
    }
}
