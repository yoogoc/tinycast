import Foundation

enum TextTransform: String, CaseIterable, Identifiable, Sendable {
    enum Category: String, Sendable {
        case encoding = "Encoding"
        case token = "Token"
        case hash = "Hashes"
    }

    case base64Encode
    case base64Decode
    case urlEncode
    case urlDecode
    case jsonEscape
    case jsonUnescape
    case jwtDecode
    case md5
    case sha1
    case sha256
    case sha512

    var id: String { rawValue }

    var name: String {
        switch self {
        case .base64Encode: return "Base64 Encode"
        case .base64Decode: return "Base64 Decode"
        case .urlEncode: return "URL Encode"
        case .urlDecode: return "URL Decode"
        case .jsonEscape: return "JSON Escape"
        case .jsonUnescape: return "JSON Unescape"
        case .jwtDecode: return "JWT Decode"
        case .md5: return "MD5 Hash"
        case .sha1: return "SHA-1 Hash"
        case .sha256: return "SHA-256 Hash"
        case .sha512: return "SHA-512 Hash"
        }
    }

    var sfSymbol: String {
        switch self {
        case .base64Encode, .urlEncode, .jsonEscape: return "arrow.right"
        case .base64Decode, .urlDecode, .jsonUnescape: return "arrow.left"
        case .jwtDecode: return "key.horizontal"
        case .md5, .sha1, .sha256, .sha512: return "number"
        }
    }

    var category: Category {
        switch self {
        case .base64Encode, .base64Decode, .urlEncode, .urlDecode, .jsonEscape, .jsonUnescape:
            return .encoding
        case .jwtDecode:
            return .token
        case .md5, .sha1, .sha256, .sha512:
            return .hash
        }
    }
}
