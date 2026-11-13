# BTC Mini

一个极简的 macOS 菜单栏加密货币价格监控工具。打开即显示 BTC/USDT，点击菜单栏查看价格、切换币种、复制价格或调整刷新频率，不占用 Dock。支持在币安现货与 **USDT 永续合约**之间切换，价格为**最新成交价**，不是标记价或指数价。

支持 BTC、ETH、SOL、BNB、DOGE 及所选市场已上市的自定义 USDT 交易对；刷新间隔为 5 / 10 / 30 / 60 秒，默认 10 秒。币种、市场和刷新间隔都会保存。网络失败与行情过期会明确提示，保留上次更新时间。界面为中文。

## 来源与知识产权

**本项目的底层架构来源于 [Mark / jiayouzl 的 Bitcoin-Monitoring](https://github.com/jiayouzl/Bitcoin-Monitoring)**，是基于其菜单栏监控架构重新整理的轻量衍生实现。感谢原作者的开源贡献，本项目不将上游成果宣称为独立原创。

- 沿用原项目的 SwiftUI + ObservableObject、PriceManager / PriceService 分层，以及公开 Binance ticker API 与定时刷新方案；相关实现为精简重写。
- `Sources/BTCPriceResponse.swift`、`Sources/RefreshInterval.swift` 直接复用上游代码，保留原文件中的 Mark 作者说明。
- 上游参考版本：`0ca84114378063b03eeec2a29ca7684717b86744`。详细对应关系见 [NOTICE.md](NOTICE.md)。
- 保留上游 [GNU GPL v3](LICENSE)，本项目整体采用 **GPL-3.0-only**。传播修改版或二进制时应遵守 GPL，并提供对应源码、构建脚本及归属说明。

## 安装与运行

要求 macOS 13+。当前 Release 安装包面向 Apple Silicon；Intel 用户可按下文自行编译。

下载 Release 中的 ZIP，解压后将 `BTC Mini.app` 拖入“应用程序”，双击启动；价格显示在屏幕顶部菜单栏。退出可在弹出面板中点击“退出”。如希望开机启动，可在 macOS“系统设置 → 通用 → 登录项”中自行添加应用。

安装包使用本地 ad-hoc 签名，**没有 Apple Developer ID 签名或公证**。其他 Mac 上可能被 Gatekeeper 拦截；确认下载来源后可使用“系统设置 → 隐私与安全性 → 仍要打开”，或从源码本地编译。无需关闭系统安全设置。

## 本地构建

安装 Apple Command Line Tools（`xcode-select --install`）后运行：

```bash
./scripts/build.sh          # 当前机器架构
./scripts/build.sh arm64    # Apple Silicon
./scripts/build.sh x86_64   # Intel
open 'build/BTC Mini.app'
```

只使用系统自带 SwiftUI / AppKit / Foundation / Combine；无需第三方依赖或包管理器。构建结果位于 `build/BTC Mini.app`。版本标签对应完整构建源码。

检查输入校验、行情响应、过期判断、实际联网、快速切币与自动刷新：

```bash
./scripts/check.sh
```

该检查会请求公开行情，需要网络可用，且会在 `Checks` 的独立偏好设置域中存储测试币种、市场及间隔；不会修改应用的偏好设置。

## 网络与隐私

现货请求 Binance 官方公开行情域名 `https://data-api.binance.vision`；USDT 永续请求 `https://fapi.binance.com/fapi/v2/ticker/price`。均为无需 API Key 的 HTTPS GET。参考 [Binance 现货文档](https://developers.binance.com/en/docs/products/spot/rest-api)、[永续最新价格接口文档](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Symbol-Price-Ticker-v2)。实际可用性取决于网络与服务端政策，不保证任何地区持续可用。当前美国节点实测：现货接口可用，币安合约接口返回 HTTP 451。应用会明确提示，不会用现货价格代替永续价格；其他节点需重新验证。

应用仅申请 **App Sandbox + 出站网络** 权限，不包含交易、钱包访问、分析埋点、自动更新或外部脚本执行。只在本地保存币种、市场和刷新间隔，不收集账号或代理密码；遵循系统网络环境。剪贴板仅在点击“复制价格”时写入。上游项目链接只在用户点击时打开。

排查连接问题时可从终端运行以下命令，诊断结果只输出到当前终端：

```bash
'/Applications/BTC Mini.app/Contents/MacOS/BTCMini' --diagnostics
```

安全检查范围和限制见 [SECURITY.md](SECURITY.md)。
