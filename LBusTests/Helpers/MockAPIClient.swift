import Foundation
@testable import LBus

final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    var getResult: Any?
    var getError: Error?
    var lastPath: String?
    var lastQueryItems: [URLQueryItem]?

    var postResult: Any?
    var postError: Error?
    var lastPostPath: String?
    var lastPostBody: (any Encodable)?

    func get<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        lastPath = path
        lastQueryItems = queryItems
        if let error = getError { throw error }
        guard let result = getResult as? T else {
            throw APIError.decodingError(
                NSError(domain: "MockAPIClient", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "getResult type mismatch: expected \(T.self)"])
            )
        }
        return result
    }

    func post<T: Decodable, B: Encodable & Sendable>(path: String, body: B) async throws -> T {
        lastPostPath = path
        lastPostBody = body
        if let error = postError { throw error }
        guard let result = postResult as? T else {
            throw APIError.decodingError(
                NSError(domain: "MockAPIClient", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "postResult type mismatch: expected \(T.self)"])
            )
        }
        return result
    }
}
