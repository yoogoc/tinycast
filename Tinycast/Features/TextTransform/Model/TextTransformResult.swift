import Foundation

struct TextTransformResult: Equatable, Identifiable, Sendable {
    enum Payload: Equatable, Sendable {
        case value(String)
        case error(String)
    }

    let transform: TextTransform
    let payload: Payload

    var id: TextTransform.ID { transform.id }

    var copyText: String? {
        guard case .value(let text) = payload else { return nil }
        return text
    }
}
