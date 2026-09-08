import CryptoKit
import Foundation

enum TextTransformEngine {
    private static let hexDigits = Array("0123456789ABCDEF".utf8)

    static func evaluate(_ input: String, using transform: TextTransform) -> TextTransformResult {
        let payload: TextTransformResult.Payload = switch transform {
        case .base64Encode:
            .value(Data(input.utf8).base64EncodedString())
        case .base64Decode:
            decodeBase64(input)
        case .urlEncode:
            .value(encodeURLComponent(input))
        case .urlDecode:
            input.removingPercentEncoding.map(TextTransformResult.Payload.value)
                ?? .error("Invalid percent encoding")
        case .jsonEscape:
            escapeJSON(input)
        case .jsonUnescape:
            unescapeJSON(input)
        case .jwtDecode:
            decodeJWT(input)
        case .md5:
            .value(hex(Insecure.MD5.hash(data: Data(input.utf8))))
        case .sha1:
            .value(hex(Insecure.SHA1.hash(data: Data(input.utf8))))
        case .sha256:
            .value(hex(SHA256.hash(data: Data(input.utf8))))
        case .sha512:
            .value(hex(SHA512.hash(data: Data(input.utf8))))
        }
        return TextTransformResult(transform: transform, payload: payload)
    }

    private static func decodeBase64(_ input: String) -> TextTransformResult.Payload {
        let compact = input.filter { !$0.isWhitespace }
        guard let data = Data(base64Encoded: compact) else { return .error("Invalid Base64") }
        guard let decoded = String(bytes: data, encoding: .utf8) else {
            return .error("Decoded value is not UTF-8 text")
        }
        return .value(decoded)
    }

    private static func encodeURLComponent(_ input: String) -> String {
        var encoded = ""
        encoded.reserveCapacity(input.utf8.count)
        for byte in input.utf8 {
            if isUnreserved(byte) {
                encoded.unicodeScalars.append(UnicodeScalar(byte))
            } else {
                encoded.append("%")
                encoded.unicodeScalars.append(UnicodeScalar(hexDigits[Int(byte >> 4)]))
                encoded.unicodeScalars.append(UnicodeScalar(hexDigits[Int(byte & 0x0F)]))
            }
        }
        return encoded
    }

    private static func isUnreserved(_ byte: UInt8) -> Bool {
        byte >= 0x41 && byte <= 0x5A || byte >= 0x61 && byte <= 0x7A
            || byte >= 0x30 && byte <= 0x39 || byte == 0x2D || byte == 0x2E
            || byte == 0x5F || byte == 0x7E
    }

    private static func escapeJSON(_ input: String) -> TextTransformResult.Payload {
        guard let data = try? JSONEncoder().encode(input),
            let quoted = String(bytes: data, encoding: .utf8), quoted.count >= 2
        else { return .error("Couldn't encode JSON string") }
        return .value(String(quoted.dropFirst().dropLast()))
    }

    private static func unescapeJSON(_ input: String) -> TextTransformResult.Payload {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"")
            ? trimmed : "\"\(input)\""
        guard let decoded = try? JSONDecoder().decode(String.self, from: Data(source.utf8)) else {
            return .error("Invalid JSON string escape")
        }
        return .value(decoded)
    }

    private static func decodeJWT(_ input: String) -> TextTransformResult.Payload {
        let segments = input.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count == 3, !segments[0].isEmpty, !segments[1].isEmpty else {
            return .error("JWT must contain header, payload, and signature segments")
        }
        guard let headerData = decodeBase64URL(segments[0]),
            let payloadData = decodeBase64URL(segments[1])
        else { return .error("Invalid JWT Base64URL") }
        guard let header = try? JSONSerialization.jsonObject(with: headerData),
            let payload = try? JSONSerialization.jsonObject(with: payloadData),
            let outputData = try? JSONSerialization.data(
                withJSONObject: ["header": header, "payload": payload],
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
            let output = String(bytes: outputData, encoding: .utf8)
        else { return .error("JWT header or payload is not JSON") }
        return .value(output)
    }

    private static func decodeBase64URL(_ segment: Substring) -> Data? {
        var encoded = segment.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = encoded.utf8.count % 4
        guard remainder != 1 else { return nil }
        if remainder > 0 { encoded.append(String(repeating: "=", count: 4 - remainder)) }
        return Data(base64Encoded: encoded)
    }

    private static func hex<Digest: Sequence>(_ digest: Digest) -> String
    where Digest.Element == UInt8 {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}
