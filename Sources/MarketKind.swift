// SPDX-License-Identifier: GPL-3.0-only
import Foundation

enum MarketKind: String, CaseIterable, Codable {
    case spot, perpetual
    var title: String { self == .spot ? "现货" : "USDT 永续" }
    var shortTitle: String { self == .spot ? "现货" : "永续" }
    var host: String { self == .spot ? "data-api.binance.vision" : "fapi.binance.com" }
    var path: String { self == .spot ? "/api/v3/ticker/price" : "/fapi/v2/ticker/price" }
}
