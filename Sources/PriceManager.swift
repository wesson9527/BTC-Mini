// SPDX-License-Identifier: GPL-3.0-only
// Architecture adapted from Mark / jiayouzl's Bitcoin-Monitoring (GPL-3.0).
import SwiftUI

@MainActor
final class PriceManager: ObservableObject {
    @Published private(set) var symbol: String
    @Published private(set) var interval: RefreshInterval
    @Published private(set) var market: MarketKind
    @Published private(set) var price: Double?
    @Published private(set) var updatedAt: Date?
    @Published private(set) var error: String?
    @Published private(set) var loading = false
    @Published private(set) var now = Date()
    private let service = PriceService()
    private var timer: Timer?
    private var request: Task<Void, Never>?
    private var generation = 0
    private var nextFetch = Date.distantPast
    private var wakeObserver: NSObjectProtocol?
    private let defaults = UserDefaults.standard

    init() {
        let saved = defaults.string(forKey: "symbol") ?? "BTC"
        symbol = PriceService.valid(saved) ? saved : "BTC"
        market = MarketKind(rawValue: defaults.string(forKey: "market") ?? "") ?? .spot
        interval = RefreshInterval(rawValue: defaults.double(forKey: "interval")) ?? .tenSeconds
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.now = Date()
                if self.now >= self.nextFetch { self.refresh() }
            }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in Task { @MainActor in self?.refresh() } }
        refresh()
    }
    static func stale(updatedAt: Date?, now: Date, interval: TimeInterval) -> Bool {
        guard let updatedAt else { return false }
        return now.timeIntervalSince(updatedAt) > max(30, interval * 2)
    }
    var stale: Bool { Self.stale(updatedAt: updatedAt, now: now, interval: interval.rawValue) }
    var formattedPrice: String {
        guard let price else { return "—" }
        return price.formatted(.number.precision(.fractionLength(price >= 1 ? 2...2 : 2...8)))
    }
    var statusTitle: String {
        let warning = error != nil || stale ? " ⚠︎" : ""
        return "\(symbol)·\(market.shortTitle) \(formattedPrice)\(warning)"
    }
    func select(_ newSymbol: String) {
        guard PriceService.valid(newSymbol) else { return }
        generation += 1
        request?.cancel()
        loading = false
        symbol = newSymbol
        price = nil
        updatedAt = nil
        error = nil
        defaults.set(symbol, forKey: "symbol")
        refresh()
    }
    func setMarket(_ value: MarketKind) {
        market = value
        defaults.set(value.rawValue, forKey: "market")
        select(symbol)
    }
    func setInterval(_ value: RefreshInterval) {
        interval = value
        defaults.set(value.rawValue, forKey: "interval")
        nextFetch = Date().addingTimeInterval(value.rawValue)
    }
    func refresh() {
        guard !loading else { return }
        loading = true
        let requestedSymbol = symbol
        let requestedMarket = market
        let token = generation
        request = Task { [weak self] in
            guard let self else { return }
            do {
                let value = try await service.fetch(requestedSymbol, market: requestedMarket)
                guard !Task.isCancelled, token == generation else { return }
                price = value
                updatedAt = Date()
                now = Date()
                error = nil
            } catch {
                guard !Task.isCancelled, token == generation else { return }
                self.error = error.localizedDescription
            }
            if ProcessInfo.processInfo.arguments.contains("--diagnostics") {
                print("BTC Mini | \(statusTitle) | updated=\(updatedAt?.description ?? "never") | error=\(error ?? "none")")
                fflush(stdout)
            }
            loading = false
            nextFetch = Date().addingTimeInterval(interval.rawValue)
        }
    }
}
