// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import AppKit

@main
struct BTCMiniApp: App {
    @StateObject private var model = PriceManager()
    var body: some Scene {
        MenuBarExtra {
            MonitorView(model: model)
        } label: {
            Text(model.statusTitle).monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}

struct MonitorView: View {
    @ObservedObject var model: PriceManager
    @State private var customSymbol = ""
    @State private var inputError: String?
    private let coins = ["BTC", "ETH", "SOL", "BNB", "DOGE"]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bitcoinsign.circle.fill").foregroundStyle(.orange)
                Text("BTC Mini").font(.headline)
                Spacer()
                Text("币安 · \(model.market.shortTitle)").font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(model.symbol) / USDT · \(model.market.title) · 最新成交价").font(.caption).foregroundStyle(.secondary)
                Text(model.formattedPrice).font(.system(size: 34, weight: .medium, design: .rounded)).monospacedDigit()
                if let error = model.error {
                    Label(error, systemImage: "wifi.exclamationmark").font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                } else if model.stale {
                    Label("数据已过期，等待更新", systemImage: "clock.badge.exclamationmark").font(.caption).foregroundStyle(.orange)
                }
                if let date = model.updatedAt {
                    Text("上次更新 \(date.formatted(date: .omitted, time: .standard))")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(model.loading ? "正在获取行情…" : "等待行情")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Divider()
            Picker("行情市场", selection: Binding(get: { model.market }, set: { model.setMarket($0) })) {
                ForEach(MarketKind.allCases, id: \.rawValue) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("监控币种", selection: Binding(get: { model.symbol }, set: { model.select($0) })) {
                ForEach(coins, id: \.self) { Text($0).tag($0) }
                if !coins.contains(model.symbol) { Text(model.symbol).tag(model.symbol) }
            }
            HStack {
                TextField("自定义币种，如 ADA", text: $customSymbol).textFieldStyle(.roundedBorder)
                    .onSubmit(addCustom)
                Button("切换", action: addCustom)
            }
            if let inputError { Text(inputError).font(.caption).foregroundStyle(.orange) }
            Picker("自动刷新", selection: Binding(get: { model.interval }, set: { model.setInterval($0) })) {
                ForEach(RefreshInterval.allCases, id: \.rawValue) { Text($0.displayText).tag($0) }
            }
            HStack {
                Button(action: { model.refresh() }) {
                    Label(model.loading ? "刷新中…" : "刷新", systemImage: "arrow.clockwise")
                }.disabled(model.loading).keyboardShortcut("r", modifiers: .command)
                Button("复制价格") {
                    guard model.price != nil else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("币安 \(model.market.title) \(model.symbol)/USDT \(model.formattedPrice)\(model.error != nil || model.stale ? "（上次行情）" : "")", forType: .string)
                }.disabled(model.price == nil)
                Spacer()
                Button("退出") { NSApplication.shared.terminate(nil) }
            }
            Text("只读公开行情 · 无需账号或 API Key").font(.system(size: 10)).foregroundStyle(.tertiary)
            Link("基于 Mark / Bitcoin-Monitoring · GPL-3.0", destination: URL(string: "https://github.com/jiayouzl/Bitcoin-Monitoring")!)
                .font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 340)
    }
    private func addCustom() {
        let value = customSymbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard PriceService.valid(value) else { inputError = MarketError.invalidSymbol.localizedDescription; return }
        inputError = nil
        model.select(value)
        customSymbol = ""
    }
}
