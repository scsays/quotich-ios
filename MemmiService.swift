import Foundation

struct MemmiResponse: Decodable {
    let received: String
    let memmi: String
    let source: String
}

enum MemmiServiceError: Error {
    case badResponse
}

final class MemmiService {
    static let shared = MemmiService()
    private init() {}

    func enrichQuote(_ quote: String) async throws -> MemmiResponse {
        let url = AppConfig.memmiBaseURL
            .appendingPathComponent("api/v1/quotes/enrich")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["quote": quote]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw MemmiServiceError.badResponse
        }

        return try JSONDecoder().decode(MemmiResponse.self, from: data)
    }
}

