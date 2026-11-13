#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
xcrun swiftc -swift-version 5 -parse-as-library \
    Sources/BTCPriceResponse.swift Sources/RefreshInterval.swift Sources/MarketKind.swift Sources/PriceService.swift Sources/PriceManager.swift \
    Tests/Checks.swift -o build/Checks
build/Checks
