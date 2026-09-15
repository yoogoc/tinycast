import Foundation

@main
@MainActor
struct TextTransformTests {
    static var failures = 0
    static var passes = 0

    static func expect(_ actual: TextTransformResult.Payload, _ expected: String, _ message: String) {
        if actual == .value(expected) {
            passes += 1
        } else {
            failures += 1
            print("FAIL: \(message) — got \(actual), want \(expected)")
        }
    }

    static func expectError(_ actual: TextTransformResult.Payload, _ message: String) {
        if case .error = actual {
            passes += 1
        } else {
            failures += 1
            print("FAIL: \(message) — got \(actual), want an error")
        }
    }

    static func expect(_ condition: Bool, _ message: String) {
        expect(condition, true, message)
    }

    static func result(_ input: String, _ transform: TextTransform) -> TextTransformResult.Payload {
        TextTransformEngine.evaluate(input, using: transform).payload
    }

    static func main() {
        expect(
            TextTransform.allCases.map(\.category),
            [.encoding, .encoding, .encoding, .encoding, .encoding, .encoding, .token,
             .hash, .hash, .hash, .hash],
            "transform rows stay grouped in visible order")

        expect(result("hello", .base64Encode), "aGVsbG8=", "Base64 encodes ASCII")
        expect(result("你好", .base64Encode), "5L2g5aW9", "Base64 encodes UTF-8")
        expect(result("aGVsbG8=", .base64Decode), "hello", "Base64 decodes text")
        expect(result("aG Vs\nbG8=", .base64Decode), "hello", "Base64 ignores whitespace")
        expectError(result("not base64!", .base64Decode), "malformed Base64 is rejected")
        expectError(result("/w==", .base64Decode), "binary Base64 is rejected as text")

        expect(
            result("AZaz09-._~", .urlEncode), "AZaz09-._~",
            "URL encoding preserves only unreserved ASCII")
        expect(
            result("hello world?x=1&y=2", .urlEncode), "hello%20world%3Fx%3D1%26y%3D2",
            "URL encoding escapes spaces and reserved characters")
        expect(result("你好", .urlEncode), "%E4%BD%A0%E5%A5%BD", "URL encoding uses UTF-8")
        expect(
            result("hello%20world%3Fx%3D1%26y%3D2", .urlDecode), "hello world?x=1&y=2",
            "URL decoding reverses percent encoding")
        expect(result("a+b", .urlDecode), "a+b", "URL decoding preserves plus signs")
        expectError(result("bad%2", .urlDecode), "malformed percent encoding is rejected")
        expectError(result("%FF", .urlDecode), "non-UTF-8 percent encoding is rejected")

        expect(
            result("line\n\"\\", .jsonEscape), "line\\n\\\"\\\\",
            "JSON escaping handles controls, quotes, and backslashes")
        expect(
            result("line\\n\\\"\\\\", .jsonUnescape), "line\n\"\\",
            "JSON unescaping accepts content without surrounding quotes")
        expect(
            result("\"hello\\nworld\"", .jsonUnescape), "hello\nworld",
            "JSON unescaping accepts a complete JSON string")
        expectError(result("\\x", .jsonUnescape), "invalid JSON escapes are rejected")

        let token =
            "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0."
            + "eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9."
        switch result(token, .jwtDecode) {
        case .value(let decoded):
            let object = try? JSONSerialization.jsonObject(with: Data(decoded.utf8))
                as? [String: Any]
            let header = object?["header"] as? [String: Any]
            let payload = object?["payload"] as? [String: Any]
            expect(
                header?["alg"] as? String == "none"
                    && payload?["sub"] as? String == "1234567890"
                    && payload?["admin"] as? Bool == true,
                "JWT decoding returns its JSON header and payload")
        case .error(let message):
            expect(false, "valid JWT decodes — got \(message)")
        }
        expectError(result("one.two", .jwtDecode), "JWT requires three segments")
        expectError(result("bad!.also-bad.", .jwtDecode), "JWT rejects invalid Base64URL")

        expect(
            result("hello", .md5), "5d41402abc4b2a76b9719d911017c592",
            "MD5 hashes UTF-8 input")
        expect(
            result("hello", .sha1), "aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d",
            "SHA-1 hashes UTF-8 input")
        expect(
            result("hello", .sha256),
            "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
            "SHA-256 hashes UTF-8 input")
        expect(
            result("hello", .sha512),
            "9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca7"
                + "2323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043",
            "SHA-512 hashes UTF-8 input")

        print("\(passes) passed, \(failures) failed")
        if failures > 0 { exit(1) }
    }

    static func expect<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
        if actual == expected {
            passes += 1
        } else {
            failures += 1
            print("FAIL: \(message) — got \(actual), want \(expected)")
        }
    }
}
