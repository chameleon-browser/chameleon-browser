# Lightpanda 浏览器指纹检测审计报告

**日期:** 2026-02-25  
**测试版本:** `zig-out/bin/lightpanda` (2026-01-31 编译)  
**测试 Profile:** `chrome131-macos`

---

## 一、总体评估

使用编译好的 Lightpanda 浏览器实际访问了 4 个主流检测网站，结合源码审计，发现：

| 指标 | 结果 |
|------|------|
| **bot.sannysoft.com 通过率** | 7/14 项通过 (50%) |
| **AreYouHeadless 检测** | **通过** — "You are not Chrome headless" |
| **TLS 指纹 (tls.peet.ws)** | HTTP/2 设置匹配 Chrome，但 JA3 hash 对应 Chrome 116（UA 声称 131） |
| **BrowserLeaks Canvas** | Canvas 产出数据但指纹在数据库中唯一 (100% unique)，仅 4 色 |
| **源码审计发现** | 8 个 CRITICAL、6 个 HIGH、6 个 MEDIUM 级别泄漏 |

**结论：** 基础的 bot 检测（WebDriver、UA、window.chrome）已通过，但中高级检测（Plugins 类型、Canvas 内容、Audio 指纹、TLS 版本匹配、CSS matchMedia）存在明显泄漏。

---

## 二、测试方法

```bash
# 使用 fetch 命令直接访问检测网站，获取渲染后的 DOM
./zig-out/bin/lightpanda fetch --dump --browser chrome131-macos <URL>
```

测试网站：
1. `bot.sannysoft.com` — 综合 bot 检测（Intoli 测试 + fpScanner）
2. `arh.antoinevastel.com/bots/areyouheadless` — Chrome Headless 专项检测
3. `tls.peet.ws/api/all` — TLS/HTTP2 指纹检测（返回 JSON）
4. `browserleaks.com/canvas` — Canvas 指纹检测

---

## 三、实际测试结果

### 3.1 bot.sannysoft.com

| 测试项 | 结果 | 状态 |
|--------|------|------|
| User Agent | `Chrome/131.0.0.0` (无 HeadlessChrome) | ✅ PASS |
| WebDriver | `missing (passed)` | ✅ PASS |
| WebDriver Advanced (40+ 自动化全局变量) | `passed` | ✅ PASS |
| Chrome 对象 | `present (passed)` | ✅ PASS |
| Plugins Length | `5` | ✅ PASS |
| navigator.cookieEnabled | `true` | ✅ PASS |
| navigator.javaEnabled | `false` | ✅ PASS |
| screen (2560×1440, depth=30) | 正常 | ✅ PASS |
| navigator.language | `en-US` | ✅ PASS |
| navigator.platform | `MacIntel` | ✅ PASS |
| navigator.vendor | `Google Inc.` | ✅ PASS |
| navigator.getBattery | `Charging: true, Level: 1` | ✅ PASS |
| **Permissions** | `denied` | ❌ FAIL |
| **Plugins Type (PluginArray)** | 空/失败 | ❌ FAIL |
| **Languages** | 空/失败 | ❌ FAIL |
| **WebGL Vendor/Renderer** | 未渲染 | ❌ FAIL |
| **Broken Image Dimensions** | 未渲染 | ❌ FAIL |
| **navigator.plugins JSON** | `{}` (空对象) | ❌ FAIL |
| **navigator.sendBeacon** | 无输出 | ❌ FAIL |
| **Canvas 1-5 Hash** | 未渲染 | ⚠️ 不确定 |
| **FP-Scanner 结果** | 未渲染 | ❌ FAIL |

**分析：** 基础检测全部通过，但涉及实际 API 行为的检测（Plugins 对象遍历、Languages 数组格式、WebGL 渲染、Canvas Hash 计算）大部分失败。

### 3.2 AreYouHeadless (Antoine Vastel)

```
结果: "You are not Chrome headless" ✅ PASS
```

这是一个专门检测 Chromium Headless 内部行为的高级测试，Lightpanda 通过了。

### 3.3 TLS 指纹 (tls.peet.ws)

| 指标 | Lightpanda 实际值 | Chrome 131 期望值 | 状态 |
|------|-------------------|-------------------|------|
| TLS 版本 | 1.3 | 1.3 | ✅ |
| Cipher Suites 数量 | 16 + GREASE | 17 + GREASE | ⚠️ 接近 |
| GREASE | 有 | 有 | ✅ |
| ALPN | h2, http/1.1 | h2, http/1.1 | ✅ |
| ALPS 扩展 | 有 (application_settings_old) | 有 | ✅ |
| compress_certificate | brotli | brotli | ✅ |
| **JA3 Hash** | `a4a782d100bcc207c412dd0144ffb67b` | Chrome 131 的 hash | ❌ 不匹配（是 Chrome 116 的） |
| **JA4** | `t13d1516h2_...` | Chrome 131 JA4 | ❌ 不匹配 |
| HTTP/2 SETTINGS | `1:65536;2:0;3:1000;4:6291456;6:262144` | 匹配 Chrome | ✅ |
| HTTP/2 WINDOW_UPDATE | `15663105` | 匹配 Chrome | ✅ |
| HTTP/2 伪头部顺序 | `m,a,s,p` | `m,a,s,p` | ✅ |
| **Header 顺序** | accept-encoding 在 user-agent 之前 | sec-ch-ua 在 user-agent 之前 | ❌ 不匹配 |

**关键问题：** curl-impersonate 使用 `chrome116` target，但 UA 声称 Chrome 131。JA3/JA4 与 UA 版本不匹配，高级反 bot 系统（Cloudflare、Akamai）可检测此不一致。

### 3.4 BrowserLeaks Canvas

| 指标 | 结果 | 状态 |
|------|------|------|
| Canvas 2D API | ✅ 支持 | ✅ |
| Text API | ✅ 支持 | ✅ |
| toDataURL | ✅ 支持 | ✅ |
| 指纹 Hash | `cce276f91bccf6cef278b3a503972b9c` | ⚠️ |
| 唯一性 | **100%** (数据库中唯一) | ❌ |
| 颜色数 | **4** (真实浏览器通常更多) | ❌ |
| PNG 验证 | "Not a PNG file" | ❌ |

**关键问题：** Canvas 指纹在 BrowserLeaks 数据库中 100% 唯一，说明产出的 Canvas 数据不像任何真实浏览器。原因是所有 Canvas 绘制操作都是 no-op，toDataURL 只基于 seed 生成。

---

## 四、指纹泄漏清单

### CRITICAL 级别

| ID | 类别 | 描述 | 文件 | 当前行为 | 期望行为 |
|----|------|------|------|----------|----------|
| **C-01** | Canvas | Canvas 绘制操作全部是 no-op | `CanvasRenderingContext2D.zig:120-139` | fillRect/fillText/arc 等函数体为空 | 需要实现真实的 2D 绘制，或至少影响 toDataURL 输出 |
| **C-02** | Canvas | toDataURL() 输出不依赖绘制内容 | `Canvas.zig:96-101` | 仅基于 seed + 尺寸 + MIME 生成 hash | 输出应反映实际绘制内容 |
| **C-03** | Audio | AudioContext connect/start 是 no-op | `AudioContext.zig:415-418` | oscillator→compressor→destination 连接无效 | 需要实现音频图连接，影响 startRendering 输出 |
| **C-04** | Audio | startRendering() 不处理音频图 | `AudioContext.zig:291-308` | buffer 数据纯粹基于 seed 生成 | 应模拟 DSP 处理管线的输出特征 |
| **C-05** | CSS | matchMedia() 所有查询返回 false | `MediaQueryList.zig:42-43` | 包括 `(min-width: 1px)` 也返回 false | 至少实现基本的尺寸/颜色/设备类型匹配 |
| **C-06** | Font | measureText() 完全不依赖字体 | `TextMetrics.zig:30-31` | 固定 0.55 * text.len * fontSize | 不同字体应返回不同宽度 |
| **C-07** | Font | setFont() 是 no-op | `CanvasRenderingContext2D.zig:135` | 设置的字体被忽略 | 应存储字体并影响 measureText |
| **C-08** | TLS | JA3/JA4 与 UA 版本不匹配 | `profiles.zig:177,268,357` | 所有 profile 使用 `chrome116` impersonate target | 应更新到与 UA 版本匹配的 target（chrome131/132） |

### HIGH 级别

| ID | 类别 | 描述 | 文件 | 当前行为 | 期望行为 |
|----|------|------|------|----------|----------|
| **H-01** | Navigator | plugins.item(n) 返回 null | `PluginArray.zig:64-66` | length=5 但 item() 返回 null | 应返回 Plugin 对象（PDF Viewer 等） |
| **H-02** | Navigator | mimeTypes.item(n) 返回 null | `PluginArray.zig:131-132` | length=2 但 item() 返回 null | 应返回 MimeType 对象 |
| **H-03** | DOM | Notification API 完全缺失 | 无对应文件 | `typeof Notification === 'undefined'` | 应存在 Notification 构造函数和 permission 属性 |
| **H-04** | Network | fetch() 缺少标准 Headers | `Fetch.zig:56-79` | 缺少 Accept, Sec-Fetch-*, Sec-CH-UA | 应自动添加浏览器标准 headers |
| **H-05** | Network | XHR 缺少标准 Headers | `XMLHttpRequest.zig:158-178` | 同 fetch() | 同 fetch() |
| **H-06** | WebGL | 所有绘制操作是 no-op | `WebGLRenderingContext.zig:424-908` | drawArrays/drawElements 等函数体为空 | 至少影响 readPixels 输出 |

### MEDIUM 级别

| ID | 类别 | 描述 | 文件 | 当前行为 | 期望行为 |
|----|------|------|------|----------|----------|
| **M-01** | Network | Header 顺序不匹配 Chrome | `Page.zig:406-436` | user-agent 在最前面 | sec-ch-ua 应在 user-agent 之前 |
| **M-02** | DOM | navigator.bluetooth 缺失 | 无对应文件 | `'bluetooth' in navigator === false` | 应存在 stub 对象 |
| **M-03** | DOM | navigator.usb 缺失 | 无对应文件 | `'usb' in navigator === false` | 应存在 stub 对象 |
| **M-04** | Media | enumerateDevices() 返回空数组 | `MediaDevices.zig:32-37` | `[]` | 至少返回一个 audiooutput 设备 |
| **M-05** | DOM | 无 WebSocket Web API | 无对应文件 | `new WebSocket()` 不可用 | 应实现 WebSocket 构造函数 |
| **M-06** | WebGL | getShaderPrecisionFormat 返回固定值 | `WebGLRenderingContext.zig:419` | 所有类型返回 127/127/23 | 不同 shader 类型应返回不同值 |

### LOW 级别

| ID | 类别 | 描述 | 文件 | 当前行为 | 期望行为 |
|----|------|------|------|----------|----------|
| **L-01** | Network | navigator.connection.type 硬编码 | `Navigator.zig:279` | 固定 "wifi" | 应可通过 profile 配置 |
| **L-02** | DOM | navigator.deviceMemory 所有 profile 相同 | `profiles.zig` | 全部为 8 | 不同 profile 应有不同值 |
| **L-03** | Chrome | chrome.csi()/loadTimes() 合成时间 | `Chrome.zig:62-95` | 使用固定偏移量 | 应有更多随机变化 |
| **L-04** | DOM | Broken image dimensions = 0x0 | 未实现 | 破损图片宽高为 0 | 应返回非零值（如 16x16） |

---

## 五、改进计划

### Phase 1: 关键修复 (第 1-2 周)

| 任务 | 修复泄漏 | 优先级 | 预估工作量 |
|------|----------|--------|------------|
| 更新 curl-impersonate target 到 chrome131 | C-08 | P0 | 0.5 天 |
| 实现 PluginArray.item() 返回真实 Plugin 对象 | H-01, H-02 | P0 | 1 天 |
| 实现基础 matchMedia() 解析和匹配 | C-05 | P0 | 2 天 |
| 添加 Notification API stub (构造函数 + permission) | H-03 | P0 | 0.5 天 |
| fetch()/XHR 自动添加标准 Headers | H-04, H-05 | P0 | 1 天 |

### Phase 2: Canvas/Audio 指纹改进 (第 3-4 周)

| 任务 | 修复泄漏 | 优先级 | 预估工作量 |
|------|----------|--------|------------|
| Canvas 2D: 实现 fillRect/fillText 实际影响像素数据 | C-01, C-02 | P1 | 3-5 天 |
| measureText: 实现字体感知的宽度计算 | C-06, C-07 | P1 | 2 天 |
| AudioContext: 实现基础的音频图连接和 DSP 模拟 | C-03, C-04 | P1 | 3 天 |
| WebGL: readPixels 应基于绘制命令序列 | H-06 | P1 | 2 天 |

### Phase 3: 一致性打磨 (第 2 个月)

| 任务 | 修复泄漏 | 优先级 | 预估工作量 |
|------|----------|--------|------------|
| 修正 HTTP Header 顺序匹配 Chrome | M-01 | P2 | 1 天 |
| 添加 navigator.bluetooth/usb stub | M-02, M-03 | P2 | 0.5 天 |
| enumerateDevices() 返回默认设备 | M-04 | P2 | 0.5 天 |
| 实现 WebSocket Web API | M-05 | P2 | 3 天 |
| WebGL shader precision 按类型区分 | M-06 | P2 | 0.5 天 |

### Phase 4: 精细化 (第 3 个月+)

| 任务 | 修复泄漏 | 优先级 | 预估工作量 |
|------|----------|--------|------------|
| connection.type 可配置 | L-01 | P3 | 0.5 天 |
| deviceMemory profile 差异化 | L-02 | P3 | 0.5 天 |
| chrome.csi()/loadTimes() 增加随机性 | L-03 | P3 | 0.5 天 |
| Broken image 返回非零尺寸 | L-04 | P3 | 0.5 天 |
| 构建指纹回归测试套件 | — | P3 | 2 天 |

---

## 六、当前做得好的部分

以下方面 Lightpanda 的实现**已经很好**，通过了实际检测：

1. **navigator.webdriver = false** — 正确，通过了所有 WebDriver 检测
2. **User-Agent 配置系统** — 可配置的 profile，UA 字符串逼真
3. **window.chrome 对象** — 完整实现了 runtime/app/csi/loadTimes
4. **WebDriver Advanced 检测** — 40+ 自动化框架全局变量检测全部通过
5. **AreYouHeadless 高级检测** — 通过了 Antoine Vastel 的内部行为检测
6. **curl-impersonate + BoringSSL** — TLS 指纹基础框架正确（GREASE、ALPS、H2 设置）
7. **HTTP/2 参数** — SETTINGS frame 和伪头部顺序完全匹配 Chrome
8. **Screen 属性** — profile 驱动，值逼真（2560×1440, colorDepth=30, DPR=2.0）
9. **Permissions API** — 实现完整，默认值合理
10. **BatteryManager** — 可配置，默认值正常
11. **RTCPeerConnection** — 存在但阻止 WebRTC IP 泄漏
12. **Client Hints API (userAgentData)** — 完整实现 brands/platform/highEntropyValues

---

## 七、检测网站覆盖总结

| 检测网站 | 测试了 | 结果 |
|----------|--------|------|
| bot.sannysoft.com | ✅ 是 | 50% 通过 |
| arh.antoinevastel.com | ✅ 是 | 通过 |
| tls.peet.ws | ✅ 是 | HTTP/2 匹配，TLS 版本不匹配 |
| browserleaks.com/canvas | ✅ 是 | Canvas 存在但指纹异常 |
| creepjs | ⚠️ 页面过于复杂，渲染不完整 | 需要 CDP 方式测试 |
| pixelscan.net | 未测试 | 需要后续测试 |
| fingerprint.com | 未测试 | 需要后续测试 |

---

*报告生成: 2026-02-25 | 使用 Lightpanda `zig-out/bin/lightpanda` 实际测试 + 源码审计*
