import Testing
import Foundation
@testable import LBus

// MARK: - Mock URL Protocol

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var mockResponseData: Data?
    nonisolated(unsafe) static var mockStatusCode: Int = 200
    nonisolated(unsafe) static var mockError: Error?
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastRequestBody: Data?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        Self.lastRequestBody = request.httpBody ?? request.httpBodyStream.flatMap { stream in
            stream.open()
            defer { stream.close() }
            var data = Data()
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let count = stream.read(buffer, maxLength: 1024)
                if count > 0 { data.append(buffer, count: count) }
                else { break }
            }
            return data
        }

        if let error = Self.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.mockStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data = Self.mockResponseData {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        mockResponseData = nil
        mockStatusCode = 200
        mockError = nil
        lastRequest = nil
        lastRequestBody = nil
    }
}

// MARK: - Test Helpers

private func makeClient() -> APIClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: config)
    return APIClient(
        baseURL: URL(string: "https://test.example.com")!,
        session: session
    )
}

private struct TestModel: Codable, Equatable {
    let name: String
    let value: Int
}

private struct TestBody: Codable, Equatable {
    let id: String
}

// MARK: - Tests

@Suite(.serialized)
struct APIClientTests {

    init() {
        MockURLProtocol.reset()
    }

    @Test func getBuildsURLWithQueryParams() async throws {
        MockURLProtocol.mockResponseData = #"{"name":"test","value":1}"#.data(using: .utf8)

        let client = makeClient()
        let _: TestModel = try await client.get(
            path: "busroutes",
            queryItems: [URLQueryItem(name: "route", value: "22")]
        )

        let url = MockURLProtocol.lastRequest?.url
        #expect(url?.host == "test.example.com")
        #expect(url?.path.contains("busroutes") == true)
        #expect(url?.query?.contains("route=22") == true)
    }

    @Test func getDecodesJSONResponse() async throws {
        MockURLProtocol.mockResponseData = #"{"name":"red line","value":42}"#.data(using: .utf8)

        let client = makeClient()
        let result: TestModel = try await client.get(path: "test")

        #expect(result == TestModel(name: "red line", value: 42))
    }

    @Test func postEncodesBodyAndSetsHeaders() async throws {
        MockURLProtocol.mockResponseData = #"{"name":"ok","value":0}"#.data(using: .utf8)

        let client = makeClient()
        let _: TestModel = try await client.post(path: "savefavorites", body: TestBody(id: "device123"))

        let request = MockURLProtocol.lastRequest
        #expect(request?.httpMethod == "POST")
        #expect(request?.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let bodyData = try #require(MockURLProtocol.lastRequestBody)
        let sentBody = try JSONDecoder().decode(TestBody.self, from: bodyData)
        #expect(sentBody == TestBody(id: "device123"))
    }

    @Test func invalidStatusCodeThrowsInvalidResponse() async throws {
        MockURLProtocol.mockResponseData = #"{"error":"not found"}"#.data(using: .utf8)
        MockURLProtocol.mockStatusCode = 404

        let client = makeClient()
        do {
            let _: TestModel = try await client.get(path: "missing")
            Issue.record("Expected APIError.invalidResponse")
        } catch let error as APIError {
            guard case .invalidResponse(let code) = error else {
                Issue.record("Expected invalidResponse, got \(error)")
                return
            }
            #expect(code == 404)
        }
    }

    @Test func malformedJSONThrowsDecodingError() async throws {
        MockURLProtocol.mockResponseData = #"not json"#.data(using: .utf8)

        let client = makeClient()
        do {
            let _: TestModel = try await client.get(path: "bad")
            Issue.record("Expected APIError.decodingError")
        } catch let error as APIError {
            guard case .decodingError = error else {
                Issue.record("Expected decodingError, got \(error)")
                return
            }
        }
    }

    @Test func networkFailureThrowsNetworkError() async throws {
        MockURLProtocol.mockError = URLError(.notConnectedToInternet)

        let client = makeClient()
        do {
            let _: TestModel = try await client.get(path: "offline")
            Issue.record("Expected APIError.networkError")
        } catch let error as APIError {
            guard case .networkError = error else {
                Issue.record("Expected networkError, got \(error)")
                return
            }
        }
    }
}
