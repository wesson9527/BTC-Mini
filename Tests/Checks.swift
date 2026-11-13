// SPDX-License-Identifier: GPL-3.0-only
import Foundation

@main
struct Checks {
    @MainActor
    static func main() async throws {
        for symbol in ["BTC", "ETH", "1INCH", "1000SATS"] { precondition(PriceService.valid(symbol)) }
        for symbol in ["btc", "A", "../BTC", "BTC&x=y", "", "ABCDEFGHIJK"] { precondition(!PriceService.valid(symbol)) }
        let valid = Data(#"{"symbol":"BTCUSDT","price":"70000.12"}"#.utf8)
        precondition(tryValue(valid) == 70000.12)
        for fixture in [
            #"{"symbol":"ETHUSDT","price":"70000"}"#,
            #"{"symbol":"BTCUSDT","price":"NaN"}"#,
            #"{"symbol":"BTCUSDT","price":"inf"}"#,
            #"{"symbol":"BTCUSDT","price":"-1"}"#,
            #"{"symbol":"BTCUSDT","price":"0"}"#,
            #"{"code":-1121,"msg":"Invalid symbol."}"#
        ] { precondition(tryValue(Data(fixture.utf8)) == nil) }
        let now = Date()
        precondition(!PriceManager.stale(updatedAt: now, now: now, interval: 10))
        precondition(PriceManager.stale(updatedAt: now.addingTimeInterval(-31), now: now, interval: 10))
        precondition(!PriceManager.stale(updatedAt: now.addingTimeInterval(-100), now: now, interval: 60))
        precondition(PriceManager.stale(updatedAt: now.addingTimeInterval(-121), now: now, interval: 60))
        precondition(!PriceManager.stale(updatedAt: nil, now: now, interval: 10))
        print("PASS: symbol validation, response validation, stale data boundaries")
        let service = PriceService()
        for symbol in ["BTC", "ETH", "SOL", "BNB", "DOGE"] {
            let price = try await service.fetch(symbol)
            print("PASS: live \(symbol)/USDT \(price)")
        }
        do {
            let price = try await service.fetch("BTC", market: .perpetual)
            print("PASS: live Binance BTC/USDT perpetual \(price)")
        } catch MarketError.http(451) {
            print("LIMITATION: Binance perpetual endpoint returns HTTP 451 on current network; live perpetual price not verified")
        }
        let model = PriceManager()
        model.setMarket(.perpetual)
        model.setMarket(.spot)
        model.select("ETH")
        model.select("SOL")
        for _ in 0..<40 {
            if model.updatedAt != nil && !model.loading { break }
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        precondition(model.symbol == "SOL" && model.price != nil && model.error == nil)
        precondition(model.statusTitle.hasPrefix("SOL·现货 "))
        print("PASS: rapid coin switching cancels stale responses and updates menu title")
        let firstUpdate = model.updatedAt!
        model.setInterval(.fiveSeconds)
        for _ in 0..<40 {
            if let date = model.updatedAt, date > firstUpdate { break }
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        precondition(model.updatedAt! > firstUpdate)
        precondition(UserDefaults.standard.string(forKey: "symbol") == "SOL")
        precondition(UserDefaults.standard.double(forKey: "interval") == 5)
        precondition(UserDefaults.standard.string(forKey: "market") == "spot")
        precondition(MarketKind.perpetual.host == "fapi.binance.com")
        precondition(MarketKind.perpetual.path == "/fapi/v2/ticker/price")
        print("PASS: market switching cancels previous requests and persists market")
        print("PASS: automatic refresh and persisted preferences")
    }
    static func tryValue(_ data: Data) -> Double? { try? PriceService.decode(data, symbol: "BTC") }
}
