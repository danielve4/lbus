import Foundation
@testable import LBus

actor MockAPIClient: APIClientProtocol {
    private(set) var getResult: Any?
    private(set) var getError: Error?
    private(set) var getCallCount = 0
    private(set) var lastPath: String?
    private(set) var lastQueryItems: [URLQueryItem]?

    private(set) var postResult: Any?
    private(set) var postError: Error?
    private(set) var lastPostPath: String?
    private(set) var lastPostBody: (any Encodable & Sendable)?

    func setGetResult(_ value: Any?) { getResult = value }
    func setGetError(_ error: Error?) { getError = error }
    func setPostResult(_ value: Any?) { postResult = value }
    func setPostError(_ error: Error?) { postError = error }

    func get<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        getCallCount += 1
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
