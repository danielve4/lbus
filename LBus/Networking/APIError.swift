import Foundation

enum APIError: LocalizedError {
    case networkError(Error)
    case invalidResponse(statusCode: Int)
    case decodingError(Error)
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let statusCode):
            return "Server returned status code \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiError(let message):
            return message
        }
    }
}
