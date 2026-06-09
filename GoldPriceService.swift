import Foundation

struct GoldPriceQuote: Equatable {
    var cnyPerGram: Double
    var updatedAt: Date
}

enum GoldPriceError: LocalizedError {
    case invalidResponse
    case apiMessage(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Invalid gold price response"
        case .apiMessage(let message):
            message
        }
    }
}

final class GoldPriceService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCNYPerGram() async throws -> GoldPriceQuote {
        let url = try makeURL()
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw GoldPriceError.invalidResponse
        }

        let payload = try JSONDecoder().decode(ZSBankGoldPriceResponse.self, from: data)

        guard payload.success, payload.resultCode == 0 else {
            throw GoldPriceError.apiMessage(payload.resultMsg)
        }

        let resultData = payload.resultData
        guard resultData.success, resultData.code == "0000" else {
            throw GoldPriceError.apiMessage(payload.resultMsg)
        }

        return GoldPriceQuote(
            cnyPerGram: resultData.data.lastPrice,
            updatedAt: resultData.data.tradeDateTime.date ?? Date()
        )
    }

    private func makeURL() throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.jdjygold.com"
        components.path = "/gw2/generic/produTools/h5/m/getGoldPrice"
        components.queryItems = [
            URLQueryItem(name: "goldCode", value: "CZB-JCJ")
        ]

        guard let url = components.url else {
            throw GoldPriceError.invalidResponse
        }
        return url
    }
}

private struct ZSBankGoldPriceResponse: Decodable {
    var resultData: ResultData
    var success: Bool
    var resultCode: Int
    var resultMsg: String

    struct ResultData: Decodable {
        var code: String
        var data: GoldData
        var success: Bool
    }

    struct GoldData: Decodable {
        var lastPrice: Double
        var tradeDateTime: TradeDateTime
    }

    struct TradeDateTime: Decodable {
        var year: Int
        var monthValue: Int
        var dayOfMonth: Int
        var hour: Int
        var minute: Int
        var second: Int

        var date: Date? {
            var components = DateComponents()
            components.calendar = Calendar(identifier: .gregorian)
            components.timeZone = TimeZone(identifier: "Asia/Shanghai")
            components.year = year
            components.month = monthValue
            components.day = dayOfMonth
            components.hour = hour
            components.minute = minute
            components.second = second
            return components.date
        }
    }
}
