# 安全检查说明

检查日期：2026-11-13。此说明是有限范围的源码与本地运行检查，不是第三方安全审计，也不代表绝对安全保证。

## 对原项目的检查

参考仓库为 https://github.com/jiayouzl/Bitcoin-Monitoring ，参考提交 `0ca84114378063b03eeec2a29ca7684717b86744`。

检查了项目构建配置、权限声明，以及 Swift 源码中的网络目标、凭据持久化、外部执行、剪贴板和开机启动相关路径。所检路径未发现明显的钱包窃取、远程脚本执行或交易授权逻辑。构建配置没有第三方包依赖或 shell 构建阶段。

需要注意：原项目将代理密码保存在 UserDefaults，未使用 Keychain；HTTP Basic / Digest 认证委托也没有将认证范围严格限定在代理保护空间。BTC Mini 不包含代理凭据收集或保存功能。

原仓库发布 ZIP 未完成下载和二进制核验，因此**没有运行、安装或认定原发布包安全**，也没有证明原发布包与源码一致。

## 对 BTC Mini 的检查

- 从交付源码在本地编译，没有第三方运行库；`otool -L` 列出的依赖均为 Apple 系统库。
- 启用 App Sandbox，只附加 `com.apple.security.network.client`；没有文件访问、Apple Events、录屏、辅助功能、钱包或密钥权限。
- 仅请求 `https://data-api.binance.vision/api/v3/ticker/price`（现货）与 `https://fapi.binance.com/fapi/v2/ticker/price`（USDT 永续）；重定向限制为同一 HTTPS 主机，TLS 证书验证使用系统默认行为。
- 临时 URLSession 关闭 Cookie、凭据存储与响应缓存。不加载远程代码，不自动下载更新。
- 行情响应检查交易对名称、正数和有限数值，防止错误交易对或无效价格冒充有效数据。
- 请求失败保留更新时间并显示警告；过期门槛为 `max(30 秒, 2 × 刷新间隔)`，每 5 秒重新判断。切换币种或市场时取消旧请求，避免旧行情覆盖新币种。
- 本地偏好仅保存币种、市场、刷新间隔；点击“复制价格”时才写剪贴板，不读取剪贴板。
- 使用 ad-hoc 本地签名与 hardened runtime，未获得 Apple Developer ID 签名及公证。签名校验只能证明当前包未被修改，不能证明发布者身份。

## 可复核方式

```bash
./scripts/build.sh
./scripts/check.sh
codesign --verify --deep --strict 'build/BTC Mini.app'
codesign -d --entitlements - 'build/BTC Mini.app'
otool -L 'build/BTC Mini.app/Contents/MacOS/BTCMini'
```

行情可用性受 VPN、网络与服务端政策影响；网络失败会显示错误并按所选间隔再次尝试。当前网络上现货行情已验证，永续接口返回 HTTP 451 地区限制，未能验证实时永续报价。该工具仅查看公开报价，永续价格采用最新成交价，不是标记价或指数价。
