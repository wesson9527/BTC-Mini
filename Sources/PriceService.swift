// SPDX-License-Identifier: GPL-3.0-only
import Foundation

enum MarketError: LocalizedError {
    case invalidSymbol, http(Int), invalidData
    var errorDescription: String? {
        switch self {
        case .invalidSymbol: return "请输入 2–10 位英文字母或数字，如 BTC"
        case .http(451): return "当前网络地区无法访问币安合约行情（HTTP 451）"
        case .http(let code): return "行情接口返回 HTTP \(code)，请检查网络或确认该交易对已上市"
        case .invalidData: return "行情数据无效，请稍后重试"
        }
    }
}

final class PriceService: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    static func valid(_ symbol: String) -> Bool {
        symbol.range(of: "^[A-Z0-9]{2,10}$", options: .regularExpression) != nil
    }
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 15
        config.httpCookieStorage = nil
        config.urlCredentialStorage = nil
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    func fetch(_ symbol: String, market: MarketKind = .spot) async throws -> Double {
        guard Self.valid(symbol) else { throw MarketError.invalidSymbol }
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = market.host
        parts.path = market.path
        parts.queryItems = [URLQueryItem(name: "symbol", value: symbol + "USDT")]
        guard let url = parts.url else { throw MarketError.invalidSymbol }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw MarketError.invalidData }
        guard http.statusCode == 200 else { throw MarketError.http(http.statusCode) }
        return try Self.decode(data, symbol: symbol)
    }
    static func decode(_ data: Data, symbol: String) throws -> Double {
        let item = try JSONDecoder().decode(TickerPriceResponse.self, from: data)
        guard item.symbol == symbol + "USDT", let price = Double(item.price), price.isFinite, price > 0 else {
            throw MarketError.invalidData
        }
        return price
    }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(request.url?.scheme == "https" && request.url?.host == task.originalRequest?.url?.host && MarketKind.allCases.contains(where: { $0.host == request.url?.host }) ? request : nil)
    }
}
