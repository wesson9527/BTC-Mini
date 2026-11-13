# Attribution / 上游归属

Original project: Bitcoin-Monitoring

Original author: Mark / jiayouzl

Source: https://github.com/jiayouzl/Bitcoin-Monitoring

Reference commit: 0ca84114378063b03eeec2a29ca7684717b86744

Upstream license: GNU General Public License version 3

BTC Mini is a lightweight derivative inspired by and adapted from the original project's native macOS menu bar monitoring architecture. It is not an official release of, or endorsed by, the upstream author.

## Directly reused files

| BTC Mini | Original path | Changes |
| --- | --- | --- |
| Sources/BTCPriceResponse.swift | Bitcoin-Monitoring/Models/BTCPriceResponse.swift | None; original author comments retained |
| Sources/RefreshInterval.swift | Bitcoin-Monitoring/Models/RefreshInterval.swift | None; original author comments retained |
| LICENSE | LICENSE | None |

## Adapted architecture and new implementation

- `PriceManager`: adapts the upstream observable manager / timer / persistent preferences architecture. Rewritten with request cancellation, generation checks, wake refresh, stale data state, and spot/perpetual market selection.
- `PriceService`: adapts the upstream public Binance ticker request / response architecture. Rewritten with an ephemeral session, strict response validation, separate official public spot and USDT perpetual endpoints, and restricted redirects.
- `BTCMiniApp` / `MonitorView`: new minimal SwiftUI MenuBarExtra interface replacing upstream menus and preference windows.
- `MarketKind` is a new market/endpoint mapping model. Build scripts, tests, sandbox entitlements, and documentation are provided for this derivative.

Modifications prepared on 2026-11-13. The derivative is distributed under GPL-3.0-only with complete corresponding source and build instructions. Existing upstream authorship and license remain applicable to reused material.
